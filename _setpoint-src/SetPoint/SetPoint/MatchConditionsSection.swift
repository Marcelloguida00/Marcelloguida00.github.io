import SwiftUI
import SwiftData

/// Mappa e condizioni meteo nel dettaglio partita (storico).
struct MatchConditionsSection: View {
    @Bindable var match: MatchRecord
    @Environment(\.modelContext) private var context
    @State private var loader = ShareConditionsLoader()
    @State private var loading = true
    @State private var capturingLocation = false
    @State private var locationFailed = false

    private var reloadKey: String {
        "\(match.date.timeIntervalSince1970)-\(match.latitude)-\(match.longitude)-\(match.venue)"
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Label("Campo e condizioni", systemImage: "cloud.sun.fill")
                .font(.system(.subheadline, design: .rounded, weight: .bold))
                .foregroundStyle(Theme.accent)

            if loading {
                HStack(spacing: 8) {
                    ProgressView().controlSize(.small)
                    Text("Caricamento…")
                        .font(.system(.caption, design: .rounded))
                        .foregroundStyle(.secondary)
                }
                .padding(.vertical, 4)
            } else if let conditions = loader.conditions {
                conditionsCard(conditions)
            } else {
                missingLocationCard
            }
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .card()
        .task(id: reloadKey) {
            await loadConditions(persistLocation: true)
        }
    }

    private var missingLocationCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            if !match.displayVenue.isEmpty {
                Label(match.displayVenue, systemImage: "sportscourt.fill")
                    .font(.system(.subheadline, design: .rounded, weight: .semibold))
            }

            Text(locationFailed
                 ? "Non è stato possibile ottenere la posizione. Controlla i permessi in Impostazioni → SetPoint."
                 : "Aggiungi la posizione del campo per vedere mappa e meteo della partita.")
                .font(.system(.caption, design: .rounded))
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)

            Button {
                captureLocation()
            } label: {
                HStack {
                    if capturingLocation {
                        ProgressView().controlSize(.small)
                    }
                    Label(
                        match.hasStoredLocation ? "Aggiorna posizione" : "Usa posizione attuale",
                        systemImage: "location.fill"
                    )
                }
                .font(.system(.footnote, design: .rounded, weight: .bold))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(Theme.accent.opacity(0.10), in: RoundedRectangle(cornerRadius: 12))
                .foregroundStyle(Theme.accent)
            }
            .buttonStyle(PressableStyle())
            .disabled(capturingLocation)
        }
    }

    private func captureLocation() {
        capturingLocation = true
        locationFailed = false
        Task {
            let saved = await MatchLocationCapture.shared.attach(to: match)
            if saved {
                try? context.save()
                locationFailed = false
                await loadConditions(persistLocation: false)
            } else {
                locationFailed = true
                loading = false
            }
            capturingLocation = false
        }
    }

    private func loadConditions(persistLocation: Bool) async {
        loading = true
        let hadLocation = match.hasStoredLocation
        await loader.load(for: match)
        if persistLocation,
           !hadLocation,
           !match.hasStoredLocation,
           await MatchLocationCapture.shared.attachIfNeeded(to: match) {
            try? context.save()
            await loader.load(for: match)
        }
        loading = false
    }

    @ViewBuilder
    private func conditionsCard(_ conditions: ShareConditions) -> some View {
        VStack(spacing: 0) {
            ZStack {
                Group {
                    if let mapImage = conditions.mapImage {
                        Image(uiImage: mapImage)
                            .resizable()
                            .scaledToFill()
                    } else {
                        Color(red: 0.14, green: 0.16, blue: 0.15)
                    }
                }
                .frame(height: 130)
                .clipped()

                LinearGradient(
                    colors: [.black.opacity(0.05), .black.opacity(0.55)],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .frame(height: 130)
                .allowsHitTesting(false)

                VStack {
                    Spacer()
                    Text(conditions.venueLabel)
                        .font(.system(.caption2, design: .rounded, weight: .bold))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(.black.opacity(0.45), in: Capsule())
                        .padding(.bottom, 8)
                }
                .frame(height: 130)
            }
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))

            HStack(spacing: 0) {
                metric(icon: "thermometer.medium", label: "Temp", value: tempText(conditions.temperatureC))
                Divider().frame(height: 36)
                metric(icon: "humidity.fill", label: "Umidità", value: humidityText(conditions.humidityPercent))
                Divider().frame(height: 36)
                metric(icon: "aqi.medium", label: "Aria", value: aqiText(conditions.airQualityIndex))
            }
            .padding(.vertical, 10)
        }
        .background(Color(red: 0.13, green: 0.13, blue: 0.14))
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
    }

    private func metric(icon: String, label: String, value: String) -> some View {
        VStack(spacing: 3) {
            Image(systemName: icon)
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(.white.opacity(0.45))
            Text(value)
                .font(.system(.body, design: .rounded, weight: .heavy))
                .monospacedDigit()
                .foregroundStyle(.white)
            Text(label.uppercased())
                .font(.system(size: 9, weight: .bold, design: .rounded))
                .foregroundStyle(.white.opacity(0.4))
        }
        .frame(maxWidth: .infinity)
    }

    private func tempText(_ temp: Int?) -> String {
        guard let temp else { return "—" }
        return "\(temp)°"
    }

    private func humidityText(_ humidity: Int?) -> String {
        guard let humidity else { return "—" }
        return "\(humidity)%"
    }

    private func aqiText(_ aqi: Int?) -> String {
        guard let aqi else { return "—" }
        return "\(aqi)"
    }
}
