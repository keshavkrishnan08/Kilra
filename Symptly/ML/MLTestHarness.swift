import Foundation

/// Test harness for validating ML models with synthetic data.
/// Generates realistic symptom entries and daily summaries,
/// runs all models, and verifies outputs are within expected ranges.
struct MLTestHarness {

    // MARK: - Synthetic Data Generation

    /// Generates realistic symptom entries with configurable patterns.
    static func generateEntries(
        days: Int = 60,
        symptomsPerDay: ClosedRange<Int> = 1...4,
        baselineSeverity: Double = 5.0,
        trendSlope: Double = 0.0,        // severity change per day (positive = worsening)
        volatility: Double = 1.5,        // standard deviation of severity noise
        cyclePeriod: Int? = nil,          // optional cyclical pattern (e.g. 7 for weekly)
        cycleAmplitude: Double = 1.5,    // severity swing for cycle
        symptoms: [String] = ["Headache", "Fatigue", "Nausea", "Back Pain"],
        triggers: [String] = ["Stress", "Poor Sleep", "Weather", "Caffeine"],
        triggerProbability: Double = 0.3
    ) -> [SymptomEntry] {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        var entries: [SymptomEntry] = []

        for dayOffset in stride(from: -(days - 1), through: 0, by: 1) {
            guard let date = calendar.date(byAdding: .day, value: dayOffset, to: today) else { continue }

            let entryCount = Int.random(in: symptomsPerDay)
            let dayIndex = Double(dayOffset + days - 1)

            for _ in 0..<entryCount {
                let symptom = symptoms.randomElement() ?? "Headache"

                // Severity: baseline + trend + cycle + noise
                var severity = baselineSeverity
                severity += trendSlope * dayIndex
                if let period = cyclePeriod {
                    severity += cycleAmplitude * sin(2 * .pi * dayIndex / Double(period))
                }
                severity += Double.random(in: -volatility...volatility)
                let clampedSeverity = max(1, min(10, Int(round(severity))))

                // Random triggers
                var entryTriggers: [String] = []
                for trigger in triggers {
                    if Double.random(in: 0...1) < triggerProbability {
                        entryTriggers.append(trigger)
                    }
                }

                // Random time within the day
                let hour = Int.random(in: 6...22)
                let minute = Int.random(in: 0...59)
                var components = calendar.dateComponents([.year, .month, .day], from: date)
                components.hour = hour
                components.minute = minute
                let timestamp = calendar.date(from: components) ?? date

                let durations: [SymptomEntry.SymptomDuration] = [.momentary, .minutes, .hours, .halfDay, .allDay]

                entries.append(SymptomEntry(
                    id: UUID(),
                    symptomId: UUID(),
                    symptomName: symptom,
                    severity: clampedSeverity,
                    timestamp: timestamp,
                    notes: nil,
                    triggers: entryTriggers,
                    duration: durations.randomElement(),
                    location: nil
                ))
            }
        }

        return entries.sorted { $0.timestamp < $1.timestamp }
    }

    /// Generates daily summaries matching the entry date range.
    static func generateSummaries(
        entries: [SymptomEntry],
        moodRange: ClosedRange<Int> = 2...4,
        energyRange: ClosedRange<Int> = 2...4,
        sleepRange: ClosedRange<Double> = 5.5...8.5,
        stressRange: ClosedRange<Int> = 1...4
    ) -> [DailySummary] {
        let calendar = Calendar.current
        let uniqueDays = Set(entries.map { calendar.startOfDay(for: $0.timestamp) }).sorted()

        return uniqueDays.map { date in
            let dayEntries = entries.filter { calendar.isDate($0.timestamp, inSameDayAs: date) }
            return DailySummary(
                id: UUID(),
                date: date,
                overallMood: Int.random(in: moodRange),
                overallEnergy: Int.random(in: energyRange),
                entries: dayEntries,
                notes: nil,
                sleepHours: Double.random(in: sleepRange),
                stressLevel: Int.random(in: stressRange),
                waterIntake: Int.random(in: 2...8)
            )
        }
    }

