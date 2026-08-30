import SwiftUI
import UIKit

struct PersonalRecordCelebrationView: View {
    let result: SaveResult
    let onContinue: () -> Void
    let onViewProgress: () -> Void

    @State private var appeared = false

    var body: some View {
        ZStack {
            Color.signalInk.ignoresSafeArea()
            PRConfettiField(isAnimating: appeared)
                .ignoresSafeArea()
                .allowsHitTesting(false)

            VStack(spacing: 0) {
                Spacer()

                ZStack {
                    Circle()
                        .fill(Color.signalOrange.opacity(0.15))
                        .frame(width: 142, height: 142)
                        .scaleEffect(appeared ? 1 : 0.55)
                    Circle()
                        .stroke(Color.signalOrange.opacity(0.4), lineWidth: 2)
                        .frame(width: 112, height: 112)
                    Image(systemName: "trophy.fill")
                        .font(.system(size: 50, weight: .black))
                        .foregroundStyle(Color.signalOrange)
                        .rotationEffect(.degrees(appeared ? 0 : -18))
                }
                .padding(.bottom, 30)

                Text("NEW PERSONAL RECORD")
                    .font(.system(size: 12, weight: .black))
                    .tracking(2.5)
                    .foregroundStyle(Color.signalOrange)

                Text(result.exerciseName.uppercased())
                    .editorialTitle(size: 48, lineSpacing: -4)
                    .foregroundStyle(Color.signalPaper)
                    .multilineTextAlignment(.center)
                    .minimumScaleFactor(0.64)
                    .lineLimit(2)
                    .padding(.horizontal, 28)
                    .padding(.top, 10)

                Text(setDescription)
                    .font(.system(size: 35, weight: .black))
                    .fontWidth(.compressed)
                    .foregroundStyle(Color.signalPaper)
                    .padding(.top, 18)

                HStack(spacing: 0) {
                    celebrationStat(
                        value: "\(result.estimatedMax.formattedWeight) LB",
                        label: "ESTIMATED MAX"
                    )
                    Rectangle()
                        .fill(Color.signalPaper.opacity(0.14))
                        .frame(width: 1, height: 42)
                    celebrationStat(
                        value: "+\(improvement.formattedWeight) LB",
                        label: "IMPROVEMENT"
                    )
                }
                .padding(.vertical, 20)
                .background(Color.signalPaper.opacity(0.07), in: RoundedRectangle(cornerRadius: 18))
                .padding(.horizontal, 30)
                .padding(.top, 28)

                Spacer()

                VStack(spacing: 12) {
                    Button(action: onViewProgress) {
                        HStack {
                            Text("VIEW EXERCISE PROGRESS")
                                .font(.system(size: 18, weight: .black))
                                .fontWidth(.compressed)
                            Spacer()
                            Image(systemName: "chart.xyaxis.line")
                                .font(.system(size: 16, weight: .black))
                        }
                        .padding(.horizontal, 22)
                        .frame(height: 60)
                    }
                    .buttonStyle(OrangeButtonStyle())

                    Button("KEEP TRAINING", action: onContinue)
                        .font(.system(size: 13, weight: .black))
                        .tracking(1.1)
                        .foregroundStyle(Color.signalPaper.opacity(0.68))
                        .frame(height: 46)
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 20)
            }
            .opacity(appeared ? 1 : 0)
            .offset(y: appeared ? 0 : 18)
        }
        .onAppear {
            UINotificationFeedbackGenerator().notificationOccurred(.success)
            withAnimation(.spring(response: 0.65, dampingFraction: 0.78)) {
                appeared = true
            }
        }
        .accessibilityElement(children: .contain)
    }

    private var improvement: Double {
        max(result.estimatedMax - result.previousBestEstimatedMax, 0)
    }

    private var setDescription: String {
        let side = result.side == .both ? "" : "\(result.side.shortLabel) · "
        let assistance = result.loadType == .assistance ? " ASSIST" : ""
        return "\(side)\(result.weight.formattedWeight) LB\(assistance) × \(result.reps)"
    }

    private func celebrationStat(value: String, label: String) -> some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.system(size: 22, weight: .black))
                .fontWidth(.compressed)
                .foregroundStyle(Color.signalPaper)
            Text(label)
                .font(.system(size: 8, weight: .black))
                .tracking(1)
                .foregroundStyle(Color.signalPaper.opacity(0.52))
        }
        .frame(maxWidth: .infinity)
    }
}

private struct PRConfettiField: View {
    let isAnimating: Bool
    private let colors: [Color] = [
        .signalOrange,
        .signalPaper,
        .success,
        Color(red: 0.18, green: 0.48, blue: 0.78),
    ]

    var body: some View {
        GeometryReader { geometry in
            ForEach(0..<24, id: \.self) { index in
                RoundedRectangle(cornerRadius: index.isMultiple(of: 3) ? 6 : 1)
                    .fill(colors[index % colors.count])
                    .frame(
                        width: index.isMultiple(of: 3) ? 8 : 5,
                        height: index.isMultiple(of: 2) ? 16 : 10
                    )
                    .rotationEffect(.degrees(isAnimating ? Double(index * 95) : 0))
                    .position(
                        x: xPosition(index: index, width: geometry.size.width),
                        y: isAnimating ? geometry.size.height + 40 : -30
                    )
                    .animation(
                        .easeIn(duration: 2.4 + Double(index % 5) * 0.18)
                            .delay(Double(index % 8) * 0.08),
                        value: isAnimating
                    )
            }
        }
    }

    private func xPosition(index: Int, width: CGFloat) -> CGFloat {
        let normalized = CGFloat((index * 47) % 101) / 100
        return 16 + normalized * max(width - 32, 1)
    }
}
