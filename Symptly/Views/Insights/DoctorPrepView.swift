import SwiftUI

struct DoctorPrepView: View {
    @EnvironmentObject var dataStore: DataStore
    @Environment(\.dismiss) private var dismiss

    @State private var dayRange: Int = 30
    @State private var showDatePicker = false
    @State private var customStartDate = Calendar.current.date(byAdding: .day, value: -30, to: Date()) ?? Date()
    @State private var useCustomRange = false
    @State private var showShareSheet = false
    @State private var showCopiedToast = false

    // MARK: - Computed Data

    private var startDate: Date {
        useCustomRange
            ? customStartDate
            : Calendar.current.date(byAdding: .day, value: -dayRange, to: Date()) ?? Date()
    }

    private var filteredEntries: [SymptomEntry] {
        dataStore.entries.filter { $0.timestamp >= startDate && $0.timestamp <= Date() }
    }

    private var totalEntries: Int { filteredEntries.count }

    private var mostFrequentSymptom: (name: String, count: Int)? {
        let grouped = Dictionary(grouping: filteredEntries, by: \.symptomName)
        guard let top = grouped.max(by: { $0.value.count < $1.value.count }) else { return nil }
        return (top.key, top.value.count)
    }

    private var averageSeverity: Double {
        guard !filteredEntries.isEmpty else { return 0 }
        return Double(filteredEntries.map(\.severity).reduce(0, +)) / Double(filteredEntries.count)
    }

    private var worstDay: (date: Date, severity: Double)? {
        let calendar = Calendar.current
        let grouped = Dictionary(grouping: filteredEntries) { entry in
            calendar.startOfDay(for: entry.timestamp)
        }
        guard let worst = grouped.max(by: {
            let avg1 = Double($0.value.map(\.severity).reduce(0, +)) / Double($0.value.count)
            let avg2 = Double($1.value.map(\.severity).reduce(0, +)) / Double($1.value.count)
            return avg1 < avg2
        }) else { return nil }
        let avg = Double(worst.value.map(\.severity).reduce(0, +)) / Double(worst.value.count)
        return (worst.key, avg)
    }

    private var medicationComplianceRate: Double {
        let calendar = Calendar.current
        let activeMeds = dataStore.medications.filter { $0.isActive && $0.frequency != .asNeeded }
        guard !activeMeds.isEmpty else { return -1 } // -1 means no trackable meds

        let expectedDoses = activeMeds.reduce(0) { total, med in
            let medStartClamped = max(med.startDate, startDate)
            let medDays = max(1, calendar.dateComponents([.day], from: medStartClamped, to: Date()).day ?? 1)
            let multiplier: Int
            switch med.frequency {
            case .daily: multiplier = 1
            case .twiceDaily: multiplier = 2
            case .weekly: multiplier = max(1, medDays / 7)
            case .asNeeded: multiplier = 0
            case .other: multiplier = 1
            }
            return total + medDays * multiplier
        }
        guard expectedDoses > 0 else { return -1 }

        let takenLogs = dataStore.medicationLogs.filter { log in
            log.timestamp >= startDate && log.timestamp <= Date() && log.taken
        }
        return min(1.0, Double(takenLogs.count) / Double(expectedDoses))
    }

    private var rankedSymptoms: [(name: String, count: Int, trend: SymptomTrend)] {
        let grouped = Dictionary(grouping: filteredEntries, by: \.symptomName)
        let midpoint = startDate.addingTimeInterval(Date().timeIntervalSince(startDate) / 2)

        return grouped.map { name, entries in
            let firstHalf = entries.filter { $0.timestamp < midpoint }
            let secondHalf = entries.filter { $0.timestamp >= midpoint }
            let avgFirst = firstHalf.isEmpty ? 0 : Double(firstHalf.map(\.severity).reduce(0, +)) / Double(firstHalf.count)
            let avgSecond = secondHalf.isEmpty ? 0 : Double(secondHalf.map(\.severity).reduce(0, +)) / Double(secondHalf.count)
            let diff = avgSecond - avgFirst
            let trend: SymptomTrend
            if abs(diff) < 0.5 { trend = .stable }
            else if diff > 0 { trend = .worsening }
            else { trend = .improving }
            return (name, entries.count, trend)
        }
        .sorted { $0.count > $1.count }
    }

