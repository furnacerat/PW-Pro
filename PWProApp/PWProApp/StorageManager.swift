import Foundation

@MainActor
class StorageManager {
    static let shared = StorageManager()
    
    private init() {}
    
    private func getDocumentsDirectory() -> URL {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
    }
    
    func save<T: Encodable>(_ data: T, to filename: String) {
        let url = getDocumentsDirectory().appendingPathComponent(filename)
        do {
            let encoded = try JSONEncoder().encode(data)
            try encoded.write(to: url, options: [.atomicWrite, .completeFileProtection])
            print("Successfully saved to \(filename)")
        } catch {
            print("Failed to save \(filename): \(error.localizedDescription)")
        }
    }
    
    func load<T: Decodable>(_ type: T.Type, from filename: String) -> T? {
        let url = getDocumentsDirectory().appendingPathComponent(filename)
        guard FileManager.default.fileExists(atPath: url.path) else {
            print("File not found: \(filename)")
            return nil
        }
        
        do {
            let data = try Data(contentsOf: url)
            let decoded = try JSONDecoder().decode(type, from: data)
            print("Successfully loaded \(filename)")
            return decoded
        } catch {
            print("Failed to load \(filename): \(error.localizedDescription)")
            return nil
        }
    }
}
