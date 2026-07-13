import SwiftUI
import SwiftData

/// Collegamento retroattivo: aggiungi giocatori iscritti a partite
/// giocate solo con il nome testuale, così lo storico arriva anche a loro.
struct MatchLinkingSection: View {
    @Bindable var match: MatchRecord
    @Environment(\.modelContext) private var context
    @AppStorage("appleUserID") private var appleUserID = ""

    @State private var activeSlot: MatchRecord.PlayerSlot? = nil
    @State private var searchText = ""
    @State private var searchResults: [PlayerProfile] = []
    @State private var searching = false
    @State private var searchError: String? = nil
    @State private var searchTask: Task<Void, Never>? = nil
    @State private var linkingSlot: MatchRecord.PlayerSlot? = nil
    @State private var statusMessage: String? = nil
    @State private var errorMessage: String? = nil

    private var visibleSlots: [MatchRecord.PlayerSlot] {
        guard !match.isSpectator else { return [] }
        if match.matchType == MatchType.doppio.rawValue {
            return MatchRecord.PlayerSlot.allCases.filter {
                !match.displayName(for: $0).isEmpty
            }
        }
        return [.opponent]
    }

    var body: some View {
        if appleUserID.isEmpty {
            loginHint
        } else if !match.isSpectator, !visibleSlots.isEmpty {
            linkingCard
        }
    }

    private var loginHint: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label("Condividi lo storico", systemImage: "person.crop.circle.badge.plus")
                .font(.system(.subheadline, design: .rounded, weight: .heavy))
                .foregroundStyle(Theme.accent)
            Text("Accedi con Apple dal Profilo per collegare i giocatori e inviare questa partita al loro storico.")
                .font(.system(.caption, design: .rounded))
                .foregroundStyle(.secondary)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .card()
    }

    private var linkingCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            Label("Aggiungi su SetPoint", systemImage: "person.crop.circle.badge.plus")
                .font(.system(.subheadline, design: .rounded, weight: .heavy))
                .foregroundStyle(Theme.accent)

            Text("Hai giocato con nomi scritti a mano? Se ora sono su SetPoint, collegali: la partita comparirà anche nel loro storico.")
                .font(.system(.caption, design: .rounded))
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)

            ForEach(visibleSlots) { slot in
                slotRow(slot)
            }

            if let status = statusMessage {
                Label(status, systemImage: "checkmark.circle.fill")
                    .font(.system(.caption, design: .rounded, weight: .semibold))
                    .foregroundStyle(Theme.win)
            }
            if let error = errorMessage {
                Label(error, systemImage: "exclamationmark.triangle.fill")
                    .font(.system(.caption, design: .rounded))
                    .foregroundStyle(Theme.loss)
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .card()
    }

    @ViewBuilder
    private func slotRow(_ slot: MatchRecord.PlayerSlot) -> some View {
        let linked = !match.userID(for: slot).isEmpty
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text(match.slotLabel(for: slot))
                    .font(.system(.caption, design: .rounded, weight: .semibold))
                    .foregroundStyle(.secondary)
                Spacer()
                Text(match.displayName(for: slot))
                    .font(.system(.footnote, design: .rounded, weight: .bold))
            }

            if linked {
                HStack(spacing: 10) {
                    PlayerAvatar(
                        appleUserID: match.userID(for: slot),
                        name: match.displayName(for: slot),
                        size: 36
                    )
                    VStack(alignment: .leading, spacing: 2) {
                        Text(match.displayName(for: slot))
                            .font(.system(.footnote, design: .rounded, weight: .bold))
                        if !match.username(for: slot).isEmpty {
                            Text("@\(match.username(for: slot))")
                                .font(.system(.caption2, design: .rounded))
                                .foregroundStyle(Theme.accent)
                        }
                    }
                    Spacer()
                    Image(systemName: "checkmark.seal.fill")
                        .foregroundStyle(Theme.win)
                }
                .padding(12)
                .background(Theme.win.opacity(0.10), in: RoundedRectangle(cornerRadius: 12))
            } else {
                if activeSlot == slot {
                    TextField("Cerca nome o @username", text: $searchText)
                        .textFieldStyle(.roundedBorder)
                        .font(.system(.subheadline, design: .rounded))
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                        .onChange(of: searchText) { _, value in
                            triggerSearch(queryText: value)
                        }

                    searchStatus

                    Button("Annulla ricerca") {
                        activeSlot = nil
                        searchText = ""
                        searchResults = []
                        searchError = nil
                    }
                    .font(.system(.caption, design: .rounded, weight: .semibold))
                    .foregroundStyle(.secondary)
                } else {
                    Button {
                        activeSlot = slot
                        searchText = match.displayName(for: slot)
                        triggerSearch(queryText: searchText)
                    } label: {
                        Label("Collega su SetPoint", systemImage: "magnifyingglass")
                            .font(.system(.footnote, design: .rounded, weight: .bold))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(Theme.accent.opacity(0.10), in: RoundedRectangle(cornerRadius: 12))
                            .foregroundStyle(Theme.accent)
                    }
                    .buttonStyle(PressableStyle())
                    .disabled(linkingSlot != nil)
                }
            }
        }
        .padding(.vertical, 4)
    }

    @ViewBuilder
    private var searchStatus: some View {
        if searching {
            HStack(spacing: 8) {
                ProgressView().controlSize(.small)
                Text("Ricerca…")
                    .font(.system(.caption, design: .rounded))
                    .foregroundStyle(.secondary)
            }
        } else if let searchError {
            Label(searchError, systemImage: "exclamationmark.triangle.fill")
                .font(.system(.caption, design: .rounded))
                .foregroundStyle(Theme.loss)
        } else if !searchResults.isEmpty {
            VStack(spacing: 0) {
                ForEach(searchResults) { player in
                    Button {
                        guard let slot = activeSlot else { return }
                        link(player, to: slot)
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
                            if linkingSlot == activeSlot {
                                ProgressView().controlSize(.small)
                            } else {
                                Image(systemName: "plus.circle.fill")
                                    .foregroundStyle(Theme.accent)
                            }
                        }
                        .padding(.vertical, 10)
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    .disabled(linkingSlot != nil)
                    if player.id != searchResults.last?.id {
                        Divider().padding(.leading, 48)
                    }
                }
            }
            .padding(.horizontal, 4)
            .background(Theme.accent.opacity(0.05), in: RoundedRectangle(cornerRadius: 12))
        } else if searchText.trimmingCharacters(in: .whitespacesAndNewlines).count >= 2 {
            Label("Nessun profilo trovato", systemImage: "magnifyingglass")
                .font(.system(.caption, design: .rounded))
                .foregroundStyle(.secondary)
        }
    }

    private func triggerSearch(queryText: String) {
        searchTask?.cancel()
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

    private func link(_ player: PlayerProfile, to slot: MatchRecord.PlayerSlot) {
        linkingSlot = slot
        errorMessage = nil
        statusMessage = nil
        Task {
            do {
                try await CloudSync.shared.linkPlayer(
                    record: match,
                    slot: slot,
                    player: player,
                    context: context
                )
                activeSlot = nil
                searchText = ""
                searchResults = []
                statusMessage = "Partita inviata a @\(player.username): la troverà nel suo storico."
            } catch {
                errorMessage = error.localizedDescription
            }
            linkingSlot = nil
        }
    }
}
