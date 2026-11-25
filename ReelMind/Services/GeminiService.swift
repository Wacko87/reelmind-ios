import Foundation

public final class GeminiService: Sendable {
    public static let shared = GeminiService()

    private let session: URLSession
    private let rateLimiter = RateLimiter(minIntervalSeconds: 2.0)

    private init() {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 45
        self.session = URLSession(configuration: config)
    }

    public var apiKey: String {
        KeychainService.shared.migrateFromUserDefaultsIfNeeded(key: "gemini_api_key")
        return KeychainService.shared.get(key: "gemini_api_key") ?? ""
    }

    public var hasApiKey: Bool {
        !apiKey.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    private var isCurrentLanguageSpanish: Bool {
        Locale.current.language.languageCode?.identifier == "es"
    }

    // MARK: - Analyze Content with Gemini

    public func analyzeContent(urlOrText: String) async throws -> Reel {
        guard hasApiKey else {
            let errorMsg = isCurrentLanguageSpanish
                ? "Por favor añade tu clave gratuita de Google Gemini en Ajustes para analizar reels."
                : "Please add your free Google Gemini API Key in Settings to analyze reels."
            throw ReelMindError.serverError(message: errorMsg)
        }

        let isSpanish = isCurrentLanguageSpanish
        let difficultyInstruction = isSpanish ? "\"Principiante\", \"Intermedio\", or \"Avanzado\"" : "\"Beginner\", \"Intermediate\", or \"Advanced\""
        let languageInstruction = isSpanish ? "Provide title, summary, and key_steps in Spanish." : "Provide title, summary, and key_steps in English."

        let systemInstruction = """
        You are ReelMind AI, an elite technical intelligence extractor specialized in AI tools, prompts, software engineering workflows, and social media reels (Instagram, TikTok, YouTube, X).
        Analyze the provided URL, text, or title, infer the subject matter, and extract structured practical knowledge.
        \(languageInstruction)
        Return strictly JSON with:
        - title: concise punchy title
        - summary: 2-3 sentence executive summary of what is achieved and why it matters
        - ai_tools: array of AI tools/models/frameworks mentioned (e.g. Midjourney v6.1, Flux 1.1 Pro, Cursor, Claude Code, ElevenLabs)
        - key_steps: ordered step-by-step blueprint to replicate the trick
        - prompts: literal formulas or prompts ready to copy
        - tags: lowercase categorization tags
        - difficulty: \(difficultyInstruction)
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
            let errorMsg = isCurrentLanguageSpanish
                ? "Por favor configura tu clave de Gemini en Ajustes."
                : "Please configure your Gemini API Key in Settings."
            throw ReelMindError.serverError(message: errorMsg)
        }

        let langNote = isCurrentLanguageSpanish ? "Write explanations in Spanish." : "Write explanations in English."

        let systemInstruction = """
        You are a Prompt Engineering Expert. Provide 3 optimized, high-fidelity variations of the user's prompt specifically tailored for \(targetModel).
        \(langNote)
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
            let errorMsg = isCurrentLanguageSpanish
                ? "Por favor configura tu clave de Gemini en Ajustes."
                : "Please configure your Gemini API Key in Settings."
            throw ReelMindError.serverError(message: errorMsg)
        }

        let langNote = isCurrentLanguageSpanish ? "Answer in Spanish." : "Answer in English."

        let systemInstruction = """
        You are ReelMind Personal Knowledge Assistant.
        Answer the user's question using ONLY the provided vault knowledge base of reels, AI tools, and prompts.
        If the answer is in the vault, cite the relevant reels. Be concise, actionable, and encouraging.
        \(langNote)
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

    // MARK: - Health Check / Test API Key

    public func testApiKey() async throws {
        guard hasApiKey else {
            let errorMsg = isCurrentLanguageSpanish
                ? "Por favor añade tu clave de Gemini en Ajustes."
                : "Please add your Gemini API Key in Settings."
            throw ReelMindError.serverError(message: errorMsg)
        }

        // Validate key and generation with lightweight gemini-3.5-flash-lite (fast, high-availability)
        guard let url = URL(string: "https://generativelanguage.googleapis.com/v1beta/models/gemini-3.5-flash-lite:generateContent") else {
            throw ReelMindError.invalidURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.timeoutInterval = 15.0
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(apiKey.trimmingCharacters(in: .whitespacesAndNewlines), forHTTPHeaderField: "x-goog-api-key")
        let payload: [String: Any] = [
            "contents": [["parts": [["text": "ping"]]]]
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
    }

    // MARK: - Internal HTTP Client with Automatic Model Failover & Exponential Backoff

    private let fallbackModels = [
        "gemini-3.5-flash-lite",
        "gemini-3.5-flash",
        "gemini-3.8-flash",
        "gemini-3.1-flash-lite"
    ]

    private func callGemini(systemInstruction: String, prompt: String, enforceJSON: Bool) async throws -> String {
        // Enforce rate limiting (Punto 19)
        try await rateLimiter.checkRateLimit()

        var userModel = UserDefaults.standard.string(forKey: "gemini_model") ?? "gemini-3.5-flash-lite"
        if userModel.contains("2.5") {
            userModel = "gemini-3.5-flash-lite"
            UserDefaults.standard.set(userModel, forKey: "gemini_model")
        }

        var modelsToTry = [userModel]
        for fb in fallbackModels where fb != userModel {
            modelsToTry.append(fb)
        }

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

        let httpBody = try JSONSerialization.data(withJSONObject: payload)
        var lastError: Error?

        for currentModel in modelsToTry {
            let endpointString = "https://generativelanguage.googleapis.com/v1beta/models/\(currentModel):generateContent"
            guard let url = URL(string: endpointString) else { continue }

            var backoffSeconds: UInt64 = 1_000_000_000 // 1s
            let maxAttempts = 2

            for attempt in 1...maxAttempts {
                var request = URLRequest(url: url)
                request.httpMethod = "POST"
                request.timeoutInterval = 25.0
                request.setValue("application/json", forHTTPHeaderField: "Content-Type")
                request.setValue(apiKey.trimmingCharacters(in: .whitespacesAndNewlines), forHTTPHeaderField: "x-goog-api-key")
                request.httpBody = httpBody

                do {
                    let (data, response) = try await session.data(for: request)
                    guard let httpResponse = response as? HTTPURLResponse else {
                        throw ReelMindError.invalidResponse(statusCode: -1)
                    }

                    if (200...299).contains(httpResponse.statusCode) {
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

                    // Parse Google API error message
                    let errorMessage: String
                    if let errorObj = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                       let errorInfo = errorObj["error"] as? [String: Any],
                       let msg = errorInfo["message"] as? String {
                        errorMessage = msg
                    } else {
                        errorMessage = "HTTP \(httpResponse.statusCode)"
                    }

                    // Check if error is temporary (503 High Demand, 429 Rate Limit, 404 Model Not Found, overload)
                    let isTemporary = httpResponse.statusCode == 503 ||
                                      httpResponse.statusCode == 429 ||
                                      httpResponse.statusCode == 404 ||
                                      errorMessage.lowercased().contains("high demand") ||
                                      errorMessage.lowercased().contains("quota") ||
                                      errorMessage.lowercased().contains("temporar")

                    if isTemporary {
                        lastError = ReelMindError.serverError(message: "Gemini API (\(currentModel)): \(errorMessage)")
                        if attempt < maxAttempts {
                            try? await Task.sleep(nanoseconds: backoffSeconds)
                            backoffSeconds *= 2
                            continue
                        }
                        // Break attempt loop to failover to next fallback model immediately
                        break
                    } else {
                        throw ReelMindError.serverError(message: "Gemini API: \(errorMessage)")
                    }
                } catch {
                    lastError = error
                    // If timeout, break attempt loop to failover immediately to next fallback model
                    if let urlErr = error as? URLError, urlErr.code == .timedOut {
                        break
                    }
                    if let reelErr = error as? ReelMindError,
                       case .serverError(let msg) = reelErr,
                       !msg.lowercased().contains("high demand") && !msg.contains("503") && !msg.contains("429") {
                        throw error
                    }
                    if attempt < maxAttempts {
                        try? await Task.sleep(nanoseconds: backoffSeconds)
                        backoffSeconds *= 2
                    }
                }
            }
        }

        if let finalErr = lastError {
            throw finalErr
        }
        let fallbackMsg = isCurrentLanguageSpanish
            ? "Los motores de Gemini están experimentando alta demanda. Por favor intenta de nuevo en unos momentos."
            : "Gemini AI engines are currently experiencing high demand. Please try again shortly."
        throw ReelMindError.serverError(message: fallbackMsg)
    }
}

// MARK: - Thread-Safe Rate Limiter Actor (Punto 19)

private actor RateLimiter {
    private let minInterval: TimeInterval
    private var lastRequestTime: Date = .distantPast

    init(minIntervalSeconds: TimeInterval) {
        self.minInterval = minIntervalSeconds
    }

    func checkRateLimit() throws {
        let now = Date()
        let elapsed = now.timeIntervalSince(lastRequestTime)
        if elapsed < minInterval {
            let remaining = String(format: "%.1f", minInterval - elapsed)
            SecurityAuditLogger.shared.log(
                event: "Rapid API request throttled. Cooldown remaining: \(remaining)s",
                severity: .warning
            )
            let errorMsg = Locale.current.language.languageCode?.identifier == "es"
                ? "Límite de velocidad: por favor espera \(remaining)s antes de consultar de nuevo."
                : "Rate limit: please wait \(remaining)s before requesting again."
            throw ReelMindError.serverError(message: errorMsg)
        }
        lastRequestTime = now
    }
}

