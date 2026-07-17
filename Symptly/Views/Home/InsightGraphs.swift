import SwiftUI

// MARK: - 1. Donut Chart Card

struct DonutChartCard: View {
    let entries: [SymptomEntry]

    @State private var animationProgress: CGFloat = 0

    private struct SeverityBucket: Identifiable {
        let id = UUID()
        let label: String
        let color: Color
        let count: Int
    }

    private var buckets: [SeverityBucket] {
        let mild = entries.filter { $0.severity >= 1 && $0.severity <= 3 }.count
        let moderate = entries.filter { $0.severity >= 4 && $0.severity <= 6 }.count
        let severe = entries.filter { $0.severity >= 7 && $0.severity <= 8 }.count
        let critical = entries.filter { $0.severity >= 9 && $0.severity <= 10 }.count
        return [
            SeverityBucket(label: "Mild", color: Color.SS.severityMild, count: mild),
            SeverityBucket(label: "Moderate", color: Color.SS.severityModerate, count: moderate),
            SeverityBucket(label: "Severe", color: Color.SS.severitySevere, count: severe),
            SeverityBucket(label: "Critical", color: Color.SS.severityCritical, count: critical),
        ].filter { $0.count > 0 }
    }

    private var total: Int { entries.count }

    var body: some View {
        SSCard(padding: Spacing.lg) {
            VStack(spacing: Spacing.md) {
                // Header
                HStack {
                    Text("Severity Distribution")
                        .font(Font.SS.labelMedium)
                        .foregroundColor(Color.SS.textTertiary)
                        .tracking(0.5)
                    Spacer()
                    SSChip(label: "\(total) entries", color: Color.SS.accent)
                }

                if buckets.isEmpty {
                    emptyState
                } else {
                    // Donut
                    ZStack {
                        donutRing
                        centerLabel
                    }
                    .frame(height: 170)
                    .padding(.vertical, Spacing.xs)

                    // Legend
                    legendGrid
                }
            }
        }
        .onAppear {
            withAnimation(.easeOut(duration: 1.0).delay(0.2)) {
                animationProgress = 1
            }
        }
    }

    // MARK: - Donut Ring

    private var donutRing: some View {
        GeometryReader { geo in
            let size = min(geo.size.width, geo.size.height)
            let lineWidth: CGFloat = 22
            let center = CGPoint(x: geo.size.width / 2, y: geo.size.height / 2)
            let radius = (size - lineWidth) / 2

            Canvas { context, canvasSize in
                let total = CGFloat(buckets.map(\.count).reduce(0, +))
                guard total > 0 else { return }

                let gap: CGFloat = 0.02 // gap between segments in radians
                var currentAngle: CGFloat = -.pi / 2

                for bucket in buckets {
                    let fraction = CGFloat(bucket.count) / total
                    let sweep = (2 * .pi - gap * CGFloat(buckets.count)) * fraction * animationProgress

                    var segmentPath = Path()
                    segmentPath.addArc(
                        center: center,
                        radius: radius,
                        startAngle: .radians(Double(currentAngle)),
                        endAngle: .radians(Double(currentAngle + sweep)),
                        clockwise: false
                    )

                    context.stroke(
                        segmentPath,
                        with: .color(bucket.color),
                        style: StrokeStyle(lineWidth: lineWidth, lineCap: .round)
                    )

                    currentAngle += sweep + gap
                }
            }
        }
    }

    // MARK: - Center Label

    private var centerLabel: some View {
        VStack(spacing: 2) {
            Text("\(total)")
                .font(Font.SS.dataMedium)
                .foregroundColor(Color.SS.textPrimary)
                .contentTransition(.numericText())
            Text("total")
                .font(Font.SS.caption)
                .foregroundColor(Color.SS.textTertiary)
        }
    }

    // MARK: - Legend

    private var legendGrid: some View {
        LazyVGrid(columns: [
            GridItem(.flexible()),
            GridItem(.flexible()),
        ], spacing: Spacing.xs) {
            ForEach(buckets) { bucket in
                HStack(spacing: Spacing.xs) {
                    Circle()
                        .fill(bucket.color)
                        .frame(width: 8, height: 8)
                    Text(bucket.label)
                        .font(Font.SS.caption)
                        .foregroundColor(Color.SS.textSecondary)
                    Spacer()
                    Text("\(bucket.count)")
                        .font(Font.SS.labelMedium)
                        .foregroundColor(Color.SS.textPrimary)
                        .monospacedDigit()
                }
            }
        }
    }

    // MARK: - Empty

    private var emptyState: some View {
        VStack(spacing: Spacing.sm) {
            SSIconImage(name: "ss.ecg", size: 28)
                .foregroundColor(Color.SS.textDisabled)
            Text("No entries yet")
                .font(Font.SS.bodySmall)
                .foregroundColor(Color.SS.textTertiary)
        }
        .frame(height: 140)
    }
}


// MARK: - 2. Category Breakdown Card

struct CategoryBreakdownCard: View {
    let entries: [SymptomEntry]
    var customSymptoms: [Symptom] = []

    @State private var barProgress: CGFloat = 0

    private struct CategoryRow: Identifiable {
        let id = UUID()
        let category: SymptomCategory
        let count: Int
        let percentage: Double
    }

