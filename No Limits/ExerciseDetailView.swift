import SwiftUI
import SwiftData
import Charts

struct ExerciseDetailView: View {
    enum SideScope: String, CaseIterable, Identifiable {
        case all = "All"
        case left = "Left"
        case right = "Right"

        var id: String { rawValue }

        var side: ExerciseSide? {
            switch self {
            case .all: return nil
            case .left: return .left
            case .right: return .right
            }
        }
    }

    let exercise: Exercise
    let onLog: (ExerciseSide?) -> Void

    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Query private var profiles: [UserProfile]
    @Query private var entries: [LiftEntry]
    @State private var sideScope: SideScope = .all

    init(
        exercise: Exercise,
        onLog: @escaping (ExerciseSide?) -> Void
    ) {
        self.exercise = exercise
        self.onLog = onLog
        let name = exercise.name
        _entries = Query(
            filter: #Predicate<LiftEntry> { $0.liftType == name },
            sort: \LiftEntry.date,
            order: .reverse
        )
    }

    private var exerciseName: String { exercise.name }
    private var muscleGroup: MuscleGroup { exercise.muscleGroup }

    private var tracksSides: Bool {
        exercise.sideTracking == .separate
            || entries.contains { $0.side != .both }
    }

    private var visibleEntries: [LiftEntry] {
        guard let side = sideScope.side else { return entries }
        return entries.filter { $0.side == side }
    }

    private var bestEntry: LiftEntry? {
        visibleEntries.max(by: { $0.e1RM < $1.e1RM })
    }

    private var overview: StrengthOverview {
        LiftAnalytics.exerciseScore(
            entries: visibleEntries,
            bodyweight: profiles.first?.bodyweight ?? 0
        )
    }

    private var trendEntries: [LiftEntry] {
        Array(visibleEntries.sorted { $0.date < $1.date }.suffix(12))
    }

