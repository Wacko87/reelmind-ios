import Foundation
import OSLog

public final class SecurityAuditLogger: Sendable {
    public static let shared = SecurityAuditLogger()
    private let logger = Logger(subsystem: "com.reelmind.app", category: "SecurityAudit")

    private init() {}

    public enum LogSeverity: Sendable {
        case info
        case warning
        case critical
    }

    public func log(event: String, severity: LogSeverity = .warning) {
        switch severity {
        case .info:
            logger.info("🛡️ [SECURITY INFO]: \(event, privacy: .public)")
        case .warning:
            logger.warning("⚠️ [SECURITY WARNING]: \(event, privacy: .public)")
        case .critical:
            logger.critical("🚨 [SECURITY CRITICAL]: \(event, privacy: .public)")
        }
    }
}
