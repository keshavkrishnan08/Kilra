import SwiftUI
import CoreML

@MainActor
final class WellnessScoreEngine: ObservableObject {
    @Published var currentScore: Double = 50
    @Published var weeklyScores: [DayScore] = []
    @Published var scoreBreakdown: ScoreBreakdown = .empty
    @Published var isReady = false

    private var coreMLModel: WellnessScoreModel?

    struct DayScore: Identifiable {
        let id = UUID()
        let date: Date
        let score: Double
        let label: String
    }

    struct ScoreBreakdown {
        var moodContribution: Double
        var energyContribution: Double
        var severityPenalty: Double
        var volumePenalty: Double
        var streakBonus: Double
        var diversityPenalty: Double
        var healthBonus: Double

        static let empty = ScoreBreakdown(
            moodContribution: 0, energyContribution: 0,
            severityPenalty: 0, volumePenalty: 0,
            streakBonus: 0, diversityPenalty: 0,
            healthBonus: 0
        )
    }

    init() {
        loadModel()
    }

    private func loadModel() {
        // Use the Xcode auto-generated WellnessScoreModel class
        do {
            let config = MLModelConfiguration()
            coreMLModel = try WellnessScoreModel(configuration: config)
        } catch {
            coreMLModel = nil
        }
        isReady = true
    }

    // MARK: - Predict wellness score using the trained ML model
    func predict(
        symptomCount: Int,
        avgSeverity: Double,
        maxSeverity: Int,
        streak: Int,
        mood: Int,
        energy: Int,
        uniqueSymptoms: Int,
        entriesToday: Int,
        onboardingProfile: OnboardingProfile? = nil
    ) -> Double {
        // Use the auto-generated CoreML class (all inputs are Double)
        if let model = coreMLModel {
            do {
                let input = WellnessScoreModelInput(
                    symptom_count: Double(symptomCount),
                    avg_severity: avgSeverity,
                    max_severity: Double(maxSeverity),
                    streak: Double(streak),
                    mood: Double(mood),
                    energy: Double(energy),
                    unique_symptoms: Double(uniqueSymptoms),
                    entries_today: Double(entriesToday)
                )
                let prediction = try model.prediction(input: input)
                return max(0, min(100, prediction.wellness_score))
            } catch {
                // Fall through to heuristic
            }
        }

        return heuristicScore(
            symptomCount: symptomCount,
            avgSeverity: avgSeverity,
            maxSeverity: maxSeverity,
            streak: streak,
            mood: mood,
            energy: energy,
            uniqueSymptoms: uniqueSymptoms,
            entriesToday: entriesToday,
            onboardingProfile: onboardingProfile
        )
    }

    // MARK: - Predict with HealthKit data
    private func predictWithHealth(
        symptomCount: Int,
        avgSeverity: Double,
        maxSeverity: Int,
        streak: Int,
        mood: Int,
        energy: Int,
        uniqueSymptoms: Int,
        entriesToday: Int,
        sleepHours: Double?,
        stepCount: Int?,
        activeMinutes: Int?,
        onboardingProfile: OnboardingProfile? = nil
    ) -> Double {
        // CoreML model doesn't know about health data — use heuristic with full inputs
        return heuristicScore(
            symptomCount: symptomCount,
            avgSeverity: avgSeverity,
            maxSeverity: maxSeverity,
            streak: streak,
            mood: mood,
            energy: energy,
            uniqueSymptoms: uniqueSymptoms,
            entriesToday: entriesToday,
            sleepHours: sleepHours,
            stepCount: stepCount,
            activeMinutes: activeMinutes,
            onboardingProfile: onboardingProfile
        )
    }