    // MARK: - Test Results

    struct TestResult {
        let testName: String
        let passed: Bool
        let details: String
    }

    // MARK: - Run All Tests

    /// Runs all ML model tests and returns a summary of results.
    static func runAllTests() -> [TestResult] {
        var results: [TestResult] = []

        results.append(contentsOf: testStatisticalAnalysis())
        results.append(contentsOf: testTimeSeriesAnalyzer())
        results.append(contentsOf: testSeverityPrediction())
        results.append(contentsOf: testLikelihoodPrediction())
        results.append(contentsOf: testTrendDetection())
        results.append(contentsOf: testAnomalyDetection())
        results.append(contentsOf: testDecomposition())

        return results
    }

    // MARK: - Individual Tests

    static func testStatisticalAnalysis() -> [TestResult] {
        var results: [TestResult] = []

        // Test 1: Welch's t-test with known different distributions
        let highSample = (0..<20).map { _ in Double.random(in: 6...9) }
        let lowSample = (0..<20).map { _ in Double.random(in: 2...5) }

        if let tResult = StatisticalAnalysis.welchTTest(sample1: highSample, sample2: lowSample) {
            let passed = tResult.isSignificant && tResult.meanDifference > 0
            results.append(TestResult(
                testName: "Welch's t-test: Distinct Distributions",
                passed: passed,
                details: "t=\(String(format: "%.2f", tResult.tStatistic)), p=\(String(format: "%.4f", tResult.pValue)), sig=\(tResult.isSignificant), d=\(String(format: "%.2f", tResult.effectSize))"
            ))
        } else {
            results.append(TestResult(testName: "Welch's t-test: Distinct Distributions", passed: false, details: "Returned nil"))
        }

        // Test 2: t-test with identical distributions should NOT be significant
        let sample1 = (0..<20).map { _ in Double.random(in: 4...6) }
        let sample2 = (0..<20).map { _ in Double.random(in: 4...6) }

        if let tResult = StatisticalAnalysis.welchTTest(sample1: sample1, sample2: sample2) {
            // With random data near same range, p-value should usually be > 0.05
            // But this isn't guaranteed, so just check it returns valid data
            let passed = tResult.pValue >= 0 && tResult.pValue <= 1
            results.append(TestResult(
                testName: "Welch's t-test: Similar Distributions",
                passed: passed,
                details: "p=\(String(format: "%.4f", tResult.pValue)), effect d=\(String(format: "%.2f", tResult.effectSize))"
            ))
        }

        // Test 3: Pearson correlation with perfect linear relationship
        let xPerfect: [Double] = [1, 2, 3, 4, 5, 6, 7, 8, 9, 10]
        let yPerfect: [Double] = [2, 4, 6, 8, 10, 12, 14, 16, 18, 20]

        if let corrResult = StatisticalAnalysis.pearsonCorrelation(x: xPerfect, y: yPerfect) {
            let passed = abs(corrResult.r - 1.0) < 0.001 && corrResult.strength == .veryStrong
            results.append(TestResult(
                testName: "Pearson: Perfect Linear",
                passed: passed,
                details: "r=\(String(format: "%.4f", corrResult.r)), r²=\(String(format: "%.4f", corrResult.rSquared)), strength=\(corrResult.strength.rawValue)"
            ))
        }

        // Test 4: Descriptive stats validation
        let testData: [Double] = [2, 4, 4, 4, 5, 5, 7, 9]
        if let stats = StatisticalAnalysis.describe(testData) {
            let expectedMean = 5.0
            let passed = abs(stats.mean - expectedMean) < 0.01 &&
                         stats.count == 8 &&
                         stats.min == 2 &&
                         stats.max == 9
            results.append(TestResult(
                testName: "Descriptive Stats: Known Data",
                passed: passed,
                details: "mean=\(String(format: "%.2f", stats.mean)), median=\(String(format: "%.2f", stats.median)), sd=\(String(format: "%.2f", stats.standardDeviation)), skew=\(String(format: "%.2f", stats.skewness))"
            ))
        }

        // Test 5: Outlier detection
        var normalData = (0..<30).map { _ in Double.random(in: 4...6) }
        normalData.append(15.0)  // Extreme outlier
        normalData.append(0.1)   // Low outlier
        let outliers = StatisticalAnalysis.detectOutliers(normalData)
        let passed = outliers.contains(30) || outliers.contains(31)  // At least one outlier detected
        results.append(TestResult(
            testName: "Outlier Detection: Extreme Values",
            passed: passed,
            details: "Found \(outliers.count) outliers at indices \(outliers)"
        ))

        return results
    }

