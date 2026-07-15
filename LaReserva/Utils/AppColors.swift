import SwiftUI

struct AppColors {
    // Primary Brand Colors
    static let primary = Color(hex: "059669") // Emerald green
    static let primaryLight = Color(hex: "E6FAF5")
    static let primaryDark = Color(hex: "047857")
    
    // Status Colors
    static let danger = Color(hex: "EF4444")
    static let warning = Color(hex: "FBBF24")
    static let info = Color(hex: "3B82F6")
    
    // Gradients
    static let primaryGradient = LinearGradient(
        colors: [Color(hex: "059669"), Color(hex: "10B981")],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    
    // Pastel Card Backgrounds
    static let cardPink = Color(hex: "FFE4E1")
    static let cardBlue = Color(hex: "DBEAFE")
    static let cardPurple = Color(hex: "E0D4FC")
    static let cardGreen = Color(hex: "D4FCE0")
    static let cardPeach = Color(hex: "FCE8D4")
    static let cardLavender = Color(hex: "F0E6FF")
    static let cardMint = Color(hex: "D1FAE5")
    static let cardYellow = Color(hex: "FEF9C3")
    static let cardRose = Color(hex: "FFE4E6")
    static let cardSky = Color(hex: "E0F2FE")
    static let cardCoral = Color(hex: "FFD6D6")
    static let cardLime = Color(hex: "E6F7D4")
    
    static let pastelColors = [
        cardPink, cardBlue, cardPurple, cardGreen, cardPeach,
        cardLavender, cardMint, cardYellow, cardRose, cardSky,
        cardCoral, cardLime
    ]
    
    static func getPastelColor(_ index: Int) -> Color {
        return pastelColors[index % pastelColors.count]
    }
    
    // Neutral Colors
    static let background = Color(hex: "F0F2F5")
    static let textPrimary = Color(hex: "1A1A2E")
    static let textSecondary = Color(hex: "444444")
    static let textMuted = Color(hex: "888888")
}

extension Color {
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
