//
//  Theme.swift
//  UNICalculate — UniSum Design System
//
//  Central source of truth for colors, gradients, spacing, radii, shadows and
//  typography. Everything visual in the app should reference these tokens so the
//  look stays consistent and can be re-themed from one place.
//

import SwiftUI

// MARK: - Color hex helpers

extension Color {
    /// Create a Color from a 24-bit hex value, e.g. `Color(hex: 0x4F46E5)`.
    init(hex: UInt) {
        let r = Double((hex >> 16) & 0xFF) / 255.0
        let g = Double((hex >> 8) & 0xFF) / 255.0
        let b = Double(hex & 0xFF) / 255.0
        self.init(.sRGB, red: r, green: g, blue: b, opacity: 1)
    }

    /// A dynamic color that resolves to `light` in light mode and `dark` in dark mode.
    init(light: UInt, dark: UInt) {
        self.init(UIColor { traits in
            traits.userInterfaceStyle == .dark
                ? UIColor(Color(hex: dark))
                : UIColor(Color(hex: light))
        })
    }
}

// MARK: - Brand palette

extension Color {
    // Brand — indigo → violet
    static let brandPrimary   = Color(light: 0x4F46E5, dark: 0x6366F1) // indigo-600 / 500
    static let brandSecondary = Color(light: 0x7C3AED, dark: 0x8B5CF6) // violet-600 / 500
    static let brandDeep      = Color(light: 0x3730A3, dark: 0x4338CA) // indigo-800 / 700
    static let brandTint      = Color(light: 0xEEF0FF, dark: 0x1E1B34) // soft indigo wash for chips/fills
    static let brandOnTint    = Color(light: 0x4338CA, dark: 0xC7D2FE) // readable brand text on brandTint (WCAG AA)

    // Semantic status
    static let successGreen = Color(light: 0x059669, dark: 0x34D399)
    static let warningAmber = Color(light: 0xD97706, dark: 0xFBBF24)
    static let dangerRed    = Color(light: 0xDC2626, dark: 0xF87171)

    // Surfaces
    static let appBackground     = Color(light: 0xF5F6FB, dark: 0x0C0C11)
    static let cardBackground    = Color(light: 0xFFFFFF, dark: 0x17171F)
    static let cardBackgroundAlt = Color(light: 0xFBFBFE, dark: 0x1E1E28)
    static let hairline          = Color(light: 0xE7E8F0, dark: 0x2A2A38)

    // Text
    static let textPrimary   = Color(light: 0x111827, dark: 0xF5F5F7)
    static let textSecondary = Color(light: 0x6B7280, dark: 0x9BA0AE)
}

// MARK: - Gradients

extension LinearGradient {
    /// Primary brand gradient (indigo → violet), top-leading to bottom-trailing.
    static let brand = LinearGradient(
        colors: [.brandPrimary, .brandSecondary],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    /// Deep brand gradient used for large hero surfaces.
    static let brandDeep = LinearGradient(
        colors: [Color(hex: 0x4338CA), Color(hex: 0x7C3AED)],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    static func status(_ color: Color) -> LinearGradient {
        LinearGradient(colors: [color.opacity(0.9), color], startPoint: .topLeading, endPoint: .bottomTrailing)
    }
}

// MARK: - Layout tokens

enum DS {
    enum Spacing {
        static let xxs: CGFloat = 4
        static let xs: CGFloat  = 8
        static let sm: CGFloat  = 12
        static let md: CGFloat  = 16
        static let lg: CGFloat  = 20
        static let xl: CGFloat  = 28
        static let xxl: CGFloat = 40
    }

    enum Radius {
        static let sm: CGFloat  = 10
        static let md: CGFloat  = 16
        static let lg: CGFloat  = 22
        static let xl: CGFloat  = 28
        static let pill: CGFloat = 999
    }
}

// MARK: - Shadow

extension View {
    /// Soft, brand-neutral elevation used by cards.
    func softShadow(_ radius: CGFloat = 14, y: CGFloat = 6, opacity: Double = 0.08) -> some View {
        shadow(color: Color.black.opacity(opacity), radius: radius, x: 0, y: y)
    }

    /// Colored glow used under primary buttons / accent surfaces.
    func brandGlow(_ color: Color = .brandPrimary, radius: CGFloat = 16, y: CGFloat = 8, opacity: Double = 0.35) -> some View {
        shadow(color: color.opacity(opacity), radius: radius, x: 0, y: y)
    }
}

// MARK: - Performance color scale (GPA / scores → color)

enum GradeColor {
    /// Map a GPA on a 0–4 scale to a semantic performance color.
    static func forGPA(_ gpa: Double) -> Color {
        switch gpa {
        case 3.5...:    return .successGreen
        case 2.5..<3.5: return .brandPrimary
        case 1.5..<2.5: return .warningAmber
        default:        return .dangerRed
        }
    }

    /// Map a 0–100 score/average to a semantic performance color.
    static func forScore(_ score: Double) -> Color {
        switch score {
        case 85...:   return .successGreen
        case 70..<85: return .brandPrimary
        case 50..<70: return .warningAmber
        default:      return .dangerRed
        }
    }
}
