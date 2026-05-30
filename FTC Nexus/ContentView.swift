import SwiftUI

struct RootView: View {
    @Environment(\.colorScheme) var colorScheme
    @State private var didFinishLaunch = false
    @StateObject private var rankingsVM = RankingsViewModel()

    var body: some View {
        ZStack {
            if didFinishLaunch {
                ContentView()
                    .transition(.opacity)
            } else {
                LaunchView {
                    withAnimation(.easeOut(duration: 0.4)) {
                        didFinishLaunch = true
                    }
                }
                .transition(.opacity)
            }
        }
        .environment(\.nexusTheme, NexusTheme(isDark: colorScheme == .dark))
        .environmentObject(rankingsVM)
    }
}

struct ContentView: View {
    var body: some View {
        NexusTabContainer { tab in
            switch tab {
            case .rankings:  RankingsView()
            case .teams: TeamsView()
            case .events:    EventsView()
            case .scrimmage: ScrimmageHomeView()
            case .messages:  Text("Messages").frame(maxWidth: .infinity, maxHeight: .infinity)
            case .resources: Text("Resources").frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
    }
}

#Preview {
    RootView()
        .environment(\.nexusTheme, NexusTheme(isDark: false))
}