    private var topTriggers: [(trigger: String, impact: Double, count: Int)] {
        let allTriggers = Set(filteredEntries.flatMap(\.triggers))
        var results: [(trigger: String, impact: Double, count: Int)] = []

        for trigger in allTriggers {
            let withTrigger = filteredEntries.filter { $0.triggers.contains(trigger) }
            let withoutTrigger = filteredEntries.filter { !$0.triggers.contains(trigger) }
            guard withTrigger.count >= 2, withoutTrigger.count >= 2 else { continue }

            let avgWith = Double(withTrigger.map(\.severity).reduce(0, +)) / Double(withTrigger.count)
            let avgWithout = Double(withoutTrigger.map(\.severity).reduce(0, +)) / Double(withoutTrigger.count)
            let impact = avgWith - avgWithout
            if impact > 0 {
                results.append((trigger, impact, withTrigger.count))
            }
        }

        return results.sorted { $0.impact > $1.impact }.prefix(3).map { $0 }
    }

    private var suggestedQuestions: [String] {
        var questions: [String] = []

        // Worsening symptoms
        for symptom in rankedSymptoms where symptom.trend == .worsening {
            questions.append("My \(symptom.name.lowercased()) has been getting worse over the past \(dayRange) days -- should we adjust treatment?")
            break
        }

        // Strong triggers
        if let top = topTriggers.first, top.impact >= 1.0 {
            questions.append("\(top.trigger) seems to make my symptoms significantly worse (about +\(String(format: "%.1f", top.impact)) severity). Are there preventive measures?")
        }

        // Sleep correlation
        let sleepCorrelations = dataStore.lifestyleCorrelations(days: dayRange)
        if sleepCorrelations.contains(where: { $0.factor == "Sleep" }) {
            questions.append("I've noticed poor sleep worsens my symptoms. Any recommendations for improving sleep quality?")
        }

        // Medication compliance
        if medicationComplianceRate >= 0 && medicationComplianceRate < 0.8 {
            questions.append("I've been having trouble with medication adherence (\(Int(medicationComplianceRate * 100))% compliance). Can we simplify my regimen?")
        }

        // Always include this one
        questions.append("Are there any new treatments or approaches for my conditions that I should know about?")

        return questions
    }

    // MARK: - Body

    var body: some View {
        ZStack {
            Color.SS.background.ignoresSafeArea()

            VStack(spacing: 0) {
                SSNavigationBar(
                    title: "Visit Prep",
                    subtitle: "For your doctor",
                    leadingIcon: "ss.chevron.left",
                    leadingAction: { dismiss() }
                )

                ScrollView(showsIndicators: false) {
                    VStack(spacing: Spacing.xl) {
                        dateRangeSection
                        keyNumbersSection
                        rankedSymptomsSection
                        triggerHighlightsSection
                        questionsSection
                        shareSection
                        Spacer(minLength: 120)
                    }
                }
            }

            // Copied toast
            if showCopiedToast {
                VStack {
                    Spacer()
                    SSToast(message: "Summary copied to clipboard")
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                        .padding(.bottom, Spacing.hero)
                }
                .animation(.spring(response: 0.4), value: showCopiedToast)
            }
        }
        .navigationBarHidden(true)
        #if canImport(UIKit)
        .sheet(isPresented: $showShareSheet) {
            ShareSheet(items: [generateTextSummary()])
        }
        #endif
    }

    // MARK: - Date Range Selector

