import SwiftUI

struct InsightsView: View {
    @EnvironmentObject var dataStore: DataStore
    @StateObject private var wellnessEngine = WellnessScoreEngine()
    @StateObject private var analysisEngine = SymptomAnalysisEngine()
    @AppStorage("healthKitEnabled") private var healthKitEnabled = true
    @State private var showContent = false
    @State private var showExportSheet = false
    @State private var showPDFExport = false

    /// Entries scoped to the last 30 days for charts that should show recent data
    private var recentEntries: [SymptomEntry] {
        let cutoff = Date().addingTimeInterval(-30 * 86400)
        return dataStore.entries.filter { $0.timestamp >= cutoff }
    }

    private var insights: [Insight] {
        var result: [Insight] = []
        let freq = dataStore.symptomFrequency(days: 30)

        // Top symptom: actionable severity context
        if let top = freq.first {
            let avg = dataStore.averageSeverity(for: top.0, days: 30)
            let severity = avg >= 7 ? "severe" : avg >= 5 ? "moderate" : "mild"
            let action = avg >= 6 ? "Consider discussing this with your doctor." : "Keep tracking to spot what triggers it."
            result.append(Insight(
                title: "\(top.0), \(severity) pattern",
                description: "\(top.0) averages \(String(format: "%.1f", avg))/10 across \(top.1) entries this month. \(action)",
                icon: "ss.tab.insights",
                color: avg >= 6 ? Color.SS.error : Color(hex: "EC4899"),
                type: .trend
            ))
        }

        // Co-occurrence: find linked symptoms
        let coOccurrence = dataStore.symptomCoOccurrence(days: 30)
        if let top = coOccurrence.first, top.coCount >= 3 {
            let pct = Int(top.ratio * 100)
            result.append(Insight(
                title: "\(top.symptom1) + \(top.symptom2) are linked",
                description: "These appear on the same day \(pct)% of the time (\(top.coCount) days). They likely share a common trigger, check your entries for overlap.",
                icon: "ss.link",
                color: Color(hex: "818CF8"),
                type: .correlation
            ))
        } else if freq.count >= 2 {
            result.append(Insight(
                title: "\(freq.count) symptoms tracked",
                description: "\(freq.prefix(2).map(\.0).joined(separator: " and ")) are your most frequent. Log a few more days to reveal connections.",
                icon: "ss.link",
                color: Color(hex: "818CF8"),
                type: .correlation
            ))
        }

        // Streak: celebrate and motivate
        let streak = dataStore.currentStreak()
        if streak >= 7 {
            result.append(Insight(
                title: "\(streak)-day streak, insights unlocked!",
                description: "A full week of data means your pattern detection is now accurate. Correlations and predictions are live.",
                icon: "ss.flame",
                color: Color(hex: "FB923C"),
                type: .milestone
            ))
        } else if streak >= 3 {
            result.append(Insight(
                title: "\(streak)-day streak, keep going!",
                description: "Log \(7 - streak) more days to unlock accurate pattern detection and predictions.",
                icon: "ss.flame",
                color: Color(hex: "FB923C"),
                type: .milestone
            ))
        }

        // Trigger correlation: specific and actionable
        let triggerCorr = dataStore.triggerCorrelations(days: 30)
        if let top = triggerCorr.first, top.avgWith - top.avgWithout >= 0.5 {
            let pctWorse = Int(((top.avgWith - top.avgWithout) / max(top.avgWithout, 1)) * 100)
            result.append(Insight(
                title: "\(top.trigger) makes symptoms \(pctWorse)% worse",
                description: "Severity jumps from \(String(format: "%.1f", top.avgWithout)) to \(String(format: "%.1f", top.avgWith)) when \(top.trigger.lowercased()) is present. Try reducing exposure on tough days.",
                icon: "ss.sparkles",
                color: Color(hex: "F97316"),
                type: .correlation
            ))
        }

        // Lifestyle correlations: already actionable from DataStore
        let lifestyleCorr = dataStore.lifestyleCorrelations(days: 30)
        for corr in lifestyleCorr.prefix(2) {
            result.append(Insight(
                title: "\(corr.factor) affects your symptoms",
                description: corr.finding,
                icon: corr.icon,
                color: Color(hex: corr.color),
                type: .correlation
            ))
        }

        // Water
        if let waterCorr = dataStore.waterCorrelation() {
            result.append(Insight(
                title: "Hydration matters",
                description: waterCorr.finding,
                icon: waterCorr.icon,
                color: Color(hex: waterCorr.color),
                type: .correlation
            ))
        }

        // Duration
        let durationCorr = dataStore.durationInsights()
        if let top = durationCorr.first {
            result.append(Insight(
                title: top.factor,
                description: top.finding,
                icon: top.icon,
                color: Color(hex: top.color),
                type: .trend
            ))
        }

        // Medication: clear impact statement
        let medCorr = dataStore.medicationCorrelations()
        if let top = medCorr.first {
            result.append(Insight(
                title: top.factor,
                description: top.finding,
                icon: top.icon,
                color: Color(hex: top.color),
                type: .correlation
            ))
        }

        if result.isEmpty {
            result.append(Insight(
                title: "Your insights are building",
                description: "Log symptoms for 5+ days to unlock AI pattern detection, trigger analysis, and personalized predictions.",
                icon: "ss.sparkles",
                color: Color.SS.accent,
                type: .trend
            ))
        }

        return result
    }