    // MARK: - Heuristic fallback with detailed weighting
    private func heuristicScore(
        symptomCount: Int,
        avgSeverity: Double,
        maxSeverity: Int,
        streak: Int,
        mood: Int,
        energy: Int,
        uniqueSymptoms: Int,
        entriesToday: Int,
        sleepHours: Double? = nil,
        stepCount: Int? = nil,
        activeMinutes: Int? = nil,
        onboardingProfile: OnboardingProfile? = nil
    ) -> Double {
        // Mood contribution: 20% weight (mood 5 = +20, mood 1 = +4)
        let moodScore = Double(mood) / 5.0 * 20.0

        // Energy contribution: 15% weight (energy 5 = +15, energy 1 = +3)
        let energyScore = Double(energy) / 5.0 * 15.0

        // Severity penalty: up to -25 points
        // Weighted by both average and max severity
        let avgSevPenalty = avgSeverity / 10.0 * 18.0
        let maxSevPenalty = Double(maxSeverity) / 10.0 * 7.0
        let severityPenalty = avgSevPenalty + maxSevPenalty

        // Volume penalty: more symptoms = worse, up to -15 points
        // Weighted exponentially so first few entries matter less
        let volumePenalty = min(pow(Double(symptomCount), 0.7) * 2.0, 15.0)

        // Diversity penalty: many different symptoms is worse than one recurring one
        let diversityPenalty = min(Double(uniqueSymptoms) * 1.5, 8.0)

        // Streak bonus: consistency is rewarded, up to +12 points
        let streakBonus = min(Double(streak) * 1.7, 12.0)

        // Interaction: high severity + high volume is extra bad
        let interactionPenalty = (avgSeverity > 6 && symptomCount > 5)
            ? (avgSeverity - 6) * Double(symptomCount - 5) * 0.5
            : 0

        // Today factor: many entries today pulls score down slightly
        let todayPenalty = min(Double(entriesToday) * 1.2, 6.0)

        // HealthKit bonuses: sleep quality and activity level
        // Sleep: good sleep (7-9h) gives up to +6, poor sleep (<5h or >10h) penalizes up to -4
        var healthBonus = 0.0
        if let sleep = sleepHours, sleep > 0 {
            if sleep >= 7 && sleep <= 9 {
                healthBonus += min((sleep - 6) * 2.0, 6.0)
            } else if sleep < 5 {
                healthBonus -= (5 - sleep) * 1.5
            } else if sleep > 10 {
                healthBonus -= (sleep - 10) * 1.0
            }
        }

        // Steps: moderate activity gives up to +4, sedentary days get nothing
        if let steps = stepCount, steps > 0 {
            let stepsK = Double(steps) / 1000.0
            if stepsK >= 3 {
                healthBonus += min(stepsK * 0.4, 4.0)
            }
        }

        // Exercise: up to +3 for 30+ active minutes
        if let minutes = activeMinutes, minutes > 0 {
            healthBonus += min(Double(minutes) / 10.0, 3.0)
        }

        // Onboarding profile bias (fades as real data accumulates)
        let profileBias = onboardingProfile?.wellnessBias(dataPoints: symptomCount) ?? 0.0

        // Base of 65 (neutral-positive starting point)
        let raw = 65.0
            + moodScore
            + energyScore
            - severityPenalty
            - volumePenalty
            - diversityPenalty
            + streakBonus
            - interactionPenalty
            - todayPenalty
            + healthBonus
            + profileBias

        return max(5, min(95, raw))
    }

