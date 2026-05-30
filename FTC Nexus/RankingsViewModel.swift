import Foundation
import FirebaseFirestore

// MARK: - Model

// `Codable` so we can persist the cached snapshot as JSON on disk.
// `id` is a computed property (was a stored `let`) so it's not encoded —
// no need to keep a redundant copy of teamNumber on disk.
struct TeamRanking: Identifiable, Codable {
    var id: Int { teamNumber }

    let teamNumber: Int
    let nameShort: String
    let city: String
    let stateProv: String
    let country: String
    let rookieYear: Int
    let opr: Double
    let oprRank: Int
    let oprEventCode: String
    let autoOpr: Double
    let autoOprRank: Int
    let teleopOpr: Double
    let teleopOprRank: Int
    let endgameOpr: Double
    let endgameOprRank: Int
    let avgPoints: Double
    let avgPointsRank: Int
    let eventsPlayed: Int
    let wins: Int
    let losses: Int
    let draws: Int
    let summedScore: Int
    let minScore: Int
    let maxScore: Int
    let summedAutoScore: Int
    let minAutoScore: Int
    let maxAutoScore: Int
    let summedTeleopScore: Int
    let minTeleopScore: Int
    let maxTeleopScore: Int
    let summedEndgameScore: Int
    let minEndgameScore: Int
    let maxEndgameScore: Int

    // Custom init from a Firestore doc. Different first-parameter type from the
    // synthesized `init(from: Decoder)` so they coexist without ambiguity.
    init(from doc: DocumentSnapshot) {
        let d = doc.data() ?? [:]
        teamNumber        = d["teamNumber"]        as? Int    ?? 0
        nameShort         = d["nameShort"]         as? String ?? ""
        city              = d["city"]              as? String ?? ""
        stateProv         = d["stateProv"]         as? String ?? ""
        country           = d["country"]           as? String ?? ""
        rookieYear        = d["rookieYear"]        as? Int    ?? 0
        opr               = d["opr"]               as? Double ?? 0
        oprRank           = d["oprRank"]           as? Int    ?? 0
        oprEventCode      = d["oprEventCode"]      as? String ?? ""
        autoOpr           = d["autoOpr"]           as? Double ?? 0
        autoOprRank       = d["autoOprRank"]       as? Int    ?? 0
        teleopOpr         = d["teleopOpr"]         as? Double ?? 0
        teleopOprRank     = d["teleopOprRank"]     as? Int    ?? 0
        endgameOpr        = d["endgameOpr"]        as? Double ?? 0
        endgameOprRank    = d["endgameOprRank"]    as? Int    ?? 0
        avgPoints         = d["avgPoints"]         as? Double ?? 0
        avgPointsRank     = d["avgPointsRank"]     as? Int    ?? 0
        eventsPlayed      = d["eventsPlayed"]      as? Int    ?? 0
        wins              = d["wins"]              as? Int    ?? 0
        losses            = d["losses"]            as? Int    ?? 0
        draws             = d["draws"]             as? Int    ?? 0
        summedScore       = d["summedScore"]       as? Int    ?? 0
        minScore          = d["minScore"]          as? Int    ?? 0
        maxScore          = d["maxScore"]          as? Int    ?? 0
        summedAutoScore   = d["summedAutoScore"]   as? Int    ?? 0
        minAutoScore      = d["minAutoScore"]      as? Int    ?? 0
        maxAutoScore      = d["maxAutoScore"]      as? Int    ?? 0
        summedTeleopScore = d["summedTeleopScore"] as? Int    ?? 0
        minTeleopScore    = d["minTeleopScore"]    as? Int    ?? 0
        maxTeleopScore    = d["maxTeleopScore"]    as? Int    ?? 0
        summedEndgameScore = d["summedEndgameScore"] as? Int  ?? 0
        minEndgameScore   = d["minEndgameScore"]   as? Int    ?? 0
        maxEndgameScore   = d["maxEndgameScore"]   as? Int    ?? 0
    }

