import Foundation
import Observation

/// Gestisce inviti a partita: invio, accettazione e avvio solo quando tutti confermano.
@Observable
@MainActor
final class MatchInviteSync {
    static let shared = MatchInviteSync()

    private(set) var incoming: [MatchInvite] = []
    private(set) var outgoingSession: OutgoingMatchSession?
    var statusMessage: String? = nil

    private var seenIncomingIDs = Set<String>()
    private var notifiedAcceptedIDs = Set<String>()
    private let sessionKey = "pendingMatchSessionID"
    private let joinInviteRecordKey = "pendingJoinInviteRecord"

    private init() {}

    private var myID: String { UserDefaults.standard.string(forKey: "appleUserID") ?? "" }
    private var myName: String {
        let name = UserName.current
        return name.isEmpty ? "Giocatore" : name
    }

    /// True se la partita richiede inviti prima di partire.
    static func requiresInvites(meta: MatchMeta) -> Bool {
        !meta.isSpectator && !meta.links.isEmpty
    }

    // MARK: - Invio (creatore)

    func sendInvites(config: MatchConfig, meta: MatchMeta) async throws {
        guard !myID.isEmpty else { return }
        if let old = outgoingSession {
            try? await CloudKitManager.shared.cancelMatchSession(sessionID: old.sessionID)
            CloudKitManager.shared.clearInviteSessionCache(sessionID: old.sessionID)
        }
        let sessionID = "session-\(myID)-\(Int(Date().timeIntervalSince1970))"
        try? await CloudKitManager.shared.cancelPendingInvites(
            from: myID,
            exceptSessionID: sessionID
        )
        try await CloudKitManager.shared.publishMatchInvites(
            sessionID: sessionID,
            creatorID: myID,
            creatorName: myName,
            config: config,
            meta: meta
        )
        UserDefaults.standard.set(sessionID, forKey: sessionKey)
        statusMessage = nil
        await refreshOutgoing()
    }

    func cancelOutgoing() async {
        guard let session = outgoingSession else { return }
        try? await CloudKitManager.shared.cancelMatchSession(sessionID: session.sessionID)
        CloudKitManager.shared.clearInviteSessionCache(sessionID: session.sessionID)
        outgoingSession = nil
        UserDefaults.standard.removeObject(forKey: sessionKey)
        statusMessage = "Inviti annullati."
    }

    // MARK: - Risposta (invitato)

    func accept(_ invite: MatchInvite) async {
        guard !myID.isEmpty else {
            statusMessage = "Accedi con Apple dal Profilo per accettare gli inviti."
            return
        }
        do {
            try await CloudKitManager.shared.respondToInvite(
                invite,
                status: .accepted,
                inviteeID: myID
            )
            UserDefaults.standard.set(invite.recordName, forKey: joinInviteRecordKey)
            incoming.removeAll { $0.id == invite.id }
            statusMessage = "Invito accettato. La partita partirà appena il creatore la avvia."
            await refreshAll()
        } catch {
            statusMessage = "Impossibile accettare l'invito: \(error.localizedDescription)"
        }
    }

    func decline(_ invite: MatchInvite) async {
        guard !myID.isEmpty else {
            statusMessage = "Accedi con Apple dal Profilo per rifiutare gli inviti."
            return
        }
        do {
            try await CloudKitManager.shared.respondToInvite(
                invite,
                status: .declined,
                inviteeID: myID
            )
            if UserDefaults.standard.string(forKey: joinInviteRecordKey) == invite.recordName {
                UserDefaults.standard.removeObject(forKey: joinInviteRecordKey)
            }
            incoming.removeAll { $0.id == invite.id }
            statusMessage = nil
        } catch {
            statusMessage = "Impossibile rifiutare l'invito: \(error.localizedDescription)"
        }
    }

    // MARK: - Polling

    func refreshAll() async {
        await refreshIncoming()
        await refreshOutgoing()
        await tryRejoinShared()
    }

