import Foundation

/// Prediction engine that forecasts symptom severity and likelihood
/// based on historical patterns, triggers, temporal features, and lifestyle factors.
struct SymptomPredictionEngine {

    // MARK: - Severity Prediction

    struct SeverityPrediction {
        let symptomName: String
        let predictedSeverity: Double   // 1-10
        let confidence: Double          // 0-1
        let contributingFactors: [Factor]
    }

    struct Factor {
        let name: String
        let contribution: Double  // positive = increases severity, negative = decreases
        let weight: Double       // 0-1 importance
    }

    /// Predicts severity for a given symptom based on weighted feature analysis.
    /// Features: historical baseline, recent trend, day-of-week affinity, active triggers,
    /// mood/energy/sleep context, and seasonal/monthly pattern.
    static func predictSeverity(
        symptomName: String,
        entries: [SymptomEntry],
        summaries: [DailySummary],
        activeTriggers: [String] = [],
        targetDate: Date = Date(),
        profile: OnboardingProfile? = nil,
        healthSnapshot: HealthSnapshot? = nil
    ) -> SeverityPrediction? {
        let relevant = entries.filter { $0.symptomName == symptomName }
        guard relevant.count >= 3 else { return nil }

        let calendar = Calendar.current
        var factors: [Factor] = []
        var predicted = 0.0
        var totalWeight = 0.0

        // Feature 1: Historical baseline (weight: 0.25)
        // When data is sparse (<5 entries) and a profile exists, blend with onboarding baseline
        let baseWeight = 0.25
        let allSeverities = relevant.map { Double($0.severity) }
        var baseline = allSeverities.reduce(0, +) / Double(allSeverities.count)
        if relevant.count < 5, let profile = profile {
            let dataRatio = Double(relevant.count) / 5.0
            baseline = baseline * dataRatio + profile.severityBaseline * (1.0 - dataRatio)
        }
        predicted += baseline * baseWeight
        totalWeight += baseWeight
        factors.append(Factor(name: "Historical Average", contribution: baseline, weight: baseWeight))

        // Feature 2: Recent trend (last 7 days vs overall) (weight: 0.25)
        let trendWeight = 0.25
        let recentCutoff = targetDate.addingTimeInterval(-7 * 86400)
        let recentEntries = relevant.filter { $0.timestamp >= recentCutoff }
        if recentEntries.count >= 2 {
            let recentAvg = Double(recentEntries.map(\.severity).reduce(0, +)) / Double(recentEntries.count)
            predicted += recentAvg * trendWeight
            totalWeight += trendWeight
            let trendDiff = recentAvg - baseline
            factors.append(Factor(
                name: "Recent Trend",
                contribution: trendDiff,
                weight: trendWeight
            ))
        }

        // Feature 3: Day-of-week affinity (weight: 0.12)
        let dowWeight = 0.12
        let targetDOW = calendar.component(.weekday, from: targetDate)
        let sameDayEntries = relevant.filter { calendar.component(.weekday, from: $0.timestamp) == targetDOW }
        if sameDayEntries.count >= 2 {
            let dowAvg = Double(sameDayEntries.map(\.severity).reduce(0, +)) / Double(sameDayEntries.count)
            predicted += dowAvg * dowWeight
            totalWeight += dowWeight
            let dowDiff = dowAvg - baseline
            factors.append(Factor(
                name: "Day-of-Week Pattern",
                contribution: dowDiff,
                weight: dowWeight
            ))
        }

        // Feature 4: Trigger impact (weight: 0.13)
        let triggerWeight = 0.13
        if !activeTriggers.isEmpty {
            let withTrigger = relevant.filter { !Set($0.triggers).isDisjoint(with: activeTriggers) }
            let withoutTrigger = relevant.filter { Set($0.triggers).isDisjoint(with: activeTriggers) }
            if withTrigger.count >= 2 && withoutTrigger.count >= 1 {
                let trigAvg = Double(withTrigger.map(\.severity).reduce(0, +)) / Double(withTrigger.count)
                predicted += trigAvg * triggerWeight
                totalWeight += triggerWeight
                let trigDiff = trigAvg - baseline
                factors.append(Factor(
                    name: "Active Triggers",
                    contribution: trigDiff,
                    weight: triggerWeight
                ))
            }
        }

        // Feature 5: Mood/Energy context (weight: 0.13)
        let contextWeight = 0.13
        let todaySummary = summaries.first { calendar.isDate($0.date, inSameDayAs: targetDate) }
        if let summary = todaySummary {
            let moodFactor = summary.overallMood > 0 ? Double(6 - summary.overallMood) * 0.5 : 0
            let energyFactor = summary.overallEnergy > 0 ? Double(6 - summary.overallEnergy) * 0.3 : 0
            let contextAdj = baseline + moodFactor + energyFactor
            predicted += contextAdj * contextWeight
            totalWeight += contextWeight
            factors.append(Factor(
                name: "Mood/Energy",
                contribution: moodFactor + energyFactor,
                weight: contextWeight
            ))
        }

        // Feature 6: Seasonal/monthly pattern (weight: 0.12)
        // Captures monthly cyclical patterns (e.g., migraines worse in spring,
        // joint pain worse in winter). Compares same-month historical severity.
        let seasonWeight = 0.12
        let targetMonth = calendar.component(.month, from: targetDate)
        let sameMonthEntries = relevant.filter {
            calendar.component(.month, from: $0.timestamp) == targetMonth
        }
        if sameMonthEntries.count >= 3 {
            let monthAvg = Double(sameMonthEntries.map(\.severity).reduce(0, +)) / Double(sameMonthEntries.count)
            predicted += monthAvg * seasonWeight
            totalWeight += seasonWeight
            let seasonDiff = monthAvg - baseline
            factors.append(Factor(
                name: "Seasonal Pattern",
                contribution: seasonDiff,
                weight: seasonWeight
            ))
        }

        // Feature 7: HealthKit context — poor sleep/low activity predicts worse severity
        if let health = healthSnapshot {
            let healthWeight = 0.10
            var healthAdj = baseline

            // Poor sleep (< 5.5h) increases predicted severity
            if let sleep = health.sleepHours, sleep > 0 {
                if sleep < 5.5 {
                    healthAdj += (5.5 - sleep) * 0.6
                    factors.append(Factor(name: "Poor Sleep (\(String(format: "%.1f", sleep))h)", contribution: (5.5 - sleep) * 0.6, weight: healthWeight))
                } else if sleep >= 7 {
                    healthAdj -= min((sleep - 6) * 0.3, 1.0)
                    factors.append(Factor(name: "Good Sleep (\(String(format: "%.1f", sleep))h)", contribution: -min((sleep - 6) * 0.3, 1.0), weight: healthWeight))
                }
            }

            // Elevated resting heart rate suggests stress/inflammation
            if let hr = health.heartRate, hr > 0 {
                if hr > 85 {
                    healthAdj += (hr - 85) * 0.05
                    factors.append(Factor(name: "Elevated HR (\(Int(hr)) bpm)", contribution: (hr - 85) * 0.05, weight: healthWeight * 0.5))
                }
            }

            // Low activity days correlate with worse symptoms for some users
            if let steps = health.stepCount, steps > 0, steps < 2000 {
                healthAdj += 0.3
                factors.append(Factor(name: "Low Activity (\(steps) steps)", contribution: 0.3, weight: healthWeight * 0.5))
            }

            predicted += healthAdj * healthWeight
            totalWeight += healthWeight
        }

        // Normalize prediction
        let finalPrediction = totalWeight > 0 ? predicted / totalWeight : baseline
        let clamped = max(1, min(10, finalPrediction))

        // Confidence based on sample size and consistency
        let sampleConfidence = min(1.0, Double(relevant.count) / 20.0)
        if let stats = StatisticalAnalysis.describe(allSeverities) {
            let cvPenalty = min(0.5, stats.coefficientOfVariation * 0.5)
            let confidence = sampleConfidence * (1 - cvPenalty)

            return SeverityPrediction(
                symptomName: symptomName,
                predictedSeverity: clamped,
                confidence: confidence,
                contributingFactors: factors.sorted { abs($0.contribution) > abs($1.contribution) }
            )
        }

        return SeverityPrediction(
            symptomName: symptomName,
            predictedSeverity: clamped,
            confidence: sampleConfidence * 0.6,
            contributingFactors: factors
        )
    }