    private var rows: [CategoryRow] {
        guard !entries.isEmpty else { return [] }

        // Scope to last 30 days for relevance
        let cutoff = Date().addingTimeInterval(-30 * 86400)
        let recent = entries.filter { $0.timestamp >= cutoff }
        guard !recent.isEmpty else { return [] }

        var categoryCount: [SymptomCategory: Int] = [:]
        for entry in recent {
            // Skip entries with no matching symptom definition rather than mis-bucketing
            if let symptom = Symptom.find(entry.symptomName, customSymptoms: customSymptoms) {
                categoryCount[symptom.category, default: 0] += 1
            }
        }

        let total = Double(recent.count)
        return categoryCount
            .sorted { $0.value > $1.value }
            .map { CategoryRow(category: $0.key, count: $0.value, percentage: Double($0.value) / total) }
    }

    private var maxCount: Int {
        rows.map(\.count).max() ?? 1
    }

    var body: some View {
        SSCard(padding: Spacing.lg) {
            VStack(alignment: .leading, spacing: Spacing.md) {
                // Header
                HStack {
                    Text("Category Breakdown")
                        .font(Font.SS.labelMedium)
                        .foregroundColor(Color.SS.textTertiary)
                        .tracking(0.5)
                    Spacer()
                    SSChip(label: "\(rows.count) categories", color: Color.SS.violet)
                }

                if rows.isEmpty {
                    emptyCategoryState
                } else {
                    VStack(spacing: Spacing.sm) {
                        ForEach(rows) { row in
                            categoryBarRow(row)
                        }
                    }
                }
            }
        }
        .onAppear {
            withAnimation(.easeOut(duration: 0.8).delay(0.15)) {
                barProgress = 1
            }
        }
    }

    private func categoryBarRow(_ row: CategoryRow) -> some View {
        VStack(spacing: Spacing.xxs + 1) {
            HStack {
                SSIconImage(name: row.category.icon, size: 14)
                    .foregroundColor(row.category.color)

                Text(row.category.rawValue)
                    .font(Font.SS.bodySmall)
                    .foregroundColor(Color.SS.textPrimary)

                Spacer()

                Text("\(row.count)")
                    .font(Font.SS.labelMedium)
                    .foregroundColor(Color.SS.textPrimary)
                    .monospacedDigit()

                Text("\(Int(row.percentage * 100))%")
                    .font(Font.SS.caption)
                    .foregroundColor(Color.SS.textTertiary)
                    .monospacedDigit()
                    .frame(width: 32, alignment: .trailing)
            }

            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(Color.SS.surfaceTertiary)

                    Capsule()
                        .fill(row.category.color)
                        .frame(
                            width: geo.size.width
                                * CGFloat(row.count)
                                / CGFloat(maxCount)
                                * barProgress
                        )
                }
            }
            .frame(height: 6)
        }
    }

    private var emptyCategoryState: some View {
        VStack(spacing: Spacing.sm) {
            SSIconImage(name: "ss.cat.pain", size: 28)
                .foregroundColor(Color.SS.textDisabled)
            Text("Log symptoms to see categories")
                .font(Font.SS.bodySmall)
                .foregroundColor(Color.SS.textTertiary)
        }
        .frame(maxWidth: .infinity)
        .frame(height: 100)
    }
}


// MARK: - 3. Weekly Comparison Card

struct WeeklyComparisonCard: View {
    @ObservedObject var dataStore: DataStore

    @State private var barScale: CGFloat = 0

    private var calendar: Calendar { Calendar.current }

