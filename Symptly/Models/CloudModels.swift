import SwiftData
import Foundation

// MARK: - Onboarding Profile (syncs across devices via CloudKit)

@Model
final class PersistedOnboardingProfile {
    var profileId: UUID = UUID()
    var age: Double = 0
    var biologicalSex: String = ""
    var goals: [String] = []
    var categories: [String] = []
    var frequency: String = ""
    var impacts: [String] = []
    var stress: Double = 5
    var exercise: Double = 3
    var sleep: Double = 7
    var conditions: [String] = []
    var severityBaseline: Double = 5
    var duration: String = ""
    var healthRating: Double = 5
    var completedAt: Date = Date.now

    init() {}

    init(from answers: [String: Any]) {
        self.age = answers["age"] as? Double ?? 0
        self.biologicalSex = answers["sex"] as? String ?? ""
        self.goals = answers["goals"] as? [String] ?? []
        self.categories = answers["categories"] as? [String] ?? []
        self.frequency = answers["frequency"] as? String ?? ""
        self.impacts = answers["impacts"] as? [String] ?? []
        self.stress = answers["stress"] as? Double ?? 5
        self.exercise = answers["exercise"] as? Double ?? 3
        self.sleep = answers["sleep"] as? Double ?? 7
        self.conditions = answers["conditions"] as? [String] ?? []
        self.severityBaseline = answers["severityBaseline"] as? Double ?? 5
        self.duration = answers["duration"] as? String ?? ""
        self.healthRating = answers["healthRating"] as? Double ?? 5
        self.completedAt = Date()
    }

    func toAnswers() -> [String: Any] {
        var answers: [String: Any] = [:]
        if age > 0 { answers["age"] = age }
        if !biologicalSex.isEmpty { answers["sex"] = biologicalSex }
        if !goals.isEmpty { answers["goals"] = goals }
        if !categories.isEmpty { answers["categories"] = categories }
        if !frequency.isEmpty { answers["frequency"] = frequency }
        if !impacts.isEmpty { answers["impacts"] = impacts }
        answers["stress"] = stress
        answers["exercise"] = exercise
        answers["sleep"] = sleep
        if !conditions.isEmpty { answers["conditions"] = conditions }
        answers["severityBaseline"] = severityBaseline
        if !duration.isEmpty { answers["duration"] = duration }
        answers["healthRating"] = healthRating
        return answers
    }

    func toProfile() -> OnboardingProfile {
        OnboardingProfile(
            age: age, biologicalSex: biologicalSex, goals: goals,
            categories: categories, frequency: frequency, impacts: impacts,
            stress: stress, exercise: exercise, sleep: sleep,
            conditions: conditions, severityBaseline: severityBaseline,
            duration: duration, healthRating: healthRating
        )
    }
}

// MARK: - SwiftData Models for CloudKit Sync
// CloudKit requires ALL properties to have default values or be optional.

@Model
final class PersistedSymptomEntry {
    var entryId: UUID = UUID()
    var symptomId: UUID = UUID()
    var symptomName: String = ""
    var severity: Int = 1
    var timestamp: Date = Date.now
    var notes: String?
    var triggers: [String] = []
    var durationRaw: String?
    var location: String?

    init(from entry: SymptomEntry) {
        self.entryId = entry.id
        self.symptomId = entry.symptomId
        self.symptomName = entry.symptomName
        self.severity = entry.severity
        self.timestamp = entry.timestamp
        self.notes = entry.notes
        self.triggers = entry.triggers
        self.durationRaw = entry.duration?.rawValue
        self.location = entry.location
    }

    init() {}

    func toStruct() -> SymptomEntry {
        SymptomEntry(
            id: entryId,
            symptomId: symptomId,
            symptomName: symptomName,
            severity: severity,
            timestamp: timestamp,
            notes: notes,
            triggers: triggers,
            duration: durationRaw.flatMap { SymptomEntry.SymptomDuration(rawValue: $0) },
            location: location
        )
    }
}

@Model
final class PersistedDailySummary {
    var summaryId: UUID = UUID()
    var date: Date = Date.now
    var overallMood: Int = 3
    var overallEnergy: Int = 3
    var notes: String?
    var sleepHours: Double?
    var stressLevel: Int?
    var waterIntake: Int?

    init(from summary: DailySummary) {
        self.summaryId = summary.id
        self.date = summary.date
        self.overallMood = summary.overallMood
        self.overallEnergy = summary.overallEnergy
        self.notes = summary.notes
        self.sleepHours = summary.sleepHours
        self.stressLevel = summary.stressLevel
        self.waterIntake = summary.waterIntake
    }

    init() {}

    func toStruct(entries: [SymptomEntry] = []) -> DailySummary {
        DailySummary(
            id: summaryId,
            date: date,
            overallMood: overallMood,
            overallEnergy: overallEnergy,
            entries: entries,
            notes: notes,
            sleepHours: sleepHours,
            stressLevel: stressLevel,
            waterIntake: waterIntake
        )
    }
}

