import CoreLocation
import Foundation
import MapKit
import UIKit

/// Meteo e mappa al momento della partita (solo con localizzazione autorizzata).
struct ShareConditions {
    var mapImage: UIImage?
    var venueLabel: String
    var temperatureC: Int?
    var humidityPercent: Int?
    var airQualityIndex: Int?
}

@Observable
@MainActor
final class ShareConditionsLoader {
    var conditions: ShareConditions?

    func load(for match: MatchRecord) async {
        let coordinate: CLLocationCoordinate2D?
        if let stored = match.coordinate {
            coordinate = CLLocationCoordinate2D(latitude: stored.latitude, longitude: stored.longitude)
        } else if let location = await MatchLocationCapture.shared.requestLocation() {
            coordinate = location.coordinate
        } else {
            conditions = nil
            return
        }

        guard let coordinate else {
            conditions = nil
            return
        }

        let venue = venueLabel(for: match)
        async let mapImage = captureMap(at: coordinate)
        async let weather = fetchWeather(at: coordinate, date: match.date)
        let (map, weatherData) = await (mapImage, weather)

        conditions = ShareConditions(
            mapImage: map,
            venueLabel: venue,
            temperatureC: weatherData?.temperatureC,
            humidityPercent: weatherData?.humidityPercent,
            airQualityIndex: weatherData?.airQualityIndex
        )
    }

    private func venueLabel(for match: MatchRecord) -> String {
        let name = match.displayVenue
        return name.isEmpty ? "In campo" : name
    }

    private func captureMap(at coordinate: CLLocationCoordinate2D) async -> UIImage? {
        let options = MKMapSnapshotter.Options()
        options.region = MKCoordinateRegion(
            center: coordinate,
            latitudinalMeters: 1200,
            longitudinalMeters: 1200
        )
        options.size = CGSize(width: 520, height: 200)
        options.mapType = .mutedStandard
        options.traitCollection = UITraitCollection(userInterfaceStyle: .dark)

        let snapshotter = MKMapSnapshotter(options: options)
        return await withCheckedContinuation { continuation in
            snapshotter.start { snapshot, _ in
                guard let snapshot else {
                    continuation.resume(returning: nil)
                    return
                }
                let pinPoint = snapshot.point(for: coordinate)
                let image = UIGraphicsImageRenderer(size: snapshot.image.size).image { ctx in
                    snapshot.image.draw(at: .zero)
                    let context = ctx.cgContext
                    let outer: CGFloat = 11
                    let inner: CGFloat = 5
                    context.setFillColor(UIColor.white.cgColor)
                    context.fillEllipse(in: CGRect(
                        x: pinPoint.x - outer, y: pinPoint.y - outer,
                        width: outer * 2, height: outer * 2))
                    context.setFillColor(UIColor(red: 0.72, green: 0.95, blue: 0.28, alpha: 1).cgColor)
                    context.fillEllipse(in: CGRect(
                        x: pinPoint.x - inner, y: pinPoint.y - inner,
                        width: inner * 2, height: inner * 2))
                }
                continuation.resume(returning: image)
            }
        }
    }

    private struct WeatherSnapshot {
        var temperatureC: Int?
        var humidityPercent: Int?
        var airQualityIndex: Int?
    }

    private func fetchWeather(at coordinate: CLLocationCoordinate2D,
                              date: Date) async -> WeatherSnapshot? {
        let lat = coordinate.latitude
        let lon = coordinate.longitude
        let isRecent = abs(date.timeIntervalSinceNow) < 48 * 3600

        if isRecent {
            return await fetchCurrentWeather(lat: lat, lon: lon)
        }
        return await fetchHistoricalWeather(lat: lat, lon: lon, date: date)
    }