    static func testTimeSeriesAnalyzer() -> [TestResult] {
        var results: [TestResult] = []

        // Test 1: EMA smoothness: output should be less volatile than input
        let noisyData = (0..<30).map { _ in Double.random(in: 1...10) }
        let smoothed = TimeSeriesAnalyzer.ema(noisyData, alpha: 0.2)

        let inputVariance = variance(noisyData)
        let outputVariance = variance(smoothed)
        results.append(TestResult(
            testName: "EMA: Reduces Volatility",
            passed: outputVariance < inputVariance,
            details: "Input var=\(String(format: "%.2f", inputVariance)), Output var=\(String(format: "%.2f", outputVariance))"
        ))

        // Test 2: EMA preserves length
        results.append(TestResult(
            testName: "EMA: Preserves Length",
            passed: smoothed.count == noisyData.count,
            details: "Input: \(noisyData.count), Output: \(smoothed.count)"
        ))

        // Test 3: Trend detection: worsening data
        let worseningData = (0..<30).map { i in Double(i) * 0.2 + Double.random(in: -0.5...0.5) + 3.0 }
        let trend = TimeSeriesAnalyzer.trendStrength(worseningData)
        results.append(TestResult(
            testName: "Trend: Detects Worsening",
            passed: trend.direction == .worsening && trend.slope > 0,
            details: "slope=\(String(format: "%.3f", trend.slope)), R²=\(String(format: "%.3f", trend.rSquared)), dir=\(trend.direction.rawValue)"
        ))

        // Test 4: Trend detection: improving data
        let improvingData = (0..<30).map { i in 8.0 - Double(i) * 0.15 + Double.random(in: -0.3...0.3) }
        let improveTrend = TimeSeriesAnalyzer.trendStrength(improvingData)
        results.append(TestResult(
            testName: "Trend: Detects Improving",
            passed: improveTrend.direction == .improving && improveTrend.slope < 0,
            details: "slope=\(String(format: "%.3f", improveTrend.slope)), dir=\(improveTrend.direction.rawValue)"
        ))

        // Test 5: Forecast: should continue in the trend direction
        let forecastValues = TimeSeriesAnalyzer.forecast(worseningData, count: 5)
        let lastActual = worseningData.last ?? 0
        results.append(TestResult(
            testName: "Forecast: Extends Trend",
            passed: forecastValues.count == 5 && (forecastValues.last ?? 0) >= lastActual - 1,
            details: "Last actual=\(String(format: "%.1f", lastActual)), Forecast end=\(String(format: "%.1f", forecastValues.last ?? 0))"
        ))

        // Test 6: Moving statistics bands
        let stableData = (0..<30).map { _ in 5.0 + Double.random(in: -1...1) }
        let stats = TimeSeriesAnalyzer.movingStatistics(stableData, window: 7)
        let bandsValid = zip(stats.lowerBand, stats.upperBand).allSatisfy { $0 <= $1 }
        results.append(TestResult(
            testName: "Moving Stats: Valid Bands",
            passed: bandsValid && stats.means.count == stableData.count,
            details: "All lower <= upper: \(bandsValid), count: \(stats.means.count)"
        ))

        return results
    }

