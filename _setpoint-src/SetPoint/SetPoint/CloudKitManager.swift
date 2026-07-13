import Foundation
import CloudKit
import UIKit

struct PlayerProfile: Identifiable, Codable, Equatable {
    var id: String { appleUserID }
    let appleUserID: String
    let username: String
    let fullName: String
    var hasAvatar: Bool = false
}

/// Errori CloudKit tradotti per l'interfaccia.
enum CloudKitUserError: LocalizedError {
    case noAccount
    case restricted
    case unavailable
    case queryNotConfigured
    case unknown

    var errorDescription: String? {
        switch self {
        case .noAccount:
            return "Accedi a iCloud nelle Impostazioni del dispositivo per usare la ricerca giocatori."
        case .restricted:
            return "iCloud non è disponibile su questo dispositivo (account con restrizioni)."
        case .unavailable:
            return "iCloud temporaneamente non disponibile. Riprova tra poco."
        case .queryNotConfigured:
            return "CloudKit non è configurato per le ricerche: in CloudKit Console segna i campi username e searchName come Queryable, poi ridistribuisci lo schema."
        case .unknown:
            return "Impossibile verificare lo stato di iCloud."
        }
    }
}

/// Match live di un altro partecipante, letto dal database pubblico.
struct RemoteLiveMatch: Identifiable, Equatable {
    let creatorID: String
    let creatorName: String
    let score: LiveScore
    var id: String { creatorID }
}

/// Partita conclusa condivisa da un altro partecipante (da importare
/// nello storico locale ribaltando la prospettiva se ero avversario).
struct SharedMatchDownload {
    let recordName: String
    let creatorID: String
    let creatorName: String
    let partnerID: String
    let opponentID: String
    let opponent2ID: String
    let payload: MatchRecordPayload
}

@MainActor
final class CloudKitManager {
    static let shared = CloudKitManager()
    
    private let container = CKContainer(identifier: "iCloud.com.MarcelloGuida.SetPoint")
    private var publicDB: CKDatabase { container.publicCloudDatabase }
    private var privateDB: CKDatabase { container.privateCloudDatabase }
    private var avatarCache: [String: UIImage] = [:]
    
    private init() {}

    /// Nome normalizzato per ricerche case-insensitive (CloudKit non supporta [cd] nei predicati).
    static func normalizedSearchName(_ name: String) -> String {
        name.trimmingCharacters(in: .whitespacesAndNewlines)
            .lowercased()
            .folding(options: .diacriticInsensitive, locale: .current)
    }

    /// Verifica che l'utente sia loggato su iCloud prima di query o salvataggi cloud.
    func ensureCloudAvailable() async throws {
        let status = try await container.accountStatus()
        switch status {
        case .available: return
        case .noAccount: throw CloudKitUserError.noAccount
        case .restricted: throw CloudKitUserError.restricted
        case .temporarilyUnavailable: throw CloudKitUserError.unavailable
        case .couldNotDetermine: throw CloudKitUserError.unknown
        @unknown default: throw CloudKitUserError.unknown
        }
    }

    private func mapQueryError(_ error: Error) -> Error {
        guard let ck = error as? CKError, ck.code == .invalidArguments else { return error }
        let detail = ck.localizedDescription
        return NSError(
            domain: "SetPoint.CloudKit",
            code: ck.errorCode,
            userInfo: [NSLocalizedDescriptionKey:
                "Query CloudKit rifiutata. \(detail)\n\nIn CloudKit Console → Public Database → PlayerProfile: segna username e searchName come Queryable, poi Deploy Schema Changes nell'ambiente che stai usando (Development da Xcode, Production da TestFlight)."]
        )
    }

    private func profile(from record: CKRecord) -> PlayerProfile? {
        guard let username = record["username"] as? String,
              let fullName = record["fullName"] as? String,
              let appleUserID = record["appleUserID"] as? String
        else { return nil }
        return PlayerProfile(appleUserID: appleUserID,
                             username: username,
                             fullName: fullName,
                             hasAvatar: record["avatar"] != nil)
    }

    private func queryPlayerProfiles(predicate: NSPredicate, limit: Int = 10) async throws -> [PlayerProfile] {
        let query = CKQuery(recordType: "PlayerProfile", predicate: predicate)
        do {
            let (results, _) = try await publicDB.records(matching: query, resultsLimit: limit)
            return results.compactMap { _, result in
                guard let record = try? result.get() else { return nil }
                return profile(from: record)
            }
        } catch let error as CKError where error.code == .unknownItem {
            return []
        } catch {
            throw mapQueryError(error)
        }
    }

