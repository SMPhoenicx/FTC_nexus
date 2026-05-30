//
//  NexusTab.swift
//  FTC Nexus
//
//  Created by Suman Muppavarapu on 5/1/26.
//

import SwiftUI

// MARK: - Tab definition

enum NexusTab: CaseIterable, Hashable {
    case rankings
    case events
    case scrimmage
    case messages
    case resources
    case teams

    var title: String {
        switch self {
        case .rankings:  return "Rankings"
        case .events:    return "Events"
        case .scrimmage: return "Scrimmage"
        case .messages:  return "Messages"
        case .resources: return "Resources"
        case .teams: return "Teams"
        }
    }

    var icon: String {
        switch self {
        case .rankings:  return "trophy"
        case .events:    return "calendar.circle"
        case .scrimmage: return "gamecontroller"
        case .messages:  return "bubble.left.and.bubble.right"
        case .resources: return "book"
        case .teams: return "person.3"
        }
    }

    var filledIcon: String { "\(icon).fill" }
}

// MARK: - Root container
// Use this as your top-level view instead of SwiftUI's TabView.
// Pass a ViewBuilder closure that maps each NexusTab to its screen.
//
// Example:
//   NexusTabContainer { tab in
//       switch tab {
//       case .rankings:  RankingsView()
//       case .events:    EventsView()
//       ...
//       }
//   }

struct NexusTabContainer<Content: View>: View {
    @Environment(\.nexusTheme) var t
    @State private var selected: NexusTab = .rankings
    @Namespace private var ns

    let content: (NexusTab) -> Content

    init(@ViewBuilder content: @escaping (NexusTab) -> Content) {
        self.content = content
    }

    var body: some View {
        ZStack(alignment: .bottom) {
            // Active screen — swap without animation for instant feel
            content(selected)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                // Push content up so it doesn't hide behind the tab bar
                .safeAreaInset(edge: .bottom) {
                    Color.clear.frame(height: 80)
                }

            NexusTabBar(selected: $selected, namespace: ns)
        }
        .ignoresSafeArea(edges: .bottom)
    }
}

// MARK: - Floating pill tab bar

struct NexusTabBar: View {
    @Environment(\.nexusTheme) var t
    @Binding var selected: NexusTab
    var namespace: Namespace.ID

    @State private var localSelected: NexusTab = .rankings

    var body: some View {
        HStack(spacing: 0) {
            ForEach(NexusTab.allCases, id: \.self) { tab in
                NexusTabItem(
                    tab: tab,
                    isSelected: localSelected == tab,
                    namespace: namespace
                ) {
                    withAnimation(.bouncy(duration: 0.3)) {
                        selected = tab
                    }
                }
            }
        }
        .padding(.horizontal, 6)
        .padding(.vertical, 6)
        .background {
            Capsule()
                .fill(.ultraThinMaterial)
                .overlay {
                    Capsule()
                        .strokeBorder(
                            t.isDark
                                ? Color.white.opacity(0.08)
                                : Color.black.opacity(0.06),
                            lineWidth: 1
                        )
                }
        }
        .shadow(
            color: t.isDark
                ? Color.black.opacity(0.5)
                : Color.black.opacity(0.12),
            radius: 20, y: 8
        )
        .padding(.horizontal, 20)
        .padding(.bottom, 28) // above home indicator
        .onChange(of: selected) { newValue in
            withAnimation(.bouncy(duration: 0.3)) {
                localSelected = newValue
            }
        }
    }
}

// MARK: - Individual tab item

struct NexusTabItem: View {
    @Environment(\.nexusTheme) var t
    let tab: NexusTab
    let isSelected: Bool
    let namespace: Namespace.ID
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                // Icon — filled when selected, bounce on iOS 17+
                Group {
                    if #available(iOS 17.0, *) {
                        Image(systemName: isSelected ? tab.filledIcon : tab.icon)
                            .font(.system(size: 18, weight: isSelected ? .semibold : .regular))
                            .symbolEffect(.bounce, value: isSelected)
                    } else {
                        Image(systemName: isSelected ? tab.filledIcon : tab.icon)
                            .font(.system(size: 18, weight: isSelected ? .semibold : .regular))
                    }
                }
                .foregroundStyle(isSelected ? t.accent : t.textSubtle)
                .frame(height: 22)

                // Accent underline dot
                Capsule()
                    .fill(isSelected ? t.accent : Color.clear)
                    .frame(width: isSelected ? 18 : 0, height: 2.5)
                    .animation(
                        .spring(response: 0.3, dampingFraction: 0.6),
                        value: isSelected
                    )
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 8)
            .background {
                if isSelected {
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .fill(
                            t.isDark
                                ? Color.white.opacity(0.10)
                                : Color.black.opacity(0.07)
                        )
                        .matchedGeometryEffect(id: "tabHighlight", in: namespace)
                }
            }
        }
        .buttonStyle(.plain)
    }
}
