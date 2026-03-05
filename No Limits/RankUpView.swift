//
//  RankUpView.swift
//  No Limits
//
//  Created by Sukhman Singh on 3/5/26.
//

import SwiftUI
import UIKit

struct RankUpView: View {
    let rank: Rank
    let onContinue: () -> Void

    @State private var badgeScale: CGFloat = 0.4
    @State private var badgeOpacity: Double = 0
    @State private var textOpacity: Double = 0
    @State private var buttonOpacity: Double = 0
    @State private var glowOpacity: Double = 0
    @State private var ringScale: CGFloat = 0.6

    var body: some View {
        ZStack {
            Color.appBg.ignoresSafeArea()

            // Glow
            Circle()
                .fill(rank.color.opacity(0.2))
                .frame(width: 480, height: 480)
                .blur(radius: 80)
                .scaleEffect(ringScale)
                .opacity(glowOpacity)

            VStack(spacing: 0) {
                Spacer()

                // Badge
                ZStack {
                    // Outer ring pulse
                    Circle()
                        .strokeBorder(rank.color.opacity(0.2), lineWidth: 1)
                        .frame(width: 180, height: 180)

                    Circle()
                        .fill(rank.color.opacity(0.12))
                        .frame(width: 152, height: 152)

                    Circle()
                        .strokeBorder(
                            LinearGradient(
                                colors: [rank.color, rank.color.opacity(0.3)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 2
                        )
                        .frame(width: 152, height: 152)

                    Image(systemName: rank.symbolName)
                        .font(.system(size: 64, weight: .semibold))
                        .foregroundColor(rank.color)
                }
                .scaleEffect(badgeScale)
                .opacity(badgeOpacity)

                Spacer().frame(height: 40)

                // Text
                VStack(spacing: 12) {
                    Text("RANK UP")
                        .font(.system(size: 13, weight: .black, design: .rounded))
                        .foregroundColor(rank.color)
                        .tracking(5)

                    Text(rank.rawValue)
                        .font(.system(size: 54, weight: .black))
                        .foregroundColor(.white)

                    Text("You've earned your rank.\nKeep pushing.")
                        .font(.system(size: 16))
                        .foregroundColor(.textSecondary)
                        .multilineTextAlignment(.center)
                        .lineSpacing(5)
                }
                .opacity(textOpacity)

                Spacer()

                // Continue button
                Button(action: {
                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                    onContinue()
                }) {
                    Text("Continue")
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 56)
                        .background(rank.color.opacity(0.22))
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
                                .strokeBorder(rank.color.opacity(0.55), lineWidth: 1.5)
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                }
                .opacity(buttonOpacity)
                .padding(.horizontal, 32)
                .padding(.bottom, 52)
            }
        }
        .onAppear { runEntranceAnimation() }
    }

    private func runEntranceAnimation() {
        // Success haptic on rank-up
        let notification = UINotificationFeedbackGenerator()
        notification.notificationOccurred(.success)

        withAnimation(.spring(response: 0.55, dampingFraction: 0.65).delay(0.1)) {
            badgeScale = 1.0
            badgeOpacity = 1.0
            ringScale = 1.0
            glowOpacity = 1.0
        }
        withAnimation(.easeOut(duration: 0.4).delay(0.45)) {
            textOpacity = 1.0
        }
        withAnimation(.easeOut(duration: 0.35).delay(0.65)) {
            buttonOpacity = 1.0
        }
    }
}

#Preview {
    RankUpView(rank: .gold, onContinue: {})
}
