import Foundation
import Combine

final class EstimatesStore: ObservableObject {
    @Published var estimates: [Estimate] = []

    private var autosaveCancellable: AnyCancellable?
    private let fileName = "estimates.json"

    init() {
        load()
        autosaveCancellable = $estimates
            .dropFirst()
            .debounce(for: .seconds(0.3), scheduler: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.save()
            }
    }

    deinit {
        autosaveCancellable?.cancel()
    }

    private func storageURL() -> URL? {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first?.appendingPathComponent(fileName)
    }

    func load() {
        guard let url = storageURL(), FileManager.default.fileExists(atPath: url.path) else { return }
        do {
            let data = try Data(contentsOf: url)
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            let list = try decoder.decode([Estimate].self, from: data)
            DispatchQueue.main.async {
                self.estimates = list
            }
        } catch {
            print("Failed to load estimates from disk: \(error)")
        }
    }

    func save() {
        guard let url = storageURL() else { return }
        do {
            let encoder = JSONEncoder()
            encoder.outputFormatting = [.prettyPrinted]
            encoder.dateEncodingStrategy = .iso8601
            let data = try encoder.encode(estimates)
            // write atomically
            try data.write(to: url, options: .atomic)
        } catch {
            print("Failed to save estimates to disk: \(error)")
        }
    }
}
