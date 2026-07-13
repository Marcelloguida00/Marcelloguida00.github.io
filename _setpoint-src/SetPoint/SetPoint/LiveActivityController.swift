import Foundation
import ActivityKit

/// Gestisce la Live Activity del match: tabellone in tempo reale su
/// Lock Screen e Dynamic Island, alimentato dagli snapshot del Watch.
final class LiveActivityController {
    static let shared = LiveActivityController()

    private var activity: Activity<MatchActivityAttributes>?

    func update(with snapshot: LiveScore) {
        let state = MatchActivityAttributes.ContentState(
            points: snapshot.points,
            games: snapshot.games,
            setsWon: snapshot.setsWon,
            sets: snapshot.sets,
            server: snapshot.server,
            winner: snapshot.winner)
        let content = ActivityContent(state: state, staleDate: nil)

        if let activity, activity.attributes.startedAt == snapshot.startedAt {
            Task { await activity.update(content) }
        } else {
            end()
            guard ActivityAuthorizationInfo().areActivitiesEnabled else { return }
            let attributes = MatchActivityAttributes(
                teams: snapshot.teams,
                sport: snapshot.sport,
                matchName: snapshot.matchName,
                startedAt: snapshot.startedAt)
            activity = try? Activity.request(attributes: attributes, content: content)
        }
    }

    func end() {
        guard let activity else { return }
        self.activity = nil
        Task { await activity.end(nil, dismissalPolicy: .immediate) }
    }
}
