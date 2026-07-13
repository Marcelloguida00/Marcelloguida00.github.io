import SwiftUI
import SwiftData

/// Tabellone gigante in tempo reale del match in corso (Live Sync).
/// Stile "segnapunti da campo": set precedenti, targa giocatori, set,
/// game e punti su fondo verde. Toccando una riga si assegna il punto
/// direttamente dal telefono (funziona anche a Watch scollegato).
struct LiveScreen: View {
    private var sync: WatchSync { WatchSync.shared }
    private let cloud = CloudSync.shared
    private let invites = MatchInviteSync.shared
    // Il filtro sulla timeline è in memoria: è un array codificato come blob,
    // CoreData non sa tradurre `.count` in SQL e crasha all'avvio.
    @Query(filter: #Predicate<MatchRecord> { !$0.finished },
           sort: \MatchRecord.date, order: .reverse)
    private var unfinishedMatches: [MatchRecord]
    private var suspendedMatches: [MatchRecord] {
        unfinishedMatches.filter { !$0.timeline.isEmpty }
    }
    @Environment(\.modelContext) private var context
    @State private var showNewMatch = false
    @State private var showEndConfirm = false
    @State private var showPauseConfirm = false
    @State private var showCancelInvitesConfirm = false
    @State private var processingInviteID: String? = nil