    var body: some View {
        NavigationStack {
        ZStack {
            Color.SS.background.ignoresSafeArea()

            VStack(spacing: 0) {
                SSNavigationBar(title: "Insights", subtitle: "AI-powered analysis")

                ScrollView(showsIndicators: false) {
                    VStack(spacing: Spacing.xl) {
                        // Wellness Score
                        InsightsSectionHeader(title: "Wellness Score", subtitle: "Your overall health snapshot")
                        WellnessScoreCard(engine: wellnessEngine)
                            .padding(.horizontal, Spacing.xl)

                        // Correlation Map
                        CorrelationCard(dataStore: dataStore)
                            .padding(.horizontal, Spacing.xl)

                        // History
                        NavigationLink(destination: HistoryView().environmentObject(dataStore)) {
                            SSCard(padding: Spacing.md) {
                                HStack(spacing: Spacing.md) {
                                    ZStack {
                                        Circle()
                                            .fill(Color.SS.accent.opacity(0.12))
                                            .frame(width: 40, height: 40)
                                        Image(systemName: "clock.arrow.circlepath")
                                            .font(.system(size: 16, weight: .medium))
                                            .foregroundColor(Color.SS.accent)
                                    }

                                    VStack(alignment: .leading, spacing: 3) {
                                        Text("Symptom History")
                                            .font(Font.SS.accentSmall)
                                            .foregroundColor(Color.SS.textPrimary)
                                        Text("Browse past entries, charts & heatmaps")
                                            .font(Font.SS.caption)
                                            .foregroundColor(Color.SS.textTertiary)
                                    }

                                    Spacer()

                                    Image(systemName: "chevron.right")
                                        .font(.system(size: 12, weight: .semibold))
                                        .foregroundColor(Color.SS.textDisabled)
                                }
                            }
                        }
                        .accessibilityLabel("View symptom history")
                        .buttonStyle(PlainButtonStyle())
                        .padding(.horizontal, Spacing.xl)

                        // Insights List
                        InsightsSectionHeader(title: "AI Insights", subtitle: "Patterns detected in your data")
                        VStack(alignment: .leading, spacing: Spacing.md) {
                            Text("Discoveries")
                                .font(Font.SS.headlineSmall)
                                .foregroundColor(Color.SS.textPrimary)
                                .padding(.horizontal, Spacing.xl)

                            LazyVStack(spacing: Spacing.sm) {
                                ForEach(insights) { insight in
                                    InsightCard(insight: insight)
                                }
                            }
                            .padding(.horizontal, Spacing.xl)
                        }

                        // Doctor Visit Prep
                        NavigationLink(destination: DoctorPrepView().environmentObject(dataStore)) {
                            SSCard(padding: Spacing.md) {
                                HStack(spacing: Spacing.md) {
                                    ZStack {
                                        Circle()
                                            .fill(Color.SS.violet.opacity(0.12))
                                            .frame(width: 40, height: 40)
                                        Image(systemName: "stethoscope")
                                            .font(.system(size: 16, weight: .medium))
                                            .foregroundColor(Color.SS.violet)
                                    }

                                    VStack(alignment: .leading, spacing: 3) {
                                        Text("Prepare for Your Visit")
                                            .font(Font.SS.accentSmall)
                                            .foregroundColor(Color.SS.textPrimary)
                                        Text("Curated summary for your next appointment")
                                            .font(Font.SS.caption)
                                            .foregroundColor(Color.SS.textTertiary)
                                    }

                                    Spacer()

                                    Image(systemName: "chevron.right")
                                        .font(.system(size: 12, weight: .semibold))
                                        .foregroundColor(Color.SS.textDisabled)
                                }
                            }
                        }
                        .accessibilityLabel("Prepare for your doctor visit")
                        .buttonStyle(PlainButtonStyle())
                        .padding(.horizontal, Spacing.xl)

                        // Charts Section
                        InsightsSectionHeader(title: "Symptom Analytics", subtitle: "Visualize your trends")
                        VStack(alignment: .leading, spacing: Spacing.md) {
                            Text("Charts")
                                .font(Font.SS.headlineSmall)
                                .foregroundColor(Color.SS.textPrimary)
                                .padding(.horizontal, Spacing.xl)

                            DonutChartCard(entries: recentEntries)
                                .padding(.horizontal, Spacing.xl)

                            CategoryBreakdownCard(entries: dataStore.entries, customSymptoms: dataStore.customSymptoms)
                                .padding(.horizontal, Spacing.xl)

                            WeeklyComparisonCard(dataStore: dataStore)
                                .padding(.horizontal, Spacing.xl)

                            TriggerImpactCard(entries: dataStore.entries)
                                .padding(.horizontal, Spacing.xl)

                            MoodEnergyTrendCard(summaries: dataStore.dailySummaries)
                                .padding(.horizontal, Spacing.xl)

                            SleepSeverityCard(
                                summaries: dataStore.dailySummaries,
                                entries: dataStore.entries
                            )
                            .padding(.horizontal, Spacing.xl)

                            TimeOfDayCard(entries: dataStore.entries)
                                .padding(.horizontal, Spacing.xl)

                            SymptomForecastCard(dataStore: dataStore)
                                .padding(.horizontal, Spacing.xl)

                            SeverityTrendLineCard(dataStore: dataStore)
                                .padding(.horizontal, Spacing.xl)

                            SymptomPieCard(entries: recentEntries, customSymptoms: dataStore.customSymptoms)
                                .padding(.horizontal, Spacing.xl)

                            DailyEntryBarCard(dataStore: dataStore)
                                .padding(.horizontal, Spacing.xl)

                            MoodWeeklyBarCard(summaries: dataStore.dailySummaries)
                                .padding(.horizontal, Spacing.xl)

                            SeverityHeatmapCard(dataStore: dataStore)
                                .padding(.horizontal, Spacing.xl)

                            SymptomRadarCard(entries: dataStore.entries, customSymptoms: dataStore.customSymptoms)
                                .padding(.horizontal, Spacing.xl)
                        }

                        // ML Analysis
                        InsightsSectionHeader(title: "Pattern Analysis", subtitle: "Machine learning findings")
                        MLAnalysisCard(engine: analysisEngine)
                            .padding(.horizontal, Spacing.xl)

                        // Correlations
                        InsightsSectionHeader(title: "Correlations", subtitle: "What affects your symptoms")

                        // Weather Correlations (always visible)
                        CorrelationSection(
                            title: "Weather Impact",
                            correlations: dataStore.weatherCorrelations(),
                            emptyMessage: "Not enough weather data yet, keep logging for weather-based insights"
                        )

                        // Health Correlations (always visible)
                        CorrelationSection(
                            title: "Health & Activity",
                            correlations: dataStore.healthCorrelations(),
                            emptyMessage: "Enable Apple Health in Settings to see how sleep, steps, and exercise affect your symptoms"
                        )

                        // Lifestyle Deep Dive (always visible)
                        CorrelationSection(
                            title: "Lifestyle & Medication",
                            correlations: {
                                let waterCorr = dataStore.waterCorrelation()
                                let durationCorr = dataStore.durationInsights()
                                let medCorr = dataStore.medicationCorrelations()
                                return [waterCorr].compactMap { $0 } + durationCorr + medCorr
                            }(),
                            emptyMessage: "Log water intake, medications, and check-ins to see lifestyle correlations"
                        )

                        // Trend cards
                        InsightsSectionHeader(title: "Weekly Trends", subtitle: "This week vs last week")
                        VStack(alignment: .leading, spacing: Spacing.md) {
                            Text("Trends")
                                .font(Font.SS.headlineSmall)
                                .foregroundColor(Color.SS.textPrimary)
                                .padding(.horizontal, Spacing.xl)

                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: Spacing.sm) {
                                    ForEach(trendCards, id: \.title) { card in
                                        TrendCard(
                                            title: card.title,
                                            trend: card.trend,
                                            subtitle: card.subtitle,
                                            color: card.color,
                                            isPositive: card.isPositive
                                        )
                                    }
                                }
                                .padding(.horizontal, Spacing.xl)
                            }
                        }

                        // Export buttons
                        VStack(spacing: Spacing.sm) {
                            #if canImport(UIKit)
                            SSButton(title: "Export PDF Report", icon: "ss.doc.richtext", style: .primary) {
                                SSHaptics.light()
                                showPDFExport = true
                            }
                            .accessibilityLabel("Export PDF report for your healthcare provider")
                            #endif

                            SSButton(title: "Export CSV Data", icon: "ss.doc.richtext", style: .secondary) {
                                SSHaptics.light()
                                showExportSheet = true
                            }
                            .accessibilityLabel("Export symptom data as CSV file")
                            Text("Share reports with your healthcare provider")
                                .font(Font.SS.caption)
                                .foregroundColor(Color.SS.textDisabled)
                        }
                        .padding(.horizontal, Spacing.xl)

                        Spacer(minLength: 120)
                    }
                }
            }
        }
        .opacity(showContent ? 1 : 0)
        .onAppear {
            wellnessEngine.computeWeeklyScores(dataStore: dataStore, profile: dataStore.onboardingProfile, healthKitEnabled: healthKitEnabled)
            analysisEngine.analyze(dataStore: dataStore, profile: dataStore.onboardingProfile)
            withAnimation(.easeOut(duration: 0.3)) { showContent = true }
        }
        .onChange(of: dataStore.entries.count) {
            wellnessEngine.computeWeeklyScores(dataStore: dataStore, profile: dataStore.onboardingProfile, healthKitEnabled: healthKitEnabled)
            analysisEngine.analyze(dataStore: dataStore, profile: dataStore.onboardingProfile)
        }
        .onChange(of: dataStore.dailySummaries.count) {
            wellnessEngine.computeWeeklyScores(dataStore: dataStore, profile: dataStore.onboardingProfile, healthKitEnabled: healthKitEnabled)
            analysisEngine.analyze(dataStore: dataStore, profile: dataStore.onboardingProfile)
        }
        .sheet(isPresented: $showExportSheet) {
            ShareSheet(items: [dataStore.exportCSV()])
        }
        #if canImport(UIKit)
        .sheet(isPresented: $showPDFExport) {
            let pdfData = PDFReportGenerator.generateReport(
                dataStore: dataStore,
                wellnessScore: wellnessEngine.currentScore
            )
            ShareSheet(items: [pdfData])
        }
        #endif
        .navigationBarHidden(true)
        } // NavigationStack
    }

    private struct TrendData {
        let title: String
        let trend: String
        let subtitle: String
        let color: Color
        let isPositive: Bool
    }

    private var trendCards: [TrendData] {
        let freq = dataStore.symptomFrequency(days: 7)
        var cards: [TrendData] = []
        for item in freq.prefix(3) {
            let thisWeek = item.1
            let lastWeekEntries = dataStore.entries.filter {
                $0.symptomName == item.0 &&
                $0.timestamp >= Date().addingTimeInterval(-14 * 86400) &&
                $0.timestamp < Date().addingTimeInterval(-7 * 86400)
            }.count
            let change: Int
            if lastWeekEntries > 0 {
                change = Int(round(Double(thisWeek - lastWeekEntries) / Double(lastWeekEntries) * 100))
            } else {
                change = thisWeek > 0 ? 100 : 0
            }
            let isPositive = change <= 0
            let trendStr = change < 0 ? "\(change)%" : change > 0 ? "+\(change)%" : "0%"
            cards.append(TrendData(
                title: item.0,
                trend: trendStr,
                subtitle: isPositive ? "improving" : "increasing",
                color: Symptom.find(item.0, customSymptoms: dataStore.customSymptoms).map { Color(hex: $0.color) } ?? Color.SS.accent,
                isPositive: isPositive
            ))
        }
        if cards.isEmpty {
            cards.append(TrendData(title: "No Data", trend: "--", subtitle: "log symptoms", color: Color.SS.textDisabled, isPositive: true))
        }
        return cards
    }
}