    private var thisWeekStart: Date {
        calendar.date(from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: Date())) ?? Date()
    }
    private var lastWeekStart: Date {
        calendar.date(byAdding: .day, value: -7, to: thisWeekStart) ?? Date()
    }

    private var thisWeekEntries: [SymptomEntry] {
        dataStore.entriesForDateRange(from: thisWeekStart, to: Date())
    }
    private var lastWeekEntries: [SymptomEntry] {
        dataStore.entriesForDateRange(from: lastWeekStart, to: thisWeekStart)
    }

    private struct ComparisonMetric: Identifiable {
        let id = UUID()
        let label: String
        let thisWeek: Double
        let lastWeek: Double
        let delta: Double // percentage change
    }

    private var metrics: [ComparisonMetric] {
        let twCount = Double(thisWeekEntries.count)
        let lwCount = Double(lastWeekEntries.count)

        let twAvgSev = thisWeekEntries.isEmpty
            ? 0
            : Double(thisWeekEntries.map(\.severity).reduce(0, +)) / twCount
        let lwAvgSev = lastWeekEntries.isEmpty
            ? 0
            : Double(lastWeekEntries.map(\.severity).reduce(0, +)) / lwCount

        let twUnique = Double(Set(thisWeekEntries.map(\.symptomName)).count)
        let lwUnique = Double(Set(lastWeekEntries.map(\.symptomName)).count)

        func delta(_ current: Double, _ previous: Double) -> Double {
            guard previous > 0 else { return current > 0 ? 100 : 0 }
            return ((current - previous) / previous) * 100
        }

        return [
            ComparisonMetric(label: "Entries", thisWeek: twCount, lastWeek: lwCount, delta: delta(twCount, lwCount)),
            ComparisonMetric(label: "Avg Severity", thisWeek: twAvgSev, lastWeek: lwAvgSev, delta: delta(twAvgSev, lwAvgSev)),
            ComparisonMetric(label: "Unique Symptoms", thisWeek: twUnique, lastWeek: lwUnique, delta: delta(twUnique, lwUnique)),
        ]
    }

    var body: some View {
        SSCard(padding: Spacing.lg) {
            VStack(alignment: .leading, spacing: Spacing.md) {
                // Header
                HStack {
                    Text("Week over Week")
                        .font(Font.SS.labelMedium)
                        .foregroundColor(Color.SS.textTertiary)
                        .tracking(0.5)
                    Spacer()
                    weekLegend
                }

                VStack(spacing: Spacing.lg) {
                    ForEach(metrics) { metric in
                        metricRow(metric)
                    }
                }
            }
        }
        .onAppear {
            withAnimation(.easeOut(duration: 0.9).delay(0.1)) {
                barScale = 1
            }
        }
    }

    // MARK: - Legend

    private var weekLegend: some View {
        HStack(spacing: Spacing.sm) {
            HStack(spacing: 4) {
                RoundedRectangle(cornerRadius: 2)
                    .fill(Color.SS.accent)
                    .frame(width: 10, height: 4)
                Text("This wk")
                    .font(Font.SS.caption)
                    .foregroundColor(Color.SS.textTertiary)
            }
            HStack(spacing: 4) {
                RoundedRectangle(cornerRadius: 2)
                    .fill(Color.SS.surfaceTertiary)
                    .frame(width: 10, height: 4)
                Text("Last wk")
                    .font(Font.SS.caption)
                    .foregroundColor(Color.SS.textTertiary)
            }
        }
    }

    // MARK: - Metric Row

    private func metricRow(_ metric: ComparisonMetric) -> some View {
        let maxVal = max(metric.thisWeek, metric.lastWeek, 1)
        // "Entries" increase = good (more tracking). Severity/symptoms increase = bad.
        let invertMeaning = metric.label == "Entries"

        return VStack(spacing: Spacing.xxs + 1) {
            HStack {
                Text(metric.label)
                    .font(Font.SS.bodySmall)
                    .foregroundColor(Color.SS.textPrimary)
                Spacer()
                deltaBadge(metric.delta, invertMeaning: invertMeaning)
            }

            // This week bar
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(Color.SS.surfaceTertiary.opacity(0.4))
                    Capsule()
                        .fill(Color.SS.accent)
                        .frame(width: max(4, geo.size.width * CGFloat(metric.thisWeek / maxVal) * barScale))
                }
            }
            .frame(height: 8)

            // Last week bar
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(Color.SS.surfaceTertiary.opacity(0.4))
                    Capsule()
                        .fill(Color.SS.surfaceTertiary)
                        .frame(width: max(4, geo.size.width * CGFloat(metric.lastWeek / maxVal) * barScale))
                }
            }
            .frame(height: 8)
        }
    }

    // MARK: - Delta Badge

    /// `invertMeaning`: when true, an increase is positive (e.g. more entries = good tracking)
    private func deltaBadge(_ delta: Double, invertMeaning: Bool = false) -> some View {
        let isUp = delta > 0
        let isNeutral = abs(delta) < 0.5
        let isPositive = invertMeaning ? isUp : !isUp  // For severity: down is good. For entries: up is good.
        let color = isNeutral ? Color.SS.textTertiary : (isPositive ? Color.SS.success : Color.SS.warning)
        let arrow = isNeutral ? "" : (isUp ? "\u{2191}" : "\u{2193}")
        let text = isNeutral ? "0%" : "\(arrow)\(abs(Int(delta)))%"

        return Text(text)
            .font(Font.SS.labelSmall)
            .foregroundColor(color)
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(
                Capsule().fill(color.opacity(0.10))
            )
    }
}


// MARK: - 4. Trigger Impact Card

struct TriggerImpactCard: View {
    let entries: [SymptomEntry]

    @State private var barProgress: CGFloat = 0

    private struct TriggerRow: Identifiable {
        let id = UUID()
        let name: String
        let count: Int
    }

    private var triggers: [TriggerRow] {
        // Scope to last 30 days so stale triggers don't dominate
        let cutoff = Date().addingTimeInterval(-30 * 86400)
        let recent = entries.filter { $0.timestamp >= cutoff }

        var freq: [String: Int] = [:]
        for entry in recent {
            for trigger in entry.triggers {
                freq[trigger, default: 0] += 1
            }
        }
        return freq
            .sorted { $0.value > $1.value }
            .prefix(8)
            .map { TriggerRow(name: $0.key, count: $0.value) }
    }

    private var maxCount: Int {
        triggers.map(\.count).max() ?? 1
    }

    var body: some View {
        SSCard(padding: Spacing.lg) {
            VStack(alignment: .leading, spacing: Spacing.md) {
                // Header
                HStack {
                    Text("Trigger Frequency")
                        .font(Font.SS.labelMedium)
                        .foregroundColor(Color.SS.textTertiary)
                        .tracking(0.5)
                    Spacer()
                    SSIconImage(name: "ss.sparkles", size: 14)
                        .foregroundColor(Color.SS.violet)
                }

                if triggers.isEmpty {
                    emptyTriggerState
                } else {
                    VStack(spacing: Spacing.sm) {
                        ForEach(triggers) { trigger in
                            triggerBarRow(trigger)
                        }
                    }
                }
            }
        }
        .onAppear {
            withAnimation(.easeOut(duration: 0.8).delay(0.2)) {
                barProgress = 1
            }
        }
    }

    private func triggerBarRow(_ trigger: TriggerRow) -> some View {
        VStack(spacing: Spacing.xxs) {
            HStack {
                Text(trigger.name)
                    .font(Font.SS.bodySmall)
                    .foregroundColor(Color.SS.textPrimary)
                    .lineLimit(1)
                Spacer()
                Text("\(trigger.count)")
                    .font(Font.SS.labelMedium)
                    .foregroundColor(Color.SS.textSecondary)
                    .monospacedDigit()
            }

            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(Color.SS.surfaceTertiary)

                    Capsule()
                        .fill(
                            LinearGradient(
                                colors: [Color.SS.accent, Color.SS.violet],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(
                            width: geo.size.width
                                * CGFloat(trigger.count)
                                / CGFloat(maxCount)
                                * barProgress
                        )
                }
            }
            .frame(height: 6)
        }
    }

