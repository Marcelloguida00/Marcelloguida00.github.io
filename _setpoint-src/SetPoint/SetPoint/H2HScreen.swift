import SwiftUI
import SwiftData

/// Head-to-Head per avversario e analisi di coppia per partner.
struct H2HScreen: View {
    @Query private var matches: [MatchRecord]

    var body: some View {
        NavigationStack {
            Group {
                let opponents = OpponentStats.compute(from: matches)
                let partners = OpponentStats.partners(from: matches)
                if opponents.isEmpty && partners.isEmpty {
                    ContentUnavailableView(
                        "Nessuna rivalità",
                        systemImage: "person.line.dotted.person.fill",
                        description: Text("Inserisci i nomi degli avversari quando avvii una partita."))
                } else {
                    List {
                        if !opponents.isEmpty {
                            Section {
                                ForEach(opponents) { statsCard($0) }
                            } header: {
                                sectionHeader("Avversari", icon: "figure.tennis")
                            }
                        }
                        if !partners.isEmpty {
                            Section {
                                ForEach(partners) { statsCard($0) }
                            } header: {
                                sectionHeader("Coppie (doppio)", icon: "person.2.fill")
                            }
                        }
                    }
                    .listStyle(.insetGrouped)
                    .scrollContentBackground(.hidden)
                }
            }
            .background(Theme.background)
            .navigationTitle("Rivalità")
        }
    }

    private func sectionHeader(_ title: String, icon: String) -> some View {
        Label(title, systemImage: icon)
            .font(.system(.subheadline, design: .rounded, weight: .heavy))
            .foregroundStyle(Theme.accent)
            .textCase(nil)
    }

    private func statsCard(_ stats: OpponentStats) -> some View {
        StatsRow(stats: stats)
            .listRowBackground(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Theme.surface)
                    .padding(.vertical, 4)
            )
            .listRowSeparator(.hidden)
    }
}

struct StatsRow: View {
    let stats: OpponentStats

    var body: some View {
        HStack(spacing: 12) {
            InitialsAvatar(name: stats.name, size: 44)

            VStack(alignment: .leading, spacing: 6) {
                Text(stats.name)
                    .font(.system(.body, design: .rounded, weight: .bold))
                    .lineLimit(1)
                HStack(spacing: 6) {
                    Chip(text: "\(stats.played) partite")
                    Chip(text: "Set \(stats.setsWon)–\(stats.setsLost)")
                    Chip(text: stats.streakLabel, icon: "flame.fill")
                }
            }

            Spacer(minLength: 8)

            WinRateRing(rate: stats.winRate)
        }
        .padding(.vertical, 6)
    }
}
