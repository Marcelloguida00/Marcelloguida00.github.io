import Foundation
import UserNotifications

/// Notifiche locali per inviti e aggiornamenti partita.
@MainActor
final class NotificationManager {
    static let shared = NotificationManager()

    private init() {}

    func requestPermissionIfNeeded() async {
        let center = UNUserNotificationCenter.current()
        let settings = await center.notificationSettings()
        guard settings.authorizationStatus == .notDetermined else { return }
        _ = try? await center.requestAuthorization(options: [.alert, .sound, .badge])
    }

    func notifyMatchInvite(from creatorName: String, sessionID: String) {
        post(
            id: "invite-\(sessionID)",
            title: "Invito a una partita",
            body: "\(creatorName) ti ha aggiunto a una partita. Apri SetPoint per accettare."
        )
    }

    func notifyInviteAccepted(by playerName: String) {
        post(
            id: "accepted-\(UUID().uuidString)",
            title: "Invito accettato",
            body: "\(playerName) ha accettato la partita."
        )
    }

    func notifyInviteDeclined(by playerName: String) {
        post(
            id: "declined-\(UUID().uuidString)",
            title: "Invito rifiutato",
            body: "\(playerName) ha rifiutato la partita."
        )
    }

    func notifyAllAccepted() {
        post(
            id: "all-accepted-\(UUID().uuidString)",
            title: "Tutti pronti!",
            body: "Tutti i giocatori hanno accettato: la partita sta per iniziare."
        )
    }

    private func post(id: String, title: String, body: String) {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default
        let request = UNNotificationRequest(identifier: id, content: content, trigger: nil)
        UNUserNotificationCenter.current().add(request)
    }
}
