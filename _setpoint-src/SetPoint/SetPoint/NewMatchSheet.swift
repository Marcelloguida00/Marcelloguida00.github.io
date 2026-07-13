import SwiftUI

/// Configurazione della partita dall'iPhone: layout a card coerente con
/// il design system SetPoint (verde campo, lime, blocchi arrotondati).
struct NewMatchSheet: View {
    @Environment(\.dismiss) private var dismiss
    @AppStorage("appleUserID") private var appleUserID = ""
    @State private var config = MatchConfig()
    @State private var meta = MatchMeta()

    @State private var searchResults: [PlayerProfile] = []
    @State private var activeSearchField: SearchField? = nil
    @State private var searchTask: Task<Void, Never>? = nil
    @State private var appToggles: Set<SearchField> = []
    @State private var searching = false
    @State private var searchError: String? = nil
    @State private var sendingInvites = false
    @State private var inviteError: String? = nil

    enum SearchField: Hashable {
        case homeName, partner, opponent, opponent2
    }

    private var needsInvites: Bool {
        !meta.isSpectator && !meta.links.isEmpty && !appleUserID.isEmpty
    }

    private var canStart: Bool {
        meta.spectatorNamesComplete(type: config.matchType)
    }

    var body: some View {
        NavigationStack {
            ZStack(alignment: .bottom) {
                ScrollView {
                    VStack(spacing: 16) {
                        sheetHero

                        sectionCard(title: "Sport", icon: "sportscourt.fill") {
                            sportPicker
                            if config.sport == .tennis {
                                Divider().opacity(0.35)
                                courtSurfacePicker
                            }
                            Divider().opacity(0.35)
                            matchTypePicker
                        }

                        sectionCard(title: "Regole", icon: "slider.horizontal.3") {
                            setsPicker
                            Divider().opacity(0.35)
                            ruleToggle("Fast4", subtitle: "Set a 4 game", isOn: $config.fast4)
                            if config.sport == .padel {
                                ruleToggle("Golden Point", subtitle: "Punto secco sul 40-40",
                                           isOn: $config.goldenPoint)
                            }
                            if config.setsToWin > 1 {
                                ruleToggle("Super tie-break", subtitle: "Set decisivo a 10 punti",
                                           isOn: $config.superTiebreak)
                            }
                        }

                        sectionCard(title: "Campo", icon: "sportscourt.fill") {
                            venueField
                        }

                        sectionCard(title: "Modalità", icon: "person.2.fill") {
                            rolePicker
                            Text(meta.isSpectator
                                 ? "Segnapunti per altri: le partite restano nello storico ma non contano in Rivalità."
                                 : "Giochi tu: il tuo nome viene dal Profilo.")
                                .font(.system(.caption, design: .rounded))
                                .foregroundStyle(.secondary)
                                .fixedSize(horizontal: false, vertical: true)
                        }

                        sectionCard(
                            title: meta.isSpectator ? "Giocatori" : "Avversari",
                            icon: "person.3.fill"
                        ) {
                            if meta.isSpectator {
                                spectatorPlayerFields
                            } else {
                                playerModeFields
                            }
                            if !footerLines.isEmpty {
                                footerNote
                            }
                        }
                    }
                    .padding(.horizontal)
                    .padding(.top, 8)
                    .padding(.bottom, 100)
                }
                .background(Theme.background)

                bottomBar
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("Nuova partita")
                        .font(.system(.headline, design: .rounded, weight: .heavy))
                }
                ToolbarItem(placement: .cancellationAction) {
                    Button("Chiudi") { dismiss() }
                        .font(.system(.subheadline, design: .rounded, weight: .semibold))
                }
            }
            .alert("Invito non inviato", isPresented: .init(
                get: { inviteError != nil },
                set: { if !$0 { inviteError = nil } }
            )) {
                Button("OK", role: .cancel) { inviteError = nil }
            } message: {
                Text(inviteError ?? "")
            }
        }
        .presentationDragIndicator(.visible)
    }

    // MARK: - Header

    private var sheetHero: some View {
        HStack(spacing: 14) {
            Image(systemName: config.sport == .tennis ? "figure.tennis" : "figure.pickleball")
                .font(.system(size: 28, weight: .bold))
                .foregroundStyle(Theme.lime)
                .frame(width: 52, height: 52)
                .background(.white.opacity(0.12), in: RoundedRectangle(cornerRadius: 14))

            VStack(alignment: .leading, spacing: 4) {
                Text("Configura il match")
                    .font(.system(.headline, design: .rounded, weight: .heavy))
                    .foregroundStyle(.white)
                Text(summaryLine)
                    .font(.system(.caption, design: .rounded, weight: .medium))
                    .foregroundStyle(.white.opacity(0.75))
            }
            Spacer()
        }
        .padding(18)
        .background(
            LinearGradient(colors: [Theme.court, Theme.courtDeep],
                           startPoint: .topLeading, endPoint: .bottomTrailing),
            in: RoundedRectangle(cornerRadius: 20))
    }

    private var summaryLine: String {
        let sets = config.setsToWin == 1 ? "1 set" : (config.setsToWin == 2 ? "2 su 3" : "3 su 5")
        let role = meta.isSpectator ? "Spettatore" : "Giocatore"
        return "\(config.sport.rawValue) · \(config.matchType.rawValue) · \(sets) · \(role)"
    }

    // MARK: - Bottom CTA

    private var bottomBar: some View {
        VStack(spacing: 0) {
            Divider()
            Button {
                Task { await confirmMatch() }
            } label: {
                Group {
                    if sendingInvites {
                        ProgressView()
                            .tint(Theme.tile)
                    } else {
                        Label(needsInvites ? "Invia inviti" : "Avvia partita",
                              systemImage: needsInvites ? "paperplane.fill" : "play.fill")
                            .font(.system(.headline, design: .rounded, weight: .heavy))
                    }
                }
                .foregroundStyle(Theme.tile)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(canStart ? Theme.lime : Theme.lime.opacity(0.35),
                            in: RoundedRectangle(cornerRadius: 16))
            }
            .buttonStyle(PressableStyle())
            .disabled(!canStart || sendingInvites)
            .padding(.horizontal)
            .padding(.top, 12)
            .padding(.bottom, 8)
            .background(Theme.background)
        }
    }

    // MARK: - Section wrapper

    private func sectionCard<Content: View>(
        title: String,
        icon: String,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            Label(title, systemImage: icon)
                .font(.system(.subheadline, design: .rounded, weight: .heavy))
                .foregroundStyle(Theme.accent)

            content()
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .card()
    }

    // MARK: - Sport & formazione

    private var sportPicker: some View {
        HStack(spacing: 10) {
            sportBlock(.tennis, icon: "figure.tennis")
            sportBlock(.padel, icon: "figure.pickleball")
        }
        .onChange(of: config.sport) { _, sport in
            config.matchType = sport == .padel ? .doppio : .singolare
        }
    }

    private var matchTypePicker: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Formazione")
                .font(.system(.caption, design: .rounded, weight: .semibold))
                .foregroundStyle(.secondary)
            HStack(spacing: 8) {
                ForEach(MatchType.allCases) { type in
                    optionChip(type.rawValue, selected: config.matchType == type) {
                        config.matchType = type
                    }
                }
            }
        }
    }

    private var courtSurfacePicker: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Superficie")
                .font(.system(.caption, design: .rounded, weight: .semibold))
                .foregroundStyle(.secondary)
            HStack(spacing: 8) {
                ForEach(CourtSurface.allCases) { surface in
                    optionChip(surface.rawValue, selected: config.courtSurface == surface) {
                        config.courtSurface = surface
                    }
                }
            }
        }
    }

    private func sportBlock(_ sport: Sport, icon: String) -> some View {
        let selected = config.sport == sport
        return Button {
            withAnimation(.spring(duration: 0.25)) { config.sport = sport }
        } label: {
            VStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.title2)
                Text(sport.rawValue)
                    .font(.system(.subheadline, design: .rounded, weight: .heavy))
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 18)
            .foregroundStyle(selected ? Theme.lime : .secondary)
            .background(selected ? Theme.court : Theme.accent.opacity(0.08),
                        in: RoundedRectangle(cornerRadius: 14))
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .strokeBorder(selected ? Theme.lime.opacity(0.5) : .clear, lineWidth: 2)
            )
        }
        .buttonStyle(PressableStyle())
        .accessibilityAddTraits(selected ? .isSelected : [])
    }

    // MARK: - Regole

    private var setsPicker: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Set vincenti")
                .font(.system(.caption, design: .rounded, weight: .semibold))
                .foregroundStyle(.secondary)
            HStack(spacing: 8) {
                optionChip("1 set", selected: config.setsToWin == 1) { config.setsToWin = 1 }
                optionChip("2 su 3", selected: config.setsToWin == 2) { config.setsToWin = 2 }
                optionChip("3 su 5", selected: config.setsToWin == 3) { config.setsToWin = 3 }
            }
        }
    }

    private func ruleToggle(_ title: String, subtitle: String, isOn: Binding<Bool>) -> some View {
        Toggle(isOn: isOn) {
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(.subheadline, design: .rounded, weight: .semibold))
                Text(subtitle)
                    .font(.system(.caption2, design: .rounded))
                    .foregroundStyle(.secondary)
            }
        }
        .tint(Theme.accent)
    }

    // MARK: - Modalità

    private var rolePicker: some View {
        HStack(spacing: 0) {
            roleSegment("Giocatore", icon: "figure.tennis", selected: !meta.isSpectator) {
                meta.isSpectator = false
                meta.homeNameLink = nil
            }
            roleSegment("Spettatore", icon: "eye.fill", selected: meta.isSpectator) {
                meta.isSpectator = true
                appToggles.removeAll()
                meta.homeNameLink = nil
                meta.partnerLink = nil
                meta.opponentLink = nil
                meta.opponent2Link = nil
            }
        }
        .padding(4)
        .background(Theme.accent.opacity(0.08), in: RoundedRectangle(cornerRadius: 14))
    }

    private func roleSegment(_ title: String, icon: String, selected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: { withAnimation(.spring(duration: 0.25)) { action() } }) {
            Label(title, systemImage: icon)
                .font(.system(.footnote, design: .rounded, weight: .bold))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 10)
                .foregroundStyle(selected ? .white : .secondary)
                .background(selected ? Theme.court : .clear, in: RoundedRectangle(cornerRadius: 10))
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(selected ? .isSelected : [])
    }

    private func optionChip(_ title: String, selected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: { withAnimation(.spring(duration: 0.2)) { action() } }) {
            Text(title)
                .font(.system(.caption, design: .rounded, weight: .bold))
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
                .foregroundStyle(selected ? Theme.lime : .secondary)
                .background(selected ? Theme.court : Theme.accent.opacity(0.08),
                            in: Capsule())
        }
        .buttonStyle(.plain)
    }

    // MARK: - Giocatori

    private var venueField: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Dove state giocando?")
                .font(.system(.caption, design: .rounded, weight: .semibold))
                .foregroundStyle(.secondary)
            TextField("es. Campo 1, Circolo Roma…", text: $meta.venue)
                .font(.system(.subheadline, design: .rounded))
                .textInputAutocapitalization(.words)
                .padding(12)
                .background(Theme.accent.opacity(0.06), in: RoundedRectangle(cornerRadius: 12))
        }
    }

    @ViewBuilder
    private var spectatorPlayerFields: some View {
        if config.matchType == .doppio {
            playerRow("Giocatore 1 · squadra A", text: $meta.homeName, field: .homeName)
            playerRow("Giocatore 2 · squadra A", text: $meta.partner, field: .partner)
            playerRow("Giocatore 3 · squadra B", text: $meta.opponent, field: .opponent)
            playerRow("Giocatore 4 · squadra B", text: $meta.opponent2, field: .opponent2)
        } else {
            playerRow("Giocatore 1", text: $meta.homeName, field: .homeName)
            playerRow("Giocatore 2", text: $meta.opponent, field: .opponent)
        }
    }

    @ViewBuilder
    private var playerModeFields: some View {
        if config.matchType == .doppio {
            playerRow("Partner", text: $meta.partner, field: .partner)
            playerRow("Avversario 1", text: $meta.opponent, field: .opponent)
            playerRow("Avversario 2", text: $meta.opponent2, field: .opponent2)
        } else {
            playerRow("Avversario", text: $meta.opponent, field: .opponent)
        }
    }

    private var footerLines: [String] {
        if meta.isSpectator {
            var lines = ["Compila tutti i nomi per avviare."]
            if !appleUserID.isEmpty {
                lines.append("Attiva «Cerca su SetPoint» per trovare i profili dei giocatori.")
            } else {
                lines.append("Accedi dal Profilo per cercare i giocatori con l'app.")
            }
            return lines
        }
        var lines = ["Parte subito sul telefono; il Watch si apre in automatico se collegato."]
        if appleUserID.isEmpty {
            lines.append("Accedi dal Profilo per invitare giocatori con l'app.")
        } else if !meta.links.isEmpty {
            lines.append("I giocatori collegati devono accettare prima che inizi.")
        }
        return lines
    }

    private var footerNote: some View {
        HStack(alignment: .top, spacing: 8) {
            Image(systemName: "info.circle.fill")
                .font(.caption)
                .foregroundStyle(Theme.accent)
            Text(footerLines.joined(separator: " "))
                .font(.system(.caption2, design: .rounded))
                .foregroundStyle(.secondary)
        }
        .padding(12)
        .background(Theme.accent.opacity(0.08), in: RoundedRectangle(cornerRadius: 12))
    }

    @ViewBuilder
    private func playerRow(_ label: String,
                           text: Binding<String>, field: SearchField) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(label)
                .font(.system(.caption, design: .rounded, weight: .semibold))
                .foregroundStyle(.secondary)

            TextField("Nome", text: text)
                .font(.system(.subheadline, design: .rounded, weight: .medium))
                .padding(12)
                .background(Theme.accent.opacity(0.06), in: RoundedRectangle(cornerRadius: 12))
                .onChange(of: text.wrappedValue) { _, value in
                    if let link = link(for: field), link.fullName != value {
                        setLink(nil, for: field)
                    }
                    if appToggles.contains(field), link(for: field) == nil {
                        triggerSearch(queryText: value, field: field)
                    }
                }

            if !appleUserID.isEmpty {
                Button {
                    withAnimation(.spring(duration: 0.25)) {
                        if appToggles.contains(field) {
                            appToggles.remove(field)
                            setLink(nil, for: field)
                            if activeSearchField == field {
                                searchTask?.cancel()
                                searchResults = []
                                activeSearchField = nil
                            }
                        } else {
                            appToggles.insert(field)
                            triggerSearch(queryText: text.wrappedValue, field: field)
                        }
                    }
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: appToggles.contains(field) ? "checkmark.circle.fill" : "circle")
                            .foregroundStyle(appToggles.contains(field) ? Theme.accent : Color.secondary.opacity(0.45))
                        Text("Cerca su SetPoint")
                            .font(.system(.footnote, design: .rounded, weight: .semibold))
                        Spacer()
                        if link(for: field) != nil {
                            Image(systemName: "checkmark.seal.fill")
                                .foregroundStyle(Theme.win)
                        }
                    }
                    .foregroundStyle(.secondary)
                    .padding(.vertical, 4)
                }
                .buttonStyle(.plain)

                if let link = link(for: field) {
                    linkedChip(link, field: field)
                } else if appToggles.contains(field) {
                    searchStatus(for: text.wrappedValue, field: field)
                }
            }
        }
        .padding(.vertical, 4)
    }

    @ViewBuilder
    private func searchStatus(for query: String, field: SearchField) -> some View {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        if activeSearchField == field && !searchResults.isEmpty {
            resultsList(field: field)
        } else if searching && activeSearchField == field {
            HStack(spacing: 8) {
                ProgressView().controlSize(.small)
                Text("Ricerca…")
                    .font(.system(.caption, design: .rounded))
                    .foregroundStyle(.secondary)
            }
        } else if let searchError, activeSearchField == field {
            Label(searchError, systemImage: "exclamationmark.triangle.fill")
                .font(.system(.caption, design: .rounded))
                .foregroundStyle(Theme.loss)
        } else if trimmed.count >= 2 {
            Label("Nessun profilo trovato", systemImage: "magnifyingglass")
                .font(.system(.caption, design: .rounded))
                .foregroundStyle(.secondary)
        }
    }

    private func linkedChip(_ link: LinkedPlayer, field: SearchField) -> some View {
        HStack(spacing: 10) {
            PlayerAvatar(appleUserID: link.userID, name: link.fullName, size: 36)
            VStack(alignment: .leading, spacing: 2) {
                Text(link.fullName)
                    .font(.system(.footnote, design: .rounded, weight: .bold))
                Text("@\(link.username)")
                    .font(.system(.caption2, design: .rounded))
                    .foregroundStyle(Theme.accent)
            }
            Spacer()
            Button {
                withAnimation(.spring(duration: 0.25)) { setLink(nil, for: field) }
            } label: {
                Image(systemName: "xmark.circle.fill")
                    .font(.title3)
                    .foregroundStyle(.tertiary)
            }
            .buttonStyle(.plain)
        }
        .padding(12)
        .background(Theme.win.opacity(0.10), in: RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .strokeBorder(Theme.win.opacity(0.3), lineWidth: 1)
        )
    }

    private func resultsList(field: SearchField) -> some View {
        VStack(spacing: 0) {
            ForEach(searchResults) { player in
                Button {
                    withAnimation(.spring(duration: 0.25)) { selectPlayer(player, field: field) }
                } label: {
                    HStack(spacing: 12) {
                        PlayerAvatar(appleUserID: player.appleUserID, name: player.fullName, size: 36)
                        VStack(alignment: .leading, spacing: 2) {
                            Text(player.fullName)
                                .font(.system(.subheadline, design: .rounded, weight: .bold))
                                .foregroundStyle(.primary)
                            Text("@\(player.username)")
                                .font(.system(.caption, design: .rounded))
                                .foregroundStyle(Theme.accent)
                        }
                        Spacer()
                        Image(systemName: "plus.circle.fill")
                            .foregroundStyle(Theme.accent)
                    }
                    .padding(.vertical, 10)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                if player.id != searchResults.last?.id {
                    Divider().padding(.leading, 48)
                }
            }
        }
        .padding(.horizontal, 4)
        .background(Theme.accent.opacity(0.05), in: RoundedRectangle(cornerRadius: 12))
    }

    // MARK: - Collegamento profili

    private func link(for field: SearchField) -> LinkedPlayer? {
        switch field {
        case .homeName: meta.homeNameLink
        case .partner: meta.partnerLink
        case .opponent: meta.opponentLink
        case .opponent2: meta.opponent2Link
        }
    }

    private func setLink(_ link: LinkedPlayer?, for field: SearchField) {
        switch field {
        case .homeName: meta.homeNameLink = link
        case .partner: meta.partnerLink = link
        case .opponent: meta.opponentLink = link
        case .opponent2: meta.opponent2Link = link
        }
    }

    private func triggerSearch(queryText: String, field: SearchField) {
        searchTask?.cancel()
        activeSearchField = field

        let trimmed = queryText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard trimmed.count >= 2 else {
            searchResults = []
            searching = false
            searchError = nil
            return
        }

        searching = true
        searchError = nil
        searchTask = Task {
            try? await Task.sleep(nanoseconds: 300_000_000)
            guard !Task.isCancelled else { return }

            do {
                let profiles = try await CloudKitManager.shared.searchPlayers(queryText: trimmed)
                guard !Task.isCancelled else { return }
                searchResults = profiles.filter { $0.appleUserID != appleUserID }
                searchError = nil
            } catch {
                guard !Task.isCancelled else { return }
                searchResults = []
                searchError = error.localizedDescription
            }
            searching = false
        }
    }

    private func selectPlayer(_ player: PlayerProfile, field: SearchField) {
        let link = LinkedPlayer(userID: player.appleUserID,
                                username: player.username,
                                fullName: player.fullName)
        switch field {
        case .homeName:
            meta.homeName = player.fullName
            meta.homeNameLink = link
        case .partner:
            meta.partner = player.fullName
            meta.partnerLink = link
        case .opponent:
            meta.opponent = player.fullName
            meta.opponentLink = link
        case .opponent2:
            meta.opponent2 = player.fullName
            meta.opponent2Link = link
        }
        searchTask?.cancel()
        searchResults = []
        activeSearchField = nil
        searching = false
    }

    private func preparedMeta() -> MatchMeta {
        var meta = meta
        if config.matchType == .singolare {
            meta.partner = ""
            meta.partnerLink = nil
            meta.opponent2 = ""
            meta.opponent2Link = nil
        }
        if meta.isSpectator {
            meta.homeNameLink = nil
            meta.partnerLink = nil
            meta.opponentLink = nil
            meta.opponent2Link = nil
        }
        return meta
    }

    private func confirmMatch() async {
        let meta = preparedMeta()
        inviteError = nil

        if MatchInviteSync.requiresInvites(meta: meta) {
            sendingInvites = true
            defer { sendingInvites = false }
            do {
                try await MatchInviteSync.shared.sendInvites(config: config, meta: meta)
                dismiss()
            } catch {
                inviteError = error.localizedDescription
            }
        } else {
            WatchSync.shared.startMatch(config: config, meta: meta)
            dismiss()
        }
    }
}

#Preview {
    NewMatchSheet()
}
