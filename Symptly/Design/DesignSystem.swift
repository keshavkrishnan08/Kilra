import SwiftUI

// MARK: - Adaptive Color Helper
#if canImport(UIKit)
private func adaptiveColor(light: String, dark: String) -> Color {
    Color(UIColor { traits in
        traits.userInterfaceStyle == .dark
            ? UIColor(red: 0, green: 0, blue: 0, alpha: 1).fromHex(dark)
            : UIColor(red: 0, green: 0, blue: 0, alpha: 1).fromHex(light)
    })
}

private extension UIColor {
    func fromHex(_ hex: String) -> UIColor {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let r = CGFloat((int >> 16) & 0xFF) / 255
        let g = CGFloat((int >> 8) & 0xFF) / 255
        let b = CGFloat(int & 0xFF) / 255
        return UIColor(red: r, green: g, blue: b, alpha: 1.0)
    }
}
#endif

// MARK: - Color System
extension Color {
    struct SS {
        // Adaptive backgrounds
        #if canImport(UIKit)
        static let background = adaptiveColor(light: "FAF9F6", dark: "111318")
        static let surfacePrimary = adaptiveColor(light: "FFFFFF", dark: "1A1D24")
        static let surfaceSecondary = adaptiveColor(light: "F4F3F0", dark: "22262E")
        static let surfaceTertiary = adaptiveColor(light: "E9E7E2", dark: "2C3039")
        static let surfaceElevated = adaptiveColor(light: "FFFFFF", dark: "242830")

        // Text hierarchy
        static let textPrimary = adaptiveColor(light: "1C2534", dark: "F0F2F5")
        static let textSecondary = adaptiveColor(light: "4A5568", dark: "A0AEC0")
        static let textTertiary = adaptiveColor(light: "8896AB", dark: "6B7A8D")
        static let textDisabled = adaptiveColor(light: "C1CAD6", dark: "404856")

        // Separators
        static let separator = adaptiveColor(light: "E6E3DD", dark: "2A2E36")
        static let separatorStrong = adaptiveColor(light: "D3CFC8", dark: "3A3F48")
        #else
        static let background = Color(hex: "FAF9F6")
        static let surfacePrimary = Color(hex: "FFFFFF")
        static let surfaceSecondary = Color(hex: "F4F3F0")
        static let surfaceTertiary = Color(hex: "E9E7E2")
        static let surfaceElevated = Color(hex: "FFFFFF")
        static let textPrimary = Color(hex: "1C2534")
        static let textSecondary = Color(hex: "4A5568")
        static let textTertiary = Color(hex: "8896AB")
        static let textDisabled = Color(hex: "C1CAD6")
        static let separator = Color(hex: "E6E3DD")
        static let separatorStrong = Color(hex: "D3CFC8")
        #endif

        // Accent — vivid teal (same in both modes)
        static let accent = Color(hex: "00C49A")
        static let accentLight = Color(hex: "33DFBB")
        static let accentDark = Color(hex: "009977")
        static let accentSubtle = Color(hex: "00C49A").opacity(0.10)

        // Secondary accent — soft violet
        static let violet = Color(hex: "7C5CFC")
        static let violetLight = Color(hex: "9B82FA")
        static let violetSubtle = Color(hex: "7C5CFC").opacity(0.10)

        // Semantic colors
        static let success = Color(hex: "22C55E")
        static let warning = Color(hex: "F59E0B")
        static let error = Color(hex: "EF4444")
        static let info = Color(hex: "3B82F6")

        // Severity scale
        static let severityNone = Color(hex: "22C55E")
        static let severityMild = Color(hex: "84CC16")
        static let severityModerate = Color(hex: "EAB308")
        static let severitySevere = Color(hex: "F97316")
        static let severityCritical = Color(hex: "EF4444")

        // Gradients
        static let gradientPrimary = LinearGradient(
            colors: [accent, violet],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )

