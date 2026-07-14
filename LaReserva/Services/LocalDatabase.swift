import Foundation

class LocalDatabase: ObservableObject {
    static let shared = LocalDatabase()

    private let defaults = UserDefaults.standard

    private init() {}

    // MARK: - Settings
    func getString(_ key: String) -> String? {
        defaults.string(forKey: key)
    }

    func setString(_ key: String, value: String) {
        defaults.set(value, forKey: key)
    }

    func getBool(_ key: String) -> Bool {
        defaults.bool(forKey: key)
    }

    func setBool(_ key: String, value: Bool) {
        defaults.set(value, forKey: key)
    }

    func getDouble(_ key: String) -> Double {
        defaults.double(forKey: key)
    }

    func setDouble(_ key: String, value: Double) {
        defaults.set(value, forKey: key)
    }

    func remove(_ key: String) {
        defaults.removeObject(forKey: key)
    }

    // MARK: - Cache
    func cacheData<T: Encodable>(_ data: T, forKey key: String) {
        if let encoded = try? JSONEncoder().encode(data) {
            defaults.set(encoded, forKey: key)
        }
    }

    func getCachedData<T: Decodable>(_ type: T.Type, forKey key: String) -> T? {
        guard let data = defaults.data(forKey: key) else { return nil }
        return try? JSONDecoder().decode(type, from: data)
    }
}
