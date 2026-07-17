import SwiftUI

// MARK: - 1. Severity Trend Line Card

struct SeverityTrendLineCard: View {
    @ObservedObject var dataStore: DataStore
    var days: Int = 21

    @State private var animateChart = false

    private var calendar: Calendar { Calendar.current }

    private struct DayPoint: Identifiable {
        let id = UUID()
        let date: Date
        let label: String
        let average: Double
    }

    private var dayPoints: [DayPoint] {
        let today = calendar.startOfDay(for: Date())
        let formatter = DateFormatter()
        formatter.dateFormat = "EEE"

        var points: [DayPoint] = []
        for offset in stride(from: -(days - 1), through: 0, by: 1) {
            guard let date = calendar.date(byAdding: .day, value: offset, to: today) else { continue }
            let dayEntries = dataStore.entries.filter { calendar.isDate($0.timestamp, inSameDayAs: date) }
            let avg: Double
            if dayEntries.isEmpty {
                avg = 0
            } else {
                avg = Double(dayEntries.map(\.severity).reduce(0, +)) / Double(dayEntries.count)
            }
            points.append(DayPoint(date: date, label: formatter.string(from: date), average: avg))
        }
        return points
    }

    private var hasData: Bool {
        dayPoints.contains { $0.average > 0 }
    }

    var body: some View {
        SSCard(padding: Spacing.lg) {
            VStack(alignment: .leading, spacing: Spacing.sm) {
                // Header
                HStack {
                    Text("SEVERITY TREND")
                        .font(Font.SS.labelMedium)
                        .foregroundColor(Color.SS.textTertiary)
                        .tracking(0.5)
                    Spacer()
                    SSChip(label: "\(days)d", color: Color.SS.accent)
                }

                if !hasData {
                    emptyState
                } else {
                    // Chart area with EMA smoothed trend overlay
                    GeometryReader { geo in
                        let points = dayPoints.map(\.average)
                        let emaPoints = TimeSeriesAnalyzer.ema(points, alpha: 0.3)
                        let allValues = points + emaPoints.filter { $0 > 0 }
                        let minVal = max(0, (allValues.min() ?? 0) - 1)
                        let maxVal = min(10, (allValues.max() ?? 10) + 1)
                        let range = max(maxVal - minVal, 1)

                        ZStack {
                            // Gradient fill under curve
                            SmoothedPath(
                                points: points,
                                minVal: minVal,
                                range: range,
                                size: geo.size,
                                closed: true
                            )
                            .fill(
                                LinearGradient(
                                    colors: [
                                        Color.SS.accent.opacity(0.18),
                                        Color.SS.violet.opacity(0.08),
                                        Color.SS.accent.opacity(0.02)
                                    ],
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                            )
                            .opacity(animateChart ? 1 : 0)

                            // Raw data stroke (lighter)
                            SmoothedPath(
                                points: points,
                                minVal: minVal,
                                range: range,
                                size: geo.size,
                                closed: false
                            )
                            .trim(from: 0, to: animateChart ? 1 : 0)
                            .stroke(
                                Color.SS.accent.opacity(0.25),
                                style: StrokeStyle(lineWidth: 1.5, lineCap: .round, lineJoin: .round)
                            )

                            // EMA smoothed trend line (prominent)
                            SmoothedPath(
                                points: emaPoints,
                                minVal: minVal,
                                range: range,
                                size: geo.size,
                                closed: false
                            )
                            .trim(from: 0, to: animateChart ? 1 : 0)
                            .stroke(
                                LinearGradient(
                                    colors: [Color.SS.accent, Color.SS.violet],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                ),
                                style: StrokeStyle(lineWidth: 2.5, lineCap: .round, lineJoin: .round)
                            )

                            // Data point dots
                            ForEach(Array(points.enumerated()), id: \.offset) { index, value in
                                if value > 0 {
                                    let x = geo.size.width * CGFloat(index) / CGFloat(max(points.count - 1, 1))
                                    let y = geo.size.height - ((CGFloat(value) - CGFloat(minVal)) / CGFloat(range) * geo.size.height)

                                    ZStack {
                                        Circle()
                                            .fill(Color.SS.surfacePrimary)
                                            .frame(width: 8, height: 8)
                                        Circle()
                                            .fill(severityDotColor(value))
                                            .frame(width: 5, height: 5)
                                    }
                                    .position(x: x, y: y)
                                    .opacity(animateChart ? 1 : 0)
                                }
                            }
                        }
                    }
                    .frame(height: 140)

                    // Trend summary using TimeSeriesAnalyzer
                    let trendMetrics = TimeSeriesAnalyzer.trendStrength(dayPoints.map(\.average))
                    HStack(spacing: Spacing.xs) {
                        Text("Trend:")
                            .font(Font.SS.caption)
                            .foregroundColor(Color.SS.textDisabled)
                        Text(trendMetrics.direction.rawValue)
                            .font(Font.SS.labelSmall)
                            .foregroundColor(
                                trendMetrics.direction == .improving ? Color.SS.success :
                                trendMetrics.direction == .worsening ? Color.SS.warning :
                                Color.SS.textTertiary
                            )
                        if abs(trendMetrics.changePerWeek) >= 0.1 {
                            Text("(\(String(format: "%+.1f", trendMetrics.changePerWeek))/wk)")
                                .font(Font.SS.caption)
                                .foregroundColor(Color.SS.textDisabled)
                        }
                        Spacer()
                    }

                    // X-axis day labels (show every few days to avoid crowding)
                    HStack {
                        let step = max(1, dayPoints.count / 7)
                        ForEach(Array(stride(from: 0, to: dayPoints.count, by: step)), id: \.self) { i in
                            if i < dayPoints.count {
                                Text(dayPoints[i].label)
                                    .font(Font.SS.caption)
                                    .foregroundColor(Color.SS.textDisabled)
                                if i + step < dayPoints.count {
                                    Spacer()
                                }
                            }
                        }
                    }
                }
            }
        }
        .onAppear {
            withAnimation(.easeOut(duration: 1.0).delay(0.2)) {
                animateChart = true
            }
        }
    }

    private func severityDotColor(_ value: Double) -> Color {
        switch value {
        case 0..<3: return Color.SS.severityNone
        case 3..<5: return Color.SS.severityMild
        case 5..<7: return Color.SS.severityModerate
        case 7..<9: return Color.SS.severitySevere
        default: return Color.SS.severityCritical
        }
    }

    private var emptyState: some View {
        VStack(spacing: Spacing.sm) {
            SSIconImage(name: "ss.ecg", size: 28)
                .foregroundColor(Color.SS.textDisabled)
            Text("No severity data yet")
                .font(Font.SS.bodySmall)
                .foregroundColor(Color.SS.textTertiary)
        }
        .frame(maxWidth: .infinity)
        .frame(height: 140)
    }
}


// MARK: - 2. Symptom Pie Card

struct SymptomPieCard: View {
    let entries: [SymptomEntry]
    var customSymptoms: [Symptom] = []