    private var visibleVolume: Double {
        LiftAnalytics.totalVolume(
            entries: visibleEntries,
            bodyweight: profiles.first?.bodyweight ?? 0
        )
    }

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 24) {
                header
                if tracksSides {
                    sidePicker
                }
                metrics

                if ExerciseCatalog.isRanked(exerciseName), !visibleEntries.isEmpty {
                    rankCard
                }

                if visibleEntries.count > 1,
                   !tracksSides || sideScope != .all {
                    trendCard
                }

                history
            }
            .padding(.horizontal, 24)
            .padding(.top, 12)
            .padding(.bottom, 110)
        }
        .background(Color.paper.ignoresSafeArea())
        .safeAreaInset(edge: .bottom) {
            Button {
                let preferredSide = sideScope.side
                    ?? (tracksSides ? .left : nil)
                onLog(preferredSide)
            } label: {
                HStack(spacing: 10) {
                    Image(systemName: "plus")
                        .font(.system(size: 15, weight: .black))
                    Text(logButtonTitle)
                        .font(.system(size: 18, weight: .black))
                        .fontWidth(.compressed)
                        .lineLimit(1)
                }
                .frame(maxWidth: .infinity)
                .frame(height: 58)
            }
            .buttonStyle(OrangeButtonStyle())
            .padding(.horizontal, 24)
            .padding(.vertical, 10)
            .background(.ultraThinMaterial)
        }
        .toolbar(.hidden, for: .navigationBar)
    }

    private var logButtonTitle: String {
        let sidePrefix = sideScope.side.map { "\($0.rawValue.uppercased()) " } ?? ""
        return "LOG \(sidePrefix)\(exerciseName.uppercased())"
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Button { dismiss() } label: {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 16, weight: .black))
                        .foregroundStyle(Color.ink)
                        .frame(width: 42, height: 42)
                        .background(Color.hairline.opacity(0.38), in: Circle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Back")

                Spacer()

                Text(muscleGroup.rawValue.uppercased())
                    .font(.system(size: 11, weight: .black))
                    .tracking(1.6)
                    .foregroundStyle(Color.inkMuted)
            }

            HStack(alignment: .bottom, spacing: 14) {
                ExerciseIcon(muscleGroup: muscleGroup, size: 58, inverted: true)
                Text(exerciseName.uppercased())
                    .editorialTitle(size: 46, lineSpacing: -5)
                    .minimumScaleFactor(0.66)
                    .foregroundStyle(Color.ink)
                    .lineLimit(2)
            }
        }
    }

    private var sidePicker: some View {
        HStack(spacing: 4) {
            ForEach(SideScope.allCases) { scope in
                Button {
                    withAnimation(.easeOut(duration: 0.18)) {
                        sideScope = scope
                    }
                } label: {
                    Text(scope.rawValue.uppercased())
                        .font(.system(size: 12, weight: .black))
                        .fontWidth(.condensed)
                        .tracking(0.8)
                        .foregroundStyle(
                            sideScope == scope ? Color.paper : Color.inkMuted
                        )
                        .frame(maxWidth: .infinity)
                        .frame(height: 40)
                        .background(sideScope == scope ? Color.ink : Color.clear)
                        .clipShape(RoundedRectangle(cornerRadius: 11))
                }
                .buttonStyle(.plain)
                .accessibilityAddTraits(sideScope == scope ? .isSelected : [])
            }
        }
        .padding(4)
        .background(
            Color.hairline.opacity(0.34),
            in: RoundedRectangle(cornerRadius: 14)
        )
    }

    @ViewBuilder
    private var metrics: some View {
        if tracksSides, sideScope == .all {
            HStack(spacing: 10) {
                sideMetric(side: .left)
                sideMetric(side: .right)
                MetricTile(
                    label: "LOGS",
                    value: "\(entries.count)",
                    detail: entries.count == 1 ? "entry" : "entries"
                )
            }
        } else {
            HStack(spacing: 10) {
                MetricTile(
                    label: exercise.loadType == .assistance
                        ? "BEST ASSIST."
                        : "BEST SET",
                    value: bestEntry.map {
                        "\($0.weight.formattedWeight) × \($0.reps)"
                    } ?? "—",
                    detail: "lb × reps"
                )
                MetricTile(
                    label: exercise.loadType == .assistance
                        ? "EFFECTIVE MAX"
                        : "EST. MAX",
                    value: bestEntry.map { $0.e1RM.formattedWeight } ?? "—",
                    detail: "lb"
                )
                MetricTile(
                    label: "LOGS",
                    value: "\(visibleEntries.count)",
                    detail: visibleEntries.count == 1 ? "entry" : "entries"
                )
            }
        }
    }

    private func sideMetric(side: ExerciseSide) -> some View {
        let best = entries
            .filter { $0.side == side }
            .max(by: { $0.e1RM < $1.e1RM })
        return MetricTile(
            label: "\(side.rawValue.uppercased()) PB",
            value: best.map {
                "\($0.weight.formattedWeight) × \($0.reps)"
            } ?? "—",
            detail: "lb × reps"
        )
    }

    private var rankCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("EXERCISE RANK")
                        .sectionEyebrow()
                    Text(overview.rank.rawValue.uppercased())
                        .font(.system(size: 30, weight: .black))
                        .fontWidth(.compressed)
                        .foregroundStyle(Color.ink)
                }
                Spacer()
                Text(String(format: "%.2f×", overview.score))
                    .font(.system(size: 30, weight: .black))
                    .fontWidth(.compressed)
                    .foregroundStyle(overview.rank.color)
            }

            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    Capsule().fill(Color.hairline.opacity(0.5))
                    Capsule()
                        .fill(Color.signalOrange)
                        .frame(width: max(8, geometry.size.width * overview.progress))
                }
            }
            .frame(height: 8)

            HStack {
                Text("\(Int(overview.progress * 100))% through \(overview.rank.rawValue)")
                Spacer()
                Text(overview.rank.nextRank.map { "Next: \($0.rawValue)" } ?? "Top rank")
            }
            .font(.system(size: 12, weight: .bold))
            .foregroundStyle(Color.inkMuted)
        }
        .padding(18)
        .cardStyle(cornerRadius: 18)
    }

    private var trendCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .firstTextBaseline) {
                Text(
                    exercise.loadType == .assistance
                        ? "EFFECTIVE LOAD TREND"
                        : "E1RM TREND"
                )
                    .sectionEyebrow()
                Spacer()
                if let change = LiftAnalytics.changePercent(entries: visibleEntries) {
                    Text("\(change >= 0 ? "+" : "")\(change, format: .number.precision(.fractionLength(1)))%")
                        .font(.system(size: 13, weight: .black))
                        .foregroundStyle(change >= 0 ? Color.success : Color.inkMuted)
                }
            }

            Chart(trendEntries, id: \.id) { entry in
                AreaMark(
                    x: .value("Date", entry.date),
                    y: .value("Performance max", entry.e1RM)
                )
                .foregroundStyle(
                    LinearGradient(
                        colors: [.signalOrange.opacity(0.28), .signalOrange.opacity(0.02)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )

                LineMark(
                    x: .value("Date", entry.date),
                    y: .value("Performance max", entry.e1RM)
                )
                .foregroundStyle(Color.signalOrange)
                .lineStyle(StrokeStyle(lineWidth: 3, lineCap: .round, lineJoin: .round))

                PointMark(
                    x: .value("Date", entry.date),
                    y: .value("Performance max", entry.e1RM)
                )
                .foregroundStyle(Color.ink)
                .symbolSize(24)
            }
            .chartXAxis(.hidden)
            .chartYAxis {
                AxisMarks(position: .leading, values: .automatic(desiredCount: 3)) {
                    AxisGridLine().foregroundStyle(Color.hairline.opacity(0.55))
                    AxisValueLabel()
                        .font(.system(size: 10, weight: .bold))
                        .foregroundStyle(Color.inkMuted)
                }
            }
            .frame(height: 150)
            .accessibilityLabel(
                exercise.loadType == .assistance
                    ? "Effective load trend"
                    : "Estimated one rep max trend"
            )
        }
        .padding(18)
        .cardStyle(cornerRadius: 18)
    }

    private var history: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("ALL LOGS")
                    .sectionEyebrow()
                Spacer()
                if !visibleEntries.isEmpty {
                    Text("\(visibleVolume.formattedWeight) lb work")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundStyle(Color.inkMuted)
                }
            }

            if visibleEntries.isEmpty {
                Text(emptyHistoryMessage)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(Color.inkMuted)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 34)
                    .cardStyle(cornerRadius: 18)
            } else {
                ForEach(visibleEntries, id: \.id) { entry in
                    ExerciseLogRow(
                        entry: entry,
                        isPersonalBest: isPersonalBest(entry),
                        onDelete: { delete(entry) }
                    )
                }
            }
        }
    }

    private var emptyHistoryMessage: String {
        if let side = sideScope.side {
            return "No \(side.rawValue.lowercased())-side logs yet."
        }
        return "No \(exerciseName) logs yet."
    }

    private func isPersonalBest(_ entry: LiftEntry) -> Bool {
        let comparableEntries = tracksSides
            ? entries.filter { $0.side == entry.side }
            : entries
        return entry.id == comparableEntries.max(by: { $0.e1RM < $1.e1RM })?.id
    }

    private func delete(_ entry: LiftEntry) {
        withAnimation(.easeOut(duration: 0.2)) {
            AppStatsSynchronizer.delete(entry, context: modelContext)
        }
    }
}

