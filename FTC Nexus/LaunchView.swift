//
//  LaunchView.swift
//  FTC Nexus
//
//  Created by Suman Muppavarapu on 5/6/26.
//


import SwiftUI

struct LaunchView: View {
    @Environment(\.nexusTheme) var t
    @EnvironmentObject var rankingsVM: RankingsViewModel
    let onComplete: () -> Void

    @State private var pulseScale: CGFloat = 0.92
    @State private var pulseOpacity: Double = 0.85
    @State private var titleOffset: CGFloat = 8
    @State private var titleOpacity: Double = 0
    @State private var hasStarted = false

    // How long to hold the splash, regardless of network. Cache loads
    // synchronously so the main UI is already populated when we finish.
    private let minSplashSeconds: UInt64 = 1_500_000_000

    var body: some View {
        ZStack {
            t.bg.ignoresSafeArea()

            VStack(spacing: 22) {
                Spacer()

                // Logo mark — pulsing red FIRST badge
                ZStack {
                    Circle()
                        .fill(t.accent.opacity(0.14))
                        .frame(width: 140, height: 140)
                        .scaleEffect(pulseScale * 1.08)

                    RoundedRectangle(cornerRadius: 24, style: .continuous)
                        .fill(t.accent)
                        .frame(width: 92, height: 92)
                        .shadow(color: t.accent.opacity(0.45), radius: 22, y: 10)

                    Image(systemName: "trophy.fill")
                        .font(.system(size: 42, weight: .black))
                        .foregroundColor(.white)
                }
                .scaleEffect(pulseScale)
                .opacity(pulseOpacity)

                VStack(spacing: 6) {
                    Text("FTC Nexus")
                        .font(.system(size: 30, weight: .black))
                        .foregroundColor(t.textPrimary)
                        .tracking(-0.7)
                    Text("DECODE 2025")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(t.accent)
                        .tracking(0.6)
                }
                .offset(y: titleOffset)
                .opacity(titleOpacity)

                Spacer()

                VStack(spacing: 10) {
                    ProgressView()
                        .tint(t.accent)
                        .scaleEffect(0.9)
                    Text("Loading rankings…")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(t.textSubtle)
                        .tracking(0.3)
                }
                .opacity(titleOpacity)
                .padding(.bottom, 60)
            }
        }
        .onAppear {
            guard !hasStarted else { return }
            hasStarted = true

            withAnimation(.easeInOut(duration: 1.0).repeatForever(autoreverses: true)) {
                pulseScale = 1.0
                pulseOpacity = 1.0
            }
            withAnimation(.easeOut(duration: 0.5).delay(0.15)) {
                titleOffset = 0
                titleOpacity = 1
            }

            Task { await runStartup() }
        }
    }

    @MainActor
    private func runStartup() async {
        // Pull from cache synchronously, fire off the Firestore refresh.
        rankingsVM.initLoad()

        // Hold the splash for the branding minimum. The Firestore fetch keeps
        // running in the background; if it lands during the splash, great —
        // if not, the cached rows show instantly when we transition.
        try? await Task.sleep(nanoseconds: minSplashSeconds)

        onComplete()
    }
}
