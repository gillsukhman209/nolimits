import Charts
import SwiftData
import SwiftUI

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

    enum TrendRange: String, CaseIterable, Identifiable {
        case fourWeeks = "4W"
        case threeMonths = "3M"
        case oneYear = "1Y"
        case all = "ALL"
        var id: String { rawValue }

        func contains(_ date: Date, now: Date = .now) -> Bool {
            let calendar = Calendar.current
            switch self {
            case .fourWeeks:
                return date >= (calendar.date(byAdding: .day, value: -28, to: now) ?? now)
            case .threeMonths:
                return date >= (calendar.date(byAdding: .month, value: -3, to: now) ?? now)
            case .oneYear:
                return date >= (calendar.date(byAdding: .year, value: -1, to: now) ?? now)
            case .all:
                return true
            }
        }
    }

    enum ChartMetric: String, CaseIterable, Identifiable {
        case weight = "Weight"
        case estimatedMax = "Est. max"
        case reps = "Reps"
        var id: String { rawValue }
    }

    let exercise: Exercise
    let onLog: (ExerciseSide?) -> Void

    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Query private var profiles: [UserProfile]
    @Query private var entries: [LiftEntry]
    @State private var sideScope: SideScope = .all
    @State private var trendRange: TrendRange = .threeMonths
    @State private var chartMetric: ChartMetric = .weight
    @State private var editPresentation: EditSetPresentation?
    @State private var selectedChartEntryID: UUID?

    init(exercise: Exercise, onLog: @escaping (ExerciseSide?) -> Void) {
        self.exercise = exercise
        self.onLog = onLog
        let name = exercise.name
        _entries = Query(
            filter: #Predicate<LiftEntry> { $0.liftType == name },
            sort: \LiftEntry.date,
            order: .reverse
        )
    }

    private var tracksSides: Bool {
        exercise.sideTracking == .separate || entries.contains { $0.side != .both }
    }

    private var visibleEntries: [LiftEntry] {
        guard let side = sideScope.side else { return entries }
        return entries.filter { $0.side == side }
    }

    private var chartEntries: [LiftEntry] {
        visibleEntries
            .filter { trendRange.contains($0.date) }
            .sorted { $0.date < $1.date }
    }

    private var snapshot: ExerciseProgressSnapshot {
        LiftAnalytics.snapshot(
            entries: visibleEntries,
            bodyweight: profiles.first?.bodyweight ?? 0
        )
    }

    private var repRecords: [WeightRepRecord] {
        LiftAnalytics.weightRepRecords(entries: visibleEntries)
    }

    private var personalBestIDs: Set<UUID> {
        LiftAnalytics.personalBestEntryIDs(entries: entries)
    }

    private var selectedChartEntry: LiftEntry? {
        guard let selectedChartEntryID else { return nil }
        return chartEntries.first { $0.id == selectedChartEntryID }
    }

    private var displayedTrend: Double? {
        if tracksSides && sideScope == .all {
            let sideTrends = [ExerciseSide.left, .right].compactMap { side in
                LiftAnalytics.recentTrendPercent(entries: entries.filter { $0.side == side })
            }
            guard !sideTrends.isEmpty else {
                return LiftAnalytics.recentTrendPercent(entries: visibleEntries)
            }
            return sideTrends.reduce(0, +) / Double(sideTrends.count)
        }
        return snapshot.trendPercent
    }

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 22) {
                header
                if tracksSides { sidePicker }
                progressHero
                metricsGrid
                if snapshot.bestEntry != nil { nextTargetCard }
                if chartEntries.count > 1 { chartCard }
                if !repRecords.isEmpty { repRecordSection }
                historySection
            }
            .padding(.horizontal, 24)
            .padding(.top, 12)
            .padding(.bottom, 110)
        }
        .background(Color.paper.ignoresSafeArea())
        .safeAreaInset(edge: .bottom) { logButton }
        .toolbar(.hidden, for: .navigationBar)
        .sheet(item: $editPresentation) { presentation in
            EditSetSheet(entry: presentation.entry)
        }
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
                Text(exercise.muscleGroup.rawValue.uppercased())
                    .font(.system(size: 11, weight: .black))
                    .tracking(1.6)
                    .foregroundStyle(Color.inkMuted)
            }

            HStack(alignment: .bottom, spacing: 14) {
                ExerciseIcon(muscleGroup: exercise.muscleGroup, size: 58, inverted: true)
                Text(exercise.name.uppercased())
                    .editorialTitle(size: 44, lineSpacing: -5)
                    .minimumScaleFactor(0.62)
                    .foregroundStyle(Color.ink)
                    .lineLimit(2)
            }
        }
    }

    private var sidePicker: some View {
        HStack(spacing: 4) {
            ForEach(SideScope.allCases) { scope in
                Button {
                    withAnimation(.easeOut(duration: 0.18)) { sideScope = scope }
                } label: {
                    Text(scope.rawValue.uppercased())
                        .font(.system(size: 12, weight: .black))
                        .fontWidth(.condensed)
                        .tracking(0.8)
                        .foregroundStyle(sideScope == scope ? Color.paper : Color.inkMuted)
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
        .background(Color.hairline.opacity(0.34), in: RoundedRectangle(cornerRadius: 14))
    }

    private var progressHero: some View {
        VStack(alignment: .leading, spacing: 17) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("PERFORMANCE TREND")
                        .font(.system(size: 11, weight: .black))
                        .tracking(1.8)
                        .foregroundStyle(Color.signalPaper.opacity(0.62))
                    Text(trendHeadline)
                        .font(.system(size: 31, weight: .black))
                        .fontWidth(.compressed)
                        .foregroundStyle(Color.signalPaper)
                }
                Spacer()
                Image(systemName: trendIcon)
                    .font(.system(size: 26, weight: .black))
                    .foregroundStyle(Color.signalOrange)
            }

            Text(trendDetail)
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(Color.signalPaper.opacity(0.66))

            if let best = snapshot.bestEntry {
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("BEST PR")
                            .font(.system(size: 9, weight: .black))
                            .tracking(1.2)
                            .foregroundStyle(Color.signalPaper.opacity(0.52))
                        Text(setDescription(best))
                            .font(.system(size: 18, weight: .black))
                            .fontWidth(.condensed)
                            .foregroundStyle(Color.signalPaper)
                    }
                    Spacer()
                    Text(best.date.formatted(date: .abbreviated, time: .omitted))
                        .font(.system(size: 11, weight: .bold))
                        .foregroundStyle(Color.signalPaper.opacity(0.58))
                }
                .padding(.top, 2)
            }
        }
        .padding(20)
        .background(Color.signalInk, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
        .accessibilityElement(children: .combine)
    }

    private var trendHeadline: String {
        guard let trend = displayedTrend else {
            return visibleEntries.isEmpty ? "NO SETS YET" : "BASELINE SAVED"
        }
        if trend > 1 { return "UP \(trend.formatted(.number.precision(.fractionLength(1))))%" }
        if trend < -1 { return "DOWN \(abs(trend).formatted(.number.precision(.fractionLength(1))))%" }
        return "HOLDING STEADY"
    }

    private var trendIcon: String {
        guard let trend = displayedTrend else { return "scope" }
        if trend > 1 { return "arrow.up.right" }
        if trend < -1 { return "arrow.down.right" }
        return "arrow.right"
    }

    private var trendDetail: String {
        guard displayedTrend != nil else {
            return visibleEntries.count < 2
                ? "Save at least two sets to calculate a performance trend."
                : "Add more sets to establish a reliable trend."
        }
        return "Compares the estimated-max average from your earliest and most recent sets in this view."
    }

    private var metricsGrid: some View {
        VStack(spacing: 10) {
            HStack(spacing: 10) {
                DetailMetricTile(
                    label: exercise.loadType == .assistance ? "BEST ASSISTANCE" : "BEST SET",
                    value: snapshot.bestEntry.map(setDescription) ?? "—",
                    detail: "highest estimated performance"
                )
                DetailMetricTile(
                    label: exercise.loadType == .assistance ? "EFFECTIVE MAX" : "ESTIMATED MAX",
                    value: snapshot.bestEntry.map { "\($0.e1RM.formattedWeight) lb" } ?? "—",
                    detail: "calculated from weight × reps"
                )
            }
            HStack(spacing: 10) {
                DetailMetricTile(
                    label: exercise.loadType == .assistance ? "RECENT ASSIST." : "RECENT AVG.",
                    value: visibleEntries.isEmpty ? "—" : "\(snapshot.recentAverageWeight.formattedWeight) lb",
                    detail: "average of last 5 sets"
                )
                DetailMetricTile(
                    label: "HISTORY",
                    value: "\(snapshot.setCount) sets",
                    detail: "across \(snapshot.trainingDays) training day\(snapshot.trainingDays == 1 ? "" : "s")"
                )
            }
        }
    }

    private var nextTargetCard: some View {
        HStack(spacing: 13) {
            Image(systemName: "scope")
                .font(.system(size: 16, weight: .black))
                .foregroundStyle(Color.signalOrange)
                .frame(width: 40, height: 40)
                .background(Color.signalOrange.opacity(0.1), in: Circle())
            VStack(alignment: .leading, spacing: 2) {
                Text("NEXT MILESTONE").sectionEyebrow()
                Text(nextTargetDescription)
                    .font(.system(size: 18, weight: .black))
                    .fontWidth(.condensed)
                    .foregroundStyle(Color.ink)
            }
            Spacer()
        }
        .padding(15)
        .cardStyle(cornerRadius: 16)
        .accessibilityElement(children: .combine)
    }

    private var nextTargetDescription: String {
        guard let best = snapshot.bestEntry else { return "Log a baseline set" }
        let side = best.side == .both ? "" : "\(best.side.rawValue) · "
        if exercise.loadType == .assistance {
            return best.weight > 0
                ? "\(side)\(max(best.weight - 5, 0).formattedWeight) lb assist × \(best.reps)"
                : "\(side)0 lb assist × \(best.reps + 1)"
        }
        return best.reps >= 12
            ? "\(side)\((best.weight + 5).formattedWeight) lb × 8"
            : "\(side)\(best.weight.formattedWeight) lb × \(best.reps + 1)"
    }

    private var chartCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("EVERY SET, CHARTED").sectionEyebrow()
                    Text(chartSubtitle)
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(Color.inkMuted)
                }
                Spacer()
                Text("\(chartEntries.count) sets")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundStyle(Color.inkMuted)
            }

            HStack(spacing: 4) {
                ForEach(ChartMetric.allCases) { metric in
                    selectionButton(metric.rawValue, isSelected: chartMetric == metric) {
                        withAnimation(.easeOut(duration: 0.18)) { chartMetric = metric }
                    }
                }
            }
            .selectionBarStyle()

            chartSelectionDetail

            Chart(chartEntries, id: \.id) { entry in
                LineMark(
                    x: .value("Date", entry.date),
                    y: .value(chartMetric.rawValue, chartValue(entry))
                )
                .foregroundStyle(by: .value("Side", chartSeries(entry)))
                .lineStyle(StrokeStyle(lineWidth: 2.8, lineCap: .round, lineJoin: .round))
                .interpolationMethod(.catmullRom)

                PointMark(
                    x: .value("Date", entry.date),
                    y: .value(chartMetric.rawValue, chartValue(entry))
                )
                .foregroundStyle(by: .value("Side", chartSeries(entry)))
                .symbolSize(
                    selectedChartEntryID == entry.id
                        ? 92
                        : (personalBestIDs.contains(entry.id) ? 42 : 24)
                )

                if selectedChartEntryID == entry.id {
                    RuleMark(x: .value("Selected date", entry.date))
                        .foregroundStyle(Color.ink.opacity(0.52))
                        .lineStyle(StrokeStyle(lineWidth: 1, dash: [4, 4]))
                }
            }
            .chartForegroundStyleScale([
                "All sets": Color.signalOrange,
                "Both": Color.signalOrange,
                "Left": Color(red: 0.18, green: 0.48, blue: 0.78),
                "Right": Color.success,
            ])
            .chartXAxis {
                AxisMarks(values: .automatic(desiredCount: 4)) { value in
                    AxisGridLine().foregroundStyle(Color.hairline.opacity(0.38))
                    AxisValueLabel(format: .dateTime.month(.abbreviated).day())
                        .font(.system(size: 9, weight: .bold))
                        .foregroundStyle(Color.inkMuted)
                }
            }
            .chartYAxis {
                AxisMarks(position: .leading, values: .automatic(desiredCount: 4)) {
                    AxisGridLine().foregroundStyle(Color.hairline.opacity(0.5))
                    AxisValueLabel()
                        .font(.system(size: 9, weight: .bold))
                        .foregroundStyle(Color.inkMuted)
                }
            }
            .chartLegend(tracksSides && sideScope == .all ? .visible : .hidden)
            .chartOverlay { proxy in
                GeometryReader { geometry in
                    Rectangle()
                        .fill(Color.clear)
                        .contentShape(Rectangle())
                        .gesture(
                            DragGesture(minimumDistance: 0)
                                .onChanged { value in
                                    selectChartEntry(
                                        at: value.location,
                                        proxy: proxy,
                                        geometry: geometry
                                    )
                                }
                        )
                }
            }
            .frame(height: 220)
            .accessibilityLabel("\(chartMetric.rawValue) chart for \(exercise.name)")
            .accessibilityHint("Press and drag across the chart to inspect each set")

            HStack(spacing: 4) {
                ForEach(TrendRange.allCases) { range in
                    selectionButton(range.rawValue, isSelected: trendRange == range) {
                        withAnimation(.easeOut(duration: 0.18)) { trendRange = range }
                    }
                }
            }
            .selectionBarStyle()
        }
        .padding(18)
        .cardStyle(cornerRadius: 18)
        .onChange(of: trendRange) { selectedChartEntryID = nil }
        .onChange(of: chartMetric) { selectedChartEntryID = nil }
        .onChange(of: sideScope) { selectedChartEntryID = nil }
        .sensoryFeedback(.selection, trigger: selectedChartEntryID)
    }

    @ViewBuilder
    private var chartSelectionDetail: some View {
        if let entry = selectedChartEntry {
            HStack(spacing: 12) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(entry.date.formatted(date: .abbreviated, time: .shortened).uppercased())
                        .font(.system(size: 9, weight: .black))
                        .tracking(0.8)
                        .foregroundStyle(Color.inkMuted)
                    Text(setDescription(entry))
                        .font(.system(size: 18, weight: .black))
                        .fontWidth(.condensed)
                        .foregroundStyle(Color.ink)
                }
                Spacer()
                VStack(alignment: .trailing, spacing: 2) {
                    if personalBestIDs.contains(entry.id) {
                        Text("PR")
                            .font(.system(size: 9, weight: .black))
                            .foregroundStyle(Color.white)
                            .padding(.horizontal, 7)
                            .padding(.vertical, 3)
                            .background(Color.signalOrange, in: Capsule())
                    }
                    Text("Est. \(entry.e1RM.formattedWeight) lb")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundStyle(Color.inkMuted)
                }
            }
            .padding(.horizontal, 13)
            .frame(height: 58)
            .background(Color.hairline.opacity(0.28), in: RoundedRectangle(cornerRadius: 12))
            .accessibilityElement(children: .combine)
        } else {
            Label("Hold and drag across the chart to inspect each set", systemImage: "hand.draw")
                .font(.system(size: 11, weight: .bold))
                .foregroundStyle(Color.inkMuted)
                .frame(maxWidth: .infinity, alignment: .leading)
                .frame(height: 34)
        }
    }

    private func selectChartEntry(
        at location: CGPoint,
        proxy: ChartProxy,
        geometry: GeometryProxy
    ) {
        guard let plotFrame = proxy.plotFrame else { return }
        let frame = geometry[plotFrame]
        guard frame.contains(location) else { return }
        let xPosition = location.x - frame.origin.x
        guard let selectedDate: Date = proxy.value(atX: xPosition),
              let nearest = LiftAnalytics.nearestEntry(
                  to: selectedDate,
                  entries: chartEntries
              ) else { return }
        selectedChartEntryID = nearest.id
    }

    private var chartSubtitle: String {
        switch chartMetric {
        case .weight:
            return exercise.loadType == .assistance
                ? "Assistance used for each set · lower is harder"
                : "Actual working weight used for every set"
        case .estimatedMax:
            return "Weight and reps combined into one performance estimate"
        case .reps:
            return "Repetitions completed in every set"
        }
    }

    private func chartValue(_ entry: LiftEntry) -> Double {
        switch chartMetric {
        case .weight: return entry.weight
        case .estimatedMax: return entry.e1RM
        case .reps: return Double(entry.reps)
        }
    }

    private func chartSeries(_ entry: LiftEntry) -> String {
        if tracksSides && sideScope == .all { return entry.side.rawValue }
        return "All sets"
    }

    private func selectionButton(
        _ title: String,
        isSelected: Bool,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            Text(title.uppercased())
                .font(.system(size: 9, weight: .black))
                .tracking(0.3)
                .foregroundStyle(isSelected ? Color.paper : Color.inkMuted)
                .frame(maxWidth: .infinity)
                .frame(height: 31)
                .background(isSelected ? Color.ink : Color.clear)
                .clipShape(RoundedRectangle(cornerRadius: 8))
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }

    private var repRecordSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            VStack(alignment: .leading, spacing: 2) {
                Text("REP RECORDS BY WEIGHT").sectionEyebrow()
                Text(exercise.loadType == .assistance
                     ? "Your best reps at each assistance level"
                     : "Your best reps at every weight you have used")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(Color.inkMuted)
            }

            ForEach(repRecords) { record in
                HStack(spacing: 13) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(record.loadType == .assistance ? "ASSISTANCE" : "WEIGHT")
                            .font(.system(size: 9, weight: .black))
                            .tracking(1)
                            .foregroundStyle(Color.inkMuted)
                        Text("\(record.weight.formattedWeight) lb")
                            .font(.system(size: 22, weight: .black))
                            .fontWidth(.compressed)
                            .foregroundStyle(Color.ink)
                    }
                    if record.side != .both {
                        Text(record.side.shortLabel)
                            .font(.system(size: 9, weight: .black))
                            .foregroundStyle(Color.ink)
                            .frame(width: 25, height: 25)
                            .background(Color.hairline.opacity(0.5), in: Circle())
                    }
                    Spacer()
                    VStack(alignment: .trailing, spacing: 2) {
                        Text("\(record.reps) REPS")
                            .font(.system(size: 19, weight: .black))
                            .fontWidth(.condensed)
                            .foregroundStyle(Color.signalOrange)
                        Text("\(record.setCount) set\(record.setCount == 1 ? "" : "s") · \(record.achievedAt.formatted(date: .abbreviated, time: .omitted))")
                            .font(.system(size: 10, weight: .medium))
                            .foregroundStyle(Color.inkMuted)
                    }
                }
                .padding(14)
                .cardStyle(cornerRadius: 15)
                .accessibilityElement(children: .combine)
            }
        }
    }

    private var historySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("ALL SETS").sectionEyebrow()
                Spacer()
                if !visibleEntries.isEmpty {
                    Text("\(snapshot.totalVolume.formattedWeight) lb work")
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
                        isPersonalBest: personalBestIDs.contains(entry.id),
                        onEdit: { editPresentation = EditSetPresentation(entry: entry) },
                        onDelete: { delete(entry) }
                    )
                }
            }
        }
    }

    private var emptyHistoryMessage: String {
        if let side = sideScope.side {
            return "No \(side.rawValue.lowercased())-side sets yet."
        }
        return "No \(exercise.name) sets yet."
    }

    private var logButton: some View {
        Button {
            let preferredSide = sideScope.side ?? (tracksSides ? .left : nil)
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

    private var logButtonTitle: String {
        let sidePrefix = sideScope.side.map { "\($0.rawValue.uppercased()) " } ?? ""
        return "LOG \(sidePrefix)\(exercise.name.uppercased())"
    }

    private func setDescription(_ entry: LiftEntry) -> String {
        let side = entry.side == .both ? "" : "\(entry.side.shortLabel) · "
        let assistance = entry.loadType == .assistance ? " assist" : ""
        return "\(side)\(entry.weight.formattedWeight) lb\(assistance) × \(entry.reps)"
    }

    private func delete(_ entry: LiftEntry) {
        withAnimation(.easeOut(duration: 0.2)) {
            AppStatsSynchronizer.delete(entry, context: modelContext)
        }
    }
}

private extension View {
    func selectionBarStyle() -> some View {
        padding(3)
            .background(Color.hairline.opacity(0.3), in: RoundedRectangle(cornerRadius: 10))
    }
}

struct DetailMetricTile: View {
    let label: String
    let value: String
    let detail: String

    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            Text(label)
                .font(.system(size: 9, weight: .black))
                .tracking(1.1)
                .foregroundStyle(Color.inkMuted)
            Text(value)
                .font(.system(size: 20, weight: .black))
                .fontWidth(.compressed)
                .foregroundStyle(Color.ink)
                .minimumScaleFactor(0.58)
                .lineLimit(1)
            Text(detail)
                .font(.system(size: 9, weight: .medium))
                .foregroundStyle(Color.inkFaint)
                .lineLimit(1)
                .minimumScaleFactor(0.75)
        }
        .padding(13)
        .frame(maxWidth: .infinity, minHeight: 88, alignment: .leading)
        .cardStyle(cornerRadius: 15)
    }
}