    func cachedAvatar(for appleUserID: String) -> UIImage? {
        avatarCache[appleUserID]
    }

    func cacheAvatar(_ image: UIImage, for appleUserID: String) {
        avatarCache[appleUserID] = image
    }

    func clearAvatarCache(for appleUserID: String) {
        avatarCache.removeValue(forKey: appleUserID)
    }
    
    /// Recupera il profilo utente associato al suo Apple User ID.
    func fetchProfile(appleUserID: String) async throws -> PlayerProfile? {
        guard !appleUserID.isEmpty else { return nil }
        let recordID = CKRecord.ID(recordName: appleUserID)
        do {
            let record = try await publicDB.record(for: recordID)
            guard let username = record["username"] as? String,
                  let fullName = record["fullName"] as? String else {
                return nil
            }
            return PlayerProfile(appleUserID: appleUserID,
                                 username: username,
                                 fullName: fullName,
                                 hasAvatar: record["avatar"] != nil)
        } catch {
            // Se il record non esiste, non consideriamo l'errore bloccante ma restituiamo nil
            if let ckError = error as? CKError, ckError.code == .unknownItem {
                return nil
            }
            throw error
        }
    }
    
    /// Genera un username base univoco (es. utente482917).
    func generateUniqueUsername(excludingAppleUserID: String) async throws -> String {
        for _ in 0..<20 {
            let number = Int.random(in: 100_000...999_999)
            let candidate = "utente\(number)"
            let taken = try await isUsernameTaken(candidate, excludingAppleUserID: excludingAppleUserID)
            if !taken { return candidate }
        }
        let suffix = UUID().uuidString.prefix(8).lowercased()
        return "utente\(suffix)"
    }

    /// Nomi generici da non usare mai come username.
    private static let blockedUsernameSlugs: Set<String> = [
        "giocatore", "utente", "player", "user", "apple", "test"
    ]

    /// Slug dal nome Apple (es. "Marcello Guida" → "marcello").
    private func usernameSlug(from fullName: String) -> String? {
        let parts = fullName.trimmingCharacters(in: .whitespacesAndNewlines)
            .lowercased()
            .folding(options: .diacriticInsensitive, locale: .current)
            .split(whereSeparator: { !$0.isLetter && !$0.isNumber })
            .map(String.init)
        guard let first = parts.first, first.count >= 3 else { return nil }
        let slug = String(first.prefix(20))
        let allowed = CharacterSet.alphanumerics
        guard slug.unicodeScalars.allSatisfy({ allowed.contains($0) }),
              !Self.blockedUsernameSlugs.contains(slug)
        else { return nil }
        return slug
    }

    /// Slug dall'email Apple (es. "marcello@icloud.com" → "marcello").
    private func usernameSlug(fromEmail email: String) -> String? {
        let local = email.split(separator: "@").first.map(String.init) ?? ""
        let slug = local.lowercased()
            .folding(options: .diacriticInsensitive, locale: .current)
            .filter { $0.isLetter || $0.isNumber }
        guard slug.count >= 3, !Self.blockedUsernameSlugs.contains(slug) else { return nil }
        return String(slug.prefix(20))
    }

    /// Fallback stabile legato all'Apple ID (es. "sp_a1b2c3d4").
    private func usernameFromAppleID(_ appleUserID: String) -> String {
        let suffix = appleUserID
            .filter { $0.isLetter || $0.isNumber }
            .suffix(8)
            .lowercased()
        return "sp_\(suffix)"
    }

    /// Username assegnato automaticamente all'accesso con Apple: deriva dal
    /// nome o dall'email quando possibile, altrimenti fallback stabile.
    func assignUsername(appleUserID: String, fullName: String, email: String? = nil) async throws -> String {
        let candidates: [String?] = [
            usernameSlug(from: fullName),
            email.flatMap { usernameSlug(fromEmail: $0) }
        ]
        for base in candidates.compactMap({ $0 }) {
            if try await !isUsernameTaken(base, excludingAppleUserID: appleUserID) {
                return base
            }
            for suffix in 2...99 {
                let candidate = "\(base)\(suffix)"
                if try await !isUsernameTaken(candidate, excludingAppleUserID: appleUserID) {
                    return candidate
                }
            }
        }
        let stable = usernameFromAppleID(appleUserID)
        if try await !isUsernameTaken(stable, excludingAppleUserID: appleUserID) {
            return stable
        }
        return try await generateUniqueUsername(excludingAppleUserID: appleUserID)
    }

