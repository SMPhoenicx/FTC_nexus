//
//  TeamsView.swift
//  FTC Nexus
//
//  Created by Suman Muppavarapu on 5/11/26.
//


import SwiftUI

struct TeamsView: View {
    @Environment(\.nexusTheme) var t
    @StateObject private var vm = TeamsViewModel()
    @State private var showFilterSheet = false
    @State private var pageInputText: String = ""
    @FocusState private var pageInputFocused: Bool

    private let seasons: [Int] = {
        let cal = Calendar.current
        let y = cal.component(.year, from: Date())
        let m = cal.component(.month, from: Date())
        let cur = m >= 9 ? y : y - 1
        return Array((2019 ... cur).reversed())
    }()

    var body: some View {
        ZStack {
            t.bg.ignoresSafeArea()
            VStack(spacing: 0) {
                headerSection
                Divider().background(t.divider)
                contentArea
                if !vm.isLoading && vm.totalPages > 1 {
                    Divider().background(t.divider)
                    paginationBar
                }
            }
        }
        .onAppear { vm.initLoad() }
        .sheet(isPresented: $showFilterSheet) {
            TeamsFilterSheet(vm: vm)
        }
        .navigationBarBackButtonHidden(true)
        .toolbar(.hidden, for: .navigationBar)
    }

    // MARK: - Header

    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 3) {
                    Text("Teams")
                        .font(.system(size: 28, weight: .black))
                        .foregroundColor(t.textPrimary)
                        .tracking(-0.6)
                    Text(verbatim: "\(vm.totalTeamCount) TEAMS · \(vm.season)")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(t.accent)
                        .tracking(0.4)
                }
                Spacer()
                Menu {
                    ForEach(seasons, id: \.self) { s in
                        Button("\(s, format: .number.grouping(.never))") {
                            vm.changeSeason(to: s)
                        }
                    }
                } label: {
                    NeumorphicCard(radius: 12, padding: .init(top: 8, leading: 12, bottom: 8, trailing: 12)) {
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

            // Search + filter
            HStack(spacing: 8) {
                NeumorphicInset {
                    HStack(spacing: 8) {
                        Image(systemName: "magnifyingglass")
                            .font(.system(size: 13))
                            .foregroundColor(t.textSubtle)
                        TextField("Search teams, numbers, cities…", text: $vm.searchQuery)
                            .font(.system(size: 14))
                            .foregroundColor(t.textPrimary)
                            .tint(t.accent)
                            .autocorrectionDisabled()
                        if vm.isSearching {
                            Button { vm.searchQuery = "" } label: {
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundColor(t.textSubtle)
                                    .font(.system(size: 14))
                            }
                        }
                    }
                }
                Button { showFilterSheet = true } label: {
                    NeumorphicCard(radius: 12, padding: .init(top: 9, leading: 11, bottom: 9, trailing: 11)) {
                        ZStack(alignment: .topTrailing) {
                            Image(systemName: "line.3.horizontal.decrease")
                                .font(.system(size: 15, weight: .medium))
                                .foregroundColor(vm.hasActiveFilters ? t.accent : t.textSubtle)
                            if vm.hasActiveFilters {
                                Circle().fill(t.accent)
                                    .frame(width: 7, height: 7)
                                    .offset(x: 3, y: -3)
                            }
                        }
                    }
                }
                .buttonStyle(.plain)
            }

            if let region = vm.filterRegion {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 6) {
                        ActiveFilterPill(label: region) { vm.filterRegion = nil }
                        Button { vm.clearAllFilters() } label: {
                            Text("Clear all")
                                .font(.system(size: 11, weight: .semibold))
                                .foregroundColor(t.accent)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 5)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.top, 6)
        .padding(.bottom, 10)
    }

    // MARK: - Content
    @ViewBuilder
    private var contentArea: some View {
        if vm.isLoading {
            Spacer()
            ProgressView().tint(t.accent).scaleEffect(1.2)
            Text("Loading teams…")
                .font(.system(size: 13))
                .foregroundColor(t.textSubtle)
                .padding(.top, 10)
            Spacer()
        } else if let error = vm.errorMessage, vm.allTeams.isEmpty {
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
                Button("Retry") { Task { await vm.refresh() } }
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(t.accent)
                    .padding(.horizontal, 24).padding(.vertical, 10)
                    .background(Capsule().fill(t.accentMuted))
            }
            Spacer()
        } else if vm.currentPageTeams.isEmpty {
            Spacer()
            VStack(spacing: 8) {
                Image(systemName: "magnifyingglass")
                    .font(.system(size: 32))
                    .foregroundColor(t.textSubtle)
                Text(vm.isSearching || vm.hasActiveFilters
                     ? "No teams match your search"
                     : "No teams found")
                    .font(.system(size: 14))
                    .foregroundColor(t.textSubtle)
            }
            Spacer()
        } else {
            ScrollView {
                LazyVStack(spacing: 0) {
                    ForEach(vm.currentPageTeams) { team in
                        NavigationLink(value: team) {
                            TeamListRow(team: team)
                        }
                        .buttonStyle(.plain)
                        Divider().background(t.divider).padding(.leading, 16)
                    }
                }
                .padding(.top, 4)
            }
            .navigationDestination(for: TeamInfo.self) { team in
                TeamHomeView(team: team, season: vm.season)
            }
            if vm.isSearching || vm.hasActiveFilters {
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
            pageButton(icon: "chevron.left.2", disabled: vm.currentPage <= 1) {
                vm.goToFirstPage(); pageInputText = ""
            }
            pageButton(icon: "chevron.left", disabled: vm.currentPage <= 1) {
                vm.goToPreviousPage(); pageInputText = ""
            }
            HStack(spacing: 6) {
                Text("PAGE")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundColor(t.textSubtle).tracking(0.5)
                NeumorphicInset(radius: 8) {
                    TextField("\(vm.currentPage)", text: $pageInputText)
                        .focused($pageInputFocused)
                        .keyboardType(.numberPad)
                        .multilineTextAlignment(.center)
                        .font(.system(size: 13, weight: .semibold).monospacedDigit())
                        .foregroundColor(t.textPrimary)
                        .tint(t.accent)
                        .frame(width: 44, height: 18)
                        .onSubmit {
                            if let p = Int(pageInputText) { vm.goToPage(p) }
                            pageInputText = ""; pageInputFocused = false
                        }
                }
                .frame(width: 60)
                Text("of \(vm.totalPages)")
                    .font(.system(size: 12, weight: .medium).monospacedDigit())
                    .foregroundColor(t.textSecondary)
            }
            pageButton(icon: "chevron.right", disabled: vm.currentPage >= vm.totalPages) {
                vm.goToNextPage(); pageInputText = ""
            }
            pageButton(icon: "chevron.right.2", disabled: vm.currentPage >= vm.totalPages) {
                vm.goToLastPage(); pageInputText = ""
            }
        }
        .padding(.vertical, 12)
        .frame(maxWidth: .infinity)
        .background(t.bg)
    }

    private func pageButton(icon: String, disabled: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(disabled ? t.textSubtle : t.accent)
                .frame(width: 32, height: 32)
                .background(
                    Circle().fill(t.card)
                        .overlay(Circle().strokeBorder(t.outline, lineWidth: 1))
                )
        }
        .disabled(disabled)
        .buttonStyle(.plain)
    }
}

