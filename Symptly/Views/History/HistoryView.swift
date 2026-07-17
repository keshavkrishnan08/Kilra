import SwiftUI

struct HistoryView: View {
    @EnvironmentObject var dataStore: DataStore
    @State private var selectedTimeRange: TimeRange = .week
    @State private var showContent = false

    enum TimeRange: String, CaseIterable {
        case week = "7D"
        case month = "30D"
        case quarter = "90D"
        case year = "1Y"

        var days: Int {
            switch self {
            case .week: return 7
            case .month: return 30
            case .quarter: return 90
            case .year: return 365
            }
        }
    }

    private var filteredEntries: [SymptomEntry] {
        let cutoff = Date().addingTimeInterval(-Double(selectedTimeRange.days * 86400))
        return dataStore.entries.filter { $0.timestamp >= cutoff }
            .sorted { $0.timestamp > $1.timestamp }
    }

    private var uniqueSymptomCount: Int {
        Set(filteredEntries.map(\.symptomName)).count
    }

    private var averageSeverity: String {
        guard !filteredEntries.isEmpty else { return "--" }
        let avg = Double(filteredEntries.map(\.severity).reduce(0, +)) / Double(filteredEntries.count)
        return String(format: "%.1f", avg)
    }

    var body: some View {
        ZStack {
            Color.SS.background.ignoresSafeArea()

            VStack(spacing: 0) {
                SSNavigationBar(title: "History", subtitle: "Your symptom timeline")

                ScrollView(showsIndicators: false) {
                    VStack(spacing: Spacing.xl) {
                        // Time range selector
                        HStack(spacing: 4) {
                            ForEach(TimeRange.allCases, id: \.self) { range in
                                Button(action: {
                                    SSHaptics.selection()
                                    withAnimation { selectedTimeRange = range }
                                }) {
                                    Text(range.rawValue)
                                        .font(Font.SS.labelMedium)
                                        .foregroundColor(
                                            selectedTimeRange == range ? Color.SS.background : Color.SS.textSecondary
                                        )
                                        .tracking(0.5)
                                        .frame(maxWidth: .infinity)
                                        .padding(.vertical, Spacing.xs)
                                        .background(
                                            Capsule()
                                                .fill(selectedTimeRange == range ? Color.SS.accent : Color.clear)
                                        )
                                }
                                .accessibilityLabel("View \(range.days) day history")
                            }
                        }
                        .padding(3)
                        .background(
                            Capsule()
                                .fill(Color.SS.surfaceSecondary)
                        )
                        .padding(.horizontal, Spacing.xl)

                        // Mini chart
                        HistoryChartView(timeRange: selectedTimeRange, dataStore: dataStore)
                            .padding(.horizontal, Spacing.xl)

                        // Summary stats
                        HStack(spacing: Spacing.sm) {
                            HistoryStatCard(value: "\(filteredEntries.count)", label: "Total Entries", color: Color.SS.accent)
                            HistoryStatCard(value: averageSeverity, label: "Avg Severity", color: Color.SS.warning)
                            HistoryStatCard(value: "\(uniqueSymptomCount)", label: "Unique", color: Color.SS.violet)
                        }
                        .padding(.horizontal, Spacing.xl)

                        // Activity heat map
                        SymptomHeatMapCard(
                            timeRange: selectedTimeRange,
                            dataStore: dataStore
                        )
                        .padding(.horizontal, Spacing.xl)

                        // Entries by day
                        VStack(alignment: .leading, spacing: Spacing.md) {
                            Text("All Entries")
                                .font(Font.SS.headlineSmall)
                                .foregroundColor(Color.SS.textPrimary)
                                .padding(.horizontal, Spacing.xl)

                            if filteredEntries.isEmpty {
                                SSEmptyState(
                                    icon: "ss.tab.history",
                                    title: "No entries yet",
                                    subtitle: "Start logging symptoms to build your history"
                                )
                            } else {
                                LazyVStack(spacing: Spacing.xs) {
                                    ForEach(filteredEntries) { entry in
                                        SymptomEntryRow(entry: entry)
                                            .swipeActions(edge: .trailing) {
                                                Button(role: .destructive) {
                                                    SSHaptics.medium()
                                                    withAnimation { dataStore.deleteEntry(entry) }
                                                } label: {
                                                    Text("Delete")
                                                }
                                                .accessibilityLabel("Delete symptom entry")
                                            }
                                    }
                                }
                                .padding(.horizontal, Spacing.xl)
                            }
                        }

                        Spacer(minLength: 120)
                    }
                }
            }
        }
        .opacity(showContent ? 1 : 0)
        .onAppear {
            withAnimation(.easeOut(duration: 0.3)) { showContent = true }
        }
    }
}