    // MARK: - Symptom Likelihood

    struct LikelihoodPrediction: Identifiable {
        let id = UUID()
        let symptomName: String
        let probability: Double     // 0-1
        let expectedSeverity: Double
        let reasoning: String
    }

    /// Predicts the probability of each tracked symptom occurring on the target date.
    /// Uses frequency, recency, day-of-week affinity, and recent trajectory.
    static func predictLikelihood(
        entries: [SymptomEntry],
        targetDate: Date = Date(),
        profile: OnboardingProfile? = nil
    ) -> [LikelihoodPrediction] {
        let calendar = Calendar.current
        guard !entries.isEmpty else { return [] }

        let uniqueSymptoms = Set(entries.map(\.symptomName))
        let totalDays = max(1, {
            let sorted = entries.sorted { $0.timestamp < $1.timestamp }
            guard let first = sorted.first, let last = sorted.last else { return 1 }
            return max(1, calendar.dateComponents([.day], from: first.timestamp, to: last.timestamp).day ?? 1)
        }())
        let targetDOW = calendar.component(.weekday, from: targetDate)

        var predictions: [LikelihoodPrediction] = []

        for symptom in uniqueSymptoms {
            let symptomEntries = entries.filter { $0.symptomName == symptom }
            guard symptomEntries.count >= 2 else { continue }

            var score = 0.0
            var reasonParts: [String] = []

            // Factor 1: Base frequency (occurrence rate)
            let uniqueDays = Set(symptomEntries.map { calendar.startOfDay(for: $0.timestamp) }).count
            let baseRate = Double(uniqueDays) / Double(totalDays)
            score += baseRate * 0.35
            if baseRate > 0.5 {
                reasonParts.append("appears on \(Int(baseRate * 100))% of days")
            }

            // Factor 2: Recency — more recent = higher likelihood
            let now = targetDate
            let sorted = symptomEntries.sorted { $0.timestamp > $1.timestamp }
            let daysSinceLast = calendar.dateComponents([.day], from: sorted[0].timestamp, to: now).day ?? 999
            let recencyScore: Double
            switch daysSinceLast {
            case 0...1: recencyScore = 1.0; reasonParts.append("active in last 24h")
            case 2...3: recencyScore = 0.75
            case 4...7: recencyScore = 0.5
            case 8...14: recencyScore = 0.25
            default: recencyScore = 0.1
            }
            score += recencyScore * 0.30

            // Factor 3: Day-of-week affinity
            let sameDOW = symptomEntries.filter { calendar.component(.weekday, from: $0.timestamp) == targetDOW }
            let dowRate = Double(sameDOW.count) / Double(symptomEntries.count)
            let expectedDowRate = 1.0 / 7.0
            let dowBoost = dowRate > expectedDowRate * 1.5 ? 0.15 : (dowRate < expectedDowRate * 0.5 ? -0.05 : 0)
            score += (dowRate * 0.20) + dowBoost
            if dowRate > expectedDowRate * 1.5 {
                let dayName = calendar.weekdaySymbols[targetDOW - 1]
                reasonParts.append("common on \(dayName)s")
            }

            // Factor 4: Recent trajectory (increasing or decreasing frequency)
            let last7 = symptomEntries.filter { $0.timestamp >= now.addingTimeInterval(-7 * 86400) }.count
            let prev7 = symptomEntries.filter {
                $0.timestamp >= now.addingTimeInterval(-14 * 86400) &&
                $0.timestamp < now.addingTimeInterval(-7 * 86400)
            }.count
            if last7 > prev7 + 1 {
                score += 0.10
                reasonParts.append("trending up this week")
            } else if last7 < prev7 - 1 {
                score -= 0.05
            } else {
                score += 0.05
            }

            let probability = max(0, min(1, score))

            // Expected severity from recent entries
            let recentSev = sorted.prefix(5).map { Double($0.severity) }
            let expectedSev = recentSev.isEmpty ? 5.0 : recentSev.reduce(0, +) / Double(recentSev.count)

            let reasoning = reasonParts.isEmpty ? "Based on historical frequency" : reasonParts.joined(separator: ", ")

            predictions.append(LikelihoodPrediction(
                symptomName: symptom,
                probability: probability,
                expectedSeverity: expectedSev,
                reasoning: reasoning.prefix(1).uppercased() + reasoning.dropFirst()
            ))
        }

        return predictions.sorted { $0.probability > $1.probability }
    }