// MARK: - Wellness Score
struct WellnessScoreCard: View {
    @ObservedObject var engine: WellnessScoreEngine
    @State private var animatedScore: Double = 0

    var body: some View {
        SSCard(padding: Spacing.lg) {
            VStack(spacing: Spacing.md) {
                HStack {
                    Text("Wellness Score")
                        .font(Font.SS.labelMedium)
                        .foregroundColor(Color.SS.textTertiary)
                        .tracking(0.5)
                    Spacer()
                    Text("ML-Powered")
                        .font(Font.SS.caption)
                        .foregroundColor(Color.SS.accent)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(
                            Capsule().fill(Color.SS.accentSubtle)
                        )
                }

                HStack(spacing: Spacing.xl) {
                    ZStack {
                        SSProgressRing(
                            progress: animatedScore / 100,
                            lineWidth: 3,
                            size: 90,
                            color: scoreColor
                        )

                        VStack(spacing: 0) {
                            Text("\(Int(animatedScore))")
                                .font(.system(size: 32, weight: .ultraLight, design: .monospaced))
                                .foregroundColor(Color.SS.textPrimary)
                                .contentTransition(.numericText())
                            Text("/100")
                                .font(Font.SS.caption)
                                .foregroundColor(Color.SS.textTertiary)
                        }
                    }

                    // Breakdown bars from the engine
                    VStack(alignment: .leading, spacing: Spacing.sm) {
                        let b = engine.scoreBreakdown
                        ScoreBreakdownRow(
                            label: "Mood",
                            value: max(0.05, b.moodContribution / 20.0),
                            color: Color.SS.accent
                        )
                        ScoreBreakdownRow(
                            label: "Energy",
                            value: max(0.05, b.energyContribution / 15.0),
                            color: Color.SS.violet
                        )
                        ScoreBreakdownRow(
                            label: "Severity Impact",
                            value: max(0.05, min(1.0, 1.0 + b.severityPenalty / 25.0)),
                            color: b.severityPenalty < -10 ? Color.SS.warning : Color(hex: "818CF8")
                        )
                        ScoreBreakdownRow(
                            label: "Streak Bonus",
                            value: max(0.05, b.streakBonus / 12.0),
                            color: Color(hex: "34D399")
                        )
                        if b.healthBonus != 0 {
                            ScoreBreakdownRow(
                                label: "Health Data",
                                value: max(0.05, min(1.0, (b.healthBonus + 6) / 13.0)),
                                color: b.healthBonus >= 0 ? Color.SS.info : Color.SS.warning
                            )
                        }
                    }
                }
            }
        }
        .onAppear {
            withAnimation(.easeOut(duration: 1.2).delay(0.3)) {
                animatedScore = engine.currentScore
            }
        }
        .onChange(of: engine.currentScore) {
            withAnimation(.easeOut(duration: 0.8)) {
                animatedScore = engine.currentScore
            }
        }
    }

