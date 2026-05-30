//
//  TeamHomeView.swift
//  FTC Nexus
//
//  Created by Suman Muppavarapu on 5/11/26.
//


import SwiftUI
import FirebaseFirestore

struct TeamHomeView: View {
    @Environment(\.nexusTheme) var t
    @Environment(\.dismiss) var dismiss
    let team: TeamInfo
    @State var season: Int

    @State private var ranking: TeamRanking? = nil
    @State private var detailedInfo: TeamInfo? = nil
    @State private var isLoading = true
    @State private var errorMessage: String? = nil

    private let seasons: [Int] = {
        let cal = Calendar.current
        let y = cal.component(.year, from: Date())
        let m = cal.component(.month, from: Date())
        let cur = m >= 9 ? y : y - 1
        return Array((2019 ... cur).reversed())
    }()

    private var displayTeam: TeamInfo { detailedInfo ?? team }

    var body: some View {
        ZStack {
            t.bg.ignoresSafeArea()
            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    headerSection
                        .padding(.horizontal, 16)
                        .padding(.top, 12)

                    seasonPickerRow
                        .padding(.horizontal, 16)
                        .padding(.top, 14)

                    oprSection
                        .padding(.horizontal, 16)
                        .padding(.top, 18)

                    eventsPlaceholder
                        .padding(.horizontal, 16)
                        .padding(.top, 24)

                    matchesPlaceholder
                        .padding(.horizontal, 16)
                        .padding(.top, 18)
                        .padding(.bottom, 40)
                }
            }
        }
        .navigationTitle("\(displayTeam.teamNumber)")
        .navigationBarTitleDisplayMode(.inline)
        .task(id: season) { await loadAll() }
    }

    // MARK: - Header

    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(verbatim: "\(displayTeam.teamNumber)")
                .font(.system(size: 44, weight: .black).monospacedDigit())
                .foregroundColor(t.accent)
                .tracking(-1.2)
            Text(displayTeam.nameShort ?? displayTeam.nameFull ?? "—")
                .font(.system(size: 20, weight: .bold))
                .foregroundColor(t.textPrimary)
            if !displayTeam.locationString.isEmpty {
                Label(displayTeam.locationString, systemImage: "mappin.and.ellipse")
                    .font(.system(size: 12))
                    .foregroundColor(t.textSubtle)
            }
            HStack(spacing: 10) {
                if let yr = displayTeam.rookieYear, yr > 0 {
                    badge(label: "ROOKIE", value: "\(yr)")
                }
                if let site = displayTeam.website,
                   !site.isEmpty,
                   let url = URL(string: normalizedURL(site)) {
                    Link(destination: url) {
                        HStack(spacing: 4) {
                            Image(systemName: "link")
                                .font(.system(size: 10, weight: .semibold))
                            Text(site)
                                .font(.system(size: 11, weight: .semibold))
                                .lineLimit(1)
                        }
                        .foregroundColor(t.blue)
                        .padding(.horizontal, 10).padding(.vertical, 5)
                        .background(Capsule().fill(t.blueMuted))
                    }
                }
            }
        }
    }

    private func badge(label: String, value: String) -> some View {
        HStack(spacing: 5) {
            Text(label)
                .font(.system(size: 9, weight: .bold))
                .tracking(0.5)
                .foregroundColor(t.textSubtle)
            Text(value)
                .font(.system(size: 11, weight: .bold).monospacedDigit())
                .foregroundColor(t.textSecondary)
        }
        .padding(.horizontal, 10).padding(.vertical, 5)
        .background(Capsule().fill(t.card).overlay(Capsule().strokeBorder(t.outline, lineWidth: 1)))
    }

    // MARK: - Season picker

    private var seasonPickerRow: some View {
        HStack {
            Text("SEASON")
                .font(.system(size: 10, weight: .bold))
                .tracking(0.8)
                .foregroundColor(t.textSubtle)
            Spacer()
            Menu {
                ForEach(seasons, id: \.self) { s in
                    Button("\(s, format: .number.grouping(.never))") { season = s }
                }
            } label: {
                NeumorphicCard(radius: 12, padding: .init(top: 8, leading: 12, bottom: 8, trailing: 12)) {
                    HStack(spacing: 5) {
                        Text(verbatim: "\(season)")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(t.textSecondary)
                        Image(systemName: "chevron.up.chevron.down")
                            .font(.system(size: 10, weight: .medium))
                            .foregroundColor(t.textSubtle)
                    }
                }
            }
        }
    }

    // MARK: - OPR section

    @ViewBuilder
    private var oprSection: some View {
        let showEndgame = season < 2024

        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("OPR")
                    .font(.system(size: 10, weight: .bold))
                    .tracking(0.8)
                    .foregroundColor(t.textSubtle)
                Spacer()
                if let r = ranking, !r.oprEventCode.isEmpty {
                    HStack(spacing: 4) {
                        Image(systemName: "trophy.fill")
                            .font(.system(size: 9))
                        Text("Best at \(r.oprEventCode)")
                            .font(.system(size: 10, weight: .semibold))
                    }
                    .foregroundColor(t.blue)
                }
            }

            if isLoading {
                NeumorphicCard {
                    HStack {
                        ProgressView().tint(t.accent).scaleEffect(0.8)
                        Text("Loading OPRs…")
                            .font(.system(size: 12))
                            .foregroundColor(t.textSubtle)
                            .padding(.leading, 6)
                        Spacer()
                    }
                }
            } else if let r = ranking {
                LazyVGrid(
                    columns: [GridItem(.flexible()), GridItem(.flexible())],
                    spacing: 12
                ) {
                    oprCard(label: "OPR",    value: r.opr,        rank: r.oprRank)
                    oprCard(label: "Auto",   value: r.autoOpr,    rank: r.autoOprRank)
                    oprCard(label: "Teleop", value: r.teleopOpr,  rank: r.teleopOprRank)
                    if showEndgame {
                        oprCard(label: "Endgame", value: r.endgameOpr, rank: r.endgameOprRank)
                    }
                }
            } else {
                NeumorphicCard {
                    HStack {
                        Image(systemName: "questionmark.circle")
                            .foregroundColor(t.textSubtle)
                        Text("No OPR data for \(season)")
                            .font(.system(size: 12))
                            .foregroundColor(t.textSubtle)
                        Spacer()
                    }
                }
            }
        }
    }

    private func oprCard(label: String, value: Double, rank: Int) -> some View {
        NeumorphicCard(radius: 16, padding: .init(top: 14, leading: 16, bottom: 14, trailing: 16)) {
            VStack(alignment: .leading, spacing: 5) {
                HStack(alignment: .firstTextBaseline, spacing: 6) {
                    Text(String(format: "%.1f", value))
                        .font(.system(size: 26, weight: .black).monospacedDigit())
                        .foregroundColor(t.textPrimary)
                    Text("#\(rank)")
                        .font(.system(size: 12, weight: .bold).monospacedDigit())
                        .foregroundColor(t.accent)
                }
                Text(label)
                    .font(.system(size: 11, weight: .bold))
                    .tracking(0.3)
                    .foregroundColor(t.accent)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    // MARK: - Placeholders for next iteration

    private var eventsPlaceholder: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("EVENTS")
                .font(.system(size: 10, weight: .bold))
                .tracking(0.8)
                .foregroundColor(t.textSubtle)
            NeumorphicCard {
                HStack {
                    Image(systemName: "calendar")
                        .foregroundColor(t.textSubtle)
                    Text("Events the team played in (coming soon)")
                        .font(.system(size: 13))
                        .foregroundColor(t.textSubtle)
                    Spacer()
                }
            }
        }
    }

    private var matchesPlaceholder: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("MATCHES")
                .font(.system(size: 10, weight: .bold))
                .tracking(0.8)
                .foregroundColor(t.textSubtle)
            NeumorphicCard {
                HStack {
                    Image(systemName: "list.bullet.rectangle")
                        .foregroundColor(t.textSubtle)
                    Text("Match breakdowns (coming soon)")
                        .font(.system(size: 13))
                        .foregroundColor(t.textSubtle)
                    Spacer()
                }
            }
        }
    }

    // MARK: - Loading

    private func loadAll() async {
        isLoading = true
        errorMessage = nil
        async let r = loadRanking()
        async let d = loadDetailedTeam()
        _ = await (r, d)
        isLoading = false
    }

    @MainActor
    private func loadRanking() async {
        let db = Firestore.firestore()
        do {
            let snap = try await db
                .collection("seasons")
                .document(String(season))
                .collection("teams")
                .document(String(team.teamNumber))
                .getDocument()
            if snap.exists {
                ranking = TeamRanking(from: snap)
            } else {
                ranking = nil
            }
        } catch {
            ranking = nil
        }
    }

    @MainActor
    private func loadDetailedTeam() async {
        let api = APIReceiver(
            username: "blitzomen",
            apiKey: "6C8EC18F-253B-4ED9-91A3-1D5E0A3347CD"
        )
        do {
            let listings = try await api.getTeams(season: season, teamNumber: team.teamNumber)
            if let first = listings.teams?.first {
                detailedInfo = first.toTeamInfo()
            }
        } catch {
            // keep the list-level info we already have
        }
    }

    private func normalizedURL(_ s: String) -> String {
        if s.hasPrefix("http") { return s }
        return "https://\(s)"
    }
}