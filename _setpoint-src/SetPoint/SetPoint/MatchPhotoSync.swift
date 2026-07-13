import Foundation
import Observation
import SwiftData
import SwiftUI
import UIKit
import WatchConnectivity

/// Salva, sincronizza e scarica le foto ricordo di fine partita.
@Observable
@MainActor
final class MatchPhotoSync {
    static let shared = MatchPhotoSync()

    private let skippedKey = "skippedMatchPhotoPrompts"

    private init() {}

    // MARK: - Prompt

    func shouldPrompt(for matchDate: Date) -> Bool {
        guard !MatchPhotoStore.exists(for: matchDate) else { return false }
        let key = Int(matchDate.timeIntervalSince1970)
        let skipped = UserDefaults.standard.array(forKey: skippedKey) as? [Int] ?? []
        return !skipped.contains(key)
    }

    func skipPrompt(for matchDate: Date) {
        let key = Int(matchDate.timeIntervalSince1970)
        var skipped = Set(UserDefaults.standard.array(forKey: skippedKey) as? [Int] ?? [])
        skipped.insert(key)
        UserDefaults.standard.set(Array(skipped), forKey: skippedKey)
    }

    func requestPromptIfNeeded(for matchDate: Date) {
        guard shouldPrompt(for: matchDate) else { return }
        NotificationCenter.default.post(
            name: .matchSavedForPhoto,
            object: nil,
            userInfo: ["matchDate": matchDate]
        )
    }

    // MARK: - Salvataggio

    func savePhoto(_ image: UIImage, matchDate: Date, context: ModelContext) async {
        guard MatchPhotoStore.save(image, matchDate: matchDate) else { return }
        markRecord(hasPhoto: true, matchDate: matchDate, context: context)
        transferToCompanion(matchDate: matchDate)
        if let data = try? Data(contentsOf: MatchPhotoStore.url(for: matchDate)),
           let userID = UserDefaults.standard.string(forKey: "appleUserID"),
           !userID.isEmpty {
            try? await CloudKitManager.shared.uploadMatchPhoto(
                data: data, matchDate: matchDate, userID: userID)
        }
        NotificationCenter.default.post(
            name: .matchPhotoUpdated,
            object: nil,
            userInfo: ["matchDate": matchDate]
        )
    }

    func applyReceivedPhoto(at sourceURL: URL, matchDate: Date, context: ModelContext?) {
        let dest = MatchPhotoStore.url(for: matchDate)
        try? FileManager.default.removeItem(at: dest)
        try? FileManager.default.copyItem(at: sourceURL, to: dest)
        if let context {
            markRecord(hasPhoto: true, matchDate: matchDate, context: context)
        }
        NotificationCenter.default.post(
            name: .matchPhotoUpdated,
            object: nil,
            userInfo: ["matchDate": matchDate]
        )
    }

    // MARK: - Cloud

    func refreshFromCloud(context: ModelContext) async {
        guard let userID = UserDefaults.standard.string(forKey: "appleUserID"),
              !userID.isEmpty else { return }
        guard let photos = try? await CloudKitManager.shared.fetchMatchPhotos(userID: userID)
        else { return }

        for item in photos {
            guard !MatchPhotoStore.exists(for: item.date) else { continue }
            guard MatchPhotoStore.save(data: item.data, matchDate: item.date) else { continue }
            markRecord(hasPhoto: true, matchDate: item.date, context: context)
        }
    }

    // MARK: - Watch

    func transferToCompanion(matchDate: Date) {
        guard WCSession.isSupported(),
              WCSession.default.activationState == .activated else { return }
        let url = MatchPhotoStore.url(for: matchDate)
        guard FileManager.default.fileExists(atPath: url.path) else { return }
        WCSession.default.transferFile(
            url,
            metadata: ["matchPhotoDate": matchDate.timeIntervalSince1970]
        )
    }

    // MARK: - Record

    private func markRecord(hasPhoto: Bool, matchDate: Date, context: ModelContext) {
        let target = matchDate
        let matches = (try? context.fetch(FetchDescriptor<MatchRecord>(
            predicate: #Predicate { $0.date == target }
        ))) ?? []
        guard let record = matches.first else { return }
        record.hasMatchPhoto = hasPhoto
        try? context.save()
    }
}

struct PhotoPromptItem: Identifiable {
    let matchDate: Date
    var id: TimeInterval { matchDate.timeIntervalSince1970 }
}

#if os(iOS)
/// Sezione foto ricordo nel dettaglio partita.
struct MatchPhotoSection: View {
    @Bindable var match: MatchRecord
    @Environment(\.modelContext) private var context

    @State private var showPrompt = false
    @State private var photo: UIImage? = nil

    private var hasPhoto: Bool {
        match.hasMatchPhoto || MatchPhotoStore.exists(for: match.date)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Foto ricordo", systemImage: "camera.fill")
                .font(.system(.subheadline, design: .rounded, weight: .heavy))
                .foregroundStyle(Theme.accent)

            if let photo {
                Image(uiImage: photo)
                    .resizable()
                    .scaledToFill()
                    .frame(maxWidth: .infinity)
                    .frame(height: 220)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
            } else if hasPhoto {
                RoundedRectangle(cornerRadius: 16)
                    .fill(Theme.surface)
                    .frame(height: 120)
                    .overlay(ProgressView())
            } else {
                Text("Una foto personale di fine partita, visibile solo nel tuo storico.")
                    .font(.system(.caption, design: .rounded))
                    .foregroundStyle(.secondary)
                Button {
                    showPrompt = true
                } label: {
                    Label("Aggiungi foto", systemImage: "plus.circle.fill")
                        .font(.system(.footnote, design: .rounded, weight: .bold))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(Theme.accent.opacity(0.10), in: RoundedRectangle(cornerRadius: 12))
                        .foregroundStyle(Theme.accent)
                }
                .buttonStyle(PressableStyle())
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .card()
        .task(id: match.date) { loadPhoto() }
        .onReceive(NotificationCenter.default.publisher(for: .matchPhotoUpdated)) { note in
            guard let date = note.userInfo?["matchDate"] as? Date,
                  abs(date.timeIntervalSince(match.date)) < 1 else { return }
            loadPhoto()
        }
        .sheet(isPresented: $showPrompt) {
            MatchPhotoPromptSheet(matchDate: match.date) {
                showPrompt = false
                loadPhoto()
            }
        }
    }

    private func loadPhoto() {
        photo = MatchPhotoStore.load(for: match.date)
        if photo != nil, !match.hasMatchPhoto {
            match.hasMatchPhoto = true
            try? context.save()
        }
    }
}
#endif
