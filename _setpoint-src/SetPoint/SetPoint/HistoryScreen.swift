import SwiftUI
import SwiftData

/// Archivio partite, filtrabile per sport: card con esito, punteggio
/// e dettaglio con inerzia del match.
struct HistoryScreen: View {
    @Query(sort: \MatchRecord.date, order: .reverse) private var matches: [MatchRecord]
    @Environment(\.modelContext) private var context
    @State private var sportFilter = "Tutti"
    @State private var modeFilter = "Tutte"

    private var filtered: [MatchRecord] {
        matches
            .filter { sportFilter == "Tutti" || $0.sport == sportFilter }
            .filter { modeFilter == "Tutte"
                || (modeFilter == "Giocate" && !$0.isSpectator)
                || (modeFilter == "Spettatore" && $0.isSpectator) }
    }

    var body: some View {
        NavigationStack {
            Group {
                if matches.isEmpty {
                    ContentUnavailableView(
                        "Nessuna partita",
                        systemImage: "figure.tennis",
                        description: Text("Le partite giocate su iPhone o Apple Watch verranno archiviate qui."))
                } else {
                    List {
                        Section {
                            Picker("Sport", selection: $sportFilter) {
                                ForEach(["Tutti", "Tennis", "Padel"], id: \.self) { Text($0) }
                            }
                            .pickerStyle(.segmented)
                            .listRowBackground(Color.clear)
                            .listRowInsets(EdgeInsets())

                            Picker("Tipo", selection: $modeFilter) {
                                ForEach(["Tutte", "Giocate", "Spettatore"], id: \.self) { Text($0) }
                            }
                            .pickerStyle(.segmented)
                            .listRowBackground(Color.clear)
                            .listRowInsets(EdgeInsets())
                        }

                        ForEach(filtered) { match in
                            NavigationLink {
                                MatchDetailScreen(match: match)
                            } label: {
                                HistoryRow(match: match)
                            }
                            .listRowBackground(
                                RoundedRectangle(cornerRadius: 16)
                                    .fill(Theme.surface)
                                    .padding(.vertical, 4)
                            )
                            .listRowSeparator(.hidden)
                        }
                        .onDelete { indexes in
                            indexes.forEach {
                                let match = filtered[$0]
                                CloudSync.shared.deletePersonal(matchDate: match.date)
                                context.delete(match)
                            }
                        }
                    }
                    .listStyle(.insetGrouped)
                    .scrollContentBackground(.hidden)
                }
            }
            .background(Theme.background)
            .navigationTitle("Storico")
            .task(id: matches.filter { !$0.hasHealthData }.count) {
                await MatchHealthRecovery.recoverAllIfNeeded(in: matches, context: context)
            }
        }
    }
}

struct HistoryRow: View {
    let match: MatchRecord

    private var resultColor: Color {
        match.isSpectator ? Theme.accent : (match.won ? Theme.win : Theme.loss)
    }

