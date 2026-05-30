import Foundation

// MARK: - API Client

class APIReceiver {
    
    private let baseURL = "https://ftc-api.firstinspires.org/v2.0"
    private let authHeader: String
    private let session: URLSession
    
    init(username: String, apiKey: String) {
        let credentials = "\(username):\(apiKey)"
        let encodedToken = Data(credentials.utf8).base64EncodedString()
        self.authHeader = "Basic \(encodedToken)"
        self.session = URLSession.shared
    }
    
    // MARK: - request method
    private func request<T: Decodable>(
        path: String,
        queryItems: [URLQueryItem] = []
    ) async throws -> T {
        guard var components = URLComponents(string: baseURL + path) else {
            throw FTCError.invalidURL(path)
        }
        
        //filter for non emtpy
        let filtered = queryItems.filter { $0.value != nil && !$0.value!.isEmpty }
        if !filtered.isEmpty {
            components.queryItems = filtered
        }
        
        guard let url = components.url else {
            throw FTCError.invalidURL(path)
        }
        
        var urlRequest = URLRequest(url: url)
        urlRequest.setValue(authHeader, forHTTPHeaderField: "Authorization")
        urlRequest.setValue("application/json", forHTTPHeaderField: "Accept")
        
        let (data, response) = try await session.data(for: urlRequest)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw FTCError.invalidResponse
        }
        