    /// Nome visualizzato valido (mai il placeholder generico).
    static func resolvedDisplayName(_ fullName: String) -> String {
        let trimmed = fullName.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty || trimmed.lowercased() == "giocatore" ? "" : trimmed
    }

    /// Crea il profilo cloud al primo Sign in with Apple: username automatico
    /// (dal nome Apple o email se possibile).
    func setupInitialProfile(appleUserID: String, fullName: String, email: String? = nil) async throws -> PlayerProfile {
        let resolved = Self.resolvedDisplayName(fullName)
        let effectiveName = resolved.isEmpty ? "Giocatore" : resolved
        let username = try await assignUsername(appleUserID: appleUserID,
                                                fullName: resolved,
                                                email: email)
        try await saveProfile(appleUserID: appleUserID, username: username, fullName: effectiveName)

        return PlayerProfile(appleUserID: appleUserID,
                             username: username,
                             fullName: effectiveName,
                             hasAvatar: false)
    }

    /// Corregge profili creati senza nome Apple (es. @giocatore).
    func repairProfileIfNeeded(appleUserID: String,
                               preferredName: String,
                               email: String?,
                               currentUsername: String,
                               currentFullName: String) async throws -> PlayerProfile? {
        let name = Self.resolvedDisplayName(preferredName)
        guard !name.isEmpty else { return nil }

        let needsUsernameFix = Self.blockedUsernameSlugs.contains(currentUsername.lowercased())
            || currentUsername.hasPrefix("utente")
        let needsNameFix = currentFullName.trimmingCharacters(in: .whitespaces).lowercased() == "giocatore"
            || currentFullName.isEmpty
        guard needsUsernameFix || needsNameFix else { return nil }

        let newUsername: String
        if needsUsernameFix {
            newUsername = try await assignUsername(appleUserID: appleUserID, fullName: name, email: email)
        } else {
            newUsername = currentUsername
        }

        try await saveProfile(appleUserID: appleUserID, username: newUsername, fullName: name)
        var hasAvatar = false
        if let record = try? await publicDB.record(for: CKRecord.ID(recordName: appleUserID)) {
            hasAvatar = record["avatar"] != nil
        }
        return PlayerProfile(appleUserID: appleUserID,
                             username: newUsername,
                             fullName: name,
                             hasAvatar: hasAvatar)
    }

    /// Salva o aggiorna il profilo utente.
    func saveProfile(appleUserID: String, username: String, fullName: String) async throws {
        guard !appleUserID.isEmpty, !username.isEmpty, !fullName.isEmpty else { return }
        
        let recordID = CKRecord.ID(recordName: appleUserID)
        let record: CKRecord
        
        do {
            record = try await publicDB.record(for: recordID)
        } catch {
            record = CKRecord(recordType: "PlayerProfile", recordID: recordID)
        }
        
        // Pulizia username (sempre minuscolo)
        let cleanUsername = username.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        
        record["username"] = cleanUsername as CKRecordValue
        record["fullName"] = fullName as CKRecordValue
        record["searchName"] = Self.normalizedSearchName(fullName) as CKRecordValue
        record["appleUserID"] = appleUserID as CKRecordValue

        try await ensureCloudAvailable()
        try await publicDB.save(record)
    }

    /// Salva o aggiorna la foto profilo su CloudKit.
    func saveAvatar(appleUserID: String, imageData: Data) async throws {
        guard !appleUserID.isEmpty else { return }

        let recordID = CKRecord.ID(recordName: appleUserID)
        let record: CKRecord
        do {
            record = try await publicDB.record(for: recordID)
        } catch {
            record = CKRecord(recordType: "PlayerProfile", recordID: recordID)
            record["appleUserID"] = appleUserID as CKRecordValue
        }

        let tempURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("avatar-\(appleUserID).jpg")
        try imageData.write(to: tempURL, options: .atomic)
        record["avatar"] = CKAsset(fileURL: tempURL)
        try await publicDB.save(record)
        try? FileManager.default.removeItem(at: tempURL)

        if let image = UIImage(data: imageData) {
            cacheAvatar(image, for: appleUserID)
        }
    }

