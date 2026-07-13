import Foundation

/// Snapshot compatto dello stato live del match, inviato dal Watch all'iPhone
/// a ogni punto (Live Sync). L'ultimo stato vince: viaggia via applicationContext.
struct LiveScore: Codable, Equatable {
    var sport: String
    var matchName: String
    var teams: [String]
    var points: [String]        // etichette punteggio del game ("40", "AD", cifre nel TB)
    var games: [Int]
    var setsWon: [Int]
    var sets: [String]          // set chiusi, es. "6-3"
    var server: Int
    var inTiebreak: Bool
    var winner: Int?
    var startedAt: Date
    var updatedAt: Date
}

/// Versione trasferibile di MatchRecord per il sync Watch → iPhone
/// (transferUserInfo: coda affidabile, consegna anche a iPhone non raggiungibile).
struct MatchRecordPayload: Codable {
    var date: Date
    var sport: String
    var matchType: String
    var name: String
    var opponent: String
    var opponent2: String
    var partner: String
    var homeName: String
    var isSpectator: Bool
    var won: Bool
    var finished: Bool
    var scoreline: String
    var setsWon: Int
    var setsLost: Int
    var pointsWon: Int
    var pointsLost: Int
    var duration: TimeInterval
    var activeCalories: Double? = nil
    var avgHeartRate: Double? = nil
    var maxHeartRate: Double? = nil
    var steps: Int? = nil
    var distanceMeters: Double? = nil
    var healthRecoveredFromSalute: Bool? = nil
    var timeline: [Int]
    var setBreaks: [Int]
    var setDurations: [Double]
    var hasMatchPhoto: Bool? = nil
    var courtSurface: String? = nil
    var latitude: Double? = nil
    var longitude: Double? = nil

    var venue: String? = nil

    init(record: MatchRecord) {
        date = record.date
        sport = record.sport
        matchType = record.matchType
        name = record.name
        venue = record.venue
        opponent = record.opponent
        opponent2 = record.opponent2
        partner = record.partner
        homeName = record.homeName
        isSpectator = record.isSpectator
        won = record.won
        finished = record.finished
        scoreline = record.scoreline
        setsWon = record.setsWon
        setsLost = record.setsLost
        pointsWon = record.pointsWon
        pointsLost = record.pointsLost
        duration = record.duration
        activeCalories = record.activeCalories
        avgHeartRate = record.avgHeartRate
        maxHeartRate = record.maxHeartRate
        steps = record.steps
        distanceMeters = record.distanceMeters
        healthRecoveredFromSalute = record.healthRecoveredFromSalute
        timeline = record.timeline
        setBreaks = record.setBreaks
        setDurations = record.setDurations
        hasMatchPhoto = record.hasMatchPhoto
        courtSurface = record.courtSurface
        latitude = record.latitude
        longitude = record.longitude
    }

    func makeRecord() -> MatchRecord {
        MatchRecord(date: date, sport: sport, matchType: matchType, name: name,
                    opponent: opponent, opponent2: opponent2, partner: partner,
                    homeName: homeName, isSpectator: isSpectator, venue: venue ?? "",
                    hasMatchPhoto: hasMatchPhoto ?? false,
                    courtSurface: courtSurface ?? "",
                    latitude: latitude ?? 0,
                    longitude: longitude ?? 0,
                    won: won, finished: finished, scoreline: scoreline,
                    setsWon: setsWon, setsLost: setsLost,
                    pointsWon: pointsWon, pointsLost: pointsLost,
                    duration: duration,
                    activeCalories: activeCalories ?? 0,
                    avgHeartRate: avgHeartRate ?? 0,
                    maxHeartRate: maxHeartRate ?? 0,
                    steps: steps ?? 0,
                    distanceMeters: distanceMeters ?? 0,
                    healthRecoveredFromSalute: healthRecoveredFromSalute ?? false,
                    timeline: timeline, setBreaks: setBreaks, setDurations: setDurations)
    }
}

/// Stato completo del match live, scambiato in entrambe le direzioni
/// (avvio remoto e riconciliazione): config + timeline bastano a
/// ricostruire il motore con un replay. Vince chi ha più punti in timeline,
/// a parità di conteggio vince l'updatedAt più recente.
struct LiveMatchState: Codable {
    var config: MatchConfig
    var meta: MatchMeta
    var startedAt: Date
    var updatedAt: Date
    var timeline: [Int]