    private var dateRangeSection: some View {
        SSCard(padding: Spacing.md) {
            VStack(alignment: .leading, spacing: Spacing.sm) {
                HStack {
                    Image(systemName: "calendar")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(Color.SS.accent)
                    Text("Date Range")
                        .font(Font.SS.labelMedium)
                        .foregroundColor(Color.SS.textTertiary)
                        .tracking(0.5)
                }

                if !useCustomRange {
                    HStack(spacing: Spacing.xs) {
                        ForEach([7, 14, 30, 90, 180], id: \.self) { days in
                            Button {
                                SSHaptics.selection()
                                dayRange = days
                            } label: {
                                Text("\(days)d")
                                    .font(Font.SS.labelMedium)
                                    .foregroundColor(dayRange == days ? .white : Color.SS.textSecondary)
                                    .padding(.horizontal, Spacing.sm)
                                    .padding(.vertical, Spacing.xxs + 3)
                                    .background(
                                        Capsule()
                                            .fill(dayRange == days ? Color.SS.accent : Color.SS.surfaceSecondary)
                                    )
                            }
                            .buttonStyle(PlainButtonStyle())
                        }

                        Spacer()

                        Button {
                            SSHaptics.selection()
                            withAnimation(.easeOut(duration: 0.2)) { useCustomRange = true }
                        } label: {
                            Image(systemName: "slider.horizontal.3")
                                .font(.system(size: 13))
                                .foregroundColor(Color.SS.textTertiary)
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                } else {
                    VStack(spacing: Spacing.xs) {
                        DatePicker("From", selection: $customStartDate, in: ...Date(), displayedComponents: .date)
                            .font(Font.SS.bodySmall)
                            .foregroundColor(Color.SS.textSecondary)
                            .tint(Color.SS.accent)

                        HStack {
                            Spacer()
                            Button("Use preset") {
                                SSHaptics.selection()
                                withAnimation(.easeOut(duration: 0.2)) { useCustomRange = false }
                            }
                            .font(Font.SS.labelSmall)
                            .foregroundColor(Color.SS.accent)
                            .buttonStyle(PlainButtonStyle())
                        }
                    }
                }
            }
        }
        .padding(.horizontal, Spacing.xl)
    }

    // MARK: - Key Numbers

    private var keyNumbersSection: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            Text("Key Numbers")
                .font(Font.SS.headlineSmall)
                .foregroundColor(Color.SS.textPrimary)
                .padding(.horizontal, Spacing.xl)

            if totalEntries == 0 {
                SSCard(padding: Spacing.lg) {
                    HStack {
                        Image(systemName: "chart.bar.xaxis")
                            .foregroundColor(Color.SS.textDisabled)
                        Text("No entries in this period")
                            .font(Font.SS.bodySmall)
                            .foregroundColor(Color.SS.textTertiary)
                    }
                }
                .padding(.horizontal, Spacing.xl)
            } else {
                LazyVGrid(columns: [
                    GridItem(.flexible(), spacing: Spacing.sm),
                    GridItem(.flexible(), spacing: Spacing.sm)
                ], spacing: Spacing.sm) {
                    StatCard(
                        label: "Total Entries",
                        value: "\(totalEntries)",
                        icon: "list.bullet",
                        color: Color.SS.accent
                    )
                    StatCard(
                        label: "Most Frequent",
                        value: mostFrequentSymptom?.name ?? "--",
                        detail: mostFrequentSymptom != nil ? "\(mostFrequentSymptom!.count)x" : nil,
                        icon: "arrow.up.right",
                        color: Color.SS.violet
                    )
                    StatCard(
                        label: "Avg Severity",
                        value: String(format: "%.1f", averageSeverity),
                        detail: "/ 10",
                        icon: "gauge.medium",
                        color: severityColor(for: averageSeverity)
                    )
                    if let worst = worstDay {
                        StatCard(
                            label: "Worst Day",
                            value: shortDate(worst.date),
                            detail: String(format: "%.1f avg", worst.severity),
                            icon: "exclamationmark.triangle",
                            color: Color.SS.error
                        )
                    }
                }
                .padding(.horizontal, Spacing.xl)

                if medicationComplianceRate >= 0 {
                    SSCard(padding: Spacing.md) {
                        HStack(spacing: Spacing.md) {
                            SSProgressRing(
                                progress: medicationComplianceRate,
                                lineWidth: 3,
                                size: 44,
                                color: complianceColor
                            )

                            VStack(alignment: .leading, spacing: 2) {
                                Text("Medication Compliance")
                                    .font(Font.SS.labelMedium)
                                    .foregroundColor(Color.SS.textTertiary)
                                Text("\(Int(medicationComplianceRate * 100))%")
                                    .font(Font.SS.dataMedium)
                                    .foregroundColor(Color.SS.textPrimary)
                            }

                            Spacer()

                            SSChip(
                                label: complianceLabel,
                                color: complianceColor
                            )
                        }
                    }
                    .padding(.horizontal, Spacing.xl)
                }
            }
        }
    }

    // MARK: - Ranked Symptoms

    private var rankedSymptomsSection: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            Text("Top Symptoms")
                .font(Font.SS.headlineSmall)
                .foregroundColor(Color.SS.textPrimary)
                .padding(.horizontal, Spacing.xl)

