import SwiftUI
import UIKit

struct RankUpView: View {
    let rank: Rank
    let exerciseName: String
    let onContinue: () -> Void

    @State private var appeared = false
    @State private var pulse = false

    var body: some View {
        ZStack {
            Color.ink.ignoresSafeArea()

            Circle()
                .stroke(Color.signalOrange.opacity(0.24), lineWidth: 2)
                .frame(width: 270, height: 270)
                .scaleEffect(pulse ? 1.14 : 0.92)
                .opacity(pulse ? 0 : 1)

            VStack(spacing: 0) {
                Spacer()

                Image(systemName: rank.symbolName)
                    .font(.system(size: 44, weight: .black))
                    .foregroundStyle(rank.color)
                    .frame(width: 118, height: 118)
                    .background(Color.paper.opacity(0.10), in: Circle())
                    .scaleEffect(appeared ? 1 : 0.5)
                    .opacity(appeared ? 1 : 0)

                Text("YOU RANKED UP TO")
                    .font(.system(size: 12, weight: .black))
                    .tracking(2.8)
                    .foregroundStyle(Color.paper.opacity(0.60))
                    .padding(.top, 38)

                Text(rank.rawValue.uppercased())
                    .font(.system(size: 68, weight: .black))
                    .fontWidth(.compressed)
                    .tracking(-1)
                    .foregroundStyle(Color.paper)
                    .padding(.top, 6)

                Text("\(exerciseName) moved you forward.")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(Color.paper.opacity(0.62))
                    .padding(.top, 10)

                Spacer()

                Button(action: onContinue) {
                    Text("BACK TO TODAY")
                        .font(.system(size: 19, weight: .black))
                        .fontWidth(.compressed)
                        .frame(maxWidth: .infinity)
                        .frame(height: 62)
                }
                .buttonStyle(OrangeButtonStyle())
                .padding(.horizontal, 26)
                .padding(.bottom, 30)
            }
            .opacity(appeared ? 1 : 0.4)
            .offset(y: appeared ? 0 : 16)
        }
        .onAppear {
            UINotificationFeedbackGenerator().notificationOccurred(.success)
            withAnimation(.spring(response: 0.62, dampingFraction: 0.72)) {
                appeared = true
            }
            withAnimation(.easeOut(duration: 1.15).repeatForever(autoreverses: false)) {
                pulse = true
            }
        }
    }
}

#Preview {
    RankUpView(rank: .gold, exerciseName: "Bench Press", onContinue: {})
}
