import SwiftUI
import SwiftData
import AuthenticationServices
import PhotosUI
import UIKit

/// Nome dell'utente mostrato su card, cloud e profilo.
/// Registrato → nome Apple; ospite → nome inserito manualmente.
enum UserName {
    static var current: String {
        let appleUserID = UserDefaults.standard.string(forKey: "appleUserID") ?? ""
        if !appleUserID.isEmpty {
            return (UserDefaults.standard.string(forKey: "appleUserName") ?? "")
                .trimmingCharacters(in: .whitespacesAndNewlines)
        }
        return (UserDefaults.standard.string(forKey: "displayName") ?? "")
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }
}

/// Profilo utente: riepilogo stagione + Sign in with Apple (base per
/// ricerca per nome utente e sincronizzazione cloud).
struct ProfileScreen: View {
    @AppStorage("appleUserID") private var appleUserID = ""
    @AppStorage("appleUserName") private var appleUserName = ""
    @AppStorage("appleUserEmail") private var appleUserEmail = ""
    @AppStorage("displayName") private var displayName = ""
    @Query private var matches: [MatchRecord]
    @Environment(\.modelContext) private var modelContext

    private var competitive: [MatchRecord] { matches.filter { !$0.isSpectator } }

    private let sync = WatchSync.shared

    @State private var username = ""
    @State private var savingProfile = false
    @State private var profileError: String? = nil
    @State private var infoMessage: String? = nil
    @State private var showDeleteAccount = false
    @State private var avatarItem: PhotosPickerItem? = nil
    @State private var uploadingAvatar = false
    @State private var avatarRefreshToken = UUID()
    @State private var usernameCopied = false
    @State private var showNamePrompt = false
    @State private var pendingName = ""
    @State private var needsAvatarHint = false

    private var trimmedUsername: String {
        username.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    /// Nome inserito come ospite, riusato se Apple non restituisce fullName.
    private var resolvedGuestName: String {
        CloudKitManager.resolvedDisplayName(displayName)
    }

    private var shareUsernameText: String {
        "Aggiungimi su SetPoint: @\(trimmedUsername)"
    }

    private var wins: Int { competitive.filter(\.won).count }
    private var winRate: Int {
        competitive.isEmpty ? 0 : wins * 100 / competitive.count
    }
    private var courtTime: TimeInterval {
        competitive.reduce(0) { $0 + $1.duration }
    }

    /// Nome mostrato nell'header.
    private var shownName: String {
        if !appleUserID.isEmpty {
            return appleUserName.trimmingCharacters(in: .whitespacesAndNewlines)
        }
        return displayName.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    /// Nome effettivo su tabellone, card e cloud.
    private var effectiveName: String {
        let name = shownName.trimmingCharacters(in: .whitespacesAndNewlines)
        return name.isEmpty ? "Giocatore" : name
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    hero

                    if !appleUserID.isEmpty, !trimmedUsername.isEmpty {
                        usernameShareCard
                    }

                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())],
                              spacing: 10) {
                        StatTile(value: "\(competitive.count)", label: "Partite",
                                 icon: "figure.tennis")
                        StatTile(value: "\(wins)", label: "Vittorie",
                                 tint: Theme.win, icon: "trophy.fill")
                        StatTile(value: "\(winRate)%", label: "Win rate",
                                 tint: winRate >= 50 ? Theme.win : Theme.loss,
                                 icon: "percent")
                        StatTile(value: LiveScreen.format(courtTime),
                                 label: "In campo", icon: "stopwatch.fill")
                    }

                    if appleUserID.isEmpty {
                        guestNameCard
                    }

                    appleWatchCard

                    prenotazioneComingSoonCard

