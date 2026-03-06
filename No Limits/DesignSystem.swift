//
//  DesignSystem.swift
//  No Limits
//
//  Created by Sukhman Singh on 3/5/26.
//

import SwiftUI

// MARK: - Colors

extension Color {
    // Backgrounds
    static let appBg         = Color(red: 0.04, green: 0.04, blue: 0.06)
    static let cardBg        = Color(red: 0.09, green: 0.09, blue: 0.13)
    static let surfaceBg     = Color(red: 0.12, green: 0.12, blue: 0.17)
    static let cardBorder    = Color.white.opacity(0.06)

    // Text
    static let textPrimary   = Color.white
    static let textSecondary = Color(red: 0.55, green: 0.55, blue: 0.65)
    static let textTertiary  = Color.white.opacity(0.30)

    // Accents
    static let accentOrange  = Color(red: 1.00, green: 0.55, blue: 0.15)
    static let accentRed     = Color(red: 1.00, green: 0.25, blue: 0.40)
    static let accentEmber   = Color(red: 1.00, green: 0.40, blue: 0.10)
}

// MARK: - Gradients

extension LinearGradient {
    static let accent = LinearGradient(
        colors: [.accentOrange, .accentRed],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    static let accentSubtle = LinearGradient(
        colors: [Color.accentOrange.opacity(0.15), Color.accentRed.opacity(0.08)],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    static let glassEdge = LinearGradient(
        colors: [Color.white.opacity(0.12), Color.white.opacity(0.03)],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
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
        case .iron:     return Color(red: 0.50, green: 0.50, blue: 0.58)
        case .bronze:   return Color(red: 0.82, green: 0.52, blue: 0.22)
        case .silver:   return Color(red: 0.75, green: 0.78, blue: 0.85)
        case .gold:     return Color(red: 1.00, green: 0.82, blue: 0.20)
        case .platinum: return Color(red: 0.20, green: 0.92, blue: 0.88)
        case .diamond:  return Color(red: 0.45, green: 0.72, blue: 1.00)
        case .titan:    return Color(red: 0.78, green: 0.32, blue: 1.00)
        }
    }

    var gradient: LinearGradient {
        switch self {
        case .iron:
            return LinearGradient(colors: [Color(red: 0.50, green: 0.50, blue: 0.58), Color(red: 0.38, green: 0.38, blue: 0.45)], startPoint: .topLeading, endPoint: .bottomTrailing)
        case .bronze:
            return LinearGradient(colors: [Color(red: 0.88, green: 0.58, blue: 0.25), Color(red: 0.72, green: 0.40, blue: 0.15)], startPoint: .topLeading, endPoint: .bottomTrailing)
        case .silver:
            return LinearGradient(colors: [Color(red: 0.82, green: 0.85, blue: 0.92), Color(red: 0.62, green: 0.65, blue: 0.72)], startPoint: .topLeading, endPoint: .bottomTrailing)
        case .gold:
            return LinearGradient(colors: [Color(red: 1.00, green: 0.88, blue: 0.30), Color(red: 0.90, green: 0.68, blue: 0.10)], startPoint: .topLeading, endPoint: .bottomTrailing)
        case .platinum:
            return LinearGradient(colors: [Color(red: 0.25, green: 0.95, blue: 0.90), Color(red: 0.10, green: 0.75, blue: 0.80)], startPoint: .topLeading, endPoint: .bottomTrailing)
        case .diamond:
            return LinearGradient(colors: [Color(red: 0.50, green: 0.78, blue: 1.00), Color(red: 0.30, green: 0.55, blue: 0.95)], startPoint: .topLeading, endPoint: .bottomTrailing)
        case .titan:
            return LinearGradient(colors: [Color(red: 0.85, green: 0.40, blue: 1.00), Color(red: 0.55, green: 0.15, blue: 0.90)], startPoint: .topLeading, endPoint: .bottomTrailing)
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

// MARK: - Glass Card Modifier

struct CardStyle: ViewModifier {
    var cornerRadius: CGFloat = 20

    func body(content: Content) -> some View {
        content
            .background(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .fill(Color.cardBg)
            )
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .strokeBorder(LinearGradient.glassEdge, lineWidth: 1)
            )
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
    }
}

extension View {
    func cardStyle(cornerRadius: CGFloat = 20) -> some View {
        modifier(CardStyle(cornerRadius: cornerRadius))
    }
}

// MARK: - Glow Effect

struct GlowModifier: ViewModifier {
    let color: Color
    let radius: CGFloat

    func body(content: Content) -> some View {
        content
            .shadow(color: color.opacity(0.5), radius: radius, x: 0, y: 0)
            .shadow(color: color.opacity(0.2), radius: radius * 2, x: 0, y: 0)
    }
}

extension View {
    func glow(_ color: Color, radius: CGFloat = 8) -> some View {
        modifier(GlowModifier(color: color, radius: radius))
    }
}

// MARK: - Shimmer Animation

struct ShimmerModifier: ViewModifier {
    @State private var phase: CGFloat = 0

    func body(content: Content) -> some View {
        content
            .overlay(
                LinearGradient(
                    colors: [.clear, Color.white.opacity(0.08), .clear],
                    startPoint: .leading,
                    endPoint: .trailing
                )
                .rotationEffect(.degrees(25))
                .offset(x: phase)
                .mask(content)
            )
            .onAppear {
                withAnimation(.linear(duration: 3).repeatForever(autoreverses: false)) {
                    phase = 400
                }
            }
    }
}

extension View {
    func shimmer() -> some View {
        modifier(ShimmerModifier())
    }
}
