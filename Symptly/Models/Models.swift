import SwiftUI
import Foundation

// MARK: - Onboarding Profile (value type for ML engines)
struct OnboardingProfile {
    let age: Double
    let biologicalSex: String
    let goals: [String]
    let categories: [String]
    let frequency: String
    let impacts: [String]
    let stress: Double
    let exercise: Double
    let sleep: Double
    let conditions: [String]
    let severityBaseline: Double
    let duration: String
    let healthRating: Double

    /// Compute an onboarding bias for the wellness score (-15 to +15).
    /// Fades as real data accumulates.
    func wellnessBias(dataPoints: Int) -> Double {
        var bias = 0.0

        // Severity baseline: high reported severity = lower expectation
        bias -= (severityBaseline - 5) * 2.0

        // Frequency
        switch frequency {
        case "Daily": bias -= 5
        case "Several times a week": bias -= 3
        case "Weekly": bias -= 1
        case "Occasionally": bias += 2
        case "Rarely": bias += 4
        default: break
        }

        // Conditions count
        let conditionCount = conditions.filter { $0 != "None of these" }.count
        if conditionCount == 0 { bias += 2 }
        else { bias -= min(Double(conditionCount) * 1.5, 8) }

        // Duration
        switch duration {
        case "3+ years": bias -= 4
        case "1-3 years": bias -= 2
        case "6-12 months": bias -= 1
        case "Less than a month": bias += 2
        default: break
        }

        // Health rating
        bias += (healthRating - 5) * 1.5

        // Stress/exercise
        bias -= (stress - 5) * 0.8
        bias += (exercise - 3) * 0.8

        // Clamp
        bias = max(-15, min(15, bias))

        // Fade as data accumulates (gone by ~60 data points)
        let fade = max(0, 1.0 - Double(dataPoints) / 60.0)
        return bias * fade
    }

    /// Compute baseline flare-up risk adjustment based on self-reported severity/frequency.
    func flareUpRiskBias() -> Double {
        var risk = 0.0
        if severityBaseline >= 7 { risk += 0.1 }
        switch frequency {
        case "Daily": risk += 0.15
        case "Several times a week": risk += 0.08
        default: break
        }
        switch duration {
        case "3+ years": risk += 0.05
        case "1-3 years": risk += 0.03
        default: break
        }
        return min(risk, 0.25)
    }
}

// MARK: - Symptom
struct Symptom: Identifiable, Codable, Hashable {
    let id: UUID
    var name: String
    var category: SymptomCategory
    var icon: String
    var color: String

    /// Look up a symptom by name across both the built-in library and a custom list.
    static func find(_ name: String, customSymptoms: [Symptom] = []) -> Symptom? {
        library.first(where: { $0.name == name })
            ?? customSymptoms.first(where: { $0.name == name })
    }

