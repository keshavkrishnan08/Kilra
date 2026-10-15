import SwiftUI
import Combine

/// ML-powered analysis engine that classifies symptom patterns, identifies triggers,
/// predicts flare-ups, clusters co-occurring symptoms, and detects severity trends.
@MainActor
final class SymptomAnalysisEngine: ObservableObject {

    // MARK: - Published Results
    @Published var patternClassification: PatternClassification = .unknown
    @Published var triggerRiskScores: [TriggerRisk] = []
    @Published var severityTrend: SeverityTrend = .unknown
    @Published var symptomClusters: [SymptomCluster] = []
    @Published var flareUpRisk: FlareUpRisk = FlareUpRisk(probability: 0, level: .low, factors: [])
    @Published var cyclicalPatterns: [CyclicalPattern] = []
    @Published var isAnalyzed = false

    // MARK: - Pattern Classification
    enum PatternClassification: String {
        case chronic = "Chronic"
        case episodic = "Episodic"
        case cyclical = "Cyclical"
        case improving = "Improving"
        case worsening = "Worsening"
        case newOnset = "New Onset"
        case unknown = "Analyzing..."

        var icon: String {
            switch self {
            case .chronic: return "ss.clock"
            case .episodic: return "ss.sparkles"
            case .cyclical: return "ss.arrow.right"
            case .improving: return "ss.arrow.downright"
            case .worsening: return "ss.arrow.up"
            case .newOnset: return "ss.star"
            case .unknown: return "ss.ecg"
            }
        }

        var color: Color {
            switch self {
            case .chronic: return Color.SS.warning
            case .episodic: return Color.SS.violet
            case .cyclical: return Color.SS.info
            case .improving: return Color.SS.success
            case .worsening: return Color.SS.error
            case .newOnset: return Color.SS.accent
            case .unknown: return Color.SS.textTertiary
            }
        }

        var description: String {
            switch self {
            case .chronic: return "Symptoms appear consistently with little variation"
            case .episodic: return "Symptoms come in distinct episodes with gaps between"
            case .cyclical: return "A repeating pattern detected in your symptom timing"
            case .improving: return "Overall symptom severity is trending downward"
            case .worsening: return "Overall symptom severity is trending upward"
            case .newOnset: return "Not enough history yet to classify your pattern"
            case .unknown: return "Log more symptoms to unlock pattern analysis"
            }
        }
    }

    // MARK: - Severity Trend
    enum SeverityTrend: String {
        case improving = "Improving"
        case stable = "Stable"
        case worsening = "Worsening"
        case volatile = "Volatile"
        case unknown = "Unknown"

        var color: Color {
            switch self {
            case .improving: return Color.SS.success
            case .stable: return Color.SS.info
            case .worsening: return Color.SS.error
            case .volatile: return Color.SS.warning
            case .unknown: return Color.SS.textTertiary
            }
        }
    }

    // MARK: - Trigger Risk
    struct TriggerRisk: Identifiable {
        let id = UUID()
        let trigger: String
        let riskScore: Double          // 0-1 confidence
        let avgSeverityWith: Double
        let avgSeverityWithout: Double
        let occurrences: Int
        let bayesianProbability: Double // P(high_severity | trigger)
    }

    // MARK: - Symptom Cluster
    struct SymptomCluster: Identifiable {
        let id = UUID()
        let symptoms: [String]
        let coOccurrenceRate: Double   // 0-1
        let avgSeverity: Double
        let label: String              // auto-generated name
    }

    // MARK: - Flare-Up Risk
    struct FlareUpRisk {
        let probability: Double        // 0-1
        let level: RiskLevel
        let factors: [String]

        enum RiskLevel: String {
            case low = "Low"
            case moderate = "Moderate"
            case high = "High"
            case elevated = "Elevated"

            var color: Color {
                switch self {
                case .low: return Color.SS.success
                case .moderate: return Color.SS.warning
                case .high: return Color.SS.error
                case .elevated: return Color(hex: "F97316")
                }
            }
        }
    }

    // MARK: - Cyclical Pattern
    struct CyclicalPattern: Identifiable {
        let id = UUID()
        let symptomName: String
        let periodDays: Int
        let confidence: Double
        let nextExpectedDate: Date
    }

