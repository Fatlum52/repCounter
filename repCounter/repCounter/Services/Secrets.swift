import Foundation

/// Reads API keys from Secrets.plist (not checked into git).
enum Secrets {
    private static let secrets: [String: Any] = {
        guard let url = Bundle.main.url(forResource: "Secrets", withExtension: "plist"),
              let data = try? Data(contentsOf: url),
              let dict = try? PropertyListSerialization.propertyList(from: data, format: nil) as? [String: Any]
        else {
            print("⚠️ Secrets.plist not found – API calls will fail.")
            return [:]
        }
        return dict
    }()

    static var rapidAPIKey: String {
        secrets["RAPIDAPI_KEY"] as? String ?? ""
    }
}