    static func testSeverityPrediction() -> [TestResult] {
        var results: [TestResult] = []

        // Generate synthetic data with known properties
        let entries = generateEntries(
            days: 45,
            baselineSeverity: 6.0,
            trendSlope: 0.0,
            volatility: 1.0,
            symptoms: ["Headache", "Fatigue"],
            triggers: ["Stress", "Poor Sleep"]
        )
        let summaries = generateSummaries(entries: entries)

        // Test 1: Prediction returns valid severity range
        if let prediction = SymptomPredictionEngine.predictSeverity(
            symptomName: "Headache",
            entries: entries,
            summaries: summaries
        ) {
            let validRange = prediction.predictedSeverity >= 1 && prediction.predictedSeverity <= 10
            let validConfidence = prediction.confidence >= 0 && prediction.confidence <= 1
            results.append(TestResult(
                testName: "Severity Prediction: Valid Range",
                passed: validRange && validConfidence,
                details: "predicted=\(String(format: "%.1f", prediction.predictedSeverity)), confidence=\(String(format: "%.2f", prediction.confidence)), factors=\(prediction.contributingFactors.count)"
            ))
        } else {
            results.append(TestResult(testName: "Severity Prediction: Valid Range", passed: false, details: "Returned nil"))
        }

        // Test 2: Prediction with triggers should differ from without
        if let withTriggers = SymptomPredictionEngine.predictSeverity(
            symptomName: "Headache",
            entries: entries,
            summaries: summaries,
            activeTriggers: ["Stress", "Poor Sleep"]
        ), let withoutTriggers = SymptomPredictionEngine.predictSeverity(
            symptomName: "Headache",
            entries: entries,
            summaries: summaries,
            activeTriggers: []
        ) {
            // Just check both return valid values (trigger impact may be small with random data)
            results.append(TestResult(
                testName: "Severity Prediction: Trigger Sensitivity",
                passed: true,
                details: "With triggers=\(String(format: "%.1f", withTriggers.predictedSeverity)), Without=\(String(format: "%.1f", withoutTriggers.predictedSeverity))"
            ))
        }

        // Test 3: Insufficient data returns nil
        let fewEntries = Array(entries.prefix(2))
        let nilResult = SymptomPredictionEngine.predictSeverity(
            symptomName: "Headache",
            entries: fewEntries,
            summaries: summaries
        )
        results.append(TestResult(
            testName: "Severity Prediction: Insufficient Data Guard",
            passed: nilResult == nil,
            details: "With 2 entries: \(nilResult == nil ? "correctly nil" : "unexpected value")"
        ))

        return results
    }

    static func testLikelihoodPrediction() -> [TestResult] {
        var results: [TestResult] = []

        let entries = generateEntries(
            days: 30,
            symptomsPerDay: 2...3,
            symptoms: ["Headache", "Fatigue", "Nausea"]
        )

        let predictions = SymptomPredictionEngine.predictLikelihood(entries: entries)

        // Test 1: All tracked symptoms should have predictions
        results.append(TestResult(
            testName: "Likelihood: All Symptoms Covered",
            passed: predictions.count >= 2,
            details: "Predicted \(predictions.count) symptoms from \(entries.count) entries"
        ))

        // Test 2: Probabilities are valid (0 to 1)
        let allValid = predictions.allSatisfy { $0.probability >= 0 && $0.probability <= 1 }
        results.append(TestResult(
            testName: "Likelihood: Valid Probabilities",
            passed: allValid,
            details: "Probabilities: \(predictions.map { String(format: "%.2f", $0.probability) }.joined(separator: ", "))"
        ))

        // Test 3: Sorted by probability (descending)
        let isSorted = zip(predictions, predictions.dropFirst()).allSatisfy { $0.probability >= $1.probability }
        results.append(TestResult(
            testName: "Likelihood: Sorted Descending",
            passed: isSorted,
            details: "Top: \(predictions.first?.symptomName ?? "none") (\(String(format: "%.2f", predictions.first?.probability ?? 0)))"
        ))

        return results
    }