        switch httpResponse.statusCode {
        case 200:
            let decoder = JSONDecoder()
            return try decoder.decode(T.self, from: data)
        case 304:
            throw FTCError.notModified
        case 401:
            throw FTCError.unauthorized
        case 404:
            throw FTCError.eventNotFound
        default:
            throw FTCError.httpError(statusCode: httpResponse.statusCode,
                                     body: String(data: data, encoding: .utf8))
        }
    }
    
    // MARK: - Get Functions
    
    /// Root API index — returns version info and available seasons.
    func getAPIIndex() async throws -> APIIndex {
        try await request(path: "")
    }
    
    /// Get a high-level summary for a season.
    func getSeasonSummary(season: Int) async throws -> SeasonSummary {
        try await request(path: "/\(season)")
    }
    
    func getSeasonName(season: Int) async throws -> String {
        try await request(path: "/\(season)/gameName")
    }
    
    /// List all events for a season, optionally filtered by one event code or one team number.
    /// Cannot specify both eventCode and teamNumber at the same time.
    func getEvents(
        season: Int,
        eventCode: String? = nil,
        teamNumber: Int? = nil
    ) async throws -> EventListings {
        try await request(path: "/\(season)/events", queryItems: [
            URLQueryItem(name: "eventCode", value: eventCode),
            URLQueryItem(name: "teamNumber", value: teamNumber.map(String.init)),
        ])
    }
    
    /// List teams for a season, with optional filters.
    /// Cannot combine teamNumber with eventCode/state.
    /// can only use excludeNonCompeting with an eventCode
    func getTeams(
        season: Int,
        teamNumber: Int? = nil,
        eventCode: String? = nil,
        state: String? = nil,
        excludeNonCompeting: Bool = false,
        page: Int = 1
    ) async throws -> TeamListings {
        try await request(path: "/\(season)/teams", queryItems: [
            URLQueryItem(name: "teamNumber", value: teamNumber.map(String.init)),
            URLQueryItem(name: "eventCode", value: eventCode),
            URLQueryItem(name: "state", value: state),
            URLQueryItem(name: "excludeNonCompeting", value: excludeNonCompeting ? "true" : nil),
            URLQueryItem(name: "page", value: String(page)),
        ])
    }
    
    /// Get the event schedule (without results).
    func getSchedule(
        season: Int,
        eventCode: String,
        tournamentLevel: String? = nil,
        teamNumber: Int? = nil,
        start: Int? = nil,
        end: Int? = nil
    ) async throws -> EventSchedule {
        try await request(path: "/\(season)/schedule/\(eventCode)", queryItems: [
            URLQueryItem(name: "tournamentLevel", value: tournamentLevel),
            URLQueryItem(name: "teamNumber", value: teamNumber.map(String.init)),
            URLQueryItem(name: "start", value: start.map(String.init)),
            URLQueryItem(name: "end", value: end.map(String.init)),
        ])
    }
    
    /// Get the hybrid schedule (schedule + results merged).
    func getHybridSchedule(
        season: Int,
        eventCode: String,
        tournamentLevel: String,
        start: Int? = nil,
        end: Int? = nil
    ) async throws -> HybridSchedule {
        try await request(path: "/\(season)/schedule/\(eventCode)/\(tournamentLevel)/hybrid", queryItems: [
            URLQueryItem(name: "start", value: start.map(String.init)),
            URLQueryItem(name: "end", value: end.map(String.init)),
        ])
    }
    
    /// Get match results for completed matches at an event.
    /// matchNumber/start/end require tournamentLevel. Cannot combine teamNumber with matchNumber.
    func getMatchResults(
        season: Int,
        eventCode: String,
        tournamentLevel: String? = nil,
        teamNumber: Int? = nil,
        matchNumber: Int? = nil,
        start: Int? = nil,
        end: Int? = nil
    ) async throws -> MatchResults {
        try await request(path: "/\(season)/matches/\(eventCode)", queryItems: [
            URLQueryItem(name: "tournamentLevel", value: tournamentLevel),
            URLQueryItem(name: "teamNumber", value: teamNumber.map(String.init)),
            URLQueryItem(name: "matchNumber", value: matchNumber.map(String.init)),
            URLQueryItem(name: "start", value: start.map(String.init)),
            URLQueryItem(name: "end", value: end.map(String.init)),
        ])
    }
    
    /// Get detailed score breakdown for matches at an event.
    /// Returns game-specific scoring elements
    func getScoreDetails(
        season: Int,
        eventCode: String,
        tournamentLevel: String,
        teamNumber: Int? = nil,
        matchNumber: Int? = nil,
        start: Int? = nil,
        end: Int? = nil
    ) async throws -> MatchScores {
        try await request(path: "/\(season)/scores/\(eventCode)/\(tournamentLevel)", queryItems: [
            URLQueryItem(name: "teamNumber", value: teamNumber.map(String.init)),
            URLQueryItem(name: "matchNumber", value: matchNumber.map(String.init)),
            URLQueryItem(name: "start", value: start.map(String.init)),
            URLQueryItem(name: "end", value: end.map(String.init)),
        ])
    }
    
    /// Get event rankings. Cannot combine teamNumber with top
    /// top just gives x out of the total teams ranked in order
    func getRankings(
        season: Int,
        eventCode: String,
        teamNumber: Int? = nil,
        top: Int? = nil
    ) async throws -> EventRankings {
        try await request(path: "/\(season)/rankings/\(eventCode)", queryItems: [
            URLQueryItem(name: "teamNumber", value: teamNumber.map(String.init)),
            URLQueryItem(name: "top", value: top.map(String.init)),
        ])
    }
    
    /// Get final alliance compositions after selection at an event.
    func getAlliances(
        season: Int,
        eventCode: String
    ) async throws -> AllianceSelection {
        try await request(path: "/\(season)/alliances/\(eventCode)")
    }
    
    /// Get step-by-step alliance selection details (pick order, accepts, declines).
    func getAllianceSelectionDetails(
        season: Int,
        eventCode: String
    ) async throws -> AllianceSelectionDetail {
        try await request(path: "/\(season)/alliances/\(eventCode)/selection")
    }
    
    /// Get the master list of all possible award types for a season.
    func getAwardsList(season: Int) async throws -> AwardListings {
        try await request(path: "/\(season)/awards/list")
    }
    
    /// Get all awards given at a specific event, optionally filtered by team.
    func getEventAwards(
        season: Int,
        eventCode: String,
        teamNumber: Int? = nil
    ) async throws -> Awards {
        try await request(path: "/\(season)/awards/\(eventCode)", queryItems: [
            URLQueryItem(name: "teamNumber", value: teamNumber.map(String.init)),
        ])
    }
    
    /// Get all awards won by a specific team across the season.
    func getTeamAwards(
        season: Int,
        teamNumber: Int,
        eventCode: String? = nil
    ) async throws -> Awards {
        if let eventCode = eventCode {
            return try await request(path: "/\(season)/awards/\(eventCode)/\(teamNumber)")
        } else {
            return try await request(path: "/\(season)/awards/\(teamNumber)")
        }
    }
    
    /// List leagues for a season, optionally filtered by region and/or league code.
    func getLeagues(
        season: Int,
        regionCode: String? = nil,
        leagueCode: String? = nil
    ) async throws -> LeagueListings {
        try await request(path: "/\(season)/leagues", queryItems: [
            URLQueryItem(name: "regionCode", value: regionCode),
            URLQueryItem(name: "leagueCode", value: leagueCode),
        ])
    }
    
    /// Get team numbers belonging to a specific league.
    func getLeagueMembers(
        season: Int,
        regionCode: String,
        leagueCode: String
    ) async throws -> LeagueMembers {
        try await request(path: "/\(season)/leagues/members/\(regionCode)/\(leagueCode)")
    }
    
    /// Get cumulative league meet rankings (does NOT include league tournament).
    func getLeagueRankings(
        season: Int,
        regionCode: String,
        leagueCode: String
    ) async throws -> EventRankings {
        try await request(path: "/\(season)/leagues/rankings/\(regionCode)/\(leagueCode)")
    }
    
    /// Get Regional Championship advancement allocations (seasons 2025+).
    func getRegionalAdvancement(season: Int) async throws -> [RegionalAdvancement] {
        try await request(path: "/\(season)/advancement")
    }
    
    /// Get which teams advanced from a specific event.
    func getAdvancement(
        season: Int,
        eventCode: String,
        excludeSkipped: Bool = false
    ) async throws -> Advancement {
        try await request(path: "/\(season)/advancement/\(eventCode)", queryItems: [
            URLQueryItem(name: "excludeSkipped", value: excludeSkipped ? "true" : nil),
        ])
    }
    
    /// Get advancement points earned by each team at an event (seasons 2025+).
    func getAdvancementPoints(
        season: Int,
        eventCode: String
    ) async throws -> [AdvancementPoints] {
        try await request(path: "/\(season)/advancement/\(eventCode)/points")
    }
    
    /// Get where teams at an event advanced from.
    func getAdvancementSource(
        season: Int,
        eventCode: String,
        includeDeclines: Bool = false
    ) async throws -> [AdvancementSource] {
        try await request(path: "/\(season)/advancement/\(eventCode)/source", queryItems: [
            URLQueryItem(name: "includeDeclines", value: includeDeclines ? "true" : nil),
        ])
    }
}

