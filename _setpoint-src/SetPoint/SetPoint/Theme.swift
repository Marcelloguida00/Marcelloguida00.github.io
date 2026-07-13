import SwiftUI
import UIKit

/// Design system dell'app iOS — stile "vibrant & block-based" sui colori
/// del brand: verde campo + lime della pallina (come l'app icon).
/// Token semantici adattivi light/dark, niente esadecimali sparsi nelle viste.
enum Theme {
    /// Verde campo profondo: superfici hero e tabellone (uguale nei due modi).
    static let court = Color(red: 0.10, green: 0.30, blue: 0.20)
    static let courtDeep = Color(red: 0.05, green: 0.20, blue: 0.13)

    /// Lime della pallina: accento energico su superfici scure.
    static let lime = Color(red: 0.78, green: 0.92, blue: 0.25)

    /// Giallo targa del tabellone.
    static let plate = Color(red: 0.86, green: 0.81, blue: 0.44)

    /// Tegola scura delle cifre.
    static let tile = Color(red: 0.09, green: 0.15, blue: 0.11)

    /// Accento principale: verde campo in light, lime in dark (contrasto AA).
    static let accent = Color(uiColor: UIColor { trait in
        trait.userInterfaceStyle == .dark
            ? UIColor(red: 0.78, green: 0.92, blue: 0.25, alpha: 1)
            : UIColor(red: 0.09, green: 0.42, blue: 0.26, alpha: 1)
    })

    /// Sfondo schermata: verde nebbia in light, quasi nero in dark.
    static let background = Color(uiColor: UIColor { trait in
        trait.userInterfaceStyle == .dark
            ? UIColor(red: 0.06, green: 0.08, blue: 0.07, alpha: 1)
            : UIColor(red: 0.94, green: 0.97, blue: 0.94, alpha: 1)
    })

    /// Superficie delle card.
    static let surface = Color(uiColor: UIColor { trait in
        trait.userInterfaceStyle == .dark
            ? UIColor(red: 0.11, green: 0.15, blue: 0.13, alpha: 1)
            : .white
    })

    /// Colori squadra (coerenti con il Watch).
    static let teamColors: [Color] = [.cyan, .orange]

    /// Esito: semantici, mai da soli (sempre con testo/icona).
    static let win = Color(uiColor: UIColor { trait in
        trait.userInterfaceStyle == .dark
            ? UIColor(red: 0.35, green: 0.85, blue: 0.45, alpha: 1)
            : UIColor(red: 0.10, green: 0.55, blue: 0.28, alpha: 1)
    })
    static let loss = Color(uiColor: UIColor { trait in
        trait.userInterfaceStyle == .dark
            ? UIColor(red: 1.00, green: 0.45, blue: 0.40, alpha: 1)
            : UIColor(red: 0.80, green: 0.18, blue: 0.15, alpha: 1)
    })
}

// MARK: - Componenti riusabili

/// Card a blocchi: superficie, angoli generosi, ombra leggera.
struct CardModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .background(Theme.surface, in: RoundedRectangle(cornerRadius: 20))
            .shadow(color: .black.opacity(0.08), radius: 8, y: 3)
    }
}

extension View {
    func card() -> some View { modifier(CardModifier()) }
}

/// Feedback di pressione: scala + opacità con molla (HIG: 150-300ms).
struct PressableStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.965 : 1)
            .opacity(configuration.isPressed ? 0.85 : 1)
            .animation(.spring(duration: 0.25), value: configuration.isPressed)
    }
}

/// Tessera statistica: valore grande + etichetta.
struct StatTile: View {
    let value: String
    let label: String
    var tint: Color = Theme.accent
    var icon: String? = nil
    var compact: Bool = false

    var body: some View {
        VStack(spacing: compact ? 2 : 4) {
            if let icon {
                Image(systemName: icon)
                    .font(compact ? .caption2 : .caption)
                    .foregroundStyle(tint)
            }
            Text(value)
                .font(.system(compact ? .title3 : .title2, design: .rounded, weight: .heavy))
                .monospacedDigit()
                .minimumScaleFactor(0.6)
                .lineLimit(1)
                .foregroundStyle(tint)
            Text(label)
                .font(.system(.caption2, design: .rounded, weight: .semibold))
                .foregroundStyle(.secondary)
                .textCase(.uppercase)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, compact ? 10 : 14)
        .background(tint.opacity(0.10), in: RoundedRectangle(cornerRadius: compact ? 12 : 14))
    }
}

/// Chip informativa (sport, formazione, superficie…).
struct Chip: View {
    let text: String
    var icon: String? = nil

    var body: some View {
        HStack(spacing: 4) {
            if let icon {
                Image(systemName: icon).font(.system(size: 10, weight: .semibold))
            }
            Text(text)
                .font(.system(.caption2, design: .rounded, weight: .semibold))
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(.quaternary, in: Capsule())
        .foregroundStyle(.secondary)
    }
}

/// Anello percentuale vittorie (H2H): colore + numero, mai solo colore.
struct WinRateRing: View {
    let rate: Int   // 0-100

    var body: some View {
        ZStack {
            Circle()
                .stroke(.quaternary, lineWidth: 5)
            Circle()
                .trim(from: 0, to: CGFloat(rate) / 100)
                .stroke(rate >= 50 ? Theme.win : Theme.loss,
                        style: StrokeStyle(lineWidth: 5, lineCap: .round))
                .rotationEffect(.degrees(-90))
            Text("\(rate)%")
                .font(.system(size: 13, weight: .heavy, design: .rounded))
                .monospacedDigit()
        }
        .frame(width: 48, height: 48)
        .accessibilityLabel("Percentuale vittorie \(rate) per cento")
    }
}

/// Avatar con iniziali per avversari e coppie.
struct InitialsAvatar: View {
    let name: String
    var size: CGFloat = 40

    private var initials: String {
        let parts = name.split(separator: "+").flatMap { $0.split(separator: " ") }
        return parts.prefix(2).compactMap { $0.first.map(String.init) }
            .joined().uppercased()
    }

    var body: some View {
        Text(initials.isEmpty ? "?" : initials)
            .font(.system(size: size * 0.38, weight: .heavy, design: .rounded))
            .foregroundStyle(Theme.lime)
            .frame(width: size, height: size)
            .background(Theme.court, in: Circle())
    }
}

/// Avatar cloud: foto profilo da iCloud/CloudKit se disponibile, altrimenti iniziali.
struct PlayerAvatar: View {
    let appleUserID: String?
    let name: String
    var size: CGFloat = 40

    @State private var image: UIImage?

    var body: some View {
        Group {
            if let image {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
            } else {
                InitialsAvatar(name: name, size: size)
            }
        }
        .frame(width: size, height: size)
        .clipShape(Circle())
        .task(id: appleUserID) {
            guard let id = appleUserID, !id.isEmpty else { return }
            if let cached = CloudKitManager.shared.cachedAvatar(for: id) {
                image = cached
                return
            }
            image = await CloudKitManager.shared.fetchAvatar(appleUserID: id)
        }
    }
}