    private var scoreColor: Color {
        switch Int(animatedScore) {
        case 0..<30: return Color.SS.error
        case 30..<50: return Color.SS.warning
        case 50..<70: return Color.SS.accent
        default: return Color.SS.success
        }
    }
}

struct ScoreBreakdownRow: View {
    let label: String
    let value: Double
    let color: Color

    var body: some View {
        VStack(spacing: 3) {
            HStack {
                Text(label)
                    .font(Font.SS.caption)
                    .foregroundColor(Color.SS.textTertiary)
                Spacer()
                Text("\(Int(value * 100))%")
                    .font(Font.SS.caption)
                    .foregroundColor(color)
                    .monospacedDigit()
            }
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule().fill(Color.SS.surfaceTertiary)
                    Capsule().fill(color).frame(width: geo.size.width * value)
                }
            }
            .frame(height: 3)
        }
    }
}

// MARK: - Correlation Card
struct CorrelationCard: View {
    let dataStore: DataStore

    private var topCoOccurrence: (String, String, Int, Double)? {
        dataStore.symptomCoOccurrence(days: 30).first
    }

    private var topTriggerCorrelation: (trigger: String, avgWith: Double, avgWithout: Double, count: Int)? {
        dataStore.triggerCorrelations(days: 30).first
    }

