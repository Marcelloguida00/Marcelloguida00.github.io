import Foundation
import HealthKit
import Observation
import SwiftData
import WatchConnectivity
import WidgetKit

/// Hub del match live su iPhone: tiene un motore di punteggio locale, così
/// il tabellone funziona anche a Watch scollegato. Lo stato viaggia nei due
/// sensi via applicationContext e alla riconnessione vince chi ha
/// l'aggiornamento più recente. I match conclusi arrivano dal Watch via
/// transferUserInfo (coda affidabile) con dedup per data.
@Observable
final class WatchSync: NSObject, WCSessionDelegate {
    static let shared = WatchSync()

    /// Snapshot del match in corso (alimenta tabellone e Live Activity).
    var live: LiveScore?

    /// Watch raggiungibile: le modifiche arrivano al polso in tempo reale.
    var reachable = false

    /// Watch app installata.
    var isWatchAppInstalled = false

    /// Motore locale del match in corso, nil se nessuno.
    private(set) var engine: MatchEngine?
    private var meta = MatchMeta()

    /// Inizio dell'ultimo match gestito: aggancia il record archiviato
    /// (anche quello in arrivo dal Watch) ai giocatori collegati del meta.
    private var lastStart: Date?

    private var container: ModelContainer?
    private let healthStore = HKHealthStore()
    private let activeMatchStateKey = "activeLiveMatchState"

    func activate(container: ModelContainer) {
        self.container = container
        guard WCSession.isSupported() else { return }
        WCSession.default.delegate = self
        WCSession.default.activate()
    }

    /// Rilegge lo stato di installazione dal sistema (utile all'apertura dell'app).
    func refreshWatchInstallStatus() {
        guard WCSession.isSupported() else { return }
        let session = WCSession.default
        guard session.activationState == .activated else { return }
        reachable = session.isReachable
        isWatchAppInstalled = session.isWatchAppInstalled || session.isReachable
    }

    var canRestoreMatch: Bool {
        guard engine == nil, live == nil,
              let data = UserDefaults.standard.data(forKey: activeMatchStateKey),
              let state = try? JSONDecoder().decode(LiveMatchState.self, from: data)
        else { return false }
        return state.updatedAt.timeIntervalSinceNow > -6 * 3600
    }

    @discardableResult
    func restoreMatchIfNeeded() -> Bool {
        guard canRestoreMatch,
              let data = UserDefaults.standard.data(forKey: activeMatchStateKey),
              let state = try? JSONDecoder().decode(LiveMatchState.self, from: data)
        else { return false }
        adopt(state)
        removeSuspendedRecord(matching: state.startedAt)
        return true
    }

    /// Riprende una partita sospesa dallo storico sul tabellone live.
    @discardableResult
    func resumeFromHistory(_ record: MatchRecord) -> Bool {
        guard engine == nil, live == nil,
              let state = record.liveMatchState()
        else { return false }
        adopt(state)
        clearPersistedMatch()
        return true
    }

    // MARK: - Match locale (funziona anche senza Watch)

    /// Avvia una partita: il motore parte subito sul telefono; il Watch
    /// la apre via sendMessage se raggiungibile, altrimenti la adotta
    /// dall'applicationContext alla riconnessione.
    func startMatch(config: MatchConfig, meta: MatchMeta) {
        var meta = meta
        if !meta.isSpectator,
           meta.homeName.trimmingCharacters(in: .whitespaces).isEmpty {
            meta.homeName = UserName.current
        }
        self.meta = meta
        engine = MatchEngine(config: config)
        lastStart = engine?.startDate
        publishLocal()
        if WCSession.default.isReachable,
           let engine,
           let data = try? JSONEncoder().encode(engine.matchState(meta: meta)) {
            WCSession.default.sendMessage(["liveState": data], replyHandler: nil)
        }
        wakeWatchApp()
    }

    /// Assegna un punto dal tabellone del telefono.
    func awardPoint(to team: Int) {
        guard let engine, engine.winner == nil else { return }
        engine.awardPoint(to: team)
        publishLocal()
    }

