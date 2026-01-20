import Foundation
import Combine

final class WeatherStore: ObservableObject {
    @Published var current: WeatherSnapshot?
    @Published var lastUpdated: Date?
    @Published var isLoading: Bool = false

    private let service: WeatherService
    private var cancellables = Set<AnyCancellable>()

    init(service: WeatherService = WeatherService()) {
        self.service = service
    }

    func fetch(zip: String) {
        guard !zip.isEmpty else { return }
        isLoading = true
        service.fetchCurrentWeather(zip: zip) { [weak self] result in
            DispatchQueue.main.async {
                self?.isLoading = false
                switch result {
                case .success(let snap):
                    self?.current = snap
                    self?.lastUpdated = Date()
                case .failure(let err):
                    print("Weather fetch error: \(err)")
                }
            }
        }
    }
}