            if rankedSymptoms.isEmpty {
                SSCard(padding: Spacing.lg) {
                    Text("No symptoms logged in this period.")
                        .font(Font.SS.bodySmall)
                        .foregroundColor(Color.SS.textTertiary)
                }
                .padding(.horizontal, Spacing.xl)
            } else {
                SSCard(padding: Spacing.sm) {
                    VStack(spacing: 0) {
                        ForEach(Array(rankedSymptoms.enumerated()), id: \.element.name) { index, symptom in
                            if index > 0 {
                                SSDivider()
                                    .padding(.horizontal, Spacing.xs)
                            }

                            HStack(spacing: Spacing.md) {
                                Text("#\(index + 1)")
                                    .font(Font.SS.labelMedium)
                                    .foregroundColor(Color.SS.textDisabled)
                                    .frame(width: 28)

                                let symColor = symptomColor(symptom.name)
                                Circle()
                                    .fill(symColor.opacity(0.15))
                                    .frame(width: 32, height: 32)
                                    .overlay(
                                        Image(systemName: "circle.fill")
                                            .font(.system(size: 8))
                                            .foregroundColor(symColor)
                                    )

                                VStack(alignment: .leading, spacing: 2) {
                                    Text(symptom.name)
                                        .font(Font.SS.bodyMedium)
                                        .foregroundColor(Color.SS.textPrimary)
                                    Text("\(symptom.count) entries")
                                        .font(Font.SS.caption)
                                        .foregroundColor(Color.SS.textTertiary)
                                }

                                Spacer()

                                trendBadge(symptom.trend)
                            }
                            .padding(.horizontal, Spacing.sm)
                            .padding(.vertical, Spacing.sm)
                        }
                    }
                }
                .padding(.horizontal, Spacing.xl)
            }
        }
    }

    // MARK: - Trigger Highlights

    private var triggerHighlightsSection: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            Text("Trigger Highlights")
                .font(Font.SS.headlineSmall)
                .foregroundColor(Color.SS.textPrimary)
                .padding(.horizontal, Spacing.xl)

            if topTriggers.isEmpty {
                SSCard(padding: Spacing.lg) {
                    HStack(spacing: Spacing.sm) {
                        Image(systemName: "bolt.slash")
                            .foregroundColor(Color.SS.textDisabled)
                        Text("Not enough trigger data yet. Keep logging!")
                            .font(Font.SS.bodySmall)
                            .foregroundColor(Color.SS.textTertiary)
                    }
                }
                .padding(.horizontal, Spacing.xl)
            } else {
                ForEach(Array(topTriggers.enumerated()), id: \.element.trigger) { _, trigger in
                    SSAccentCard(accentColor: Color.SS.warning) {
                        HStack(spacing: Spacing.md) {
                            ZStack {
                                Circle()
                                    .fill(Color.SS.warning.opacity(0.12))
                                    .frame(width: 36, height: 36)
                                Image(systemName: "bolt.fill")
                                    .font(.system(size: 14))
                                    .foregroundColor(Color.SS.warning)
                            }

                            VStack(alignment: .leading, spacing: 2) {
                                Text(trigger.trigger)
                                    .font(Font.SS.accentSmall)
                                    .foregroundColor(Color.SS.textPrimary)
                                Text("\(trigger.count) occurrences")
                                    .font(Font.SS.caption)
                                    .foregroundColor(Color.SS.textTertiary)
                            }

                            Spacer()

                            VStack(alignment: .trailing, spacing: 2) {
                                Text("+\(String(format: "%.1f", trigger.impact))")
                                    .font(Font.SS.dataMedium)
                                    .foregroundColor(Color.SS.warning)
                                Text("severity")
                                    .font(Font.SS.caption)
                                    .foregroundColor(Color.SS.textTertiary)
                            }
                        }
                    }
                    .padding(.horizontal, Spacing.xl)
                }
            }
        }
    }

    // MARK: - Questions to Ask

    private var questionsSection: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            HStack {
                Text("Questions for Your Doctor")
                    .font(Font.SS.headlineSmall)
                    .foregroundColor(Color.SS.textPrimary)
                Spacer()
                SSChip(label: "\(suggestedQuestions.count)", color: Color.SS.accent)
            }
            .padding(.horizontal, Spacing.xl)

            VStack(spacing: Spacing.sm) {
                ForEach(Array(suggestedQuestions.enumerated()), id: \.offset) { _, question in
                    SSCard(padding: Spacing.md) {
                        HStack(alignment: .top, spacing: Spacing.sm) {
                            Image(systemName: "questionmark.circle.fill")
                                .font(.system(size: 16))
                                .foregroundColor(Color.SS.info)
                                .padding(.top, 1)

                            Text(question)
                                .font(Font.SS.bodySmall)
                                .foregroundColor(Color.SS.textSecondary)
                                .lineSpacing(4)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }
                }
            }
            .padding(.horizontal, Spacing.xl)
        }
    }

    // MARK: - Share

    private var shareSection: some View {
        VStack(spacing: Spacing.sm) {
            SSButton(title: "Share Summary", style: .primary) {
                SSHaptics.light()
                showShareSheet = true
            }

            SSButton(title: "Copy to Clipboard", style: .secondary) {
                #if canImport(UIKit)
                UIPasteboard.general.string = generateTextSummary()
                #endif
                SSHaptics.success()
                withAnimation { showCopiedToast = true }
                DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                    withAnimation { showCopiedToast = false }
                }
            }

            Text("Plain text summary for your healthcare provider")
                .font(Font.SS.caption)
                .foregroundColor(Color.SS.textDisabled)
        }
        .padding(.horizontal, Spacing.xl)
    }

    // MARK: - Helpers

    private func severityColor(for value: Double) -> Color {
        switch value {
        case 0..<3: return Color.SS.severityNone
        case 3..<5: return Color.SS.severityMild
        case 5..<7: return Color.SS.severityModerate
        case 7..<9: return Color.SS.severitySevere
        default: return Color.SS.severityCritical
        }
    }

    private func symptomColor(_ name: String) -> Color {
        Symptom.library.first(where: { $0.name == name })
            .map { Color(hex: $0.color) } ?? Color.SS.accent
    }

    private var complianceColor: Color {
        switch medicationComplianceRate {
        case 0.8...1.0: return Color.SS.success
        case 0.5..<0.8: return Color.SS.warning
        default: return Color.SS.error
        }
    }

    private var complianceLabel: String {
        switch medicationComplianceRate {
        case 0.8...1.0: return "Good"
        case 0.5..<0.8: return "Fair"
        default: return "Low"
        }
    }

    @ViewBuilder
    private func trendBadge(_ trend: SymptomTrend) -> some View {
        HStack(spacing: 3) {
            Image(systemName: trend.icon)
                .font(.system(size: 10, weight: .bold))
            Text(trend.label)
                .font(Font.SS.labelSmall)
        }
        .foregroundColor(trend.color)
        .padding(.horizontal, Spacing.xs)
        .padding(.vertical, Spacing.xxs)
        .background(
            Capsule().fill(trend.color.opacity(0.10))
        )
    }

    private func shortDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
        return formatter.string(from: date)
    }

    // MARK: - Text Summary Generator

    private func generateTextSummary() -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .medium

        var lines: [String] = []
        lines.append("SYMPTOM SUMMARY")
        lines.append("Period: \(dateFormatter.string(from: startDate)) - \(dateFormatter.string(from: Date()))")
        lines.append("Generated by Symptly")
        lines.append("")

        // Key numbers
        lines.append("--- KEY NUMBERS ---")
        lines.append("Total entries: \(totalEntries)")
        if let top = mostFrequentSymptom {
            lines.append("Most frequent: \(top.name) (\(top.count) times)")
        }
        lines.append("Average severity: \(String(format: "%.1f", averageSeverity)) / 10")
        if let worst = worstDay {
            lines.append("Worst day: \(dateFormatter.string(from: worst.date)) (avg \(String(format: "%.1f", worst.severity)))")
        }
        if medicationComplianceRate >= 0 {
            lines.append("Medication compliance: \(Int(medicationComplianceRate * 100))%")
        }
        lines.append("")

        // HealthKit averages
        let healthSnaps = dataStore.healthSnapshots.filter { $0.date >= startDate && $0.date <= Date() }
        if !healthSnaps.isEmpty {
            lines.append("--- HEALTH DATA (Apple Health) ---")
            let sleepSnaps = healthSnaps.compactMap(\.sleepHours).filter { $0 > 0 }
            if !sleepSnaps.isEmpty {
                let avgSleep = sleepSnaps.reduce(0, +) / Double(sleepSnaps.count)
                lines.append("Average sleep: \(String(format: "%.1f", avgSleep)) hours (\(sleepSnaps.count) days)")
            }
            let stepSnaps = healthSnaps.compactMap(\.stepCount).filter { $0 > 0 }
            if !stepSnaps.isEmpty {
                let avgSteps = stepSnaps.reduce(0, +) / stepSnaps.count
                lines.append("Average daily steps: \(avgSteps)")
            }
            let exSnaps = healthSnaps.compactMap(\.activeMinutes).filter { $0 > 0 }
            if !exSnaps.isEmpty {
                let avgEx = exSnaps.reduce(0, +) / exSnaps.count
                lines.append("Average exercise: \(avgEx) min/day")
            }
            let hrSnaps = healthSnaps.compactMap(\.heartRate).filter { $0 > 0 }
            if !hrSnaps.isEmpty {
                let avgHR = Int(hrSnaps.reduce(0, +) / Double(hrSnaps.count))
                lines.append("Average resting heart rate: \(avgHR) bpm")
            }
            lines.append("")
        }

        // Daily check-in averages (stress, water)
        let periodSummaries = dataStore.dailySummaries.filter { $0.date >= startDate && $0.date <= Date() }
        if !periodSummaries.isEmpty {
            let stressData = periodSummaries.compactMap(\.stressLevel).filter { $0 > 0 }
            let waterData = periodSummaries.compactMap(\.waterIntake).filter { $0 > 0 }
            if !stressData.isEmpty || !waterData.isEmpty {
                lines.append("--- LIFESTYLE CHECK-INS ---")
                if !stressData.isEmpty {
                    let avgStress = Double(stressData.reduce(0, +)) / Double(stressData.count)
                    let stressLabel = avgStress >= 4 ? "High" : avgStress >= 3 ? "Moderate" : "Low"
                    lines.append("Average stress: \(String(format: "%.1f", avgStress))/5 (\(stressLabel), \(stressData.count) check-ins)")
                }
                if !waterData.isEmpty {
                    let avgWater = Double(waterData.reduce(0, +)) / Double(waterData.count)
                    lines.append("Average water intake: \(String(format: "%.1f", avgWater)) glasses/day (\(waterData.count) check-ins)")
                }
                lines.append("")
            }
        }

        // Ranked symptoms
        if !rankedSymptoms.isEmpty {
            lines.append("--- SYMPTOMS (by frequency) ---")
            for (i, s) in rankedSymptoms.enumerated() {
                let arrow = s.trend == .worsening ? "WORSENING" : s.trend == .improving ? "IMPROVING" : "STABLE"
                lines.append("\(i + 1). \(s.name) - \(s.count) entries [\(arrow)]")
            }
            lines.append("")
        }

        // Triggers
        if !topTriggers.isEmpty {
            lines.append("--- TOP TRIGGERS ---")
            for t in topTriggers {
                lines.append("- \(t.trigger): +\(String(format: "%.1f", t.impact)) severity impact (\(t.count) occurrences)")
            }
            lines.append("")
        }

        // Questions
        lines.append("--- SUGGESTED QUESTIONS ---")
        for (i, q) in suggestedQuestions.enumerated() {
            lines.append("\(i + 1). \(q)")
        }

        return lines.joined(separator: "\n")
    }
}

