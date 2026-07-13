import Foundation

/// Stato di un invito a partita su CloudKit.
enum MatchInviteStatus: String, Codable, Equatable {
    case pending
    case accepted
    case declined
    case cancelled
    case started
}

/// Invito ricevuto o inviato per una partita con giocatori collegati.
struct MatchInvite: Identifiable, Equatable {
    let recordName: String
    let sessionID: String
    let creatorID: String
    let creatorName: String
    let inviteeID: String
    let inviteeName: String
    var status: MatchInviteStatus
    let config: MatchConfig
    let meta: MatchMeta
    let createdAt: Date

    var id: String { recordName }
}

/// Sessione di inviti in uscita creata dal giocatore che avvia la partita.
struct OutgoingMatchSession: Identifiable, Equatable {
    let sessionID: String
    let config: MatchConfig
    let meta: MatchMeta
    var invites: [MatchInvite]
    let createdAt: Date

    var id: String { sessionID }

    var allAccepted: Bool {
        !invites.isEmpty && invites.allSatisfy { $0.status == .accepted }
    }

    var anyDeclined: Bool {
        invites.contains { $0.status == .declined }
    }

    var pendingInvites: [MatchInvite] {
        invites.filter { $0.status == .pending }
    }

    var acceptedInvites: [MatchInvite] {
        invites.filter { $0.status == .accepted }
    }
}