@Model
final class PersistedMedication {
    var medicationId: UUID = UUID()
    var name: String = ""
    var dosage: String = ""
    var frequencyRaw: String = "Daily"
    var timeOfDayRaw: String = "Morning"
    var notes: String?
    var startDate: Date = Date.now
    var isActive: Bool = true

    init(from med: Medication) {
        self.medicationId = med.id
        self.name = med.name
        self.dosage = med.dosage
        self.frequencyRaw = med.frequency.rawValue
        self.timeOfDayRaw = med.timeOfDay.rawValue
        self.notes = med.notes
        self.startDate = med.startDate
        self.isActive = med.isActive
    }

    init() {}

    func toStruct() -> Medication {
        Medication(
            id: medicationId,
            name: name,
            dosage: dosage,
            frequency: Medication.MedicationFrequency(rawValue: frequencyRaw) ?? .daily,
            timeOfDay: Medication.MedicationTime(rawValue: timeOfDayRaw) ?? .morning,
            notes: notes,
            startDate: startDate,
            isActive: isActive
        )
    }
}

@Model
final class PersistedMedicationLog {
    var logId: UUID = UUID()
    var medicationId: UUID = UUID()
    var medicationName: String = ""
    var timestamp: Date = Date.now
    var taken: Bool = false
    var notes: String?

    init(from log: MedicationLog) {
        self.logId = log.id
        self.medicationId = log.medicationId
        self.medicationName = log.medicationName
        self.timestamp = log.timestamp
        self.taken = log.taken
        self.notes = log.notes
    }

    init() {}

    func toStruct() -> MedicationLog {
        MedicationLog(
            id: logId,
            medicationId: medicationId,
            medicationName: medicationName,
            timestamp: timestamp,
            taken: taken,
            notes: notes
        )
    }
}

@Model
final class PersistedWeatherSnapshot {
    var snapshotId: UUID = UUID()
    var date: Date = Date.now
    var temperature: Double = 0
    var humidity: Int = 0
    var pressure: Double = 0
    var weatherCode: Int = 0
    var weatherDescription: String = ""

    init(from snapshot: WeatherSnapshot) {
        self.snapshotId = UUID()
        self.date = snapshot.date
        self.temperature = snapshot.temperature
        self.humidity = snapshot.humidity
        self.pressure = snapshot.pressure
        self.weatherCode = snapshot.weatherCode
        self.weatherDescription = snapshot.weatherDescription
    }

    init() {}

    func toStruct() -> WeatherSnapshot {
        WeatherSnapshot(
            date: date,
            temperature: temperature,
            humidity: humidity,
            pressure: pressure,
            weatherCode: weatherCode,
            weatherDescription: weatherDescription
        )
    }
}

@Model
final class PersistedHealthSnapshot {
    var snapshotId: UUID = UUID()
    var date: Date = Date.now
    var sleepHours: Double?
    var heartRate: Double?
    var stepCount: Int?
    var activeMinutes: Int?

    init(from snapshot: HealthSnapshot) {
        self.snapshotId = UUID()
        self.date = snapshot.date
        self.sleepHours = snapshot.sleepHours
        self.heartRate = snapshot.heartRate
        self.stepCount = snapshot.stepCount
        self.activeMinutes = snapshot.activeMinutes
    }

    init() {}

    func toStruct() -> HealthSnapshot {
        HealthSnapshot(
            date: date,
            sleepHours: sleepHours,
            heartRate: heartRate,
            stepCount: stepCount,
            activeMinutes: activeMinutes
        )
    }
}

@Model
final class PersistedCustomSymptom {
    var symptomId: UUID = UUID()
    var name: String = ""
    var categoryRaw: String = "Pain"
    var icon: String = ""
    var color: String = "FFFFFF"

    init(from symptom: Symptom) {
        self.symptomId = symptom.id
        self.name = symptom.name
        self.categoryRaw = symptom.category.rawValue
        self.icon = symptom.icon
        self.color = symptom.color
    }

    init() {}

    func toStruct() -> Symptom {
        Symptom(
            id: symptomId,
            name: name,
            category: SymptomCategory(rawValue: categoryRaw) ?? .pain,
            icon: icon,
            color: color
        )
    }
}

@Model
final class PersistedJournalEntry {
    var entryId: UUID = UUID()
    var title: String = ""
    var entryBody: String = ""
    var mood: Int?
    var tags: [String] = []
    var timestamp: Date = Date.now
    var isFavorite: Bool = false

    init(from entry: JournalEntry) {
        self.entryId = entry.id
        self.title = entry.title
        self.entryBody = entry.body
        self.mood = entry.mood
        self.tags = entry.tags
        self.timestamp = entry.timestamp
        self.isFavorite = entry.isFavorite
    }

    init() {}

    func toStruct() -> JournalEntry {
        JournalEntry(
            id: entryId,
            title: title,
            body: entryBody,
            mood: mood,
            tags: tags,
            timestamp: timestamp,
            isFavorite: isFavorite
        )
    }
}