// MARK: - History Chart
struct HistoryChartView: View {
    let timeRange: HistoryView.TimeRange
    let dataStore: DataStore

    private var dataPoints: [CGFloat] {
        let calendar = Calendar.current
        let bucketCount: Int
        let bucketDays: Int

        switch timeRange {
        case .week:
            bucketCount = 7; bucketDays = 1
        case .month:
            bucketCount = 4; bucketDays = 7
        case .quarter:
            bucketCount = 3; bucketDays = 30
        case .year:
            bucketCount = 4; bucketDays = 90
        }

        var points: [CGFloat] = []
        for i in (0..<bucketCount).reversed() {
            let end = calendar.date(byAdding: .day, value: -i * bucketDays, to: Date()) ?? Date()
            let start = calendar.date(byAdding: .day, value: -bucketDays, to: end) ?? end
            let bucketEntries = dataStore.entriesForDateRange(from: start, to: end)
            if bucketEntries.isEmpty {
                points.append(0)
            } else {
                let avg = Double(bucketEntries.map(\.severity).reduce(0, +)) / Double(bucketEntries.count)
                points.append(CGFloat(avg))
            }
        }
        return points
    }

    var body: some View {
        SSCard(padding: Spacing.md) {
            VStack(alignment: .leading, spacing: Spacing.sm) {
                HStack {
                    Text("Severity Trend")
                        .font(Font.SS.labelMedium)
                        .foregroundColor(Color.SS.textTertiary)
                        .tracking(0.5)
                    Spacer()
                    if dataPoints.count >= 2 {
                        let last = dataPoints.last ?? 0
                        let prev = dataPoints[dataPoints.count - 2]
                        if last < prev {
                            HStack(spacing: 4) {
                                SSIconImage(name: "ss.arrow.downright", size: 12)
                                    .foregroundColor(Color.SS.success)
                                Text("Improving")
                                    .font(Font.SS.labelSmall)
                                    .foregroundColor(Color.SS.success)
                            }
                        } else if last > prev {
                            HStack(spacing: 4) {
                                SSIconImage(name: "ss.arrow.up", size: 12)
                                    .foregroundColor(Color.SS.warning)
                                Text("Increasing")
                                    .font(Font.SS.labelSmall)
                                    .foregroundColor(Color.SS.warning)
                            }
                        } else {
                            Text("Stable")
                                .font(Font.SS.labelSmall)
                                .foregroundColor(Color.SS.textTertiary)
                        }
                    }
                }

                // Line chart
                GeometryReader { geo in
                    let points = dataPoints
                    let maxVal = max(points.max() ?? 10, 1)
                    if points.count > 1 {
                        Path { path in
                            let stepX = geo.size.width / CGFloat(points.count - 1)
                            for (index, point) in points.enumerated() {
                                let x = stepX * CGFloat(index)
                                let y = geo.size.height - (point / maxVal * geo.size.height)
                                if index == 0 {
                                    path.move(to: CGPoint(x: x, y: y))
                                } else {
                                    path.addLine(to: CGPoint(x: x, y: y))
                                }
                            }
                        }
                        .stroke(
                            LinearGradient(
                                colors: [Color.SS.accent, Color.SS.violet],
                                startPoint: .leading,
                                endPoint: .trailing
                            ),
                            style: StrokeStyle(lineWidth: 1.5, lineCap: .round, lineJoin: .round)
                        )

                        ForEach(Array(points.enumerated()), id: \.offset) { index, point in
                            let stepX = geo.size.width / CGFloat(points.count - 1)
                            Circle()
                                .fill(Color.SS.accent)
                                .frame(width: 4, height: 4)
                                .position(
                                    x: stepX * CGFloat(index),
                                    y: geo.size.height - (point / maxVal * geo.size.height)
                                )
                        }
                    } else {
                        Text("Not enough data")
                            .font(Font.SS.bodySmall)
                            .foregroundColor(Color.SS.textDisabled)
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                    }
                }
                .frame(height: 120)

                // X-axis labels
                HStack {
                    ForEach(xLabels, id: \.self) { label in
                        Text(label)
                            .font(Font.SS.caption)
                            .foregroundColor(Color.SS.textDisabled)
                        if label != xLabels.last { Spacer() }
                    }
                }
            }
        }
    }

    private var xLabels: [String] {
        switch timeRange {
        case .week: return ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"]
        case .month: return ["W1", "W2", "W3", "W4"]
        case .quarter: return ["M1", "M2", "M3"]
        case .year: return ["Q1", "Q2", "Q3", "Q4"]
        }
    }
}

