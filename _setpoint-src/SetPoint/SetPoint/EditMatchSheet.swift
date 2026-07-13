import SwiftUI
import SwiftData

/// Modifica i metadati di una partita archiviata (campo, giocatori, sport).
struct EditMatchSheet: View {
    @Bindable var match: MatchRecord
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var context

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    sectionCard(title: "Campo", icon: "sportscourt.fill") {
                        VStack(alignment: .leading, spacing: 6) {
                            Text("Dove avete giocato?")
                                .font(.system(.caption, design: .rounded, weight: .semibold))
                                .foregroundStyle(.secondary)
                            TextField("es. Campo 1, Circolo Roma…", text: $match.venue)
                                .font(.system(.subheadline, design: .rounded))
                                .textInputAutocapitalization(.words)
                                .padding(12)
                                .background(Theme.accent.opacity(0.06), in: RoundedRectangle(cornerRadius: 12))
                        }
                    }

                    sectionCard(title: "Sport", icon: "figure.tennis") {
                        sportPicker
                        if currentSport == .tennis {
                            Divider().opacity(0.35)
                            courtSurfacePicker
                        }
                        Divider().opacity(0.35)
                        matchTypePicker
                    }

                    sectionCard(
                        title: match.isSpectator ? "Giocatori" : "Partecipanti",
                        icon: "person.3.fill"
                    ) {
                        if match.isSpectator {
                            spectatorFields
                        } else {
                            playerFields
                        }
                    }
                }
                .padding(.horizontal)
                .padding(.vertical, 12)
            }
            .background(Theme.background)
            .navigationTitle("Modifica partita")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Annulla") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Salva") {
                        try? context.save()
                        dismiss()
                    }
                    .font(.system(.body, design: .rounded, weight: .bold))
                }
            }
        }
        .presentationDragIndicator(.visible)
    }

    private var currentSport: Sport {
        Sport(rawValue: match.sport) ?? .tennis
    }

    private var currentMatchType: MatchType {
        MatchType(rawValue: match.matchType) ?? .singolare
    }

    private var sportPicker: some View {
        HStack(spacing: 8) {
            sportChip(.tennis)
            sportChip(.padel)
        }
    }

    private func sportChip(_ sport: Sport) -> some View {
        let selected = currentSport == sport
        return Button {
            withAnimation(.spring(duration: 0.2)) {
                match.sport = sport.rawValue
                if sport == .padel { match.courtSurface = "" }
            }
        } label: {
            Label(sport.rawValue,
                  systemImage: sport == .padel ? "figure.pickleball" : "figure.tennis")
                .font(.system(.subheadline, design: .rounded, weight: .bold))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .foregroundStyle(selected ? Theme.lime : .secondary)
                .background(selected ? Theme.court : Theme.accent.opacity(0.08),
                            in: RoundedRectangle(cornerRadius: 12))
        }
        .buttonStyle(.plain)
    }

    private var courtSurfacePicker: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Superficie")
                .font(.system(.caption, design: .rounded, weight: .semibold))
                .foregroundStyle(.secondary)
            HStack(spacing: 8) {
                ForEach(CourtSurface.allCases) { surface in
                    let selected = match.courtSurface == surface.rawValue
                    Button {
                        withAnimation(.spring(duration: 0.2)) {
                            match.courtSurface = surface.rawValue
                        }
                    } label: {
                        Text(surface.rawValue)
                            .font(.system(.caption, design: .rounded, weight: .bold))
                            .padding(.horizontal, 12)
                            .padding(.vertical, 10)
                            .foregroundStyle(selected ? Theme.lime : .secondary)
                            .background(selected ? Theme.court : Theme.accent.opacity(0.08),
                                        in: Capsule())
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    private var matchTypePicker: some View {
        HStack(spacing: 8) {
            matchTypeChip(.singolare)
            matchTypeChip(.doppio)
        }
    }

    private func matchTypeChip(_ type: MatchType) -> some View {
        let selected = currentMatchType == type
        return Button {
            withAnimation(.spring(duration: 0.2)) {
                match.matchType = type.rawValue
                if type == .singolare {
                    match.partner = ""
                    match.opponent2 = ""
                }
            }
        } label: {
            Label(type.rawValue,
                  systemImage: type == .doppio ? "person.2.fill" : "person.fill")
                .font(.system(.subheadline, design: .rounded, weight: .bold))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .foregroundStyle(selected ? Theme.lime : .secondary)
                .background(selected ? Theme.court : Theme.accent.opacity(0.08),
                            in: RoundedRectangle(cornerRadius: 12))
        }
        .buttonStyle(.plain)
    }

    @ViewBuilder
    private var spectatorFields: some View {
        if currentMatchType == .doppio {
            nameField("Giocatore 1 · squadra A", text: $match.homeName)
            nameField("Giocatore 2 · squadra A", text: $match.partner)
            nameField("Giocatore 3 · squadra B", text: $match.opponent)
            nameField("Giocatore 4 · squadra B", text: $match.opponent2)
        } else {
            nameField("Giocatore 1", text: $match.homeName)
            nameField("Giocatore 2", text: $match.opponent)
        }
    }

    @ViewBuilder
    private var playerFields: some View {
        if currentMatchType == .doppio {
            nameField("Partner", text: $match.partner)
            nameField("Avversario 1", text: $match.opponent)
            nameField("Avversario 2", text: $match.opponent2)
        } else {
            nameField("Avversario", text: $match.opponent)
        }
    }

    private func nameField(_ label: String, text: Binding<String>) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(label)
                .font(.system(.caption, design: .rounded, weight: .semibold))
                .foregroundStyle(.secondary)
            TextField(label, text: text)
                .font(.system(.subheadline, design: .rounded))
                .textInputAutocapitalization(.words)
                .padding(12)
                .background(Theme.accent.opacity(0.06), in: RoundedRectangle(cornerRadius: 12))
        }
    }

    private func sectionCard<Content: View>(
        title: String,
        icon: String,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Label(title, systemImage: icon)
                .font(.system(.subheadline, design: .rounded, weight: .heavy))
                .foregroundStyle(Theme.accent)
            content()
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .card()
    }
}
