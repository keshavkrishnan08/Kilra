import SwiftUI
import Combine

final class AppState: ObservableObject {
    enum AppFlow {
        case splash
        case onboarding
        case scoreReveal
        case paywall
        case main
    }

    @Published var currentFlow: AppFlow = .splash
    @Published var hasCompletedOnboarding: Bool = false
    @Published var hasActiveSubscription: Bool = false
    @Published var hasSeenScoreReveal: Bool = false

    // Onboarding answers stored for baseline score
    @Published var onboardingAnswers: [String: Any] = [:]

    private let defaults = UserDefaults.standard

    init() {
        self.hasCompletedOnboarding = defaults.bool(forKey: "hasCompletedOnboarding")
        self.hasActiveSubscription = defaults.bool(forKey: "hasActiveSubscription")
        self.hasSeenScoreReveal = defaults.bool(forKey: "hasSeenScoreReveal")
        loadOnboardingAnswers()
        determineFlow()
    }

    func determineFlow() {
        if !hasCompletedOnboarding {
            currentFlow = .onboarding
        } else if !hasSeenScoreReveal {
            currentFlow = .scoreReveal
        } else if !hasActiveSubscription {
            currentFlow = .paywall
        } else {
            currentFlow = .main
        }
    }

    func completeOnboarding() {
        hasCompletedOnboarding = true
        defaults.set(true, forKey: "hasCompletedOnboarding")
        persistOnboardingAnswers()
        determineFlow()
    }

    func completeScoreReveal() {
        hasSeenScoreReveal = true
        defaults.set(true, forKey: "hasSeenScoreReveal")
        determineFlow()
    }

    func activateSubscription() {
        hasActiveSubscription = true
        defaults.set(true, forKey: "hasActiveSubscription")
        determineFlow()
    }

    func resetApp() {
        hasCompletedOnboarding = false
        hasActiveSubscription = false
        hasSeenScoreReveal = false
        onboardingAnswers.removeAll()
        defaults.set(false, forKey: "hasCompletedOnboarding")
        defaults.set(false, forKey: "hasActiveSubscription")
        defaults.set(false, forKey: "hasSeenScoreReveal")
        defaults.removeObject(forKey: "onboardingAnswers")
        determineFlow()
    }

    func resetOnboarding() {
        hasCompletedOnboarding = false
        hasSeenScoreReveal = false
        defaults.set(false, forKey: "hasCompletedOnboarding")
        defaults.set(false, forKey: "hasSeenScoreReveal")
        determineFlow()
    }

    // MARK: - Onboarding Answer Persistence

    private func persistOnboardingAnswers() {
        if let data = try? JSONSerialization.data(withJSONObject: onboardingAnswers) {
            defaults.set(data, forKey: "onboardingAnswers")
        }
    }

    private func loadOnboardingAnswers() {
        if let data = defaults.data(forKey: "onboardingAnswers"),
           let dict = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
            onboardingAnswers = dict
        }
    }

    // MARK: - Compute baseline score from onboarding answers
    func computeBaselineScore() -> Int {
        var score = 65.0

        // Age factor: younger adults have slightly higher baseline, seniors lower
        if let age = onboardingAnswers["age"] as? Double {
            if age < 25 {
                score += 3.0
            } else if age < 40 {
                score += 1.5
            } else if age > 60 {
                score -= 2.0
            } else if age > 75 {
                score -= 4.0
            }
        }

        // Sex-based adjustment (biological differences in symptom expression)
        if let sex = onboardingAnswers["sex"] as? String {
            switch sex {
            case "Female": score -= 1.0  // Statistically higher symptom reporting baseline
            case "Male": score += 0.5
            default: break
            }
        }

        // Goals count: more goals = more health-aware = slight positive signal
        if let goals = onboardingAnswers["goals"] as? [String] {
            score += min(Double(goals.count) * 0.5, 2.5)
        }

        // Health rating (1-10, higher = healthier)
        if let healthRating = onboardingAnswers["healthRating"] as? Double {
            score += (healthRating - 5) * 3.0
        }

        // Severity baseline (1-10, lower = better)
        if let severity = onboardingAnswers["severityBaseline"] as? Double {
            score -= (severity - 3) * 2.5
        }

        // Stress level (1-10, lower = better)
        if let stress = onboardingAnswers["stress"] as? Double {
            score -= (stress - 5) * 1.5
        }

        // Sleep hours (7-8 optimal)
        if let sleep = onboardingAnswers["sleep"] as? Double {
            let sleepDelta = abs(sleep - 7.5)
            score -= sleepDelta * 2.0
        }

        // Exercise (more = better)
        if let exercise = onboardingAnswers["exercise"] as? Double {
            score += (exercise - 3) * 1.5
        }

        // Frequency penalty
        if let freq = onboardingAnswers["frequency"] as? String {
            switch freq {
            case "Daily": score -= 8
            case "Several times a week": score -= 5
            case "Weekly": score -= 2
            case "Occasionally": score += 2
            case "Rarely": score += 5
            default: break
            }
        }

        // Duration penalty
        if let duration = onboardingAnswers["duration"] as? String {
            switch duration {
            case "Less than a month": score += 3
            case "1-3 months": score -= 1
            case "3-6 months": score -= 3
            case "6-12 months": score -= 5
            case "1-3 years": score -= 7
            case "3+ years": score -= 10
            default: break
            }
        }

        // Impact count (more areas affected = worse)
        if let impacts = onboardingAnswers["impacts"] as? [String] {
            score -= Double(impacts.count) * 1.5
        }

        // Conditions count (with diminishing returns)
        if let conditions = onboardingAnswers["conditions"] as? [String] {
            let filtered = conditions.filter { $0 != "None of these" }
            if filtered.isEmpty {
                score += 3.0 // No conditions is a positive signal
            } else {
                score -= min(Double(filtered.count) * 2.0, 12.0)
            }
        }

        // Symptom categories count
        if let categories = onboardingAnswers["categories"] as? [String] {
            score -= Double(categories.count) * 1.0
        }

        return max(12, min(88, Int(score)))
    }
}