    // MARK: - Run Full Analysis
    func analyze(dataStore: DataStore, profile: OnboardingProfile? = nil) {
        let entries = dataStore.entries
        let summaries = dataStore.dailySummaries
        let todayHealth = dataStore.healthForDate(Date())

        guard entries.count >= 3 else {
            patternClassification = .unknown
            severityTrend = .unknown
            isAnalyzed = true
            return
        }

        // Run all analyses
        patternClassification = classifyPattern(entries: entries)
        severityTrend = analyzeSeverityTrend(entries: entries)
        triggerRiskScores = computeTriggerRisks(entries: entries)
        symptomClusters = clusterSymptoms(entries: entries)
        flareUpRisk = predictFlareUpRisk(entries: entries, summaries: summaries, profile: profile, healthSnapshot: todayHealth)
        cyclicalPatterns = detectCyclicalPatterns(entries: entries)
        isAnalyzed = true
    }

    // MARK: - 1. Pattern Classification (uses multiple heuristics)
    private func classifyPattern(entries: [SymptomEntry]) -> PatternClassification {
        let calendar = Calendar.current
        let sorted = entries.sorted { $0.timestamp < $1.timestamp }
        guard let first = sorted.first, let last = sorted.last else { return .unknown }

        let totalDays = max(1, calendar.dateComponents([.day], from: first.timestamp, to: last.timestamp).day ?? 1)

        // New onset: less than 14 days of history
        if totalDays < 14 { return .newOnset }

        // Calculate daily entry presence
        let uniqueDays = Set(sorted.map { calendar.startOfDay(for: $0.timestamp) })
        let coverageRate = Double(uniqueDays.count) / Double(totalDays)

        // Severity trend analysis (linear regression)
        let slope = linearRegressionSlope(entries: sorted)

        // Check for cyclical patterns
        let hasCycles = detectCyclicalPatterns(entries: entries).contains { $0.confidence > 0.6 }

        // Gap analysis: find gaps between symptom days
        let sortedDays = uniqueDays.sorted()
        var gaps: [Int] = []
        for i in 1..<sortedDays.count {
            let gap = calendar.dateComponents([.day], from: sortedDays[i-1], to: sortedDays[i]).day ?? 0
            gaps.append(gap)
        }
        let avgGap = gaps.isEmpty ? 0 : Double(gaps.reduce(0, +)) / Double(gaps.count)
        let maxGap = gaps.max() ?? 0

        // Classification logic
        if hasCycles {
            return .cyclical
        }

        // Strong trend?
        if slope < -0.03 && totalDays >= 14 {
            return .improving
        }
        if slope > 0.03 && totalDays >= 14 {
            return .worsening
        }

        // Chronic: high coverage, consistent presence
        if coverageRate > 0.6 && avgGap < 2.5 {
            return .chronic
        }

        // Episodic: clear gaps between episodes
        if maxGap >= 5 && avgGap >= 3 {
            return .episodic
        }

        // Default: check trend direction
        if slope < -0.01 { return .improving }
        if slope > 0.01 { return .worsening }

        return .chronic
    }

    // MARK: - 2. Severity Trend (linear regression + volatility)
    private func analyzeSeverityTrend(entries: [SymptomEntry]) -> SeverityTrend {
        guard entries.count >= 5 else { return .unknown }

        let sorted = entries.sorted { $0.timestamp < $1.timestamp }
        let slope = linearRegressionSlope(entries: sorted)

        // Check volatility: standard deviation of severities
        let severities = sorted.map { Double($0.severity) }
        let mean = severities.reduce(0, +) / Double(severities.count)
        let variance = severities.map { pow($0 - mean, 2) }.reduce(0, +) / Double(severities.count)
        let stdDev = sqrt(variance)

        if stdDev > 2.5 { return .volatile }
        if slope < -0.02 { return .improving }
        if slope > 0.02 { return .worsening }
        return .stable
    }

