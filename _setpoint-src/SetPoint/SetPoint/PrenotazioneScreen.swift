import SwiftUI

/// Placeholder per la futura prenotazione campi: tab visibile in anticipo
/// per comunicare che la funzionalità è in arrivo.
struct PrenotazioneScreen: View {
    var body: some View {
        NavigationStack {
            ContentUnavailableView {
                Label("Prenotazione", systemImage: "calendar.badge.clock")
            } description: {
                Text("Stiamo lavorando per permetterti di prenotare campi da tennis e padel direttamente dall'app.")
            } actions: {
                Text("Coming soon")
                    .font(.system(.subheadline, design: .rounded, weight: .heavy))
                    .kerning(1.5)
                    .foregroundStyle(Theme.accent)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 10)
                    .background(Theme.accent.opacity(0.12), in: Capsule())
                    .overlay(
                        Capsule()
                            .strokeBorder(Theme.accent.opacity(0.35), lineWidth: 1)
                    )
            }
            .background(Theme.background)
            .navigationTitle("Prenotazione")
        }
    }
}

#Preview {
    PrenotazioneScreen()
}
