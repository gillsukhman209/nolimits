//
//  DesignSystem.swift
//  No Limits
//
//  Created by Sukhman Singh on 3/5/26.
//

import SwiftUI

// MARK: - Colors

extension Color {
    // Deep indigo base — NOT flat black
    static let appBg         = Color(red: 0.04, green: 0.03, blue: 0.10)
    static let cardBg        = Color(red: 0.09, green: 0.07, blue: 0.18)
    static let surfaceBg     = Color(red: 0.13, green: 0.10, blue: 0.24)
    static let cardBorder    = Color.white.opacity(0.08)

    // Text
    static let textPrimary   = Color.white
    static let textSecondary = Color(red: 0.58, green: 0.55, blue: 0.72)
    static let textTertiary  = Color(red: 0.35, green: 0.32, blue: 0.48)

    // Accents — vivid multi-color palette
    static let accentOrange  = Color(red: 0.55, green: 0.35, blue: 1.00)   // vivid violet
    static let accentRed     = Color(red: 0.95, green: 0.30, blue: 0.60)   // hot pink
    static let accentEmber   = Color(red: 0.40, green: 0.20, blue: 0.90)   // deeper violet
    static let accentBlue    = Color(red: 0.20, green: 0.70, blue: 1.00)   // sky blue
    static let accentCyan    = Color(red: 0.00, green: 0.90, blue: 0.85)   // cyan
    static let accentGreen   = Color(red: 0.20, green: 0.90, blue: 0.50)   // mint green
}

// MARK: - Gradients

extension LinearGradient {
    static let accent = LinearGradient(
        colors: [Color(red: 0.55, green: 0.35, blue: 1.00), Color(red: 0.95, green: 0.30, blue: 0.60)],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    static let accentSubtle = LinearGradient(
        colors: [Color.accentOrange.opacity(0.15), Color.accentRed.opacity(0.08)],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    static let glassEdge = LinearGradient(
        colors: [Color.white.opacity(0.12), Color.white.opacity(0.02)],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    static let heroGradient = LinearGradient(
        colors: [Color(red: 0.08, green: 0.05, blue: 0.18), Color(red: 0.04, green: 0.03, blue: 0.10)],
        startPoint: .top,
        endPoint: .bottom
    )

    static let screenBg = LinearGradient(
        colors: [
            Color(red: 0.08, green: 0.04, blue: 0.20),
            Color(red: 0.04, green: 0.03, blue: 0.10),
            Color(red: 0.02, green: 0.02, blue: 0.06)
        ],
        startPoint: .top,
        endPoint: .bottom
    )
}

// MARK: - Rank

enum Rank: String, CaseIterable, Equatable {
    case iron     = "Iron"
    case bronze   = "Bronze"
    case silver   = "Silver"
    case gold     = "Gold"
    case platinum = "Platinum"
    case diamond  = "Diamond"
    case titan    = "Titan"

    var color: Color {
        switch self {
        case .iron:     return Color(red: 0.50, green: 0.52, blue: 0.65)
        case .bronze:   return Color(red: 0.90, green: 0.55, blue: 0.20)
        case .silver:   return Color(red: 0.75, green: 0.78, blue: 0.90)
        case .gold:     return Color(red: 1.00, green: 0.78, blue: 0.15)
        case .platinum: return Color(red: 0.00, green: 0.92, blue: 0.88)
        case .diamond:  return Color(red: 0.35, green: 0.65, blue: 1.00)
        case .titan:    return Color(red: 0.80, green: 0.30, blue: 1.00)
        }
    }

    var gradient: LinearGradient {
        switch self {
        case .iron:
            return LinearGradient(colors: [Color(red: 0.55, green: 0.57, blue: 0.70), Color(red: 0.38, green: 0.40, blue: 0.52)], startPoint: .topLeading, endPoint: .bottomTrailing)
        case .bronze:
            return LinearGradient(colors: [Color(red: 0.95, green: 0.62, blue: 0.22), Color(red: 0.72, green: 0.38, blue: 0.10)], startPoint: .topLeading, endPoint: .bottomTrailing)
        case .silver:
            return LinearGradient(colors: [Color(red: 0.85, green: 0.88, blue: 0.98), Color(red: 0.60, green: 0.63, blue: 0.75)], startPoint: .topLeading, endPoint: .bottomTrailing)
        case .gold:
            return LinearGradient(colors: [Color(red: 1.00, green: 0.85, blue: 0.20), Color(red: 0.90, green: 0.62, blue: 0.05)], startPoint: .topLeading, endPoint: .bottomTrailing)
        case .platinum:
            return LinearGradient(colors: [Color(red: 0.00, green: 0.98, blue: 0.95), Color(red: 0.00, green: 0.65, blue: 0.72)], startPoint: .topLeading, endPoint: .bottomTrailing)
        case .diamond:
            return LinearGradient(colors: [Color(red: 0.42, green: 0.72, blue: 1.00), Color(red: 0.20, green: 0.45, blue: 0.95)], startPoint: .topLeading, endPoint: .bottomTrailing)
        case .titan:
            return LinearGradient(colors: [Color(red: 0.85, green: 0.35, blue: 1.00), Color(red: 0.50, green: 0.15, blue: 0.90)], startPoint: .topLeading, endPoint: .bottomTrailing)
        }
    }

    var symbolName: String {
        switch self {
        case .iron:     return "bolt.fill"
        case .bronze:   return "flame.fill"
        case .silver:   return "star.fill"
        case .gold:     return "trophy.fill"
        case .platinum: return "sparkles"
        case .diamond:  return "rhombus.fill"
        case .titan:    return "crown.fill"
        }
    }

    var lowerBound: Double {
        switch self {
        case .iron:     return 0
        case .bronze:   return 0.60
        case .silver:   return 0.80
        case .gold:     return 1.00
        case .platinum: return 1.20
        case .diamond:  return 1.40
        case .titan:    return 1.60
        }
    }

    var upperBound: Double {
        switch self {
        case .iron:     return 0.60
        case .bronze:   return 0.80
        case .silver:   return 1.00
        case .gold:     return 1.20
        case .platinum: return 1.40
        case .diamond:  return 1.60
        case .titan:    return 10.0
        }
    }

    var nextRank: Rank? {
        let all = Rank.allCases
        guard let idx = all.firstIndex(of: self), idx + 1 < all.count else { return nil }
        return all[idx + 1]
    }

    static func fromScore(_ score: Double) -> Rank {
        for rank in Rank.allCases.reversed() {
            if score >= rank.lowerBound { return rank }
        }
        return .iron
    }
}

// MARK: - Card Modifier

struct CardStyle: ViewModifier {
    var cornerRadius: CGFloat = 20

    func body(content: Content) -> some View {
        content
            .background(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .fill(Color.cardBg)
                    .overlay(
                        RoundedRectangle(cornerRadius: cornerRadius)
                            .strokeBorder(LinearGradient.glassEdge, lineWidth: 1)
                    )
            )
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
    }
}

extension View {
    func cardStyle(cornerRadius: CGFloat = 20) -> some View {
        modifier(CardStyle(cornerRadius: cornerRadius))
    }
}