    /// Scarica la foto profilo da CloudKit (con cache in memoria).
    func fetchAvatar(appleUserID: String) async -> UIImage? {
        guard !appleUserID.isEmpty else { return nil }
        if let cached = cachedAvatar(for: appleUserID) { return cached }

        do {
            let record = try await publicDB.record(for: CKRecord.ID(recordName: appleUserID))
            guard let asset = record["avatar"] as? CKAsset,
                  let url = asset.fileURL,
                  let data = try? Data(contentsOf: url),
                  let image = UIImage(data: data)
            else { return nil }
            cacheAvatar(image, for: appleUserID)
            return image
        } catch {
            return nil
        }
    }
    
    /// Verifica se un nome utente è già in uso da parte di un altro utente.
    func isUsernameTaken(_ username: String, excludingAppleUserID: String) async throws -> Bool {
        let cleanUsername = username.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        let matches = try await queryPlayerProfiles(
            predicate: NSPredicate(format: "username == %@", cleanUsername),
            limit: 1
        )
        guard let existing = matches.first else { return false }
        return existing.appleUserID != excludingAppleUserID
    }

    /// Aggiorna searchName sui profili già salvati (migrazione leggera).
    func backfillSearchNameIfNeeded(appleUserID: String, fullName: String) async {
        guard !appleUserID.isEmpty else { return }
        let target = Self.normalizedSearchName(fullName)
        guard !target.isEmpty else { return }
        do {
            let record = try await publicDB.record(for: CKRecord.ID(recordName: appleUserID))
            let current = record["searchName"] as? String ?? ""
            guard current != target else { return }
            record["searchName"] = target as CKRecordValue
            try await publicDB.save(record)
        } catch {
            // Migrazione best-effort: non blocca l'app.
        }
    }
    
    /// Elimina il profilo pubblico (rimuovi nome utente / elimina account).
    func deleteProfile(appleUserID: String) async throws {
        guard !appleUserID.isEmpty else { return }
        do {
            try await publicDB.deleteRecord(withID: CKRecord.ID(recordName: appleUserID))
        } catch let error as CKError where error.code == .unknownItem {
            // Mai salvato: già "eliminato".
        }
    }

    // MARK: - Match live condiviso

    /// Pubblica (o sovrascrive) lo stato live del match: un solo record
    /// per creatore, l'ultimo stato vince.
    func publishLive(score: LiveScore, creatorID: String, creatorName: String,
                     participantIDs: [String]) async throws {
        let record = CKRecord(recordType: "LiveMatch",
                              recordID: CKRecord.ID(recordName: "live-\(creatorID)"))
        record["creatorID"] = creatorID as CKRecordValue
        record["creatorName"] = creatorName as CKRecordValue
        record["participantIDs"] = participantIDs as CKRecordValue
        record["payload"] = try JSONEncoder().encode(score) as CKRecordValue
        record["updatedAt"] = score.updatedAt as CKRecordValue
        _ = try await publicDB.modifyRecords(saving: [record], deleting: [],
                                             savePolicy: .allKeys)
    }

    /// Rimuove il match live a fine partita.
    func deleteLive(creatorID: String) async {
        _ = try? await publicDB.deleteRecord(withID: CKRecord.ID(recordName: "live-\(creatorID)"))
    }

    /// Match live in corso in cui compare l'utente (esclusi i propri,
    /// filtrati dal chiamante). Ignora record fermi da ore.
    func fetchLiveMatches(participantID: String) async throws -> [RemoteLiveMatch] {
        let predicate = NSPredicate(format: "participantIDs CONTAINS %@", participantID)
        let query = CKQuery(recordType: "LiveMatch", predicate: predicate)
        let results: [(CKRecord.ID, Result<CKRecord, Error>)]
        do {
            (results, _) = try await publicDB.records(matching: query, resultsLimit: 20)
        } catch let error as CKError where error.code == .unknownItem || error.code == .invalidArguments {
            return []   // schema non ancora creato
        }
        return results.compactMap { _, result in
            guard let record = try? result.get(),
                  let creatorID = record["creatorID"] as? String,
                  let data = record["payload"] as? Data,
                  let score = try? JSONDecoder().decode(LiveScore.self, from: data),
                  score.updatedAt.timeIntervalSinceNow > -6 * 3600
            else { return nil }
            return RemoteLiveMatch(creatorID: creatorID,
                                   creatorName: record["creatorName"] as? String ?? "Giocatore",
                                   score: score)
        }
        .sorted { $0.score.updatedAt > $1.score.updatedAt }
    }