    // MARK: - Multi-Day Forecast

    struct DayForecast: Identifiable {
        let id = UUID()
        let date: Date
        let symptomForecasts: [SymptomForecast]
        let overallRisk: Double  // 0-1 composite risk for the day
    }

    struct SymptomForecast: Identifiable {
        let id = UUID()
        let symptomName: String
        let predictedSeverity: Double
        let probability: Double
    }

    /// Forecasts symptom activity for the next `days` days.
    /// Uses batch likelihood computation per day to avoid redundant O(n²) work.
    static func forecast(
        entries: [SymptomEntry],
        summaries: [DailySummary],
        days: Int = 7
    ) -> [DayForecast] {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let uniqueSymptoms = Array(Set(entries.map(\.symptomName)))

        var forecasts: [DayForecast] = []

        for offset in 1...days {
            guard let targetDate = calendar.date(byAdding: .day, value: offset, to: today) else { continue }

            // Compute likelihood once per target date (not per symptom)
            let likelihoodMap: [String: Double]
            let likelihoods = predictLikelihood(entries: entries, targetDate: targetDate)
            likelihoodMap = Dictionary(
                likelihoods.map { ($0.symptomName, $0.probability) },
                uniquingKeysWith: { first, _ in first }
            )

            var symptomForecasts: [SymptomForecast] = []

            for symptom in uniqueSymptoms {
                if let prediction = predictSeverity(
                    symptomName: symptom,
                    entries: entries,
                    summaries: summaries,
                    targetDate: targetDate
                ) {
                    let prob = likelihoodMap[symptom] ?? 0.3

                    symptomForecasts.append(SymptomForecast(
                        symptomName: symptom,
                        predictedSeverity: prediction.predictedSeverity,
                        probability: prob
                    ))
                }
            }

            // Overall risk: weighted average of (probability * severity) for top symptoms
            let riskScores = symptomForecasts.map { $0.probability * ($0.predictedSeverity / 10.0) }
            let overallRisk = riskScores.isEmpty ? 0 : min(1.0, riskScores.reduce(0, +) / max(1, Double(riskScores.count)) * 2)

            forecasts.append(DayForecast(
                date: targetDate,
                symptomForecasts: symptomForecasts.sorted { $0.probability > $1.probability },
                overallRisk: overallRisk
            ))
        }

        return forecasts
    }
}