    private var emptyTriggerState: some View {
        VStack(spacing: Spacing.sm) {
            SSIconImage(name: "ss.sparkles", size: 28)
                .foregroundColor(Color.SS.textDisabled)
            Text("Add triggers when logging symptoms")
                .font(Font.SS.bodySmall)
                .foregroundColor(Color.SS.textTertiary)
        }
        .frame(maxWidth: .infinity)
        .frame(height: 100)
    }
}


// MARK: - 5. Mood & Energy Trend Card

struct MoodEnergyTrendCard: View {
    let summaries: [DailySummary]

    @State private var lineProgress: CGFloat = 0
    @State private var selectedIndex: Int? = nil

    private var sortedSummaries: [DailySummary] {
        summaries
            .sorted { $0.date < $1.date }
            .suffix(14)
            .map { $0 } // convert ArraySlice -> Array
    }

    private var moodPoints: [Double] {
        sortedSummaries.map { Double($0.overallMood) }
    }

    private var energyPoints: [Double] {
        sortedSummaries.map { Double($0.overallEnergy) }
    }

    private var dayLabels: [String] {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEE"
        return sortedSummaries.map { formatter.string(from: $0.date) }
    }

    var body: some View {
        SSCard(padding: Spacing.lg) {
            VStack(alignment: .leading, spacing: Spacing.md) {
                // Header
                HStack {
                    Text("Mood & Energy")
                        .font(Font.SS.labelMedium)
                        .foregroundColor(Color.SS.textTertiary)
                        .tracking(0.5)
                    Spacer()
                    trendLegend
                }

                if moodPoints.count < 2 {
                    emptyTrendState
                } else {
                    // Selected day tooltip
                    if let idx = selectedIndex, idx < sortedSummaries.count {
                        selectedTooltip(idx)
                    }

                    // Chart area
                    GeometryReader { geo in
                        let chartSize = CGSize(width: geo.size.width, height: geo.size.height)
                        ZStack {
                            // Grid lines
                            gridLines(size: chartSize)

                            // Energy fill
                            SmoothedPath(
                                points: energyPoints,
                                minVal: 0.5,
                                range: 5.0,
                                size: chartSize,
                                closed: true
                            )
                            .fill(Color.SS.violet.opacity(0.06 * Double(lineProgress)))

                            // Energy line
                            SmoothedPath(
                                points: energyPoints,
                                minVal: 0.5,
                                range: 5.0,
                                size: chartSize,
                                closed: false
                            )
                            .trim(from: 0, to: lineProgress)
                            .stroke(
                                Color.SS.violet.opacity(0.7),
                                style: StrokeStyle(lineWidth: 2, lineCap: .round)
                            )

                            // Mood fill
                            SmoothedPath(
                                points: moodPoints,
                                minVal: 0.5,
                                range: 5.0,
                                size: chartSize,
                                closed: true
                            )
                            .fill(Color.SS.accent.opacity(0.08 * Double(lineProgress)))

                            // Mood line
                            SmoothedPath(
                                points: moodPoints,
                                minVal: 0.5,
                                range: 5.0,
                                size: chartSize,
                                closed: false
                            )
                            .trim(from: 0, to: lineProgress)
                            .stroke(
                                Color.SS.accent,
                                style: StrokeStyle(lineWidth: 2.5, lineCap: .round)
                            )

                            // Data dots
                            dataDots(chartSize: chartSize)
                        }
                        .contentShape(Rectangle())
                        .gesture(
                            DragGesture(minimumDistance: 0)
                                .onChanged { value in
                                    let idx = Int(round(value.location.x / chartSize.width * CGFloat(max(moodPoints.count - 1, 1))))
                                    selectedIndex = max(0, min(moodPoints.count - 1, idx))
                                }
                                .onEnded { _ in
                                    withAnimation(.easeOut(duration: 0.3)) {
                                        selectedIndex = nil
                                    }
                                }
                        )
                    }
                    .frame(height: 140)

                    // X-axis day labels
                    xAxisLabels
                }
            }
        }
        .onAppear {
            withAnimation(.easeOut(duration: 1.2).delay(0.25)) {
                lineProgress = 1
            }
        }
    }

    // MARK: - Subviews

    private var trendLegend: some View {
        HStack(spacing: Spacing.sm) {
            HStack(spacing: 4) {
                Circle().fill(Color.SS.accent).frame(width: 6, height: 6)
                Text("Mood")
                    .font(Font.SS.caption)
                    .foregroundColor(Color.SS.textTertiary)
            }
            HStack(spacing: 4) {
                Circle().fill(Color.SS.violet.opacity(0.7)).frame(width: 6, height: 6)
                Text("Energy")
                    .font(Font.SS.caption)
                    .foregroundColor(Color.SS.textTertiary)
            }
        }
    }

    private func selectedTooltip(_ idx: Int) -> some View {
        HStack(spacing: Spacing.md) {
            let day = dayLabels[idx]
            Text(day)
                .font(Font.SS.labelMedium)
                .foregroundColor(Color.SS.textPrimary)
            Spacer()
            HStack(spacing: 4) {
                Circle().fill(Color.SS.accent).frame(width: 5, height: 5)
                Text("Mood \(sortedSummaries[idx].overallMood)")
                    .font(Font.SS.caption)
                    .foregroundColor(Color.SS.textSecondary)
            }
            HStack(spacing: 4) {
                Circle().fill(Color.SS.violet.opacity(0.7)).frame(width: 5, height: 5)
                Text("Energy \(sortedSummaries[idx].overallEnergy)")
                    .font(Font.SS.caption)
                    .foregroundColor(Color.SS.textSecondary)
            }
        }
        .padding(.horizontal, Spacing.sm)
        .padding(.vertical, Spacing.xxs + 2)
        .background(
            RoundedRectangle(cornerRadius: Radius.xs)
                .fill(Color.SS.surfaceSecondary)
        )
        .transition(.opacity)
    }

