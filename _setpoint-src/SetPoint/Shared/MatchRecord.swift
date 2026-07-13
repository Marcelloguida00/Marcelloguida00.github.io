import Foundation
import SwiftData

/// Partita archiviata: base per storico, statistiche e Head-to-Head.
@Model
final class MatchRecord {
    var date: Date = Date()
    var sport: String = ""
    var courtSurface: String = ""    // Cemento | Terra rossa | Erba (solo tennis)
    var matchType: String = "Doppio"   // Singolare | Doppio
    var name: String = ""              // nome/tag personalizzato della partita
    var venue: String = ""           // campo o circolo dove si gioca
    var hasMatchPhoto: Bool = false  // foto ricordo salvata (non nella card social)
    var opponent: String = ""
    var opponent2: String = ""         // secondo avversario (solo doppio)
    var partner: String = ""         // compagno (solo doppio)
    var homeName: String = ""        // giocatore squadra A (spettatore) o nome utente
    var isSpectator: Bool = false    // non conta in H2H / profilo / widget
    var won: Bool = false
    var finished: Bool = true          // false se terminata manualmente
    var scoreline: String = ""       // es. "6-3 4-6 10-7"
    var setsWon: Int = 0
    var setsLost: Int = 0
    var pointsWon: Int = 0
    var pointsLost: Int = 0
    var duration: TimeInterval = 0
    var activeCalories: Double = 0
    var avgHeartRate: Double = 0
    var maxHeartRate: Double = 0
    var steps: Int = 0
    var distanceMeters: Double = 0
    var healthRecoveredFromSalute: Bool = false
    var timeline: [Int] = []           // chi ha vinto ogni punto (0 = io/noi)
    var setBreaks: [Int] = []          // indici di fine set nella timeline
    var setDurations: [Double] = []
    var cloudID: String = ""           // record CloudKit condiviso ("" = solo locale)
    var latitude: Double = 0           // posizione al termine partita (0 = assente)
    var longitude: Double = 0

    /// Profili SetPoint collegati retroattivamente (o al momento della partita).
    var partnerUserID: String = ""
    var partnerUsername: String = ""
    var opponentUserID: String = ""
    var opponentUsername: String = ""
    var opponent2UserID: String = ""
    var opponent2Username: String = ""

    /// Slot giocatore collegabile su SetPoint.
    enum PlayerSlot: String, CaseIterable, Identifiable {
        case partner, opponent, opponent2
        var id: String { rawValue }
    }