    /// true se questo snapshot deve sostituire il motore locale.
    func shouldReplace(engine: MatchEngine) -> Bool {
        guard startedAt == engine.startDate else { return true }
        if timeline.count > engine.timeline.count { return true }
        if timeline.count < engine.timeline.count { return false }
        if timeline != engine.timeline { return updatedAt >= engine.updatedAt }
        return updatedAt > engine.updatedAt
    }
}

/// Payload del canale WatchConnectivity: snapshot per la UI ("live") +
/// stato completo per la riconciliazione ("liveState").
enum LiveSync {
    static func context(engine: MatchEngine, meta: MatchMeta) -> [String: Any]? {
        let encoder = JSONEncoder()
        guard let live = try? encoder.encode(engine.liveScore(meta: meta)),
              let state = try? encoder.encode(engine.matchState(meta: meta))
        else { return nil }
        return ["live": live, "liveState": state]
    }
}

#if canImport(ActivityKit)
import ActivityKit

/// Attributi della Live Activity del match (Lock Screen + Dynamic Island).
struct MatchActivityAttributes: ActivityAttributes {
    struct ContentState: Codable, Hashable {
        var points: [String]
        var games: [Int]
        var setsWon: [Int]
        var sets: [String]
        var server: Int
        var winner: Int?
    }

    var teams: [String]
    var sport: String
    var matchName: String
    var startedAt: Date
}
#endif

#if os(iOS) || os(watchOS)
import SwiftData

/// Store SwiftData condiviso tra app iOS e widget tramite App Group.
/// cloudKitDatabase è sempre .none: con l'entitlement iCloud presente,
/// .automatic attiverebbe il sync CloudKit e la validazione dello schema
/// fallirebbe (MatchRecord ha proprietà senza default). CloudKit è usato
/// solo via CKContainer per i profili (CloudKitManager).
enum SharedStore {
    static let appGroup = "group.com.MarcelloGuida.SetPoint"

    #if os(watchOS)
    private static let storeFileName = "SetPoint-watch.store"
    #else
    private static let storeFileName = "SetPoint.store"
    #endif

    static func makeContainer() -> ModelContainer {
        let schema = Schema([MatchRecord.self])

        // 1. Prova App Group (store condiviso con i widget su iOS)
        if let url = FileManager.default
            .containerURL(forSecurityApplicationGroupIdentifier: appGroup)?
            .appendingPathComponent(storeFileName) {
            if let container = try? ModelContainer(for: schema,
                                                   configurations: ModelConfiguration(url: url, cloudKitDatabase: .none)) {
                return container
            }
            // Store incompatibile (schema cambiato): cancella e ricrea
            try? FileManager.default.removeItem(at: url)
            let walURL = url.deletingPathExtension().appendingPathExtension("store-wal")
            let shmURL = url.deletingPathExtension().appendingPathExtension("store-shm")
            try? FileManager.default.removeItem(at: walURL)
            try? FileManager.default.removeItem(at: shmURL)
            if let container = try? ModelContainer(for: schema,
                                                   configurations: ModelConfiguration(url: url, cloudKitDatabase: .none)) {
                return container
            }
        }

        // 2. Fallback store locale (se App Group non disponibile)
        if let container = try? ModelContainer(for: schema,
                                               configurations: ModelConfiguration(cloudKitDatabase: .none)) {
            return container
        }

        // 3. Ultimo fallback: in-memory (mai bloccare l'avvio al polso)
        do {
            return try ModelContainer(for: schema,
                                      configurations: ModelConfiguration(isStoredInMemoryOnly: true,
                                                                         cloudKitDatabase: .none))
        } catch {
            #if os(watchOS)
            // Evita fatalError sul polso: l'app resta usabile anche senza storico locale.
            if let container = try? ModelContainer(
                for: schema,
                configurations: ModelConfiguration(isStoredInMemoryOnly: true,
                                                     cloudKitDatabase: .none)) {
                return container
            }
            return try! ModelContainer(for: Schema([]),
                                       configurations: ModelConfiguration(isStoredInMemoryOnly: true,
                                                                          cloudKitDatabase: .none))
            #else
            fatalError("Impossibile creare il ModelContainer SwiftData: \(error)")
            #endif
        }
    }
}
#endif
