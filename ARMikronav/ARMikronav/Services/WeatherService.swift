// WeatherService.swift
// ARMikronav
//
// Lädt das aktuelle Wetter für den Standort des Users über die Open-Meteo-API
// (kostenlos, kein API-Key nötig – passt zum Secrets-freien AppConfig-Ansatz).
// Zusätzlich Reverse-Geocoding via CLGeocoder für den Ortsnamen im Homescreen.

import Foundation
import CoreLocation

/// Aktuelles Wetter an einer Koordinate (Ausschnitt der Open-Meteo-Antwort).
struct CurrentWeather: Equatable {
    let temperatureC: Double
    let weatherCode: Int
    let windSpeedKmh: Double
    let isDay: Bool

    /// SF-Symbol passend zum WMO-Wettercode.
    var symbolName: String {
        switch weatherCode {
        case 0: return isDay ? "sun.max.fill" : "moon.stars.fill"
        case 1, 2: return isDay ? "cloud.sun.fill" : "cloud.moon.fill"
        case 3: return "cloud.fill"
        case 45, 48: return "cloud.fog.fill"
        case 51, 53, 55, 56, 57: return "cloud.drizzle.fill"
        case 61, 63, 65, 66, 67: return "cloud.rain.fill"
        case 71, 73, 75, 77: return "cloud.snow.fill"
        case 80, 81, 82: return "cloud.heavyrain.fill"
        case 85, 86: return "cloud.snow.fill"
        case 95, 96, 99: return "cloud.bolt.rain.fill"
        default: return "cloud.fill"
        }
    }

    /// Deutsche Kurzbeschreibung des WMO-Wettercodes.
    var localizedDescription: String {
        switch weatherCode {
        case 0: return "Klar"
        case 1: return "Überwiegend klar"
        case 2: return "Teilweise bewölkt"
        case 3: return "Bedeckt"
        case 45, 48: return "Nebel"
        case 51, 53, 55: return "Nieselregen"
        case 56, 57: return "Gefrierender Nieselregen"
        case 61, 63, 65: return "Regen"
        case 66, 67: return "Gefrierender Regen"
        case 71, 73, 75: return "Schneefall"
        case 77: return "Schneegriesel"
        case 80, 81, 82: return "Regenschauer"
        case 85, 86: return "Schneeschauer"
        case 95: return "Gewitter"
        case 96, 99: return "Gewitter mit Hagel"
        default: return "Wechselhaft"
        }
    }
}

enum WeatherServiceError: Error {
    case invalidURL
    case badResponse
}

final class WeatherService: Sendable {
    static let shared = WeatherService()

    private init() {}

    func fetchCurrentWeather(for coordinate: CLLocationCoordinate2D) async throws -> CurrentWeather {
        var components = URLComponents(string: "https://api.open-meteo.com/v1/forecast")
        components?.queryItems = [
            URLQueryItem(name: "latitude", value: String(format: "%.4f", coordinate.latitude)),
            URLQueryItem(name: "longitude", value: String(format: "%.4f", coordinate.longitude)),
            URLQueryItem(name: "current", value: "temperature_2m,weather_code,wind_speed_10m,is_day"),
            URLQueryItem(name: "timezone", value: "auto")
        ]
        guard let url = components?.url else {
            throw WeatherServiceError.invalidURL
        }

        let (data, response) = try await URLSession.shared.data(from: url)
        guard let http = response as? HTTPURLResponse, http.statusCode == 200 else {
            throw WeatherServiceError.badResponse
        }

        let decoded = try JSONDecoder().decode(OpenMeteoResponse.self, from: data)
        return CurrentWeather(
            temperatureC: decoded.current.temperature2m,
            weatherCode: decoded.current.weatherCode,
            windSpeedKmh: decoded.current.windSpeed10m,
            isDay: decoded.current.isDay == 1
        )
    }

    /// Ortsname (Quartier bzw. Stadt) zur Koordinate, nil wenn das
    /// Reverse-Geocoding fehlschlägt – die UI zeigt dann nur das Wetter.
    func placeName(for coordinate: CLLocationCoordinate2D) async -> String? {
        let location = CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)
        let placemark = try? await CLGeocoder().reverseGeocodeLocation(location).first
        return placemark?.subLocality ?? placemark?.locality
    }
}

// MARK: - Open-Meteo DTO

private struct OpenMeteoResponse: Decodable {
    let current: Current

    struct Current: Decodable {
        let temperature2m: Double
        let weatherCode: Int
        let windSpeed10m: Double
        let isDay: Int

        enum CodingKeys: String, CodingKey {
            case temperature2m = "temperature_2m"
            case weatherCode = "weather_code"
            case windSpeed10m = "wind_speed_10m"
            case isDay = "is_day"
        }
    }
}