    init(
        teamNumber: Int, nameShort: String,
        city: String, stateProv: String, country: String,
        rookieYear: Int,
        opr: Double, oprRank: Int, oprEventCode: String,
        autoOpr: Double, autoOprRank: Int,
        teleopOpr: Double, teleopOprRank: Int,
        endgameOpr: Double, endgameOprRank: Int,
        eventsPlayed: Int,
        wins: Int = 0, losses: Int = 0, draws: Int = 0,
        summedScore: Int = 0,
        minScore: Int = 0, maxScore: Int = 0,
        summedAutoScore: Int = 0,
        minAutoScore: Int = 0, maxAutoScore: Int = 0,
        summedTeleopScore: Int = 0,
        minTeleopScore: Int = 0, maxTeleopScore: Int = 0,
        summedEndgameScore: Int = 0,
        minEndgameScore: Int = 0, maxEndgameScore: Int = 0
    ) {
        self.teamNumber       = teamNumber
        self.nameShort        = nameShort
        self.city             = city
        self.stateProv        = stateProv
        self.country          = country
        self.rookieYear       = rookieYear
        self.opr              = opr
        self.oprRank          = oprRank
        self.oprEventCode     = oprEventCode
        self.autoOpr          = autoOpr
        self.autoOprRank      = autoOprRank
        self.teleopOpr        = teleopOpr
        self.teleopOprRank    = teleopOprRank
        self.endgameOpr       = endgameOpr
        self.endgameOprRank   = endgameOprRank
        self.avgPoints        = 0.0
        self.avgPointsRank    = 1
        self.eventsPlayed     = eventsPlayed
        self.wins             = wins
        self.losses           = losses
        self.draws            = draws
        self.summedScore      = summedScore
        self.minScore         = minScore
        self.maxScore         = maxScore
        self.summedAutoScore  = summedAutoScore
        self.minAutoScore     = minAutoScore
        self.maxAutoScore     = maxAutoScore
        self.summedTeleopScore  = summedTeleopScore
        self.minTeleopScore     = minTeleopScore
        self.maxTeleopScore     = maxTeleopScore
        self.summedEndgameScore = summedEndgameScore
        self.minEndgameScore    = minEndgameScore
        self.maxEndgameScore    = maxEndgameScore
    }

    static var preview: TeamRanking {
        TeamRanking(
            teamNumber: 14270, nameShort: "Quantum",
            city: "Bucharest", stateProv: "", country: "Romania",
            rookieYear: 2018,
            opr: 232.21, oprRank: 1, oprEventCode: "ROCMP",
            autoOpr: 45.08, autoOprRank: 3,
            teleopOpr: 187.13, teleopOprRank: 1,
            endgameOpr: 22.40, endgameOprRank: 2,
            eventsPlayed: 3,
            wins: 8, losses: 2, draws: 0,
            summedScore: 2180, minScore: 185, maxScore: 247,
            summedAutoScore: 420, minAutoScore: 38, maxAutoScore: 52,
            summedTeleopScore: 1650, minTeleopScore: 140, maxTeleopScore: 198,
            summedEndgameScore: 110, minEndgameScore: 8, maxEndgameScore: 15
        )
    }
}

// MARK: - Sort Options

enum RankingSortField: String, CaseIterable {
    case opr        = "oprRank"
    case auto       = "autoOprRank"
    case teleop     = "teleopOprRank"
    case endgame    = "endgameOprRank"
    case avg        = "avgPointsRank"

    var label: String {
        switch self {
        case .opr:     return "OPR"
        case .auto:    return "Auto"
        case .teleop:  return "Teleop"
        case .endgame: return "Endgame"
        case .avg:     return "Avg"
        }
    }

    func rankValue(for team: TeamRanking) -> Int {
        switch self {
        case .opr:     return team.oprRank
        case .auto:    return team.autoOprRank
        case .teleop:  return team.teleopOprRank
        case .endgame: return team.endgameOprRank
        case .avg:     return team.avgPointsRank
        }
    }

    func value(for team: TeamRanking) -> Double {
        switch self {
        case .opr:     return team.opr
        case .auto:    return team.autoOpr
        case .teleop:  return team.teleopOpr
        case .endgame: return team.endgameOpr
        case .avg:     return team.avgPoints
        }
    }
}

// MARK: - ViewModel

@MainActor
class RankingsViewModel: ObservableObject {

    private var allTeams: [TeamRanking] = []
    private var filteredTeams: [TeamRanking] = []

    @Published var currentPageTeams: [TeamRanking] = []

    @Published var searchQuery: String = "" {
        didSet { applyFilterAndPage() }
    }

    @Published var sortField: RankingSortField = .opr {
        didSet { applySortAndPage() }
    }

    @Published var currentPage: Int = 1
    @Published var totalPages: Int = 1
    @Published var isLoading: Bool = false       // full-screen spinner (no data yet)
    @Published var isRefreshing: Bool = false    // background refresh while data is showing
    @Published var errorMessage: String? = nil
    @Published var season: Int = currentFTCSeason()
    @Published var lastUpdated: Date? = nil
    @Published var isResorting: Bool = false

    let pageSize: Int = 100
    private let db = Firestore.firestore()

    // Guard against duplicate initLoad() calls (LaunchView calls it; if
    // RankingsView's onAppear ever races us, this keeps things idempotent).
    private var hasInitialized = false

    // MARK: - Public load API