    private func fetchCurrentWeather(lat: Double, lon: Double) async -> WeatherSnapshot? {
        let weatherURL = URL(string:
            "https://api.open-meteo.com/v1/forecast?latitude=\(lat)&longitude=\(lon)&current=temperature_2m,relative_humidity_2m&timezone=auto"
        )
        let airURL = URL(string:
            "https://air-quality-api.open-meteo.com/v1/air-quality?latitude=\(lat)&longitude=\(lon)&current=european_aqi&timezone=auto"
        )

        async let weatherData = fetchData(from: weatherURL)
        async let airData = fetchData(from: airURL)
        let (wData, aData) = await (weatherData, airData)

        var snapshot = WeatherSnapshot()
        if let wData,
           let decoded = try? JSONDecoder().decode(OpenMeteoCurrent.self, from: wData) {
            if let temp = decoded.current.temperature_2m {
                snapshot.temperatureC = Int(temp.rounded())
            }
            if let humidity = decoded.current.relative_humidity_2m {
                snapshot.humidityPercent = humidity
            }
        }
        if let aData,
           let decoded = try? JSONDecoder().decode(OpenMeteoAirCurrent.self, from: aData),
           let aqi = decoded.current.european_aqi {
            snapshot.airQualityIndex = aqi
        }

        let hasData = snapshot.temperatureC != nil
            || snapshot.humidityPercent != nil
            || snapshot.airQualityIndex != nil
        return hasData ? snapshot : WeatherSnapshot()
    }

    private func fetchData(from url: URL?) async -> Data? {
        guard let url else { return nil }
        return try? await URLSession.shared.data(from: url).0
    }

    private func fetchHistoricalWeather(lat: Double, lon: Double,
                                        date: Date) async -> WeatherSnapshot? {
        let day = date.formatted(.iso8601.year().month().day())
        let hour = Calendar.current.component(.hour, from: date)

        let weatherURL = URL(string:
            "https://archive-api.open-meteo.com/v1/archive?latitude=\(lat)&longitude=\(lon)&start_date=\(day)&end_date=\(day)&hourly=temperature_2m,relative_humidity_2m&timezone=auto"
        )
        let airURL = URL(string:
            "https://air-quality-api.open-meteo.com/v1/air-quality?latitude=\(lat)&longitude=\(lon)&start_date=\(day)&end_date=\(day)&hourly=european_aqi&timezone=auto"
        )

        async let weatherData = fetchData(from: weatherURL)
        async let airData = fetchData(from: airURL)

        let (wData, aData) = await (weatherData, airData)
        var snapshot = WeatherSnapshot()

        if let wData,
           let decoded = try? JSONDecoder().decode(OpenMeteoArchive.self, from: wData) {
            let index = min(hour, max(0, (decoded.hourly.temperature_2m?.count ?? 1) - 1))
            if let temps = decoded.hourly.temperature_2m, index < temps.count {
                snapshot.temperatureC = Int(temps[index].rounded())
            }
            if let humidity = decoded.hourly.relative_humidity_2m, index < humidity.count {
                snapshot.humidityPercent = humidity[index]
            }
        }

        if let aData,
           let decoded = try? JSONDecoder().decode(OpenMeteoAir.self, from: aData),
           let aqi = decoded.hourly.european_aqi,
           hour < aqi.count {
            snapshot.airQualityIndex = aqi[hour]
        }

        let hasData = snapshot.temperatureC != nil
            || snapshot.humidityPercent != nil
            || snapshot.airQualityIndex != nil
        return hasData ? snapshot : WeatherSnapshot()
    }
}

private struct OpenMeteoCurrent: Decodable {
    let current: Current
    struct Current: Decodable {
        let temperature_2m: Double?
        let relative_humidity_2m: Int?
    }
}

private struct OpenMeteoAirCurrent: Decodable {
    let current: Current
    struct Current: Decodable {
        let european_aqi: Int?
    }
}

private struct OpenMeteoArchive: Decodable {
    let hourly: Hourly
    struct Hourly: Decodable {
        let temperature_2m: [Double]?
        let relative_humidity_2m: [Int]?
    }
}

private struct OpenMeteoAir: Decodable {
    let hourly: Hourly
    struct Hourly: Decodable {
        let european_aqi: [Int]?
    }
}
