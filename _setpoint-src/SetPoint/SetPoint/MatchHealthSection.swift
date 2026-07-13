import SwiftUI
import SwiftData

/// Metriche Apple Salute nel dettaglio partita (storico iPhone).
struct MatchHealthSection: View {
    @Bindable var match: MatchRecord
    @Environment(\.modelContext) private var context
    @State private var loading = false
    @State private var searched = false

    private var reloadKey: String {
        "\(match.date.timeIntervalSince1970)-\(match.hasHealthData)-\(match.healthRecoveredFromSalute)"
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Label("Salute e attività", systemImage: "heart.text.square.fill")
                .font(.system(.subheadline, design: .rounded, weight: .bold))
                .foregroundStyle(.red)

            if loading {
                HStack(spacing: 8) {
                    ProgressView().controlSize(.small)
                    Text(match.hasHealthData ? "Aggiornamento…" : "Ricerca in Apple Salute…")
                        .font(.system(.caption, design: .rounded))
                        .foregroundStyle(.secondary)
                }
                .padding(.vertical, 4)
            } else if match.hasHealthData {
                healthGrid
                footer
            } else if searched {
                Text("Nessun dato salute trovato per questa partita. Verifica che l'allenamento sia stato registrato sull'Apple Watch e che SetPoint abbia accesso ad Apple Salute.")
                    .font(.system(.caption, design: .rounded))
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .card()
        .task(id: reloadKey) {
            await recoverIfNeeded()
        }
    }

    @ViewBuilder
    private var healthGrid: some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())],
                  spacing: 8) {
            if match.activeCalories > 0 {
                StatTile(value: "\(Int(match.activeCalories.rounded()))",
                         label: "Calorie", tint: .orange,
                         icon: "flame.fill", compact: true)
            }
            if match.avgHeartRate > 0 {
                StatTile(value: "\(Int(match.avgHeartRate.rounded()))",
                         label: "Battito medio", tint: .red,
                         icon: "heart.fill", compact: true)
            }
            if match.maxHeartRate > 0 {
                StatTile(value: "\(Int(match.maxHeartRate.rounded()))",
                         label: "Battito max", tint: .pink,
                         icon: "bolt.heart.fill", compact: true)
            }
            if match.steps > 0 {
                StatTile(value: formattedSteps(match.steps),
                         label: "Passi", tint: Theme.accent,
                         icon: "figure.walk", compact: true)
            }
            // Sempre visibile (anche "0 m"): rende evidente quando il
            // Watch non ha rilevato spostamenti durante il match.
            StatTile(value: formattedDistance(match.distanceMeters),
                     label: "Distanza", tint: .cyan,
                     icon: "figure.run", compact: true)
        }
    }

    private var footer: some View {
        Text(match.healthRecoveredFromSalute
             ? "Recuperati da Apple Salute"
             : "Raccolti da Apple Watch durante il match")
            .font(.system(.caption2, design: .rounded))
            .foregroundStyle(.secondary)
    }

    private func recoverIfNeeded() async {
        if match.hasHealthData {
            searched = true
            return
        }
        loading = true
        defer {
            loading = false
            searched = true
        }
        await MatchHealthRecovery.recoverIfNeeded(for: match, context: context)
    }

    private func formattedSteps(_ steps: Int) -> String {
        steps >= 10_000
            ? String(format: "%.1fk", Double(steps) / 1000)
            : "\(steps)"
    }

    private func formattedDistance(_ meters: Double) -> String {
        if meters >= 1000 {
            return String(format: "%.1f km", meters / 1000)
        }
        return "\(Int(meters.rounded())) m"
    }
}
