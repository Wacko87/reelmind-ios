import Foundation
import LocalAuthentication
import Observation
import UIKit

@Observable
@MainActor
public final class AppLockService {
    public static let shared = AppLockService()

    public var isLocked: Bool = false
    public var authenticationError: String? = nil
    public var isPermissionDenied: Bool = false

    public var isBiometricEnabled: Bool {
        get {
            UserDefaults.standard.bool(forKey: "biometric_lock_enabled")
        }
        set {
            UserDefaults.standard.set(newValue, forKey: "biometric_lock_enabled")
            if newValue {
                SecurityAuditLogger.shared.log(event: "Biometric App Lock enabled by user.", severity: .info)
            } else {
                SecurityAuditLogger.shared.log(event: "Biometric App Lock disabled by user.", severity: .warning)
            }
        }
    }

    private init() {
        if UserDefaults.standard.bool(forKey: "biometric_lock_enabled") {
            self.isLocked = true
        }
    }

    public func lock() {
        if isBiometricEnabled {
            isLocked = true
        }
    }

    @available(iOSApplicationExtension, unavailable)
    public func openSystemSettings() {
        if let url = URL(string: UIApplication.openSettingsURLString), UIApplication.shared.canOpenURL(url) {
            UIApplication.shared.open(url)
        }
    }

    public func emergencyUnlock() {
        self.isBiometricEnabled = false
        self.isLocked = false
        self.authenticationError = nil
        self.isPermissionDenied = false
        SecurityAuditLogger.shared.log(event: "App Lock emergency unlocked due to permission lockout.", severity: .warning)
    }

    public func authenticate() async {
        guard isBiometricEnabled else {
            isLocked = false
            return
        }

        let context = LAContext()
        context.localizedCancelTitle = "Cancel"
        var error: NSError?

        if context.canEvaluatePolicy(.deviceOwnerAuthentication, error: &error) {
            let reason = Locale.current.language.languageCode?.identifier == "es"
                ? "Desbloquea tu bóveda personal de ReelMind"
                : "Unlock your private ReelMind vault"

            do {
                let success = try await context.evaluatePolicy(.deviceOwnerAuthentication, localizedReason: reason)
                if success {
                    self.isLocked = false
                    self.authenticationError = nil
                    self.isPermissionDenied = false
                    SecurityAuditLogger.shared.log(event: "Biometric unlock successful.", severity: .info)
                }
            } catch {
                let nsError = error as NSError
                if nsError.domain == LAErrorDomain && (nsError.code == LAError.biometryNotAvailable.rawValue || nsError.code == 6 || nsError.code == -6) {
                    self.isPermissionDenied = true
                    self.authenticationError = Locale.current.language.languageCode?.identifier == "es"
                        ? "Permiso de Face ID desactivado. Actívalo en Ajustes de iOS > ReelMind."
                        : "Face ID permission denied. Enable it in iOS Settings > ReelMind."
                } else {
                    self.isPermissionDenied = false
                    self.authenticationError = error.localizedDescription
                }
                self.isLocked = true
                SecurityAuditLogger.shared.log(event: "Biometric unlock failed or cancelled: \(error.localizedDescription)", severity: .warning)
            }
        } else {
            // No biometrics or passcode enrolled on device
            self.isLocked = false
        }
    }
}