        static let gradientSubtle = LinearGradient(
            colors: [accent.opacity(0.12), violet.opacity(0.06)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )

        static let gradientCard = LinearGradient(
            colors: [surfacePrimary, surfaceSecondary.opacity(0.5)],
            startPoint: .top,
            endPoint: .bottom
        )

        static let gradientMesh = LinearGradient(
            colors: [background, surfaceSecondary, background],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )

        // Overlay
        static let overlay = Color.black.opacity(0.3)
        static let overlayHeavy = Color.black.opacity(0.6)
    }
}

// MARK: - Hex Color Extension
extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 6:
            (a, r, g, b) = (255, (int >> 16) & 0xFF, (int >> 8) & 0xFF, int & 0xFF)
        case 8:
            (a, r, g, b) = ((int >> 24) & 0xFF, (int >> 16) & 0xFF, (int >> 8) & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

// MARK: - Typography System
extension Font {
    struct SS {
        static let displayLarge = Font.system(size: 42, weight: .bold, design: .rounded)
        static let displayMedium = Font.system(size: 34, weight: .bold, design: .rounded)
        static let displaySmall = Font.system(size: 28, weight: .semibold, design: .rounded)

        static let headlineLarge = Font.system(size: 24, weight: .semibold, design: .rounded)
        static let headlineMedium = Font.system(size: 20, weight: .semibold, design: .rounded)
        static let headlineSmall = Font.system(size: 18, weight: .semibold, design: .rounded)

        static let titleLarge = Font.system(size: 20, weight: .medium, design: .default)
        static let titleMedium = Font.system(size: 17, weight: .medium, design: .default)
        static let titleSmall = Font.system(size: 15, weight: .medium, design: .default)

        static let bodyLarge = Font.system(size: 17, weight: .regular, design: .default)
        static let bodyMedium = Font.system(size: 15, weight: .regular, design: .default)
        static let bodySmall = Font.system(size: 13, weight: .regular, design: .default)

        static let labelLarge = Font.system(size: 14, weight: .medium, design: .default)
        static let labelMedium = Font.system(size: 12, weight: .medium, design: .default)
        static let labelSmall = Font.system(size: 11, weight: .medium, design: .default)

        static let caption = Font.system(size: 11, weight: .regular, design: .default)

        static let dataLarge = Font.system(size: 32, weight: .bold, design: .rounded)
        static let dataMedium = Font.system(size: 24, weight: .semibold, design: .rounded)
        static let dataSmall = Font.system(size: 16, weight: .medium, design: .monospaced)

        static let accentLarge = Font.system(size: 20, weight: .semibold, design: .default)
        static let accentMedium = Font.system(size: 16, weight: .semibold, design: .default)
        static let accentSmall = Font.system(size: 13, weight: .semibold, design: .default)
    }
}

// MARK: - Spacing System
struct Spacing {
    static let xxxs: CGFloat = 2
    static let xxs: CGFloat = 4
    static let xs: CGFloat = 8
    static let sm: CGFloat = 12
    static let md: CGFloat = 16
    static let lg: CGFloat = 20
    static let xl: CGFloat = 24
    static let xxl: CGFloat = 32
    static let xxxl: CGFloat = 40
    static let xxxxl: CGFloat = 48
    static let section: CGFloat = 56
    static let hero: CGFloat = 80
}

// MARK: - Corner Radius
struct Radius {
    static let xs: CGFloat = 6
    static let sm: CGFloat = 10
    static let md: CGFloat = 14
    static let lg: CGFloat = 18
    static let xl: CGFloat = 22
    static let xxl: CGFloat = 26
    static let pill: CGFloat = 100
}

// MARK: - Shadows
extension View {
    func ssShadow(_ style: SSShadowStyle = .medium) -> some View {
        switch style {
        case .subtle:
            return self.shadow(color: Color.black.opacity(0.04), radius: 4, x: 0, y: 2)
        case .medium:
            return self.shadow(color: Color.black.opacity(0.06), radius: 10, x: 0, y: 4)
        case .elevated:
            return self.shadow(color: Color.black.opacity(0.10), radius: 20, x: 0, y: 8)
        case .glow:
            return self.shadow(color: Color.SS.accent.opacity(0.20), radius: 14, x: 0, y: 4)
        case .violetGlow:
            return self.shadow(color: Color.SS.violet.opacity(0.16), radius: 14, x: 0, y: 4)
        }
    }
}

enum SSShadowStyle {
    case subtle, medium, elevated, glow, violetGlow
}

// MARK: - Custom Icon View
struct SSIconImage: View {
    let name: String
    var size: CGFloat = 24

    var body: some View {
        Image(name)
            .renderingMode(.template)
            .resizable()
            .aspectRatio(contentMode: .fit)
            .frame(width: size, height: size)
    }
}

// MARK: - Haptics
struct SSHaptics {
    #if canImport(UIKit)
    static func light() {
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
    }
    static func medium() {
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
    }
    static func soft() {
        UIImpactFeedbackGenerator(style: .soft).impactOccurred()
    }
    static func success() {
        UINotificationFeedbackGenerator().notificationOccurred(.success)
    }
    static func selection() {
        UISelectionFeedbackGenerator().selectionChanged()
    }
    static func error() {
        UINotificationFeedbackGenerator().notificationOccurred(.error)
    }
    #else
    static func light() {}
    static func medium() {}
    static func soft() {}
    static func success() {}
    static func selection() {}
    static func error() {}
    #endif
}