struct MetricTile: View {
    let label: String
    let value: String
    let detail: String

    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            Text(label)
                .font(.system(size: 10, weight: .black))
                .tracking(1.3)
                .foregroundStyle(Color.inkMuted)
            Text(value)
                .font(.system(size: 21, weight: .black))
                .fontWidth(.compressed)
                .foregroundStyle(Color.ink)
                .minimumScaleFactor(0.65)
                .lineLimit(1)
            Text(detail)
                .font(.system(size: 10, weight: .medium))
                .foregroundStyle(Color.inkFaint)
        }
        .padding(13)
        .frame(maxWidth: .infinity, alignment: .leading)
        .cardStyle(cornerRadius: 15)
    }
}

struct ExerciseLogRow: View {
    let entry: LiftEntry
    let isPersonalBest: Bool
    let onDelete: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 3) {
                Text(entry.date.formatted(date: .abbreviated, time: .omitted).uppercased())
                    .font(.system(size: 11, weight: .black))
                    .tracking(1)
                    .foregroundStyle(Color.inkMuted)
                Text(entry.date.formatted(date: .omitted, time: .shortened))
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(Color.inkFaint)
            }

            Spacer()

            if isPersonalBest {
                Text("PB")
                    .font(.system(size: 10, weight: .black))
                    .foregroundStyle(Color.white)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 5)
                    .background(Color.signalOrange, in: Capsule())
            }

            if entry.side != .both {
                Text(entry.side.shortLabel)
                    .font(.system(size: 10, weight: .black))
                    .foregroundStyle(Color.ink)
                    .frame(width: 26, height: 26)
                    .background(Color.hairline.opacity(0.55), in: Circle())
                    .accessibilityLabel(entry.side.rawValue)
            }

            Text(loadDescription)
                .font(.system(size: 19, weight: .black))
                .fontWidth(.condensed)
                .foregroundStyle(Color.ink)

            Menu {
                Button(role: .destructive, action: onDelete) {
                    Label("Delete log", systemImage: "trash")
                }
            } label: {
                Image(systemName: "ellipsis")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(Color.inkMuted)
                    .frame(width: 28, height: 38)
            }
        }
        .padding(14)
        .cardStyle(cornerRadius: 15)
    }

    private var loadDescription: String {
        let suffix = entry.loadType == .assistance ? " assist" : ""
        return "\(entry.weight.formattedWeight) lb\(suffix) × \(entry.reps)"
    }
}