// MARK: - Symptom Heat Map Card
struct SymptomHeatMapCard: View {
    let timeRange: HistoryView.TimeRange
    let dataStore: DataStore

    private let cellSize: CGFloat = 12
    private let cellSpacing: CGFloat = 3
    private let dayLabels = ["M", "T", "W", "T", "F", "S", "S"]

    /// Build a grid of entry counts keyed by (column, row).
    /// Row 0 = Monday, row 6 = Sunday. Columns run oldest → newest (left → right).
    private var gridData: (columns: Int, counts: [[Int]]) {
        let calendar = Calendar.current
        let totalDays = timeRange.days
        let today = calendar.startOfDay(for: Date())

        // Monday = 1 in ISO, Sunday = 7. Map to row index 0-6.
        func rowIndex(for date: Date) -> Int {
            let weekday = calendar.component(.weekday, from: date) // Sun=1 … Sat=7
            // Convert to Mon=0 … Sun=6
            return (weekday + 5) % 7
        }

        // Figure out how many columns we need
        let startDate = calendar.date(byAdding: .day, value: -(totalDays - 1), to: today) ?? today
        let startRow = rowIndex(for: startDate)
        let totalSlots = startRow + totalDays
        let columns = Int(ceil(Double(totalSlots) / 7.0))

        // Initialize the grid
        var counts = Array(repeating: Array(repeating: -1, count: 7), count: columns)

        // Fill valid cells with entry counts
        for dayOffset in 0..<totalDays {
            guard let date = calendar.date(byAdding: .day, value: dayOffset, to: startDate) else { continue }
            let row = rowIndex(for: date)
            let slotIndex = startRow + dayOffset
            let col = slotIndex / 7
            let entryCount = dataStore.entriesForDate(date).count
            counts[col][row] = entryCount
        }

        return (columns, counts)
    }

    private func cellColor(for count: Int) -> Color {
        switch count {
        case _ where count < 0:
            return Color.clear
        case 0:
            return Color.SS.surfaceTertiary
        case 1:
            return Color.SS.accent.opacity(0.3)
        case 2:
            return Color.SS.accent.opacity(0.55)
        default:
            return Color.SS.accent.opacity(0.85)
        }
    }

    var body: some View {
        SSCard(padding: Spacing.md) {
            VStack(alignment: .leading, spacing: Spacing.sm) {
                Text("Activity Map")
                    .font(Font.SS.labelMedium)
                    .foregroundColor(Color.SS.textTertiary)
                    .tracking(0.5)

                let grid = gridData

                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(alignment: .top, spacing: cellSpacing) {
                        // Day-of-week labels column
                        VStack(spacing: cellSpacing) {
                            ForEach(0..<7, id: \.self) { row in
                                Text(dayLabels[row])
                                    .font(Font.SS.caption)
                                    .foregroundColor(Color.SS.textDisabled)
                                    .frame(width: cellSize, height: cellSize)
                            }
                        }

                        // Grid columns
                        ForEach(0..<grid.columns, id: \.self) { col in
                            VStack(spacing: cellSpacing) {
                                ForEach(0..<7, id: \.self) { row in
                                    let count = grid.counts[col][row]
                                    RoundedRectangle(cornerRadius: 2)
                                        .fill(cellColor(for: count))
                                        .frame(width: cellSize, height: cellSize)
                                }
                            }
                        }
                    }
                }

                // Legend
                HStack(spacing: Spacing.xs) {
                    Spacer()

                    Text("Less")
                        .font(Font.SS.caption)
                        .foregroundColor(Color.SS.textDisabled)

                    ForEach([0, 1, 2, 3], id: \.self) { level in
                        RoundedRectangle(cornerRadius: 2)
                            .fill(cellColor(for: level))
                            .frame(width: cellSize, height: cellSize)
                    }

                    Text("More")
                        .font(Font.SS.caption)
                        .foregroundColor(Color.SS.textDisabled)
                }
            }
        }
    }
}

// MARK: - History Stat Card
struct HistoryStatCard: View {
    let value: String
    let label: String
    let color: Color

    var body: some View {
        VStack(spacing: 6) {
            Text(value)
                .font(Font.SS.dataMedium)
                .foregroundColor(color)

            Text(label)
                .font(Font.SS.caption)
                .foregroundColor(Color.SS.textTertiary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, Spacing.md)
        .background(
            RoundedRectangle(cornerRadius: Radius.md)
                .fill(Color.SS.surfaceSecondary)
                .overlay(
                    RoundedRectangle(cornerRadius: Radius.md)
                        .strokeBorder(Color.SS.separator, lineWidth: 0.5)
                )
        )
    }
}