    var body: some View {
        SSAccentCard(accentColor: Color.SS.violet) {
            VStack(alignment: .leading, spacing: Spacing.sm) {
                HStack {
                    SSIconImage(name: "ss.link", size: 14)
                        .foregroundColor(Color.SS.violet)
                    Text("Top Correlations")
                        .font(Font.SS.labelMedium)
                        .foregroundColor(Color.SS.textTertiary)
                        .tracking(0.5)
                }

                if let co = topCoOccurrence {
                    // Symptom co-occurrence
                    HStack(spacing: Spacing.md) {
                        VStack(spacing: 4) {
                            SSIconImage(name: iconFor(co.0), size: 20)
                                .foregroundColor(colorFor(co.0))
                            Text(co.0)
                                .font(Font.SS.labelSmall)
                                .foregroundColor(Color.SS.textSecondary)
                        }
                        .frame(maxWidth: .infinity)

                        VStack(spacing: 4) {
                            Circle().fill(Color.SS.violet).frame(width: 4, height: 4)
                            Rectangle().fill(Color.SS.violet.opacity(0.3)).frame(width: 1, height: 16)
                            Text("\(co.2)d")
                                .font(Font.SS.caption)
                                .foregroundColor(Color.SS.violet)
                            Rectangle().fill(Color.SS.violet.opacity(0.3)).frame(width: 1, height: 16)
                            Circle().fill(Color.SS.violet).frame(width: 4, height: 4)
                        }

                        VStack(spacing: 4) {
                            SSIconImage(name: iconFor(co.1), size: 20)
                                .foregroundColor(colorFor(co.1))
                            Text(co.1)
                                .font(Font.SS.labelSmall)
                                .foregroundColor(Color.SS.textSecondary)
                        }
                        .frame(maxWidth: .infinity)
                    }

                    Text("Appeared together on \(co.2) days (\(Int(co.3 * 100))% overlap)")
                        .font(Font.SS.caption)
                        .foregroundColor(Color.SS.textTertiary)
                } else if let trigger = topTriggerCorrelation {
                    // Trigger correlation fallback
                    HStack(spacing: Spacing.md) {
                        SSIconImage(name: "ss.sparkles", size: 18)
                            .foregroundColor(Color.SS.warning)
                        VStack(alignment: .leading, spacing: 2) {
                            Text(trigger.trigger)
                                .font(Font.SS.bodyMedium)
                                .foregroundColor(Color.SS.textPrimary)
                            Text("Avg severity: \(String(format: "%.1f", trigger.avgWith)) with vs \(String(format: "%.1f", trigger.avgWithout)) without")
                                .font(Font.SS.caption)
                                .foregroundColor(Color.SS.textTertiary)
                        }
                    }
                } else {
                    Text("Log more symptoms to discover correlations between them.")
                        .font(Font.SS.bodySmall)
                        .foregroundColor(Color.SS.textTertiary)
                }
            }
        }
    }

