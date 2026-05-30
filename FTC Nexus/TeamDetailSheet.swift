//
//  TeamDetailSheet.swift
//  FTC Nexus
//

import SwiftUI

struct TeamDetailSheet: View {
    @Environment(\.nexusTheme) var t
    @Environment(\.dismiss) var dismiss
    @Binding var season: Int
    let team: TeamRanking

    var body: some View {
        ZStack {
            t.sheetBg.ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    headerSection
                        .padding(.horizontal, 20)
                        .padding(.top, 28)
                        .padding(.bottom, 22)

                    Divider().background(t.divider).padding(.horizontal, 20)

                    oprGrid
                        .padding(.horizontal, 14)
                        .padding(.top, 20)

                    recordSection
                        .padding(.horizontal, 20)
                        .padding(.top, 22)

                    scoreBreakdownSection
                        .padding(.horizontal, 20)
                        .padding(.top, 22)

                    Button {
                        dismiss()
                    } label: {
                        Text("Done")
                            .font(.system(size: 15, weight: .bold))
                            .foregroundColor(t.accent)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(
                                RoundedRectangle(cornerRadius: 14, style: .continuous)
                                    .fill(t.accentMuted)
                            )
                    }
                    .buttonStyle(.plain)
                    .padding(.horizontal, 20)
                    .padding(.top, 28)
                    .padding(.bottom, 40)
                }
            }
        }
        .presentationDetents([.large])
        .presentationDragIndicator(.visible)
        .presentationBackground(t.sheetBg)
    }

    // MARK: - Header

    private var headerSection: some View {
        HStack(alignment: .top, spacing: 0) {
            VStack(alignment: .leading, spacing: 6) {
                Text(verbatim: "\(team.teamNumber)")
                    .font(.system(size: 46, weight: .black).monospacedDigit())
                    .foregroundColor(t.accent)
                    .tracking(-1.5)
                    .lineLimit(1)

                Text(team.nameShort)
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(t.textPrimary)

                let loc = [team.city, team.stateProv, team.country]
                    .filter { !$0.isEmpty }
                    .joined(separator: ", ")
                if !loc.isEmpty {
                    Label(loc, systemImage: "mappin.and.ellipse")
                        .font(.system(size: 12))
                        .foregroundColor(t.textSubtle)
                }

                if !team.oprEventCode.isEmpty {
                    HStack(spacing: 5) {
                        Image(systemName: "trophy.fill")
                            .font(.system(size: 10))
                            .foregroundColor(t.blue)
                        Text("Best OPR at \(team.oprEventCode)")
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundColor(t.blue)
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(
                        Capsule()
                            .fill(t.blueMuted)
                            .overlay(
                                Capsule().strokeBorder(
                                    t.blue.opacity(0.25), lineWidth: 1
                                )
                            )
                    )
                    .padding(.top, 2)
                }
            }

            Spacer(minLength: 12)

            VStack(alignment: .trailing, spacing: 8) {
                // Rookie year
                if team.rookieYear > 0 {
                    VStack(spacing: 2) {
                        Text("ROOKIE")
                            .font(.system(size: 8, weight: .bold))
                            .tracking(0.8)
                            .foregroundColor(t.textSubtle)
                        Text(verbatim: "\(team.rookieYear)")
                            .font(.system(size: 20, weight: .black).monospacedDigit())
                            .foregroundColor(t.textSecondary)
                    }
                }
                // Events played
                VStack(spacing: 2) {
                    Text(verbatim: "\(team.eventsPlayed)")
                        .font(.system(size: 20, weight: .black).monospacedDigit())
                        .foregroundColor(t.textSecondary)
                    Text("EVENTS")
                        .font(.system(size: 8, weight: .bold))
                        .tracking(0.8)
                        .foregroundColor(t.textSubtle)
                }
            }
            .padding(.top, 6)
        }
    }

    // MARK: - OPR 2×2 grid

    private var oprGrid: some View {
        let cards: [(label: String, value: Double, rank: Int, desc: String)] = season < 2024 ? [
            ("OPR",     team.opr,        team.oprRank,      "Offensive Power Rating"),
            ("Auto",    team.autoOpr,    team.autoOprRank,  "Autonomous phase"),
            ("Teleop",  team.teleopOpr,  team.teleopOprRank,"Driver-controlled"),
            ("Endgame", team.endgameOpr, team.endgameOprRank,"Endgame phase"),
        ]:[
            ("OPR",     team.opr,        team.oprRank,      "Offensive Power Rating"),
            ("Auto",    team.autoOpr,    team.autoOprRank,  "Autonomous phase"),
            ("Teleop",  team.teleopOpr,  team.teleopOprRank,"Driver-controlled")
        ]

        return LazyVGrid(
            columns: [GridItem(.flexible()), GridItem(.flexible())],
            spacing: 12
        ) {
            ForEach(cards, id: \.label) { card in
                NeumorphicCard(
                    radius: 16,
                    padding: .init(top: 14, leading: 16, bottom: 14, trailing: 16)
                ) {
                    VStack(alignment: .leading, spacing: 5) {
                        HStack(alignment: .firstTextBaseline, spacing: 6) {
                            Text(String(format: "%.1f", card.value))
                                .font(.system(size: 26, weight: .black).monospacedDigit())
                                .foregroundColor(t.textPrimary)
                            Text("#\(card.rank)")
                                .font(.system(size: 12, weight: .bold).monospacedDigit())
                                .foregroundColor(t.accent)
                        }
                        Text(card.label)
                            .font(.system(size: 11, weight: .bold))
                            .tracking(0.3)
                            .foregroundColor(t.accent)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
        }
    }

    // MARK: - Record (W / L / D)

    private var recordSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            DetailSectionHeader(title: "RECORD")

            NeumorphicCard(
                radius: 16,
                padding: .init(top: 16, leading: 20, bottom: 16, trailing: 20)
            ) {
                HStack(spacing: 0) {
                    RecordCell(
                        value: "\(team.wins)",
                        label: "W",
                        color: t.win
                    )
                    Spacer()
                    Rectangle()
                        .fill(t.divider)
                        .frame(width: 1, height: 40)
                    Spacer()
                    RecordCell(
                        value: "\(team.losses)",
                        label: "L",
                        color: team.losses > 0 ? t.loss : t.textSubtle
                    )
                    Spacer()
                    Rectangle()
                        .fill(t.divider)
                        .frame(width: 1, height: 40)
                    Spacer()
                    RecordCell(
                        value: "\(team.draws)",
                        label: "D",
                        color: t.tie
                    )
                }
                .frame(maxWidth: .infinity)
            }
        }
    }

    // MARK: - Score breakdown

    private var scoreBreakdownSection: some View {
        // Avg per match = summedScore / total matches played
        let totalMatches = team.wins + team.losses + team.draws
        let avgPerMatch: Double = totalMatches > 0
            ? Double(team.summedScore) / Double(totalMatches)
            : team.avgPoints

        let rows: [(name: String, avg: Double, total: Int, min: Int, max: Int)] = season < 2023 ? [
            (
                "Total Score",
                team.opr,
                team.summedScore,
                team.minScore,
                team.maxScore
            ),
            ("Auto OPR",    team.autoOpr, team.summedAutoScore, team.minAutoScore, team.maxAutoScore),
            ("Teleop OPR",  team.teleopOpr, team.summedTeleopScore, team.minTeleopScore, team.maxTeleopScore),
            ("Endgame OPR", team.endgameOpr, team.summedEndgameScore, team.minEndgameScore, team.maxEndgameScore)
        ]:[
            (
                "Total Score",
                team.opr,
                team.summedScore,
                team.minScore,
                team.maxScore
            ),
            ("Auto OPR",    team.autoOpr, team.summedAutoScore, team.minAutoScore, team.maxAutoScore),
            ("Teleop OPR",  team.teleopOpr, team.summedTeleopScore, team.minTeleopScore, team.maxTeleopScore)
        ]

        return VStack(alignment: .leading, spacing: 12) {
            DetailSectionHeader(title: "SCORE BREAKDOWN")

            // Headers
            HStack(spacing: 0) {
                Text("").frame(maxWidth: .infinity, alignment: .leading)
                ForEach(["OPR", "TOT", "MIN", "MAX"], id: \.self) { h in
                    Text(h)
                        .frame(width: 52, alignment: .trailing)
                }
            }
            .font(.system(size: 9, weight: .bold))
            .tracking(0.6)
            .foregroundColor(t.textSubtle)
            .padding(.horizontal, 4)

            Divider().background(t.divider)

            // Full score row — all values real
            ForEach(rows, id: \.name) { row in
                HStack(spacing: 0) {
                    Text(row.name)
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(t.textPrimary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    Text(String(format: "%.1f", row.avg))
                        .font(.system(size: 13, weight: .bold).monospacedDigit())
                        .foregroundColor(t.accent)
                        .frame(width: 52, alignment: .trailing)
                    Text("\(row.total)")
                        .font(.system(size: 13).monospacedDigit())
                        .foregroundColor(t.textPrimary)
                        .frame(width: 52, alignment: .trailing)
                    Text("\(row.min)")
                        .font(.system(size: 13).monospacedDigit())
                        .foregroundColor(t.textPrimary)
                        .frame(width: 52, alignment: .trailing)
                    Text("\(row.max)")
                        .font(.system(size: 13).monospacedDigit())
                        .foregroundColor(t.textPrimary)
                        .frame(width: 52, alignment: .trailing)
                }
                .padding(.vertical, 9)
                .padding(.horizontal, 4)
                Divider().background(t.divider)
            }

            // Avg points card
            NeumorphicCard(radius: 12, padding: .init(top: 12, leading: 14, bottom: 12, trailing: 14)) {
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("AVG MATCH SCORE")
                            .font(.system(size: 9, weight: .bold))
                            .tracking(0.7)
                            .foregroundColor(t.textSubtle)
                        Text(String(format: "%.1f", team.avgPoints))
                            .font(.system(size: 28, weight: .black).monospacedDigit())
                            .foregroundColor(t.textPrimary)
                    }
                    Spacer()
                    VStack(alignment: .trailing, spacing: 2) {
                        Text("RANK")
                            .font(.system(size: 9, weight: .bold))
                            .tracking(0.7)
                            .foregroundColor(t.textSubtle)
                        Text("#\(team.avgPointsRank)")
                            .font(.system(size: 28, weight: .black).monospacedDigit())
                            .foregroundColor(t.accent)
                    }
                }
                .frame(maxWidth: .infinity)
            }
            .padding(.top, 4)
        }
    }
}

// MARK: - Helpers

private struct DetailSectionHeader: View {
    @Environment(\.nexusTheme) var t
    let title: String
    var body: some View {
        Text(title)
            .font(.system(size: 10, weight: .bold))
            .tracking(0.8)
            .foregroundColor(t.textSubtle)
    }
}

private struct RecordCell: View {
    let value: String
    let label: String
    let color: Color
    var body: some View {
        VStack(spacing: 3) {
            Text(value)
                .font(.system(size: 32, weight: .black).monospacedDigit())
                .foregroundColor(color)
            Text(label)
                .font(.system(size: 10, weight: .bold))
                .tracking(0.5)
                .foregroundColor(color.opacity(0.65))
        }
    }
}
