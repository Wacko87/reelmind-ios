import Foundation

public final class GeminiService: Sendable {
    public static let shared = GeminiService()

    private let session: URLSession

    private init() {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 45
        self.session = URLSession(configuration: config)
    }

    public var apiKey: String {
        UserDefaults.standard.string(forKey: "gemini_api_key") ?? ""
    }

    public var hasApiKey: Bool {
        !apiKey.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    // MARK: - Analyze Content with Gemini

    public func analyzeContent(urlOrText: String) async throws -> Reel {
        guard hasApiKey else {
            throw ReelMindError.serverError(message: "Please add your free Google Gemini API Key in Settings to analyze reels.")
        }

        let systemInstruction = """
        You are ReelMind AI, an elite technical intelligence extractor specialized in AI tools, prompts, software engineering workflows, and social media reels (Instagram, TikTok, YouTube, X).
        Analyze the provided URL, text, or title, infer the subject matter, and extract structured practical knowledge.
        Return strictly JSON with:
        - title: concise punchy title
        - summary: 2-3 sentence executive summary of what is achieved and why it matters
        - ai_tools: array of AI tools/models/frameworks mentioned (e.g. Midjourney v6.1, Flux 1.1 Pro, Cursor, Claude Code, ElevenLabs)
        - key_steps: ordered step-by-step blueprint to replicate the trick
        - prompts: literal formulas or prompts ready to copy
        - tags: lowercase categorization tags
        - difficulty: "Principiante", "Intermedio", or "Avanzado"
        - estimated_time: "< 5 min", "15-30 min", or "> 1 hora"
        """

        let promptText = "Analyze this link/content and extract all AI tools, prompts and tutorial steps: \(urlOrText)"

        let responseJSON = try await callGemini(
            systemInstruction: systemInstruction,
            prompt: promptText,
            enforceJSON: true
        )

        guard let data = responseJSON.data(using: .utf8) else {
            throw ReelMindError.decodingError(message: "Failed to convert Gemini response to data.")
        }

        struct GeminiRawOutput: Codable {
            let title: String
            let summary: String
            let ai_tools: [String]?
            let key_steps: [String]?
            let prompts: [String]?
            let tags: [String]?
            let difficulty: String?
            let estimated_time: String?
        }

        let raw = try JSONDecoder().decode(GeminiRawOutput.self, from: data)

        // Detect platform from URL
        let platform: String
        let lower = urlOrText.lowercased()
        if lower.contains("instagram.com") { platform = "Instagram" }
        else if lower.contains("tiktok.com") { platform = "TikTok" }
        else if lower.contains("youtube.com") || lower.contains("youtu.be") { platform = "YouTube" }
        else if lower.contains("twitter.com") || lower.contains("x.com") { platform = "X" }
        else { platform = "Web" }

        let now = ISO8601DateFormatter().string(from: Date())

        return Reel(
            id: UUID().uuidString,
            url: urlOrText,
            platform: platform,
            title: raw.title,
            summary: raw.summary,
            aiTools: raw.ai_tools ?? [],
            keySteps: raw.key_steps ?? [],
            prompts: raw.prompts ?? [],
            tags: raw.tags ?? [],
            difficulty: raw.difficulty ?? "Intermedio",
            estimatedTime: raw.estimated_time ?? "15-30 min",
            status: "pending",
            userNotes: "",
            mediaType: "reel",
            createdAt: now,
            updatedAt: now
        )
    }

    // MARK: - Prompt Optimization

    public func optimizePrompt(prompt: String, targetModel: String) async throws -> [PromptVariation] {
        guard hasApiKey else {
            throw ReelMindError.serverError(message: "Please configure your Gemini API Key in Settings.")
        }

        let systemInstruction = """
        You are a Prompt Engineering Expert. Provide 3 optimized, high-fidelity variations of the user's prompt specifically tailored for \(targetModel).
        Return strict JSON array with objects:
        [
          {"label": "Style / Focus name", "prompt": "optimized prompt text", "explanation": "why this variation works best"}
        ]
        """

        let rawJSON = try await callGemini(
            systemInstruction: systemInstruction,
            prompt: "Optimize this prompt: \(prompt)",
            enforceJSON: true
        )

        guard let data = rawJSON.data(using: .utf8) else {
            throw ReelMindError.decodingError(message: "Could not parse variations.")
        }

        struct RawVariation: Codable {
            let label: String
            let prompt: String
            let explanation: String?
        }

        let decoded = try JSONDecoder().decode([RawVariation].self, from: data)
        return decoded.map { PromptVariation(label: $0.label, prompt: $0.prompt, explanation: $0.explanation) }
    }

    // MARK: - Ask Vault

    public func askVault(question: String, vaultContext: String) async throws -> String {
        guard hasApiKey else {
            throw ReelMindError.serverError(message: "Please configure your Gemini API Key in Settings.")
        }

        let systemInstruction = """
        You are ReelMind Personal Knowledge Assistant.
        Answer the user's question using ONLY the provided vault knowledge base of reels, AI tools, and prompts.
        If the answer is in the vault, cite the relevant reels. Be concise, actionable, and encouraging.
        """

        let prompt = """
        VAULT KNOWLEDGE BASE:
        \(vaultContext)

        QUESTION:
        \(question)
        """

        return try await callGemini(
            systemInstruction: systemInstruction,
            prompt: prompt,
            enforceJSON: false
        )
    }

    // MARK: - Internal HTTP Client

    private func callGemini(systemInstruction: String, prompt: String, enforceJSON: Bool) async throws -> String {
        let model = UserDefaults.standard.string(forKey: "gemini_model") ?? "gemini-2.5-flash"
        let endpointString = "https://generativelanguage.googleapis.com/v1beta/models/\(model):generateContent?key=\(apiKey.trimmingCharacters(in: .whitespacesAndNewlines))"

        guard let url = URL(string: endpointString) else {
            throw ReelMindError.invalidURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        var generationConfig: [String: Any] = [
            "temperature": 0.3,
            "maxOutputTokens": 2048
        ]

        if enforceJSON {
            generationConfig["responseMimeType"] = "application/json"
        }

        let payload: [String: Any] = [
            "system_instruction": [
                "parts": [["text": systemInstruction]]
            ],
            "contents": [
                [
                    "role": "user",
                    "parts": [["text": prompt]]
                ]
            ],
            "generationConfig": generationConfig
        ]

        request.httpBody = try JSONSerialization.data(withJSONObject: payload)

        let (data, response) = try await session.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse else {
            throw ReelMindError.invalidResponse(statusCode: -1)
        }

        guard (200...299).contains(httpResponse.statusCode) else {
            if let errorObj = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
               let errorInfo = errorObj["error"] as? [String: Any],
               let message = errorInfo["message"] as? String {
                throw ReelMindError.serverError(message: "Gemini API: \(message)")
            }
            throw ReelMindError.invalidResponse(statusCode: httpResponse.statusCode)
        }

        guard let responseObj = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let candidates = responseObj["candidates"] as? [[String: Any]],
              let firstCandidate = candidates.first,
              let content = firstCandidate["content"] as? [String: Any],
              let parts = content["parts"] as? [[String: Any]],
              let firstPart = parts.first,
              let text = firstPart["text"] as? String else {
            throw ReelMindError.decodingError(message: "Unexpected response format from Gemini.")
        }

        return text
    }
}
