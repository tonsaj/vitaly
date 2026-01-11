import SwiftUI

extension Color {
    // MARK: - Vitaly Brand Colors (Warm Dark Theme)

    /// Primary brand color - Warm orange
    static let vitalyPrimary = Color(red: 0.95, green: 0.45, blue: 0.25)  // #F27340

    /// Secondary brand color - Coral/peach
    static let vitalySecondary = Color(red: 0.98, green: 0.6, blue: 0.45)  // #FA9973

    /// Tertiary - Light peach for gradients
    static let vitalyTertiary = Color(red: 1.0, green: 0.78, blue: 0.65)  // #FFC7A6

    /// Accent color - Bright orange for highlights
    static let vitalyAccent = Color(red: 1.0, green: 0.5, blue: 0.2)  // #FF8033

    /// Background - Deep black
    static let vitalyBackground = Color(red: 0.05, green: 0.05, blue: 0.07)  // #0D0D12

    /// Card background - Dark gray with slight warmth
    static let vitalyCardBackground = Color(red: 0.1, green: 0.1, blue: 0.12)  // #1A1A1F

    /// Surface - Slightly lighter for elevated elements
    static let vitalySurface = Color(red: 0.15, green: 0.15, blue: 0.17)  // #26262B

    /// Text primary - Off-white
    static let vitalyTextPrimary = Color(red: 0.95, green: 0.95, blue: 0.95)  // #F2F2F2

    /// Text secondary - Warm gray
    static let vitalyTextSecondary = Color(red: 0.6, green: 0.58, blue: 0.55)  // #99948C

    // MARK: - Metric Colors (Warm palette)

    static let vitalySleep = Color(red: 0.6, green: 0.5, blue: 0.85)     // Soft purple
    static let vitalyActivity = Color(red: 0.95, green: 0.55, blue: 0.3) // Warm orange
    static let vitalyHeart = Color(red: 0.95, green: 0.35, blue: 0.4)    // Coral red
    static let vitalyRecovery = Color(red: 1.0, green: 0.7, blue: 0.35)  // Golden

    // MARK: - Status Colors

    static let vitalyExcellent = Color(red: 0.3, green: 0.85, blue: 0.5)  // Green
    static let vitalyGood = Color(red: 0.95, green: 0.55, blue: 0.3)      // Orange (matches brand)
    static let vitalyFair = Color(red: 0.95, green: 0.75, blue: 0.35)     // Yellow-orange
    static let vitalyPoor = Color(red: 0.95, green: 0.35, blue: 0.4)      // Red

    // MARK: - Legacy App Colors (deprecated, use Vitaly colors)

    static let appPrimary = vitalyPrimary
    static let appSecondary = vitalySecondary

    // Metric colors
    static let sleepColor = vitalySleep
    static let activityColor = vitalyActivity
    static let heartColor = vitalyHeart
    static let recoveryColor = vitalyRecovery

    // Status colors
    static let excellent = vitalyExcellent
    static let good = vitalyGood
    static let fair = vitalyFair
    static let poor = vitalyPoor

    // Gradients
    static var appGradient: LinearGradient {
        LinearGradient(
            colors: [appPrimary, appSecondary],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    static func metricGradient(for type: MetricType) -> LinearGradient {
        let colors: [Color]
        switch type {
        case .sleep:
            colors = [.vitalySleep, .vitalySleep.opacity(0.7)]
        case .activity:
            colors = [.vitalyActivity, Color(red: 1.0, green: 0.65, blue: 0.4)]
        case .heart:
            colors = [.vitalyHeart, Color(red: 1.0, green: 0.5, blue: 0.55)]
        case .recovery:
            colors = [.vitalyRecovery, Color(red: 1.0, green: 0.8, blue: 0.5)]
        }
        return LinearGradient(colors: colors, startPoint: .topLeading, endPoint: .bottomTrailing)
    }

    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
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

extension LinearGradient {
    /// Primary Vitaly gradient - Warm sunset
    static let vitalyGradient = LinearGradient(
        colors: [Color.vitalyPrimary, Color.vitalySecondary, Color.vitalyTertiary],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    /// Hero gradient for main cards
    static let vitalyHeroGradient = LinearGradient(
        colors: [
            Color(red: 0.95, green: 0.4, blue: 0.2),
            Color(red: 0.98, green: 0.55, blue: 0.35),
            Color(red: 1.0, green: 0.75, blue: 0.55)
        ],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    /// Background gradient
    static let vitalyBackgroundGradient = LinearGradient(
        colors: [Color.vitalyBackground, Color(red: 0.08, green: 0.08, blue: 0.1)],
        startPoint: .top,
        endPoint: .bottom
    )

    /// Card gradient - subtle dark
    static let vitalyCardGradient = LinearGradient(
        colors: [Color.vitalyCardBackground, Color.vitalySurface.opacity(0.5)],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    /// Sleep metric gradient
    static let vitalySleepGradient = LinearGradient(
        colors: [Color.vitalySleep, Color.vitalySleep.opacity(0.7)],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    /// Activity metric gradient
    static let vitalyActivityGradient = LinearGradient(
        colors: [Color.vitalyActivity, Color(red: 1.0, green: 0.65, blue: 0.4)],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    /// Heart metric gradient
    static let vitalyHeartGradient = LinearGradient(
        colors: [Color.vitalyHeart, Color(red: 1.0, green: 0.5, blue: 0.55)],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    /// Recovery metric gradient
    static let vitalyRecoveryGradient = LinearGradient(
        colors: [Color.vitalyRecovery, Color(red: 1.0, green: 0.8, blue: 0.5)],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
}

extension MetricType {
    var vitalyColor: Color {
        switch self {
        case .sleep: return .vitalySleep
        case .activity: return .vitalyActivity
        case .heart: return .vitalyHeart
        case .recovery: return .vitalyRecovery
        }
    }

    var vitalyGradient: LinearGradient {
        switch self {
        case .sleep: return .vitalySleepGradient
        case .activity: return .vitalyActivityGradient
        case .heart: return .vitalyHeartGradient
        case .recovery: return .vitalyRecoveryGradient
        }
    }
}