    private func gridLines(size: CGSize) -> some View {
        Canvas { context, _ in
            let steps = 4
            for i in 0...steps {
                let y = size.height * CGFloat(i) / CGFloat(steps)
                var line = Path()
                line.move(to: CGPoint(x: 0, y: y))
                line.addLine(to: CGPoint(x: size.width, y: y))
                context.stroke(
                    line,
                    with: .color(Color.SS.separator.opacity(0.5)),
                    style: StrokeStyle(lineWidth: 0.5, dash: [4, 4])
                )
            }
        }
    }

    private func dataDots(chartSize: CGSize) -> some View {
        ForEach(Array(moodPoints.enumerated()), id: \.offset) { index, mood in
            let x = chartSize.width * CGFloat(index) / CGFloat(max(moodPoints.count - 1, 1))
            let yMood = chartSize.height - ((CGFloat(mood) - 0.5) / 5.0 * chartSize.height)
            let energy = energyPoints[index]
            let yEnergy = chartSize.height - ((CGFloat(energy) - 0.5) / 5.0 * chartSize.height)
            let isSelected = selectedIndex == index

            // Mood dot
            Circle()
                .fill(Color.SS.accent)
                .frame(width: isSelected ? 8 : 5, height: isSelected ? 8 : 5)
                .position(x: x, y: yMood)
                .opacity(Double(lineProgress))
                .animation(.easeOut(duration: 0.15), value: isSelected)

            // Energy dot
            Circle()
                .fill(Color.SS.violet.opacity(0.7))
                .frame(width: isSelected ? 8 : 5, height: isSelected ? 8 : 5)
                .position(x: x, y: yEnergy)
                .opacity(Double(lineProgress))
                .animation(.easeOut(duration: 0.15), value: isSelected)
        }
    }

    private var xAxisLabels: some View {
        HStack {
            if dayLabels.count <= 7 {
                ForEach(Array(dayLabels.enumerated()), id: \.offset) { _, label in
                    Text(label)
                        .font(Font.SS.caption)
                        .foregroundColor(Color.SS.textTertiary)
                        .frame(maxWidth: .infinity)
                }
            } else {
                // Show every other label to avoid crowding
                ForEach(Array(dayLabels.enumerated()), id: \.offset) { idx, label in
                    if idx % 2 == 0 || idx == dayLabels.count - 1 {
                        Text(label)
                            .font(Font.SS.caption)
                            .foregroundColor(Color.SS.textTertiary)
                            .frame(maxWidth: .infinity)
                    }
                }
            }
        }
    }

    private var emptyTrendState: some View {
        VStack(spacing: Spacing.sm) {
            SSIconImage(name: "ss.ecg", size: 28)
                .foregroundColor(Color.SS.textDisabled)
            Text("Need at least 2 daily check-ins")
                .font(Font.SS.bodySmall)
                .foregroundColor(Color.SS.textTertiary)
        }
        .frame(maxWidth: .infinity)
        .frame(height: 140)
    }
}


// MARK: - 6. Sleep vs Severity Card

struct SleepSeverityCard: View {
    let summaries: [DailySummary]
    let entries: [SymptomEntry]

    @State private var dotOpacity: Double = 0

    private struct DayPoint: Identifiable {
        let id = UUID()
        let sleepHours: Double
        let avgSeverity: Double
    }

    private var points: [DayPoint] {
        let calendar = Calendar.current
        // Scope to last 30 days for relevant correlations
        let cutoff = Date().addingTimeInterval(-30 * 86400)
        let recentSummaries = summaries.filter { $0.date >= cutoff }
        var result: [DayPoint] = []

        for summary in recentSummaries {
            guard let sleep = summary.sleepHours, sleep > 0 else { continue }
            let dayEntries = entries.filter { calendar.isDate($0.timestamp, inSameDayAs: summary.date) }
            guard !dayEntries.isEmpty else { continue }
            let avg = Double(dayEntries.map(\.severity).reduce(0, +)) / Double(dayEntries.count)
            result.append(DayPoint(sleepHours: sleep, avgSeverity: avg))
        }

        return result
    }

    // Axis ranges
    private var sleepRange: (min: Double, max: Double) {
        guard !points.isEmpty else { return (4, 10) }
        let vals = points.map(\.sleepHours)
        let lo = max(0, (vals.min() ?? 4) - 0.5)
        let hi = (vals.max() ?? 10) + 0.5
        return (lo, hi)
    }

    private var severityRange: (min: Double, max: Double) {
        guard !points.isEmpty else { return (0, 10) }
        let vals = points.map(\.avgSeverity)
        let lo = max(0, (vals.min() ?? 0) - 0.5)
        let hi = min(10, (vals.max() ?? 10) + 0.5)
        return (lo, hi)
    }

