import Foundation
import Observation
import SwiftData
import WidgetKit

/// Ponte CloudKit del match: quando la partita ha giocatori collegati
/// (toggle "Ha l'applicazione"), pubblica lo stato live a ogni punto e la
/// partita conclusa sul database pubblico; sugli altri dispositivi importa
/// le partite in cui l'utente compare e mostra i loro match live.
@Observable
@MainActor
final class CloudSync {
    static let shared = CloudSync()

    /// Match live degli altri partecipanti (aggiornati dal polling).
    private(set) var remoteLive: [RemoteLiveMatch] = []

    /// Tabellone condiviso a cui l'utente partecipa come invitato.
    private(set) var joinedMatch: RemoteLiveMatch? = nil

    private let joinedCreatorKey = "joinedLiveCreatorID"

    // Pubblicazione coalescente: un solo salvataggio in volo, l'ultimo vince.
    private var pending: (score: LiveScore, meta: MatchMeta)?
    private var publishing = false

    private init() {}

    private var myID: String { UserDefaults.standard.string(forKey: "appleUserID") ?? "" }
    private var myName: String {
        let name = UserName.current
        return name.isEmpty ? "Giocatore" : name
    }

    // MARK: - Pubblicazione live

    /// Pubblica lo snapshot del punteggio (chiamata a ogni punto).
    func publishLive(score: LiveScore, meta: MatchMeta) {
        guard !myID.isEmpty, !meta.isSpectator, !meta.links.isEmpty else { return }
        var cloudScore = score
        cloudScore.teams[0] = homeLabel(meta: meta)   // "NOI/IO" → nomi reali per chi guarda
        pending = (cloudScore, meta)
        guard !publishing else { return }
        publishing = true
        Task {
            while let (score, meta) = pending {
                pending = nil
                try? await CloudKitManager.shared.publishLive(
                    score: score, creatorID: myID, creatorName: myName,
                    participantIDs: [myID] + meta.links.map(\.userID))
            }
            publishing = false
        }
    }

    /// Rimuove il match live pubblicato (fine partita).
    func endLive() {
        guard !myID.isEmpty else { return }
        pending = nil
        Task { await CloudKitManager.shared.deleteLive(creatorID: myID) }
    }

    /// Etichetta della squadra di casa vista dagli altri: nome del creatore
    /// (+ partner nel doppio) al posto di "NOI"/"IO".
    private func homeLabel(meta: MatchMeta) -> String {
        let first = myName.split(separator: " ").first.map(String.init) ?? myName
        let partner = meta.partner.trimmingCharacters(in: .whitespaces)
            .split(separator: " ").first.map(String.init) ?? ""
        return (partner.isEmpty ? first : "\(first)+\(partner)").uppercased()
    }

    // MARK: - Partita conclusa

    /// Pubblica il match archiviato sui profili collegati e annota il
    /// recordName sul record locale (dedup).
    func publishFinished(record: MatchRecord, meta: MatchMeta) {
        guard !myID.isEmpty, !meta.isSpectator else { return }
        record.persistLinks(from: meta)
        Task { try? await shareRecord(record) }
    }

    /// Collega un giocatore iscritto dopo la partita e invia lo storico al suo profilo.
    func linkPlayer(record: MatchRecord,
                    slot: MatchRecord.PlayerSlot,
                    player: PlayerProfile,
                    context: ModelContext) async throws {
        guard !myID.isEmpty, !record.isSpectator else {
            throw CloudKitUserError.noAccount
        }
        guard player.appleUserID != myID else { return }
        record.applyLink(
            LinkedPlayer(userID: player.appleUserID,
                         username: player.username,
                         fullName: player.fullName),
            slot: slot
        )
        try await shareRecord(record)
        try context.save()
        WidgetCenter.shared.reloadAllTimelines()
    }

    /// Rimuove il collegamento e aggiorna la condivisione cloud.
    func unlinkPlayer(record: MatchRecord,
                      slot: MatchRecord.PlayerSlot,
                      context: ModelContext) async throws {
        guard !myID.isEmpty else { return }
        record.clearLink(slot: slot)
        if record.hasAnyLinkedPlayer {
            try await shareRecord(record)
        }
        try context.save()
    }

    @discardableResult
    private func shareRecord(_ record: MatchRecord) async throws -> String? {
        let meta = record.sharingMeta()
        guard !meta.links.isEmpty else { return nil }
        let payload = MatchRecordPayload(record: record)
        let cloudName = try await CloudKitManager.shared.publishSharedMatch(
            payload: payload, creatorID: myID, creatorName: myName, meta: meta
        )
        record.cloudID = cloudName
        return cloudName
    }

    // MARK: - Backup personale sull'account

    /// Salva la partita conclusa nell'archivio personale dell'account:
    /// al login su un altro dispositivo lo storico riparte da qui.
    func backupPersonal(record: MatchRecord) {
        guard !myID.isEmpty, record.finished else { return }
        let payload = MatchRecordPayload(record: record)
        let id = myID
        Task { try? await CloudKitManager.shared.saveUserMatch(payload: payload, userID: id) }
    }

    /// Elimina la partita anche dal backup dell'account (eliminazione dallo storico).
    func deletePersonal(matchDate: Date) {
        guard !myID.isEmpty else { return }
        let id = myID
        Task { await CloudKitManager.shared.deleteUserMatch(userID: id, matchDate: matchDate) }
    }

