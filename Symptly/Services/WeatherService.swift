import Foundation
import SwiftUI
import CoreLocation

// MARK: - Open-Meteo API Response Models
private struct OpenMeteoResponse: Codable {
    let current: CurrentWeather

    struct CurrentWeather: Codable {
        let temperature2m: Double
        let relativeHumidity2m: Int
        let surfacePressure: Double
        let weatherCode: Int

        enum CodingKeys: String, CodingKey {
            case temperature2m = "temperature_2m"
            case relativeHumidity2m = "relative_humidity_2m"
            case surfacePressure = "surface_pressure"
            case weatherCode = "weather_code"
        }
    }
}

// MARK: - Weather Service

@MainActor
final class WeatherService: NSObject, ObservableObject {

    // MARK: Published Properties

    @Published var temperature: Double?
    @Published var humidity: Int?
    @Published var pressure: Double?
    @Published var weatherCode: Int?
    @Published var weatherDescription: String = "Unknown"

    // MARK: Location

    private let locationManager = CLLocationManager()
    private var locationContinuation: CheckedContinuation<CLLocation, Error>?

    // MARK: Computed Properties

    /// Returns an SF-symbol-style icon name based on the current weather code.
    var weatherIcon: String {
        guard let code = weatherCode else { return "ss.weather.unknown" }
        switch code {
        case 0:
            return "ss.weather.clear"
        case 1...3:
            return "ss.weather.cloudy"
        case 45, 48:
            return "ss.weather.fog"
        case 51...55:
            return "ss.weather.drizzle"
        case 56, 57:
            return "ss.weather.drizzle"
        case 61...65:
            return "ss.weather.rain"
        case 66, 67:
            return "ss.weather.rain"
        case 71...75:
            return "ss.weather.snow"
        case 77:
            return "ss.weather.snow"
        case 80...82:
            return "ss.weather.showers"
        case 85, 86:
            return "ss.weather.snow"
        case 95:
            return "ss.weather.thunderstorm"
        case 96, 99:
            return "ss.weather.thunderstorm"
        default:
            return "ss.weather.unknown"
        }
    }

    // MARK: Initializer

    override init() {
        super.init()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyKilometer
    }

    // MARK: Public Methods

    /// Fetches current weather for the user's location using the Open-Meteo API.
    func fetchCurrentWeather() async {
        do {
            let location = try await requestLocation()
            let lat = location.coordinate.latitude
            let lon = location.coordinate.longitude

            let urlString = "https://api.open-meteo.com/v1/forecast?latitude=\(lat)&longitude=\(lon)&current=temperature_2m,relative_humidity_2m,surface_pressure,weather_code&timezone=auto"

            guard let url = URL(string: urlString) else { return }

            let (data, _) = try await URLSession.shared.data(from: url)
            let response = try JSONDecoder().decode(OpenMeteoResponse.self, from: data)

            temperature = response.current.temperature2m
            humidity = response.current.relativeHumidity2m
            pressure = response.current.surfacePressure
            weatherCode = response.current.weatherCode
            weatherDescription = weatherCodeToDescription(response.current.weatherCode)
        } catch {
            print("[WeatherService] Failed to fetch weather: \(error.localizedDescription)")
        }
    }

    /// Maps a WMO weather code to a human-readable description.
    func weatherCodeToDescription(_ code: Int) -> String {
        switch code {
        case 0:
            return "Clear"
        case 1:
            return "Mainly clear"
        case 2:
            return "Partly cloudy"
        case 3:
            return "Overcast"
        case 45:
            return "Fog"
        case 48:
            return "Depositing rime fog"
        case 51:
            return "Light drizzle"
        case 53:
            return "Moderate drizzle"
        case 55:
            return "Dense drizzle"
        case 56:
            return "Light freezing drizzle"
        case 57:
            return "Dense freezing drizzle"
        case 61:
            return "Slight rain"
        case 63:
            return "Moderate rain"
        case 65:
            return "Heavy rain"
        case 66:
            return "Light freezing rain"
        case 67:
            return "Heavy freezing rain"
        case 71:
            return "Slight snow"
        case 73:
            return "Moderate snow"
        case 75:
            return "Heavy snow"
        case 77:
            return "Snow grains"
        case 80:
            return "Slight showers"
        case 81:
            return "Moderate showers"
        case 82:
            return "Violent showers"
        case 85:
            return "Slight snow showers"
        case 86:
            return "Heavy snow showers"
        case 95:
            return "Thunderstorm"
        case 96:
            return "Thunderstorm with slight hail"
        case 99:
            return "Thunderstorm with heavy hail"
        default:
            return "Unknown"
        }
    }

    // MARK: Private Helpers

    /// Requests the user's current location, handling authorization along the way.
    private func requestLocation() async throws -> CLLocation {
        let status = locationManager.authorizationStatus

        switch status {
        case .notDetermined:
            locationManager.requestWhenInUseAuthorization()
            // Wait briefly for the authorization callback, then request location.
            try await Task.sleep(nanoseconds: 1_000_000_000)
            return try await requestSingleLocation()
        case .authorizedWhenInUse, .authorizedAlways:
            return try await requestSingleLocation()
        case .denied, .restricted:
            throw LocationError.permissionDenied
        @unknown default:
            throw LocationError.permissionDenied
        }
    }

    /// Wraps `CLLocationManager.requestLocation()` in an async continuation.
    private func requestSingleLocation() async throws -> CLLocation {
        return try await withCheckedThrowingContinuation { continuation in
            self.locationContinuation = continuation
            self.locationManager.requestLocation()
        }
    }

    // MARK: Errors

    enum LocationError: LocalizedError {
        case permissionDenied
        case locationUnavailable

        var errorDescription: String? {
            switch self {
            case .permissionDenied:
                return "Location permission was denied. Enable it in Settings to use weather features."
            case .locationUnavailable:
                return "Unable to determine your current location."
            }
        }
    }
}

// MARK: - CLLocationManagerDelegate

extension WeatherService: CLLocationManagerDelegate {

    nonisolated func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        Task { @MainActor in
            guard let location = locations.first else {
                locationContinuation?.resume(throwing: LocationError.locationUnavailable)
                locationContinuation = nil
                return
            }
            locationContinuation?.resume(returning: location)
            locationContinuation = nil
        }
    }

    nonisolated func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        Task { @MainActor in
            locationContinuation?.resume(throwing: error)
            locationContinuation = nil
        }
    }
}