    // MARK: - Partite concluse condivise

    /// Pubblica la partita archiviata sui profili collegati; il nome record
    /// è deterministico (creatore + inizio partita), quindi ripubblicare
    /// lo stesso match è innocuo. Ritorna il recordName.
    func publishSharedMatch(payload: MatchRecordPayload, creatorID: String,
                            creatorName: String, meta: MatchMeta) async throws -> String {
        let recordName = "match-\(creatorID)-\(Int(payload.date.timeIntervalSince1970))"
        let record = CKRecord(recordType: "SharedMatch",
                              recordID: CKRecord.ID(recordName: recordName))
        record["creatorID"] = creatorID as CKRecordValue
        record["creatorName"] = creatorName as CKRecordValue
        record["participantIDs"] = ([creatorID] + meta.links.map(\.userID)) as CKRecordValue
        record["partnerID"] = (meta.partnerLink?.userID ?? "") as CKRecordValue
        record["opponentID"] = (meta.opponentLink?.userID ?? "") as CKRecordValue
        record["opponent2ID"] = (meta.opponent2Link?.userID ?? "") as CKRecordValue
        record["payload"] = try JSONEncoder().encode(payload) as CKRecordValue
        record["date"] = payload.date as CKRecordValue
        _ = try await publicDB.modifyRecords(saving: [record], deleting: [],
                                             savePolicy: .allKeys)
        return recordName
    }

    /// Partite condivise in cui compare l'utente.
    func fetchSharedMatches(participantID: String) async throws -> [SharedMatchDownload] {
        let predicate = NSPredicate(format: "participantIDs CONTAINS %@", participantID)
        let query = CKQuery(recordType: "SharedMatch", predicate: predicate)
        let results: [(CKRecord.ID, Result<CKRecord, Error>)]
        do {
            (results, _) = try await publicDB.records(matching: query, resultsLimit: 100)
        } catch let error as CKError where error.code == .unknownItem || error.code == .invalidArguments {
            return []   // schema non ancora creato
        }
        return results.compactMap { id, result in
            guard let record = try? result.get(),
                  let creatorID = record["creatorID"] as? String,
                  let data = record["payload"] as? Data,
                  let payload = try? JSONDecoder().decode(MatchRecordPayload.self, from: data)
            else { return nil }
            return SharedMatchDownload(
                recordName: id.recordName,
                creatorID: creatorID,
                creatorName: record["creatorName"] as? String ?? "Giocatore",
                partnerID: record["partnerID"] as? String ?? "",
                opponentID: record["opponentID"] as? String ?? "",
                opponent2ID: record["opponent2ID"] as? String ?? "",
                payload: payload)
        }
    }

    /// Cerca i giocatori il cui username o nome completo inizia con la query.
    /// CloudKit non supporta i modificatori [cd] nei predicati: usiamo
    /// username (minuscolo) e searchName (nome normalizzato) con query separate.
    func searchPlayers(queryText: String) async throws -> [PlayerProfile] {
        let cleanQuery = queryText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard cleanQuery.count >= 2 else { return [] }

        try await ensureCloudAvailable()

        let cleanQueryLower = cleanQuery.lowercased()
        var seen = Set<String>()
        var profiles: [PlayerProfile] = []

        func appendUnique(_ batch: [PlayerProfile]) {
            for profile in batch where seen.insert(profile.appleUserID).inserted {
                profiles.append(profile)
            }
        }

        appendUnique(try await queryPlayerProfiles(
            predicate: NSPredicate(format: "username BEGINSWITH %@", cleanQueryLower)
        ))

        do {
            appendUnique(try await queryPlayerProfiles(
                predicate: NSPredicate(format: "searchName BEGINSWITH %@", cleanQueryLower)
            ))
        } catch let error as CKError where error.code == .invalidArguments {
            // searchName non ancora indicizzato: la ricerca per username resta valida.
        }

        return profiles
    }

