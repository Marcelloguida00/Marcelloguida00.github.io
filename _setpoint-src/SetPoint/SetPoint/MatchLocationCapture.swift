#if os(iOS)
import CoreLocation
import Foundation

/// Acquisizione posizione per archivio partite e condizioni meteo.
@MainActor
final class MatchLocationCapture: NSObject, CLLocationManagerDelegate {
    static let shared = MatchLocationCapture()

    private let manager = CLLocationManager()
    private var locationContinuation: CheckedContinuation<CLLocation?, Never>?
    private var authContinuation: CheckedContinuation<CLAuthorizationStatus, Never>?

    override init() {
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyHundredMeters
    }

    var authorizationStatus: CLAuthorizationStatus {
        manager.authorizationStatus
    }

    var isAuthorized: Bool {
        switch authorizationStatus {
        case .authorizedWhenInUse, .authorizedAlways: true
        default: false
        }
    }

    /// Salva la posizione sul record se mancante (es. alla chiusura partita).
    func attachIfNeeded(to record: MatchRecord) async -> Bool {
        guard !record.hasStoredLocation else { return false }
        return await attach(to: record)
    }

    /// Salva la posizione attuale sul record (anche in un secondo momento dallo storico).
    func attach(to record: MatchRecord) async -> Bool {
        guard let location = await requestLocation() else { return false }
        record.latitude = location.coordinate.latitude
        record.longitude = location.coordinate.longitude
        return true
    }

    func requestLocation() async -> CLLocation? {
        var status = manager.authorizationStatus
        if status == .notDetermined {
            manager.requestWhenInUseAuthorization()
            status = await waitForAuthorization()
        }

        switch status {
        case .authorizedWhenInUse, .authorizedAlways:
            if let cached = manager.location,
               cached.timestamp.timeIntervalSinceNow > -300 {
                return cached
            }
            return await withCheckedContinuation { continuation in
                locationContinuation = continuation
                manager.requestLocation()
            }
        default:
            return nil
        }
    }

    private func waitForAuthorization() async -> CLAuthorizationStatus {
        await withCheckedContinuation { continuation in
            authContinuation = continuation
            Task {
                try? await Task.sleep(for: .seconds(12))
                await MainActor.run {
                    guard let authContinuation else { return }
                    self.authContinuation = nil
                    authContinuation.resume(returning: manager.authorizationStatus)
                }
            }
        }
    }

    nonisolated func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        Task { @MainActor in
            guard let authContinuation else { return }
            self.authContinuation = nil
            authContinuation.resume(returning: manager.authorizationStatus)
        }
    }

    nonisolated func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        Task { @MainActor in
            locationContinuation?.resume(returning: locations.first)
            locationContinuation = nil
        }
    }

    nonisolated func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        Task { @MainActor in
            locationContinuation?.resume(returning: manager.location)
            locationContinuation = nil
        }
    }
}
#endif
