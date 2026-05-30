import SwiftUI

// MARK: - Rankings View

struct RankingsView: View {
    @Environment(\.nexusTheme) var t
    @EnvironmentObject var vm: RankingsViewModel

    @State private var selectedTeam: TeamRanking? = nil
    @State private var pageInputText: String = ""
    @State private var curSeason: Int = 2025
    @FocusState private var pageInputFocused: Bool

    @State private var lastUpdatedLabel: String = ""
    @State private var displayTimer: Timer? = nil

    private static let relativeFormatter: RelativeDateTimeFormatter = {
        let f = RelativeDateTimeFormatter()
        f.unitsStyle = .short
        return f
    }()

    private let seasons: [Int] = {
        let cal = Calendar.current
        let y = cal.component(.year, from: Date())
        let m = cal.component(.month, from: Date())
        let current = m >= 9 ? y : y - 1
        return Array((2019 ... current).reversed())
    }()

    var body: some View {
        ZStack {
            t.bg.ignoresSafeArea()
            VStack(spacing: 0) {
                headerSection
                sortPills
                Divider().background(t.divider)
                contentArea
                if !vm.isLoading && vm.totalPages > 1 {
                    Divider().background(t.divider)
                    paginationBar
                }
            }
        }
        .onAppear {
            vm.initLoad()
            startDisplayTimer()
        }
        .sheet(item: $selectedTeam) { team in
            TeamDetailSheet(season: $curSeason, team: team)
                .environment(\.nexusTheme, t)
        }
        .onChange(of: vm.lastUpdated) { _ in
            startDisplayTimer()
        }
        .onDisappear {
            displayTimer?.invalidate()
            displayTimer = nil
        }
    }

    // MARK: - Header

    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            // Top status row: last updated + refresh button
            HStack(spacing: 8) {
                HStack(spacing: 5) {
                    Image(systemName: "clock.arrow.circlepath")
                        .font(.system(size: 10, weight: .medium))
                    Text(lastUpdatedLabel)
                        .font(.system(size: 11, weight: .medium))
                }
                .foregroundColor(t.textSubtle)

                Spacer()

                Button {
                    vm.refresh()
                } label: {
                    NeumorphicCard(
                        radius: 10,
                        padding: .init(top: 6, leading: 11, bottom: 6, trailing: 11)
                    ) {
                        HStack(spacing: 5) {
                            if vm.isRefreshing || vm.isLoading {
                                ProgressView()
                                    .scaleEffect(0.55)
                                    .frame(width: 11, height: 11)
                                    .tint(t.accent)
                            } else {
                                Image(systemName: "arrow.clockwise")
                                    .font(.system(size: 11, weight: .bold))
                                    .foregroundColor(t.accent)
                            }
                            Text(vm.isRefreshing ? "Refreshing" : "Refresh")
                                .font(.system(size: 11, weight: .bold))
                                .tracking(0.3)
                                .foregroundColor(t.accent)
                        }
                    }
                }
                .buttonStyle(.plain)
                .disabled(vm.isLoading || vm.isRefreshing)
                .opacity((vm.isLoading || vm.isRefreshing) ? 0.65 : 1.0)
                .animation(.easeInOut(duration: 0.2), value: vm.isRefreshing)
                .animation(.easeInOut(duration: 0.2), value: vm.isLoading)
            }