    // MARK: - 3. Trigger Risk (Bayesian inference)
    private func computeTriggerRisks(entries: [SymptomEntry]) -> [TriggerRisk] {
        let cutoff = Date().addingTimeInterval(-30 * 86400)
        let recent = entries.filter { $0.timestamp >= cutoff }
        guard recent.count >= 5 else { return [] }

        // Collect all triggers
        var triggerEntries: [String: [SymptomEntry]] = [:]
        var noTriggerEntries: [SymptomEntry] = []

        for entry in recent {
            if entry.triggers.isEmpty {
                noTriggerEntries.append(entry)
            } else {
                for trigger in entry.triggers {
                    triggerEntries[trigger, default: []].append(entry)
                }
            }
        }

        let overallAvgSeverity = Double(recent.map(\.severity).reduce(0, +)) / Double(recent.count)
        let highSeverityThreshold = max(6.0, overallAvgSeverity + 1.5)
        let totalHighSeverity = recent.filter { Double($0.severity) >= highSeverityThreshold }.count
        let pHighSeverity = max(0.01, Double(totalHighSeverity) / Double(recent.count))

        var risks: [TriggerRisk] = []

        for (trigger, entries) in triggerEntries {
            guard entries.count >= 2 else { continue }

            let avgWith = Double(entries.map(\.severity).reduce(0, +)) / Double(entries.count)
            let withoutEntries = recent.filter { !$0.triggers.contains(trigger) }
            let avgWithout = withoutEntries.isEmpty ? overallAvgSeverity :
                Double(withoutEntries.map(\.severity).reduce(0, +)) / Double(withoutEntries.count)

            // Bayesian: P(high_severity | trigger)
            let highWithTrigger = entries.filter { Double($0.severity) >= highSeverityThreshold }.count
            let pTriggerGivenHigh = totalHighSeverity > 0 ?
                Double(highWithTrigger) / Double(totalHighSeverity) : 0
            let pTrigger = Double(entries.count) / Double(recent.count)

            // Bayes' theorem: P(high | trigger) = P(trigger|high) * P(high) / P(trigger)
            let bayesian = pTrigger > 0 ?
                min(1.0, (pTriggerGivenHigh * pHighSeverity) / pTrigger) : 0

            // Risk score: combination of severity difference and Bayesian probability
            let severityDiff = max(0, avgWith - avgWithout)
            let riskScore = min(1.0, (severityDiff / 5.0) * 0.5 + bayesian * 0.5)

            if riskScore > 0.1 {
                risks.append(TriggerRisk(
                    trigger: trigger,
                    riskScore: riskScore,
                    avgSeverityWith: avgWith,
                    avgSeverityWithout: avgWithout,
                    occurrences: entries.count,
                    bayesianProbability: bayesian
                ))
            }
        }

        return risks.sorted { $0.riskScore > $1.riskScore }
    }

    // MARK: - 4. Symptom Clustering (co-occurrence matrix + agglomerative)
    private func clusterSymptoms(entries: [SymptomEntry]) -> [SymptomCluster] {
        let calendar = Calendar.current

        // Build per-day symptom sets
        var daySymptoms: [Date: Set<String>] = [:]
        for entry in entries {
            let day = calendar.startOfDay(for: entry.timestamp)
            daySymptoms[day, default: []].insert(entry.symptomName)
        }

        let uniqueSymptoms = Array(Set(entries.map(\.symptomName)))
        guard uniqueSymptoms.count >= 2 else { return [] }

        // Co-occurrence matrix: count how often each pair appears on the same day
        var coMatrix: [String: [String: Int]] = [:]
        var symptomDayCounts: [String: Int] = [:]

        for (_, symptoms) in daySymptoms {
            let symptomList = Array(symptoms)
            for s in symptomList {
                symptomDayCounts[s, default: 0] += 1
            }
            for i in 0..<symptomList.count {
                for j in (i+1)..<symptomList.count {
                    let a = symptomList[i]
                    let b = symptomList[j]
                    coMatrix[a, default: [:]][b, default: 0] += 1
                    coMatrix[b, default: [:]][a, default: 0] += 1
                }
            }
        }

        // Find clusters: pairs with high Jaccard similarity
        var clusters: [SymptomCluster] = []
        var used: Set<String> = []

        let pairs = coMatrix.flatMap { a, inner in
            inner.map { b, count in (a, b, count) }
        }.filter { $0.0 < $0.1 } // deduplicate
        .sorted { $0.2 > $1.2 }

        for (a, b, coCount) in pairs {
            guard !used.contains(a) || !used.contains(b) else { continue }
            let countA = symptomDayCounts[a] ?? 0
            let countB = symptomDayCounts[b] ?? 0
            guard countA > 0 && countB > 0 else { continue }

            // Jaccard similarity: intersection / union
            let union = countA + countB - coCount
            let jaccard = union > 0 ? Double(coCount) / Double(union) : 0

            guard jaccard >= 0.25 && coCount >= 2 else { continue }

            // Calculate average severity when they co-occur
            let coOccurDays = daySymptoms.filter { $0.value.contains(a) && $0.value.contains(b) }
            let coEntries = entries.filter { entry in
                let day = calendar.startOfDay(for: entry.timestamp)
                return coOccurDays.keys.contains(day) &&
                    (entry.symptomName == a || entry.symptomName == b)
            }
            let avgSev = coEntries.isEmpty ? 0 :
                Double(coEntries.map(\.severity).reduce(0, +)) / Double(coEntries.count)

            clusters.append(SymptomCluster(
                symptoms: [a, b],
                coOccurrenceRate: jaccard,
                avgSeverity: avgSev,
                label: "\(a) + \(b)"
            ))

            used.insert(a)
            used.insert(b)

            if clusters.count >= 4 { break }
        }

        return clusters
    }