    var body: some View {
        NavigationStack {
            Group {
                if let live = sync.live {
                    scoreboard(live, editable: true)
                } else if let joined = cloud.joinedMatch {
                    sharedScoreboard(joined)
                } else if let session = invites.outgoingSession {
                    waitingForAcceptance(session)
                } else {
                    emptyState
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Theme.background)
            .navigationTitle("Live")
            .sheet(isPresented: $showNewMatch) {
                NewMatchSheet()
            }
            .task {
                while !Task.isCancelled {
                    await invites.refreshAll()
                    await cloud.refreshLive()
                    try? await Task.sleep(for: .seconds(5))
                }
            }
        }
    }

    // MARK: - Nessun match

    private var emptyState: some View {
        ScrollView {
            VStack(spacing: 24) {
                VStack(spacing: 16) {
                    Image(systemName: "tennisball.fill")
                        .font(.system(size: 56))
                        .foregroundStyle(Theme.lime)
                        .padding(24)
                        .background(.white.opacity(0.08), in: Circle())
                    Text("Pronto a scendere in campo?")
                        .font(.system(.title2, design: .rounded, weight: .heavy))
                        .foregroundStyle(.white)
                        .multilineTextAlignment(.center)
                    Text("Avvia la partita da qui.\nIl tabellone si aprirà sul Watch in automatico.")
                        .font(.system(.subheadline, design: .rounded))
                        .foregroundStyle(.white.opacity(0.75))
                        .multilineTextAlignment(.center)

                    Button {
                        showNewMatch = true
                    } label: {
                        Label("Nuova partita", systemImage: "play.fill")
                            .font(.system(.headline, design: .rounded, weight: .heavy))
                            .foregroundStyle(Theme.tile)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(Theme.lime, in: RoundedRectangle(cornerRadius: 16))
                    }
                    .buttonStyle(PressableStyle())
                    .padding(.top, 6)
                }
                .padding(28)
                .frame(maxWidth: .infinity)
                .background(
                    LinearGradient(colors: [Theme.court, Theme.courtDeep],
                                   startPoint: .top, endPoint: .bottom),
                    in: RoundedRectangle(cornerRadius: 24))
                .padding(.horizontal)

                HStack(spacing: 12) {
                    hint(icon: "applewatch.radiowaves.left.and.right",
                         text: "Live sync dal polso")
                    hint(icon: "bolt.fill", text: "Live Activity sulla Lock Screen")
                }
                .padding(.horizontal)

                if !invites.incoming.isEmpty {
                    incomingInvitesSection
                        .padding(.horizontal)
                }

                if let message = invites.statusMessage {
                    Label(message, systemImage: "info.circle.fill")
                        .font(.system(.footnote, design: .rounded))
                        .foregroundStyle(Theme.accent)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }

                if sync.canRestoreMatch {
                    resumeLocalCard
                        .padding(.horizontal)
                } else if let suspended = suspendedMatches.first {
                    resumeSuspendedCard(suspended)
                        .padding(.horizontal)
                } else if cloud.canRejoinSharedMatch {
                    resumeSharedCard
                        .padding(.horizontal)
                }

                if !cloud.remoteLive.isEmpty, cloud.joinedMatch == nil {
                    remoteSection
                        .padding(.horizontal)
                }

                if !sync.isWatchAppInstalled {
                    watchInstallBanner
                        .padding(.horizontal)
                }
            }
            .padding(.vertical)
        }
    }

    // MARK: - Inviti in arrivo

    private var incomingInvitesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Inviti a partita", systemImage: "envelope.badge.fill")
                .font(.system(.subheadline, design: .rounded, weight: .heavy))
                .foregroundStyle(Theme.accent)

            ForEach(invites.incoming) { invite in
                incomingInviteCard(invite)
            }
        }
    }

    private func incomingInviteCard(_ invite: MatchInvite) -> some View {
        let isProcessing = processingInviteID == invite.id
        return VStack(alignment: .leading, spacing: 12) {
            Text("\(invite.creatorName) ti ha aggiunto a una partita")
                .font(.system(.subheadline, design: .rounded, weight: .bold))
            HStack(spacing: 8) {
                Chip(text: invite.config.sport.rawValue, icon: "figure.tennis")
                Chip(text: invite.config.matchType.rawValue)
                if !invite.meta.displayVenue.isEmpty {
                    Chip(text: invite.meta.displayVenue)
                }
            }
            HStack(spacing: 10) {
                Button {
                    processingInviteID = invite.id
                    Task {
                        await invites.decline(invite)
                        processingInviteID = nil
                    }
                } label: {
                    Group {
                        if isProcessing {
                            ProgressView()
                        } else {
                            Text("Rifiuta")
                        }
                    }
                    .font(.system(.subheadline, design: .rounded, weight: .bold))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(Theme.loss.opacity(0.12), in: RoundedRectangle(cornerRadius: 12))
                    .foregroundStyle(Theme.loss)
                    .contentShape(Rectangle())
                }
                .buttonStyle(PressableStyle())
                .disabled(isProcessing)

                Button {
                    processingInviteID = invite.id
                    Task {
                        await invites.accept(invite)
                        processingInviteID = nil
                    }
                } label: {
                    Group {
                        if isProcessing {
                            ProgressView()
                                .tint(Theme.tile)
                        } else {
                            Text("Accetta")
                        }
                    }
                    .font(.system(.subheadline, design: .rounded, weight: .bold))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(Theme.lime, in: RoundedRectangle(cornerRadius: 12))
                    .foregroundStyle(Theme.tile)
                    .contentShape(Rectangle())
                }
                .buttonStyle(PressableStyle())
                .disabled(isProcessing)
            }
        }
        .padding(16)
        .card()
    }

    // MARK: - In attesa di accettazione (creatore)

    private func waitingForAcceptance(_ session: OutgoingMatchSession) -> some View {
        ScrollView {
            VStack(spacing: 20) {
                if !invites.incoming.isEmpty {
                    incomingInvitesSection
                        .padding(.horizontal)
                }

                VStack(spacing: 16) {
                    Image(systemName: "hourglass")
                        .font(.system(size: 48))
                        .foregroundStyle(Theme.lime)
                    Text("In attesa dei giocatori")
                        .font(.system(.title2, design: .rounded, weight: .heavy))
                        .foregroundStyle(.white)
                    Text("Quando tutti avranno accettato, potrai avviare la partita con il pulsante qui sotto.")
                        .font(.system(.subheadline, design: .rounded))
                        .foregroundStyle(.white.opacity(0.75))
                        .multilineTextAlignment(.center)
                }
                .padding(28)
                .frame(maxWidth: .infinity)
                .background(
                    LinearGradient(colors: [Theme.court, Theme.courtDeep],
                                   startPoint: .top, endPoint: .bottom),
                    in: RoundedRectangle(cornerRadius: 24))
                .padding(.horizontal)

                VStack(alignment: .leading, spacing: 10) {
                    Text("STATO INVITI")
                        .font(.system(.caption2, design: .rounded, weight: .bold))
                        .foregroundStyle(.secondary)

                    ForEach(session.invites, id: \.id) { invite in
                        HStack(spacing: 12) {
                            Image(systemName: statusIcon(invite.status))
                                .foregroundStyle(statusColor(invite.status))
                            VStack(alignment: .leading, spacing: 2) {
                                Text(invite.inviteeName)
                                    .font(.system(.subheadline, design: .rounded, weight: .bold))
                                Text(statusLabel(invite.status))
                                    .font(.system(.caption, design: .rounded))
                                    .foregroundStyle(.secondary)
                            }
                            Spacer()
                        }
                        .padding(.vertical, 4)
                    }
                }
                .padding(16)
                .card()
                .padding(.horizontal)

                if let message = invites.statusMessage {
                    Text(message)
                        .font(.system(.footnote, design: .rounded))
                        .foregroundStyle(Theme.accent)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }

                if session.allAccepted {
                    Button {
                        Task { await invites.startOutgoingMatch() }
                    } label: {
                        Label("Avvia partita", systemImage: "play.fill")
                            .font(.system(.headline, design: .rounded, weight: .heavy))
                            .foregroundStyle(Theme.tile)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(Theme.lime, in: RoundedRectangle(cornerRadius: 16))
                    }
                    .buttonStyle(PressableStyle())
                    .padding(.horizontal)
                }

                Button(role: .destructive) {
                    showCancelInvitesConfirm = true
                } label: {
                    Text("Annulla inviti")
                        .font(.system(.subheadline, design: .rounded, weight: .bold))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(Theme.loss.opacity(0.12), in: RoundedRectangle(cornerRadius: 14))
                }
                .buttonStyle(PressableStyle())
                .padding(.horizontal)
            }
            .padding(.vertical)
        }
        .confirmationDialog("Annullare gli inviti?",
                            isPresented: $showCancelInvitesConfirm,
                            titleVisibility: .visible) {
            Button("Annulla inviti", role: .destructive) {
                Task { await invites.cancelOutgoing() }
            }
        } message: {
            Text("I giocatori non potranno più accettare questa partita.")
        }
    }

    private func statusIcon(_ status: MatchInviteStatus) -> String {
        switch status {
        case .pending: "clock.fill"
        case .accepted: "checkmark.circle.fill"
        case .declined: "xmark.circle.fill"
        case .cancelled: "slash.circle.fill"
        case .started: "play.circle.fill"
        }
    }

    private func statusColor(_ status: MatchInviteStatus) -> Color {
        switch status {
        case .pending: Theme.accent
        case .accepted, .started: Theme.win
        case .declined, .cancelled: Theme.loss
        }
    }

    private func statusLabel(_ status: MatchInviteStatus) -> String {
        switch status {
        case .pending: "In attesa"
        case .accepted: "Ha accettato"
        case .declined: "Ha rifiutato"
        case .cancelled: "Annullato"
        case .started: "Partita avviata"
        }
    }

    // MARK: - Live degli altri partecipanti

    private var remoteSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                liveBadge
                Text("Partite dei tuoi giocatori")
                    .font(.system(.subheadline, design: .rounded, weight: .heavy))
                    .foregroundStyle(.primary)
            }
            ForEach(cloud.remoteLive) { match in
                remoteCard(match)
            }
        }
    }

    /// Indicatore live: lime sul verde campo, non rosso da errore.
    private var liveBadge: some View {
        HStack(spacing: 5) {
            Circle()
                .fill(Theme.lime)
                .frame(width: 7, height: 7)
            Text("LIVE")
                .font(.system(.caption2, design: .rounded, weight: .heavy))
                .kerning(1)
                .foregroundStyle(Theme.court)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(Theme.lime.opacity(0.35), in: Capsule())
        .accessibilityLabel("In diretta")
    }

    private var resumeLocalCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Partita in pausa", systemImage: "pause.circle.fill")
                .font(.system(.subheadline, design: .rounded, weight: .heavy))
                .foregroundStyle(Theme.accent)
            Text("Hai una partita interrotta su questo dispositivo. Puoi riprenderla da dove eri rimasto.")
                .font(.system(.caption, design: .rounded))
                .foregroundStyle(.secondary)
            Button {
                _ = sync.restoreMatchIfNeeded()
            } label: {
                Text("Riprendi partita")
                    .font(.system(.subheadline, design: .rounded, weight: .bold))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(Theme.lime, in: RoundedRectangle(cornerRadius: 12))
                    .foregroundStyle(Theme.tile)
            }
            .buttonStyle(PressableStyle())
        }
        .padding(16)
        .card()
    }

    private func resumeSuspendedCard(_ match: MatchRecord) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Partita sospesa", systemImage: "pause.circle.fill")
                .font(.system(.subheadline, design: .rounded, weight: .heavy))
                .foregroundStyle(Theme.accent)
            Text("Riprendi \(match.isSpectator ? match.spectatorTitle : "vs \(match.opponentsLabel)") con punteggio \(match.scoreline).")
                .font(.system(.caption, design: .rounded))
                .foregroundStyle(.secondary)
            Button {
                guard sync.resumeFromHistory(match) else { return }
                context.delete(match)
                try? context.save()
            } label: {
                Text("Riprendi partita")
                    .font(.system(.subheadline, design: .rounded, weight: .bold))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(Theme.lime, in: RoundedRectangle(cornerRadius: 12))
                    .foregroundStyle(Theme.tile)
            }
            .buttonStyle(PressableStyle())
        }
        .padding(16)
        .card()
    }

    private var resumeSharedCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Tabellone condiviso", systemImage: "person.2.fill")
                .font(.system(.subheadline, design: .rounded, weight: .heavy))
                .foregroundStyle(Theme.accent)
            Text("Sei in una partita condivisa. Tocca per rientrare nel tabellone comune.")
                .font(.system(.caption, design: .rounded))
                .foregroundStyle(.secondary)
            Button {
                Task {
                    await cloud.refreshLive()
                    await invites.refreshAll()
                }
            } label: {
                Text("Rientra nel tabellone")
                    .font(.system(.subheadline, design: .rounded, weight: .bold))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(Theme.court.opacity(0.12), in: RoundedRectangle(cornerRadius: 12))
                    .foregroundStyle(Theme.court)
            }
            .buttonStyle(PressableStyle())
        }
        .padding(16)
        .card()
    }

    private func sharedScoreboard(_ match: RemoteLiveMatch) -> some View {
        ScrollView {
            VStack(spacing: 20) {
                HStack(spacing: 8) {
                    liveBadge
                    Text("Tabellone condiviso con \(match.creatorName)")
                        .font(.system(.footnote, design: .rounded, weight: .semibold))
                        .foregroundStyle(.secondary)
                }

                board(match.score, editable: false)
                    .padding(.horizontal, 12)
                    .animation(.spring(duration: 0.3), value: match.score)

                TimelineView(.periodic(from: match.score.startedAt, by: 1)) { context in
                    Label(Self.format(context.date.timeIntervalSince(match.score.startedAt)),
                          systemImage: "stopwatch.fill")
                        .font(.system(.title3, design: .rounded, weight: .bold))
                        .monospacedDigit()
                        .foregroundStyle(.secondary)
                }

                if let winner = match.score.winner {
                    Label("Vince \(match.score.teams[winner])", systemImage: "trophy.fill")
                        .font(.system(.title3, design: .rounded, weight: .heavy))
                        .foregroundStyle(Theme.plate)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 12)
                        .background(Theme.court, in: Capsule())
                }

                Text("Il punteggio è aggiornato da \(match.creatorName). Tutti vedono lo stesso tabellone.")
                    .font(.system(.footnote, design: .rounded))
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }
            .padding(.vertical)
        }
    }

    /// Tabellone compatto in sola lettura del match di un altro giocatore.
    private func remoteCard(_ match: RemoteLiveMatch) -> some View {
        let live = match.score
        return VStack(spacing: 12) {
            HStack {
                Text(live.matchName.isEmpty
                        ? "PARTITA DI \(match.creatorName.uppercased())"
                        : live.matchName.uppercased())
                    .font(.system(.footnote, design: .rounded, weight: .heavy))
                    .kerning(2)
                    .foregroundStyle(.white)
                    .lineLimit(1)
                    .minimumScaleFactor(0.6)
                Spacer()
                if let winner = live.winner {
                    Label("Vince \(live.teams[winner])", systemImage: "trophy.fill")
                        .font(.system(.caption2, design: .rounded, weight: .heavy))
                        .foregroundStyle(Theme.plate)
                } else {
                    TimelineView(.periodic(from: live.startedAt, by: 1)) { context in
                        Label(Self.format(context.date.timeIntervalSince(live.startedAt)),
                              systemImage: "stopwatch.fill")
                            .font(.system(.caption, design: .rounded, weight: .bold))
                            .monospacedDigit()
                            .foregroundStyle(.white.opacity(0.85))
                    }
                }
            }

            ForEach(0..<2, id: \.self) { team in
                HStack(spacing: 8) {
                    HStack(spacing: 6) {
                        Text(live.teams[team])
                            .font(.system(.subheadline, design: .rounded, weight: .heavy))
                            .foregroundStyle(Theme.tile)
                            .lineLimit(1)
                            .minimumScaleFactor(0.4)
                        if live.server == team && live.winner == nil {
                            Image(systemName: "tennisball.fill")
                                .font(.caption2)
                                .foregroundStyle(Theme.court)
                        }
                    }
                    .padding(.horizontal, 8)
                    .frame(maxWidth: .infinity, minHeight: 38, alignment: .leading)
                    .background(Theme.plate, in: RoundedRectangle(cornerRadius: 8))

                    tile("\(live.setsWon[team])", color: Theme.tile,
                         background: Theme.lime, width: 34, height: 42, size: 22)
                    tile("\(live.games[team])", color: Theme.plate,
                         width: 38, height: 42, size: 22)

                    Text(live.points[team])
                        .font(.system(size: 24, weight: .heavy, design: .rounded))
                        .monospacedDigit()
                        .contentTransition(.numericText())
                        .minimumScaleFactor(0.4)
                        .foregroundStyle(Theme.tile)
                        .frame(width: 56, height: 42)
                        .background(.white, in: RoundedRectangle(cornerRadius: 8))
                }
                .accessibilityElement(children: .combine)
                .accessibilityLabel("\(live.teams[team]): set \(live.setsWon[team]), game \(live.games[team]), punti \(live.points[team])")
            }

            if !live.sets.isEmpty || live.inTiebreak {
                HStack(spacing: 6) {
                    ForEach(Array(live.sets.enumerated()), id: \.offset) { _, set in
                        Chip(text: set)
                    }
                    if live.inTiebreak {
                        Text("TIE-BREAK")
                            .font(.system(.caption2, design: .rounded, weight: .heavy))
                            .kerning(1)
                            .foregroundStyle(Theme.tile)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 3)
                            .background(Theme.lime, in: Capsule())
                    }
                    Spacer()
                }
            }
        }
        .padding(16)
        .background(
            LinearGradient(colors: [Theme.court, Theme.courtDeep],
                           startPoint: .top, endPoint: .bottom),
            in: RoundedRectangle(cornerRadius: 20))
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .strokeBorder(.white.opacity(0.2), lineWidth: 1)
        )
        .animation(.spring(duration: 0.3), value: live)
    }

    private func hint(icon: String, text: String) -> some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundStyle(Theme.accent)
            Text(text)
                .font(.system(.caption, design: .rounded, weight: .semibold))
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .padding(.horizontal, 8)
        .card()
    }

    private var watchInstallBanner: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 10) {
                Image(systemName: "applewatch.slash")
                    .font(.title3)
                    .foregroundStyle(Theme.loss)
                Text("Apple Watch app non installata")
                    .font(.system(.subheadline, design: .rounded, weight: .bold))
                    .foregroundStyle(.primary)
            }

            Text("Installa SetPoint sul Watch per segnare i punti dal polso. La partita si avvia sempre dall'iPhone.")
                .font(.system(.footnote, design: .rounded))
                .foregroundStyle(.secondary)
                .lineLimit(nil)
                .fixedSize(horizontal: false, vertical: true)

            Text("Se l'icona è già sul Watch ma non si apre, elimina SetPoint da iPhone e Watch, poi reinstalla da Xcode con ⌘R (scheme SetPoint → iPhone).")
                .font(.system(.caption, design: .rounded))
                .foregroundStyle(.secondary)
                .lineLimit(nil)
                .fixedSize(horizontal: false, vertical: true)

            VStack(alignment: .leading, spacing: 10) {
                Text("Come installarla:")
                    .font(.system(.footnote, design: .rounded, weight: .bold))
                    .foregroundStyle(.primary)
                
                VStack(alignment: .leading, spacing: 8) {
                    instructionRow(number: "1", text: "Apri l'applicazione nativa 'Watch' sul tuo iPhone.")
                    instructionRow(number: "2", text: "Scorri verso il basso fino alla sezione 'Applicazioni disponibili'.")
                    instructionRow(number: "3", text: "Cerca 'SetPoint' e tocca 'Installa' accanto ad essa.")
                }
            }
        }
        .padding(16)
        .card()
    }

    private func instructionRow(number: String, text: String) -> some View {
        HStack(alignment: .top, spacing: 8) {
            Text(number)
                .font(.system(.caption, design: .rounded, weight: .bold))
                .foregroundStyle(Theme.tile)
                .frame(width: 18, height: 18)
                .background(Theme.lime, in: Circle())
            Text(text)
                .font(.system(.footnote, design: .rounded))
                .foregroundStyle(.secondary)
                .lineLimit(nil)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    // MARK: - Tabellone

    private func scoreboard(_ live: LiveScore, editable: Bool) -> some View {
        ScrollView {
            VStack(spacing: 20) {
                board(live, editable: editable)
                    .padding(.horizontal, 12)
                    .animation(.spring(duration: 0.3), value: live)

                TimelineView(.periodic(from: live.startedAt, by: 1)) { context in
                    Label(Self.format(context.date.timeIntervalSince(live.startedAt)),
                          systemImage: "stopwatch.fill")
                        .font(.system(.title3, design: .rounded, weight: .bold))
                        .monospacedDigit()
                        .foregroundStyle(.secondary)
                }

                if let winner = live.winner {
                    Label("Vittoria \(live.teams[winner])", systemImage: "trophy.fill")
                        .font(.system(.title3, design: .rounded, weight: .heavy))
                        .foregroundStyle(Theme.plate)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 12)
                        .background(Theme.court, in: Capsule())
                } else if live.inTiebreak {
                    Text("TIE-BREAK")
                        .font(.system(.subheadline, design: .rounded, weight: .heavy))
                        .kerning(2)
                        .foregroundStyle(Theme.tile)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(Theme.lime, in: Capsule())
                }

                if editable {
                    controls(live)
                }
            }
            .padding(.vertical)
        }
    }

    /// Modifica del punteggio dal telefono: funziona anche a Watch
    /// scollegato, la riconciliazione avviene alla riconnessione.
    private func controls(_ live: LiveScore) -> some View {
        VStack(spacing: 12) {
            if live.winner == nil {
                Button {
                    sync.undoPoint()
                } label: {
                    Label("Annulla ultimo punto", systemImage: "arrow.uturn.backward")
                        .font(.system(.headline, design: .rounded, weight: .bold))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                }
                .buttonStyle(.bordered)
                .tint(Theme.accent)
                .disabled(!sync.canUndo)

                Button {
                    showPauseConfirm = true
                } label: {
                    Label("Pausa partita", systemImage: "pause.fill")
                        .font(.system(.headline, design: .rounded, weight: .bold))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                }
                .buttonStyle(.bordered)
                .tint(Theme.plate)
                .confirmationDialog("Mettere in pausa la partita?", isPresented: $showPauseConfirm) {
                    Button("Pausa partita") {
                        sync.pauseMatch()
                    }
                } message: {
                    Text("Il punteggio viene salvato come sospeso. Potrai riprenderla dal tab Live o dallo storico.")
                }
            }

            Button {
                showEndConfirm = true
            } label: {
                Label(live.winner == nil ? "Termina partita" : "Salva e chiudi",
                      systemImage: "flag.checkered")
                    .font(.system(.headline, design: .rounded, weight: .bold))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
            }
            .buttonStyle(.bordered)
            .tint(live.winner == nil ? Theme.loss : Theme.accent)
            .confirmationDialog("Terminare la partita?", isPresented: $showEndConfirm) {
                Button("Salva e termina", role: .destructive) {
                    sync.endMatch()
                }
            } message: {
                Text("Il match viene archiviato nello storico.")
            }

            if live.winner == nil {
                Text("Tocca una squadra sul tabellone per assegnarle il punto.")
                    .font(.system(.footnote, design: .rounded))
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }

            Label(sync.reachable
                    ? "Sincronizzato con l'Apple Watch in tempo reale."
                    : "Watch non collegato: il punteggio si riallineerà alla riconnessione.",
                  systemImage: sync.reachable
                    ? "applewatch.radiowaves.left.and.right" : "applewatch.slash")
                .font(.system(.footnote, design: .rounded))
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding(.horizontal)
    }

    private func board(_ live: LiveScore, editable: Bool) -> some View {
        let allSets = live.sets.map { $0.split(separator: "-").map(String.init) }
        let inline = allSets.count <= 2
        let prevSets = inline ? allSets : []
        let prevWidth = prevSets.isEmpty ? 0 : CGFloat(prevSets.count) * 34 + CGFloat(prevSets.count - 1) * 4

        return VStack(spacing: 14) {
            Text(live.matchName.isEmpty ? live.sport.uppercased() : live.matchName.uppercased())
                .font(.system(.title3, design: .rounded, weight: .heavy))
                .kerning(4)
                .foregroundStyle(.white)
                .lineLimit(1)
                .minimumScaleFactor(0.5)

            Rectangle()
                .fill(.white.opacity(0.5))
                .frame(height: 1)

            if !inline {
                prevSetsRow(live.sets)
            }

            VStack(spacing: 10) {
                headerRow(prevWidth: prevWidth)
                ForEach(0..<2, id: \.self) { team in
                    if editable {
                        Button {
                            sync.awardPoint(to: team)
                        } label: {
                            boardRow(live, team: team, prevSets: prevSets, prevWidth: prevWidth)
                        }
                        .buttonStyle(PressableStyle())
                        .disabled(live.winner != nil)
                        .accessibilityLabel("Punto a \(live.teams[team]), punteggio \(live.points[team])")
                    } else {
                        boardRow(live, team: team, prevSets: prevSets, prevWidth: prevWidth)
                    }
                }
            }
        }
        .padding(16)
        .background(
            LinearGradient(colors: [Theme.court, Theme.courtDeep],
                           startPoint: .top, endPoint: .bottom),
            in: RoundedRectangle(cornerRadius: 24))
        .overlay(
            RoundedRectangle(cornerRadius: 24)
                .strokeBorder(.white.opacity(0.2), lineWidth: 1)
        )
        .shadow(color: Theme.courtDeep.opacity(0.35), radius: 14, y: 6)
    }

    /// Partita lunga (3+ set chiusi): i parziali passano in una riga
    /// compatta sotto il titolo, così i nomi restano leggibili.
    private func prevSetsRow(_ sets: [String]) -> some View {
        HStack(spacing: 8) {
            columnTitle("SET PREC.")
            ForEach(Array(sets.enumerated()), id: \.offset) { index, set in
                Text(set)
                    .font(.system(size: 15, weight: .heavy, design: .rounded))
                    .monospacedDigit()
                    .foregroundStyle(.white)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Theme.tile, in: RoundedRectangle(cornerRadius: 6))
                    .accessibilityLabel("Set \(index + 1): \(set)")
            }
            Spacer()
        }
    }

    private func headerRow(prevWidth: CGFloat) -> some View {
        HStack(spacing: 8) {
            if prevWidth > 0 {
                columnTitle("PREC.").frame(width: prevWidth)
            }
            columnTitle("GIOCATORI").frame(maxWidth: .infinity)
            columnTitle("SET", tint: Theme.lime).frame(width: 40)
            columnTitle("GAME").frame(width: 44)
            columnTitle("PUNTI").frame(width: 68)
        }
    }

    private func columnTitle(_ text: String, tint: Color? = nil) -> some View {
        Text(text)
            .font(.system(size: 11, weight: .bold, design: .rounded))
            .foregroundStyle(tint ?? .white.opacity(0.85))
            .lineLimit(1)
            .minimumScaleFactor(0.6)
    }

    private func boardRow(_ live: LiveScore, team: Int,
                          prevSets: [[String]], prevWidth: CGFloat) -> some View {
        HStack(spacing: 8) {
            if prevWidth > 0 {
                HStack(spacing: 4) {
                    ForEach(Array(prevSets.enumerated()), id: \.offset) { _, set in
                        tile(set.indices.contains(team) ? set[team] : "-",
                             color: .white, width: 34, height: 46, size: 24)
                    }
                }
                .frame(width: prevWidth)
            }

            HStack(spacing: 6) {
                Text(live.teams[team])
                    .font(.system(.headline, design: .rounded, weight: .heavy))
                    .foregroundStyle(Theme.tile)
                    .lineLimit(1)
                    .minimumScaleFactor(0.4)
                if live.server == team && live.winner == nil {
                    Image(systemName: "tennisball.fill")
                        .font(.caption)
                        .foregroundStyle(Theme.court)
                }
            }
            .padding(.horizontal, 8)
            .frame(maxWidth: .infinity, minHeight: 46)
            .background(Theme.plate, in: RoundedRectangle(cornerRadius: 8))

            // Set in lime (dato chiave), game su tegola scura: colonne
            // distinguibili a colpo d'occhio, oltre che dall'intestazione.
            tile("\(live.setsWon[team])", color: Theme.tile,
                 background: Theme.lime, width: 40, height: 52, size: 28)
            tile("\(live.games[team])", color: Theme.plate, width: 44, height: 52, size: 28)

            Text(live.points[team])
                .font(.system(size: 34, weight: .heavy, design: .rounded))
                .monospacedDigit()
                .contentTransition(.numericText())
                .minimumScaleFactor(0.4)
                .foregroundStyle(Theme.tile)
                .frame(width: 68, height: 58)
                .background(.white, in: RoundedRectangle(cornerRadius: 8))
        }
        .contentShape(Rectangle())
    }

    private func tile(_ text: String, color: Color,
                      background: Color = Theme.tile,
                      width: CGFloat, height: CGFloat, size: CGFloat) -> some View {
        Text(text)
            .font(.system(size: size, weight: .heavy, design: .rounded))
            .monospacedDigit()
            .contentTransition(.numericText())
            .minimumScaleFactor(0.4)
            .foregroundStyle(color)
            .frame(width: width, height: height)
            .background(background, in: RoundedRectangle(cornerRadius: 8))
    }

    static func format(_ interval: TimeInterval) -> String {
        let s = max(0, Int(interval))
        return s >= 3600
            ? String(format: "%d:%02d:%02d", s / 3600, s / 60 % 60, s % 60)
            : String(format: "%02d:%02d", s / 60, s % 60)
    }
}

#Preview {
    LiveScreen()
}
