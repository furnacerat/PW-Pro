import Foundation
import Combine
import CoreLocation

struct ScheduleItem: Identifiable, Codable, Hashable {
    var id = UUID()
    var ownerName: String
    var address: String
    var scope: String
    var date: Date
    var estimateID: UUID? = nil
    var latitude: Double? = nil
    var longitude: Double? = nil
}

final class ScheduleStore: ObservableObject {
    @Published var items: [ScheduleItem] = []

    private var autosaveCancellable: AnyCancellable?
    private let fileName = "schedule.json"
    private let geocoder = CLGeocoder()

    init() {
        load()
        autosaveCancellable = $items
            .dropFirst()
            .debounce(for: .seconds(0.3), scheduler: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.save()
            }
    }

    deinit {
        autosaveCancellable?.cancel()
    }

    func add(_ item: ScheduleItem) {
        items.append(item)
        geocodeAddress(for: item.id)
    }

    func remove(id: UUID) {
        items.removeAll { $0.id == id }
    }

    /// Geocode an item by id and update its coordinates when resolved.
    func geocodeAddress(for id: UUID) {
        guard let idx = items.firstIndex(where: { $0.id == id }) else { return }
        let address = items[idx].address
        guard !address.isEmpty else { return }

        geocoder.geocodeAddressString(address) { [weak self] placemarks, error in
            DispatchQueue.main.async {
                guard let self = self else { return }
                if let error = error {
                    print("Geocode error for \(address): \(error)")
                    return
                }
                guard let loc = placemarks?.first?.location else { return }
                if let foundIdx = self.items.firstIndex(where: { $0.id == id }) {
                    self.items[foundIdx].latitude = loc.coordinate.latitude
                    self.items[foundIdx].longitude = loc.coordinate.longitude
                }
            }
        }
    }

    /// Geocode any items missing coordinates.
    func geocodeAllMissing() {
        for item in items where item.latitude == nil || item.longitude == nil {
            geocodeAddress(for: item.id)
        }
    }

    /// Batch geocode all items (or missing only) sequentially and return a textual report.
    func batchGeocodeAllAndReport(force: Bool = false, completion: @escaping ([String]) -> Void) {
        let toProcess: [ScheduleItem]
        if force {
            toProcess = items
        } else {
            toProcess = items.filter { $0.latitude == nil || $0.longitude == nil }
        }

        var reports: [String] = []
        var idx = 0

        func geocodeNext() {
            if idx >= toProcess.count {
                completion(reports)
                return
            }
            let item = toProcess[idx]
            geocoder.geocodeAddressString(item.address) { [weak self] placemarks, error in
                DispatchQueue.main.async {
                    if let error = error {
                        reports.append("FAILED: \(item.address) — \(error.localizedDescription)")
                    } else if let loc = placemarks?.first?.location {
                        reports.append("OK: \(item.address) -> \(loc.coordinate.latitude),\(loc.coordinate.longitude)")
                        if let self = self, let mainIdx = self.items.firstIndex(where: { $0.id == item.id }) {
                            self.items[mainIdx].latitude = loc.coordinate.latitude
                            self.items[mainIdx].longitude = loc.coordinate.longitude
                        }
                    } else {
                        reports.append("NO RESULT: \(item.address)")
                    }
                    idx += 1
                    // small delay to be gentle on geocoding service
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) { geocodeNext() }
                }
            }
        }

        if toProcess.isEmpty {
            completion(["No addresses to geocode."])
            return
        }
        geocodeNext()
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
            let list = try decoder.decode([ScheduleItem].self, from: data)
            DispatchQueue.main.async {
                self.items = list
                self.geocodeAllMissing()
            }
        } catch {
            print("Failed to load schedule from disk: \(error)")
        }
    }

    func save() {
        guard let url = storageURL() else { return }
        do {
            let encoder = JSONEncoder()
            encoder.outputFormatting = [.prettyPrinted]
            encoder.dateEncodingStrategy = .iso8601
            let data = try encoder.encode(items)
            try data.write(to: url, options: .atomic)
        } catch {
            print("Failed to save schedule to disk: \(error)")
        }
    }
}