    // MARK: - 5. Flare-Up Prediction
    private func predictFlareUpRisk(
        entries: [SymptomEntry],
        summaries: [DailySummary],
        profile: OnboardingProfile? = nil,
        healthSnapshot: HealthSnapshot? = nil
    ) -> FlareUpRisk {
        let calendar = Calendar.current
        let now = Date()
        guard entries.count >= 7 else {
            return FlareUpRisk(probability: 0, level: .low, factors: [])
        }

        var riskFactors: [String] = []
        var riskScore = 0.0

        // Factor 1: Recent severity spike (last 3 days vs 30-day baseline)
        let last3Days = entries.filter { $0.timestamp >= now.addingTimeInterval(-3 * 86400) }
        let baseline = entries.filter {
            $0.timestamp >= now.addingTimeInterval(-30 * 86400) &&
            $0.timestamp < now.addingTimeInterval(-3 * 86400)
        }
        if !last3Days.isEmpty && !baseline.isEmpty {
            let recentAvg = Double(last3Days.map(\.severity).reduce(0, +)) / Double(last3Days.count)
            let baselineAvg = Double(baseline.map(\.severity).reduce(0, +)) / Double(baseline.count)
            if recentAvg > baselineAvg + 1.5 {
                riskScore += 0.25
                riskFactors.append("Severity spiked \(String(format: "%.1f", recentAvg - baselineAvg)) points above baseline")
            }
        }

        // Factor 2: Increasing entry volume (more logging = more symptoms)
        let last3DayCount = last3Days.count
        let avgDailyBaseline = baseline.isEmpty ? 0 :
            Double(baseline.count) / 27.0
        if Double(last3DayCount) / 3.0 > avgDailyBaseline * 1.5 && avgDailyBaseline > 0 {
            riskScore += 0.2
            riskFactors.append("Logging \(String(format: "%.0f", (Double(last3DayCount) / 3.0 / avgDailyBaseline - 1) * 100))% more entries than usual")
        }

        // Factor 3: Poor mood/energy today
        let todaySummary = summaries.first { calendar.isDateInToday($0.date) }
        if let summary = todaySummary {
            if summary.overallMood <= 2 {
                riskScore += 0.15
                riskFactors.append("Low mood today")
            }
            if summary.overallEnergy <= 2 {
                riskScore += 0.1
                riskFactors.append("Low energy today")
            }
            if let stress = summary.stressLevel, stress >= 4 {
                riskScore += 0.15
                riskFactors.append("High stress level")
            }
        }

        // Factor 4: High-severity triggers present recently
        let recentTriggers = Set(last3Days.flatMap(\.triggers))
        let highRiskTriggers = triggerRiskScores.filter { $0.riskScore > 0.5 }
        for trigger in highRiskTriggers {
            if recentTriggers.contains(trigger.trigger) {
                riskScore += 0.15
                riskFactors.append("\"\(trigger.trigger)\" trigger is active")
                break
            }
        }

        // Factor 5: Multiple unique symptoms in last 2 days (diversity spike)
        let last2Days = entries.filter { $0.timestamp >= now.addingTimeInterval(-2 * 86400) }
        let recentUnique = Set(last2Days.map(\.symptomName)).count
        if recentUnique >= 3 {
            riskScore += 0.1
            riskFactors.append("\(recentUnique) different symptoms in the last 2 days")
        }

        // Factor 6: HealthKit: poor sleep and elevated HR increase flare risk
        if let health = healthSnapshot {
            if let sleep = health.sleepHours, sleep > 0, sleep < 5.5 {
                riskScore += 0.12
                riskFactors.append("Poor sleep last night (\(String(format: "%.1f", sleep))h)")
            }
            if let hr = health.heartRate, hr > 85 {
                riskScore += 0.08
                riskFactors.append("Elevated resting heart rate (\(Int(hr)) bpm)")
            }
            if let steps = health.stepCount, steps > 0, steps < 1500 {
                riskScore += 0.05
                riskFactors.append("Very low activity today")
            }
        }

        // Onboarding profile bias for flare-up risk
        riskScore += profile?.flareUpRiskBias() ?? 0.0

        let probability = min(1.0, riskScore)
        let level: FlareUpRisk.RiskLevel
        switch probability {
        case 0..<0.25: level = .low
        case 0.25..<0.5: level = .moderate
        case 0.5..<0.7: level = .elevated
        default: level = .high
        }

        return FlareUpRisk(
            probability: probability,
            level: level,
            factors: riskFactors
        )
    }