                    if appleUserID.isEmpty {
                        VStack(spacing: 12) {
                            SignInWithAppleButton(.signIn) { request in
                                request.requestedScopes = [.fullName]
                            } onCompletion: { result in
                                if case .success(let auth) = result,
                                   let credential = auth.credential as? ASAuthorizationAppleIDCredential {
                                    appleUserID = credential.user
                                    // Ripristina subito lo storico salvato sull'account.
                                    Task { await CloudSync.shared.syncPersonal(context: modelContext) }
                                    if let email = credential.email, !email.isEmpty {
                                        appleUserEmail = email
                                    }
                                    let name = [credential.fullName?.givenName,
                                                credential.fullName?.familyName]
                                        .compactMap { $0 }
                                        .joined(separator: " ")
                                    if !name.isEmpty {
                                        appleUserName = name
                                        Task { await loadProfile() }
                                    } else if !resolvedGuestName.isEmpty {
                                        appleUserName = resolvedGuestName
                                        Task { await loadProfile() }
                                    } else {
                                        pendingName = ""
                                        showNamePrompt = true
                                    }
                                }
                            }
                            .frame(height: 50)
                            .clipShape(RoundedRectangle(cornerRadius: 14))

                            Text("Accedi con Apple per ottenere un profilo univoco: gli altri giocatori potranno trovarti e collegarti alle partite.")
                                .font(.system(.footnote, design: .rounded))
                                .foregroundStyle(.secondary)
                                .multilineTextAlignment(.center)
                        }
                        .padding(16)
                        .card()
                    } else {
                        VStack(spacing: 0) {
                            HStack {
                                Text("Account")
                                    .font(.system(.subheadline, design: .rounded, weight: .semibold))
                                    .foregroundStyle(.secondary)
                                Spacer()
                                Text(appleUserName.isEmpty ? "Utente Apple" : appleUserName)
                                    .font(.system(.subheadline, design: .rounded, weight: .bold))
                            }
                            .padding(16)

                            if let error = profileError {
                                Divider().padding(.leading, 16)
                                Label(error, systemImage: "exclamationmark.triangle.fill")
                                    .font(.system(.caption2, design: .rounded))
                                    .foregroundStyle(Theme.loss)
                                    .padding(16)
                            } else if let info = infoMessage {
                                Divider().padding(.leading, 16)
                                Label(info, systemImage: "checkmark.circle.fill")
                                    .font(.system(.caption2, design: .rounded))
                                    .foregroundStyle(Theme.win)
                                    .padding(16)
                            }

                            Divider().padding(.leading, 16)

                            Button(role: .destructive) {
                                CloudKitManager.shared.clearAvatarCache(for: appleUserID)
                                appleUserID = ""
                                appleUserName = ""
                                username = ""
                                profileError = nil
                                infoMessage = nil
                            } label: {
                                Text("Esci")
                                    .font(.system(.subheadline, design: .rounded, weight: .bold))
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .padding(16)
                            }
                        }
                        .card()
                    }