    // MARK: - Inviti partita

    private func inviteResponseRecordName(sessionID: String, inviteeID: String) -> String {
        "invite-response-\(sessionID)-\(inviteeID)"
    }

    private func fetchInviteResponse(sessionID: String, inviteeID: String) async -> MatchInviteStatus? {
        let recordName = inviteResponseRecordName(sessionID: sessionID, inviteeID: inviteeID)
        guard let record = try? await publicDB.record(for: CKRecord.ID(recordName: recordName)),
              let statusRaw = record["status"] as? String,
              let status = MatchInviteStatus(rawValue: statusRaw)
        else { return nil }
        return status
    }

    private func mergeInviteResponses(_ invites: [MatchInvite]) async -> [MatchInvite] {
        var merged = invites
        for index in merged.indices {
            guard merged[index].status == .pending else { continue }
            if let status = await fetchInviteResponse(
                sessionID: merged[index].sessionID,
                inviteeID: merged[index].inviteeID
            ) {
                merged[index].status = status
            }
        }
        return merged
    }

    private func invite(from record: CKRecord) -> MatchInvite? {
        guard let sessionID = record["sessionID"] as? String,
              let creatorID = record["creatorID"] as? String,
              let creatorName = record["creatorName"] as? String,
              let inviteeID = record["inviteeID"] as? String,
              let inviteeName = record["inviteeName"] as? String,
              let statusRaw = record["status"] as? String,
              let status = MatchInviteStatus(rawValue: statusRaw),
              let configData = record["configPayload"] as? Data,
              let metaData = record["metaPayload"] as? Data,
              let config = try? JSONDecoder().decode(MatchConfig.self, from: configData),
              let meta = try? JSONDecoder().decode(MatchMeta.self, from: metaData)
        else { return nil }
        let createdAt = record["createdAt"] as? Date ?? Date()
        return MatchInvite(
            recordName: record.recordID.recordName,
            sessionID: sessionID,
            creatorID: creatorID,
            creatorName: creatorName,
            inviteeID: inviteeID,
            inviteeName: inviteeName,
            status: status,
            config: config,
            meta: meta,
            createdAt: createdAt
        )
    }

    private func queryInvites(predicate: NSPredicate, limit: Int = 20) async throws -> [MatchInvite] {
        let query = CKQuery(recordType: "MatchInvite", predicate: predicate)
        do {
            let (results, _) = try await publicDB.records(matching: query, resultsLimit: limit)
            return results.compactMap { _, result in
                guard let record = try? result.get() else { return nil }
                return invite(from: record)
            }
        } catch let error as CKError where error.code == .unknownItem || error.code == .invalidArguments {
            return []
        } catch {
            throw mapQueryError(error)
        }
    }

    /// Pubblica un invito per ogni giocatore collegato alla partita.
    func publishMatchInvites(sessionID: String,
                             creatorID: String,
                             creatorName: String,
                             config: MatchConfig,
                             meta: MatchMeta) async throws {
        try await ensureCloudAvailable()
        let configData = try JSONEncoder().encode(config)
        let metaData = try JSONEncoder().encode(meta)
        let now = Date()

        var records: [CKRecord] = []
        for link in meta.links {
            let recordName = "invite-\(sessionID)-\(link.userID)"
            let record = CKRecord(recordType: "MatchInvite",
                                  recordID: CKRecord.ID(recordName: recordName))
            record["sessionID"] = sessionID as CKRecordValue
            record["creatorID"] = creatorID as CKRecordValue
            record["creatorName"] = creatorName as CKRecordValue
            record["inviteeID"] = link.userID as CKRecordValue
            record["inviteeName"] = link.fullName as CKRecordValue
            record["status"] = MatchInviteStatus.pending.rawValue as CKRecordValue
            record["configPayload"] = configData as CKRecordValue
            record["metaPayload"] = metaData as CKRecordValue
            record["createdAt"] = now as CKRecordValue
            record["updatedAt"] = now as CKRecordValue
            records.append(record)
        }

        _ = try await publicDB.modifyRecords(saving: records, deleting: [],
                                             savePolicy: .allKeys)
        let recordNames = records.map(\.recordID.recordName)
        UserDefaults.standard.set(recordNames, forKey: inviteRecordsKey(for: sessionID))
    }