    var body: some View {
        HStack(spacing: 12) {
            if match.isSpectator {
                Image(systemName: "eye.fill")
                    .font(.system(.subheadline, design: .rounded, weight: .heavy))
                    .foregroundStyle(.white)
                    .frame(width: 34, height: 34)
                    .background(Theme.accent, in: Circle())
                    .accessibilityLabel("Partita da spettatore")
            } else {
                Text(match.won ? "V" : "S")
                    .font(.system(.subheadline, design: .rounded, weight: .heavy))
                    .foregroundStyle(.white)
                    .frame(width: 34, height: 34)
                    .background(resultColor, in: Circle())
                    .accessibilityLabel(match.won ? "Vittoria" : "Sconfitta")
            }

            VStack(alignment: .leading, spacing: 6) {
                Text(match.displayVenue.isEmpty
                     ? (match.isSpectator ? match.spectatorTitle : "vs \(match.opponentsLabel)")
                     : match.displayVenue)
                    .font(.system(.body, design: .rounded, weight: .bold))
                    .lineLimit(1)
                HStack(spacing: 6) {
                    Chip(text: match.sport,
                         icon: match.sport == "Padel" ? "figure.pickleball" : "figure.tennis")
                    Chip(text: match.matchType,
                         icon: match.matchType == "Doppio" ? "person.2.fill" : "person.fill")
                    if match.isSpectator {
                        Chip(text: "Spettatore", icon: "eye.fill")
                    }
                    if !match.finished {
                        Chip(text: "Sospesa", icon: "pause.fill")
                    }
                    if match.hasAnyLinkedPlayer {
                        Chip(text: "Condivisa", icon: "icloud.fill")
                    }
                }
            }

            Spacer(minLength: 8)

            VStack(alignment: .trailing, spacing: 4) {
                Text(match.scoreline)
                    .font(.system(.subheadline, design: .rounded, weight: .heavy))
                    .monospacedDigit()
                    .foregroundStyle(resultColor)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
                Text(match.date, format: .dateTime.day().month())
                    .font(.system(.caption, design: .rounded, weight: .semibold))
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 6)
    }
}

/// Dettaglio partita: hero con esito, tessere statistiche e inerzia.
struct MatchDetailScreen: View {
    @Bindable var match: MatchRecord
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var context
    private var sync: WatchSync { WatchSync.shared }
    @State private var showShare = false
    @State private var showEdit = false
    @State private var resumeFailed = false

    var body: some View {
        ScrollView {
            VStack(spacing: 12) {
                hero

                if match.canResume, sync.engine == nil, sync.live == nil {
                    resumeButton
                }

                Button {
                    showEdit = true
                } label: {
                    Label("Modifica dati", systemImage: "square.and.pencil")
                        .font(.system(.subheadline, design: .rounded, weight: .bold))
                        .foregroundStyle(Theme.accent)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(Theme.accent.opacity(0.10), in: RoundedRectangle(cornerRadius: 14))
                }
                .buttonStyle(PressableStyle())

                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())],
                          spacing: 8) {
                    StatTile(value: "\(match.setsWon)–\(match.setsLost)",
                             label: "Set", icon: "square.stack.3d.up.fill", compact: true)
                    StatTile(value: "\(match.pointsWon)–\(match.pointsLost)",
                             label: "Punti", icon: "circle.grid.2x2.fill", compact: true)
                    StatTile(value: LiveScreen.format(match.duration),
                             label: "Durata", icon: "stopwatch.fill", compact: true)
                    StatTile(value: "\(MomentumChart.longestStreak(match.timeline, team: 0))",
                             label: "Striscia max", icon: "flame.fill", compact: true)
                }

                MatchHealthSection(match: match)

                MatchConditionsSection(match: match)

                if match.timeline.count >= 4 {
                    VStack(alignment: .leading, spacing: 8) {
                        Label("Inerzia del match", systemImage: "chart.line.uptrend.xyaxis")
                            .font(.system(.subheadline, design: .rounded, weight: .bold))
                        MomentumChart(timeline: match.timeline, setBreaks: match.setBreaks)
                            .frame(height: 120)
                    }
                    .padding(12)
                    .frame(maxWidth: .infinity)
                    .card()
                }

                MatchLinkingSection(match: match)

                MatchPhotoSection(match: match)

