import SwiftUI

struct OnboardingView: View {
    let onComplete: (ProfileDraft) -> Void

    @State private var step = 0
    @State private var experience: String?
    @State private var goal: String?
    @State private var bodyweight = ""
    @State private var height = ""

    var body: some View {
        VStack(spacing: 0) {
            if step > 0 {
                progress
                    .padding(.horizontal, 24)
                    .padding(.top, 20)
            }

            Group {
                switch step {
                case 0: welcome
                case 1: experienceStep
                case 2: goalStep
                default: metricsStep
                }
            }
            .id(step)
            .transition(
                .asymmetric(
                    insertion: .move(edge: .trailing).combined(with: .opacity),
                    removal: .move(edge: .leading).combined(with: .opacity)
                )
            )
        }
        .background(Color.paper.ignoresSafeArea())
        .animation(.spring(response: 0.42, dampingFraction: 0.88), value: step)
    }

    private var progress: some View {
        HStack(spacing: 7) {
            ForEach(1...3, id: \.self) { item in
                Capsule()
                    .fill(item <= step ? Color.signalOrange : Color.hairline)
                    .frame(maxWidth: .infinity)
                    .frame(height: 5)
            }
        }
        .accessibilityLabel("Step \(step) of 3")
    }

    private var welcome: some View {
        VStack(alignment: .leading, spacing: 0) {
            Spacer()

            Image(systemName: "dumbbell.fill")
                .font(.system(size: 34, weight: .black))
                .foregroundStyle(Color.paper)
                .frame(width: 86, height: 86)
                .background(Color.ink, in: Circle())

            Text("LESS TRACKING.\nMORE LIFTING.")
                .editorialTitle(size: 62, lineSpacing: -8)
                .minimumScaleFactor(0.72)
                .foregroundStyle(Color.ink)
                .padding(.top, 30)

            Text("Liftoff keeps your lifts, records, and progress in one fast training journal.")
                .font(.system(size: 18, weight: .semibold))
                .foregroundStyle(Color.inkMuted)
                .lineSpacing(3)
                .padding(.top, 18)

            Spacer()

            primaryButton(title: "START LIFTING") {
                step = 1
            }
            .padding(.bottom, 22)
        }
        .padding(.horizontal, 26)
    }

    private var experienceStep: some View {
        OnboardingQuestionLayout(
            eyebrow: "01 · EXPERIENCE",
            title: "HOW LONG\nHAVE YOU LIFTED?",
            subtitle: "This keeps your progress context relevant.",
            canContinue: experience != nil,
            onBack: { step = 0 },
            onContinue: { step = 2 }
        ) {
            VStack(spacing: 11) {
                selectionCard("Beginner", detail: "Less than 1 year", selection: $experience)
                selectionCard("Intermediate", detail: "1 to 3 years", selection: $experience)
                selectionCard("Advanced", detail: "More than 3 years", selection: $experience)
            }
        }
    }

    private var goalStep: some View {
        OnboardingQuestionLayout(
            eyebrow: "02 · PRIMARY GOAL",
            title: "WHAT ARE\nYOU CHASING?",
            subtitle: "One answer. You can change it later.",
            canContinue: goal != nil,
            onBack: { step = 1 },
            onContinue: { step = 3 }
        ) {
            VStack(spacing: 11) {
                selectionCard("Strength", detail: "Move more weight", selection: $goal)
                selectionCard("Muscle", detail: "Build size and control", selection: $goal)
                selectionCard("Fat Loss", detail: "Train hard and stay consistent", selection: $goal)
            }
        }
    }

    private var metricsStep: some View {
        OnboardingQuestionLayout(
            eyebrow: "03 · YOUR METRICS",
            title: "SET YOUR\nBASELINE.",
            subtitle: "These details keep your training records accurate.",
            canContinue: validMetrics,
            onBack: { step = 2 },
            onContinue: finish
        ) {
            HStack(spacing: 12) {
                metricField(
                    title: "BODYWEIGHT",
                    value: $bodyweight,
                    placeholder: "175",
                    unit: "LB"
                )
                metricField(
                    title: "HEIGHT",
                    value: $height,
                    placeholder: "70",
                    unit: "IN"
                )
            }
        }
    }