            // Title row
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 3) {
                    Text("Rankings")
                        .font(.system(size: 28, weight: .black))
                        .foregroundColor(t.textPrimary)
                        .tracking(-0.6)
                    Text(verbatim:"\(seasonName(season:vm.season).uppercased()) · \(vm.season)")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(t.accent)
                        .tracking(0.4)
                }
                Spacer()
                Menu {
                    ForEach(seasons, id: \.self) { s in
                        Button("\(s, format: .number.grouping(.never))") {
                            vm.changeSeason(to: s)
                            curSeason = s
                        }
                    }
                } label: {
                    NeumorphicCard(radius: 12, padding: .init(
                        top: 8, leading: 12, bottom: 8, trailing: 12)
                    ) {
                        HStack(spacing: 5) {
                            Text(verbatim: "\(vm.season)")
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundColor(t.textSecondary)
                            Image(systemName: "chevron.up.chevron.down")
                                .font(.system(size: 10, weight: .medium))
                                .foregroundColor(t.textSubtle)
                        }
                    }
                }
            }

            // Search bar
            NeumorphicInset {
                HStack(spacing: 8) {
                    Image(systemName: "magnifyingglass")
                        .font(.system(size: 13))
                        .foregroundColor(t.textSubtle)
                    TextField("Search teams, numbers, cities…",
                              text: $vm.searchQuery)
                        .font(.system(size: 14))
                        .foregroundColor(t.textPrimary)
                        .tint(t.accent)
                        .autocorrectionDisabled()
                    if vm.isSearching {
                        Button {
                            vm.searchQuery = ""
                        } label: {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundColor(t.textSubtle)
                                .font(.system(size: 14))
                        }
                    }
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.top, 6)
        .padding(.bottom, 10)
        .onAppear {
            curSeason = vm.season
        }
    }

    // MARK: - Sort pills

    private var sortPills: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(RankingSortField.allCases, id: \.self) { field in
                    if(vm.season >= 2024) {
                        if(field != .endgame) {
                            NexusPill(
                                label: field.label.uppercased(),
                                isSelected: vm.sortField == field
                            ) {
                                withAnimation(.easeInOut(duration: 0.15)) {
                                    vm.sortField = field
                                }
                            }
                        }
                    } else {
                        NexusPill(
                            label: field.label.uppercased(),
                            isSelected: vm.sortField == field
                        ) {
                            withAnimation(.easeInOut(duration: 0.15)) {
                                vm.sortField = field
                            }
                        }
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
        }
    }

    // MARK: - Content

    @ViewBuilder
    private var contentArea: some View {
        if vm.isLoading {
            Spacer()
            ProgressView().tint(t.accent).scaleEffect(1.2)
            Text("Loading rankings…")
                .font(.system(size: 13))
                .foregroundColor(t.textSubtle)
                .padding(.top, 10)
            Spacer()
        } else if let error = vm.errorMessage {
            Spacer()
            VStack(spacing: 12) {
                Image(systemName: "exclamationmark.triangle")
                    .font(.system(size: 36))
                    .foregroundColor(t.loss)
                Text(error)
                    .font(.system(size: 13))
                    .foregroundColor(t.textSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
                Button("Retry") { vm.refresh() }
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(t.accent)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 10)
                    .background(Capsule().fill(t.accentMuted))
            }
            Spacer()
        } else if vm.currentPageTeams.isEmpty && !vm.isResorting {
            Spacer()
            VStack(spacing: 8) {
                Image(systemName: "magnifyingglass")
                    .font(.system(size: 32))
                    .foregroundColor(t.textSubtle)
                Text("No teams match \"\(vm.searchQuery)\"")
                    .font(.system(size: 14))
                    .foregroundColor(t.textSubtle)
            }
            Spacer()
        } else {
            ScrollView {
                LazyVStack(spacing: 0) {
                    ForEach(vm.currentPageTeams) { team in
                        RankRow(team: team, sortField: vm.sortField)
                            .contentShape(Rectangle())
                            .onTapGesture { selectedTeam = team }
                        Divider()
                            .background(t.divider)
                            .padding(.leading, 16)
                    }
                }
                .padding(.top, 4)
                .animation(.easeInOut(duration: 0.28), value: vm.currentPageTeams.map(\.id))
            }
            if vm.isSearching {
                Text("\(vm.filteredTeamCount) of \(vm.totalTeamCount) teams")
                    .font(.system(size: 11))
                    .foregroundColor(t.textSubtle)
                    .padding(.vertical, 6)
            }
        }
    }

    // MARK: - Pagination

    private var paginationBar: some View {
        HStack(spacing: 10) {
            pageButton(
                icon: "chevron.left.2",
                disabled: vm.currentPage <= 1
            ) {
                vm.goToFirstPage()
                pageInputText = ""
            }

            pageButton(
                icon: "chevron.left",
                disabled: vm.currentPage <= 1
            ) {
                vm.goToPreviousPage()
                pageInputText = ""
            }

            HStack(spacing: 6) {
                Text("PAGE")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundColor(t.textSubtle)
                    .tracking(0.5)

                NeumorphicInset(radius: 8) {
                    TextField("\(vm.currentPage)",
                              text: $pageInputText)
                        .focused($pageInputFocused)
                        .keyboardType(.numberPad)
                        .multilineTextAlignment(.center)
                        .font(.system(size: 13, weight: .semibold)
                                .monospacedDigit())
                        .foregroundColor(t.textPrimary)
                        .tint(t.accent)
                        .frame(width: 44, height: 18)
                        .onSubmit { jumpToTypedPage() }
                }
                .frame(width: 60)

                Text("of \(vm.totalPages)")
                    .font(.system(size: 12, weight: .medium)
                            .monospacedDigit())
                    .foregroundColor(t.textSecondary)
            }

            pageButton(
                icon: "chevron.right",
                disabled: vm.currentPage >= vm.totalPages
            ) {
                vm.goToNextPage()
                pageInputText = ""
            }

            pageButton(
                icon: "chevron.right.2",
                disabled: vm.currentPage >= vm.totalPages
            ) {
                vm.goToLastPage()
                pageInputText = ""
            }
        }
        .padding(.vertical, 12)
        .frame(maxWidth: .infinity)
        .background(t.bg)
        .onChange(of: pageInputFocused) { focused in
            if !focused {
                jumpToTypedPage()
            }
        }
    }

    private func pageButton(
        icon: String,
        disabled: Bool,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(disabled ? t.textSubtle : t.accent)
                .frame(width: 32, height: 32)
                .background(
                    Circle()
                        .fill(t.card)
                        .overlay(
                            Circle().strokeBorder(t.outline, lineWidth: 1)
                        )
                )
        }
        .disabled(disabled)
        .buttonStyle(.plain)
    }

    private func jumpToTypedPage() {
        guard let page = Int(pageInputText) else {
            pageInputText = ""
            return
        }
        vm.goToPage(page)
        pageInputText = ""
        pageInputFocused = false
    }

    // MARK: - Helpers

    private func seasonName(season:Int) -> String {
        switch(season) {
        case 2019: return "Skystone"
        case 2020: return "Ultimate Goal"
        case 2021: return "Freight Frenzy"
        case 2022: return "Power Play"
        case 2023: return "Centerstage"
        case 2024: return "Into the Deep"
        case 2025: return "Decode"
        default: return "Season Name"
        }
    }
    
    private func updateDisplayLabel() {
        guard let date = vm.lastUpdated else {
            lastUpdatedLabel = vm.isLoading ? "Updating…" : "Not yet updated"
            return
        }

        let elapsed = Date().timeIntervalSince(date)

        switch elapsed {
        case ..<10:
            lastUpdatedLabel = "Just updated"
        case 10..<60:
            lastUpdatedLabel = "Updated \(Int(elapsed))s ago"
        case 60..<3600:
            let mins = Int(elapsed / 60)
            lastUpdatedLabel = "Updated \(mins)m ago"
            rescheduleTimer(interval: 30)
        case 3600..<86400:
            let hrs = Int(elapsed / 3600)
            lastUpdatedLabel = "Updated \(hrs)h ago"
            rescheduleTimer(interval: 300)
        default:
            let days = Int(elapsed / 86400)
            lastUpdatedLabel = days == 1 ? "Updated yesterday" : "Updated \(days)d ago"
            rescheduleTimer(interval: 3600)
        }
    }

    private func rescheduleTimer(interval: TimeInterval) {
        guard let t = displayTimer, t.timeInterval != interval else { return }
        displayTimer?.invalidate()
        displayTimer = Timer.scheduledTimer(withTimeInterval: interval, repeats: true) { _ in
            updateDisplayLabel()
        }
    }
    
    private func startDisplayTimer() {
        updateDisplayLabel()
        displayTimer?.invalidate()
        displayTimer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
            updateDisplayLabel()
        }
    }
}