    // MARK: - 6. Cyclical Pattern Detection (autocorrelation)
    private func detectCyclicalPatterns(entries: [SymptomEntry]) -> [CyclicalPattern] {
        let calendar = Calendar.current
        guard entries.count >= 10 else { return [] }

        // Group entries by symptom
        var bySymptom: [String: [Date]] = [:]
        for entry in entries {
            let day = calendar.startOfDay(for: entry.timestamp)
            bySymptom[entry.symptomName, default: []].append(day)
        }

        var patterns: [CyclicalPattern] = []

        for (symptom, dates) in bySymptom {
            let uniqueDates = Array(Set(dates)).sorted()
            guard uniqueDates.count >= 4 else { continue }

            // Calculate intervals between occurrences
            var intervals: [Int] = []
            for i in 1..<uniqueDates.count {
                let gap = calendar.dateComponents([.day], from: uniqueDates[i-1], to: uniqueDates[i]).day ?? 0
                if gap > 0 { intervals.append(gap) }
            }

            guard intervals.count >= 3 else { continue }

            // Find the most common interval (with tolerance)
            // Test periods from 3 to 35 days
            var bestPeriod = 0
            var bestConfidence = 0.0

            for testPeriod in 3...35 {
                let tolerance = max(1, testPeriod / 5)
                var matches = 0
                for interval in intervals {
                    // Check if interval is a multiple of testPeriod (within tolerance)
                    let remainder = interval % testPeriod
                    let closest = min(remainder, testPeriod - remainder)
                    if closest <= tolerance {
                        matches += 1
                    }
                }
                let confidence = Double(matches) / Double(intervals.count)
                if confidence > bestConfidence {
                    bestConfidence = confidence
                    bestPeriod = testPeriod
                }
            }

            if bestConfidence >= 0.5 && bestPeriod > 0 {
                let lastDate = uniqueDates.last ?? Date()
                let nextExpected = calendar.date(byAdding: .day, value: bestPeriod, to: lastDate) ?? Date()

                patterns.append(CyclicalPattern(
                    symptomName: symptom,
                    periodDays: bestPeriod,
                    confidence: bestConfidence,
                    nextExpectedDate: nextExpected
                ))
            }
        }

        return patterns.sorted { $0.confidence > $1.confidence }
    }

    // MARK: - Linear Regression Helper
    private func linearRegressionSlope(entries: [SymptomEntry]) -> Double {
        guard entries.count >= 3 else { return 0 }

        let sorted = entries.sorted { $0.timestamp < $1.timestamp }
        let baseTime = sorted[0].timestamp.timeIntervalSince1970
        let n = Double(sorted.count)

        var sumX = 0.0, sumY = 0.0, sumXY = 0.0, sumX2 = 0.0
        for entry in sorted {
            let x = (entry.timestamp.timeIntervalSince1970 - baseTime) / 86400 // days since first
            let y = Double(entry.severity)
            sumX += x
            sumY += y
            sumXY += x * y
            sumX2 += x * x
        }

        let denominator = n * sumX2 - sumX * sumX
        guard denominator != 0 else { return 0 }

        return (n * sumXY - sumX * sumY) / denominator
    }
}
