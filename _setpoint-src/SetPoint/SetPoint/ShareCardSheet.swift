import SwiftUI
import PhotosUI
import SwiftData

/// Condivisione social del match (readme §5): card grafica del punteggio
/// in formato Storia (9:16), con personalizzazione fotografica — il tabellone
/// si sovrappone a una foto scelta dall'utente, protetta da uno scrim.
struct ShareCardSheet: View {
    @Bindable var match: MatchRecord

    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var context
    @Environment(\.colorScheme) private var colorScheme
    @State private var loader = ShareConditionsLoader()
    @AppStorage("shareCardPalette") private var paletteRaw = ShareCardPalette.field.rawValue
    @State private var photoItem: PhotosPickerItem? = nil
    @State private var photo: UIImage? = nil
    @State private var rendered: UIImage? = nil

    private var palette: ShareCardPalette {
        ShareCardPalette(rawValue: paletteRaw) ?? .field
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    if let rendered {
                        Image(uiImage: rendered)
                            .resizable()
                            .scaledToFit()
                            .frame(maxHeight: 420)
                            .clipShape(RoundedRectangle(cornerRadius: 16))
                            .shadow(color: .black.opacity(0.15), radius: 10, y: 4)
                            .accessibilityLabel("Anteprima della card: \(match.won ? "vittoria" : "sconfitta") \(match.scoreline)")
                    } else {
                        RoundedRectangle(cornerRadius: 16)
                            .fill(Theme.surface)
                            .frame(height: 420)
                            .overlay(ProgressView())
                    }

                    venueField
                    palettePicker
                    photoControls
                }
                .padding()
            }
            .background(Theme.background)
            .navigationTitle("Condividi partita")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Chiudi") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    if let rendered {
                        ShareLink(
                            item: Image(uiImage: rendered),
                            preview: SharePreview("SetPoint — \(match.scoreline)",
                                                  image: Image(uiImage: rendered))) {
                            Label("Condividi", systemImage: "square.and.arrow.up")
                                .font(.system(.body, design: .rounded, weight: .bold))
                        }
                    }
                }
            }
            .task(id: match.date) {
                await loader.load(for: match)
            }
            .task(id: renderKey) { render() }
            .onChange(of: match.venue) { _, _ in
                try? context.save()
            }
            .onChange(of: photoItem) { _, item in
                guard let item else {
                    photo = nil
                    return
                }
                Task {
                    if let data = try? await item.loadTransferable(type: Data.self) {
                        photo = UIImage(data: data)
                    }
                }
            }
        }
    }

    private var venueField: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label("Campo", systemImage: "sportscourt.fill")
                .font(.system(.subheadline, design: .rounded, weight: .bold))
                .foregroundStyle(Theme.accent)

            TextField("es. Campo 1, Circolo Roma…", text: $match.venue)
                .font(.system(.subheadline, design: .rounded))
                .textInputAutocapitalization(.words)
                .padding(12)
                .background(Theme.surface, in: RoundedRectangle(cornerRadius: 12))

            Text("Compare sulla card insieme a meteo e posizione.")
                .font(.system(.caption, design: .rounded))
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(Theme.surface.opacity(0.65), in: RoundedRectangle(cornerRadius: 16))
    }

    private var palettePicker: some View {
        VStack(alignment: .leading, spacing: 10) {
            Label("Colore card", systemImage: "paintpalette.fill")
                .font(.system(.subheadline, design: .rounded, weight: .bold))
                .foregroundStyle(Theme.accent)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(ShareCardPalette.allCases) { option in
                        paletteButton(option)
                    }
                }
                .padding(.vertical, 2)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(Theme.surface.opacity(0.65), in: RoundedRectangle(cornerRadius: 16))
    }

    private func paletteButton(_ option: ShareCardPalette) -> some View {
        let selected = palette == option
        return Button {
            withAnimation(.spring(duration: 0.25)) {
                paletteRaw = option.rawValue
            }
        } label: {
            VStack(spacing: 6) {
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [option.court, option.accent],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 44, height: 44)
                    if selected {
                        Circle()
                            .strokeBorder(.white, lineWidth: 3)
                            .frame(width: 44, height: 44)
                        Image(systemName: "checkmark")
                            .font(.system(size: 14, weight: .heavy))
                            .foregroundStyle(.white)
                    }
                }
                Text(option.label)
                    .font(.system(.caption, design: .rounded, weight: selected ? .bold : .semibold))
                    .foregroundStyle(paletteLabelColor(selected: selected, option: option))
            }
            .frame(width: 64)
        }
        .buttonStyle(PressableStyle())
        .accessibilityLabel("\(option.label)\(selected ? ", selezionato" : "")")
    }

    private func paletteLabelColor(selected: Bool, option: ShareCardPalette) -> Color {
        if colorScheme == .dark { return .white }
        return selected ? option.accent : .secondary
    }

    private var photoControls: some View {
        VStack(spacing: 10) {
            PhotosPicker(selection: $photoItem, matching: .images) {
                Label(photo == nil ? "Aggiungi una tua foto" : "Cambia foto",
                      systemImage: "photo.fill")
                    .font(.system(.headline, design: .rounded, weight: .bold))
                    .foregroundStyle(Theme.tile)
                    .frame(maxWidth: .infinity, minHeight: 50)
                    .background(Theme.lime, in: RoundedRectangle(cornerRadius: 14))
            }
            .buttonStyle(PressableStyle())

            if photo != nil {
                Button {
                    withAnimation(.spring(duration: 0.25)) {
                        photoItem = nil
                        photo = nil
                    }
                } label: {
                    Label("Rimuovi foto", systemImage: "xmark.circle.fill")
                        .font(.system(.subheadline, design: .rounded, weight: .semibold))
                        .foregroundStyle(Theme.loss)
                        .frame(minHeight: 44)
                }
            } else {
                Text("Il tabellone si sovrappone alla foto, come un selfie di fine partita.")
                    .font(.system(.caption, design: .rounded))
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
        }
    }

    // MARK: - Rendering

    private var renderKey: String {
        let c = loader.conditions
        let condKey = c.map {
            "\($0.venueLabel)-\($0.temperatureC ?? -1)-\($0.humidityPercent ?? -1)-\($0.mapImage != nil)"
        } ?? "loading"
        return "\(paletteRaw)-\(match.displayVenue)-\(photo == nil ? "flat" : "photo-\(photoItem?.hashValue ?? 0)")-\(condKey)"
    }

    @MainActor
    private func render() {
        let renderer = ImageRenderer(
            content: ShareCardView(
                match: match,
                palette: palette,
                conditions: loader.conditions,
                photo: photo
            ))
        renderer.scale = 2   // 540pt → 1080px, misura standard social
        rendered = renderer.uiImage
    }
}

