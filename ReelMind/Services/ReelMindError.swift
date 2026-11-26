import Foundation

public enum ReelMindError: LocalizedError, Sendable {
    case serverNotConfigured
    case invalidURL
    case unauthorized
    case invalidResponse(statusCode: Int)
    case serverError(message: String)
    case decodingError(message: String)
    case networkUnavailable

    public var errorDescription: String? {
        let isSpanish = Locale.current.language.languageCode?.identifier == "es"
        switch self {
        case .serverNotConfigured:
            return isSpanish
                ? "Por favor, configura la URL de tu servidor en la pestaña Ajustes."
                : "Please configure your ReelMind server URL in the Settings tab."
        case .invalidURL:
            return isSpanish
                ? "La dirección URL del servidor no es válida."
                : "The server URL provided is invalid."
        case .unauthorized:
            return isSpanish
                ? "Autenticación no autorizada. Por favor, comprueba tu PIN o usuario en Ajustes."
                : "Authentication failed. Please verify your PIN or username in Settings."
        case .invalidResponse(let statusCode):
            if statusCode == 404 {
                return isSpanish ? "Recurso no encontrado (404)." : "Resource not found (404)."
            } else if statusCode == 502 || statusCode == 503 {
                return isSpanish ? "El servidor no responde o está reiniciándose (HTTP \(statusCode))." : "Server unavailable (HTTP \(statusCode))."
            }
            return isSpanish ? "El servidor devolvió un código inesperado: HTTP \(statusCode)." : "Server returned an unexpected HTTP status: \(statusCode)."
        case .serverError(let message):
            if message.contains("empty media response") || (message.contains("[Instagram]") && message.contains("cookies")) {
                return isSpanish
                    ? "Instagram requiere inicio de sesión para acceder a este reel. El contenido pertenece a una cuenta privada, tiene restricción de edad o Meta ha bloqueado temporalmente el acceso público anónimo."
                    : "Instagram requires login to view this reel. The content is private, age-restricted, or Meta has restricted anonymous access."
            }
            if message.contains("yt-dlp") || message.contains("ERROR:") {
                var cleaned = message.replacingOccurrences(of: #"ERROR:\s*\[[^\]]+\]\s*[^:]*:\s*"#, with: "", options: .regularExpression)
                if let idx = cleaned.range(of: "Check if this post is accessible") {
                    cleaned = String(cleaned[..<idx.lowerBound])
                }
                if let idx = cleaned.range(of: "See https://") {
                    cleaned = String(cleaned[..<idx.lowerBound])
                }
                let trimmed = cleaned.trimmingCharacters(in: .whitespacesAndNewlines)
                if !trimmed.isEmpty {
                    return trimmed
                }
            }
            return message
        case .decodingError(let message):
            return isSpanish
                ? "Error al procesar la respuesta del servidor."
                : "Failed to parse server response: \(message)"
        case .networkUnavailable:
            return isSpanish
                ? "Sin conexión a internet. Comprueba tu red Wi-Fi o datos móviles."
                : "Network connection unavailable. Please check your connectivity."
        }
    }
}