    var body: some View {
        SSCard(padding: Spacing.lg) {
            VStack(alignment: .leading, spacing: Spacing.md) {
                // Header
                HStack {
                    Text("Sleep vs Severity")
                        .font(Font.SS.labelMedium)
                        .foregroundColor(Color.SS.textTertiary)
                        .tracking(0.5)
                    Spacer()
                    SSChip(label: "\(points.count) days", color: Color.SS.info)
                }

                if points.count < 2 {
                    emptyScatterState
                } else {
                    // Pearson correlation summary
                    if let corr = StatisticalAnalysis.pearsonCorrelation(
                        x: points.map(\.sleepHours),
                        y: points.map(\.avgSeverity)
                    ) {
                        HStack(spacing: Spacing.xs) {
                            Text("Correlation:")
                                .font(Font.SS.caption)
                                .foregroundColor(Color.SS.textDisabled)
                            Text("\(corr.strength.rawValue)")
                                .font(Font.SS.labelSmall)
                                .foregroundColor(
                                    corr.strength == .negligible ? Color.SS.textTertiary :
                                    corr.r < 0 ? Color.SS.success : Color.SS.warning
                                )
                            Text("(r = \(String(format: "%.2f", corr.r)))")
                                .font(Font.SS.caption)
                                .foregroundColor(Color.SS.textDisabled)
                            if corr.isSignificant {
                                Text("p<0.05")
                                    .font(Font.SS.caption)
                                    .foregroundColor(Color.SS.accent)
                            }
                            Spacer()
                        }
                    }

                    ZStack {
                        // Chart area
                        GeometryReader { geo in
                            let w = geo.size.width
                            let h = geo.size.height
                            let sRange = sleepRange.max - sleepRange.min
                            let sevRange = severityRange.max - severityRange.min

                            // Background grid
                            Canvas { context, _ in
                                // Horizontal grid
                                for i in 0...4 {
                                    let y = h * CGFloat(i) / 4.0
                                    var line = Path()
                                    line.move(to: CGPoint(x: 0, y: y))
                                    line.addLine(to: CGPoint(x: w, y: y))
                                    context.stroke(
                                        line,
                                        with: .color(Color.SS.separator.opacity(0.4)),
                                        style: StrokeStyle(lineWidth: 0.5, dash: [3, 3])
                                    )
                                }
                                // Vertical grid
                                for i in 0...4 {
                                    let x = w * CGFloat(i) / 4.0
                                    var line = Path()
                                    line.move(to: CGPoint(x: x, y: 0))
                                    line.addLine(to: CGPoint(x: x, y: h))
                                    context.stroke(
                                        line,
                                        with: .color(Color.SS.separator.opacity(0.4)),
                                        style: StrokeStyle(lineWidth: 0.5, dash: [3, 3])
                                    )
                                }
                            }

                            // Scatter dots
                            ForEach(points) { point in
                                let x = (point.sleepHours - sleepRange.min) / sRange * Double(w)
                                // severity: higher = top, so invert y
                                let y = Double(h) - ((point.avgSeverity - severityRange.min) / sevRange * Double(h))

                                Circle()
                                    .fill(dotColor(for: point.avgSeverity))
                                    .frame(width: 10, height: 10)
                                    .overlay(
                                        Circle()
                                            .strokeBorder(Color.white, lineWidth: 1.5)
                                    )
                                    .shadow(color: dotColor(for: point.avgSeverity).opacity(0.3), radius: 4, x: 0, y: 2)
                                    .position(x: CGFloat(x), y: CGFloat(y))
                                    .opacity(dotOpacity)
                            }
                        }
                    }
                    .frame(height: 160)

                    // Axis labels
                    axisLabels
                }
            }
        }
        .onAppear {
            withAnimation(.easeOut(duration: 0.7).delay(0.3)) {
                dotOpacity = 1
            }
        }
    }

    // MARK: - Helpers

    private func dotColor(for severity: Double) -> Color {
        switch severity {
        case 0..<3: return Color.SS.severityNone
        case 3..<5: return Color.SS.severityMild
        case 5..<7: return Color.SS.severityModerate
        case 7..<9: return Color.SS.severitySevere
        default: return Color.SS.severityCritical
        }
    }

    private var axisLabels: some View {
        VStack(spacing: Spacing.xxs) {
            HStack {
                Text("\(String(format: "%.0f", sleepRange.min))h")
                    .font(Font.SS.caption)
                    .foregroundColor(Color.SS.textTertiary)
                Spacer()
                Text("Sleep Hours")
                    .font(Font.SS.caption)
                    .foregroundColor(Color.SS.textDisabled)
                Spacer()
                Text("\(String(format: "%.0f", sleepRange.max))h")
                    .font(Font.SS.caption)
                    .foregroundColor(Color.SS.textTertiary)
            }

            // Severity scale legend
            HStack(spacing: Spacing.xs) {
                ForEach(
                    [
                        ("Low", Color.SS.severityNone),
                        ("Med", Color.SS.severityModerate),
                        ("High", Color.SS.severityCritical),
                    ],
                    id: \.0
                ) { label, color in
                    HStack(spacing: 3) {
                        Circle().fill(color).frame(width: 5, height: 5)
                        Text(label)
                            .font(Font.SS.caption)
                            .foregroundColor(Color.SS.textTertiary)
                    }
                }
                Spacer()
            }
        }
    }

    private var emptyScatterState: some View {
        VStack(spacing: Spacing.sm) {
            SSIconImage(name: "ss.ecg", size: 28)
                .foregroundColor(Color.SS.textDisabled)
            Text("Log sleep and symptoms to see patterns")
                .font(Font.SS.bodySmall)
                .foregroundColor(Color.SS.textTertiary)
        }
        .frame(maxWidth: .infinity)
        .frame(height: 140)
    }
}


// MARK: - 7. Time-of-Day Pattern Card

struct TimeOfDayCard: View {
    let entries: [SymptomEntry]

    @State private var barProgress: CGFloat = 0

    private enum TimePeriod: String, CaseIterable, Identifiable {
        case morning = "Morning"
        case afternoon = "Afternoon"
        case evening = "Evening"
        case night = "Night"

        var id: String { rawValue }

