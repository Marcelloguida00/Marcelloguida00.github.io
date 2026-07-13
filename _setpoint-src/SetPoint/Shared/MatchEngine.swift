import Foundation
import Observation

@Observable
final class MatchEngine {
    let config: MatchConfig
    let startDate: Date

    /// Timestamp dell'ultima azione locale (punto o undo): nella
    /// riconciliazione iPhone ↔ Watch vince lo stato più recente.
    private(set) var updatedAt: Date

    // Stato corrente (snapshot per l'undo)
    private struct State {
        var points = [0, 0]         // punti nel game (o nel TB)
        var games = [0, 0]          // game nel set corrente
        var sets: [SetResult] = []
        var setsWon = [0, 0]
        var inTiebreak = false
        var tiebreakTo = 7
        var server = 0              // team al servizio
        var tbFirstServer = 0
        var winner: Int? = nil
        var totalPoints = [0, 0]
        var setStart = Date()
        var timeline: [Int] = []    // chi ha vinto ogni punto (0/1)
        var setBreaks: [Int] = []   // indice del punto a fine di ogni set
    }

    private var state = State()
    private var history: [State] = []

    /// Timestamp dell'ultimo cambio campo (osservato dalla UI per il banner).
    private(set) var lastChangeEnds: Date? = nil

    // MARK: - Lettura

    var sets: [SetResult] { state.sets }
    var games: [Int] { state.games }
    var setsWon: [Int] { state.setsWon }
    var inTiebreak: Bool { state.inTiebreak }
    var server: Int { state.server }
    var winner: Int? { state.winner }
    var totalPoints: [Int] { state.totalPoints }
    var canUndo: Bool { !history.isEmpty }
    var currentSetStart: Date { state.setStart }
    var timeline: [Int] { state.timeline }
    var setBreaks: [Int] { state.setBreaks }

    /// Etichetta punteggio del game per il team indicato.
    func pointLabel(for team: Int) -> String {
        let p = state.points, other = 1 - team
        if state.inTiebreak { return "\(p[team])" }
        if p[team] >= 3 && p[other] >= 3 {
            if p[team] == p[other] { return "40" }
            return p[team] > p[other] ? "AD" : "40"
        }
        return ["0", "15", "30", "40"][min(p[team], 3)]
    }

    /// Lato di servizio: pari = destra, dispari = sinistra.
    var serveSide: String {
        (state.points[0] + state.points[1]) % 2 == 0 ? "DX" : "SX"
    }

    init(config: MatchConfig, startDate: Date = Date()) {
        self.config = config
        self.startDate = startDate
        self.updatedAt = startDate
    }

    /// Ricostruisce il motore da uno stato remoto rigiocando la timeline
    /// dei punti: stesso config ⇒ stesso stato, undo compreso.
    static func restore(_ state: LiveMatchState) -> MatchEngine {
        let engine = MatchEngine(config: state.config, startDate: state.startedAt)
        for team in state.timeline { engine.awardPoint(to: team) }
        engine.updatedAt = state.updatedAt
        engine.lastChangeEnds = nil   // niente banner per punti già giocati
        return engine
    }

    // MARK: - Punteggio

    @discardableResult
    func awardPoint(to team: Int) -> [ScoreEvent] {
        guard state.winner == nil else { return [] }
        history.append(state)
        if history.count > 60 { history.removeFirst() }
        updatedAt = Date()

        state.totalPoints[team] += 1
        state.points[team] += 1
        state.timeline.append(team)
        var events: [ScoreEvent] = [.point]

        if state.inTiebreak {
            let p = state.points, played = p[0] + p[1]
            // Il primo al servizio serve 1 punto, poi si alterna ogni 2
            state.server = played % 4 == 1 || played % 4 == 2
                ? 1 - state.tbFirstServer : state.tbFirstServer
            if played % 6 == 0 { events.append(.changeEnds) }
            if p[team] >= state.tiebreakTo && p[team] - p[1 - team] >= 2 {
                events.append(contentsOf: winTiebreak(team))
            }
        } else {
            let p = state.points, other = 1 - team
            let won = p[team] >= 4 && (p[team] - p[other] >= 2 || config.goldenPoint)
            if won { events.append(contentsOf: winGame(team)) }
        }
        if events.contains(where: { if case .changeEnds = $0 { true } else { false } }) {
            lastChangeEnds = Date()
        }
        return events
    }

    func undo() {
        guard let last = history.popLast() else { return }
        state = last
        updatedAt = Date()
    }

    // MARK: - Logica interna

    private func winGame(_ team: Int) -> [ScoreEvent] {
        state.points = [0, 0]
        state.games[team] += 1
        state.server = 1 - state.server
        var events: [ScoreEvent] = [.game]

        let g = state.games, other = 1 - team
        if g[team] >= config.gamesPerSet && g[team] - g[other] >= 2 {
            events.append(contentsOf: winSet(team, tiebreak: nil))
        } else if g[0] == config.tiebreakTrigger && g[1] == config.tiebreakTrigger {
            state.inTiebreak = true
            state.tiebreakTo = 7
            state.tbFirstServer = state.server
            events.append(.tiebreakStart)
        } else if (g[0] + g[1]) % 2 == 1 {
            events.append(.changeEnds)
        }
        return events
    }

