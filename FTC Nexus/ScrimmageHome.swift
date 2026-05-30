// ScrimmageHomeView.swift
import SwiftUI

struct ScrimmageHomeView: View {
    @Environment(\.nexusTheme) var t
    @State private var showFreePractice = false

    //TODO: Placeholder past scrimmages — wire to your real data model later
    private let pastScrimmages: [PastScrimmageStub] = [
        .init(name: "SJS Spring Scrimmage", date: "Apr 28, 2026", teams: 8, matches: 12),
        .init(name: "Robotics Club Internal", date: "Apr 12, 2026", teams: 4, matches: 6),
        .init(name: "Pre-Season Practice", date: "Mar 5, 2026", teams: 6, matches: 8),
    ]

    var body: some View {
        ZStack {
            t.bg.ignoresSafeArea()
            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    headerSection
                    quickActionCards
                    if !pastScrimmages.isEmpty {
                        SectionHeader(label: "PAST SCRIMMAGES")
                        ForEach(pastScrimmages) { s in
                            PastScrimmageRow(scrimmage: s)
                            Divider().background(t.divider).padding(.leading, 16)
                        }
                    }
                    Spacer(minLength: 40)
                }
            }
        }
        .fullScreenCover(isPresented: $showFreePractice) {
            FreePracticeView()
                .environment(\.nexusTheme, t)
        }
    }

    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 3) {
            Text("Scrimmage")
                .font(.system(size: 28, weight: .black))
                .foregroundColor(t.textPrimary)
                .tracking(-0.6)
            Text("DECODE 2025")
                .font(.system(size: 11, weight: .bold))
                .foregroundColor(t.accent)
                .tracking(0.4)
        }
        .padding(.horizontal, 16)
        .padding(.top, 6)
        .padding(.bottom, 16)
    }

    private var quickActionCards: some View {
        VStack(spacing: 12) {
            // Free Practice — primary action
            Button { showFreePractice = true } label: {
                NeumorphicCard(radius: 16) {
                    HStack(spacing: 14) {
                        ZStack {
                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                .fill(t.accent)
                                .frame(width: 48, height: 48)
                            Image(systemName: "play.fill")
                                .font(.system(size: 18, weight: .bold))
                                .foregroundColor(.white)
                        }
                        VStack(alignment: .leading, spacing: 3) {
                            Text("Free Practice")
                                .font(.system(size: 16, weight: .bold))
                                .foregroundColor(t.textPrimary)
                            Text("Solo run · randomized motif · full 2:30 timer")
                                .font(.system(size: 12))
                                .foregroundColor(t.textSubtle)
                                .lineLimit(1)
                        }
                        Spacer()
                        Image(systemName: "chevron.right")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(t.textSubtle)
                    }
                }
            }
            .buttonStyle(.plain)

            // New Scrimmage — secondary action
            Button { /* TODO: navigate to scrimmage setup */ } label: {
                NeumorphicCard(radius: 16) {
                    HStack(spacing: 14) {
                        ZStack {
                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                .strokeBorder(t.accent, lineWidth: 1.5)
                                .background(
                                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                                        .fill(t.accentMuted)
                                )
                                .frame(width: 48, height: 48)
                            Image(systemName: "plus")
                                .font(.system(size: 20, weight: .bold))
                                .foregroundColor(t.accent)
                        }
                        VStack(alignment: .leading, spacing: 3) {
                            Text("New Scrimmage")
                                .font(.system(size: 16, weight: .bold))
                                .foregroundColor(t.accent)
                            Text("Set up teams, schedule matches")
                                .font(.system(size: 12))
                                .foregroundColor(t.textSubtle)
                                .lineLimit(1)
                        }
                        Spacer()
                        Image(systemName: "chevron.right")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(t.textSubtle)
                    }
                }
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 16)
        .padding(.bottom, 8)
    }
}

// MARK: - Past Scrimmage Row

struct PastScrimmageStub: Identifiable {
    let id = UUID()
    let name: String
    let date: String
    let teams: Int
    let matches: Int
}

struct PastScrimmageRow: View {
    @Environment(\.nexusTheme) var t
    let scrimmage: PastScrimmageStub

    var body: some View {
        HStack(spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(t.card)
                    .overlay(
                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                            .strokeBorder(t.outline, lineWidth: 1)
                    )
                    .frame(width: 38, height: 38)
                Image(systemName: "calendar")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(t.textSubtle)
            }
            VStack(alignment: .leading, spacing: 3) {
                Text(scrimmage.name)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(t.textPrimary)
                    .lineLimit(1)
                HStack(spacing: 6) {
                    Text(scrimmage.date)
                    Text("·").foregroundColor(t.textSubtle)
                    Text("\(scrimmage.teams) teams")
                    Text("·").foregroundColor(t.textSubtle)
                    Text("\(scrimmage.matches) matches")
                }
                .font(.system(size: 11))
                .foregroundColor(t.textSubtle)
            }
            Spacer()
            Image(systemName: "chevron.right")
                .font(.system(size: 11, weight: .semibold))
                .foregroundColor(t.textSubtle)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 11)
        .contentShape(Rectangle())
    }
}

#Preview("Dark") {
    ScrimmageHomeView()
        .environment(\.nexusTheme, NexusTheme(isDark: true))
        .preferredColorScheme(.dark)
}

#Preview("Light") {
    ScrimmageHomeView()
        .environment(\.nexusTheme, NexusTheme(isDark: false))
        .preferredColorScheme(.light)
}