// MARK: - Supporting Types

private enum SymptomTrend {
    case improving, stable, worsening

    var icon: String {
        switch self {
        case .improving: return "arrow.down.right"
        case .stable: return "arrow.right"
        case .worsening: return "arrow.up.right"
        }
    }

    var label: String {
        switch self {
        case .improving: return "Improving"
        case .stable: return "Stable"
        case .worsening: return "Worsening"
        }
    }

    var color: Color {
        switch self {
        case .improving: return Color.SS.success
        case .stable: return Color.SS.info
        case .worsening: return Color.SS.error
        }
    }
}

// MARK: - Stat Card

private struct StatCard: View {
    let label: String
    let value: String
    var detail: String? = nil
    let icon: String
    let color: Color

    var body: some View {
        SSCard(padding: Spacing.md) {
            VStack(alignment: .leading, spacing: Spacing.xs) {
                HStack {
                    Image(systemName: icon)
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(color)
                    Spacer()
                }

                Text(label)
                    .font(Font.SS.caption)
                    .foregroundColor(Color.SS.textTertiary)

                HStack(alignment: .firstTextBaseline, spacing: 3) {
                    Text(value)
                        .font(Font.SS.dataMedium)
                        .foregroundColor(Color.SS.textPrimary)
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)
                    if let detail = detail {
                        Text(detail)
                            .font(Font.SS.caption)
                            .foregroundColor(Color.SS.textTertiary)
                    }
                }
            }
        }
    }
}