struct ExerciseLogRow: View {
    let entry: LiftEntry
    let isPersonalBest: Bool
    let onEdit: () -> Void
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
                Text("PR")
                    .font(.system(size: 10, weight: .black))
                    .foregroundStyle(Color.white)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 5)
                    .background(Color.signalOrange, in: Capsule())
            }
            if entry.side != .both {
                Text(entry.side.shortLabel)
                    .font(.system(size: 9, weight: .black))
                    .foregroundStyle(Color.ink)
                    .frame(width: 24, height: 24)
                    .background(Color.hairline.opacity(0.55), in: Circle())
            }
            VStack(alignment: .trailing, spacing: 2) {
                Text(loadDescription)
                    .font(.system(size: 18, weight: .black))
                    .fontWidth(.condensed)
                    .foregroundStyle(Color.ink)
                Text("Est. max \(entry.e1RM.formattedWeight) lb")
                    .font(.system(size: 10, weight: .medium))
                    .foregroundStyle(Color.inkMuted)
            }
            Menu {
                Button(action: onEdit) { Label("Edit set", systemImage: "pencil") }
                Button(role: .destructive, action: onDelete) {
                    Label("Delete set", systemImage: "trash")
                }
            } label: {
                Image(systemName: "ellipsis")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(Color.inkMuted)
                    .frame(width: 28, height: 40)
            }
        }
        .padding(14)
        .cardStyle(cornerRadius: 16)
        .accessibilityElement(children: .combine)
    }

    private var loadDescription: String {
        let suffix = entry.loadType == .assistance ? " assist" : ""
        return "\(entry.weight.formattedWeight) lb\(suffix) × \(entry.reps)"
    }
}