// MARK: - Error Types

enum FTCError: Error, LocalizedError {
    case invalidURL(String)
    case invalidResponse
    case notModified
    case unauthorized
    case eventNotFound
    case httpError(statusCode: Int, body: String?)
    
    var errorDescription: String? {
        switch self {
        case .invalidURL(let path):       return "Invalid URL path: \(path)"
        case .invalidResponse:            return "Response was not HTTP"
        case .notModified:                return "Data has not been modified (304)"
        case .unauthorized:               return "Invalid or missing API credentials (401)"
        case .eventNotFound:              return "Event not found for the given season/code (404)"
        case .httpError(let code, let body):
            return "HTTP \(code): \(body ?? "No details")"
        }
    }
}

// MARK: - Response Models

struct APIIndex: Codable {
    let name: String?
    let apiVersion: String?
    let status: String?
}

struct SeasonSummary: Codable {
    let eventCount: Int?
    let gameName: String?
    let kickoff: String?
    let rookieStart: Int?
    let teamCount: Int?
    let frcChampionships: [Championship]?
    
    struct Championship: Codable {
        let name: String?
        let startDate: String?
        let location: String?
    }
}

struct EventListings: Codable {
    let events: [Event]?
    let eventCount: Int?
}

struct Event: Codable, Identifiable {
    let code: String?
    let divisionCode: String?
    let name: String?
    let type: String?
    let typeName: String?
    let regionCode: String?
    let leagueCode: String?
    let districtCode: String?
    let venue: String?
    let address: String?
    let city: String?
    let stateprov: String?
    let country: String?
    let website: String?
    let liveStreamUrl: String?
    let timezone: String?
    let dateStart: String?
    let dateEnd: String?
    let remote: Bool?
    let hybrid: Bool?
    let fieldCount: Int?

    public var id: String { code ?? UUID().uuidString }

    var locationString: String {
        [city, stateprov, country]
            .compactMap { $0 }
            .filter { !$0.isEmpty }
            .joined(separator: ", ")
    }

    var isChampionship: Bool {
        guard let t = typeName ?? type else { return false }
        return t.lowercased().contains("championship")
    }
}

struct TeamListings: Codable {
    let teams: [Team]?
    let teamCountTotal: Int?
    let teamCountPage: Int?
    let pageCurrent: Int?
    let pageTotal: Int?
    
    struct Team: Codable {
        let teamNumber: Int?
        let nameFull: String?
        let nameShort: String?
        let city: String?
        let stateProv: String?
        let country: String?
        let rookieYear: Int?
        func toTeamInfo() -> TeamInfo? {
            guard let num = teamNumber else { return nil }
            return TeamInfo(
                teamNumber: num,
                nameFull: nameFull,
                nameShort: nameShort,
                city: city,
                stateProv: stateProv,
                country: country,
                rookieYear: rookieYear,
                schoolName: nil,
                website: nil,
                sponsors: nil
            )
        }
    }
}

struct EventSchedule: Codable {
    let schedule: [ScheduleMatch]?
    
    struct ScheduleMatch: Codable {
        let matchNumber: Int?
        let description: String?
        let startTime: String?
        let tournamentLevel: String?
        let teams: [ScheduleTeam]?
    }
    