    private func winTiebreak(_ team: Int) -> [ScoreEvent] {
        let tb = state.points
        state.games[team] += 1
        state.server = 1 - state.tbFirstServer
        // Super tie-break: vale come set intero
        let isSuperTB = state.tiebreakTo == 10
        return winSet(team, tiebreak: tb, superTB: isSuperTB)
    }

    private func winSet(_ team: Int, tiebreak: [Int]?, superTB: Bool = false) -> [ScoreEvent] {
        state.sets.append(SetResult(
            games: superTB ? [tiebreak![0], tiebreak![1]] : state.games,
            tiebreak: tiebreak,
            duration: Date().timeIntervalSince(state.setStart)
        ))
        state.setsWon[team] += 1
        state.points = [0, 0]
        state.games = [0, 0]
        state.inTiebreak = false
        state.setStart = Date()
        state.setBreaks.append(state.timeline.count)
        var events: [ScoreEvent] = [.setWon(team)]

        if state.setsWon[team] == config.setsToWin {
            state.winner = team
            events.append(.matchWon(team))
        } else if config.superTiebreak,
                  state.setsWon[0] == config.setsToWin - 1,
                  state.setsWon[1] == config.setsToWin - 1 {
            // Set decisivo giocato come super tie-break a 10
            state.inTiebreak = true
            state.tiebreakTo = 10
            state.tbFirstServer = state.server
            events.append(.tiebreakStart)
        }
        return events
    }
}

// MARK: - Sync e archiviazione (condivisi tra Watch e iPhone)

extension MatchEngine {
    /// Stato completo per la riconciliazione iPhone ↔ Watch.
    func matchState(meta: MatchMeta) -> LiveMatchState {
        LiveMatchState(config: config, meta: meta, startedAt: startDate,
                       updatedAt: updatedAt, timeline: timeline)
    }

    /// Snapshot compatto per tabellone, Live Activity e widget.
    func liveScore(meta: MatchMeta) -> LiveScore {
        LiveScore(
            sport: config.sport.rawValue,
            matchName: meta.displayVenue,
            teams: meta.teamNames(type: config.matchType),
            points: [pointLabel(for: 0), pointLabel(for: 1)],
            games: games,
            setsWon: setsWon,
            sets: sets.map { "\($0.games[0])-\($0.games[1])" },
            server: server,
            inTiebreak: inTiebreak,
            winner: winner,
            startedAt: startDate,
            updatedAt: updatedAt)
    }

    /// Record da archiviare, nil se non è stato giocato alcun punto.
    func makeRecord(meta: MatchMeta, health: MatchHealthSnapshot? = nil) -> MatchRecord? {
        guard totalPoints != [0, 0] else { return nil }
        let won = winner.map { $0 == 0 }
            ?? (setsWon[0] != setsWon[1] ? setsWon[0] > setsWon[1]
                                         : totalPoints[0] >= totalPoints[1])
        var line = sets.map { "\($0.games[0])-\($0.games[1])" }.joined(separator: " ")
        if games != [0, 0] || inTiebreak {
            line += (line.isEmpty ? "" : " ") + "(\(games[0])-\(games[1]))"
        }
        let doppio = config.matchType == .doppio
        var opp = meta.opponent.trimmingCharacters(in: .whitespaces)
        var opp2 = doppio ? meta.opponent2.trimmingCharacters(in: .whitespaces) : ""
        if opp.isEmpty { opp = opp2; opp2 = "" }   // compatta se manca il primo
        if opp.isEmpty { opp = doppio ? "Avversari" : "Avversario" }
        let record = MatchRecord(
            date: startDate,
            sport: config.sport.rawValue,
            matchType: config.matchType.rawValue,
            name: meta.name.trimmingCharacters(in: .whitespaces),
            opponent: opp,
            opponent2: opp2,
            partner: doppio ? meta.partner.trimmingCharacters(in: .whitespaces) : "",
            homeName: meta.homeName.trimmingCharacters(in: .whitespaces),
            isSpectator: meta.isSpectator,
            venue: meta.venue.trimmingCharacters(in: .whitespaces),
            courtSurface: config.sport == .tennis ? config.courtSurface.rawValue : "",
            won: won,
            finished: winner != nil,
            scoreline: line,
            setsWon: setsWon[0],
            setsLost: setsWon[1],
            pointsWon: totalPoints[0],
            pointsLost: totalPoints[1],
            duration: Date().timeIntervalSince(startDate),
            timeline: timeline,
            setBreaks: setBreaks,
            setDurations: sets.map(\.duration))
        if let health { record.applyHealth(health) }
        return record
    }
}