    var linkedUserIDs: [String] {
        [partnerUserID, opponentUserID, opponent2UserID]
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty }
    }

    /// Slot da mostrare nel dettaglio partita (nome presente, profilo non ancora collegato).
    var linkableSlots: [PlayerSlot] {
        guard !isSpectator else { return [] }
        if matchType == MatchType.doppio.rawValue {
            return PlayerSlot.allCases.filter {
                !displayName(for: $0).isEmpty && userID(for: $0).isEmpty
            }
        }
        return opponentUserID.isEmpty ? [.opponent] : []
    }

    var hasAnyLinkedPlayer: Bool { !linkedUserIDs.isEmpty }

    var hasStoredLocation: Bool {
        abs(latitude) > 0.0001 && abs(longitude) > 0.0001
    }

    var hasHealthData: Bool { healthSnapshot.hasData }

    var healthSnapshot: MatchHealthSnapshot {
        MatchHealthSnapshot(
            activeCalories: activeCalories,
            avgHeartRate: avgHeartRate,
            maxHeartRate: maxHeartRate,
            steps: steps,
            distanceMeters: distanceMeters
        )
    }

    func applyHealth(_ health: MatchHealthSnapshot, recoveredFromSalute: Bool = false) {
        activeCalories = health.activeCalories
        avgHeartRate = health.avgHeartRate
        maxHeartRate = health.maxHeartRate
        steps = health.steps
        distanceMeters = health.distanceMeters
        if recoveredFromSalute {
            healthRecoveredFromSalute = true
        }
    }

    var coordinate: (latitude: Double, longitude: Double)? {
        guard hasStoredLocation else { return nil }
        return (latitude, longitude)
    }

    /// Campo da mostrare in UI, card social e widget meteo (fallback su `name` legacy).
    var displayVenue: String {
        let court = venue.trimmingCharacters(in: .whitespacesAndNewlines)
        if !court.isEmpty { return court }
        return name.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    func displayName(for slot: PlayerSlot) -> String {
        switch slot {
        case .partner: return partner.trimmingCharacters(in: .whitespaces)
        case .opponent: return opponent.trimmingCharacters(in: .whitespaces)
        case .opponent2: return opponent2.trimmingCharacters(in: .whitespaces)
        }
    }

    func userID(for slot: PlayerSlot) -> String {
        switch slot {
        case .partner: return partnerUserID
        case .opponent: return opponentUserID
        case .opponent2: return opponent2UserID
        }
    }

    func username(for slot: PlayerSlot) -> String {
        switch slot {
        case .partner: return partnerUsername
        case .opponent: return opponentUsername
        case .opponent2: return opponent2Username
        }
    }

    func slotLabel(for slot: PlayerSlot) -> String {
        switch slot {
        case .partner: return "Partner"
        case .opponent: return matchType == MatchType.doppio.rawValue ? "Avversario 1" : "Avversario"
        case .opponent2: return "Avversario 2"
        }
    }

    func applyLink(_ player: LinkedPlayer, slot: PlayerSlot) {
        switch slot {
        case .partner:
            partnerUserID = player.userID
            partnerUsername = player.username
            if partner.trimmingCharacters(in: .whitespaces).isEmpty {
                partner = player.fullName
            }
        case .opponent:
            opponentUserID = player.userID
            opponentUsername = player.username
            if opponent.trimmingCharacters(in: .whitespaces).isEmpty {
                opponent = player.fullName
            }
        case .opponent2:
            opponent2UserID = player.userID
            opponent2Username = player.username
            if opponent2.trimmingCharacters(in: .whitespaces).isEmpty {
                opponent2 = player.fullName
            }
        }
    }

    func clearLink(slot: PlayerSlot) {
        switch slot {
        case .partner:
            partnerUserID = ""
            partnerUsername = ""
        case .opponent:
            opponentUserID = ""
            opponentUsername = ""
        case .opponent2:
            opponent2UserID = ""
            opponent2Username = ""
        }
    }

    /// Meta per la condivisione cloud a partire dai link salvati sul record.
    func sharingMeta() -> MatchMeta {
        var meta = MatchMeta(
            name: name,
            venue: venue,
            opponent: opponent,
            opponent2: opponent2,
            partner: partner,
            isSpectator: isSpectator,
            homeName: homeName
        )
        if !partnerUserID.isEmpty {
            meta.partnerLink = LinkedPlayer(
                userID: partnerUserID,
                username: partnerUsername,
                fullName: partner
            )
        }
        if !opponentUserID.isEmpty {
            meta.opponentLink = LinkedPlayer(
                userID: opponentUserID,
                username: opponentUsername,
                fullName: opponent
            )
        }
        if !opponent2UserID.isEmpty {
            meta.opponent2Link = LinkedPlayer(
                userID: opponent2UserID,
                username: opponent2Username,
                fullName: opponent2
            )
        }
        return meta
    }

    func persistLinks(from meta: MatchMeta) {
        if let link = meta.partnerLink {
            partnerUserID = link.userID
            partnerUsername = link.username
        }
        if let link = meta.opponentLink {
            opponentUserID = link.userID
            opponentUsername = link.username
        }
        if let link = meta.opponent2Link {
            opponent2UserID = link.userID
            opponent2Username = link.username
        }
    }

    /// "Luca" oppure "Luca e Anna" nel doppio.
    var opponentsLabel: String {
        opponent2.isEmpty ? opponent : "\(opponent) e \(opponent2)"
    }

    /// Etichetta squadra A (casa / team 0).
    var team0Label: String {
        let home = homeName.trimmingCharacters(in: .whitespaces)
        guard !home.isEmpty else {
            return isSpectator ? "Squadra A" : "IO"
        }
        if matchType == MatchType.doppio.rawValue {
            let p = partner.trimmingCharacters(in: .whitespaces)
            return p.isEmpty ? home : "\(home) e \(p)"
        }
        return home
    }

    /// Titolo per lo storico in modalità spettatore.
    var spectatorTitle: String {
        "\(team0Label) vs \(opponentsLabel)"
    }

    init(date: Date, sport: String, matchType: String, name: String,
         opponent: String, opponent2: String, partner: String,
         homeName: String = "", isSpectator: Bool = false,
         venue: String = "",
         hasMatchPhoto: Bool = false,
         courtSurface: String = "",
         latitude: Double = 0,
         longitude: Double = 0,
         won: Bool, finished: Bool, scoreline: String,
         setsWon: Int, setsLost: Int, pointsWon: Int, pointsLost: Int,
         duration: TimeInterval,
         activeCalories: Double = 0,
         avgHeartRate: Double = 0,
         maxHeartRate: Double = 0,
         steps: Int = 0,
         distanceMeters: Double = 0,
         healthRecoveredFromSalute: Bool = false,
         timeline: [Int], setBreaks: [Int], setDurations: [Double]) {
        self.date = date
        self.sport = sport
        self.matchType = matchType
        self.name = name
        self.opponent = opponent
        self.opponent2 = opponent2
        self.partner = partner
        self.homeName = homeName
        self.isSpectator = isSpectator
        self.venue = venue
        self.hasMatchPhoto = hasMatchPhoto
        self.courtSurface = courtSurface
        self.latitude = latitude
        self.longitude = longitude
        self.timeline = timeline
        self.setBreaks = setBreaks
        self.setDurations = setDurations
        self.won = won
        self.finished = finished
        self.scoreline = scoreline
        self.setsWon = setsWon
        self.setsLost = setsLost
        self.pointsWon = pointsWon
        self.pointsLost = pointsLost
        self.duration = duration
        self.activeCalories = activeCalories
        self.avgHeartRate = avgHeartRate
        self.maxHeartRate = maxHeartRate
        self.steps = steps
        self.distanceMeters = distanceMeters
        self.healthRecoveredFromSalute = healthRecoveredFromSalute
    }

    /// Partita interrotta senza esito finale: si può riprendere dallo storico.
    var canResume: Bool {
        !finished && !timeline.isEmpty
    }

    /// Ricostruisce lo stato live per riprendere il match (config approssimata).
    func liveMatchState() -> LiveMatchState? {
        guard canResume else { return nil }
        return LiveMatchState(
            config: inferredConfig(),
            meta: sharingMeta(),
            startedAt: date,
            updatedAt: Date(),
            timeline: timeline
        )
    }

    private func inferredConfig() -> MatchConfig {
        var config = MatchConfig()
        config.sport = Sport(rawValue: sport) ?? .tennis
        config.matchType = MatchType(rawValue: matchType) ?? .singolare
        if let surface = CourtSurface(rawValue: courtSurface) {
            config.courtSurface = surface
        }
        let setsPlayed = setsWon + setsLost
        config.setsToWin = setsPlayed >= 4 ? 3 : 2
        return config
    }
}

