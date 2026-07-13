//
//  ContentView.swift
//  SetPoint
//
//  Created by Marcello Guida on 09/07/26.
//

import SwiftUI
import SwiftData

extension Notification.Name {
    static let switchToLiveTab = Notification.Name("switchToLiveTab")
}

private enum AppTab: Hashable {
    case live, history, h2h, profile
}

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.scenePhase) private var scenePhase
    @State private var photoPrompt: PhotoPromptItem? = nil
    @State private var selectedTab: AppTab = .live

    var body: some View {
        TabView(selection: $selectedTab) {
            Tab("Live", systemImage: "dot.radiowaves.left.and.right", value: AppTab.live) {
                LiveScreen()
            }
            Tab("Storico", systemImage: "clock.arrow.circlepath", value: AppTab.history) {
                HistoryScreen()
            }
            Tab("Rivalità", systemImage: "person.line.dotted.person.fill", value: AppTab.h2h) {
                H2HScreen()
            }
            Tab("Profilo", systemImage: "person.crop.circle", value: AppTab.profile) {
                ProfileScreen()
            }
        }
        .tint(Theme.accent)
        .onReceive(NotificationCenter.default.publisher(for: .switchToLiveTab)) { _ in
            selectedTab = .live
        }
        .onReceive(NotificationCenter.default.publisher(for: .matchSavedForPhoto)) { note in
            guard let date = note.userInfo?["matchDate"] as? Date else { return }
            photoPrompt = PhotoPromptItem(matchDate: date)
        }
        .sheet(item: $photoPrompt) { item in
            MatchPhotoPromptSheet(matchDate: item.matchDate) {
                photoPrompt = nil
            }
        }
        .task {
            WatchSync.shared.refreshWatchInstallStatus()
            await NotificationManager.shared.requestPermissionIfNeeded()
            await CloudSync.shared.importShared(context: modelContext)
            await CloudSync.shared.syncPersonal(context: modelContext)
            await MatchInviteSync.shared.refreshAll()
            await MatchPhotoSync.shared.refreshFromCloud(context: modelContext)
        }
        .onChange(of: scenePhase) { _, phase in
            guard phase == .active else { return }
            WatchSync.shared.refreshWatchInstallStatus()
            Task {
                await CloudSync.shared.importShared(context: modelContext)
                await CloudSync.shared.syncPersonal(context: modelContext)
                await MatchInviteSync.shared.refreshAll()
                await MatchPhotoSync.shared.refreshFromCloud(context: modelContext)
            }
        }
    }
}

#Preview {
    ContentView()
        .modelContainer(for: MatchRecord.self, inMemory: true)
}