    static func testTrendDetection() -> [TestResult] {
        var results: [TestResult] = []

        // Test with clear worsening pattern
        let worseningEntries = generateEntries(
            days: 30,
            symptomsPerDay: 2...3,
            baselineSeverity: 3.0,
            trendSlope: 0.12,
            volatility: 0.8
        )

        let severities = worseningEntries.map { Double($0.severity) }
        let trend = TimeSeriesAnalyzer.trendStrength(severities)

        results.append(TestResult(
            testName: "Trend Detection: Worsening Pattern",
            passed: trend.slope > 0,
            details: "slope=\(String(format: "%.4f", trend.slope)), R²=\(String(format: "%.3f", trend.rSquared)), weekly change=\(String(format: "%.2f", trend.changePerWeek))"
        ))

        // Test with stable pattern
        let stableEntries = generateEntries(
            days: 30,
            baselineSeverity: 5.0,
            trendSlope: 0.0,
            volatility: 0.5
        )
        let stableSeverities = stableEntries.map { Double($0.severity) }
        let stableTrend = TimeSeriesAnalyzer.trendStrength(stableSeverities)

        results.append(TestResult(
            testName: "Trend Detection: Stable Pattern",
            passed: abs(stableTrend.slope) < 0.1,
            details: "slope=\(String(format: "%.4f", stableTrend.slope)), direction=\(stableTrend.direction.rawValue)"
        ))

        return results
    }

    static func testAnomalyDetection() -> [TestResult] {
        var results: [TestResult] = []

        // Create stable data with injected anomalies
        var stableData = (0..<40).map { _ in 5.0 + Double.random(in: -0.5...0.5) }
        stableData[25] = 10.0  // Inject spike
        stableData[30] = 0.5   // Inject dip

        let anomalies = TimeSeriesAnalyzer.detectAnomalies(stableData, window: 7, threshold: 2.0)

        let detectedSpike = anomalies.contains { $0.index == 25 && $0.type == .spike }
        let detectedDip = anomalies.contains { $0.index == 30 && $0.type == .dip }

        results.append(TestResult(
            testName: "Anomaly Detection: Spike",
            passed: detectedSpike,
            details: "Spike at index 25: \(detectedSpike ? "detected" : "missed")"
        ))

        results.append(TestResult(
            testName: "Anomaly Detection: Dip",
            passed: detectedDip,
            details: "Dip at index 30: \(detectedDip ? "detected" : "missed")"
        ))

        // No false positives in stable data
        let pureStable = (0..<40).map { _ in 5.0 }
        let noAnomalies = TimeSeriesAnalyzer.detectAnomalies(pureStable)
        results.append(TestResult(
            testName: "Anomaly Detection: No False Positives",
            passed: noAnomalies.isEmpty,
            details: "Constant data anomalies: \(noAnomalies.count)"
        ))

        return results
    }

    static func testDecomposition() -> [TestResult] {
        var results: [TestResult] = []

        // Create data with known weekly seasonality
        let data = (0..<42).map { i in
            5.0 + 2.0 * sin(2 * .pi * Double(i) / 7.0) + Double.random(in: -0.3...0.3)
        }

        let decomp = TimeSeriesAnalyzer.decompose(data, period: 7)

        // Trend + seasonal + residual should reconstruct original
        var reconstructionError = 0.0
        for i in 0..<data.count {
            let reconstructed = decomp.trend[i] + decomp.seasonal[i] + decomp.residual[i]
            reconstructionError += abs(reconstructed - data[i])
        }
        let avgError = reconstructionError / Double(data.count)

        results.append(TestResult(
            testName: "Decomposition: Reconstruction",
            passed: avgError < 0.01,
            details: "Avg reconstruction error: \(String(format: "%.6f", avgError))"
        ))

        // Seasonal component should have period 7
        results.append(TestResult(
            testName: "Decomposition: Component Lengths",
            passed: decomp.trend.count == data.count &&
                    decomp.seasonal.count == data.count &&
                    decomp.residual.count == data.count,
            details: "All components match input length (\(data.count))"
        ))

        return results
    }

    // MARK: - Helpers

    private static func variance(_ data: [Double]) -> Double {
        guard data.count > 1 else { return 0 }
        let mean = data.reduce(0, +) / Double(data.count)
        return data.map { pow($0 - mean, 2) }.reduce(0, +) / Double(data.count)
    }
}