                    if !appleUserID.isEmpty {
                        deleteAccountCard
                    }
                }
                .padding()
            }
            .background(Theme.background)
            .task {
                await loadProfile()
            }
            .navigationTitle("Profilo")
            .sheet(isPresented: $showNamePrompt) {
                namePromptSheet
            }
        }
    }

    /// Apple spesso non restituisce il nome al secondo accesso: chiediamolo una volta.
    private var namePromptSheet: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 20) {
                Text("Come ti chiami in campo?")
                    .font(.system(.title3, design: .rounded, weight: .heavy))
                Text("Apple condivide il nome solo al primo accesso. Inseriscilo qui: serve per il tabellone e per il tuo username.")
                    .font(.system(.subheadline, design: .rounded))
                    .foregroundStyle(.secondary)

                TextField("es. Marcello", text: $pendingName)
                    .textFieldStyle(.roundedBorder)
                    .font(.system(.body, design: .rounded))
                    .textInputAutocapitalization(.words)
                    .autocorrectionDisabled()

                Spacer()
            }
            .padding()
            .navigationTitle("Il tuo nome")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Continua") {
                        let trimmed = pendingName.trimmingCharacters(in: .whitespacesAndNewlines)
                        guard trimmed.count >= 2 else { return }
                        appleUserName = trimmed
                        showNamePrompt = false
                        Task { await loadProfile() }
                    }
                    .disabled(pendingName.trimmingCharacters(in: .whitespacesAndNewlines).count < 2)
                }
            }
            .interactiveDismissDisabled()
        }
        .presentationDetents([.medium])
    }

    private var hero: some View {
        VStack(spacing: 12) {
            ZStack(alignment: .bottomTrailing) {
                ZStack {
                    Circle()
                        .fill(.white.opacity(0.10))
                        .frame(width: 92, height: 92)
                    if appleUserID.isEmpty {
                        if shownName.isEmpty {
                            Image(systemName: "person.fill")
                                .font(.system(size: 40))
                                .foregroundStyle(Theme.lime)
                        } else {
                            InitialsAvatar(name: shownName, size: 80)
                        }
                    } else {
                        PlayerAvatar(appleUserID: appleUserID, name: effectiveName, size: 80)
                            .id(avatarRefreshToken)
                    }
                }

                if !appleUserID.isEmpty {
                    PhotosPicker(selection: $avatarItem, matching: .images) {
                        Image(systemName: uploadingAvatar ? "hourglass" : "camera.fill")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundStyle(Theme.tile)
                            .frame(width: 28, height: 28)
                            .background(Theme.lime, in: Circle())
                            .overlay(Circle().strokeBorder(Theme.court, lineWidth: 2))
                    }
                    .disabled(uploadingAvatar)
                    .offset(x: 4, y: 4)
                }
            }
            Text(shownName.isEmpty ? "Il tuo profilo" : shownName)
                .font(.system(.title3, design: .rounded, weight: .heavy))
                .foregroundStyle(.white)
            Text(appleUserID.isEmpty
                 ? "Registrati con Apple: il tuo nome viene impostato in automatico su tabellone e nelle partite."
                 : "La tua stagione a colpo d'occhio")
                .font(.system(.footnote, design: .rounded))
                .foregroundStyle(.white.opacity(0.7))

            if needsAvatarHint {
                Text("Tocca la fotocamera per aggiungere la tua foto profilo.")
                    .font(.system(.caption, design: .rounded, weight: .semibold))
                    .foregroundStyle(Theme.lime)
                    .multilineTextAlignment(.center)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 28)
        .background(
            LinearGradient(colors: [Theme.court, Theme.courtDeep],
                           startPoint: .top, endPoint: .bottom),
            in: RoundedRectangle(cornerRadius: 24))
        .onChange(of: avatarItem) { _, item in
            guard let item else { return }
            Task { await uploadAvatar(from: item) }
        }
        .task(id: appleUserID) {
            guard !appleUserID.isEmpty else { return }
            _ = await CloudKitManager.shared.fetchAvatar(appleUserID: appleUserID)
        }
    }

    /// Username grande con azioni rapide per condividerlo con gli avversari.
    private var usernameShareCard: some View {
        VStack(spacing: 16) {
            Text("@\(trimmedUsername)")
                .font(.system(size: 32, weight: .heavy, design: .rounded))
                .foregroundStyle(Theme.court)
                .minimumScaleFactor(0.6)
                .lineLimit(1)

            Text("Condividi il tuo username con gli avversari: è collegato al tuo account Apple e non può essere modificato.")
                .font(.system(.caption, design: .rounded))
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)

            HStack(spacing: 10) {
                Button {
                    UIPasteboard.general.string = "@\(trimmedUsername)"
                    usernameCopied = true
                    Task {
                        try? await Task.sleep(for: .seconds(2))
                        usernameCopied = false
                    }
                } label: {
                    Label(usernameCopied ? "Copiato!" : "Copia",
                          systemImage: usernameCopied ? "checkmark" : "doc.on.doc")
                        .font(.system(.subheadline, design: .rounded, weight: .bold))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(Theme.court.opacity(0.10), in: RoundedRectangle(cornerRadius: 12))
                        .foregroundStyle(Theme.court)
                }
                .buttonStyle(PressableStyle())

                ShareLink(item: shareUsernameText) {
                    Label("Condividi", systemImage: "square.and.arrow.up")
                        .font(.system(.subheadline, design: .rounded, weight: .bold))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(Theme.lime.opacity(0.35), in: RoundedRectangle(cornerRadius: 12))
                        .foregroundStyle(Theme.courtDeep)
                }
                .buttonStyle(PressableStyle())
            }
        }
        .padding(20)
        .card()
    }

    /// Prenotazione campi — in arrivo, non più tab dedicata.
    private var prenotazioneComingSoonCard: some View {
        HStack(spacing: 14) {
            Image(systemName: "calendar.badge.clock")
                .font(.system(size: 28))
                .foregroundStyle(Theme.accent)
                .frame(width: 44, height: 44)
                .background(Theme.accent.opacity(0.12), in: RoundedRectangle(cornerRadius: 12))

            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 8) {
                    Text("Prenotazione campi")
                        .font(.system(.subheadline, design: .rounded, weight: .bold))
                    Text("In arrivo")
                        .font(.system(.caption2, design: .rounded, weight: .heavy))
                        .foregroundStyle(Theme.accent)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(Theme.accent.opacity(0.12), in: Capsule())
                }
                Text("Stiamo lavorando per permetterti di prenotare campi da tennis e padel direttamente dall'app.")
                    .font(.system(.caption, design: .rounded))
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(16)
        .card()
    }

    /// Senza account: campo sempre visibile per scegliere il nome.
    private var guestNameCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Il tuo nome")
                .font(.system(.subheadline, design: .rounded, weight: .semibold))
                .foregroundStyle(.secondary)

            Text("Compare sul tabellone e sulle card condivise al posto di \"Io\". Puoi cambiarlo quando vuoi.")
                .font(.system(.caption, design: .rounded))
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)

            HStack(spacing: 8) {
                Image(systemName: "person.text.rectangle.fill")
                    .font(.system(size: 16))
                    .foregroundStyle(Theme.accent)
                TextField("es. Marcello", text: $displayName)
                    .textFieldStyle(.roundedBorder)
                    .font(.system(.subheadline, design: .rounded))
                    .textInputAutocapitalization(.words)
                    .autocorrectionDisabled()
                    .submitLabel(.done)
            }
        }
        .padding(16)
        .card()
    }

    private var appleWatchCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 10) {
                Image(systemName: sync.isWatchAppInstalled ? "applewatch" : "applewatch.slash")
                    .font(.system(size: 26))
                    .foregroundStyle(sync.isWatchAppInstalled ? Theme.accent : Theme.loss)
                VStack(alignment: .leading, spacing: 2) {
                    Text("Apple Watch")
                        .font(.system(.subheadline, design: .rounded, weight: .bold))
                        .foregroundStyle(.primary)
                    Text("Sincronizzazione e tracciamento al polso")
                        .font(.system(.caption, design: .rounded))
                        .foregroundStyle(.secondary)
                }
                Spacer()
                if sync.isWatchAppInstalled {
                    Text("Installata")
                        .font(.system(.caption, design: .rounded, weight: .bold))
                        .foregroundStyle(Theme.win)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Theme.win.opacity(0.12), in: Capsule())
                } else {
                    Text("Non installata")
                        .font(.system(.caption, design: .rounded, weight: .bold))
                        .foregroundStyle(Theme.loss)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Theme.loss.opacity(0.12), in: Capsule())
                }
            }

            if sync.isWatchAppInstalled {
                Text("L'app è installata sul Watch. Avvia le partite dall'iPhone: il tabellone apparirà sul polso.")
                    .font(.system(.footnote, design: .rounded))
                    .foregroundStyle(.secondary)
                    .lineLimit(nil)
                    .fixedSize(horizontal: false, vertical: true)
            } else {
                VStack(alignment: .leading, spacing: 10) {
                    Text("Se vedi l'icona sul Watch ma qui risulta non installata, reinstalla da Xcode (⌘R sullo scheme SetPoint → iPhone). Il pulsante INSTALLA nell'app Watch spesso lascia una build incompleta.")
                        .font(.system(.footnote, design: .rounded))
                        .foregroundStyle(.secondary)
                        .lineLimit(nil)
                        .fixedSize(horizontal: false, vertical: true)

                    Text("Installazione manuale:")
                        .font(.system(.footnote, design: .rounded, weight: .bold))
                        .foregroundStyle(.primary)
                    
                    VStack(alignment: .leading, spacing: 8) {
                        instructionRow(number: "1", text: "Apri l'applicazione nativa 'Watch' sul tuo iPhone.")
                        instructionRow(number: "2", text: "Scorri verso il basso fino alla sezione 'Applicazioni disponibili'.")
                        instructionRow(number: "3", text: "Cerca 'SetPoint' e tocca 'Installa' accanto ad essa.")
                    }
                }
            }
        }
        .padding(16)
        .card()
    }

    /// Zona pericolosa: separata dal resto dell'account (HIG), con
    /// conferma esplicita e spiegazione delle conseguenze.
    private var deleteAccountCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            Label("Elimina account", systemImage: "trash.fill")
                .font(.system(.subheadline, design: .rounded, weight: .bold))
                .foregroundStyle(Theme.loss)

            Text("Elimina il profilo pubblico dal cloud e scollega l'account Apple da questo dispositivo. Le partite salvate sul telefono restano.")
                .font(.system(.caption, design: .rounded))
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)

            Button {
                showDeleteAccount = true
            } label: {
                if savingProfile {
                    ProgressView()
                        .frame(maxWidth: .infinity, minHeight: 44)
                } else {
                    Text("Elimina definitivamente")
                        .font(.system(.subheadline, design: .rounded, weight: .bold))
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity, minHeight: 44)
                        .background(Theme.loss, in: RoundedRectangle(cornerRadius: 12))
                }
            }
            .buttonStyle(PressableStyle())
            .disabled(savingProfile)
            .confirmationDialog("Eliminare l'account?",
                                isPresented: $showDeleteAccount,
                                titleVisibility: .visible) {
                Button("Elimina account", role: .destructive) {
                    Task { await deleteAccount() }
                }
            } message: {
                Text("Azione irreversibile: profilo pubblico e nome utente vengono eliminati dal cloud. Le partite locali non vengono toccate.")
            }
        }
        .padding(16)
        .card()
    }

    private func instructionRow(number: String, text: String) -> some View {
        HStack(alignment: .top, spacing: 8) {
            Text(number)
                .font(.system(.caption, design: .rounded, weight: .bold))
                .foregroundStyle(Theme.tile)
                .frame(width: 18, height: 18)
                .background(Theme.lime, in: Circle())
            Text(text)
                .font(.system(.footnote, design: .rounded))
                .foregroundStyle(.secondary)
                .lineLimit(nil)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private func uploadAvatar(from item: PhotosPickerItem) async {
        guard !appleUserID.isEmpty else { return }
        uploadingAvatar = true
        defer {
            uploadingAvatar = false
            avatarItem = nil
        }

        guard let data = try? await item.loadTransferable(type: Data.self),
              let image = UIImage(data: data),
              let jpeg = image.jpegData(compressionQuality: 0.85)
        else { return }

        do {
            try await CloudKitManager.shared.saveAvatar(appleUserID: appleUserID, imageData: jpeg)
            avatarRefreshToken = UUID()
            needsAvatarHint = false
        } catch {
            profileError = "Impossibile salvare la foto profilo: \(error.localizedDescription)"
        }
    }

    private func loadProfile() async {
        guard !appleUserID.isEmpty else { return }
        let email = appleUserEmail.isEmpty ? nil : appleUserEmail
        do {
            if let profile = try await CloudKitManager.shared.fetchProfile(appleUserID: appleUserID) {
                username = profile.username
                var preferredName = appleUserName.isEmpty ? profile.fullName : appleUserName

                if CloudKitManager.resolvedDisplayName(preferredName).isEmpty,
                   profile.username.lowercased() == "giocatore"
                   || profile.fullName.lowercased() == "giocatore" {
                    if !resolvedGuestName.isEmpty {
                        appleUserName = resolvedGuestName
                        preferredName = resolvedGuestName
                    } else {
                        pendingName = ""
                        showNamePrompt = true
                        needsAvatarHint = !profile.hasAvatar
                        return
                    }
                }

                var hasAvatar = profile.hasAvatar
                if let repaired = try await CloudKitManager.shared.repairProfileIfNeeded(
                    appleUserID: appleUserID,
                    preferredName: preferredName,
                    email: email,
                    currentUsername: profile.username,
                    currentFullName: profile.fullName
                ) {
                    username = repaired.username
                    if appleUserName.isEmpty { appleUserName = repaired.fullName }
                    infoMessage = "Profilo aggiornato: @\(repaired.username)"
                    avatarRefreshToken = UUID()
                    hasAvatar = repaired.hasAvatar
                }
                await CloudKitManager.shared.backfillSearchNameIfNeeded(
                    appleUserID: appleUserID,
                    fullName: preferredName
                )
                needsAvatarHint = !hasAvatar
            } else {
                if CloudKitManager.resolvedDisplayName(appleUserName).isEmpty {
                    if !resolvedGuestName.isEmpty {
                        appleUserName = resolvedGuestName
                    } else {
                        pendingName = ""
                        showNamePrompt = true
                        return
                    }
                }
                let profile = try await CloudKitManager.shared.setupInitialProfile(
                    appleUserID: appleUserID,
                    fullName: appleUserName,
                    email: email
                )
                username = profile.username
                infoMessage = "Profilo creato: @\(profile.username)"
                avatarRefreshToken = UUID()
                needsAvatarHint = !profile.hasAvatar
            }
        } catch {
            profileError = "Impossibile caricare il profilo cloud: \(error.localizedDescription)"
            print("Errore caricamento profilo CloudKit: \(error)")
        }
    }

    /// Elimina profilo pubblico ed eventuale match live dal cloud, poi
    /// scollega l'account dal dispositivo. Le partite locali restano.
    private func deleteAccount() async {
        guard !appleUserID.isEmpty else { return }
        savingProfile = true
        profileError = nil
        infoMessage = nil

        do {
            try await CloudKitManager.shared.deleteProfile(appleUserID: appleUserID)
            await CloudKitManager.shared.deleteLive(creatorID: appleUserID)
            CloudKitManager.shared.clearAvatarCache(for: appleUserID)
            appleUserID = ""
            appleUserName = ""
            username = ""
        } catch {
            profileError = "Impossibile eliminare l'account: \(error.localizedDescription) Riprova."
        }

        savingProfile = false
    }
}

#Preview {
    ProfileScreen()
        .modelContainer(for: MatchRecord.self, inMemory: true)
}