        var hourRange: ClosedRange<Int> {
            switch self {
            case .morning: return 6...11
            case .afternoon: return 12...16
            case .evening: return 17...20
            case .night: return 21...23 // also 0-5, handled separately
            }
        }

        var icon: String {
            switch self {
            case .morning: return "sunrise.fill"
            case .afternoon: return "sun.max.fill"
            case .evening: return "sunset.fill"
            case .night: return "moon.stars.fill"
            }
        }

        var color: Color {
            switch self {
            case .morning: return Color(hex: "FBBF24")
            case .afternoon: return Color(hex: "F97316")
            case .evening: return Color(hex: "8B5CF6")
            case .night: return Color(hex: "3B82F6")
            }
        }

        var hours: String {
            switch self {
            case .morning: return "6am–12pm"
            case .afternoon: return "12–5pm"
            case .evening: return "5–9pm"
            case .night: return "9pm–6am"
            }
        }

        func contains(hour: Int) -> Bool {
            switch self {
            case .night:
                return hour >= 21 || hour < 6
            default:
                return hourRange.contains(hour)
            }
        }
    }

    private struct PeriodData: Identifiable {
        let id = UUID()
        let period: TimePeriod
        let count: Int
        let averageSeverity: Double
    }

    private var periodData: [PeriodData] {
        let calendar = Calendar.current
        // Scope to last 30 days for current patterns
        let cutoff = Date().addingTimeInterval(-30 * 86400)
        let recent = entries.filter { $0.timestamp >= cutoff }
        var result: [PeriodData] = []

        for period in TimePeriod.allCases {
            let matching = recent.filter { entry in
                let hour = calendar.component(.hour, from: entry.timestamp)
                return period.contains(hour: hour)
            }
            let count = matching.count
            let avg = matching.isEmpty
                ? 0.0
                : Double(matching.map(\.severity).reduce(0, +)) / Double(count)
            result.append(PeriodData(period: period, count: count, averageSeverity: avg))
        }

        return result
    }

    private var maxCount: Int {
        periodData.map(\.count).max() ?? 1
    }

    var body: some View {
        SSCard(padding: Spacing.lg) {
            VStack(alignment: .leading, spacing: Spacing.md) {
                // Header
                HStack {
                    Text("Time of Day Patterns")
                        .font(Font.SS.labelMedium)
                        .foregroundColor(Color.SS.textTertiary)
                        .tracking(0.5)
                    Spacer()
                    SSChip(label: "\(entries.count) entries", color: Color.SS.violet)
                }

                if entries.isEmpty {
                    emptyTimeState
                } else {
                    VStack(spacing: Spacing.sm) {
                        ForEach(periodData) { data in
                            periodRow(data)
                        }
                    }
                }
            }
        }
        .onAppear {
            withAnimation(.easeOut(duration: 0.9).delay(0.15)) {
                barProgress = 1
            }
        }
    }

    // MARK: - Period Row

    private func periodRow(_ data: PeriodData) -> some View {
        VStack(spacing: Spacing.xxs + 1) {
            HStack {
                Image(systemName: data.period.icon)
                    .font(.system(size: 13))
                    .foregroundColor(data.period.color)
                    .frame(width: 18)

                Text(data.period.rawValue)
                    .font(Font.SS.bodySmall)
                    .foregroundColor(Color.SS.textPrimary)

                Text(data.period.hours)
                    .font(Font.SS.caption)
                    .foregroundColor(Color.SS.textTertiary)

                Spacer()

                // Severity badge
                if data.count > 0 {
                    Text("avg \(String(format: "%.1f", data.averageSeverity))")
                        .font(Font.SS.caption)
                        .foregroundColor(severityColor(data.averageSeverity))
                        .padding(.horizontal, 5)
                        .padding(.vertical, 1)
                        .background(
                            Capsule().fill(severityColor(data.averageSeverity).opacity(0.10))
                        )
                }

                Text("\(data.count)")
                    .font(Font.SS.labelMedium)
                    .foregroundColor(Color.SS.textPrimary)
                    .monospacedDigit()
                    .frame(width: 28, alignment: .trailing)
            }

            // Count bar
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(Color.SS.surfaceTertiary)

                    Capsule()
                        .fill(
                            LinearGradient(
                                colors: [data.period.color, data.period.color.opacity(0.6)],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(
                            width: data.count > 0
                                ? max(4, geo.size.width
                                    * CGFloat(data.count)
                                    / CGFloat(maxCount)
                                    * barProgress)
                                : 0
                        )
                }
            }
            .frame(height: 6)
        }
    }

    // MARK: - Helpers

    private func severityColor(_ severity: Double) -> Color {
        switch severity {
        case 0..<3: return Color.SS.severityNone
        case 3..<5: return Color.SS.severityMild
        case 5..<7: return Color.SS.severityModerate
        case 7..<9: return Color.SS.severitySevere
        default: return Color.SS.severityCritical
        }
    }

    private var emptyTimeState: some View {
        VStack(spacing: Spacing.sm) {
            Image(systemName: "clock")
                .font(.system(size: 28))
                .foregroundColor(Color.SS.textDisabled)
            Text("No entries yet")
                .font(Font.SS.bodySmall)
                .foregroundColor(Color.SS.textTertiary)
        }
        .frame(maxWidth: .infinity)
        .frame(height: 100)
    }
}


// MARK: - 8. Symptom Forecast Card

struct SymptomForecastCard: View {
    @ObservedObject var dataStore: DataStore

    @State private var cardOpacity: Double = 0

    private struct ForecastItem: Identifiable {
        let id = UUID()
        let symptomName: String
        let likelihood: Likelihood
        let trend: Trend
        let score: Double
    }