    private func iconFor(_ name: String) -> String {
        Symptom.find(name, customSymptoms: dataStore.customSymptoms)?.icon ?? "ss.ecg"
    }

    private func colorFor(_ name: String) -> Color {
        Symptom.find(name, customSymptoms: dataStore.customSymptoms).map { Color(hex: $0.color) } ?? Color.SS.accent
    }
}

// MARK: - Insight Card
struct InsightCard: View {
    let insight: Insight

    var body: some View {
        SSCard(padding: Spacing.md) {
            HStack(spacing: Spacing.md) {
                SSIconImage(name: insight.icon, size: 20)
                    .foregroundColor(insight.color)
                    .frame(width: 32)

                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text(insight.title)
                            .font(Font.SS.accentSmall)
                            .foregroundColor(Color.SS.textPrimary)

                        Spacer()

                        SSChip(label: insightTypeLabel, color: insight.color)
                    }

                    Text(insight.description)
                        .font(Font.SS.bodySmall)
                        .foregroundColor(Color.SS.textSecondary)
                        .lineSpacing(4)
                }
            }
        }
    }

    private var insightTypeLabel: String {
        switch insight.type {
        case .trend: return "Trend"
        case .correlation: return "Link"
        case .alert: return "Alert"
        case .milestone: return "Goal"
        }
    }
}

// MARK: - Trend Card
struct TrendCard: View {
    let title: String
    let trend: String
    let subtitle: String
    let color: Color
    let isPositive: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            Circle()
                .fill(color.opacity(0.12))
                .frame(width: 36, height: 36)
                .overlay(
                    SSIconImage(name: isPositive ? "ss.arrow.downright" : "ss.arrow.up", size: 14)
                        .foregroundColor(color)
                )

            Text(title)
                .font(Font.SS.bodyMedium)
                .foregroundColor(Color.SS.textPrimary)

            Text(trend)
                .font(Font.SS.accentMedium)
                .foregroundColor(isPositive ? Color.SS.success : Color.SS.warning)

            Text(subtitle)
                .font(Font.SS.caption)
                .foregroundColor(Color.SS.textTertiary)
        }
        .frame(width: 140)
        .padding(Spacing.md)
        .background(
            RoundedRectangle(cornerRadius: Radius.lg)
                .fill(Color.SS.surfaceSecondary)
                .overlay(
                    RoundedRectangle(cornerRadius: Radius.lg)
                        .strokeBorder(Color.SS.separator, lineWidth: 0.5)
                )
        )
    }
}

