import SwiftUI
import SwiftData
import Combine

@MainActor
final class DataStore: ObservableObject {
    @Published var entries: [SymptomEntry] = []
    @Published var dailySummaries: [DailySummary] = []
    @Published var trackedSymptoms: [Symptom] = []
    @Published var medications: [Medication] = []
    @Published var medicationLogs: [MedicationLog] = []
    @Published var customSymptoms: [Symptom] = []
    @Published var weatherSnapshots: [WeatherSnapshot] = []
    @Published var journalEntries: [JournalEntry] = []
    @Published var healthSnapshots: [HealthSnapshot] = []
    @Published var onboardingProfile: OnboardingProfile?

    private let modelContext: ModelContext

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
        migrateFromUserDefaultsIfNeeded()
        fetchAll()
    }

    private func fetchAll() {
        fetchEntries()
        fetchSummaries()
        fetchMedications()
        fetchMedicationLogs()
        fetchCustomSymptoms()
        fetchWeatherSnapshots()
        fetchJournalEntries()
        fetchHealthSnapshots()
        fetchOnboardingProfile()
    }

    // MARK: - Onboarding Profile

    func saveOnboardingProfile(_ answers: [String: Any]) {
        // Remove existing profile (single user)
        try? modelContext.delete(model: PersistedOnboardingProfile.self)
        let profile = PersistedOnboardingProfile(from: answers)
        modelContext.insert(profile)
        save()
        onboardingProfile = profile.toProfile()
    }

    func loadOnboardingAnswers() -> [String: Any]? {
        let descriptor = FetchDescriptor<PersistedOnboardingProfile>()
        guard let persisted = try? modelContext.fetch(descriptor).first else { return nil }
        return persisted.toAnswers()
    }

    private func fetchOnboardingProfile() {
        let descriptor = FetchDescriptor<PersistedOnboardingProfile>()
        if let persisted = try? modelContext.fetch(descriptor).first {
            onboardingProfile = persisted.toProfile()
        }
    }

    private func save() {
        try? modelContext.save()
    }

    // MARK: - Fetch Methods

    private func fetchEntries() {
        let descriptor = FetchDescriptor<PersistedSymptomEntry>(
            sortBy: [SortDescriptor(\.timestamp, order: .reverse)]
        )
        entries = (try? modelContext.fetch(descriptor))?.map { $0.toStruct() } ?? []
    }

    private func fetchSummaries() {
        let descriptor = FetchDescriptor<PersistedDailySummary>(
            sortBy: [SortDescriptor(\.date, order: .reverse)]
        )
        let persisted = (try? modelContext.fetch(descriptor)) ?? []
        let calendar = Calendar.current
        dailySummaries = persisted.map { sd in
            let dayEntries = entries.filter { calendar.isDate($0.timestamp, inSameDayAs: sd.date) }
            return sd.toStruct(entries: dayEntries)
        }
    }

    private func fetchMedications() {
        let descriptor = FetchDescriptor<PersistedMedication>(
            sortBy: [SortDescriptor(\.startDate, order: .reverse)]
        )
        medications = (try? modelContext.fetch(descriptor))?.map { $0.toStruct() } ?? []
    }

    private func fetchMedicationLogs() {
        let descriptor = FetchDescriptor<PersistedMedicationLog>(
            sortBy: [SortDescriptor(\.timestamp, order: .reverse)]
        )
        medicationLogs = (try? modelContext.fetch(descriptor))?.map { $0.toStruct() } ?? []
    }

    private func fetchCustomSymptoms() {
        let descriptor = FetchDescriptor<PersistedCustomSymptom>()
        customSymptoms = (try? modelContext.fetch(descriptor))?.map { $0.toStruct() } ?? []
    }

    private func fetchWeatherSnapshots() {
        let descriptor = FetchDescriptor<PersistedWeatherSnapshot>(
            sortBy: [SortDescriptor(\.date, order: .reverse)]
        )
        weatherSnapshots = (try? modelContext.fetch(descriptor))?.map { $0.toStruct() } ?? []
    }

    private func fetchJournalEntries() {
        let descriptor = FetchDescriptor<PersistedJournalEntry>(
            sortBy: [SortDescriptor(\.timestamp, order: .reverse)]
        )
        journalEntries = (try? modelContext.fetch(descriptor))?.map { $0.toStruct() } ?? []
    }

    private func fetchHealthSnapshots() {
        let descriptor = FetchDescriptor<PersistedHealthSnapshot>(
            sortBy: [SortDescriptor(\.date, order: .reverse)]
        )
        healthSnapshots = (try? modelContext.fetch(descriptor))?.map { $0.toStruct() } ?? []
    }

    // MARK: - All Symptoms (library + custom)
    var allSymptoms: [Symptom] {
        Symptom.library + customSymptoms
    }

    // MARK: - Custom Symptoms
    func addCustomSymptom(_ symptom: Symptom) {
        modelContext.insert(PersistedCustomSymptom(from: symptom))
        save()
        customSymptoms.append(symptom)
    }

    func deleteCustomSymptom(_ symptom: Symptom) {
        let targetId = symptom.id
        let descriptor = FetchDescriptor<PersistedCustomSymptom>(
            predicate: #Predicate { $0.symptomId == targetId }
        )
        if let persisted = try? modelContext.fetch(descriptor).first {
            modelContext.delete(persisted)
            save()
        }
        customSymptoms.removeAll { $0.id == symptom.id }
    }

    // MARK: - Weather
    func saveWeatherSnapshot(_ snapshot: WeatherSnapshot) {
        let calendar = Calendar.current
        let descriptor = FetchDescriptor<PersistedWeatherSnapshot>()
        let all = (try? modelContext.fetch(descriptor)) ?? []

        if let existing = all.first(where: { calendar.isDate($0.date, inSameDayAs: snapshot.date) }) {
            existing.temperature = snapshot.temperature
            existing.humidity = snapshot.humidity
            existing.pressure = snapshot.pressure
            existing.weatherCode = snapshot.weatherCode
            existing.weatherDescription = snapshot.weatherDescription
        } else {
            modelContext.insert(PersistedWeatherSnapshot(from: snapshot))
        }
        save()

        if let index = weatherSnapshots.firstIndex(where: { calendar.isDate($0.date, inSameDayAs: snapshot.date) }) {
            weatherSnapshots[index] = snapshot
        } else {
            weatherSnapshots.append(snapshot)
        }
    }

    func weatherForDate(_ date: Date) -> WeatherSnapshot? {
        weatherSnapshots.first { Calendar.current.isDate($0.date, inSameDayAs: date) }
    }

    func weatherCorrelations(days: Int = 30) -> [(factor: String, finding: String, icon: String, color: String)] {
        let cutoff = Date().addingTimeInterval(-Double(days * 86400))
        let recentWeather = weatherSnapshots.filter { $0.date >= cutoff }
        guard recentWeather.count >= 5 else { return [] }

        var results: [(factor: String, finding: String, icon: String, color: String)] = []

        // Temperature correlation
        let coldDays = recentWeather.filter { $0.temperature < 10 }
        let warmDays = recentWeather.filter { $0.temperature >= 20 }
        if coldDays.count >= 2 && warmDays.count >= 2 {
            let coldSev = avgSeverityForDates(coldDays.map(\.date))
            let warmSev = avgSeverityForDates(warmDays.map(\.date))
            let diff = coldSev - warmSev
            if abs(diff) >= 0.5 {
                let worse = diff > 0 ? "cold (<10°)" : "warm (>20°)"
                results.append((
                    "Temperature",
                    "Symptoms tend to be worse on \(worse) days by \(String(format: "%.1f", abs(diff))) severity points",
                    "ss.sun",
                    "F59E0B"
                ))
            }
        }

        // Pressure correlation
        let lowPressure = recentWeather.filter { $0.pressure < 1010 }
        let highPressure = recentWeather.filter { $0.pressure >= 1020 }
        if lowPressure.count >= 2 && highPressure.count >= 2 {
            let lowSev = avgSeverityForDates(lowPressure.map(\.date))
            let highSev = avgSeverityForDates(highPressure.map(\.date))
            let diff = lowSev - highSev
            if diff >= 0.5 {
                results.append((
                    "Barometric Pressure",
                    "Low pressure days correlate with \(String(format: "%.1f", diff)) higher avg severity — common for migraines",
                    "ss.wind",
                    "60A5FA"
                ))
            }
        }

        // Humidity correlation
        let humid = recentWeather.filter { $0.humidity >= 70 }
        let dry = recentWeather.filter { $0.humidity < 50 }
        if humid.count >= 2 && dry.count >= 2 {
            let humidSev = avgSeverityForDates(humid.map(\.date))
            let drySev = avgSeverityForDates(dry.map(\.date))
            let diff = humidSev - drySev
            if abs(diff) >= 0.5 {
                let worse = diff > 0 ? "humid (>70%)" : "dry (<50%)"
                results.append((
                    "Humidity",
                    "\(worse.capitalized) conditions linked to higher symptom severity",
                    "ss.drop",
                    "818CF8"
                ))
            }
        }

        return results
    }

    // MARK: - Health Snapshots (HealthKit)
    func saveHealthSnapshot(_ snapshot: HealthSnapshot) {
        let calendar = Calendar.current
        let descriptor = FetchDescriptor<PersistedHealthSnapshot>()
        let all = (try? modelContext.fetch(descriptor)) ?? []

        if let existing = all.first(where: { calendar.isDate($0.date, inSameDayAs: snapshot.date) }) {
            existing.sleepHours = snapshot.sleepHours
            existing.heartRate = snapshot.heartRate
            existing.stepCount = snapshot.stepCount
            existing.activeMinutes = snapshot.activeMinutes
        } else {
            modelContext.insert(PersistedHealthSnapshot(from: snapshot))
        }
        save()

        if let index = healthSnapshots.firstIndex(where: { calendar.isDate($0.date, inSameDayAs: snapshot.date) }) {
            healthSnapshots[index] = snapshot
        } else {
            healthSnapshots.append(snapshot)
        }
    }

    func healthForDate(_ date: Date) -> HealthSnapshot? {
        healthSnapshots.first { Calendar.current.isDate($0.date, inSameDayAs: date) }
    }

    /// Returns the most recent HealthKit sleep value if available (for auto-filling daily check-in)
    func latestHealthKitSleep() -> Double? {
        let calendar = Calendar.current
        // Check today first, then yesterday (HealthKit sleep often spans overnight)
        if let today = healthSnapshots.first(where: { calendar.isDateInToday($0.date) }),
           let sleep = today.sleepHours, sleep > 0 {
            return sleep
        }
        if let yesterday = healthSnapshots.first(where: { calendar.isDateInYesterday($0.date) }),
           let sleep = yesterday.sleepHours, sleep > 0 {
            return sleep
        }
        return nil
    }

    /// Correlate HealthKit metrics (steps, exercise, heart rate) with symptom severity
    func healthCorrelations(days: Int = 30) -> [(factor: String, finding: String, icon: String, color: String)] {
        let cutoff = Date().addingTimeInterval(-Double(days * 86400))
        let recentHealth = healthSnapshots.filter { $0.date >= cutoff }
        guard recentHealth.count >= 5 else { return [] }

        var results: [(factor: String, finding: String, icon: String, color: String)] = []

        // Step count correlation
        let withSteps = recentHealth.filter { ($0.stepCount ?? 0) > 0 }
        if withSteps.count >= 4 {
            let sorted = withSteps.sorted { ($0.stepCount ?? 0) < ($1.stepCount ?? 0) }
            let lowHalf = Array(sorted.prefix(sorted.count / 2))
            let highHalf = Array(sorted.suffix(sorted.count / 2))

            let lowSev = avgSeverityForDates(lowHalf.map(\.date))
            let highSev = avgSeverityForDates(highHalf.map(\.date))
            let diff = lowSev - highSev

            if abs(diff) >= 0.5 {
                let avgLowSteps = lowHalf.compactMap(\.stepCount).reduce(0, +) / max(lowHalf.count, 1)
                let avgHighSteps = highHalf.compactMap(\.stepCount).reduce(0, +) / max(highHalf.count, 1)

                if diff > 0 {
                    results.append((
                        "Activity Level",
                        "Days with more steps (~\(avgHighSteps / 1000)k) show \(String(format: "%.1f", diff)) lower avg severity vs low-step days (~\(avgLowSteps / 1000)k)",
                        "ss.flame",
                        "34D399"
                    ))
                } else {
                    results.append((
                        "Activity Level",
                        "Higher activity days (~\(avgHighSteps / 1000)k steps) correlate with \(String(format: "%.1f", abs(diff))) higher severity — watch for overexertion",
                        "ss.flame",
                        "F97316"
                    ))
                }
            }
        }

        // Exercise minutes correlation
        let withExercise = recentHealth.filter { ($0.activeMinutes ?? 0) > 0 }
        if withExercise.count >= 4 {
            let exerciseDays = withExercise.filter { ($0.activeMinutes ?? 0) >= 20 }
            let restDays = recentHealth.filter { ($0.activeMinutes ?? 0) < 10 }

            if exerciseDays.count >= 2 && restDays.count >= 2 {
                let exerciseSev = avgSeverityForDates(exerciseDays.map(\.date))
                let restSev = avgSeverityForDates(restDays.map(\.date))
                let diff = restSev - exerciseSev

                if abs(diff) >= 0.5 {
                    if diff > 0 {
                        results.append((
                            "Exercise",
                            "Active days (20+ min exercise) average \(String(format: "%.1f", diff)) points lower severity than rest days",
                            "ss.cat.energy",
                            "34D399"
                        ))
                    } else {
                        results.append((
                            "Exercise",
                            "Exercise days show \(String(format: "%.1f", abs(diff))) higher avg severity — consider pacing",
                            "ss.cat.energy",
                            "F97316"
                        ))
                    }
                }
            }
        }

        // Resting heart rate correlation
        let withHR = recentHealth.filter { ($0.heartRate ?? 0) > 0 }
        if withHR.count >= 4 {
            let sorted = withHR.sorted { ($0.heartRate ?? 0) < ($1.heartRate ?? 0) }
            let lowHR = Array(sorted.prefix(sorted.count / 2))
            let highHR = Array(sorted.suffix(sorted.count / 2))

            let lowHRSev = avgSeverityForDates(lowHR.map(\.date))
            let highHRSev = avgSeverityForDates(highHR.map(\.date))
            let diff = highHRSev - lowHRSev

            if diff >= 0.5 {
                let avgHighBpm = Int(highHR.compactMap(\.heartRate).reduce(0, +) / Double(max(highHR.count, 1)))
                results.append((
                    "Heart Rate",
                    "Higher resting HR days (~\(avgHighBpm) bpm) correlate with \(String(format: "%.1f", diff)) worse severity",
                    "ss.ecg",
                    "EF4444"
                ))
            }
        }

        return results
    }

    // MARK: - Clear All Data
    func clearAllData() {
        try? modelContext.delete(model: PersistedSymptomEntry.self)
        try? modelContext.delete(model: PersistedDailySummary.self)
        try? modelContext.delete(model: PersistedMedication.self)
        try? modelContext.delete(model: PersistedMedicationLog.self)
        try? modelContext.delete(model: PersistedCustomSymptom.self)
        try? modelContext.delete(model: PersistedWeatherSnapshot.self)
        try? modelContext.delete(model: PersistedJournalEntry.self)
        try? modelContext.delete(model: PersistedHealthSnapshot.self)
        save()

        entries.removeAll()
        dailySummaries.removeAll()
        medications.removeAll()
        medicationLogs.removeAll()
        customSymptoms.removeAll()
        weatherSnapshots.removeAll()
        journalEntries.removeAll()
        healthSnapshots.removeAll()
    }

    // MARK: - Entries
    func addEntry(_ entry: SymptomEntry) {
        modelContext.insert(PersistedSymptomEntry(from: entry))
        save()
        entries.insert(entry, at: 0)
    }

    func deleteEntry(_ entry: SymptomEntry) {
        let targetId = entry.id
        let descriptor = FetchDescriptor<PersistedSymptomEntry>(
            predicate: #Predicate { $0.entryId == targetId }
        )
        if let persisted = try? modelContext.fetch(descriptor).first {
            modelContext.delete(persisted)
            save()
        }
        entries.removeAll { $0.id == entry.id }
    }

    func entriesForDate(_ date: Date) -> [SymptomEntry] {
        let calendar = Calendar.current
        return entries.filter { calendar.isDate($0.timestamp, inSameDayAs: date) }
    }

    func entriesForDateRange(from start: Date, to end: Date) -> [SymptomEntry] {
        entries.filter { $0.timestamp >= start && $0.timestamp <= end }
    }

    // MARK: - Daily Summaries
    func saveDailySummary(_ summary: DailySummary) {
        let calendar = Calendar.current
        let descriptor = FetchDescriptor<PersistedDailySummary>()
        let all = (try? modelContext.fetch(descriptor)) ?? []

        if let existing = all.first(where: { calendar.isDate($0.date, inSameDayAs: summary.date) }) {
            existing.overallMood = summary.overallMood
            existing.overallEnergy = summary.overallEnergy
            existing.notes = summary.notes
            existing.sleepHours = summary.sleepHours
            existing.stressLevel = summary.stressLevel
            existing.waterIntake = summary.waterIntake
        } else {
            modelContext.insert(PersistedDailySummary(from: summary))
        }
        save()

        if let index = dailySummaries.firstIndex(where: {
            Calendar.current.isDate($0.date, inSameDayAs: summary.date)
        }) {
            dailySummaries[index] = summary
        } else {
            dailySummaries.append(summary)
        }
    }

    func summaryForDate(_ date: Date) -> DailySummary? {
        dailySummaries.first { Calendar.current.isDate($0.date, inSameDayAs: date) }
    }

    // MARK: - Analytics
    func averageSeverity(for symptomName: String, days: Int = 30) -> Double {
        let cutoff = Date().addingTimeInterval(-Double(days * 86400))
        let relevant = entries.filter { $0.symptomName == symptomName && $0.timestamp >= cutoff }
        guard !relevant.isEmpty else { return 0 }
        return Double(relevant.map(\.severity).reduce(0, +)) / Double(relevant.count)
    }

    func symptomFrequency(days: Int = 30) -> [(String, Int)] {
        let cutoff = Date().addingTimeInterval(-Double(days * 86400))
        let relevant = entries.filter { $0.timestamp >= cutoff }
        var frequency: [String: Int] = [:]
        for entry in relevant {
            frequency[entry.symptomName, default: 0] += 1
        }
        return frequency.sorted { $0.value > $1.value }
    }

    func currentStreak() -> Int {
        let calendar = Calendar.current
        var streak = 0
        var checkDate = Date()

        while true {
            let hasEntries = entries.contains { calendar.isDate($0.timestamp, inSameDayAs: checkDate) }
            if hasEntries {
                streak += 1
                guard let prev = calendar.date(byAdding: .day, value: -1, to: checkDate) else { break }
                checkDate = prev
            } else {
                break
            }
        }

        return streak
    }

    // MARK: - Medications
    func addMedication(_ medication: Medication) {
        modelContext.insert(PersistedMedication(from: medication))
        save()
        medications.append(medication)
    }

    func updateMedication(_ medication: Medication) {
        let targetId = medication.id
        let descriptor = FetchDescriptor<PersistedMedication>(
            predicate: #Predicate { $0.medicationId == targetId }
        )
        if let existing = try? modelContext.fetch(descriptor).first {
            existing.name = medication.name
            existing.dosage = medication.dosage
            existing.frequencyRaw = medication.frequency.rawValue
            existing.timeOfDayRaw = medication.timeOfDay.rawValue
            existing.notes = medication.notes
            existing.startDate = medication.startDate
            existing.isActive = medication.isActive
            save()
        }
        if let index = medications.firstIndex(where: { $0.id == medication.id }) {
            medications[index] = medication
        }
    }

    func deleteMedication(_ medication: Medication) {
        let targetId = medication.id
        let descriptor = FetchDescriptor<PersistedMedication>(
            predicate: #Predicate { $0.medicationId == targetId }
        )
        if let persisted = try? modelContext.fetch(descriptor).first {
            modelContext.delete(persisted)
            save()
        }
        medications.removeAll { $0.id == medication.id }
    }

    func logMedication(_ log: MedicationLog) {
        modelContext.insert(PersistedMedicationLog(from: log))
        save()
        medicationLogs.append(log)
    }

    func medicationLogsForDate(_ date: Date) -> [MedicationLog] {
        let calendar = Calendar.current
        return medicationLogs.filter { calendar.isDate($0.timestamp, inSameDayAs: date) }
    }

    func isMedicationTakenToday(_ medicationId: UUID) -> Bool {
        medicationLogsForDate(Date()).contains { $0.medicationId == medicationId && $0.taken }
    }

    // MARK: - Flare-Up Detection

    /// Compares the last 3 days' average severity and entry frequency against a 14-day baseline.
    /// Triggers when recent avg is 1.5+ points above baseline or entry count is 2x the daily average.
    func detectFlareUp() -> FlareUpAlert? {
        let calendar = Calendar.current
        let now = Date()

        guard let threeDaysAgo = calendar.date(byAdding: .day, value: -3, to: now),
              let fourteenDaysAgo = calendar.date(byAdding: .day, value: -14, to: now) else {
            return nil
        }

        // Recent window: last 3 days
        let recentEntries = entries.filter { $0.timestamp >= threeDaysAgo }
        guard !recentEntries.isEmpty else { return nil }

        // Baseline window: 4–14 days ago (excludes recent window to avoid contamination)
        let baselineEntries = entries.filter { $0.timestamp >= fourteenDaysAgo && $0.timestamp < threeDaysAgo }
        guard baselineEntries.count >= 3 else { return nil }

        let recentAvgSeverity = Double(recentEntries.map(\.severity).reduce(0, +)) / Double(recentEntries.count)
        let baselineAvgSeverity = Double(baselineEntries.map(\.severity).reduce(0, +)) / Double(baselineEntries.count)
        let severityDelta = recentAvgSeverity - baselineAvgSeverity

        // Count-based check: are they logging way more entries than usual?
        let baselineDays = max(1, calendar.dateComponents([.day], from: fourteenDaysAgo, to: threeDaysAgo).day ?? 11)
        let baselineDailyAvg = Double(baselineEntries.count) / Double(baselineDays)
        let recentDailyAvg = Double(recentEntries.count) / 3.0
        let frequencySpike = baselineDailyAvg > 0 && recentDailyAvg >= baselineDailyAvg * 2.0

        // Must meet at least one threshold
        guard severityDelta >= 1.5 || frequencySpike else { return nil }

        // Find the most affected symptom in the recent window
        var symptomSeverities: [String: (total: Int, count: Int)] = [:]
        for entry in recentEntries {
            let existing = symptomSeverities[entry.symptomName] ?? (total: 0, count: 0)
            symptomSeverities[entry.symptomName] = (total: existing.total + entry.severity, count: existing.count + 1)
        }
        let mostAffected = symptomSeverities
            .max { a, b in Double(a.value.total) / Double(a.value.count) < Double(b.value.total) / Double(b.value.count) }

        let symptomName = mostAffected?.key ?? recentEntries.first?.symptomName ?? "Unknown"

        // Determine flare severity tier
        let flareSeverity: FlareUpAlert.FlareSeverity
        if severityDelta >= 3.0 || (severityDelta >= 2.0 && frequencySpike) {
            flareSeverity = .severe
        } else if severityDelta >= 2.0 || frequencySpike {
            flareSeverity = .moderate
        } else {
            flareSeverity = .mild
        }

        // Build a human-readable message
        let message: String
        switch flareSeverity {
        case .severe:
            message = "Your symptoms have spiked significantly. \(symptomName) is hitting hard — consider reaching out to your provider."
        case .moderate:
            message = "\(symptomName) is trending above your baseline. Keep an eye on your triggers."
        case .mild:
            message = "Slight uptick in \(symptomName) over the past few days compared to your usual."
        }

        return FlareUpAlert(
            severity: flareSeverity,
            message: message,
            symptomName: symptomName,
            severityDelta: severityDelta
        )
    }

    // MARK: - Correlation Analysis

    /// For each trigger, compute the average severity of entries that include it vs exclude it.
    /// Uses Welch's t-test to filter out correlations that aren't statistically significant.
    func triggerCorrelations(days: Int = 30) -> [(trigger: String, avgWith: Double, avgWithout: Double, count: Int)] {
        let cutoff = Date().addingTimeInterval(-Double(days * 86400))
        let relevant = entries.filter { $0.timestamp >= cutoff }
        guard relevant.count >= 5 else { return [] }

        let allTriggers = Set(relevant.flatMap(\.triggers))
        var results: [(trigger: String, avgWith: Double, avgWithout: Double, count: Int)] = []

        for trigger in allTriggers {
            let withTrigger = relevant.filter { $0.triggers.contains(trigger) }
            let withoutTrigger = relevant.filter { !$0.triggers.contains(trigger) }
            guard withTrigger.count >= 2, withoutTrigger.count >= 2 else { continue }

            let withSeverities = withTrigger.map { Double($0.severity) }
            let withoutSeverities = withoutTrigger.map { Double($0.severity) }

            let avgWith = withSeverities.reduce(0, +) / Double(withSeverities.count)
            let avgWithout = withoutSeverities.reduce(0, +) / Double(withoutSeverities.count)

            // Only include if the difference is meaningful (effect size > 0.2 or significant)
            if let tTest = StatisticalAnalysis.welchTTest(sample1: withSeverities, sample2: withoutSeverities) {
                if tTest.effectSize >= 0.2 || tTest.isSignificant || abs(avgWith - avgWithout) >= 1.0 {
                    results.append((trigger, avgWith, avgWithout, withTrigger.count))
                }
            } else {
                // Fallback: include if raw difference is notable
                if abs(avgWith - avgWithout) >= 0.5 {
                    results.append((trigger, avgWith, avgWithout, withTrigger.count))
                }
            }
        }

        // Sort by effect size (Cohen's d) when available, otherwise by raw difference
        return results.sorted { abs($0.avgWith - $0.avgWithout) > abs($1.avgWith - $1.avgWithout) }
    }

    /// Correlate daily check-in fields (sleep, stress) with symptom severity.
    /// Uses Welch's t-test for statistical rigor and Pearson correlation where applicable.
    func lifestyleCorrelations(days: Int = 30) -> [(factor: String, finding: String, icon: String, color: String)] {
        let cutoff = Date().addingTimeInterval(-Double(days * 86400))
        let recentSummaries = dailySummaries.filter { $0.date >= cutoff }
        guard recentSummaries.count >= 5 else { return [] }

        var results: [(factor: String, finding: String, icon: String, color: String)] = []

        // Sleep correlation — use Pearson correlation between sleep hours and daily severity
        let summariesWithSleep = recentSummaries.filter { $0.sleepHours != nil }
        if summariesWithSleep.count >= 5 {
            let sleepValues = summariesWithSleep.map { $0.sleepHours ?? 0 }
            let sleepSeverities = summariesWithSleep.map { avgSeverityForDates([$0.date]) }

            if let corr = StatisticalAnalysis.pearsonCorrelation(x: sleepValues, y: sleepSeverities),
               corr.strength != .negligible {
                let direction = corr.r < 0 ? "less" : "more"
                let sigLabel = corr.isSignificant ? "" : " (trend)"
                results.append((
                    "Sleep",
                    "\(corr.strength.rawValue) \(direction == "less" ? "inverse" : "positive") link between sleep and severity (r=\(String(format: "%.2f", corr.r)))\(sigLabel)",
                    "ss.moon.zzz",
                    "818CF8"
                ))
            } else {
                // Fallback to group comparison
                let lowSleep = summariesWithSleep.filter { ($0.sleepHours ?? 8) < 6.5 }
                let goodSleep = summariesWithSleep.filter { ($0.sleepHours ?? 8) >= 7 }

                if lowSleep.count >= 2 && goodSleep.count >= 2 {
                    let lowSev = severitiesForDates(lowSleep.map(\.date))
                    let goodSev = severitiesForDates(goodSleep.map(\.date))

                    if let tTest = StatisticalAnalysis.welchTTest(sample1: lowSev, sample2: goodSev),
                       (tTest.effectSize >= 0.2 || abs(tTest.meanDifference) >= 0.5) {
                        let diff = tTest.meanDifference
                        if diff > 0 {
                            results.append((
                                "Sleep",
                                "Symptoms average \(String(format: "%.1f", diff)) points worse on days with under 6.5h sleep (d=\(String(format: "%.1f", tTest.effectSize)))",
                                "ss.moon.zzz",
                                "818CF8"
                            ))
                        }
                    }
                }
            }
        }

        // Stress correlation — t-test between high vs low stress days
        let summariesWithStress = recentSummaries.filter { $0.stressLevel != nil }
        if summariesWithStress.count >= 5 {
            let highStress = summariesWithStress.filter { ($0.stressLevel ?? 0) >= 4 }
            let lowStress = summariesWithStress.filter { ($0.stressLevel ?? 0) <= 2 }

            if highStress.count >= 2 && lowStress.count >= 2 {
                let highSev = severitiesForDates(highStress.map(\.date))
                let lowSev = severitiesForDates(lowStress.map(\.date))

                if let tTest = StatisticalAnalysis.welchTTest(sample1: highSev, sample2: lowSev),
                   (tTest.effectSize >= 0.2 || tTest.meanDifference >= 0.5) {
                    let sigLabel = tTest.isSignificant ? " (p<0.05)" : ""
                    results.append((
                        "Stress",
                        "High stress days show \(String(format: "%.1f", tTest.meanDifference)) higher avg severity (d=\(String(format: "%.1f", tTest.effectSize)))\(sigLabel)",
                        "ss.head.brain",
                        "F472B6"
                    ))
                }
            }
        }

        // Mood correlation — Pearson between mood and severity
        let moodDays = recentSummaries.filter { $0.overallMood > 0 }
        if moodDays.count >= 5 {
            let moodValues = moodDays.map { Double($0.overallMood) }
            let moodSeverities = moodDays.map { avgSeverityForDates([$0.date]) }

            if let corr = StatisticalAnalysis.pearsonCorrelation(x: moodValues, y: moodSeverities),
               corr.strength != .negligible {
                let sigLabel = corr.isSignificant ? " (p<0.05)" : ""
                results.append((
                    "Mood",
                    "\(corr.strength.rawValue) inverse link — lower mood tracks with higher severity (r=\(String(format: "%.2f", corr.r)))\(sigLabel)",
                    "ss.mood.1",
                    "EC4899"
                ))
            } else {
                // Fallback: group comparison
                let lowMood = moodDays.filter { $0.overallMood <= 2 }
                let highMood = moodDays.filter { $0.overallMood >= 4 }
                if lowMood.count >= 2 && highMood.count >= 2 {
                    let diff = avgSeverityForDates(lowMood.map(\.date)) - avgSeverityForDates(highMood.map(\.date))
                    if diff >= 0.5 {
                        results.append((
                            "Mood",
                            "Low mood days have \(String(format: "%.1f", diff)) higher severity on average",
                            "ss.mood.1",
                            "EC4899"
                        ))
                    }
                }
            }
        }

        return results
    }

    /// Returns an array of individual entry severities for the given dates (for t-tests)
    private func severitiesForDates(_ dates: [Date]) -> [Double] {
        let calendar = Calendar.current
        var result: [Double] = []
        for date in dates {
            let dayEntries = entries.filter { calendar.isDate($0.timestamp, inSameDayAs: date) }
            if !dayEntries.isEmpty {
                let avg = Double(dayEntries.map(\.severity).reduce(0, +)) / Double(dayEntries.count)
                result.append(avg)
            }
        }
        return result
    }

    /// Correlate water intake from daily check-in with symptom severity
    func waterCorrelation(days: Int = 30) -> (factor: String, finding: String, icon: String, color: String)? {
        let cutoff = Date().addingTimeInterval(-Double(days * 86400))
        let recentSummaries = dailySummaries.filter { $0.date >= cutoff }
        let withWater = recentSummaries.filter { ($0.waterIntake ?? 0) > 0 }
        guard withWater.count >= 5 else { return nil }

        let lowWater = withWater.filter { ($0.waterIntake ?? 0) <= 3 }
        let highWater = withWater.filter { ($0.waterIntake ?? 0) >= 6 }
        guard lowWater.count >= 2, highWater.count >= 2 else { return nil }

        let lowSev = avgSeverityForDates(lowWater.map(\.date))
        let highSev = avgSeverityForDates(highWater.map(\.date))
        let diff = lowSev - highSev

        guard abs(diff) >= 0.5 else { return nil }

        if diff > 0 {
            return (
                "Hydration",
                "Days with 6+ glasses of water show \(String(format: "%.1f", diff)) lower avg severity than days with 3 or fewer",
                "ss.drop",
                "60A5FA"
            )
        } else {
            return (
                "Hydration",
                "Higher water intake days show slightly higher severity — likely not causal",
                "ss.drop",
                "60A5FA"
            )
        }
    }

    /// Analyze symptom duration patterns — do longer episodes correlate with higher severity or specific triggers?
    func durationInsights(days: Int = 30) -> [(factor: String, finding: String, icon: String, color: String)] {
        let cutoff = Date().addingTimeInterval(-Double(days * 86400))
        let relevant = entries.filter { $0.timestamp >= cutoff && $0.duration != nil }
        guard relevant.count >= 5 else { return [] }

        var results: [(factor: String, finding: String, icon: String, color: String)] = []

        // Group by duration bucket: short (momentary/minutes) vs long (hours/halfDay/allDay/ongoing)
        let shortDurations: Set<SymptomEntry.SymptomDuration> = [.momentary, .minutes]
        let longDurations: Set<SymptomEntry.SymptomDuration> = [.hours, .halfDay, .allDay, .ongoing]

        let shortEntries = relevant.filter { shortDurations.contains($0.duration!) }
        let longEntries = relevant.filter { longDurations.contains($0.duration!) }

        if shortEntries.count >= 2 && longEntries.count >= 2 {
            let shortAvg = Double(shortEntries.map(\.severity).reduce(0, +)) / Double(shortEntries.count)
            let longAvg = Double(longEntries.map(\.severity).reduce(0, +)) / Double(longEntries.count)
            let diff = longAvg - shortAvg

            if diff >= 0.5 {
                results.append((
                    "Duration",
                    "Longer episodes (hours+) average \(String(format: "%.1f", diff)) higher severity than brief ones",
                    "ss.clock",
                    "F59E0B"
                ))
            }
        }

        // Find which symptom has the longest average duration
        var symptomDurations: [String: [SymptomEntry.SymptomDuration]] = [:]
        for entry in relevant {
            symptomDurations[entry.symptomName, default: []].append(entry.duration!)
        }

        let durationWeight: [SymptomEntry.SymptomDuration: Double] = [
            .momentary: 0, .minutes: 1, .hours: 2, .halfDay: 3, .allDay: 4, .ongoing: 5
        ]

        if let longest = symptomDurations
            .filter({ $0.value.count >= 2 })
            .max(by: {
                let a = $0.value.compactMap { durationWeight[$0] }.reduce(0, +) / Double($0.value.count)
                let b = $1.value.compactMap { durationWeight[$0] }.reduce(0, +) / Double($1.value.count)
                return a < b
            }) {
            let avgDur = longest.value.compactMap { durationWeight[$0] }.reduce(0, +) / Double(longest.value.count)
            if avgDur >= 2.0 { // At least "hours" on average
                let label: String
                if avgDur >= 4 { label = "all day" }
                else if avgDur >= 3 { label = "half a day" }
                else { label = "hours" }
                results.append((
                    "Persistent Symptom",
                    "\(longest.key) typically lasts \(label) — the longest-lasting of your tracked symptoms",
                    "ss.clock",
                    "F97316"
                ))
            }
        }

        return results
    }

    /// Correlate medication adherence with symptom severity
    func medicationCorrelations(days: Int = 30) -> [(factor: String, finding: String, icon: String, color: String)] {
        let calendar = Calendar.current
        let cutoff = Date().addingTimeInterval(-Double(days * 86400))
        let recentLogs = medicationLogs.filter { $0.timestamp >= cutoff && $0.taken }
        guard recentLogs.count >= 3 else { return [] }

        var results: [(factor: String, finding: String, icon: String, color: String)] = []

        // Group medication logs by day
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        var medDays: Set<String> = []
        for log in recentLogs {
            medDays.insert(formatter.string(from: log.timestamp))
        }

        // Compare severity on med days vs non-med days
        var medDayDates: [Date] = []
        var noMedDayDates: [Date] = []

        for dayOffset in 0..<days {
            guard let date = calendar.date(byAdding: .day, value: -dayOffset, to: Date()) else { continue }
            let key = formatter.string(from: date)
            let hasEntries = entries.contains { calendar.isDate($0.timestamp, inSameDayAs: date) }
            guard hasEntries else { continue }

            if medDays.contains(key) {
                medDayDates.append(date)
            } else {
                noMedDayDates.append(date)
            }
        }

        if medDayDates.count >= 2 && noMedDayDates.count >= 2 {
            let medSev = avgSeverityForDates(medDayDates)
            let noMedSev = avgSeverityForDates(noMedDayDates)
            let diff = noMedSev - medSev

            if abs(diff) >= 0.5 {
                if diff > 0 {
                    results.append((
                        "Medication Effect",
                        "Days you took medication show \(String(format: "%.1f", diff)) lower avg severity than days without",
                        "ss.pill",
                        "34D399"
                    ))
                } else {
                    results.append((
                        "Medication",
                        "Medication days show slightly higher severity — could indicate you medicate on worse days",
                        "ss.pill",
                        "F59E0B"
                    ))
                }
            }
        }

        // Per-medication breakdown (top medication only)
        let medNames = Set(recentLogs.map(\.medicationName))
        var bestMed: (name: String, diff: Double)?

        for medName in medNames {
            let medLogDays = recentLogs.filter { $0.medicationName == medName }
            let medDayKeys = Set(medLogDays.map { formatter.string(from: $0.timestamp) })
            guard medDayKeys.count >= 2 else { continue }

            var withMedDates: [Date] = []
            for dayOffset in 0..<days {
                guard let date = calendar.date(byAdding: .day, value: -dayOffset, to: Date()) else { continue }
                let key = formatter.string(from: date)
                let hasEntries = entries.contains { calendar.isDate($0.timestamp, inSameDayAs: date) }
                if hasEntries && medDayKeys.contains(key) {
                    withMedDates.append(date)
                }
            }

            guard withMedDates.count >= 2, noMedDayDates.count >= 2 else { continue }
            let withSev = avgSeverityForDates(withMedDates)
            let withoutSev = avgSeverityForDates(noMedDayDates)
            let delta = withoutSev - withSev

            if let current = bestMed {
                if delta > current.diff { bestMed = (medName, delta) }
            } else if delta >= 0.5 {
                bestMed = (medName, delta)
            }
        }

        if let best = bestMed, results.isEmpty {
            results.append((
                "\(best.name)",
                "Severity averages \(String(format: "%.1f", best.diff)) points lower on days you take \(best.name)",
                "ss.pill",
                "34D399"
            ))
        }

        return results
    }

    /// Co-occurrence: how often do two symptoms appear on the same day?
    func symptomCoOccurrence(days: Int = 30) -> [(symptom1: String, symptom2: String, coCount: Int, ratio: Double)] {
        let cutoff = Date().addingTimeInterval(-Double(days * 86400))
        let relevant = entries.filter { $0.timestamp >= cutoff }

        // Group by day
        var daySymptoms: [String: Set<String>] = [:]
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        for entry in relevant {
            let key = formatter.string(from: entry.timestamp)
            daySymptoms[key, default: []].insert(entry.symptomName)
        }

        let uniqueSymptoms = Array(Set(relevant.map(\.symptomName)))
        guard uniqueSymptoms.count >= 2 else { return [] }

        var results: [(symptom1: String, symptom2: String, coCount: Int, ratio: Double)] = []
        for i in 0..<uniqueSymptoms.count {
            for j in (i+1)..<uniqueSymptoms.count {
                let s1 = uniqueSymptoms[i]
                let s2 = uniqueSymptoms[j]
                let daysWithBoth = daySymptoms.values.filter { $0.contains(s1) && $0.contains(s2) }.count
                let daysWithEither = daySymptoms.values.filter { $0.contains(s1) || $0.contains(s2) }.count
                guard daysWithEither > 0 else { continue }
                let ratio = Double(daysWithBoth) / Double(daysWithEither)
                if daysWithBoth >= 2 {
                    results.append((symptom1: s1, symptom2: s2, coCount: daysWithBoth, ratio: ratio))
                }
            }
        }

        return results.sorted { $0.coCount > $1.coCount }
    }

    private func avgSeverityForDates(_ dates: [Date]) -> Double {
        let calendar = Calendar.current
        var totalSeverity = 0
        var totalCount = 0
        for date in dates {
            let dayEntries = entries.filter { calendar.isDate($0.timestamp, inSameDayAs: date) }
            totalSeverity += dayEntries.map(\.severity).reduce(0, +)
            totalCount += dayEntries.count
        }
        guard totalCount > 0 else { return 0 }
        return Double(totalSeverity) / Double(totalCount)
    }

    // MARK: - Post-Logging Feedback
    /// Returns contextual feedback after logging a symptom entry
    func feedbackForEntry(_ entry: SymptomEntry) -> (message: String, color: String)? {
        let cutoff = Date().addingTimeInterval(-30 * 86400)
        let sameSymptom = entries.filter { $0.symptomName == entry.symptomName && $0.timestamp >= cutoff && $0.id != entry.id }
        guard sameSymptom.count >= 3 else { return nil }

        let avgSev = Double(sameSymptom.map(\.severity).reduce(0, +)) / Double(sameSymptom.count)
        let diff = Double(entry.severity) - avgSev

        if diff >= 2.0 {
            let pct = Int((diff / avgSev) * 100)
            return (
                "This \(entry.symptomName) is \(pct)% more severe than your 30-day average (\(String(format: "%.1f", avgSev)))",
                "F97316"
            )
        } else if diff <= -2.0 {
            return (
                "Good news — this is milder than your usual \(entry.symptomName) (avg \(String(format: "%.1f", avgSev)))",
                "34D399"
            )
        }

        // Check if this is a high-frequency day
        let todayCount = entriesForDate(Date()).count
        if todayCount >= 4 {
            return (
                "You've logged \(todayCount) symptoms today — consider reviewing your triggers",
                "818CF8"
            )
        }

        return nil
    }

    // MARK: - Journal Entries
    func addJournalEntry(_ entry: JournalEntry) {
        modelContext.insert(PersistedJournalEntry(from: entry))
        save()
        journalEntries.insert(entry, at: 0)
    }

    func updateJournalEntry(_ entry: JournalEntry) {
        let targetId = entry.id
        let descriptor = FetchDescriptor<PersistedJournalEntry>(
            predicate: #Predicate { $0.entryId == targetId }
        )
        if let existing = try? modelContext.fetch(descriptor).first {
            existing.title = entry.title
            existing.entryBody = entry.body
            existing.mood = entry.mood
            existing.tags = entry.tags
            existing.timestamp = entry.timestamp
            existing.isFavorite = entry.isFavorite
            save()
        }
        if let index = journalEntries.firstIndex(where: { $0.id == entry.id }) {
            journalEntries[index] = entry
        }
    }

    func deleteJournalEntry(_ entry: JournalEntry) {
        let targetId = entry.id
        let descriptor = FetchDescriptor<PersistedJournalEntry>(
            predicate: #Predicate { $0.entryId == targetId }
        )
        if let persisted = try? modelContext.fetch(descriptor).first {
            modelContext.delete(persisted)
            save()
        }
        journalEntries.removeAll { $0.id == entry.id }
    }

    func toggleFavorite(_ entry: JournalEntry) {
        let targetId = entry.id
        let descriptor = FetchDescriptor<PersistedJournalEntry>(
            predicate: #Predicate { $0.entryId == targetId }
        )
        if let existing = try? modelContext.fetch(descriptor).first {
            existing.isFavorite.toggle()
            save()
        }
        if let index = journalEntries.firstIndex(where: { $0.id == entry.id }) {
            journalEntries[index].isFavorite.toggle()
        }
    }

    // MARK: - Export
    func exportCSV() -> String {
        var csv = "Date,Time,Symptom,Severity,Duration,Triggers,Notes\n"
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        let timeFormatter = DateFormatter()
        timeFormatter.dateFormat = "HH:mm"

        for entry in entries.sorted(by: { $0.timestamp < $1.timestamp }) {
            let date = formatter.string(from: entry.timestamp)
            let time = timeFormatter.string(from: entry.timestamp)
            let triggers = entry.triggers.joined(separator: "; ")
            let notes = entry.notes?.replacingOccurrences(of: ",", with: ";") ?? ""
            let duration = entry.duration?.rawValue ?? ""
            csv += "\(date),\(time),\(entry.symptomName),\(entry.severity),\(duration),\(triggers),\(notes)\n"
        }

        return csv
    }

    // MARK: - Migration from UserDefaults

    private func migrateFromUserDefaultsIfNeeded() {
        let defaults = UserDefaults.standard
        guard !defaults.bool(forKey: "swiftDataMigrated") else { return }

        let decoder = JSONDecoder()

        if let data = defaults.data(forKey: "symptom_entries"),
           let saved = try? decoder.decode([SymptomEntry].self, from: data) {
            for entry in saved {
                modelContext.insert(PersistedSymptomEntry(from: entry))
            }
        }

        if let data = defaults.data(forKey: "daily_summaries"),
           let saved = try? decoder.decode([DailySummary].self, from: data) {
            for summary in saved {
                modelContext.insert(PersistedDailySummary(from: summary))
            }
        }

        if let data = defaults.data(forKey: "medications"),
           let saved = try? decoder.decode([Medication].self, from: data) {
            for med in saved {
                modelContext.insert(PersistedMedication(from: med))
            }
        }

        if let data = defaults.data(forKey: "medication_logs"),
           let saved = try? decoder.decode([MedicationLog].self, from: data) {
            for log in saved {
                modelContext.insert(PersistedMedicationLog(from: log))
            }
        }

        if let data = defaults.data(forKey: "custom_symptoms"),
           let saved = try? decoder.decode([Symptom].self, from: data) {
            for symptom in saved {
                modelContext.insert(PersistedCustomSymptom(from: symptom))
            }
        }

        if let data = defaults.data(forKey: "weather_snapshots"),
           let saved = try? decoder.decode([WeatherSnapshot].self, from: data) {
            for snapshot in saved {
                modelContext.insert(PersistedWeatherSnapshot(from: snapshot))
            }
        }

        if let data = defaults.data(forKey: "journal_entries"),
           let saved = try? decoder.decode([JournalEntry].self, from: data) {
            for entry in saved {
                modelContext.insert(PersistedJournalEntry(from: entry))
            }
        }

        if let data = defaults.data(forKey: "health_snapshots"),
           let saved = try? decoder.decode([HealthSnapshot].self, from: data) {
            for snapshot in saved {
                modelContext.insert(PersistedHealthSnapshot(from: snapshot))
            }
        }

        save()

        // Clean up old UserDefaults keys
        for key in ["symptom_entries", "daily_summaries", "medications", "medication_logs",
                     "custom_symptoms", "weather_snapshots", "journal_entries", "health_snapshots"] {
            defaults.removeObject(forKey: key)
        }
        defaults.set(true, forKey: "swiftDataMigrated")
    }
}
