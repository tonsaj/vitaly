import Foundation

/// API Configuration
///
/// IMPORTANT: Replace the placeholder API key with your actual Gemini API key.
/// Get your free API key from: https://aistudio.google.com/app/apikey
///
/// For production, consider using:
/// - Environment variables
/// - Keychain storage
/// - Firebase Remote Config
/// - A backend proxy server
enum APIConfig {
    /// Gemini API Key from Google AI Studio
    /// Free tier: 15 RPM (requests per minute), 1M tokens/month
    /// Get yours at: https://aistudio.google.com/app/apikey
    static let geminiAPIKey: String = {
        // Try to load from environment variable first
        if let key = ProcessInfo.processInfo.environment["GEMINI_API_KEY"], !key.isEmpty {
            return key
        }

        // Try to load from Secrets.plist
        if let path = Bundle.main.path(forResource: "Secrets", ofType: "plist"),
           let dict = NSDictionary(contentsOfFile: path),
           let key = dict["GEMINI_API_KEY"] as? String, !key.isEmpty {
            return key
        }

        // Fallback - replace with your API key for development
        // WARNING: Do not commit real API keys to version control!
        return "YOUR_GEMINI_API_KEY_HERE"
    }()
}