// MARK: - Correlation Section (always visible)
struct CorrelationSection: View {
    let title: String
    let correlations: [(factor: String, finding: String, icon: String, color: String)]
    let emptyMessage: String

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            Text(title)
                .font(Font.SS.headlineSmall)
                .foregroundColor(Color.SS.textPrimary)
                .padding(.horizontal, Spacing.xl)

            if correlations.isEmpty {
                SSCard(padding: Spacing.md) {
                    HStack(spacing: Spacing.md) {
                        SSIconImage(name: "ss.ecg", size: 20)
                            .foregroundColor(Color.SS.textDisabled)
                            .frame(width: 32)
                        Text(emptyMessage)
                            .font(Font.SS.bodySmall)
                            .foregroundColor(Color.SS.textTertiary)
                            .lineSpacing(4)
                    }
                }
                .padding(.horizontal, Spacing.xl)
            } else {
                ForEach(Array(correlations.enumerated()), id: \.offset) { _, corr in
                    SSCard(padding: Spacing.md) {
                        HStack(spacing: Spacing.md) {
                            SSIconImage(name: corr.icon, size: 20)
                                .foregroundColor(Color(hex: corr.color))
                                .frame(width: 32)

                            VStack(alignment: .leading, spacing: 4) {
                                Text(corr.factor)
                                    .font(Font.SS.accentSmall)
                                    .foregroundColor(Color.SS.textPrimary)
                                Text(corr.finding)
                                    .font(Font.SS.bodySmall)
                                    .foregroundColor(Color.SS.textSecondary)
                                    .lineSpacing(4)
                            }
                        }
                    }
                    .padding(.horizontal, Spacing.xl)
                }
            }
        }
    }
}

// MARK: - Section Header
struct InsightsSectionHeader: View {
    let title: String
    var subtitle: String? = nil

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(Font.SS.headlineSmall)
                .foregroundColor(Color.SS.textPrimary)
            if let subtitle = subtitle {
                Text(subtitle)
                    .font(Font.SS.caption)
                    .foregroundColor(Color.SS.textTertiary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, Spacing.xl)
        .padding(.top, Spacing.lg)
        .padding(.bottom, Spacing.xs)
    }
}

// MARK: - ML Analysis Card
struct MLAnalysisCard: View {
    @ObservedObject var engine: SymptomAnalysisEngine
    @State private var showDetail = false