    /// Annulla l'ultimo punto dal telefono.
    func undoPoint() {
        guard let engine, engine.canUndo else { return }
        engine.undo()
        publishLocal()
    }

    var canUndo: Bool { engine?.canUndo ?? false }

    /// Chiude il match dal telefono: archivia il record, spegne la Live
    /// Activity e avvisa il Watch.
    func endMatch() {
        guard let engine else { return }
        if let record = engine.makeRecord(meta: meta) {
            record.finished = true
            record.persistLinks(from: meta)
            if upsert(record) {
                MatchPhotoSync.shared.requestPromptIfNeeded(for: record.date)
            }
        }
        pushEnded(startedAt: engine.startDate)
        self.engine = nil
        live = nil
        clearPersistedMatch()
        LiveActivityController.shared.end()
        CloudSync.shared.endLive()
    }

    /// Mette in pausa: archivia come sospesa e mantiene lo stato per la ripresa.
    func pauseMatch() {
        guard let engine else { return }
        guard let record = engine.makeRecord(meta: meta) else { return }
        record.finished = false
        record.persistLinks(from: meta)
        upsertSuspended(record)
        lastStart = engine.startDate
        persistActiveMatch()
        pushEnded(startedAt: engine.startDate)
        self.engine = nil
        live = nil
        LiveActivityController.shared.end()
        CloudSync.shared.endLive()
    }

    /// Aggiorna tabellone, Live Activity e Watch dopo un'azione locale.
    private func publishLocal() {
        guard let engine else { return }
        let snapshot = engine.liveScore(meta: meta)
        live = snapshot
        persistActiveMatch()
        LiveActivityController.shared.update(with: snapshot)
        CloudSync.shared.publishLive(score: snapshot, meta: meta)
        guard WCSession.default.activationState == .activated,
              let context = LiveSync.context(engine: engine, meta: meta) else { return }
        // Consegna istantanea al polso quando raggiungibile; il context
        // resta la rete di sicurezza per la riconnessione.
        if WCSession.default.isReachable {
            WCSession.default.sendMessage(context, replyHandler: nil)
        }
        try? WCSession.default.updateApplicationContext(context)
    }

    /// Sovrascrive il contesto pubblicato: un match chiuso non va riadottato.
    private func pushEnded(startedAt: Date) {
        guard WCSession.default.activationState == .activated else { return }
        let payload: [String: Any] = ["liveEnded": startedAt.timeIntervalSince1970]
        if WCSession.default.isReachable {
            WCSession.default.sendMessage(payload, replyHandler: nil)
        }
        try? WCSession.default.updateApplicationContext(payload)
    }

    /// Lancia l'app Watch come per un allenamento, così il match parte
    /// anche a Watch spento sul quadrante.
    private func wakeWatchApp() {
        guard HKHealthStore.isHealthDataAvailable() else { return }
        let configuration = HKWorkoutConfiguration()
        configuration.activityType = .tennis
        configuration.locationType = .outdoor
        healthStore.startWatchApp(with: configuration) { _, _ in }
    }

    // MARK: - Stato in arrivo dal Watch

    private func handle(context: [String: Any]) {
        if context["watchReady"] != nil {
            isWatchAppInstalled = true
            return
        }
        // Il context di fine match porta sia il record ("match") sia il
        // segnale di chiusura ("liveEnded"): vanno processati entrambi.
        if let data = context["match"] as? Data {
            insert(matchData: data)
        }
        if let data = context["liveState"] as? Data,
           let state = try? JSONDecoder().decode(LiveMatchState.self, from: data) {
            adopt(state)
        } else if let ended = context["liveEnded"] as? TimeInterval {
            if let engine {
                // Chiudi solo lo stesso match: il record arriva dal Watch
                guard abs(engine.startDate.timeIntervalSince1970 - ended) < 1 else { return }
                self.engine = nil
            }
            live = nil
            clearPersistedMatch()
            LiveActivityController.shared.end()
            CloudSync.shared.endLive()
        }
    }