    static let library: [Symptom] = [
        // Pain
        Symptom(id: UUID(), name: "Headache", category: .pain, icon: "ss.headache", color: "EF4444"),
        Symptom(id: UUID(), name: "Back Pain", category: .pain, icon: "ss.backpain", color: "F97316"),
        Symptom(id: UUID(), name: "Joint Pain", category: .pain, icon: "ss.jointpain", color: "FB923C"),
        Symptom(id: UUID(), name: "Chest Pain", category: .pain, icon: "ss.chestpain", color: "DC2626"),
        Symptom(id: UUID(), name: "Muscle Ache", category: .pain, icon: "ss.muscleache", color: "EA580C"),
        Symptom(id: UUID(), name: "Abdominal Pain", category: .pain, icon: "ss.abdominal", color: "F87171"),

        // Digestive
        Symptom(id: UUID(), name: "Nausea", category: .digestive, icon: "ss.nausea", color: "A3E635"),
        Symptom(id: UUID(), name: "Bloating", category: .digestive, icon: "ss.bloating", color: "84CC16"),
        Symptom(id: UUID(), name: "Acid Reflux", category: .digestive, icon: "ss.acidreflux", color: "F59E0B"),
        Symptom(id: UUID(), name: "Constipation", category: .digestive, icon: "ss.constipation", color: "D97706"),
        Symptom(id: UUID(), name: "Diarrhea", category: .digestive, icon: "ss.diarrhea", color: "CA8A04"),

        // Neurological
        Symptom(id: UUID(), name: "Dizziness", category: .neurological, icon: "ss.dizziness", color: "8B5CF6"),
        Symptom(id: UUID(), name: "Brain Fog", category: .neurological, icon: "ss.brainfog", color: "A78BFA"),
        Symptom(id: UUID(), name: "Numbness", category: .neurological, icon: "ss.numbness", color: "7C3AED"),
        Symptom(id: UUID(), name: "Tremors", category: .neurological, icon: "ss.tremors", color: "6D28D9"),

        // Mental
        Symptom(id: UUID(), name: "Anxiety", category: .mental, icon: "ss.anxiety", color: "EC4899"),
        Symptom(id: UUID(), name: "Depression", category: .mental, icon: "ss.depression", color: "BE185D"),
        Symptom(id: UUID(), name: "Insomnia", category: .mental, icon: "ss.insomnia", color: "DB2777"),
        Symptom(id: UUID(), name: "Mood Swings", category: .mental, icon: "ss.moodswings", color: "F472B6"),

        // Respiratory
        Symptom(id: UUID(), name: "Shortness of Breath", category: .respiratory, icon: "ss.shortbreath", color: "60A5FA"),
        Symptom(id: UUID(), name: "Cough", category: .respiratory, icon: "ss.cough", color: "3B82F6"),
        Symptom(id: UUID(), name: "Wheezing", category: .respiratory, icon: "ss.wheezing", color: "2563EB"),
        Symptom(id: UUID(), name: "Congestion", category: .respiratory, icon: "ss.congestion", color: "1D4ED8"),

        // Skin
        Symptom(id: UUID(), name: "Rash", category: .skin, icon: "ss.rash", color: "F472B6"),
        Symptom(id: UUID(), name: "Itching", category: .skin, icon: "ss.itching", color: "E879F9"),
        Symptom(id: UUID(), name: "Dry Skin", category: .skin, icon: "ss.dryskin", color: "C084FC"),

        // Energy
        Symptom(id: UUID(), name: "Fatigue", category: .energy, icon: "ss.fatigue", color: "FBBF24"),
        Symptom(id: UUID(), name: "Low Energy", category: .energy, icon: "ss.lowenergy", color: "F59E0B"),
        Symptom(id: UUID(), name: "Weakness", category: .energy, icon: "ss.weakness", color: "D97706"),
    ]
}

enum SymptomCategory: String, Codable, CaseIterable {
    case pain = "Pain"
    case digestive = "Digestive"
    case neurological = "Neurological"
    case mental = "Mental Health"
    case respiratory = "Respiratory"
    case skin = "Skin"
    case energy = "Energy"

    var icon: String {
        switch self {
        case .pain: return "ss.cat.pain"
        case .digestive: return "ss.cat.digestive"
        case .neurological: return "ss.cat.neuro"
        case .mental: return "ss.cat.mental"
        case .respiratory: return "ss.cat.respiratory"
        case .skin: return "ss.cat.skin"
        case .energy: return "ss.cat.energy"
        }
    }

    var color: Color {
        switch self {
        case .pain: return Color(hex: "EF4444")
        case .digestive: return Color(hex: "84CC16")
        case .neurological: return Color(hex: "8B5CF6")
        case .mental: return Color(hex: "EC4899")
        case .respiratory: return Color(hex: "60A5FA")
        case .skin: return Color(hex: "E879F9")
        case .energy: return Color(hex: "FBBF24")
        }
    }
}