    func fetchPendingInvites(for inviteeID: String) async throws -> [MatchInvite] {
        guard !inviteeID.isEmpty else { return [] }
        let predicate = NSPredicate(
            format: "inviteeID == %@ AND status == %@",
            inviteeID, MatchInviteStatus.pending.rawValue
        )
        let invites = try await queryInvites(predicate: predicate)
        let merged = await mergeInviteResponses(invites)
        let pending = merged.filter { $0.status == .pending }
        let deduped = Dictionary(grouping: pending, by: \.creatorID)
            .values
            .compactMap { $0.max(by: { $0.createdAt < $1.createdAt }) }
        return deduped
            .sorted { $0.createdAt > $1.createdAt }
    }

    private func inviteRecordsKey(for sessionID: String) -> String {
        "inviteRecordNames-\(sessionID)"
    }

    func fetchInvite(recordName: String) async throws -> MatchInvite? {
        guard let record = try? await publicDB.record(for: CKRecord.ID(recordName: recordName)),
              var invite = invite(from: record) else { return nil }
        if invite.status == .pending,
           let status = await fetchInviteResponse(
               sessionID: invite.sessionID,
               inviteeID: invite.inviteeID
           ) {
            invite.status = status
        }
        return invite
    }

    func fetchInvites(recordNames: [String]) async throws -> [MatchInvite] {
        var invites: [MatchInvite] = []
        for recordName in recordNames {
            guard let record = try? await publicDB.record(for: CKRecord.ID(recordName: recordName)),
                  let invite = invite(from: record) else { continue }
            invites.append(invite)
        }
        return await mergeInviteResponses(invites)
    }

    func fetchInvites(sessionID: String) async throws -> [MatchInvite] {
        let key = inviteRecordsKey(for: sessionID)
        if let recordNames = UserDefaults.standard.stringArray(forKey: key), !recordNames.isEmpty {
            return try await fetchInvites(recordNames: recordNames)
        }
        let predicate = NSPredicate(format: "sessionID == %@", sessionID)
        let invites = try await queryInvites(predicate: predicate, limit: 10)
        return await mergeInviteResponses(invites)
    }

    /// L'invitato non può modificare il record creato dal mittente nel DB pubblico:
    /// salva una risposta su un record di sua proprietà.
    func respondToInvite(_ invite: MatchInvite,
                         status: MatchInviteStatus,
                         inviteeID: String) async throws {
        try await ensureCloudAvailable()
        let recordName = inviteResponseRecordName(sessionID: invite.sessionID, inviteeID: inviteeID)
        let recordID = CKRecord.ID(recordName: recordName)

        let record: CKRecord
        if let existing = try? await publicDB.record(for: recordID) {
            record = existing
        } else {
            record = CKRecord(recordType: "MatchInviteResponse", recordID: recordID)
            record["sessionID"] = invite.sessionID as CKRecordValue
            record["inviteRecordName"] = invite.recordName as CKRecordValue
            record["inviteeID"] = inviteeID as CKRecordValue
        }
        record["status"] = status.rawValue as CKRecordValue
        record["updatedAt"] = Date() as CKRecordValue
        try await publicDB.save(record)
    }

    func updateInviteStatus(recordName: String, status: MatchInviteStatus) async throws {
        let record = try await publicDB.record(for: CKRecord.ID(recordName: recordName))
        record["status"] = status.rawValue as CKRecordValue
        record["updatedAt"] = Date() as CKRecordValue
        try await publicDB.save(record)
    }

    func clearInviteSessionCache(sessionID: String) {
        UserDefaults.standard.removeObject(forKey: inviteRecordsKey(for: sessionID))
    }

    /// Annulla inviti pendenti precedenti dello stesso creatore.
    func cancelPendingInvites(from creatorID: String,
                              exceptSessionID: String? = nil) async throws {
        let predicate = NSPredicate(
            format: "creatorID == %@ AND status == %@",
            creatorID, MatchInviteStatus.pending.rawValue
        )
        let invites = try await queryInvites(predicate: predicate, limit: 50)
        for invite in invites where invite.sessionID != exceptSessionID {
            try? await updateInviteStatus(recordName: invite.recordName, status: .cancelled)
        }
    }

    func cancelMatchSession(sessionID: String) async throws {
        let invites = try await fetchInvites(sessionID: sessionID)
        for invite in invites where invite.status == .pending || invite.status == .accepted {
            try await updateInviteStatus(recordName: invite.recordName, status: .cancelled)
        }
    }

