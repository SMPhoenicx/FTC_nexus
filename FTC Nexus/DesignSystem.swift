import SwiftUI

// ─── Color tokens ──────────────────────────────────────────────────

struct NexusTheme {
    let isDark: Bool

    // Backgrounds — soft off-white / soft dark for neumorphism
    var bg: Color           { isDark ? Color(hex: "16171C") : Color(hex: "E8E8EC") }
    var card: Color         { isDark ? Color(hex: "1C1D24") : Color(hex: "E8E8EC") }
    var sheetBg: Color      { isDark ? Color(hex: "1A1B22") : Color(hex: "EDEDF1") }

    // FIRST red accent — primary action color
    var accent: Color       { isDark ? Color(hex: "EE3B45") : Color(hex: "D8232A") }
    var accentMuted: Color  { accent.opacity(0.14) }
    var accentText: Color   { isDark ? Color(hex: "F25058") : Color(hex: "C01D24") }

    // FIRST blue — secondary accent for active states / highlights
    var blue: Color         { isDark ? Color(hex: "3B8EEE") : Color(hex: "0066B3") }
    var blueMuted: Color    { blue.opacity(0.14) }

    // Text — near-black/near-white for FIRST feel
    var textPrimary: Color  { isDark ? Color(hex: "F5F5F8") : Color(hex: "0F1014") }
    var textSecondary: Color{ isDark ? Color(hex: "A3A3B0") : Color(hex: "3D3F48") }
    var textSubtle: Color   { isDark ? Color(hex: "5C5D68") : Color(hex: "8B8C97") }
    var divider: Color      { isDark ? Color.white.opacity(0.06) : Color.black.opacity(0.07) }

    // Subtle outline visible on all neumorphic surfaces
    var outline: Color      { isDark ? Color.white.opacity(0.08) : Color.black.opacity(0.10) }

    // Semantic
    var win: Color  { isDark ? Color(hex: "34D399") : Color(hex: "059669") }
    var loss: Color { isDark ? Color(hex: "F87171") : Color(hex: "DC2626") }
    var tie: Color  { Color(hex: "94A3B8") }

    // Medal
    var gold: Color   { Color(hex: "F5C842") }
    var silver: Color { Color(hex: "C0BFC4") }
    var bronze: Color { Color(hex: "D4895A") }

    // Neumorphic shadows
    var neuShadowLight: Color { isDark ? Color.white.opacity(0.045) : Color.white.opacity(0.88) }
    var neuShadowDark:  Color { isDark ? Color.black.opacity(0.72)  : Color.black.opacity(0.18) }
    var neuRadius: CGFloat { 12 }
    var neuOffset: CGFloat { isDark ? 4 : 5 }

    var neuInsetLight: Color { isDark ? Color.white.opacity(0.03) : Color.white.opacity(0.7) }
    var neuInsetDark:  Color { isDark ? Color.black.opacity(0.55) : Color.black.opacity(0.12) }
}

struct NexusThemeKey: EnvironmentKey {
    static let defaultValue = NexusTheme(isDark: false)
}
extension EnvironmentValues {
    var nexusTheme: NexusTheme {
        get { self[NexusThemeKey.self] }
        set { self[NexusThemeKey.self] = newValue }
    }
}

// Rounded Rectangle in Neumorphic style with adjustable radius, maybe make a zstackable one later

struct NeumorphicCard<Content: View>: View {
    @Environment(\.nexusTheme) var t
    var radius: CGFloat = 16
    var padding: EdgeInsets = .init(top: 14, leading: 16, bottom: 14, trailing: 16)
    @ViewBuilder var content: () -> Content

    var body: some View {
        content()
            .padding(padding)
            .background(
                RoundedRectangle(cornerRadius: radius, style: .continuous)
                    .fill(t.card)
                    .shadow(color: t.neuShadowLight, radius: t.neuRadius, x: -t.neuOffset, y: -t.neuOffset)
                    .shadow(color: t.neuShadowDark,  radius: t.neuRadius, x:  t.neuOffset, y:  t.neuOffset)
            )
            .overlay(
                RoundedRectangle(cornerRadius: radius, style: .continuous)
                    .strokeBorder(t.outline, lineWidth: 1)
            )
    }
}

//

struct NeumorphicInset<Content: View>: View {
    @Environment(\.nexusTheme) var t
    var radius: CGFloat = 12
    @ViewBuilder var content: () -> Content

    var body: some View {
        content()
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .background(
                RoundedRectangle(cornerRadius: radius, style: .continuous)
                    .fill(t.card)
                    .overlay(
                        RoundedRectangle(cornerRadius: radius, style: .continuous)
                            .stroke(t.neuShadowLight, lineWidth: 1)
                            .blur(radius: 1.4)
                            .offset(x: -1.2, y: -1.2)
                            .mask(RoundedRectangle(cornerRadius: radius, style: .continuous).fill(LinearGradient(
                                colors: [.black, .clear],
                                startPoint: .topLeading, endPoint: .bottomTrailing)))
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: radius, style: .continuous)
                            .stroke(t.neuShadowDark, lineWidth: 1)
                            .blur(radius: 1.4)
                            .offset(x: 1.2, y: 1.2)
                            .mask(RoundedRectangle(cornerRadius: radius, style: .continuous).fill(LinearGradient(
                                colors: [.clear, .black],
                                startPoint: .topLeading, endPoint: .bottomTrailing)))
                    )
            )
            .overlay(
                RoundedRectangle(cornerRadius: radius, style: .continuous)
                    .strokeBorder(t.outline, lineWidth: 1)
            )
    }
}

// Pill, outline when selected, color when not

struct NexusPill: View {
    @Environment(\.nexusTheme) var t
    let label: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(label)
                .font(.system(size: 11, weight: .bold))
                .tracking(0.4)
                .foregroundColor(isSelected ? .white : t.textSubtle)
                .padding(.horizontal, 14)
                .padding(.vertical, 6)
                .background(
                    Capsule()
                        .fill(isSelected ? t.accent : t.card)
                        .shadow(color: isSelected ? .clear : t.neuShadowLight, radius: 6, x: -3, y: -3)
                        .shadow(color: isSelected ? .clear : t.neuShadowDark,  radius: 6, x:  3, y:  3)
                )
                .overlay(
                    Capsule()
                        .strokeBorder(isSelected ? Color.clear : t.outline, lineWidth: 1)
                )
        }
        .buttonStyle(.plain)
        .animation(.easeInOut(duration: 0.15), value: isSelected)
    }
}
// allows hex values to be used
extension Color {
    init(hex: String) {
        let h = hex.trimmingCharacters(in: .init(charactersIn: "#"))
        var val: UInt64 = 0
        Scanner(string: h).scanHexInt64(&val)
        let r = Double((val >> 16) & 0xFF) / 255
        let g = Double((val >> 8)  & 0xFF) / 255
        let b = Double(val         & 0xFF) / 255
        self.init(red: r, green: g, blue: b)
    }
}

struct TabularFont: ViewModifier {
    let size: CGFloat
    let weight: Font.Weight
    func body(content: Content) -> some View {
        content.font(.system(size: size, weight: weight, design: .default).monospacedDigit())
    }
}
extension View {
    func tabularFont(_ size: CGFloat, weight: Font.Weight = .regular) -> some View {
        modifier(TabularFont(size: size, weight: weight))
    }
}