    private func selectionCard(
        _ title: String,
        detail: String,
        selection: Binding<String?>
    ) -> some View {
        let isSelected = selection.wrappedValue == title
        return Button {
            selection.wrappedValue = title
        } label: {
            HStack(spacing: 14) {
                ZStack {
                    Circle()
                        .stroke(isSelected ? Color.signalOrange : Color.hairline, lineWidth: 2)
                        .frame(width: 28, height: 28)
                    if isSelected {
                        Circle()
                            .fill(Color.signalOrange)
                            .frame(width: 16, height: 16)
                    }
                }

                VStack(alignment: .leading, spacing: 3) {
                    Text(title)
                        .font(.system(size: 20, weight: .black))
                        .fontWidth(.condensed)
                        .foregroundStyle(Color.ink)
                    Text(detail)
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(Color.inkMuted)
                }
                Spacer()
            }
            .padding(17)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                isSelected ? Color.signalOrange.opacity(0.08) : Color.paperRaised,
                in: RoundedRectangle(cornerRadius: 17)
            )
            .overlay {
                RoundedRectangle(cornerRadius: 17)
                    .stroke(isSelected ? Color.signalOrange : Color.hairline, lineWidth: 1.5)
            }
        }
        .buttonStyle(.plain)
    }

    private func metricField(
        title: String,
        value: Binding<String>,
        placeholder: String,
        unit: String
    ) -> some View {
        VStack(spacing: 12) {
            Text(title)
                .sectionEyebrow()
            TextField(placeholder, text: value)
                .font(.system(size: 44, weight: .black))
                .fontWidth(.compressed)
                .multilineTextAlignment(.center)
                .keyboardType(.decimalPad)
                .foregroundStyle(Color.ink)
            Text(unit)
                .font(.system(size: 11, weight: .black))
                .tracking(1.3)
                .foregroundStyle(Color.inkMuted)
        }
        .padding(.vertical, 22)
        .frame(maxWidth: .infinity)
        .cardStyle(cornerRadius: 18)
    }

    private func primaryButton(title: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack {
                Text(title)
                    .font(.system(size: 20, weight: .black))
                    .fontWidth(.compressed)
                    .tracking(0.8)
                Spacer()
                Image(systemName: "arrow.right")
                    .font(.system(size: 17, weight: .black))
            }
            .padding(.horizontal, 22)
            .frame(maxWidth: .infinity)
            .frame(height: 64)
        }
        .buttonStyle(OrangeButtonStyle())
    }

    private var validMetrics: Bool {
        (Double(bodyweight) ?? 0) > 0 && (Double(height) ?? 0) > 0
    }

    private func finish() {
        guard let experience,
              let goal,
              let bodyweight = Double(bodyweight),
              let height = Double(height) else {
            return
        }
        onComplete(
            ProfileDraft(
                experience: experience,
                goal: goal,
                bodyweight: bodyweight,
                height: height
            )
        )
    }
}

struct OnboardingQuestionLayout<Content: View>: View {
    let eyebrow: String
    let title: String
    let subtitle: String
    let canContinue: Bool
    let onBack: () -> Void
    let onContinue: () -> Void
    @ViewBuilder let content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                Button(action: onBack) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 16, weight: .black))
                        .foregroundStyle(Color.ink)
                        .frame(width: 42, height: 42)
                        .background(Color.hairline.opacity(0.38), in: Circle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Back")
                Spacer()
            }
            .padding(.top, 22)

            Text(eyebrow)
                .sectionEyebrow()
                .padding(.top, 26)

            Text(title)
                .editorialTitle(size: 51, lineSpacing: -7)
                .foregroundStyle(Color.ink)
                .padding(.top, 10)

            Text(subtitle)
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(Color.inkMuted)
                .padding(.top, 12)

            content
                .padding(.top, 30)

            Spacer(minLength: 24)

            Button(action: onContinue) {
                HStack {
                    Text("CONTINUE")
                        .font(.system(size: 20, weight: .black))
                        .fontWidth(.compressed)
                    Spacer()
                    Image(systemName: "arrow.right")
                        .font(.system(size: 16, weight: .black))
                }
                .padding(.horizontal, 22)
                .frame(maxWidth: .infinity)
                .frame(height: 62)
                .opacity(canContinue ? 1 : 0.44)
            }
            .buttonStyle(OrangeButtonStyle())
            .disabled(!canContinue)
            .padding(.bottom, 22)
        }
        .padding(.horizontal, 26)
    }
}

#Preview {
    OnboardingView(onComplete: { _ in })
}
