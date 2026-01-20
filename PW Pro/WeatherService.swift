import Foundation

final class WeatherService {
    private let apiKey: String?

    init(apiKey: String? = nil) {
        self.apiKey = apiKey ?? UserDefaults.standard.string(forKey: "OpenWeatherAPIKey")
    }

    enum WeatherError: Error {
        case missingAPIKey
        case invalidResponse
        case decodingError(Error)
        case network(Error)
    }

    func fetchCurrentWeather(zip: String, completion: @escaping (Result<WeatherSnapshot, Error>) -> Void) {
        guard let key = apiKey, !key.isEmpty else {
            // fallback mock data when no API key configured
            let mock = WeatherSnapshot(temperatureF: 72, windSpeedMph: 5, description: "Clear")
            completion(.success(mock))
            return
        }

        var components = URLComponents(string: "https://api.openweathermap.org/data/2.5/weather")!
        components.queryItems = [
            URLQueryItem(name: "zip", value: "\(zip),us"),
            URLQueryItem(name: "appid", value: key),
            URLQueryItem(name: "units", value: "imperial")
        ]

        guard let url = components.url else { completion(.failure(WeatherError.invalidResponse)); return }

        let task = URLSession.shared.dataTask(with: url) { data, resp, err in
            if let err = err {
                completion(.failure(WeatherError.network(err)))
                return
            }
            guard let data = data else { completion(.failure(WeatherError.invalidResponse)); return }

            do {
                if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any] {
                    guard let main = json["main"] as? [String: Any], let wind = json["wind"] as? [String: Any] else {
                        completion(.failure(WeatherError.invalidResponse)); return
                    }
                    let temp = main["temp"] as? Double ?? 0
                    // OpenWeather returns wind speed in meter/sec; but with units=imperial it returns mph
                    let windSpeed = wind["speed"] as? Double ?? 0
                    let weatherArr = json["weather"] as? [[String: Any]]
                    let desc = weatherArr?.first?["description"] as? String ?? weatherArr?.first?["main"] as? String
                    let snapshot = WeatherSnapshot(temperatureF: temp, windSpeedMph: windSpeed, description: desc)
                    completion(.success(snapshot))
                    return
                } else {
                    completion(.failure(WeatherError.invalidResponse))
                }
            } catch {
                completion(.failure(WeatherError.decodingError(error)))
            }
        }
        task.resume()
    }
}