    private enum Likelihood: String {
        case high = "High"
        case medium = "Medium"
        case low = "Low"

        var color: Color {
            switch self {
            case .high: return Color.SS.error
            case .medium: return Color.SS.warning
            case .low: return Color.SS.success
            }
        }
    }

    private enum Trend {
        case worsening, stable, improving

        var arrow: String {
            switch self {
            case .worsening: return "\u{2191}"
            case .stable: return "\u{2192}"
            case .improving: return "\u{2193}"
            }
        }

        var label: String {
            switch self {
            case .worsening: return "worsening"
            case .stable: return "stable"
            case .improving: return "improving"
            }
        }

        var color: Color {
            switch self {
            case .worsening: return Color.SS.warning
            case .stable: return Color.SS.textTertiary
            case .improving: return Color.SS.success
            }
        }
    }

    private var forecasts: [ForecastItem] {
        guard dataStore.entries.count >= 5 else { return [] }

        let calendar = Calendar.current
        let now = Date()
        let tomorrow = calendar.date(byAdding: .day, value: 1, to: now) ?? now

        // Use ML prediction engine for likelihood
        let predictions = SymptomPredictionEngine.predictLikelihood(
            entries: dataStore.entries,
            targetDate: tomorrow
        )

        var scored: [ForecastItem] = []

        for prediction in predictions.prefix(5) {
            guard prediction.probability > 0.1 else { continue }

            // Determine trend from time series analysis
            let symptomEntries = dataStore.entries.filter { $0.symptomName == prediction.symptomName }
            let severities = symptomEntries.sorted { $0.timestamp < $1.timestamp }.map { Double($0.severity) }
            let trendMetrics = TimeSeriesAnalyzer.trendStrength(severities)

            let trend: Trend
            switch trendMetrics.direction {
            case .worsening: trend = .worsening
            case .improving: trend = .improving
            case .stable: trend = .stable
            }

            let likelihood: Likelihood
            if prediction.probability >= 0.55 {
                likelihood = .high
            } else if prediction.probability >= 0.30 {
                likelihood = .medium
            } else {
                likelihood = .low
            }

            scored.append(ForecastItem(
                symptomName: prediction.symptomName,
                likelihood: likelihood,
                trend: trend,
                score: prediction.probability
            ))
        }

        return Array(scored.prefix(3))
    }

    private var tomorrowLabel: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE"
        let tomorrow = Calendar.current.date(byAdding: .day, value: 1, to: Date())!
        return formatter.string(from: tomorrow)
    }

    var body: some View {
        SSCard(padding: Spacing.lg) {
            VStack(alignment: .leading, spacing: Spacing.md) {
                // Header
                HStack {
                    Text("Tomorrow's Forecast")
                        .font(Font.SS.labelMedium)
                        .foregroundColor(Color.SS.textTertiary)
                        .tracking(0.5)
                    Spacer()
                    SSChip(label: tomorrowLabel, color: Color.SS.accent)
                }

                if forecasts.isEmpty {
                    emptyForecastState
                } else {
                    VStack(spacing: Spacing.sm) {
                        ForEach(forecasts) { item in
                            forecastRow(item)
                        }
                    }

                    // Disclaimer
                    Text("Based on your 30-day patterns — not a medical prediction")
                        .font(Font.SS.caption)
                        .foregroundColor(Color.SS.textDisabled)
                }
            }
        }
        .opacity(cardOpacity)
        .onAppear {
            withAnimation(.easeOut(duration: 0.6).delay(0.2)) {
                cardOpacity = 1
            }
        }
    }

    // MARK: - Forecast Row

    private func forecastRow(_ item: ForecastItem) -> some View {
        HStack(spacing: Spacing.sm) {
            // Symptom icon
            let found = Symptom.find(item.symptomName, customSymptoms: dataStore.customSymptoms)
            let symptomIcon = found?.icon ?? "ss.ecg"
            let symptomColor = found.map { Color(hex: $0.color) } ?? Color.SS.accent

            Circle()
                .fill(symptomColor.opacity(0.12))
                .frame(width: 34, height: 34)
                .overlay(
                    SSIconImage(name: symptomIcon, size: 15)
                        .foregroundColor(symptomColor)
                )

            VStack(alignment: .leading, spacing: 2) {
                Text(item.symptomName)
                    .font(Font.SS.bodySmall)
                    .foregroundColor(Color.SS.textPrimary)

                HStack(spacing: Spacing.xs) {
                    // Trend arrow
                    Text("\(item.trend.arrow) \(item.trend.label)")
                        .font(Font.SS.caption)
                        .foregroundColor(item.trend.color)
                }
            }

            Spacer()

            // Likelihood badge
            Text(item.likelihood.rawValue)
                .font(Font.SS.labelSmall)
                .foregroundColor(item.likelihood.color)
                .padding(.horizontal, 8)
                .padding(.vertical, 3)
                .background(
                    Capsule().fill(item.likelihood.color.opacity(0.10))
                )
        }
        .padding(.vertical, Spacing.xxs)
    }

    // MARK: - Empty State

    private var emptyForecastState: some View {
        VStack(spacing: Spacing.sm) {
            Image(systemName: "sparkles")
                .font(.system(size: 28))
                .foregroundColor(Color.SS.textDisabled)
            Text("Need more data to predict patterns")
                .font(Font.SS.bodySmall)
                .foregroundColor(Color.SS.textTertiary)
            Text("Log at least 5 entries over several days")
                .font(Font.SS.caption)
                .foregroundColor(Color.SS.textDisabled)
        }
        .frame(maxWidth: .infinity)
        .frame(height: 120)
    }
}
