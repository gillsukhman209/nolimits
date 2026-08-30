import SwiftUI
import UIKit

// MARK: - Liftoff visual system

extension Color {
    private static func adaptive(light: UIColor, dark: UIColor) -> Color {
        Color(uiColor: UIColor { traits in
            traits.userInterfaceStyle == .dark ? dark : light
        })
    }

    static let paper = adaptive(
        light: UIColor(red: 0.965, green: 0.953, blue: 0.925, alpha: 1),
        dark: UIColor(red: 0.075, green: 0.071, blue: 0.064, alpha: 1)
    )
    static let paperRaised = adaptive(
        light: UIColor(red: 0.995, green: 0.988, blue: 0.970, alpha: 1),
        dark: UIColor(red: 0.115, green: 0.108, blue: 0.096, alpha: 1)
    )
    static let ink = adaptive(
        light: UIColor(red: 0.075, green: 0.071, blue: 0.064, alpha: 1),
        dark: UIColor(red: 0.970, green: 0.955, blue: 0.920, alpha: 1)
    )
    static let inkMuted = adaptive(
        light: UIColor(red: 0.42, green: 0.39, blue: 0.34, alpha: 1),
        dark: UIColor(red: 0.68, green: 0.65, blue: 0.59, alpha: 1)
    )
    static let inkFaint = adaptive(
        light: UIColor(red: 0.68, green: 0.65, blue: 0.59, alpha: 1),
        dark: UIColor(red: 0.38, green: 0.36, blue: 0.32, alpha: 1)
    )
    static let hairline = adaptive(
        light: UIColor(red: 0.83, green: 0.81, blue: 0.76, alpha: 1),
        dark: UIColor(red: 0.24, green: 0.23, blue: 0.21, alpha: 1)
    )
    static let signalOrange = Color(red: 1.00, green: 0.245, blue: 0.035)
    static let signalOrangePressed = Color(red: 0.87, green: 0.17, blue: 0.02)
    static let signalInk = Color(red: 0.07, green: 0.065, blue: 0.055)
    static let signalPaper = Color(red: 0.970, green: 0.955, blue: 0.920)
    static let success = Color(red: 0.20, green: 0.53, blue: 0.30)

    // Backward-compatible names for untouched supporting screens.
    static let appBg = paper
    static let cardBg = paperRaised
    static let surfaceBg = hairline.opacity(0.35)
    static let cardBorder = hairline
    static let textPrimary = ink
    static let textSecondary = inkMuted
    static let textTertiary = inkFaint
    static let accentOrange = signalOrange
    static let accentRed = signalOrange
    static let accentEmber = signalOrangePressed
    static let accentBlue = Color(red: 0.20, green: 0.42, blue: 0.70)
    static let accentCyan = Color(red: 0.10, green: 0.55, blue: 0.60)
    static let accentGreen = success
}

@MainActor
extension LinearGradient {
    static let accent = LinearGradient(
        colors: [.signalOrange, .signalOrange],
        startPoint: .leading,
        endPoint: .trailing
    )

    static let accentSubtle = LinearGradient(
        colors: [.signalOrange.opacity(0.16), .signalOrange.opacity(0.04)],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    static let glassEdge = LinearGradient(
        colors: [.hairline, .hairline.opacity(0.45)],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    static let heroGradient = LinearGradient(
        colors: [.paperRaised, .paper],
        startPoint: .top,
        endPoint: .bottom
    )

    static let screenBg = LinearGradient(
        colors: [.paperRaised, .paper],
        startPoint: .top,
        endPoint: .bottom
    )
}

struct CardStyle: ViewModifier {
    var cornerRadius: CGFloat = 18

    func body(content: Content) -> some View {
        content
            .background(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .fill(Color.paperRaised)
                    .overlay(
                        RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                            .stroke(Color.hairline, lineWidth: 1)
                    )
            )
    }
}

extension View {
    func cardStyle(cornerRadius: CGFloat = 18) -> some View {
        modifier(CardStyle(cornerRadius: cornerRadius))
    }

    func editorialTitle(size: CGFloat, lineSpacing: CGFloat = -4) -> some View {
        self
            .font(.custom("BebasNeue-Regular", fixedSize: size))
            .tracking(-0.4)
            .lineSpacing(lineSpacing)
    }

    func displayLabel(size: CGFloat) -> some View {
        let textStyle: Font.TextStyle
        switch size {
        case 30...:
            textStyle = .largeTitle
        case 20...:
            textStyle = .title3
        case 16...:
            textStyle = .headline
        case 13...:
            textStyle = .subheadline
        default:
            textStyle = .caption
        }

        return self
            .font(.system(textStyle, design: .default, weight: .bold))
            .fontWidth(.condensed)
    }

    func posterLabel(size: CGFloat) -> some View {
        self
            .font(.custom("BebasNeue-Regular", fixedSize: size))
            .tracking(0.25)
    }

    func sectionEyebrow() -> some View {
        self
            .font(.caption.bold())
            .fontWidth(.condensed)
            .tracking(2.2)
            .foregroundStyle(Color.inkMuted)
    }
}

struct OrangeButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .foregroundStyle(Color.signalInk)
            .background(configuration.isPressed ? Color.signalOrangePressed : Color.signalOrange)
            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
            .scaleEffect(configuration.isPressed ? 0.985 : 1)
            .animation(.easeOut(duration: 0.12), value: configuration.isPressed)
    }
}