/// Statistiche aggregate contro un singolo avversario (H2H).
struct OpponentStats: Identifiable {
    let name: String
    var played = 0
    var wins = 0
    var setsWon = 0
    var setsLost = 0
    var streak = 0          // >0 vittorie consecutive, <0 sconfitte

    var id: String { name }
    var winRate: Int { played == 0 ? 0 : wins * 100 / played }
    var streakLabel: String { streak == 0 ? "—" : (streak > 0 ? "V\(streak)" : "S\(-streak)") }

    /// Aggrega i match in schede H2H per singolo avversario
    /// (nel doppio il match conta per entrambi gli avversari).
    static func compute(from matches: [MatchRecord]) -> [OpponentStats] {
        compute(from: matches.filter { !$0.isSpectator }) { [$0.opponent, $0.opponent2] }
    }

    /// Analisi di coppia: performance per ogni partner di doppio.
    static func partners(from matches: [MatchRecord]) -> [OpponentStats] {
        compute(from: matches.filter { !$0.isSpectator }) {
            $0.matchType == MatchType.doppio.rawValue ? [$0.partner] : []
        }
    }

    private static func compute(from matches: [MatchRecord],
                                by keys: (MatchRecord) -> [String]) -> [OpponentStats] {
        var byName: [String: OpponentStats] = [:]
        // Streak: dal match più recente a ritroso
        for m in matches.sorted(by: { $0.date > $1.date }) {
            for raw in keys(m) {
                let key = raw.trimmingCharacters(in: .whitespaces)
                guard !key.isEmpty else { continue }
                var s = byName[key] ?? OpponentStats(name: key)
                s.played += 1
                if m.won { s.wins += 1 }
                s.setsWon += m.setsWon
                s.setsLost += m.setsLost
                if s.played == 1 {
                    s.streak = m.won ? 1 : -1
                } else if (s.streak > 0) == m.won && abs(s.streak) == s.played - 1 {
                    s.streak += m.won ? 1 : -1
                }
                byName[key] = s
            }
        }
        return byName.values.sorted { $0.played > $1.played }
    }
}