    // MARK: - Compute weekly scores from DataStore
    func computeWeeklyScores(dataStore: DataStore, profile: OnboardingProfile? = nil, healthKitEnabled: Bool = true) {
        let calendar = Calendar.current
        let formatter = DateFormatter()
        formatter.dateFormat = "EEE"

        var scores: [DayScore] = []

        for dayOffset in (0..<7).reversed() {
            guard let date = calendar.date(byAdding: .day, value: -dayOffset, to: Date()) else { continue }

            let dayEntries = dataStore.entriesForDate(date)

            // Compute a rolling 7-day window ending on this date
            let windowStart = calendar.date(byAdding: .day, value: -6, to: date) ?? date
            let windowEntries = dataStore.entriesForDateRange(from: windowStart, to: date)
            let summary = dataStore.summaryForDate(date)

            // -- Symptom count: total entries in the 7-day window
            let symptomCount = windowEntries.count

            // -- Average severity: severity-weighted mean across all entries in window
            let avgSev: Double
            if windowEntries.isEmpty {
                avgSev = 0
            } else {
                // Weight recent entries more heavily (exponential decay)
                var weightedSum = 0.0
                var totalWeight = 0.0
                for entry in windowEntries {
                    let daysAgo = max(0, calendar.dateComponents([.day], from: entry.timestamp, to: date).day ?? 0)
                    let weight = pow(0.85, Double(daysAgo)) // Recent entries matter more
                    weightedSum += Double(entry.severity) * weight
                    totalWeight += weight
                }
                avgSev = totalWeight > 0 ? weightedSum / totalWeight : 0
            }

            // -- Max severity today
            let maxSev = dayEntries.map(\.severity).max() ?? 0

            // -- Unique symptom types in window
            let unique = Set(windowEntries.map(\.symptomName)).count

            // -- Mood and energy from daily check-in (default to neutral 3 if not logged)
            let mood = summary?.overallMood ?? 3
            let energy = summary?.overallEnergy ?? 3

            // -- Streak: consecutive days with at least one entry up to this date
            var streak = 0
            var checkDate = date
            while true {
                let hasEntry = dataStore.entries.contains {
                    calendar.isDate($0.timestamp, inSameDayAs: checkDate)
                }
                if hasEntry {
                    streak += 1
                    guard let prev = calendar.date(byAdding: .day, value: -1, to: checkDate) else { break }
                    checkDate = prev
                } else {
                    break
                }
            }

            // HealthKit data for this day (only if user enabled it)
            let healthSnap = healthKitEnabled ? dataStore.healthForDate(date) : nil

            let score = predictWithHealth(
                symptomCount: symptomCount,
                avgSeverity: avgSev,
                maxSeverity: maxSev,
                streak: streak,
                mood: mood,
                energy: energy,
                uniqueSymptoms: unique,
                entriesToday: dayEntries.count,
                sleepHours: healthSnap?.sleepHours,
                stepCount: healthSnap?.stepCount,
                activeMinutes: healthSnap?.activeMinutes,
                onboardingProfile: profile
            )

            scores.append(DayScore(
                date: date,
                score: score,
                label: formatter.string(from: date)
            ))
        }

        weeklyScores = scores
        currentScore = scores.last?.score ?? 50

        // Compute breakdown for today's score
        computeBreakdown(dataStore: dataStore, profile: profile, healthKitEnabled: healthKitEnabled)
    }

    // MARK: - Breakdown for transparency
    private func computeBreakdown(dataStore: DataStore, profile: OnboardingProfile? = nil, healthKitEnabled: Bool = true) {
        let calendar = Calendar.current
        let today = Date()
        let windowStart = calendar.date(byAdding: .day, value: -6, to: today) ?? today
        let windowEntries = dataStore.entriesForDateRange(from: windowStart, to: today)
        let dayEntries = dataStore.entriesForDate(today)
        let summary = dataStore.summaryForDate(today)

        let mood = Double(summary?.overallMood ?? 3)
        let energy = Double(summary?.overallEnergy ?? 3)

        var weightedSum = 0.0
        var totalWeight = 0.0
        for entry in windowEntries {
            let daysAgo = max(0, calendar.dateComponents([.day], from: entry.timestamp, to: today).day ?? 0)
            let weight = pow(0.85, Double(daysAgo))
            weightedSum += Double(entry.severity) * weight
            totalWeight += weight
        }
        let avgSev = totalWeight > 0 ? weightedSum / totalWeight : 0

        let streak = dataStore.currentStreak()
        let unique = Set(windowEntries.map(\.symptomName)).count

        // HealthKit bonus for today's breakdown (only if enabled)
        let healthSnap = healthKitEnabled ? dataStore.healthForDate(today) : nil
        var hBonus = 0.0
        if let sleep = healthSnap?.sleepHours, sleep > 0 {
            if sleep >= 7 && sleep <= 9 { hBonus += min((sleep - 6) * 2.0, 6.0) }
            else if sleep < 5 { hBonus -= (5 - sleep) * 1.5 }
            else if sleep > 10 { hBonus -= (sleep - 10) * 1.0 }
        }
        if let steps = healthSnap?.stepCount, steps > 0 {
            let stepsK = Double(steps) / 1000.0
            if stepsK >= 3 { hBonus += min(stepsK * 0.4, 4.0) }
        }
        if let minutes = healthSnap?.activeMinutes, minutes > 0 {
            hBonus += min(Double(minutes) / 10.0, 3.0)
        }

        scoreBreakdown = ScoreBreakdown(
            moodContribution: mood / 5.0 * 20.0,
            energyContribution: energy / 5.0 * 15.0,
            severityPenalty: -(avgSev / 10.0 * 18.0 + Double(dayEntries.map(\.severity).max() ?? 0) / 10.0 * 7.0),
            volumePenalty: -min(pow(Double(windowEntries.count), 0.7) * 2.0, 15.0),
            streakBonus: min(Double(streak) * 1.7, 12.0),
            diversityPenalty: -min(Double(unique) * 1.5, 8.0),
            healthBonus: hBonus
        )
    }
}