    /// Riconcilia lo storico locale col backup dell'account: scarica le
    /// partite mancanti in locale e carica quelle mai finite sul cloud
    /// (es. lo storico giocato prima del login).
    func syncPersonal(context: ModelContext) async {
        guard !myID.isEmpty else { return }
        guard let cloud = try? await CloudKitManager.shared.fetchUserMatches(userID: myID)
        else { return }
        let local = (try? context.fetch(FetchDescriptor<MatchRecord>())) ?? []
        let localDates = Set(local.map { Int($0.date.timeIntervalSince1970) })
        let cloudDates = Set(cloud.map { Int($0.date.timeIntervalSince1970) })

        var inserted = false
        for payload in cloud where !localDates.contains(Int(payload.date.timeIntervalSince1970)) {
            context.insert(payload.makeRecord())
            inserted = true
        }
        if inserted {
            try? context.save()
            WidgetCenter.shared.reloadAllTimelines()
        }

        for record in local
        where record.finished && !cloudDates.contains(Int(record.date.timeIntervalSince1970)) {
            try? await CloudKitManager.shared.saveUserMatch(
                payload: MatchRecordPayload(record: record), userID: myID)
        }
    }

    // MARK: - Live degli altri

    /// Aggiorna i match live in cui compaio (esclusi i miei).
    func refreshLive() async {
        guard !myID.isEmpty else { return }
        let id = myID
        guard let matches = try? await CloudKitManager.shared.fetchLiveMatches(participantID: id)
        else { return }
        remoteLive = matches.filter { $0.creatorID != id }
        syncJoinedMatch()
    }

    var canRejoinSharedMatch: Bool {
        UserDefaults.standard.string(forKey: joinedCreatorKey) != nil
    }

    /// Entra nel tabellone condiviso del creatore (invitato).
    func joinSharedMatch(creatorID: String) {
        guard !creatorID.isEmpty else { return }
        UserDefaults.standard.set(creatorID, forKey: joinedCreatorKey)
        syncJoinedMatch()
    }

    func leaveSharedMatch() {
        joinedMatch = nil
        UserDefaults.standard.removeObject(forKey: joinedCreatorKey)
    }

    private func syncJoinedMatch() {
        guard let creatorID = UserDefaults.standard.string(forKey: joinedCreatorKey) else {
            joinedMatch = nil
            return
        }
        if let live = remoteLive.first(where: { $0.creatorID == creatorID }) {
            joinedMatch = live
            return
        }
        if let previous = joinedMatch,
           previous.creatorID == creatorID,
           previous.score.updatedAt.timeIntervalSinceNow > -180 {
            return
        }
        leaveSharedMatch()
    }

    // MARK: - Import partite condivise

    /// Scarica le partite degli altri in cui compaio e le inserisce nello
    /// storico dalla mia prospettiva (ribaltata se ero avversario).
    func importShared(context: ModelContext) async {
        guard !myID.isEmpty else { return }
        guard let shared = try? await CloudKitManager.shared.fetchSharedMatches(participantID: myID)
        else { return }
        var inserted = false
        for match in shared where match.creatorID != myID {
            let cloudID = match.recordName
            let existing = (try? context.fetch(FetchDescriptor<MatchRecord>(
                predicate: #Predicate { $0.cloudID == cloudID }))) ?? []
            guard existing.isEmpty else { continue }
            context.insert(Self.localRecord(from: match, myID: myID))
            inserted = true
        }
        if inserted {
            try? context.save()
            WidgetCenter.shared.reloadAllTimelines()
        }
    }

    /// Costruisce il record locale dal match del creatore: se ero il suo
    /// partner la prospettiva coincide, se ero avversario si ribalta
    /// (esito, set, punti, timeline e scoreline invertiti).
    static func localRecord(from match: SharedMatchDownload, myID: String) -> MatchRecord {
        let p = match.payload
        let doppio = p.matchType == MatchType.doppio.rawValue
        let record: MatchRecord

        if match.partnerID == myID {
            record = p.makeRecord()
            record.partner = match.creatorName
        } else {
            let myPartner = doppio
                ? (match.opponentID == myID ? p.opponent2 : p.opponent)
                : ""
            record = MatchRecord(
                date: p.date, sport: p.sport, matchType: p.matchType, name: p.name,
                opponent: match.creatorName,
                opponent2: doppio ? p.partner : "",
                partner: myPartner,
                venue: p.venue ?? "",
                courtSurface: p.courtSurface ?? "",
                won: !p.won, finished: p.finished,
                scoreline: flipScoreline(p.scoreline),
                setsWon: p.setsLost, setsLost: p.setsWon,
                pointsWon: p.pointsLost, pointsLost: p.pointsWon,
                duration: p.duration,
                activeCalories: p.activeCalories ?? 0,
                avgHeartRate: p.avgHeartRate ?? 0,
                maxHeartRate: p.maxHeartRate ?? 0,
                steps: p.steps ?? 0,
                distanceMeters: p.distanceMeters ?? 0,
                healthRecoveredFromSalute: p.healthRecoveredFromSalute ?? false,
                timeline: p.timeline.map { 1 - $0 },
                setBreaks: p.setBreaks,
                setDurations: p.setDurations)
        }
        record.cloudID = match.recordName
        if match.partnerID == myID {
            record.partnerUserID = myID
        }
        if match.opponentID == myID {
            record.opponentUserID = myID
        }
        if match.opponent2ID == myID {
            record.opponent2UserID = myID
        }
        return record
    }

    /// "6-3 4-6 (2-1)" → "3-6 6-4 (1-2)".
    static func flipScoreline(_ line: String) -> String {
        line.split(separator: " ").map { token -> String in
            let partial = token.hasPrefix("(")
            let core = token.trimmingCharacters(in: CharacterSet(charactersIn: "()"))
            let games = core.split(separator: "-")
            guard games.count == 2 else { return String(token) }
            let flipped = "\(games[1])-\(games[0])"
            return partial ? "(\(flipped))" : flipped
        }
        .joined(separator: " ")
    }
}
