//
//  SetPointApp.swift
//  SetPoint
//
//  Created by Marcello Guida on 09/07/26.
//

import SwiftUI
import SwiftData

@main
struct SetPointApp: App {
    private let container = SharedStore.makeContainer()

    init() {
        WatchSync.shared.activate(container: container)
#if DEBUG
        // Partita demo per screenshot e verifiche UI:
        // SIMCTL_CHILD_DEMO_MATCH=1 xcrun simctl launch <sim> com.MarcelloGuida.SetPoint
        // DEMO_MATCH=long → maratona tennis 5 set senza nomi (fallback
        // "IO/AVVERSARIO" e riga compatta dei set precedenti).
        switch ProcessInfo.processInfo.environment["DEMO_MATCH"] {
        case "1":
            var meta = MatchMeta()
            meta.venue = "Campo 1"
            meta.partner = "Giulia"
            meta.opponent = "Luca"
            meta.opponent2 = "Sara"
            WatchSync.shared.startMatch(config: MatchConfig(), meta: meta)
            let firstSet = Array(repeating: 0, count: 24)          // 6-0
            let secondSet = [0, 0, 1, 0, 1, 0, 0, 1, 0, 0, 0, 1]  // in corso
            for team in firstSet + secondSet {
                WatchSync.shared.awardPoint(to: team)
            }
        case "long":
            var config = MatchConfig()
            config.sport = .tennis
            config.matchType = .singolare
            config.setsToWin = 3
            WatchSync.shared.startMatch(config: config, meta: MatchMeta())
            let mySet = Array(repeating: 0, count: 24)             // 6-0
            let theirSet = Array(repeating: 1, count: 24)          // 0-6
            for team in mySet + theirSet + mySet + theirSet + [0, 0, 1] {
                WatchSync.shared.awardPoint(to: team)
            }
        default:
            break
        }
#endif
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(container)
    }
}