// MARK: - Palette

enum ShareCardPalette: String, CaseIterable, Identifiable {
    case field, ocean, sunset, night, clay

    var id: String { rawValue }

    var label: String {
        switch self {
        case .field: "Campo"
        case .ocean: "Oceano"
        case .sunset: "Tramonto"
        case .night: "Notte"
        case .clay: "Terra"
        }
    }

    var court: Color {
        switch self {
        case .field: Color(red: 0.10, green: 0.30, blue: 0.20)
        case .ocean: Color(red: 0.08, green: 0.22, blue: 0.38)
        case .sunset: Color(red: 0.38, green: 0.14, blue: 0.12)
        case .night: Color(red: 0.12, green: 0.10, blue: 0.28)
        case .clay: Color(red: 0.42, green: 0.18, blue: 0.10)
        }
    }

    var courtDeep: Color {
        switch self {
        case .field: Color(red: 0.05, green: 0.20, blue: 0.13)
        case .ocean: Color(red: 0.04, green: 0.12, blue: 0.24)
        case .sunset: Color(red: 0.22, green: 0.08, blue: 0.08)
        case .night: Color(red: 0.06, green: 0.05, blue: 0.16)
        case .clay: Color(red: 0.26, green: 0.10, blue: 0.06)
        }
    }