    func markSessionStarted(sessionID: String) async throws {
        let invites = try await fetchInvites(sessionID: sessionID)
        for invite in invites where invite.status == .accepted {
            try await updateInviteStatus(recordName: invite.recordName, status: .started)
        }
    }

    // MARK: - Backup partite (database privato, sync tra i dispositivi dell'utente)

    /// Salva la partita nell'archivio personale dell'account: un record per
    /// partita con nome deterministico (utente + inizio partita), quindi
    /// ripubblicare lo stesso match è innocuo.
    func saveUserMatch(payload: MatchRecordPayload, userID: String) async throws {
        let recordName = "usermatch-\(userID)-\(Int(payload.date.timeIntervalSince1970))"
        let record = CKRecord(recordType: "UserMatch",
                              recordID: CKRecord.ID(recordName: recordName))
        record["userID"] = userID as CKRecordValue
        record["date"] = payload.date as CKRecordValue
        record["payload"] = try JSONEncoder().encode(payload) as CKRecordValue
        record["updatedAt"] = Date() as CKRecordValue
        _ = try await privateDB.modifyRecords(saving: [record], deleting: [],
                                              savePolicy: .allKeys)
    }

    /// Scarica tutte le partite archiviate sull'account (paginato).
    func fetchUserMatches(userID: String) async throws -> [MatchRecordPayload] {
        let predicate = NSPredicate(format: "userID == %@", userID)
        let query = CKQuery(recordType: "UserMatch", predicate: predicate)
        var payloads: [MatchRecordPayload] = []

        func append(_ results: [(CKRecord.ID, Result<CKRecord, Error>)]) {
            for (_, result) in results {
                guard let record = try? result.get(),
                      let data = record["payload"] as? Data,
                      let payload = try? JSONDecoder().decode(MatchRecordPayload.self, from: data)
                else { continue }
                payloads.append(payload)
            }
        }

        do {
            var (results, cursor) = try await privateDB.records(matching: query,
                                                                resultsLimit: 200)
            append(results)
            while let next = cursor {
                (results, cursor) = try await privateDB.records(continuingMatchFrom: next)
                append(results)
            }
        } catch let error as CKError where error.code == .unknownItem || error.code == .invalidArguments {
            return []   // schema non ancora creato
        }
        return payloads
    }

    /// Rimuove la partita dall'archivio dell'account (eliminazione dallo storico).
    func deleteUserMatch(userID: String, matchDate: Date) async {
        let recordName = "usermatch-\(userID)-\(Int(matchDate.timeIntervalSince1970))"
        _ = try? await privateDB.deleteRecord(withID: CKRecord.ID(recordName: recordName))
    }

    // MARK: - Foto ricordo (database privato, sync tra i dispositivi dell'utente)

    struct DownloadedMatchPhoto {
        let date: Date
        let data: Data
    }

    func uploadMatchPhoto(data: Data, matchDate: Date, userID: String) async throws {
        let recordName = "photo-\(userID)-\(Int(matchDate.timeIntervalSince1970))"
        let tempURL = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString)
            .appendingPathExtension("jpg")
        try data.write(to: tempURL, options: .atomic)
        defer { try? FileManager.default.removeItem(at: tempURL) }

        let record = CKRecord(recordType: "UserMatchPhoto",
                              recordID: CKRecord.ID(recordName: recordName))
        record["userID"] = userID as CKRecordValue
        record["matchDate"] = matchDate as CKRecordValue
        record["photo"] = CKAsset(fileURL: tempURL)
        try await privateDB.save(record)
    }

    func fetchMatchPhotos(userID: String) async throws -> [DownloadedMatchPhoto] {
        let predicate = NSPredicate(format: "userID == %@", userID)
        let query = CKQuery(recordType: "UserMatchPhoto", predicate: predicate)
        let (results, _) = try await privateDB.records(matching: query, resultsLimit: 200)
        return results.compactMap { _, result in
            guard let record = try? result.get(),
                  let date = record["matchDate"] as? Date,
                  let asset = record["photo"] as? CKAsset,
                  let url = asset.fileURL,
                  let data = try? Data(contentsOf: url)
            else { return nil }
            return DownloadedMatchPhoto(date: date, data: data)
        }
    }
}