// MARK: - Symptom Entry (logged instance)
struct SymptomEntry: Identifiable, Codable {
    let id: UUID
    let symptomId: UUID
    var symptomName: String
    var severity: Int // 1-10
    var timestamp: Date
    var notes: String?
    var triggers: [String]
    var duration: SymptomDuration?
    var location: String?

    enum SymptomDuration: String, Codable, CaseIterable {
        case momentary = "Momentary"
        case minutes = "Minutes"
        case hours = "Hours"
        case halfDay = "Half Day"
        case allDay = "All Day"
        case ongoing = "Ongoing"
    }
}

// MARK: - Daily Summary
struct DailySummary: Identifiable, Codable {
    let id: UUID
    let date: Date
    var overallMood: Int // 1-5
    var overallEnergy: Int // 1-5
    var entries: [SymptomEntry]
    var notes: String?
    var sleepHours: Double?
    var stressLevel: Int? // 1-5
    var waterIntake: Int? // glasses
}

// MARK: - Insight
struct Insight: Identifiable {
    let id = UUID()
    let title: String
    let description: String
    let icon: String
    let color: Color
    let type: InsightType

    enum InsightType {
        case trend, correlation, alert, milestone
    }
}

// MARK: - Medication
struct Medication: Identifiable, Codable {
    let id: UUID
    var name: String
    var dosage: String
    var frequency: MedicationFrequency
    var timeOfDay: MedicationTime
    var notes: String?
    var startDate: Date
    var isActive: Bool

    enum MedicationFrequency: String, Codable, CaseIterable {
        case daily = "Daily"
        case twiceDaily = "Twice daily"
        case asNeeded = "As needed"
        case weekly = "Weekly"
        case other = "Other"
    }

    enum MedicationTime: String, Codable, CaseIterable {
        case morning = "Morning"
        case afternoon = "Afternoon"
        case evening = "Evening"
        case bedtime = "Bedtime"
        case withFood = "With food"
    }
}

struct MedicationLog: Identifiable, Codable {
    let id: UUID
    let medicationId: UUID
    var medicationName: String
    var timestamp: Date
    var taken: Bool
    var notes: String?
}

// MARK: - Weather
struct WeatherSnapshot: Codable {
    let date: Date
    var temperature: Double
    var humidity: Int
    var pressure: Double
    var weatherCode: Int
    var weatherDescription: String
}

// MARK: - Flare-Up Alert
struct FlareUpAlert: Identifiable {
    let id = UUID()
    let severity: FlareSeverity
    let message: String
    let symptomName: String
    let severityDelta: Double

    enum FlareSeverity: String {
        case mild = "Mild"
        case moderate = "Moderate"
        case severe = "Severe"

        var color: Color {
            switch self {
            case .mild: return Color.SS.accent
            case .moderate: return Color.SS.warning
            case .severe: return Color.SS.error
            }
        }
    }
}

// MARK: - Health Snapshot (HealthKit daily data)
struct HealthSnapshot: Codable {
    let date: Date
    var sleepHours: Double?
    var heartRate: Double?      // average bpm
    var stepCount: Int?
    var activeMinutes: Int?
}

// MARK: - Onboarding
struct OnboardingPage: Identifiable {
    let id = UUID()
    let headline: String
    let subheadline: String
    let icon: String
    let accentColor: Color
    let animationType: AnimationType

    enum AnimationType {
        case pulse, wave, float, glow
    }
}

// MARK: - Journal Entry
struct JournalEntry: Identifiable, Codable {
    let id: UUID
    var title: String
    var body: String
    var mood: Int? // 1-5, optional
    var tags: [String]
    var timestamp: Date
    var isFavorite: Bool
}

// MARK: - Subscription Plans
struct SubscriptionPlan: Identifiable {
    let id = UUID()
    let name: String
    let price: String
    let period: String
    let savings: String?
    let features: [String]
    let isPopular: Bool
    let productId: String
    let pricePerMonth: String
}