    var accent: Color {
        switch self {
        case .field: Color(red: 0.78, green: 0.92, blue: 0.25)
        case .ocean: Color(red: 0.35, green: 0.82, blue: 0.95)
        case .sunset: Color(red: 1.00, green: 0.55, blue: 0.20)
        case .night: Color(red: 0.72, green: 0.55, blue: 1.00)
        case .clay: Color(red: 0.95, green: 0.72, blue: 0.35)
        }
    }

    var gradientEnd: Color {
        switch self {
        case .field: Color(red: 0.03, green: 0.12, blue: 0.08)
        case .ocean: Color(red: 0.02, green: 0.08, blue: 0.16)
        case .sunset: Color(red: 0.14, green: 0.05, blue: 0.05)
        case .night: Color(red: 0.04, green: 0.03, blue: 0.10)
        case .clay: Color(red: 0.18, green: 0.07, blue: 0.04)
        }
    }
}

// MARK: - Layout

private enum ShareCardLayout {
    /// Dimensioni in punti; il renderer usa scale 2 → 1080 px di larghezza.
    static let size = CGSize(width: 540, height: 960)
}

// MARK: - Card

/// La card vera e propria, disegnata a dimensione fissa per il renderer.
/// Stile SetPoint: verde campo, lime, targa oro — layout da poster social.
struct ShareCardView: View {
    let match: MatchRecord
    var palette: ShareCardPalette = .field
    var conditions: ShareConditions? = nil
    var photo: UIImage? = nil

    private var sets: [[String]] {
        match.scoreline.split(separator: " ").compactMap { token in
            let games = token.trimmingCharacters(in: CharacterSet(charactersIn: "()"))
                .split(separator: "-").map(String.init)
            return games.count == 2 ? games : nil
        }
    }

    private var homeTeamLabel: String {
        if match.isSpectator {
            return teamPairLabel(match.homeName, match.partner)
        }
        let doppio = match.matchType == MatchType.doppio.rawValue
        let myName = UserName.current
        let me = myName.isEmpty ? (doppio ? "Noi" : "Io") : myName
        return doppio ? teamPairLabel(me, match.partner) : me.uppercased()
    }

    private var awayTeamLabel: String {
        if match.isSpectator {
            return teamPairLabel(match.opponent, match.opponent2)
        }
        return teamPairLabel(match.opponent, match.opponent2,
                             fallback: match.matchType == MatchType.doppio.rawValue ? "Avversari" : "Avversario")
    }

    private var venueLabel: String {
        let fromConditions = conditions?.venueLabel.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        if !fromConditions.isEmpty, fromConditions != "In campo" { return fromConditions }
        let court = match.displayVenue.trimmingCharacters(in: .whitespacesAndNewlines)
        return court.isEmpty ? "In campo" : court
    }

    private var hasWeather: Bool {
        guard let conditions else { return false }
        return conditions.temperatureC != nil
            || conditions.humidityPercent != nil
            || conditions.airQualityIndex != nil
    }

    private func teamPairLabel(_ first: String, _ second: String, fallback: String = "—") -> String {
        let a = first.trimmingCharacters(in: .whitespaces)
        let b = second.trimmingCharacters(in: .whitespaces)
        if a.isEmpty && b.isEmpty { return fallback.uppercased() }
        if b.isEmpty { return a.uppercased() }
        if a.isEmpty { return b.uppercased() }
        return "\(a.uppercased()) + \(b.uppercased())"
    }

    var body: some View {
        ZStack {
            background

            VStack(spacing: 20) {
                Spacer(minLength: 8)

                brandHeader
                resultBadge
                scoreCard

                if hasWeather || conditions?.mapImage != nil || !match.displayVenue.isEmpty {
                    conditionsSection
                }

                statsRow

                Spacer(minLength: 8)
                footer
            }
            .padding(32)
        }
        .frame(width: ShareCardLayout.size.width, height: ShareCardLayout.size.height)
    }

