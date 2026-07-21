// WeatherService.swift
// ARMikronav
//
// Lädt das aktuelle Wetter für den Standort des Users über die OpenWeather
// One Call API 3.0 (liefert neben Temperatur/Wind auch UV-Index, gefühlte
// Temperatur und Luftfeuchtigkeit; deutsche Beschreibungen via lang=de).
// Der API-Key liegt in Secrets.swift (openWeatherAPIKey).
// Zusätzlich Reverse-Geocoding via CLGeocoder für den Ortsnamen im Homescreen.

import Foundation
import CoreLocation

/// Aktuelles Wetter an einer Koordinate (Ausschnitt der One-Call-Antwort).
struct CurrentWeather: Equatable {
    let temperatureC: Double
    let feelsLikeC: Double
    let humidityPercent: Int
    let uvIndex: Double
    let windSpeedKmh: Double
    /// OpenWeather Condition-ID (z. B. 800 = klar).
    let conditionId: Int
    /// Deutsche Kurzbeschreibung aus der API (z. B. "Mäßig bewölkt").
    let conditionDescription: String
    let isDay: Bool

    /// SF-Symbol passend zur OpenWeather-Condition-ID.
    var symbolName: String {
        switch conditionId {
        case 200...232: return "cloud.bolt.rain.fill"
        case 300...321: return "cloud.drizzle.fill"
        case 511: return "cloud.sleet.fill"
        case 520...531: return "cloud.heavyrain.fill"
        case 500...504: return "cloud.rain.fill"
        case 600...622: return "cloud.snow.fill"
        case 701...771: return "cloud.fog.fill"
        case 781: return "tornado"
        case 800: return isDay ? "sun.max.fill" : "moon.stars.fill"
        case 801, 802: return isDay ? "cloud.sun.fill" : "cloud.moon.fill"
        case 803, 804: return "cloud.fill"
        default: return "cloud.fill"
        }
    }

    /// UV-Index-Kategorie nach WHO-Skala.
    var uvCategory: String {
        switch uvIndex {
        case ..<3: return "niedrig"
        case ..<6: return "mässig"
        case ..<8: return "hoch"
        case ..<11: return "sehr hoch"
        default: return "extrem"
        }
    }
}

enum WeatherServiceError: Error {
    case missingAPIKey
    case invalidURL
    case badResponse
    case emptyResponse
}

final class WeatherService: Sendable {
    static let shared = WeatherService()

    private init() {}

    func fetchCurrentWeather(for coordinate: CLLocationCoordinate2D) async throws -> CurrentWeather {
        let apiKey = Secrets.openWeatherAPIKey
        guard !apiKey.isEmpty, apiKey != "YOUR_OPENWEATHER_API_KEY" else {
            throw WeatherServiceError.missingAPIKey
        }

        var components = URLComponents(string: "https://api.openweathermap.org/data/3.0/onecall")
        components?.queryItems = [
            URLQueryItem(name: "lat", value: String(format: "%.4f", coordinate.latitude)),
            URLQueryItem(name: "lon", value: String(format: "%.4f", coordinate.longitude)),
            URLQueryItem(name: "exclude", value: "minutely,hourly,daily,alerts"),
            URLQueryItem(name: "units", value: "metric"),
            URLQueryItem(name: "lang", value: "de"),
            URLQueryItem(name: "appid", value: apiKey)
        ]
        guard let url = components?.url else {
            throw WeatherServiceError.invalidURL
        }

        let (data, response) = try await URLSession.shared.data(from: url)
        guard let http = response as? HTTPURLResponse, http.statusCode == 200 else {
            throw WeatherServiceError.badResponse
        }

        let decoded = try JSONDecoder().decode(OneCallResponse.self, from: data)
        guard let condition = decoded.current.weather.first else {
            throw WeatherServiceError.emptyResponse
        }

        return CurrentWeather(
            temperatureC: decoded.current.temp,
            feelsLikeC: decoded.current.feelsLike,
            humidityPercent: decoded.current.humidity,
            uvIndex: decoded.current.uvi,
            // units=metric liefert Wind in m/s → km/h für die Anzeige.
            windSpeedKmh: decoded.current.windSpeed * 3.6,
            conditionId: condition.id,
            conditionDescription: condition.description.prefix(1).uppercased()
                + String(condition.description.dropFirst()),
            isDay: condition.icon.hasSuffix("d")
        )
    }

    /// Ortsname (Quartier bzw. Stadt) zur Koordinate, nil wenn das
    /// Reverse-Geocoding fehlschlägt – die UI zeigt dann nur das Wetter.
    func placeName(for coordinate: CLLocationCoordinate2D) async -> String? {
        let location = CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)
        let placemark = try? await CLGeocoder().reverseGeocodeLocation(location).first
        return placemark?.locality ?? placemark?.subLocality
    }
}

// MARK: - OpenWeather One Call 3.0 DTO

private struct OneCallResponse: Decodable {
    let current: Current

    struct Current: Decodable {
        let temp: Double
        let feelsLike: Double
        let humidity: Int
        let uvi: Double
        let windSpeed: Double
        let weather: [Condition]

        enum CodingKeys: String, CodingKey {
            case temp, humidity, uvi, weather
            case feelsLike = "feels_like"
            case windSpeed = "wind_speed"
        }
    }

    struct Condition: Decodable {
        let id: Int
        let description: String
        let icon: String
    }
}