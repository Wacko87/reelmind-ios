import Foundation
import Observation

@Observable
@MainActor
public final class IngestionViewModel {
    public var urlInput: String = ""
    public var selectedFolderId: String? = nil
    public var orgId: String? = nil
    public var isAnalyzing: Bool = false
    public var analyzedReel: Reel? = nil
    public var errorMessage: String? = nil

    private let repository: VaultRepository

    public init(repository: VaultRepository = .shared) {
        self.repository = repository
    }

    public func analyze() async -> Bool {
        let trimmed = urlInput.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            errorMessage = "Please enter or paste a valid link from Instagram, TikTok, YouTube or X."
            return false
        }

        // Security Validation (Punto 13): Length, Scheme & Host Sanitization
        if let validationError = validateURL(trimmed) {
            errorMessage = validationError
            return false
        }

        isAnalyzing = true
        errorMessage = nil
        analyzedReel = nil

        do {
            let result = try await repository.analyzeReel(url: trimmed, folderId: selectedFolderId, orgId: orgId)
            self.analyzedReel = result
            self.isAnalyzing = false
            return true
        } catch {
            self.errorMessage = error.localizedDescription
            self.isAnalyzing = false
            return false
        }
    }

    public func reset() {
        urlInput = ""
        analyzedReel = nil
        errorMessage = nil
        isAnalyzing = false
    }

    // MARK: - Security Sanitization & Validation

    private static let maxURLLength: Int = 2048

    private func validateURL(_ string: String) -> String? {
        guard string.count <= Self.maxURLLength else {
            SecurityAuditLogger.shared.log(event: "Blocked oversized ingestion input: \(string.count) characters.", severity: .warning)
            return "URL exceeds maximum allowed length (2048 characters)."
        }
        guard let url = URL(string: string),
              let scheme = url.scheme?.lowercased(),
              let host = url.host?.lowercased(),
              !host.isEmpty else {
            SecurityAuditLogger.shared.log(event: "Malformed URL rejected: \(string.prefix(40))", severity: .info)
            return "Please enter a valid web URL."
        }
        guard scheme == "https" || scheme == "http" else {
            SecurityAuditLogger.shared.log(event: "Dangerous URL scheme blocked: \(scheme)", severity: .critical)
            return "Only secure HTTP/HTTPS links are supported."
        }
        // Disallow loopback / internal network probes (SSRF prevention)
        if host == "localhost" || host == "127.0.0.1" || host.starts(with: "192.168.") || host.starts(with: "10.") || host.starts(with: "172.") {
            SecurityAuditLogger.shared.log(event: "Blocked internal network SSRF attempt to host: \(host)", severity: .critical)
            return "Local and internal network addresses are not allowed."
        }
        return nil
    }
}
