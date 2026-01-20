import Foundation

struct WeatherSnapshot: Codable {
    var temperatureF: Double
    var windSpeedMph: Double
    var description: String?
}