    /// Creatore: avvia manualmente quando tutti hanno accettato.
    func startOutgoingMatch() async {
        guard let session = outgoingSession,
              session.allAccepted,
              WatchSync.shared.live == nil
        else { return }

        var meta = session.meta
        if !meta.isSpectator, meta.homeName.trimmingCharacters(in: .whitespaces).isEmpty {
            meta.homeName = myName
        }
        WatchSync.shared.startMatch(config: session.config, meta: meta)

        NotificationManager.shared.notifyAllAccepted()
        try? await CloudKitManager.shared.markSessionStarted(sessionID: session.sessionID)
        UserDefaults.standard.removeObject(forKey: sessionKey)
        CloudKitManager.shared.clearInviteSessionCache(sessionID: session.sessionID)
        outgoingSession = nil
        notifiedAcceptedIDs.removeAll()
        statusMessage = "Partita avviata!"
    }

    private func refreshIncoming() async {
        guard !myID.isEmpty else {
            incoming = []
            return
        }
        guard let invites = try? await CloudKitManager.shared.fetchPendingInvites(for: myID) else {
            return
        }
        for invite in invites where !seenIncomingIDs.contains(invite.id) {
            NotificationManager.shared.notifyMatchInvite(
                from: invite.creatorName,
                sessionID: invite.sessionID
            )
            seenIncomingIDs.insert(invite.id)
        }
        incoming = invites
    }

    private func refreshOutgoing() async {
        guard !myID.isEmpty,
              let sessionID = UserDefaults.standard.string(forKey: sessionKey)
        else {
            outgoingSession = nil
            return
        }

        guard let invites = try? await CloudKitManager.shared.fetchInvites(sessionID: sessionID),
              !invites.isEmpty
        else {
            // Errore di rete o CloudKit: mantieni la sessione visibile.
            return
        }

        if invites.allSatisfy({ $0.status == .cancelled }) {
            outgoingSession = nil
            UserDefaults.standard.removeObject(forKey: sessionKey)
            CloudKitManager.shared.clearInviteSessionCache(sessionID: sessionID)
            return
        }

        if invites.allSatisfy({ $0.status == .started }),
           WatchSync.shared.live != nil {
            outgoingSession = nil
            UserDefaults.standard.removeObject(forKey: sessionKey)
            CloudKitManager.shared.clearInviteSessionCache(sessionID: sessionID)
            return
        }

        let session = OutgoingMatchSession(
            sessionID: sessionID,
            config: invites[0].config,
            meta: invites[0].meta,
            invites: invites,
            createdAt: invites[0].createdAt
        )
        outgoingSession = session

        for invite in invites where invite.status == .accepted && !notifiedAcceptedIDs.contains(invite.id) {
            NotificationManager.shared.notifyInviteAccepted(by: invite.inviteeName)
            notifiedAcceptedIDs.insert(invite.id)
        }

        if session.anyDeclined {
            let declined = invites.filter { $0.status == .declined }.map(\.inviteeName).joined(separator: ", ")
            statusMessage = "\(declined) ha rifiutato la partita."
            try? await CloudKitManager.shared.cancelMatchSession(sessionID: sessionID)
            CloudKitManager.shared.clearInviteSessionCache(sessionID: sessionID)
            outgoingSession = nil
            UserDefaults.standard.removeObject(forKey: sessionKey)
            for invite in invites where invite.status == .declined {
                NotificationManager.shared.notifyInviteDeclined(by: invite.inviteeName)
            }
        }
    }

    /// Invitato: rientra nel tabellone condiviso del creatore.
    private func tryRejoinShared() async {
        guard WatchSync.shared.live == nil else { return }
        guard let recordName = UserDefaults.standard.string(forKey: joinInviteRecordKey),
              let invite = try? await CloudKitManager.shared.fetchInvite(recordName: recordName),
              invite.status == .started
        else { return }
        CloudSync.shared.joinSharedMatch(creatorID: invite.creatorID)
    }
}