    struct ScheduleTeam: Codable {
        let teamNumber: Int?
        let station: String?
        let surrogate: Bool?
    }
}

struct HybridSchedule: Codable {
    let schedule: [Match]?
    
    struct Match: Codable {
        let matchNumber: Int?
        let description: String?
        let startTime: String?
        let tournamentLevel: String?
        let teams: [MatchTeam]?
        let scoreRedFinal: Int?
        let scoreBlueFinal: Int?
    }
    
    struct MatchTeam: Codable {
        let teamNumber: Int?
        let station: String?
        let surrogate: Bool?
    }
}

struct MatchResults: Codable {
    let matches: [MatchResult]?
    
    struct MatchResult: Codable {
        let matchNumber: Int?
        let description: String?
        let tournamentLevel: String?
        let startTime: String?
        let actualStartTime: String?
        let scoreRedFinal: Int?
        let scoreBlueFinal: Int?
        let scoreRedFoul: Int?
        let scoreBlueFoul: Int?
        let teams: [MatchTeam]?
    }
    
    struct MatchTeam: Codable {
        let teamNumber: Int?
        let station: String?
        let surrogate: Bool?
    }
}

struct MatchScores: Codable {
    let matchScores: [MatchScore]?
    
    struct MatchScore: Codable {
        let matchNumber: Int?
        let matchLevel: String?
        let alliances: [AllianceScore]?
    }
    
    // Score fields change every season — add the specific game fields you need.
    struct AllianceScore: Codable {
        let alliance: String?
        let totalPoints: Int?
        let autoPoints: Int?
        let dcPoints: Int?
        let endgamePoints: Int?
        let penaltyPoints: Int?
    }
}

struct EventRankings: Codable {
    let rankings: [Ranking]?
    
    struct Ranking: Codable {
        let rank: Int?
        let teamNumber: Int?
        let wins: Int?
        let losses: Int?
        let ties: Int?
        let qualAverage: Double?
        let sortOrder1: Double?
        let sortOrder2: Double?
        let sortOrder3: Double?
        let sortOrder4: Double?
        let sortOrder5: Double?
        let sortOrder6: Double?
        let matchesPlayed: Int?
    }
}

struct AllianceSelection: Codable {
    let alliances: [Alliance]?
    
    struct Alliance: Codable {
        let number: Int?
        let captain: Int?
        let round1: Int?
        let round2: Int?
        let round3: Int?
        let backup: Int?
        let backupReplaced: Int?
    }
}

struct AllianceSelectionDetail: Codable {
    let selections: [SelectionStep]?
    
    struct SelectionStep: Codable {
        let allianceNumber: Int?
        let round: Int?
        let teamNumber: Int?
        let result: String?
    }
}

struct AwardListings: Codable {
    let awards: [AwardType]?
    
    struct AwardType: Codable {
        let awardId: Int?
        let name: String?
        let description: String?
    }
}

struct Awards: Codable {
    let awards: [Award]?
    
    struct Award: Codable {
        let awardId: Int?
        let name: String?
        let series: Int?
        let teamNumber: Int?
        let person: String?
        let eventCode: String?
    }
}

struct LeagueListings: Codable {
    let leagues: [League]?
    
    struct League: Codable {
        let regionCode: String?
        let leagueCode: String?
        let name: String?
        let parentLeagueCode: String?
    }
}

struct LeagueMembers: Codable {
    let members: [Int]?
}

struct Advancement: Codable {
    let advancesTo: String?
    let slots: Int?
    let advancementSlots: [AdvancementSlot]?
    
    struct AdvancementSlot: Codable {
        let teamNumber: Int?
        let advancementReason: String?
        let skipped: Bool?
    }
}

struct RegionalAdvancement: Codable {
    let regionCode: String?
    let slots: Int?
    let fcmpReserved: Int?
}

struct AdvancementPoints: Codable {
    let teamNumber: Int?
    let advancementPoints: Double?
}

struct AdvancementSource: Codable {
    let teamNumber: Int?
    let sourceEvent: String?
    let declined: Bool?
}

struct TeamInfo: Codable, Identifiable, Hashable {
    let teamNumber: Int
    let nameFull: String?
    let nameShort: String?
    let city: String?
    let stateProv: String?
    let country: String?
    let rookieYear: Int?
    let schoolName: String?       // FIRST API returns this on team detail
    let website: String?          // FIRST API returns this on team detail
    let sponsors: String?         // sometimes present
    
    var id: Int { teamNumber }
    
    var locationString: String {
        [city, stateProv, country]
            .compactMap { $0 }
            .filter { !$0.isEmpty }
            .joined(separator: ", ")
    }
}