    /// Called once at app launch by LaunchView. Loads cache into the VM
    /// synchronously, then kicks off a Firestore refresh in the background.
    func initLoad() {
        guard !hasInitialized else { return }
        hasInitialized = true
        loadFromCache()
        Task { await fetchTeams(for: season) }
    }

    /// Force-refresh the current season from Firestore.
    func refresh() {
        Task { await fetchTeams(for: season) }
    }

    /// Switch seasons. Pulls cache for the new season immediately, then refreshes.
    func changeSeason(to newSeason: Int) {
        guard newSeason != season else { return }
        season = newSeason
        loadFromCache()
        Task { await fetchTeams(for: newSeason) }
    }

    // MARK: - Pagination

    func goToNextPage() {
        guard currentPage < totalPages else { return }
        currentPage += 1
        updateCurrentPage()
    }
    func goToPreviousPage() {
        guard currentPage > 1 else { return }
        currentPage -= 1
        updateCurrentPage()
    }
    func goToFirstPage() {
        guard currentPage != 1 else { return }
        currentPage = 1
        updateCurrentPage()
    }
    func goToLastPage() {
        guard currentPage != totalPages else { return }
        currentPage = totalPages
        updateCurrentPage()
    }
    func goToPage(_ page: Int) {
        guard page >= 1 && page <= totalPages else { return }
        currentPage = page
        updateCurrentPage()
    }

    // MARK: - Cache handling

    private func loadFromCache() {
        if let snapshot = RankingsCache.shared.load(for: season) {
            allTeams = snapshot.teams
            lastUpdated = Date()
            errorMessage = nil
            isLoading = false
            applySortAndPage()
        } else {
            // No cache for this season yet — full-screen spinner until fetch lands.
            allTeams = []
            filteredTeams = []
            currentPageTeams = []
            lastUpdated = nil
            isLoading = true
        }
    }

    // MARK: - Network fetch

    private func fetchTeams(for fetchSeason: Int) async {
        // If we already have data on screen, treat this as a soft refresh
        // (don't blank the list out).
        if allTeams.isEmpty {
            isLoading = true
        } else {
            isRefreshing = true
        }
        errorMessage = nil

        do {
            let snapshot = try await db
                .collection("seasons")
                .document(String(fetchSeason))
                .collection("teams")
                .order(by: "oprRank", descending: false)
                .getDocuments()

            // User may have switched seasons mid-fetch — bail out if so.
            guard fetchSeason == self.season else {
                isLoading = false
                isRefreshing = false
                return
            }

            let teams = snapshot.documents.map { TeamRanking(from: $0) }
            allTeams = teams

            RankingsCache.shared.save(teams: teams, for: fetchSeason)
            lastUpdated = Date()

            applySortAndPage()
        } catch {
            if allTeams.isEmpty {
                errorMessage = "Failed to load rankings: " + error.localizedDescription
            }
        }

        isLoading = false
        isRefreshing = false
    }

    // MARK: - Sorting / filtering / paging

    private func applySortAndPage() {
        isResorting = true
        allTeams.sort {
            sortField.rankValue(for: $0) <
            sortField.rankValue(for: $1)
        }
        currentPage = 1
        
        currentPageTeams = []
        
        Task { @MainActor in
                try? await Task.sleep(nanoseconds: 220_000_000) 
                applyFilterAndPage()
                isResorting = false
            }
    }

    private func applyFilterAndPage() {
        if searchQuery.trimmingCharacters(in: .whitespaces).isEmpty {
            filteredTeams = allTeams
        } else {
            let q = searchQuery.lowercased()
            filteredTeams = allTeams.filter { team in
                team.nameShort.lowercased().contains(q) ||
                String(team.teamNumber).contains(q) ||
                team.city.lowercased().contains(q) ||
                team.stateProv.lowercased().contains(q)
            }
        }

        totalPages = max(
            1,
            Int(ceil(Double(filteredTeams.count) / Double(pageSize)))
        )
        if currentPage > totalPages { currentPage = totalPages }
        updateCurrentPage()
    }

    private func updateCurrentPage() {
        let start = (currentPage - 1) * pageSize
        let end = min(start + pageSize, filteredTeams.count)
        guard start < filteredTeams.count else {
            currentPageTeams = []
            return
        }
        currentPageTeams = Array(filteredTeams[start..<end])
    }

    var filteredTeamCount: Int { filteredTeams.count }
    var totalTeamCount: Int { allTeams.count }
    var isSearching: Bool {
        !searchQuery.trimmingCharacters(in: .whitespaces).isEmpty
    }
}

private func currentFTCSeason() -> Int {
    let cal = Calendar.current
    let now = Date()
    let year = cal.component(.year, from: now)
    let month = cal.component(.month, from: now)
    return month >= 9 ? year : year - 1
}
