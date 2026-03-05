//
//  DesignSystem.swift
//  No Limits
//
//  Created by Sukhman Singh on 3/5/26.
//

import SwiftUI

// MARK: - Colors

extension Color {
    static let appBg         = Color(red: 0.05, green: 0.05, blue: 0.08)
    static let cardBg        = Color(red: 0.11, green: 0.11, blue: 0.16)
    static let cardBorder    = Color.white.opacity(0.07)
    static let textSecondary = Color.white.opacity(0.50)
    static let accentOrange  = Color(red: 1.00, green: 0.50, blue: 0.12)
    static let accentRed     = Color(red: 1.00, green: 0.22, blue: 0.38)
}

// MARK: - Gradient

extension LinearGradient {
    static let accent = LinearGradient(
        colors: [.accentOrange, .accentRed],
        startPoint: .leading,
        endPoint: .trailing
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
        case .iron:     return Color(red: 0.55, green: 0.55, blue: 0.62)
        case .bronze:   return Color(red: 0.80, green: 0.50, blue: 0.20)
        case .silver:   return Color(red: 0.78, green: 0.78, blue: 0.83)
        case .gold:     return Color(red: 1.00, green: 0.84, blue: 0.10)
        case .platinum: return Color(red: 0.10, green: 0.90, blue: 0.90)
        case .diamond:  return Color(red: 0.42, green: 0.76, blue: 1.00)
        case .titan:    return Color(red: 0.80, green: 0.30, blue: 1.00)
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

    var nextRank: Rank? {
        let all = Rank.allCases
        guard let idx = all.firstIndex(of: self), idx + 1 < all.count else { return nil }
        return all[idx + 1]
    }
}

// MARK: - Card Modifier

struct CardStyle: ViewModifier {
    var cornerRadius: CGFloat = 20

    func body(content: Content) -> some View {
        content
            .background(Color.cardBg)
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .strokeBorder(Color.cardBorder, lineWidth: 1)
            )
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
    }
}

extension View {
    func cardStyle(cornerRadius: CGFloat = 20) -> some View {
        modifier(CardStyle(cornerRadius: cornerRadius))
    }
}
