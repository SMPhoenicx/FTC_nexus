//
//  TeamsViewModel.swift
//  FTC Nexus
//
//  Created by Suman Muppavarapu on 5/11/26.
//


import Foundation

@MainActor
class TeamsViewModel: ObservableObject {
    @Published var allTeams: [TeamInfo] = []
    @Published var filteredTeams: [TeamInfo] = []
    @Published var currentPageTeams: [TeamInfo] = []

    @Published var searchQuery: String = "" { didSet { applyFilterAndPage() } }
    @Published var filterRegion: String? = nil { didSet { applyFilterAndPage() } }

    @Published var currentPage: Int = 1
    @Published var totalPages: Int = 1
    @Published var isLoading: Bool = false
    @Published var isRefreshing: Bool = false
    @Published var errorMessage: String? = nil
    @Published var season: Int = currentFTCSeason()
    @Published var lastUpdated: Date? = nil

    let pageSize: Int = 100

    // Reuse same creds RankingsViewModel uses, or pull into a shared singleton later.
    private let api = APIReceiver(
        username: "blitzomen",
        apiKey: "6C8EC18F-253B-4ED9-91A3-1D5E0A3347CD"
    )

    static let regions: [String] = [
        "Alabama", "Alaska", "Arizona", "California", "Colorado",
        "Florida", "Georgia", "Illinois", "Michigan", "New York",
        "North Carolina", "Ohio", "Oregon", "Pennsylvania", "Texas",
        "Virginia", "Washington", "International"
    ]

    var hasActiveFilters: Bool { filterRegion != nil }
    var isSearching: Bool {
        !searchQuery.trimmingCharacters(in: .whitespaces).isEmpty
    }

    func initLoad() {
        if let snap = TeamsCache.shared.load(for: season) {
            allTeams = snap.teams
            lastUpdated = snap.lastUpdated
            applyFilterAndPage()
        }
        Task { await refresh() }
    }

    func changeSeason(to newSeason: Int) {
        guard newSeason != season else { return }
        season = newSeason
        allTeams = []
        currentPage = 1
        applyFilterAndPage()
        if let snap = TeamsCache.shared.load(for: season) {
            allTeams = snap.teams
            lastUpdated = snap.lastUpdated
            applyFilterAndPage()
        }
        Task { await refresh() }
    }

    func refresh() async {
        guard !isRefreshing else { return }
        isRefreshing = true
        if allTeams.isEmpty { isLoading = true }
        errorMessage = nil

        do {
            var collected: [TeamInfo] = []
            var page = 1
            while true {
                let listings = try await api.getTeams(season: season, page: page)
                let mapped = (listings.teams ?? []).compactMap { $0.toTeamInfo() }
                collected.append(contentsOf: mapped)
                let total = listings.pageTotal ?? 1
                if page >= total { break }
                page += 1
            }
            // Sort by team number ascending — that's the default "normal" view.
            collected.sort { $0.teamNumber < $1.teamNumber }
            allTeams = collected
            lastUpdated = Date()
            TeamsCache.shared.save(teams: collected, for: season)
            applyFilterAndPage()
        } catch {
            errorMessage = "Failed to load teams: \(error.localizedDescription)"
        }

        isLoading = false
        isRefreshing = false
    }

    func clearAllFilters() {
        filterRegion = nil
        searchQuery = ""
    }

    // MARK: - Pagination (client-side, same pattern as Rankings)
    func goToNextPage()     { guard currentPage < totalPages else { return }; currentPage += 1; updateCurrentPage() }
    func goToPreviousPage() { guard currentPage > 1 else { return }; currentPage -= 1; updateCurrentPage() }
    func goToFirstPage()    { guard currentPage != 1 else { return }; currentPage = 1; updateCurrentPage() }
    func goToLastPage()     { guard currentPage != totalPages else { return }; currentPage = totalPages; updateCurrentPage() }
    func goToPage(_ p: Int) { guard p >= 1 && p <= totalPages else { return }; currentPage = p; updateCurrentPage() }

    private func applyFilterAndPage() {
        var teams = allTeams

        let q = searchQuery.trimmingCharacters(in: .whitespaces).lowercased()
        if !q.isEmpty {
            teams = teams.filter {
                String($0.teamNumber).contains(q) ||
                ($0.nameShort?.lowercased().contains(q) ?? false) ||
                ($0.nameFull?.lowercased().contains(q) ?? false) ||
                ($0.city?.lowercased().contains(q) ?? false) ||
                ($0.stateProv?.lowercased().contains(q) ?? false)
            }
        }

        if let region = filterRegion {
            let r = region.lowercased()
            teams = teams.filter {
                let state = ($0.stateProv ?? "").lowercased()
                let country = ($0.country ?? "").lowercased()
                return state.contains(r)
                    || country.contains(r)
                    || (r == "international" && country != "usa")
            }
        }

        filteredTeams = teams
        totalPages = max(1, Int(ceil(Double(teams.count) / Double(pageSize))))
        if currentPage > totalPages { currentPage = totalPages }
        updateCurrentPage()
    }

    private func updateCurrentPage() {
        let start = (currentPage - 1) * pageSize
        let end = min(start + pageSize, filteredTeams.count)
        guard start < filteredTeams.count else { currentPageTeams = []; return }
        currentPageTeams = Array(filteredTeams[start..<end])
    }

    var filteredTeamCount: Int { filteredTeams.count }
    var totalTeamCount: Int { allTeams.count }
}

private func currentFTCSeason() -> Int {
    let cal = Calendar.current
    let now = Date()
    let year = cal.component(.year, from: now)
    let month = cal.component(.month, from: now)
    return month >= 9 ? year : year - 1
}