    @State private var animationProgress: CGFloat = 0

    private struct PieSlice: Identifiable {
        let id = UUID()
        let name: String
        let count: Int
        let color: Color
        let percentage: Double
    }

    private var slices: [PieSlice] {
        guard !entries.isEmpty else { return [] }

        var freq: [String: Int] = [:]
        for entry in entries {
            freq[entry.symptomName, default: 0] += 1
        }

        let sorted = freq.sorted { $0.value > $1.value }
        let total = Double(entries.count)
        var result: [PieSlice] = []

        let topItems = sorted.prefix(6)
        for item in topItems {
            let symptomColor = Symptom.find(item.key, customSymptoms: customSymptoms)
                .map { Color(hex: $0.color) } ?? Color.SS.textTertiary
            result.append(PieSlice(
                name: item.key,
                count: item.value,
                color: symptomColor,
                percentage: Double(item.value) / total * 100
            ))
        }

        let otherCount = sorted.dropFirst(6).reduce(0) { $0 + $1.value }
        if otherCount > 0 {
            result.append(PieSlice(
                name: "Other",
                count: otherCount,
                color: Color.SS.textDisabled,
                percentage: Double(otherCount) / total * 100
            ))
        }

        return result
    }

    var body: some View {
        SSCard(padding: Spacing.lg) {
            VStack(spacing: Spacing.md) {
                // Header
                HStack {
                    Text("SYMPTOM DISTRIBUTION")
                        .font(Font.SS.labelMedium)
                        .foregroundColor(Color.SS.textTertiary)
                        .tracking(0.5)
                    Spacer()
                    SSChip(label: "\(entries.count) logged", color: Color.SS.violet)
                }

                if slices.isEmpty {
                    emptyState
                } else {
                    // Pie chart
                    ZStack {
                        pieSegments
                    }
                    .frame(height: 180)
                    .padding(.vertical, Spacing.xs)

                    // Legend
                    legendList
                }
            }
        }
        .onAppear {
            withAnimation(.easeOut(duration: 1.0).delay(0.15)) {
                animationProgress = 1
            }
        }
    }