    // MARK: - Sfondo

    private var background: some View {
        ZStack {
            LinearGradient(
                colors: [palette.court, palette.courtDeep, palette.gradientEnd],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            if let photo {
                Image(uiImage: photo)
                    .resizable()
                    .scaledToFill()
                    .frame(width: ShareCardLayout.size.width, height: ShareCardLayout.size.height)
                    .clipped()
                LinearGradient(
                    colors: [.black.opacity(0.15), .black.opacity(0.55), .black.opacity(0.82)],
                    startPoint: .top,
                    endPoint: .bottom
                )
            }
        }
    }

    // MARK: - Header

    private var brandHeader: some View {
        VStack(spacing: 12) {
            HStack(spacing: 10) {
                Image(systemName: "tennisball.fill")
                    .font(.system(size: 22, weight: .heavy))
                    .foregroundStyle(palette.accent)
                Text("SETPOINT")
                    .font(.system(size: 28, weight: .heavy, design: .rounded))
                    .kerning(5)
                    .foregroundStyle(.white)
            }

            HStack(spacing: 8) {
                metaChip(match.sport.uppercased(), icon: match.sport == "Padel" ? "figure.pickleball" : "figure.tennis")
                metaChip(match.matchType.uppercased())
                if match.sport == Sport.tennis.rawValue, !match.courtSurface.isEmpty {
                    metaChip(match.courtSurface.uppercased())
                }
                metaChip(match.date.formatted(.dateTime.day().month(.abbreviated)))
            }
        }
    }

    private func metaChip(_ text: String, icon: String? = nil) -> some View {
        HStack(spacing: 4) {
            if let icon {
                Image(systemName: icon)
                    .font(.system(size: 9, weight: .bold))
            }
            Text(text)
                .font(.system(size: 11, weight: .bold, design: .rounded))
                .kerning(0.8)
        }
        .foregroundStyle(.white.opacity(0.9))
        .padding(.horizontal, 10)
        .padding(.vertical, 5)
        .background(.white.opacity(0.12), in: Capsule())
    }

    private var resultBadge: some View {
        Group {
            if match.isSpectator {
                Label(
                    match.won ? "VINCE \(homeTeamLabel)" : "VINCE \(awayTeamLabel)",
                    systemImage: "eye.fill"
                )
            } else if match.won {
                Label("VITTORIA", systemImage: "trophy.fill")
            } else {
                Label("BELLA PARTITA", systemImage: "tennisball.fill")
            }
        }
        .font(.system(size: 18, weight: .heavy, design: .rounded))
        .kerning(2)
        .foregroundStyle(.white)
        .padding(.horizontal, 24)
        .padding(.vertical, 11)
        .background {
            Capsule().fill(badgeFill)
        }
        .shadow(color: badgeShadow, radius: 12, y: 4)
    }

    private var badgeFill: LinearGradient {
        if match.won || match.isSpectator {
            LinearGradient(colors: [palette.accent, palette.accent.opacity(0.85)],
                           startPoint: .topLeading, endPoint: .bottomTrailing)
        } else {
            LinearGradient(colors: [.white.opacity(0.28), .white.opacity(0.14)],
                           startPoint: .topLeading, endPoint: .bottomTrailing)
        }
    }

    private var badgeShadow: Color {
        match.won || match.isSpectator ? palette.accent.opacity(0.35) : .black.opacity(0.2)
    }

    // MARK: - Tabellone

    private var scoreCard: some View {
        VStack(spacing: 14) {
            setsSummary

            teamRow(label: homeTeamLabel, index: 0, winner: match.won)

            Text("VS")
                .font(.system(size: 13, weight: .heavy, design: .rounded))
                .kerning(4)
                .foregroundStyle(.white.opacity(0.45))

            teamRow(label: awayTeamLabel, index: 1, winner: !match.won)
        }
        .padding(24)
        .background(
            RoundedRectangle(cornerRadius: 28)
                .fill(Color.white.opacity(0.10))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 28)
                .strokeBorder(
                    LinearGradient(
                        colors: [.white.opacity(0.35), .white.opacity(0.08)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1
                )
        )
        .shadow(color: .black.opacity(0.25), radius: 20, y: 8)
    }

    private var setsSummary: some View {
        HStack(spacing: 6) {
            Text("\(match.setsWon)")
                .font(.system(size: 36, weight: .heavy, design: .rounded))
                .foregroundStyle(match.won ? palette.accent : .white.opacity(0.7))
            Text("–")
                .font(.system(size: 24, weight: .heavy, design: .rounded))
                .foregroundStyle(.white.opacity(0.4))
            Text("\(match.setsLost)")
                .font(.system(size: 36, weight: .heavy, design: .rounded))
                .foregroundStyle(!match.won && !match.isSpectator ? palette.accent : .white.opacity(0.7))
        }
        .monospacedDigit()
        .padding(.bottom, 4)
    }

    private func teamRow(label: String, index: Int, winner: Bool) -> some View {
        HStack(spacing: 10) {
            HStack(spacing: 8) {
                Text(label)
                    .font(.system(size: 17, weight: .heavy, design: .rounded))
                    .foregroundStyle(Theme.tile)
                    .lineLimit(2)
                    .minimumScaleFactor(0.5)
                    .multilineTextAlignment(.leading)
                if winner {
                    Image(systemName: "crown.fill")
                        .font(.system(size: 13, weight: .heavy))
                        .foregroundStyle(palette.court)
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 12)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                winner
                    ? LinearGradient(colors: [Theme.plate, Theme.plate.opacity(0.88)],
                                     startPoint: .topLeading, endPoint: .bottomTrailing)
                    : LinearGradient(colors: [Theme.plate.opacity(0.75), Theme.plate.opacity(0.6)],
                                     startPoint: .topLeading, endPoint: .bottomTrailing),
                in: RoundedRectangle(cornerRadius: 14)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .strokeBorder(winner ? palette.accent.opacity(0.6) : .clear, lineWidth: 2)
            )

            HStack(spacing: 6) {
                ForEach(Array(sets.enumerated()), id: \.offset) { _, set in
                    Text(set[index])
                        .font(.system(size: 22, weight: .heavy, design: .rounded))
                        .monospacedDigit()
                        .foregroundStyle(Theme.tile)
                        .frame(width: 40, height: 44)
                        .background(.white, in: RoundedRectangle(cornerRadius: 10))
                }
            }
        }
    }

    // MARK: - Campo, mappa e meteo

    private var conditionsSection: some View {
        VStack(spacing: 0) {
            ZStack(alignment: .bottom) {
                Group {
                    if let mapImage = conditions?.mapImage {
                        Image(uiImage: mapImage)
                            .resizable()
                            .scaledToFill()
                    } else {
                        LinearGradient(
                            colors: [palette.court.opacity(0.6), palette.courtDeep],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    }
                }
                .frame(height: 96)
                .frame(maxWidth: .infinity)
                .clipped()

                LinearGradient(
                    colors: [.black.opacity(0.05), .black.opacity(0.6)],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .frame(height: 96)
                .allowsHitTesting(false)

                HStack(spacing: 6) {
                    Image(systemName: "mappin.circle.fill")
                        .font(.system(size: 14, weight: .semibold))
                    Text(venueLabel.uppercased())
                        .font(.system(size: 12, weight: .heavy, design: .rounded))
                        .kerning(1.5)
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)
                }
                .foregroundStyle(.white)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(.black.opacity(0.45), in: Capsule())
                .padding(.bottom, 10)
            }

            if hasWeather {
                HStack(spacing: 0) {
                    weatherMetric(icon: "thermometer.medium",
                                  value: tempText(conditions?.temperatureC))
                    weatherDivider
                    weatherMetric(icon: "humidity.fill",
                                  value: humidityText(conditions?.humidityPercent))
                    weatherDivider
                    weatherMetric(icon: "aqi.medium",
                                  value: aqiText(conditions?.airQualityIndex))
                }
                .padding(.vertical, 10)
                .background(.white.opacity(0.08))
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .strokeBorder(.white.opacity(0.15), lineWidth: 1)
        )
    }

    private var weatherDivider: some View {
        Rectangle()
            .fill(.white.opacity(0.15))
            .frame(width: 1, height: 32)
    }

    private func weatherMetric(icon: String, value: String) -> some View {
        VStack(spacing: 3) {
            Image(systemName: icon)
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(.white.opacity(0.5))
            Text(value)
                .font(.system(size: 18, weight: .heavy, design: .rounded))
                .monospacedDigit()
                .foregroundStyle(.white)
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

    // MARK: - Statistiche

    private var statsRow: some View {
        HStack(spacing: 10) {
            cardStat(value: LiveScreen.format(match.duration), label: "IN CAMPO",
                     icon: "stopwatch.fill")
            cardStat(value: "\(match.pointsWon)–\(match.pointsLost)", label: "PUNTI",
                     icon: "circle.grid.2x2.fill")
            cardStat(value: "\(MomentumChart.longestStreak(match.timeline, team: 0))",
                     label: "STRISCIA", icon: "flame.fill")
        }
    }

    private func cardStat(value: String, label: String, icon: String) -> some View {
        VStack(spacing: 5) {
            Label(label, systemImage: icon)
                .font(.system(size: 9, weight: .bold, design: .rounded))
                .kerning(1)
                .foregroundStyle(.white.opacity(0.55))
            Text(value)
                .font(.system(size: 22, weight: .heavy, design: .rounded))
                .monospacedDigit()
                .lineLimit(1)
                .minimumScaleFactor(0.6)
                .foregroundStyle(.white)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .padding(.horizontal, 6)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(.white.opacity(0.08))
        )
    }

    private var footer: some View {
        HStack(spacing: 8) {
            Image(systemName: "applewatch")
                .font(.system(size: 12, weight: .semibold))
            Text("Segnato in tempo reale con SetPoint")
                .font(.system(size: 12, weight: .semibold, design: .rounded))
        }
        .foregroundStyle(.white.opacity(0.55))
    }
}

#Preview("Vittoria") {
    ShareCardView(
        match: MatchRecord(
            date: .now, sport: "Padel", matchType: "Doppio", name: "",
            opponent: "Luca", opponent2: "Sara", partner: "Giulia",
            venue: "Campo 1",
            won: true, finished: true, scoreline: "6-3 4-6 10-7",
            setsWon: 2, setsLost: 1, pointsWon: 74, pointsLost: 62,
            duration: 4980,
            timeline: [0, 0, 1, 0, 1, 0, 0, 1, 0, 0],
            setBreaks: [4], setDurations: [1600, 1700, 1680]),
        conditions: ShareConditions(
            mapImage: nil,
            venueLabel: "Campo 1",
            temperatureC: 24,
            humidityPercent: 58,
            airQualityIndex: 32))
}

#Preview("Sconfitta") {
    ShareCardView(
        match: MatchRecord(
            date: .now, sport: "Tennis", matchType: "Singolare", name: "",
            opponent: "Marco", opponent2: "", partner: "",
            venue: "Circolo Roma",
            won: false, finished: true, scoreline: "4-6 3-6",
            setsWon: 0, setsLost: 2, pointsWon: 48, pointsLost: 61,
            duration: 3720,
            timeline: [1, 1, 0, 1, 0, 1],
            setBreaks: [], setDurations: [1800, 1920]),
        conditions: ShareConditions(
            mapImage: nil,
            venueLabel: "Circolo Roma",
            temperatureC: 19,
            humidityPercent: 72,
            airQualityIndex: 18))
}
