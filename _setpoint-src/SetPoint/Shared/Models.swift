import Foundation

enum Sport: String, CaseIterable, Identifiable, Codable {
    case tennis = "Tennis"
    case padel = "Padel"
    var id: String { rawValue }
}

enum MatchType: String, CaseIterable, Identifiable, Codable {
    case singolare = "Singolare"
    case doppio = "Doppio"
    var id: String { rawValue }
}

/// Superficie di gioco (solo tennis).
enum CourtSurface: String, CaseIterable, Identifiable, Codable {
    case hard = "Cemento"
    case clay = "Terra rossa"
    case grass = "Erba"
    var id: String { rawValue }
}

/// Metriche Apple Salute raccolte durante il match sul Watch.
struct MatchHealthSnapshot: Codable, Equatable {
    var activeCalories: Double = 0
    var avgHeartRate: Double = 0
    var maxHeartRate: Double = 0
    var steps: Int = 0
    var distanceMeters: Double = 0

    var hasData: Bool {
        activeCalories > 0 || avgHeartRate > 0 || maxHeartRate > 0
            || steps > 0 || distanceMeters > 0
    }
}

/// Profilo cloud agganciato a un giocatore della partita (toggle
/// "Ha l'applicazione"): il match viene condiviso e trasmesso live
/// sui dispositivi di tutti i profili collegati.
struct LinkedPlayer: Codable, Equatable {
    var userID: String
    var username: String
    var fullName: String
}

/// Nomi associati al match (io/partner vs avversari, due nel doppio).
struct MatchMeta: Codable, Equatable {
    var name = ""
    /// Campo o circolo dove si gioca (compare sul tabellone live e sulla card social).
    var venue = ""
    var opponent = ""
    var opponent2 = ""
    var partner = ""
    /// Modalità spettatore: segnapunti per altri, senza contare nelle statistiche.
    var isSpectator = false
    /// Nome scelto in Profilo (o da Sign in with Apple): compare al posto
    /// di "IO/NOI" sul tabellone e sul Watch quando la partita parte da iPhone.
    /// In modalità spettatore è il primo giocatore della squadra A.
    var homeName = ""

    /// Profili cloud collegati (nil = giocatore senza app).
    var homeNameLink: LinkedPlayer? = nil
    var partnerLink: LinkedPlayer? = nil
    var opponentLink: LinkedPlayer? = nil
    var opponent2Link: LinkedPlayer? = nil

    var links: [LinkedPlayer] {
        [partnerLink, opponentLink, opponent2Link].compactMap { $0 }
    }

    /// Campo da mostrare in UI (`venue` con fallback su `name` legacy).
    var displayVenue: String {
        let court = venue.trimmingCharacters(in: .whitespacesAndNewlines)
        if !court.isEmpty { return court }
        return name.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    /// Etichette squadre per il tabellone.
    /// Su Apple Watch (`forWatch: true`) restano sempre IO/NOI e AVVERSARIO/AVVERSARI
    /// durante la partita; su iPhone valgono le regole complete (nomi, spettatore, ecc.).
    func teamNames(type: MatchType, forWatch: Bool = false) -> [String] {
        if forWatch {
            return type == .doppio ? ["NOI", "AVVERSARI"] : ["IO", "AVVERSARIO"]
        }
        let homeTrimmed = homeName.trimmingCharacters(in: .whitespaces)
        let home: String
        if !homeTrimmed.isEmpty {
            if type == .doppio {
                let partnerTrimmed = partner.trimmingCharacters(in: .whitespaces)
                home = partnerTrimmed.isEmpty
                    ? homeTrimmed.uppercased()
                    : "\(homeTrimmed)+\(partnerTrimmed)".uppercased()
            } else {
                home = homeTrimmed.uppercased()
            }
        } else {
            if isSpectator {
                home = type == .doppio ? "SQUADRA A" : "GIOCATORE 1"
            } else {
                home = type == .doppio ? "NOI" : "IO"
            }
        }
        let opps = [opponent, opponent2]
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty }
        let away = opps.joined(separator: "+")
        let fallback: String
        if isSpectator {
            fallback = type == .doppio ? "SQUADRA B" : "GIOCATORE 2"
        } else {
            fallback = type == .doppio ? "AVVERSARI" : "AVVERSARIO"
        }
        return [home, away.isEmpty ? fallback : away.uppercased()]
    }

    /// Tutti i nomi giocatore compilati (per validazione in modalità spettatore).
    func spectatorNamesComplete(type: MatchType) -> Bool {
        guard isSpectator else { return true }
        let names = type == .doppio
            ? [homeName, partner, opponent, opponent2]
            : [homeName, opponent]
        return names.allSatisfy { !$0.trimmingCharacters(in: .whitespaces).isEmpty }
    }
}

struct MatchConfig: Codable, Equatable {
    var sport: Sport = .padel
    var matchType: MatchType = .doppio
    var courtSurface: CourtSurface = .hard   // solo tennis
    var setsToWin: Int = 2          // 1, 2 o 3 set vincenti
    var fast4: Bool = false         // set a 4 game, tie-break sul 3-3
    var goldenPoint: Bool = false   // Padel: punto secco sul 40-40
    var superTiebreak: Bool = false // set decisivo = tie-break a 10

    var gamesPerSet: Int { fast4 ? 4 : 6 }
    var tiebreakTrigger: Int { fast4 ? 3 : 6 }
}

struct SetResult: Codable, Equatable {
    var games: [Int]                // [team0, team1]
    var tiebreak: [Int]?            // punteggio TB se giocato
    var duration: TimeInterval
    var winner: Int { games[0] > games[1] ? 0 : 1 }
}

enum ScoreEvent {
    case point
    case game
    case setWon(Int)
    case matchWon(Int)
    case changeEnds
    case tiebreakStart
}