    private func persistActiveMatch() {
        guard let engine else { return }
        let state = engine.matchState(meta: meta)
        guard let data = try? JSONEncoder().encode(state) else { return }
        UserDefaults.standard.set(data, forKey: activeMatchStateKey)
    }

    private func clearPersistedMatch() {
        UserDefaults.standard.removeObject(forKey: activeMatchStateKey)
    }

    /// Adotta lo stato del Watch se più recente del locale
    /// (riconciliazione: vince chi ha segnato per ultimo).
    private func adopt(_ state: LiveMatchState) {
        if let engine {
            guard state.shouldReplace(engine: engine) else { return }
            if state.startedAt != engine.startDate,
               let record = engine.makeRecord(meta: meta) {
                _ = upsert(record)   // match diverso e più recente: archivia il locale
            }
        }
        meta = state.meta
        lastStart = state.startedAt
        let restored = MatchEngine.restore(state)
        engine = restored
        publishLocal()
    }

    // MARK: - Archivio

    private func upsertSuspended(_ record: MatchRecord) {
        guard let container else { return }
        let context = container.mainContext
        let date = record.date
        let duplicates = (try? context.fetch(FetchDescriptor<MatchRecord>(
            predicate: #Predicate { $0.date == date }))) ?? []
        duplicates.forEach { context.delete($0) }
        context.insert(record)
        try? context.save()
        #if os(iOS)
        Task { @MainActor in
            if await MatchLocationCapture.shared.attachIfNeeded(to: record) {
                try? context.save()
            }
        }
        #endif
        WidgetCenter.shared.reloadAllTimelines()
    }

    private func removeSuspendedRecord(matching startedAt: Date) {
        guard let container else { return }
        let context = container.mainContext
        let target = startedAt
        let matches = (try? context.fetch(FetchDescriptor<MatchRecord>(
            predicate: #Predicate { $0.date == target && !$0.finished }
        ))) ?? []
        guard !matches.isEmpty else { return }
        matches.forEach { context.delete($0) }
        try? context.save()
        WidgetCenter.shared.reloadAllTimelines()
    }

    @discardableResult
    private func upsert(_ record: MatchRecord) -> Bool {
        guard let container else { return false }
        let context = container.mainContext
        let date = record.date
        let duplicates = (try? context.fetch(FetchDescriptor<MatchRecord>(
            predicate: #Predicate { $0.date == date }))) ?? []

        let saved: MatchRecord
        let isNew: Bool

        if let existing = duplicates.first {
            mergeFromWatch(into: existing, from: record)
            duplicates.dropFirst().forEach { context.delete($0) }
            saved = existing
            isNew = false
        } else {
            context.insert(record)
            saved = record
            isNew = true
        }

        try? context.save()
        attachExtras(to: saved, context: context, publishIfNew: isNew)
        return isNew
    }

    /// Unisce record dal Watch (stessa data): salute + punteggio se più aggiornato.
    private func mergeFromWatch(into existing: MatchRecord, from incoming: MatchRecord) {
        if incoming.hasHealthData
            && (!existing.hasHealthData || incoming.activeCalories > existing.activeCalories) {
            existing.applyHealth(incoming.healthSnapshot)
            existing.healthRecoveredFromSalute = incoming.healthRecoveredFromSalute
        }
        guard incoming.timeline.count >= existing.timeline.count else { return }
        existing.finished = incoming.finished
        existing.won = incoming.won
        existing.scoreline = incoming.scoreline
        existing.setsWon = incoming.setsWon
        existing.setsLost = incoming.setsLost
        existing.pointsWon = incoming.pointsWon
        existing.pointsLost = incoming.pointsLost
        existing.duration = incoming.duration
        existing.timeline = incoming.timeline
        existing.setBreaks = incoming.setBreaks
        existing.setDurations = incoming.setDurations
    }

    #if os(iOS)
    private func attachExtras(to record: MatchRecord, context: ModelContext, publishIfNew: Bool) {
        Task { @MainActor in
            if !record.hasHealthData {
                await MatchHealthRecovery.recoverIfNeeded(for: record, context: context)
            }
            if await MatchLocationCapture.shared.attachIfNeeded(to: record) {
                try? context.save()
            }
        }
        WidgetCenter.shared.reloadAllTimelines()
        CloudSync.shared.backupPersonal(record: record)
        if publishIfNew, let lastStart, abs(record.date.timeIntervalSince(lastStart)) < 2 {
            CloudSync.shared.publishFinished(record: record, meta: meta)
        }
    }
    #else
    private func attachExtras(to record: MatchRecord, context: ModelContext, publishIfNew: Bool) {
        WidgetCenter.shared.reloadAllTimelines()
        if publishIfNew, let lastStart, abs(record.date.timeIntervalSince(lastStart)) < 2 {
            CloudSync.shared.publishFinished(record: record, meta: meta)
        }
    }
    #endif

    private func insert(matchData: Data) {
        guard let payload = try? JSONDecoder().decode(MatchRecordPayload.self,
                                                      from: matchData) else { return }
        let record = payload.makeRecord()
        if upsert(record) {
            MatchPhotoSync.shared.requestPromptIfNeeded(for: record.date)
        } else {
            // Record già presente (es. chiusura da iPhone): aggiorna foto se serve.
            MatchPhotoSync.shared.requestPromptIfNeeded(for: record.date)
        }
    }

    private func handleReceivedPhoto(_ file: WCSessionFile) {
        guard let timestamp = file.metadata?["matchPhotoDate"] as? TimeInterval else { return }
        let matchDate = Date(timeIntervalSince1970: timestamp)
        let context = container?.mainContext
        MatchPhotoSync.shared.applyReceivedPhoto(
            at: file.fileURL, matchDate: matchDate, context: context)
    }

    // MARK: - WCSessionDelegate

    nonisolated func session(_ session: WCSession,
                             activationDidCompleteWith activationState: WCSessionActivationState,
                             error: Error?) {
        // Recupera l'eventuale stato live già pubblicato dal Watch
        let context = session.receivedApplicationContext
        let reachable = session.isReachable
        let installed = session.isWatchAppInstalled
        Task { @MainActor in
            self.reachable = reachable
            // isWatchAppInstalled può restare false su app Watch installate
            // da Xcode (bug noto): qualsiasi segnale dal Watch fa fede.
            self.isWatchAppInstalled = installed || reachable
            if !context.isEmpty { self.handle(context: context) }
        }
    }

    nonisolated func sessionReachabilityDidChange(_ session: WCSession) {
        let reachable = session.isReachable
        Task { @MainActor in
            self.reachable = reachable
            if reachable { self.isWatchAppInstalled = true }
        }
    }

    nonisolated func sessionWatchStateDidChange(_ session: WCSession) {
        let installed = session.isWatchAppInstalled || session.isReachable
        Task { @MainActor in
            self.isWatchAppInstalled = installed
        }
    }

    nonisolated func session(_ session: WCSession,
                             didReceiveApplicationContext applicationContext: [String: Any]) {
        Task { @MainActor in
            self.isWatchAppInstalled = true   // ci sta parlando: è installata
            self.handle(context: applicationContext)
        }
    }

    /// Punto in arrivo dal Watch via sendMessage: canale istantaneo.
    /// Il doppione via context viene scartato dal check su updatedAt.
    nonisolated func session(_ session: WCSession,
                             didReceiveMessage message: [String: Any]) {
        Task { @MainActor in
            self.isWatchAppInstalled = true
            self.handle(context: message)
        }
    }

    nonisolated func session(_ session: WCSession,
                             didReceiveUserInfo userInfo: [String: Any] = [:]) {
        guard let data = userInfo["match"] as? Data else { return }
        Task { @MainActor in
            self.isWatchAppInstalled = true
            self.insert(matchData: data)
        }
    }

    nonisolated func session(_ session: WCSession, didReceive file: WCSessionFile) {
        Task { @MainActor in
            self.isWatchAppInstalled = true
            self.handleReceivedPhoto(file)
        }
    }

    nonisolated func sessionDidBecomeInactive(_ session: WCSession) { }

    nonisolated func sessionDidDeactivate(_ session: WCSession) {
        session.activate()
    }
}
