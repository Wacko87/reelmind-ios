import UIKit
import SwiftUI
import UniformTypeIdentifiers

@objc(ShareViewController)
final class ShareViewController: UIViewController {
    private var detectedURL: String = ""

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = UIColor.black.withAlphaComponent(0.4)
        extractSharedURL()
    }

    private func extractSharedURL() {
        guard let items = extensionContext?.inputItems as? [NSExtensionItem] else {
            presentShareView()
            return
        }

        for item in items {
            guard let attachments = item.attachments else { continue }
            for provider in attachments {
                if provider.hasItemConformingToTypeIdentifier(UTType.url.identifier) {
                    provider.loadItem(forTypeIdentifier: UTType.url.identifier, options: nil) { [weak self] (url, _) in
                        if let shareURL = url as? URL {
                            DispatchQueue.main.async {
                                self?.detectedURL = shareURL.absoluteString
                                self?.presentShareView()
                            }
                        }
                    }
                    return
                } else if provider.hasItemConformingToTypeIdentifier(UTType.plainText.identifier) {
                    provider.loadItem(forTypeIdentifier: UTType.plainText.identifier, options: nil) { [weak self] (text, _) in
                        if let rawText = text as? String {
                            let extracted = self?.extractURL(from: rawText) ?? rawText
                            DispatchQueue.main.async {
                                self?.detectedURL = extracted
                                self?.presentShareView()
                            }
                        }
                    }
                    return
                }
            }
        }

        presentShareView()
    }

    private func extractURL(from text: String) -> String {
        let detector = try? NSDataDetector(types: NSTextCheckingResult.CheckingType.link.rawValue)
        let matches = detector?.matches(in: text, options: [], range: NSRange(location: 0, length: text.utf16.count))
        if let firstMatch = matches?.first, let range = Range(firstMatch.range, in: text) {
            return String(text[range])
        }
        return text.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private func presentShareView() {
        let shareView = ShareView(
            urlString: detectedURL,
            onDismiss: { [weak self] in
                self?.completeExtension()
            },
            onSubmit: { [weak self] url in
                await self?.saveSharedContent(url: url) ?? .failure(NSError(domain: "ReelMind", code: -1, userInfo: [NSLocalizedDescriptionKey: "Failed"]))
            }
        )

        let hostingController = UIHostingController(rootView: shareView)
        hostingController.view.backgroundColor = .clear

        addChild(hostingController)
        hostingController.view.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(hostingController.view)

        NSLayoutConstraint.activate([
            hostingController.view.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            hostingController.view.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            hostingController.view.centerYAnchor.constraint(equalTo: view.centerYAnchor)
        ])

        hostingController.didMove(toParent: self)
    }

    private func saveSharedContent(url: String) async -> Result<String, Error> {
        let useServer = UserDefaults.standard.bool(forKey: "reelmind_use_server_mode")

        if useServer {
            let baseURL = UserDefaults.standard.string(forKey: "reelmind_server_url") ?? ""
            guard !baseURL.isEmpty, let endpoint = URL(string: "\(baseURL.trimmingCharacters(in: CharacterSet(charactersIn: "/")))/api/reels/analyze") else {
                return .failure(NSError(domain: "ReelMind", code: 400, userInfo: [NSLocalizedDescriptionKey: "Please configure server URL in Settings"]))
            }

            var request = URLRequest(url: endpoint)
            request.httpMethod = "POST"
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")

            let token = UserDefaults.standard.string(forKey: "reelmind_api_token") ?? ""
            if !token.isEmpty {
                request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
            }

            let body: [String: Any] = ["url": url, "media_type": "auto"]
            guard let jsonData = try? JSONSerialization.data(withJSONObject: body) else {
                return .failure(NSError(domain: "ReelMind", code: 400, userInfo: [NSLocalizedDescriptionKey: "Invalid request payload"]))
            }
            request.httpBody = jsonData

            do {
                let (data, response) = try await URLSession.shared.data(for: request)
                guard let httpResponse = response as? HTTPURLResponse, (200...299).contains(httpResponse.statusCode) else {
                    return .failure(NSError(domain: "ReelMind", code: 500, userInfo: [NSLocalizedDescriptionKey: "Server error occurred"]))
                }
                if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                   let title = json["title"] as? String {
                    return .success(title)
                }
                return .success("Analyzed successfully")
            } catch {
                return .failure(error)
            }
        } else {
            // Local-First / Standalone mode: calls Gemini directly and saves locally!
            do {
                let reel = try await GeminiService.shared.analyzeContent(urlOrText: url)
                LocalVaultService.shared.addOrUpdateReel(reel)
                return .success(reel.title)
            } catch {
                return .failure(error)
            }
        }
    }

    private func completeExtension() {
        extensionContext?.completeRequest(returningItems: nil, completionHandler: nil)
    }
}