    var body: some View {
        SSCard(padding: Spacing.lg) {
            VStack(alignment: .leading, spacing: Spacing.md) {
                // Header
                HStack {
                    Text("ML Analysis")
                        .font(Font.SS.labelMedium)
                        .foregroundColor(Color.SS.textTertiary)
                        .tracking(0.5)
                    Spacer()
                    Text("AI-Powered")
                        .font(Font.SS.caption)
                        .foregroundColor(Color.SS.accent)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Capsule().fill(Color.SS.accentSubtle))
                }

                if !engine.isAnalyzed {
                    HStack {
                        Spacer()
                        ProgressView()
                            .tint(Color.SS.accent)
                        Text("Analyzing patterns...")
                            .font(Font.SS.bodySmall)
                            .foregroundColor(Color.SS.textTertiary)
                        Spacer()
                    }
                    .frame(height: 80)
                } else {
                    // Pattern Classification
                    HStack(spacing: Spacing.md) {
                        ZStack {
                            Circle()
                                .fill(engine.patternClassification.color.opacity(0.12))
                                .frame(width: 44, height: 44)
                            SSIconImage(name: engine.patternClassification.icon, size: 18)
                                .foregroundColor(engine.patternClassification.color)
                        }

                        VStack(alignment: .leading, spacing: 3) {
                            HStack(spacing: Spacing.xs) {
                                Text("Pattern")
                                    .font(Font.SS.caption)
                                    .foregroundColor(Color.SS.textTertiary)
                                Text(engine.patternClassification.rawValue)
                                    .font(Font.SS.accentSmall)
                                    .foregroundColor(engine.patternClassification.color)
                            }
                            Text(engine.patternClassification.description)
                                .font(Font.SS.caption)
                                .foregroundColor(Color.SS.textSecondary)
                                .lineSpacing(3)
                        }
                    }

                    SSDivider()

                    // Severity Trend
                    HStack(spacing: Spacing.md) {
                        Text("Severity Trend")
                            .font(Font.SS.caption)
                            .foregroundColor(Color.SS.textTertiary)
                        Spacer()
                        Text(engine.severityTrend.rawValue)
                            .font(Font.SS.labelMedium)
                            .foregroundColor(engine.severityTrend.color)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 3)
                            .background(
                                Capsule().fill(engine.severityTrend.color.opacity(0.1))
                            )
                    }

                    // Flare-up risk
                    HStack(spacing: Spacing.md) {
                        Text("Flare-Up Risk")
                            .font(Font.SS.caption)
                            .foregroundColor(Color.SS.textTertiary)
                        Spacer()
                        Text(engine.flareUpRisk.level.rawValue)
                            .font(Font.SS.labelMedium)
                            .foregroundColor(engine.flareUpRisk.level.color)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 3)
                            .background(
                                Capsule().fill(engine.flareUpRisk.level.color.opacity(0.1))
                            )
                    }

                    // Risk factors
                    if !engine.flareUpRisk.factors.isEmpty {
                        VStack(alignment: .leading, spacing: Spacing.xxs) {
                            ForEach(engine.flareUpRisk.factors.prefix(3), id: \.self) { factor in
                                HStack(spacing: Spacing.xs) {
                                    Circle()
                                        .fill(engine.flareUpRisk.level.color)
                                        .frame(width: 4, height: 4)
                                    Text(factor)
                                        .font(Font.SS.caption)
                                        .foregroundColor(Color.SS.textSecondary)
                                }
                            }
                        }
                    }

                    // Top trigger risks
                    if !engine.triggerRiskScores.isEmpty {
                        SSDivider()

                        VStack(alignment: .leading, spacing: Spacing.xs) {
                            Text("Top Trigger Risks")
                                .font(Font.SS.caption)
                                .foregroundColor(Color.SS.textTertiary)

                            ForEach(engine.triggerRiskScores.prefix(3)) { risk in
                                HStack {
                                    Text(risk.trigger)
                                        .font(Font.SS.bodySmall)
                                        .foregroundColor(Color.SS.textPrimary)
                                    Spacer()
                                    // Risk bar
                                    GeometryReader { geo in
                                        ZStack(alignment: .leading) {
                                            Capsule().fill(Color.SS.surfaceTertiary)
                                            Capsule()
                                                .fill(risk.riskScore > 0.6 ? Color.SS.error : risk.riskScore > 0.3 ? Color.SS.warning : Color.SS.accent)
                                                .frame(width: geo.size.width * risk.riskScore)
                                        }
                                    }
                                    .frame(width: 60, height: 4)

                                    Text("\(Int(risk.riskScore * 100))%")
                                        .font(Font.SS.caption)
                                        .foregroundColor(Color.SS.textTertiary)
                                        .monospacedDigit()
                                        .frame(width: 32, alignment: .trailing)
                                }
                            }
                        }
                    }

                    // Symptom clusters
                    if !engine.symptomClusters.isEmpty {
                        SSDivider()

                        VStack(alignment: .leading, spacing: Spacing.xs) {
                            Text("Co-occurring Clusters")
                                .font(Font.SS.caption)
                                .foregroundColor(Color.SS.textTertiary)

                            ForEach(engine.symptomClusters.prefix(3)) { cluster in
                                HStack(spacing: Spacing.xs) {
                                    Text(cluster.label)
                                        .font(Font.SS.bodySmall)
                                        .foregroundColor(Color.SS.textPrimary)
                                    Spacer()
                                    Text("\(Int(cluster.coOccurrenceRate * 100))% overlap")
                                        .font(Font.SS.caption)
                                        .foregroundColor(Color.SS.violet)
                                }
                            }
                        }
                    }

                    // Cyclical patterns
                    if !engine.cyclicalPatterns.isEmpty {
                        SSDivider()

                        VStack(alignment: .leading, spacing: Spacing.xs) {
                            Text("Cyclical Patterns")
                                .font(Font.SS.caption)
                                .foregroundColor(Color.SS.textTertiary)

                            ForEach(engine.cyclicalPatterns.prefix(2)) { pattern in
                                HStack {
                                    Text(pattern.symptomName)
                                        .font(Font.SS.bodySmall)
                                        .foregroundColor(Color.SS.textPrimary)
                                    Spacer()
                                    Text("~\(pattern.periodDays)d cycle")
                                        .font(Font.SS.caption)
                                        .foregroundColor(Color.SS.info)
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