    // MARK: - Pie Segments

    private var pieSegments: some View {
        GeometryReader { geo in
            let size = min(geo.size.width, geo.size.height)
            let center = CGPoint(x: geo.size.width / 2, y: geo.size.height / 2)
            let radius = size / 2 - 4

            Canvas { context, canvasSize in
                let total = CGFloat(slices.map(\.count).reduce(0, +))
                guard total > 0 else { return }

                let gap: CGFloat = 0.03
                var currentAngle: CGFloat = -.pi / 2

                for slice in slices {
                    let fraction = CGFloat(slice.count) / total
                    let sweep = (2 * .pi - gap * CGFloat(slices.count)) * fraction * animationProgress

                    var segmentPath = Path()
                    segmentPath.move(to: center)
                    segmentPath.addArc(
                        center: center,
                        radius: radius,
                        startAngle: .radians(Double(currentAngle)),
                        endAngle: .radians(Double(currentAngle + sweep)),
                        clockwise: false
                    )
                    segmentPath.closeSubpath()

                    context.fill(segmentPath, with: .color(slice.color))

                    currentAngle += sweep + gap
                }
            }
        }
    }

    // MARK: - Legend

    private var legendList: some View {
        LazyVGrid(columns: [
            GridItem(.flexible()),
            GridItem(.flexible()),
        ], spacing: Spacing.xs) {
            ForEach(slices) { slice in
                HStack(spacing: Spacing.xs) {
                    Circle()
                        .fill(slice.color)
                        .frame(width: 8, height: 8)
                    Text(slice.name)
                        .font(Font.SS.caption)
                        .foregroundColor(Color.SS.textSecondary)
                        .lineLimit(1)
                    Spacer()
                    Text("\(Int(slice.percentage))%")
                        .font(Font.SS.labelSmall)
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
            Text("No entries to chart")
                .font(Font.SS.bodySmall)
                .foregroundColor(Color.SS.textTertiary)
        }
        .frame(maxWidth: .infinity)
        .frame(height: 160)
    }
}


// MARK: - 3. Daily Entry Bar Card

struct DailyEntryBarCard: View {
    @ObservedObject var dataStore: DataStore

    @State private var barGrowth: CGFloat = 0

    private var calendar: Calendar { Calendar.current }

    private struct DayBar: Identifiable {
        let id = UUID()
        let date: Date
        let label: String
        let count: Int
        let isToday: Bool
    }

    private var bars: [DayBar] {
        let today = calendar.startOfDay(for: Date())
        let formatter = DateFormatter()
        formatter.dateFormat = "EEE"

        var result: [DayBar] = []
        for offset in -13...0 {
            guard let date = calendar.date(byAdding: .day, value: offset, to: today) else { continue }
            let count = dataStore.entries.filter { calendar.isDate($0.timestamp, inSameDayAs: date) }.count
            result.append(DayBar(
                date: date,
                label: formatter.string(from: date),
                count: count,
                isToday: offset == 0
            ))
        }
        return result
    }

    private var maxCount: Int {
        max(bars.map(\.count).max() ?? 1, 1)
    }

    private var hasData: Bool {
        bars.contains { $0.count > 0 }
    }

    var body: some View {
        SSCard(padding: Spacing.lg) {
            VStack(alignment: .leading, spacing: Spacing.sm) {
                // Header
                HStack {
                    Text("DAILY ENTRIES")
                        .font(Font.SS.labelMedium)
                        .foregroundColor(Color.SS.textTertiary)
                        .tracking(0.5)
                    Spacer()
                    SSChip(label: "14 days", color: Color.SS.accent)
                }

                if !hasData {
                    emptyState
                } else {
                    // Bars
                    GeometryReader { geo in
                        let barWidth = max((geo.size.width - CGFloat(bars.count - 1) * Spacing.xxs) / CGFloat(bars.count), 4)

                        HStack(alignment: .bottom, spacing: Spacing.xxs) {
                            ForEach(bars) { bar in
                                let fraction = CGFloat(bar.count) / CGFloat(maxCount)
                                let height = max(fraction * geo.size.height * barGrowth, bar.count > 0 ? 4 : 2)

                                VStack(spacing: 0) {
                                    Spacer(minLength: 0)

                                    RoundedRectangle(cornerRadius: Radius.xs)
                                        .fill(
                                            bar.isToday
                                                ? LinearGradient(
                                                    colors: [Color.SS.accent, Color.SS.accentLight],
                                                    startPoint: .bottom,
                                                    endPoint: .top
                                                  )
                                                : LinearGradient(
                                                    colors: [Color.SS.accent.opacity(0.6), Color.SS.violet.opacity(0.4)],
                                                    startPoint: .bottom,
                                                    endPoint: .top
                                                  )
                                        )
                                        .frame(width: barWidth, height: height)
                                        .ssShadow(bar.isToday ? .glow : .subtle)
                                }
                            }
                        }
                    }
                    .frame(height: 130)

                    // X-axis labels — show every other day to avoid crowding
                    HStack {
                        ForEach(Array(bars.enumerated()), id: \.offset) { index, bar in
                            if index % 2 == 1 || bar.isToday {
                                Text(bar.isToday ? "Today" : bar.label)
                                    .font(Font.SS.caption)
                                    .foregroundColor(bar.isToday ? Color.SS.accent : Color.SS.textDisabled)
                                    .frame(maxWidth: .infinity)
                            } else {
                                Spacer()
                                    .frame(maxWidth: .infinity)
                            }
                        }
                    }
                }
            }
        }
        .onAppear {
            withAnimation(.easeOut(duration: 0.8).delay(0.15)) {
                barGrowth = 1
            }
        }
    }

    private var emptyState: some View {
        VStack(spacing: Spacing.sm) {
            SSIconImage(name: "ss.ecg", size: 28)
                .foregroundColor(Color.SS.textDisabled)
            Text("Start logging to see daily activity")
                .font(Font.SS.bodySmall)
                .foregroundColor(Color.SS.textTertiary)
        }
        .frame(maxWidth: .infinity)
        .frame(height: 130)
    }
}


// MARK: - 4. Mood & Energy Weekly Bar Card

struct MoodWeeklyBarCard: View {
    let summaries: [DailySummary]

    @State private var barGrowth: CGFloat = 0

    private var calendar: Calendar { Calendar.current }

    private struct DayPair: Identifiable {
        let id = UUID()
        let label: String
        let mood: Int
        let energy: Int
    }

    private var dayPairs: [DayPair] {
        let today = calendar.startOfDay(for: Date())
        let formatter = DateFormatter()
        formatter.dateFormat = "EEE"

        var result: [DayPair] = []
        for offset in -6...0 {
            guard let date = calendar.date(byAdding: .day, value: offset, to: today) else { continue }
            let summary = summaries.first { calendar.isDate($0.date, inSameDayAs: date) }
            result.append(DayPair(
                label: formatter.string(from: date),
                mood: summary?.overallMood ?? 0,
                energy: summary?.overallEnergy ?? 0
            ))
        }
        return result
    }

    private var hasData: Bool {
        dayPairs.contains { $0.mood > 0 || $0.energy > 0 }
    }

    var body: some View {
        SSCard(padding: Spacing.lg) {
            VStack(alignment: .leading, spacing: Spacing.sm) {
                // Header
                HStack {
                    Text("MOOD & ENERGY")
                        .font(Font.SS.labelMedium)
                        .foregroundColor(Color.SS.textTertiary)
                        .tracking(0.5)
                    Spacer()
                    SSChip(label: "7 days", color: Color.SS.violet)
                }

                // Legend
                HStack(spacing: Spacing.md) {
                    HStack(spacing: Spacing.xxs) {
                        RoundedRectangle(cornerRadius: 2)
                            .fill(Color.SS.accent)
                            .frame(width: 10, height: 10)
                        Text("Mood")
                            .font(Font.SS.caption)
                            .foregroundColor(Color.SS.textSecondary)
                    }
                    HStack(spacing: Spacing.xxs) {
                        RoundedRectangle(cornerRadius: 2)
                            .fill(Color.SS.violet)
                            .frame(width: 10, height: 10)
                        Text("Energy")
                            .font(Font.SS.caption)
                            .foregroundColor(Color.SS.textSecondary)
                    }
                    Spacer()
                }

                if !hasData {
                    emptyState
                } else {
                    // Grouped bars
                    GeometryReader { geo in
                        let groupWidth = geo.size.width / CGFloat(dayPairs.count)
                        let barWidth = max((groupWidth - Spacing.xs) / 2, 6)
                        let maxScale: CGFloat = 5

                        HStack(alignment: .bottom, spacing: 0) {
                            ForEach(dayPairs) { pair in
                                HStack(alignment: .bottom, spacing: 2) {
                                    Spacer(minLength: 0)

                                    // Mood bar
                                    RoundedRectangle(cornerRadius: Radius.xs)
                                        .fill(Color.SS.accent)
                                        .frame(
                                            width: barWidth,
                                            height: max(CGFloat(pair.mood) / maxScale * geo.size.height * barGrowth, pair.mood > 0 ? 4 : 2)
                                        )

                                    // Energy bar
                                    RoundedRectangle(cornerRadius: Radius.xs)
                                        .fill(Color.SS.violet)
                                        .frame(
                                            width: barWidth,
                                            height: max(CGFloat(pair.energy) / maxScale * geo.size.height * barGrowth, pair.energy > 0 ? 4 : 2)
                                        )

                                    Spacer(minLength: 0)
                                }
                                .frame(width: groupWidth)
                            }
                        }
                    }
                    .frame(height: 120)

                    // Day labels
                    HStack {
                        ForEach(dayPairs) { pair in
                            Text(pair.label)
                                .font(Font.SS.caption)
                                .foregroundColor(Color.SS.textDisabled)
                                .frame(maxWidth: .infinity)
                        }
                    }
                }
            }
        }
        .onAppear {
            withAnimation(.easeOut(duration: 0.8).delay(0.15)) {
                barGrowth = 1
            }
        }
    }

    private var emptyState: some View {
        VStack(spacing: Spacing.sm) {
            SSIconImage(name: "ss.mood.3", size: 28)
                .foregroundColor(Color.SS.textDisabled)
            Text("Complete daily check-ins to see trends")
                .font(Font.SS.bodySmall)
                .foregroundColor(Color.SS.textTertiary)
        }
        .frame(maxWidth: .infinity)
        .frame(height: 120)
    }
}


// MARK: - 5. Severity Heatmap Card

struct SeverityHeatmapCard: View {
    @ObservedObject var dataStore: DataStore

    @State private var cellsVisible = false

    private let weeksToShow = 8
    private let daysPerWeek = 7
    private var calendar: Calendar { Calendar.current }

    private struct CellData: Identifiable {
        let id = UUID()
        let date: Date
        let average: Double
        let hasEntries: Bool
        let row: Int
        let col: Int
    }

    private var cells: [CellData] {
        let today = calendar.startOfDay(for: Date())
        let todayWeekday = calendar.component(.weekday, from: today) // 1=Sun, 7=Sat
        // Align grid to start on Monday: row 0=Mon, 1=Tue, ..., 6=Sun
        // Find the Monday of the current week, then go back (weeksToShow - 1) weeks
        let daysFromMonday = (todayWeekday + 5) % 7 // Mon=0, Tue=1 ... Sun=6
        let thisMonday = calendar.date(byAdding: .day, value: -daysFromMonday, to: today) ?? today
        let startDate = calendar.date(byAdding: .day, value: -(weeksToShow - 1) * 7, to: thisMonday) ?? thisMonday
        let totalDays = weeksToShow * daysPerWeek

        var result: [CellData] = []
        for i in 0..<totalDays {
            guard let date = calendar.date(byAdding: .day, value: i, to: startDate) else { continue }
            let isFuture = date > today
            let dayEntries = isFuture ? [] : dataStore.entries.filter { calendar.isDate($0.timestamp, inSameDayAs: date) }
            let avg: Double
            if dayEntries.isEmpty {
                avg = 0
            } else {
                avg = Double(dayEntries.map(\.severity).reduce(0, +)) / Double(dayEntries.count)
            }
            let row = i % daysPerWeek
            let col = i / daysPerWeek
            result.append(CellData(date: date, average: avg, hasEntries: !dayEntries.isEmpty && !isFuture, row: row, col: col))
        }
        return result
    }

    private var monthLabels: [(String, Int)] {
        var labels: [(String, Int)] = []
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM"
        var lastMonth = -1

        for cell in cells where cell.row == 0 {
            let month = calendar.component(.month, from: cell.date)
            if month != lastMonth {
                labels.append((formatter.string(from: cell.date), cell.col))
                lastMonth = month
            }
        }
        return labels
    }

    var body: some View {
        SSCard(padding: Spacing.lg) {
            VStack(alignment: .leading, spacing: Spacing.sm) {
                // Header
                HStack {
                    Text("SEVERITY HEATMAP")
                        .font(Font.SS.labelMedium)
                        .foregroundColor(Color.SS.textTertiary)
                        .tracking(0.5)
                    Spacer()
                    SSChip(label: "\(weeksToShow) weeks", color: Color.SS.accent)
                }

                // Month labels across the top
                GeometryReader { geo in
                    let colWidth = (geo.size.width - 20) / CGFloat(weeksToShow)
                    ForEach(Array(monthLabels.enumerated()), id: \.offset) { _, item in
                        Text(item.0)
                            .font(Font.SS.caption)
                            .foregroundColor(Color.SS.textDisabled)
                            .position(
                                x: 20 + colWidth * CGFloat(item.1) + colWidth / 2,
                                y: 6
                            )
                    }
                }
                .frame(height: 14)

                // Grid: day labels on left + heatmap cells
                HStack(alignment: .top, spacing: Spacing.xxs) {
                    // Day of week labels
                    VStack(spacing: 0) {
                        ForEach(0..<daysPerWeek, id: \.self) { row in
                            let label: String = {
                                switch row {
                                case 0: return "M"
                                case 2: return "W"
                                case 4: return "F"
                                default: return ""
                                }
                            }()
                            Text(label)
                                .font(Font.SS.caption)
                                .foregroundColor(Color.SS.textDisabled)
                                .frame(width: 16, height: 16)
                                .padding(.vertical, 1)
                        }
                    }

                    // Heatmap grid
                    let gridCells = cells
                    LazyHGrid(rows: Array(repeating: GridItem(.fixed(16), spacing: 2), count: daysPerWeek), spacing: 2) {
                        ForEach(gridCells) { cell in
                            RoundedRectangle(cornerRadius: 3)
                                .fill(heatColor(for: cell))
                                .frame(width: 16, height: 16)
                                .opacity(cellsVisible ? 1 : 0)
                                .animation(
                                    .easeOut(duration: 0.4).delay(Double(cell.col) * 0.04 + Double(cell.row) * 0.02),
                                    value: cellsVisible
                                )
                        }
                    }
                }

                // Color scale legend
                HStack(spacing: Spacing.xs) {
                    Text("Less")
                        .font(Font.SS.caption)
                        .foregroundColor(Color.SS.textDisabled)

                    ForEach([0.0, 2.5, 5.0, 7.5, 10.0], id: \.self) { val in
                        RoundedRectangle(cornerRadius: 2)
                            .fill(severityScaleColor(val))
                            .frame(width: 12, height: 12)
                    }

                    Text("More")
                        .font(Font.SS.caption)
                        .foregroundColor(Color.SS.textDisabled)

                    Spacer()
                }
            }
        }
        .onAppear {
            withAnimation(.easeOut(duration: 0.6).delay(0.1)) {
                cellsVisible = true
            }
        }
    }

    private func heatColor(for cell: CellData) -> Color {
        guard cell.hasEntries else { return Color.SS.surfaceTertiary }
        return severityScaleColor(cell.average)
    }

    private func severityScaleColor(_ value: Double) -> Color {
        switch value {
        case 0: return Color.SS.surfaceTertiary
        case 0..<3: return Color.SS.severityNone
        case 3..<5: return Color.SS.severityMild
        case 5..<7: return Color.SS.severityModerate
        case 7..<9: return Color.SS.severitySevere
        default: return Color.SS.severityCritical
        }
    }
}


// MARK: - 6. Symptom Radar Card

struct SymptomRadarCard: View {
    let entries: [SymptomEntry]
    var customSymptoms: [Symptom] = []

    @State private var animateRadar: CGFloat = 0

    private let categories = SymptomCategory.allCases

    /// Dynamic max scale based on the user's actual data — prevents tiny polygons
    /// when all severities are low. Minimum of 5 so the chart remains readable.
    private var maxSeverity: Double {
        let maxAvg = categoryValues.map(\.averageSeverity).max() ?? 5
        return max(5, ceil(maxAvg + 1))
    }

    private var ringLevels: [Double] {
        let step = maxSeverity / 5
        return (1...5).map { Double($0) * step }
    }

    private struct CategoryValue: Identifiable {
        let id = UUID()
        let category: SymptomCategory
        let averageSeverity: Double
    }

    /// Scoped to last 30 days. Skips entries whose symptom name doesn't match
    /// any known symptom rather than silently bucketing them as "Pain".
    private var categoryValues: [CategoryValue] {
        let cutoff = Date().addingTimeInterval(-30 * 86400)
        let recent = entries.filter { $0.timestamp >= cutoff }

        return categories.map { category in
            let matching = recent.filter { entry in
                guard let symptom = Symptom.find(entry.symptomName, customSymptoms: customSymptoms) else {
                    return false
                }
                return symptom.category == category
            }
            let avg: Double
            if matching.isEmpty {
                avg = 0
            } else {
                avg = Double(matching.map(\.severity).reduce(0, +)) / Double(matching.count)
            }
            return CategoryValue(category: category, averageSeverity: avg)
        }
    }

    private var hasData: Bool {
        categoryValues.contains { $0.averageSeverity > 0 }
    }

    var body: some View {
        SSCard(padding: Spacing.lg) {
            VStack(spacing: Spacing.md) {
                // Header
                HStack {
                    Text("CATEGORY RADAR")
                        .font(Font.SS.labelMedium)
                        .foregroundColor(Color.SS.textTertiary)
                        .tracking(0.5)
                    Spacer()
                    SSChip(label: "\(categories.count) categories", color: Color.SS.violet)
                }

                if !hasData {
                    emptyState
                } else {
                    // Radar chart
                    GeometryReader { geo in
                        let size = min(geo.size.width, geo.size.height)
                        let center = CGPoint(x: geo.size.width / 2, y: geo.size.height / 2)
                        let outerRadius = size / 2 - 30

                        ZStack {
                            // Grid rings
                            ForEach(ringLevels, id: \.self) { level in
                                radarRingPath(
                                    center: center,
                                    radius: outerRadius * CGFloat(level / maxSeverity),
                                    sides: categories.count
                                )
                                .stroke(Color.SS.separator, lineWidth: 0.5)
                            }

                            // Axis lines from center
                            ForEach(0..<categories.count, id: \.self) { i in
                                let angle = angleForIndex(i, total: categories.count)
                                let endX = center.x + cos(angle) * outerRadius
                                let endY = center.y + sin(angle) * outerRadius

                                Path { path in
                                    path.move(to: center)
                                    path.addLine(to: CGPoint(x: endX, y: endY))
                                }
                                .stroke(Color.SS.separator, lineWidth: 0.5)
                            }

                            // Filled data polygon
                            radarDataPath(center: center, radius: outerRadius)
                                .fill(Color.SS.accent.opacity(0.15))
                                .scaleEffect(animateRadar)

                            radarDataPath(center: center, radius: outerRadius)
                                .stroke(
                                    LinearGradient(
                                        colors: [Color.SS.accent, Color.SS.violet],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    ),
                                    style: StrokeStyle(lineWidth: 2, lineCap: .round, lineJoin: .round)
                                )
                                .scaleEffect(animateRadar)

                            // Data point dots
                            ForEach(Array(categoryValues.enumerated()), id: \.offset) { i, cv in
                                if cv.averageSeverity > 0 {
                                    let angle = angleForIndex(i, total: categories.count)
                                    let r = outerRadius * CGFloat(cv.averageSeverity / maxSeverity) * animateRadar
                                    let x = center.x + cos(angle) * r
                                    let y = center.y + sin(angle) * r

                                    ZStack {
                                        Circle()
                                            .fill(Color.SS.surfacePrimary)
                                            .frame(width: 8, height: 8)
                                        Circle()
                                            .fill(cv.category.color)
                                            .frame(width: 5, height: 5)
                                    }
                                    .position(x: x, y: y)
                                    .opacity(Double(animateRadar))
                                }
                            }

                            // Category labels
                            ForEach(Array(categories.enumerated()), id: \.offset) { i, cat in
                                let angle = angleForIndex(i, total: categories.count)
                                let labelRadius = outerRadius + 18
                                let x = center.x + cos(angle) * labelRadius
                                let y = center.y + sin(angle) * labelRadius

                                Text(shortCategoryLabel(cat))
                                    .font(Font.SS.caption)
                                    .foregroundColor(Color.SS.textSecondary)
                                    .position(x: x, y: y)
                            }
                        }
                    }
                    .frame(height: 240)

                    // Ring scale note
                    HStack(spacing: Spacing.xs) {
                        let low = ringLevels.first ?? 1.0
                        let mid = ringLevels[ringLevels.count / 2]
                        let high = ringLevels.last ?? 10.0
                        ForEach([low, mid, high], id: \.self) { level in
                            HStack(spacing: 2) {
                                Circle()
                                    .stroke(Color.SS.separator, lineWidth: 1)
                                    .frame(width: 6, height: 6)
                                Text(String(format: "%.0f", level))
                                    .font(Font.SS.caption)
                                    .foregroundColor(Color.SS.textDisabled)
                                    .monospacedDigit()
                            }
                        }
                        Spacer()
                    }
                }
            }
        }
        .onAppear {
            withAnimation(.easeOut(duration: 0.9).delay(0.2)) {
                animateRadar = 1
            }
        }
    }

    // MARK: - Radar Helpers

    private func angleForIndex(_ index: Int, total: Int) -> CGFloat {
        let sliceAngle = 2 * CGFloat.pi / CGFloat(total)
        return sliceAngle * CGFloat(index) - .pi / 2
    }

    private func radarRingPath(center: CGPoint, radius: CGFloat, sides: Int) -> Path {
        Path { path in
            for i in 0...sides {
                let angle = angleForIndex(i % sides, total: sides)
                let point = CGPoint(
                    x: center.x + cos(angle) * radius,
                    y: center.y + sin(angle) * radius
                )
                if i == 0 {
                    path.move(to: point)
                } else {
                    path.addLine(to: point)
                }
            }
            path.closeSubpath()
        }
    }

    private func radarDataPath(center: CGPoint, radius: CGFloat) -> Path {
        Path { path in
            let total = categoryValues.count
            for (i, cv) in categoryValues.enumerated() {
                let angle = angleForIndex(i, total: total)
                let r = radius * CGFloat(cv.averageSeverity / maxSeverity)
                let point = CGPoint(
                    x: center.x + cos(angle) * r,
                    y: center.y + sin(angle) * r
                )
                if i == 0 {
                    path.move(to: point)
                } else {
                    path.addLine(to: point)
                }
            }
            path.closeSubpath()
        }
    }

    private func shortCategoryLabel(_ cat: SymptomCategory) -> String {
        switch cat {
        case .pain: return "Pain"
        case .digestive: return "Digest"
        case .neurological: return "Neuro"
        case .mental: return "Mental"
        case .respiratory: return "Resp"
        case .skin: return "Skin"
        case .energy: return "Energy"
        }
    }

    private var emptyState: some View {
        VStack(spacing: Spacing.sm) {
            SSIconImage(name: "ss.cat.pain", size: 28)
                .foregroundColor(Color.SS.textDisabled)
            Text("Log symptoms to see your radar profile")
                .font(Font.SS.bodySmall)
                .foregroundColor(Color.SS.textTertiary)
        }
        .frame(maxWidth: .infinity)
        .frame(height: 200)
    }
}