                VStack(spacing: 0) {
                    infoRow("Sport", "\(match.sport) · \(match.matchType)")
                    if match.sport == Sport.tennis.rawValue, !match.courtSurface.isEmpty {
                        Divider().padding(.leading, 16)
                        infoRow("Superficie", match.courtSurface)
                    }
                    if match.isSpectator {
                        Divider().padding(.leading, 16)
                        infoRow("Squadra A", match.team0Label)
                        Divider().padding(.leading, 16)
                        infoRow("Squadra B", match.opponentsLabel)
                    } else {
                        Divider().padding(.leading, 16)
                        infoRow("Avversari", match.opponentsLabel)
                        if !match.partner.isEmpty {
                            Divider().padding(.leading, 16)
                            infoRow("Partner", match.partner)
                        }
                    }
                    Divider().padding(.leading, 16)
                    infoRow("Data", match.date.formatted(.dateTime.day().month().year().hour().minute()))
                }
                .card()
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
        }
        .background(Theme.background)
        .navigationTitle(match.displayVenue.isEmpty ? "Dettaglio" : match.displayVenue)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button {
                    showEdit = true
                } label: {
                    Label("Modifica", systemImage: "square.and.pencil")
                }
            }
            ToolbarItem(placement: .primaryAction) {
                Button {
                    showShare = true
                } label: {
                    Label("Condividi", systemImage: "square.and.arrow.up")
                }
                .accessibilityLabel("Condividi la partita sui social")
            }
        }
        .sheet(isPresented: $showEdit) {
            EditMatchSheet(match: match)
        }
        .sheet(isPresented: $showShare) {
            ShareCardSheet(match: match)
        }
        .alert("Impossibile riprendere", isPresented: $resumeFailed) {
            Button("OK", role: .cancel) {}
        } message: {
            Text("Chiudi la partita in corso nella schermata Live e riprova.")
        }
    }

    private var resumeButton: some View {
        Button {
            resumeMatch()
        } label: {
            Label("Riprendi partita", systemImage: "arrow.clockwise.circle.fill")
                .font(.system(.headline, design: .rounded, weight: .heavy))
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(Theme.court, in: RoundedRectangle(cornerRadius: 16))
        }
        .buttonStyle(PressableStyle())
        .accessibilityHint("Riprende il punteggio nella schermata Live")
    }

    private func resumeMatch() {
        guard WatchSync.shared.resumeFromHistory(match) else {
            resumeFailed = true
            return
        }
        context.delete(match)
        try? context.save()
        dismiss()
        NotificationCenter.default.post(name: .switchToLiveTab, object: nil)
    }

    private var hero: some View {
        VStack(spacing: 8) {
            if match.isSpectator {
                Label(match.won ? "VINCE \(match.team0Label.uppercased())"
                                : "VINCE \(match.opponentsLabel.uppercased())",
                      systemImage: "eye.fill")
                    .font(.system(.caption, design: .rounded, weight: .heavy))
                    .kerning(1.2)
                    .foregroundStyle(Theme.accent)
                    .multilineTextAlignment(.center)
            } else {
                Label(match.won ? "VITTORIA" : "SCONFITTA",
                      systemImage: match.won ? "trophy.fill" : "xmark.circle.fill")
                    .font(.system(.caption, design: .rounded, weight: .heavy))
                    .kerning(1.2)
                    .foregroundStyle(match.won ? Theme.lime : .white.opacity(0.85))
            }
            Text(match.scoreline.isEmpty ? "—" : match.scoreline)
                .font(.system(size: 32, weight: .heavy, design: .rounded))
                .monospacedDigit()
                .minimumScaleFactor(0.5)
                .lineLimit(1)
                .foregroundStyle(.white)
            heroStatusChip(
                match.finished ? "Partita conclusa" : "Partita sospesa",
                icon: match.finished ? "checkmark.circle.fill" : "pause.fill"
            )
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 18)
        .padding(.horizontal, 14)
        .background(
            LinearGradient(colors: [Theme.court, Theme.courtDeep],
                           startPoint: .top, endPoint: .bottom),
            in: RoundedRectangle(cornerRadius: 18))
    }

    private func heroStatusChip(_ text: String, icon: String) -> some View {
        Label(text, systemImage: icon)
            .font(.system(.caption, design: .rounded, weight: .bold))
            .foregroundStyle(.white)
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(.white.opacity(0.2), in: Capsule())
    }

    private func infoRow(_ label: String, _ value: String) -> some View {
        HStack {
            Text(label)
                .font(.system(.subheadline, design: .rounded, weight: .semibold))
                .foregroundStyle(.secondary)
            Spacer()
            Text(value)
                .font(.system(.subheadline, design: .rounded, weight: .bold))
                .multilineTextAlignment(.trailing)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
    }
}