// MARK: - Row

struct TeamListRow: View {
    @Environment(\.nexusTheme) var t
    let team: TeamInfo

    var body: some View {
        HStack(spacing: 14) {
            Text(verbatim: "\(team.teamNumber)")
                .font(.system(size: 18, weight: .black).monospacedDigit())
                .foregroundColor(t.textPrimary)
                .frame(width: 64, alignment: .leading)

            VStack(alignment: .leading, spacing: 3) {
                Text(team.nameShort ?? team.nameFull ?? "—")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(t.textPrimary)
                    .lineLimit(1)
                if !team.locationString.isEmpty {
                    Text(team.locationString)
                        .font(.system(size: 11))
                        .foregroundColor(t.textSubtle)
                        .lineLimit(1)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            if let yr = team.rookieYear, yr > 0 {
                VStack(spacing: 1) {
                    Text("\(yr, format: .number.grouping(.never))")
                        .font(.system(size: 11, weight: .bold).monospacedDigit())
                        .foregroundColor(t.textSecondary)
                    Text("ROOKIE")
                        .font(.system(size: 8, weight: .bold))
                        .tracking(0.4)
                        .foregroundColor(t.textSubtle)
                }
            }

            Image(systemName: "chevron.right")
                .font(.system(size: 11, weight: .semibold))
                .foregroundColor(t.textSubtle)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 11)
        .contentShape(Rectangle())
    }
}

// MARK: - Filter sheet

struct TeamsFilterSheet: View {
    @Environment(\.nexusTheme) var t
    @ObservedObject var vm: TeamsViewModel
    @Environment(\.dismiss) var dismiss

    var body: some View {
        NavigationStack {
            ZStack {
                t.sheetBg.ignoresSafeArea()
                ScrollView {
                    VStack(alignment: .leading, spacing: 24) {
                        VStack(alignment: .leading, spacing: 10) {
                            Text("REGION")
                                .font(.system(size: 10, weight: .bold))
                                .tracking(0.8)
                                .foregroundColor(t.textSubtle)
                            FlowLayout(spacing: 8) {
                                ForEach(TeamsViewModel.regions, id: \.self) { r in
                                    NexusPill(label: r.uppercased(),
                                              isSelected: vm.filterRegion == r) {
                                        vm.filterRegion = vm.filterRegion == r ? nil : r
                                    }
                                }
                            }
                        }
                    }
                    .padding(16)
                }
            }
            .navigationTitle("Filters")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Clear") { vm.clearAllFilters() }
                        .foregroundColor(t.accent)
                        .disabled(!vm.hasActiveFilters)
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { dismiss() }
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(t.accent)
                }
            }
        }
    }
}

#Preview {
    RootView()
}