// MARK: - Rank Row

struct RankRow: View {
    @Environment(\.nexusTheme) var t
    let team: TeamRanking
    let sortField: RankingSortField

    private var rank: Int { sortField.rankValue(for: team) }
    private var value: Double { sortField.value(for: team) }

    private var rankColor: Color {
        switch rank {
        case 1: return t.gold
        case 2: return t.silver
        case 3: return t.bronze
        default: return t.textSubtle
        }
    }

    private var locationLine: String {
        [team.city, team.stateProv, team.country]
            .filter { !$0.isEmpty }
            .joined(separator: ", ")
    }

    var body: some View {
        HStack(spacing: 14) {
            Text("\(rank)")
                .font(
                    .system(
                        size: rank <= 3 ? 26 : 18,
                        weight: .black
                    ).monospacedDigit()
                )
                .foregroundColor(rankColor)
                .frame(width: 44, alignment: .leading)

            VStack(alignment: .leading, spacing: 3) {
                HStack(spacing: 8) {
                    Text(verbatim: "\(team.teamNumber)")
                        .font(.system(size: 17, weight: .black)
                                .monospacedDigit())
                        .foregroundColor(t.textPrimary)
                    Text(team.nameShort)
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(t.textPrimary)
                        .lineLimit(1)
                        .truncationMode(.tail)
                }

                if !locationLine.isEmpty {
                    Text(locationLine)
                        .font(.system(size: 11))
                        .foregroundColor(t.textSubtle)
                        .lineLimit(1)
                }

                if !team.oprEventCode.isEmpty &&
                   sortField != .avg {
                    HStack(spacing: 4) {
                        Image(systemName: "trophy.fill")
                            .font(.system(size: 8))
                            .foregroundColor(t.blue)
                        Text(team.oprEventCode)
                            .font(.system(size: 10, weight: .medium))
                            .foregroundColor(t.blue)
                            .lineLimit(1)
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            VStack(alignment: .trailing, spacing: 2) {
                Text(String(format: "%.1f", value))
                    .font(.system(size: 19, weight: .black)
                            .monospacedDigit())
                    .foregroundColor(t.accent)
                Text(sortField.label.uppercased())
                    .font(.system(size: 9, weight: .bold))
                    .tracking(0.5)
                    .foregroundColor(t.textSubtle)
            }
            .frame(width: 80, alignment: .trailing)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }
}

#Preview {
    RootView()
}
