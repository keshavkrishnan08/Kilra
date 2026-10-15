import SwiftUI

struct HomeView: View {
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var dataStore: DataStore
    @EnvironmentObject var healthKitManager: HealthKitManager
    @EnvironmentObject var notificationManager: NotificationManager
    @EnvironmentObject var weatherService: WeatherService
    @StateObject private var wellnessEngine = WellnessScoreEngine()
    @Binding var showLogSymptom: Bool
    @Binding var selectedTab: MainTabView.Tab
    @State private var greeting: String = ""
    @State private var showContent = false
    @State private var showExportSheet = false
    @State private var scrollToCheckin = false
    @State private var showMedications = false
    @State private var flareUpDismissedDate: Date? = nil
    @State private var showDoctorPrep = false
    @State private var showJournalCompose = false
    @State private var showPermissionsSheet = false
    @AppStorage("hasShownPermissions") private var hasShownPermissions = false
    @AppStorage("healthKitEnabled") private var healthKitEnabled = true

    private var todayEntries: [SymptomEntry] {
        dataStore.entriesForDate(Date())
    }

    private var activeFlareUp: FlareUpAlert? {
        // Reset dismissal daily: only suppress if dismissed today
        if let dismissed = flareUpDismissedDate,
           Calendar.current.isDateInToday(dismissed) {
            return nil
        }
        return dataStore.detectFlareUp()
    }

    var body: some View {
        NavigationStack {
        ZStack {
            Color.SS.background.ignoresSafeArea()

            ScrollViewReader { scrollProxy in
            ScrollView(showsIndicators: false) {
                VStack(spacing: Spacing.xl) {
                    // Header
                    HStack(alignment: .top) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(greeting)
                                .font(Font.SS.labelMedium)
                                .foregroundColor(Color.SS.textTertiary)
                                .tracking(1)
                                .textCase(.uppercase)

                            Text("there")
                                .font(Font.SS.displaySmall)
                                .foregroundColor(Color.SS.textPrimary)
                        }

                        Spacer()

                        SSIconImage(name: "ss.bell", size: 16)
                            .foregroundColor(Color.SS.textTertiary)
                            .frame(width: 40, height: 40)
                            .accessibilityLabel("Notifications")
                    }
                    .padding(.horizontal, Spacing.xl)
                    .padding(.top, Spacing.lg)

                    // Flare-up detection banner: tappable, navigates to Doctor Prep
                    if let flare = activeFlareUp {
                        FlareUpBanner(alert: flare, onTap: {
                            showDoctorPrep = true
                        }, onDismiss: {
                            withAnimation(.easeOut(duration: 0.25)) {
                                flareUpDismissedDate = Date()
                            }
                        })
                        .padding(.horizontal, Spacing.xl)
                        .transition(.move(edge: .top).combined(with: .opacity))
                    }

                    // Today's summary (with streak)
                    TodaySummaryCard(entries: todayEntries, streak: dataStore.currentStreak())
                        .padding(.horizontal, Spacing.xl)

                    // Wellness trend chart
                    WellnessChartCard(engine: wellnessEngine)
                        .padding(.horizontal, Spacing.xl)

                    // Quick Actions
                    VStack(alignment: .leading, spacing: Spacing.sm) {
                        Text("Quick Actions")
                            .font(Font.SS.headlineSmall)
                            .foregroundColor(Color.SS.textPrimary)
                            .padding(.horizontal, Spacing.xl)

                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: Spacing.sm) {
                                QuickActionButton(
                                    icon: "ss.tab.plus",
                                    label: "Log Symptom",
                                    color: Color.SS.accent
                                ) {
                                    showLogSymptom = true
                                }

                                QuickActionButton(
                                    icon: "ss.sun",
                                    label: "Check-in",
                                    color: Color.SS.violet
                                ) {
                                    withAnimation {
                                        scrollProxy.scrollTo("dailyCheckin", anchor: .top)
                                    }
                                }

                                QuickActionButton(
                                    icon: "ss.pills",
                                    label: "Meds",
                                    color: Color.SS.info
                                ) {
                                    showMedications = true
                                }

                                QuickActionButton(
                                    icon: "ss.pencil",
                                    label: "Journal",
                                    color: Color.SS.warning
                                ) {
                                    showJournalCompose = true
                                }

                                QuickActionButton(
                                    icon: "ss.ecg",
                                    label: "Doctor Prep",
                                    color: Color(hex: "34D399")
                                ) {
                                    showDoctorPrep = true
                                }
                            }
                            .padding(.horizontal, Spacing.xl)
                        }
                    }

                    // Quick Mood: one-tap mood save (feeds DailySummary → ML)
                    QuickMoodCard(dataStore: dataStore)
                        .padding(.horizontal, Spacing.xl)

                    // Today's Medications: quick take/skip (feeds MedicationLog → ML)
                    if !dataStore.medications.filter(\.isActive).isEmpty {
                        TodayMedsCard(dataStore: dataStore)
                            .padding(.horizontal, Spacing.xl)
                    }

                    // HealthKit data (if authorized AND enabled)
                    if healthKitEnabled && healthKitManager.isAuthorized {
                        HealthDataCard(healthKit: healthKitManager)
                            .padding(.horizontal, Spacing.xl)
                    }

                    // Weather card
                    if weatherService.temperature != nil {
                        WeatherCard(weatherService: weatherService)
                            .padding(.horizontal, Spacing.xl)
                    }

                    // Daily check-in
                    DailyCheckInCard(dataStore: dataStore)
                        .id("dailyCheckin")
                        .padding(.horizontal, Spacing.xl)

                    // Recent symptoms
                    VStack(alignment: .leading, spacing: Spacing.sm) {
                        HStack {
                            Text("Recent Activity")
                                .font(Font.SS.headlineSmall)
                                .foregroundColor(Color.SS.textPrimary)
                            Spacer()
                            Text("\(dataStore.entries.count) total")
                                .font(Font.SS.labelSmall)
                                .foregroundColor(Color.SS.textTertiary)
                        }
                        .padding(.horizontal, Spacing.xl)

                        if todayEntries.isEmpty {
                            SSCard {
                                SSEmptyState(
                                    icon: "ss.ecg",
                                    title: "No symptoms logged today",
                                    subtitle: "Tap + to track how you're feeling. The more you log, the smarter your insights become.",
                                    actionTitle: "Log Symptom",
                                    action: { showLogSymptom = true }
                                )
                            }
                            .padding(.horizontal, Spacing.xl)
                        } else {
                            LazyVStack(spacing: Spacing.xs) {
                                ForEach(todayEntries) { entry in
                                    SymptomEntryRow(entry: entry)
                                }
                            }
                            .padding(.horizontal, Spacing.xl)
                        }
                    }

                    Spacer(minLength: 120)
                }
            }
            } // ScrollViewReader
        }
        .opacity(showContent ? 1 : 0)
        .onAppear {
            greeting = getGreeting()
            wellnessEngine.computeWeeklyScores(dataStore: dataStore, profile: dataStore.onboardingProfile, healthKitEnabled: healthKitEnabled)
            withAnimation(.easeOut(duration: 0.3)) { showContent = true }
            if healthKitEnabled && healthKitManager.isAuthorized {
                Task {
                    await healthKitManager.fetchTodayData()
                    // Persist daily health snapshot for correlation analysis
                    let snapshot = HealthSnapshot(
                        date: Date(),
                        sleepHours: healthKitManager.sleepHours,
                        heartRate: healthKitManager.heartRate,
                        stepCount: healthKitManager.stepCount,
                        activeMinutes: healthKitManager.activeMinutes
                    )
                    dataStore.saveHealthSnapshot(snapshot)
                }
            }
            Task {
                await weatherService.fetchCurrentWeather()
                if let temp = weatherService.temperature,
                   let humidity = weatherService.humidity,
                   let pressure = weatherService.pressure,
                   let code = weatherService.weatherCode {
                    let snapshot = WeatherSnapshot(
                        date: Date(),
                        temperature: temp,
                        humidity: humidity,
                        pressure: pressure,
                        weatherCode: code,
                        weatherDescription: weatherService.weatherDescription
                    )
                    dataStore.saveWeatherSnapshot(snapshot)
                }
            }
        }
        .onChange(of: dataStore.entries.count) {
            wellnessEngine.computeWeeklyScores(dataStore: dataStore, profile: dataStore.onboardingProfile, healthKitEnabled: healthKitEnabled)
        }
        .onChange(of: dataStore.dailySummaries.count) {
            wellnessEngine.computeWeeklyScores(dataStore: dataStore, profile: dataStore.onboardingProfile, healthKitEnabled: healthKitEnabled)
        }
        .sheet(isPresented: $showExportSheet) {
            ShareSheet(items: [dataStore.exportCSV()])
        }
        .sheet(isPresented: $showMedications) {
            MedicationView()
                .presentationDetents([.large])
                .presentationDragIndicator(.visible)
                .presentationBackground(Color.SS.surfacePrimary)
        }
        .sheet(isPresented: $showJournalCompose) {
            JournalComposeView(entry: nil)
                .environmentObject(dataStore)
                .presentationDetents([.large])
                .presentationDragIndicator(.visible)
                .presentationBackground(Color.SS.surfacePrimary)
        }
        .navigationDestination(isPresented: $showDoctorPrep) {
            DoctorPrepView()
                .environmentObject(dataStore)
        }
        .navigationBarHidden(true)
        .sheet(isPresented: $showPermissionsSheet) {
            PermissionsSheet(
                healthKitManager: healthKitManager,
                notificationManager: notificationManager,
                onDone: { hasShownPermissions = true }
            )
            .presentationDetents([.medium])
            .presentationDragIndicator(.visible)
            .presentationBackground(Color.SS.surfacePrimary)
            .interactiveDismissDisabled()
        }
        .onAppear {
            if !hasShownPermissions {
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                    showPermissionsSheet = true
                }
            }
        }
        } // NavigationStack
    }

    private func getGreeting() -> String {
        let hour = Calendar.current.component(.hour, from: Date())
        switch hour {
        case 5..<12: return "Good morning"
        case 12..<17: return "Good afternoon"
        case 17..<21: return "Good evening"
        default: return "Good night"
        }
    }
}

// MARK: - Share Sheet
#if canImport(UIKit)
struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}
#else
struct ShareSheet: View {
    let items: [Any]
    var body: some View {
        Text("Export not available on this platform")
    }
}
#endif

// MARK: - Quick Action Button
struct QuickActionButton: View {
    let icon: String
    let label: String
    let color: Color
    let action: () -> Void

    var body: some View {
        Button(action: {
            SSHaptics.light()
            action()
        }) {
            VStack(spacing: 8) {
                ZStack {
                    RoundedRectangle(cornerRadius: Radius.md)
                        .fill(color.opacity(0.08))
                        .frame(width: 48, height: 48)
                    SSIconImage(name: icon, size: 18)
                        .foregroundColor(color)
                }
                Text(label)
                    .font(Font.SS.labelSmall)
                    .foregroundColor(Color.SS.textSecondary)
            }
            .frame(width: 80)
        }
        .accessibilityLabel(label)
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Quick Mood Card (one-tap mood → DailySummary → CloudKit → ML)
struct QuickMoodCard: View {
    @ObservedObject var dataStore: DataStore
    @State private var savedMood: Int? = nil

    private let moods: [(label: String, emoji: String, color: Color)] = [
        ("Awful", "😣", Color.SS.error),
        ("Bad", "😔", Color(hex: "F97316")),
        ("Okay", "😐", Color.SS.warning),
        ("Good", "😊", Color(hex: "84CC16")),
        ("Great", "😄", Color.SS.success),
    ]

    private var todayMood: Int? {
        dataStore.summaryForDate(Date())?.overallMood
    }

    var body: some View {
        SSCard(padding: Spacing.md) {
            VStack(alignment: .leading, spacing: Spacing.sm) {
                HStack {
                    Text("How are you feeling?")
                        .font(Font.SS.labelMedium)
                        .foregroundColor(Color.SS.textPrimary)
                    Spacer()
                    if todayMood != nil || savedMood != nil {
                        SSIconImage(name: "ss.checkmark", size: 12)
                            .foregroundColor(Color.SS.success)
                    }
                }

                HStack(spacing: Spacing.xs) {
                    ForEach(Array(moods.enumerated()), id: \.offset) { index, mood in
                        let moodValue = index + 1
                        let isSelected = (savedMood ?? todayMood) == moodValue

                        Button(action: {
                            SSHaptics.selection()
                            saveMood(moodValue)
                        }) {
                            VStack(spacing: 4) {
                                Text(mood.emoji)
                                    .font(.system(size: isSelected ? 30 : 24))

                                Text(mood.label)
                                    .font(Font.SS.caption)
                                    .foregroundColor(isSelected ? mood.color : Color.SS.textTertiary)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, Spacing.xs)
                            .background(
                                RoundedRectangle(cornerRadius: Radius.sm)
                                    .fill(isSelected ? mood.color.opacity(0.12) : Color.clear)
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: Radius.sm)
                                    .strokeBorder(isSelected ? mood.color.opacity(0.3) : Color.clear, lineWidth: 1)
                            )
                        }
                        .accessibilityLabel("Rate mood as \(mood.label)")
                        .buttonStyle(PlainButtonStyle())
                        .scaleEffect(isSelected ? 1.05 : 1.0)
                        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isSelected)
                    }
                }
            }
        }
    }

    private func saveMood(_ mood: Int) {
        withAnimation { savedMood = mood }

        // Create or update today's DailySummary (persists to SwiftData → CloudKit)
        let existing = dataStore.summaryForDate(Date())
        let summary = DailySummary(
            id: existing?.id ?? UUID(),
            date: Date(),
            overallMood: mood,
            overallEnergy: existing?.overallEnergy ?? 3,
            entries: dataStore.entriesForDate(Date()),
            notes: existing?.notes,
            sleepHours: existing?.sleepHours,
            stressLevel: existing?.stressLevel,
            waterIntake: existing?.waterIntake
        )
        dataStore.saveDailySummary(summary)
    }
}

// MARK: - Today's Meds Card (quick take → MedicationLog → CloudKit → ML)
struct TodayMedsCard: View {
    @ObservedObject var dataStore: DataStore

    private var activeMeds: [Medication] {
        dataStore.medications.filter(\.isActive)
    }

    var body: some View {
        SSCard(padding: Spacing.md) {
            VStack(alignment: .leading, spacing: Spacing.sm) {
                HStack {
                    Text("Today's Medications")
                        .font(Font.SS.labelMedium)
                        .foregroundColor(Color.SS.textPrimary)
                    Spacer()
                    let taken = activeMeds.filter { dataStore.isMedicationTakenToday($0.id) }.count
                    Text("\(taken)/\(activeMeds.count)")
                        .font(Font.SS.labelSmall)
                        .foregroundColor(taken == activeMeds.count ? Color.SS.success : Color.SS.textTertiary)
                }

                ForEach(activeMeds.prefix(4)) { med in
                    let taken = dataStore.isMedicationTakenToday(med.id)

                    Button(action: {
                        SSHaptics.selection()
                        toggleMed(med, taken: taken)
                    }) {
                        HStack(spacing: Spacing.sm) {
                            ZStack {
                                Circle()
                                    .strokeBorder(taken ? Color.SS.success : Color.SS.separatorStrong, lineWidth: 1.5)
                                    .frame(width: 24, height: 24)

                                if taken {
                                    SSIconImage(name: "ss.checkmark", size: 10)
                                        .foregroundColor(Color.SS.success)
                                }
                            }

                            VStack(alignment: .leading, spacing: 2) {
                                Text(med.name)
                                    .font(Font.SS.bodyMedium)
                                    .foregroundColor(taken ? Color.SS.textTertiary : Color.SS.textPrimary)
                                    .strikethrough(taken, color: Color.SS.textDisabled)

                                Text("\(med.dosage) · \(med.timeOfDay.rawValue)")
                                    .font(Font.SS.caption)
                                    .foregroundColor(Color.SS.textTertiary)
                            }

                            Spacer()

                            SSIconImage(name: "ss.pill", size: 14)
                                .foregroundColor(taken ? Color.SS.success.opacity(0.5) : Color.SS.info)
                        }
                        .padding(.vertical, Spacing.xxs)
                    }
                    .accessibilityLabel(taken ? "\(med.name) taken" : "Mark \(med.name) as taken")
                    .buttonStyle(PlainButtonStyle())
                }
            }
        }
    }

    private func toggleMed(_ med: Medication, taken: Bool) {
        guard !taken else { return }
        let log = MedicationLog(
            id: UUID(),
            medicationId: med.id,
            medicationName: med.name,
            timestamp: Date(),
            taken: true,
            notes: nil
        )
        withAnimation { dataStore.logMedication(log) }
    }
}

// MARK: - Today Summary
struct TodaySummaryCard: View {
    let entries: [SymptomEntry]
    let streak: Int

    var body: some View {
        SSCard(padding: Spacing.md) {
            VStack(spacing: Spacing.md) {
                HStack {
                    Text("Today")
                        .font(Font.SS.labelMedium)
                        .foregroundColor(Color.SS.textTertiary)
                        .tracking(0.5)

                    Spacer()

                    Text(Date(), style: .date)
                        .font(Font.SS.labelSmall)
                        .foregroundColor(Color.SS.textDisabled)
                }

                HStack(spacing: 0) {
                    TodayStatItem(
                        value: "\(entries.count)",
                        label: "Logged",
                        icon: "ss.list",
                        color: Color.SS.accent
                    )

                    Divider()
                        .frame(height: 28)

                    TodayStatItem(
                        value: entries.isEmpty ? "--" : "\(entries.map(\.severity).max() ?? 0)",
                        label: "Peak",
                        icon: "ss.arrow.up",
                        color: Color.SS.warning
                    )

                    Divider()
                        .frame(height: 28)

                    TodayStatItem(
                        value: entries.isEmpty ? "--" : String(format: "%.1f", Double(entries.map(\.severity).reduce(0, +)) / Double(max(entries.count, 1))),
                        label: "Avg",
                        icon: "ss.equal",
                        color: Color.SS.violet
                    )

                    Divider()
                        .frame(height: 28)

                    TodayStatItem(
                        value: "\(streak)",
                        label: "Streak",
                        icon: "ss.flame",
                        color: Color.SS.warning
                    )
                }
            }
        }
    }
}

struct TodayStatItem: View {
    let value: String
    let label: String
    let icon: String
    let color: Color

    var body: some View {
        VStack(spacing: 6) {
            SSIconImage(name: icon, size: 12)
                .foregroundColor(color)

            Text(value)
                .font(Font.SS.dataMedium)
                .foregroundColor(Color.SS.textPrimary)

            Text(label)
                .font(Font.SS.caption)
                .foregroundColor(Color.SS.textTertiary)
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Daily Check-In
struct DailyCheckInCard: View {
    let dataStore: DataStore
    @State private var mood: Int = 0
    @State private var energy: Int = 0
    @State private var sleepHours: Double = 7.0
    @State private var stressLevel: Int = 0
    @State private var waterIntake: Int = 0
    @State private var notes: String = ""
    @State private var saved = false
    @State private var showDetails = false
    @FocusState private var notesFocused: Bool

    private let moodIcons = ["ss.mood.1", "ss.mood.2", "ss.mood.3", "ss.mood.4", "ss.mood.5"]
    private let moodLabels = ["Awful", "Bad", "Okay", "Good", "Great"]
    private let energyLevels = ["Very Low", "Low", "Medium", "High", "Very High"]
    private let stressLabels = ["Low", "Mild", "Medium", "High", "Intense"]

    var body: some View {
        SSAccentCard(accentColor: Color.SS.violet) {
            VStack(alignment: .leading, spacing: Spacing.md) {
                HStack {
                    SSIconImage(name: "ss.sun", size: 14)
                        .foregroundColor(Color.SS.violet)
                    Text("Daily Check-in")
                        .font(Font.SS.labelMedium)
                        .foregroundColor(Color.SS.textSecondary)
                        .tracking(0.5)
                    Spacer()
                    if saved {
                        HStack(spacing: 4) {
                            SSIconImage(name: "ss.checkmark", size: 10)
                                .foregroundColor(Color.SS.success)
                            Text("Saved")
                                .font(Font.SS.labelSmall)
                                .foregroundColor(Color.SS.success)
                        }
                    }
                }

                // Mood
                VStack(alignment: .leading, spacing: Spacing.xs) {
                    Text("How are you feeling?")
                        .font(Font.SS.bodySmall)
                        .foregroundColor(Color.SS.textSecondary)

                    HStack(spacing: Spacing.md) {
                        ForEach(0..<5) { index in
                            Button(action: {
                                SSHaptics.selection()
                                withAnimation { mood = index + 1 }
                                saveIfComplete()
                            }) {
                                VStack(spacing: 4) {
                                    SSIconImage(name: moodIcons[index], size: mood == index + 1 ? 32 : 24)
                                        .foregroundColor(mood == index + 1 ? moodColor(index) : Color.SS.textTertiary)
                                    Text(moodLabels[index])
                                        .font(Font.SS.caption)
                                        .foregroundColor(mood == index + 1 ? moodColor(index) : Color.SS.textDisabled)
                                }
                                .opacity(mood == 0 || mood == index + 1 ? 1 : 0.3)
                            }
                            .accessibilityLabel("Rate mood as \(moodLabels[index])")
                            .buttonStyle(PlainButtonStyle())
                        }
                    }
                }

                // Energy
                VStack(alignment: .leading, spacing: Spacing.xs) {
                    HStack {
                        Text("Energy level")
                            .font(Font.SS.bodySmall)
                            .foregroundColor(Color.SS.textSecondary)
                        Spacer()
                        if energy > 0 {
                            Text(energyLevels[energy - 1])
                                .font(Font.SS.labelSmall)
                                .foregroundColor(Color.SS.accent)
                        }
                    }

                    HStack(spacing: 4) {
                        ForEach(1...5, id: \.self) { level in
                            Button(action: {
                                SSHaptics.selection()
                                withAnimation { energy = level }
                                saveIfComplete()
                            }) {
                                RoundedRectangle(cornerRadius: 3)
                                    .fill(level <= energy ? Color.SS.accent : Color.SS.surfaceTertiary)
                                    .frame(height: 24)
                            }
                            .accessibilityLabel("Set energy to \(energyLevels[level - 1])")
                            .buttonStyle(PlainButtonStyle())
                        }
                    }
                }

                // Expandable details
                Button(action: {
                    SSHaptics.selection()
                    withAnimation(.easeOut(duration: 0.25)) { showDetails.toggle() }
                }) {
                    HStack(spacing: 6) {
                        Text(showDetails ? "Less details" : "More details")
                            .font(Font.SS.labelSmall)
                            .foregroundColor(Color.SS.accent)
                        SSIconImage(name: showDetails ? "ss.chevron.up" : "ss.chevron.down", size: 8)
                            .foregroundColor(Color.SS.accent)
                    }
                }
                .accessibilityLabel(showDetails ? "Show less check-in details" : "Show more check-in details")
                .buttonStyle(PlainButtonStyle())

                if showDetails {
                    VStack(spacing: Spacing.md) {
                        // Sleep hours
                        VStack(alignment: .leading, spacing: Spacing.xs) {
                            HStack {
                                SSIconImage(name: "ss.moon.zzz", size: 14)
                                    .foregroundColor(Color(hex: "818CF8"))
                                Text("Sleep")
                                    .font(Font.SS.bodySmall)
                                    .foregroundColor(Color.SS.textSecondary)
                                Spacer()
                                Text(String(format: "%.1f hrs", sleepHours))
                                    .font(Font.SS.labelSmall)
                                    .foregroundColor(Color(hex: "818CF8"))
                                    .monospacedDigit()
                            }
                            Slider(value: $sleepHours, in: 0...12, step: 0.5)
                                .accessibilityLabel("Sleep hours")
                                .tint(Color(hex: "818CF8"))
                                .onChange(of: sleepHours) { saveIfComplete() }
                        }

                        // Stress level
                        VStack(alignment: .leading, spacing: Spacing.xs) {
                            HStack {
                                SSIconImage(name: "ss.head.brain", size: 14)
                                    .foregroundColor(Color(hex: "F472B6"))
                                Text("Stress")
                                    .font(Font.SS.bodySmall)
                                    .foregroundColor(Color.SS.textSecondary)
                                Spacer()
                                if stressLevel > 0 {
                                    Text(stressLabels[stressLevel - 1])
                                        .font(Font.SS.labelSmall)
                                        .foregroundColor(Color(hex: "F472B6"))
                                }
                            }
                            HStack(spacing: 4) {
                                ForEach(1...5, id: \.self) { level in
                                    Button(action: {
                                        SSHaptics.selection()
                                        withAnimation { stressLevel = level }
                                        saveIfComplete()
                                    }) {
                                        RoundedRectangle(cornerRadius: 3)
                                            .fill(level <= stressLevel ? Color(hex: "F472B6") : Color.SS.surfaceTertiary)
                                            .frame(height: 24)
                                    }
                                    .accessibilityLabel("Set stress to \(stressLabels[level - 1])")
                                    .buttonStyle(PlainButtonStyle())
                                }
                            }
                        }

                        // Water intake
                        VStack(alignment: .leading, spacing: Spacing.xs) {
                            HStack {
                                SSIconImage(name: "ss.drop", size: 14)
                                    .foregroundColor(Color(hex: "60A5FA"))
                                Text("Water")
                                    .font(Font.SS.bodySmall)
                                    .foregroundColor(Color.SS.textSecondary)
                                Spacer()
                                Text("\(waterIntake) glasses")
                                    .font(Font.SS.labelSmall)
                                    .foregroundColor(Color(hex: "60A5FA"))
                                    .monospacedDigit()
                            }
                            HStack(spacing: 6) {
                                ForEach(0..<8, id: \.self) { glass in
                                    Button(action: {
                                        SSHaptics.selection()
                                        withAnimation { waterIntake = glass + 1 }
                                        saveIfComplete()
                                    }) {
                                        RoundedRectangle(cornerRadius: 3)
                                            .fill(glass < waterIntake ? Color(hex: "60A5FA").opacity(0.3 + Double(glass) * 0.1) : Color.SS.surfaceTertiary)
                                            .frame(height: 20)
                                    }
                                    .accessibilityLabel("Set water intake to \(glass + 1) glasses")
                                    .buttonStyle(PlainButtonStyle())
                                }
                            }
                        }

                        // Notes
                        VStack(alignment: .leading, spacing: Spacing.xs) {
                            HStack {
                                SSIconImage(name: "ss.doc", size: 14)
                                    .foregroundColor(Color.SS.textTertiary)
                                Text("Notes")
                                    .font(Font.SS.bodySmall)
                                    .foregroundColor(Color.SS.textSecondary)
                            }
                            TextField("How was your day?", text: $notes, axis: .vertical)
                                .font(Font.SS.bodySmall)
                                .foregroundColor(Color.SS.textPrimary)
                                .lineLimit(2...4)
                                .padding(Spacing.sm)
                                .background(
                                    RoundedRectangle(cornerRadius: Radius.sm)
                                        .fill(Color.SS.surfaceTertiary)
                                )
                                .focused($notesFocused)
                                .onSubmit {
                                    notesFocused = false
                                    saveIfComplete()
                                }
                                .onChange(of: notesFocused) {
                                    if !notesFocused { saveIfComplete() }
                                }
                        }
                    }
                    .transition(.opacity.combined(with: .move(edge: .top)))
                }
            }
        }
        .onAppear { loadExistingCheckin() }
    }

    private func moodColor(_ index: Int) -> Color {
        switch index {
        case 0: return Color.SS.severityCritical
        case 1: return Color.SS.severitySevere
        case 2: return Color.SS.severityModerate
        case 3: return Color.SS.severityMild
        default: return Color.SS.success
        }
    }

    private func loadExistingCheckin() {
        if let summary = dataStore.summaryForDate(Date()) {
            mood = summary.overallMood
            energy = summary.overallEnergy
            sleepHours = summary.sleepHours ?? 7.0
            stressLevel = summary.stressLevel ?? 0
            waterIntake = summary.waterIntake ?? 0
            notes = summary.notes ?? ""
            saved = true
        } else if let hkSleep = dataStore.latestHealthKitSleep() {
            // Auto-fill from HealthKit when no manual entry exists yet
            sleepHours = round(hkSleep * 2) / 2 // Round to nearest 0.5 to match slider step
        }
    }

    private func saveIfComplete() {
        guard mood > 0 && energy > 0 else { return }
        let summary = DailySummary(
            id: UUID(),
            date: Date(),
            overallMood: mood,
            overallEnergy: energy,
            entries: dataStore.entriesForDate(Date()),
            notes: notes.isEmpty ? nil : notes,
            sleepHours: sleepHours,
            stressLevel: stressLevel > 0 ? stressLevel : nil,
            waterIntake: waterIntake > 0 ? waterIntake : nil
        )
        dataStore.saveDailySummary(summary)
        SSHaptics.success()
        withAnimation { saved = true }
    }
}

// MARK: - Symptom Entry Row
struct SymptomEntryRow: View {
    let entry: SymptomEntry
    @State private var showDetail = false

    var body: some View {
        Button(action: {
            SSHaptics.light()
            showDetail = true
        }) {
            SSCard(padding: Spacing.sm) {
                HStack(spacing: Spacing.sm) {
                    Circle()
                        .fill(severityColor)
                        .frame(width: 8, height: 8)

                    VStack(alignment: .leading, spacing: 2) {
                        Text(entry.symptomName)
                            .font(Font.SS.bodyMedium)
                            .foregroundColor(Color.SS.textPrimary)

                        HStack(spacing: Spacing.xs) {
                            Text(entry.timestamp, style: .time)
                                .font(Font.SS.labelSmall)
                                .foregroundColor(Color.SS.textTertiary)

                            if let duration = entry.duration {
                                Text("· \(duration.rawValue)")
                                    .font(Font.SS.labelSmall)
                                    .foregroundColor(Color.SS.textTertiary)
                            }
                        }
                    }

                    Spacer()

                    Text("\(entry.severity)/10")
                        .font(Font.SS.dataSmall)
                        .foregroundColor(severityColor)

                    SSIconImage(name: "ss.chevron.right", size: 10)
                        .foregroundColor(Color.SS.textDisabled)
                }
            }
        }
        .accessibilityLabel("View \(entry.symptomName) entry, severity \(entry.severity) out of 10")
        .buttonStyle(PlainButtonStyle())
        .sheet(isPresented: $showDetail) {
            SymptomDetailView(entry: entry)
                .presentationDetents([.large])
                .presentationDragIndicator(.visible)
                .presentationBackground(Color.SS.surfacePrimary)
        }
    }

    private var severityColor: Color {
        switch entry.severity {
        case 1...3: return Color.SS.severityMild
        case 4...6: return Color.SS.severityModerate
        case 7...8: return Color.SS.severitySevere
        default: return Color.SS.severityCritical
        }
    }
}

// MARK: - Wellness Chart Card
struct WellnessChartCard: View {
    @ObservedObject var engine: WellnessScoreEngine
    @State private var animateChart = false

    var body: some View {
        SSCard(padding: Spacing.md) {
            VStack(alignment: .leading, spacing: Spacing.sm) {
                // Header
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Wellness Score")
                            .font(Font.SS.labelMedium)
                            .foregroundColor(Color.SS.textTertiary)
                            .tracking(0.5)

                        HStack(alignment: .firstTextBaseline, spacing: 4) {
                            Text("\(Int(engine.currentScore))")
                                .font(Font.SS.dataLarge)
                                .foregroundColor(scoreColor)
                                .contentTransition(.numericText())

                            Text("/100")
                                .font(Font.SS.labelSmall)
                                .foregroundColor(Color.SS.textDisabled)
                        }
                    }

                    Spacer()

                    // Trend badge
                    if engine.weeklyScores.count >= 2 {
                        let delta = engine.weeklyScores.last!.score - engine.weeklyScores.first!.score
                        HStack(spacing: 4) {
                            SSIconImage(name: delta >= 0 ? "ss.arrow.up" : "ss.arrow.downright", size: 10)
                            Text(delta >= 0 ? "+\(Int(delta))" : "\(Int(delta))")
                                .font(Font.SS.labelSmall)
                                .monospacedDigit()
                        }
                        .foregroundColor(delta >= 0 ? Color.SS.success : Color.SS.warning)
                        .padding(.horizontal, Spacing.xs)
                        .padding(.vertical, Spacing.xxs)
                        .background(
                            Capsule()
                                .fill((delta >= 0 ? Color.SS.success : Color.SS.warning).opacity(0.1))
                        )
                    }
                }

                // Chart
                GeometryReader { geo in
                    let scores = engine.weeklyScores
                    if scores.count >= 2 {
                        let points = scores.map { $0.score }
                        let minVal = max(0, (points.min() ?? 0) - 10)
                        let maxVal = min(100, (points.max() ?? 100) + 10)
                        let range = max(maxVal - minVal, 1)

                        ZStack {
                            // Gradient fill under curve
                            SmoothedPath(
                                points: points,
                                minVal: minVal,
                                range: range,
                                size: geo.size,
                                closed: true
                            )
                            .fill(
                                LinearGradient(
                                    colors: [
                                        Color.SS.accent.opacity(0.18),
                                        Color.SS.violet.opacity(0.08),
                                        Color.SS.accent.opacity(0.02)
                                    ],
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                            )
                            .opacity(animateChart ? 1 : 0)

                            // Smoothed line
                            SmoothedPath(
                                points: points,
                                minVal: minVal,
                                range: range,
                                size: geo.size,
                                closed: false
                            )
                            .stroke(
                                LinearGradient(
                                    colors: [Color.SS.accent, Color.SS.violet],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                ),
                                style: StrokeStyle(lineWidth: 2.5, lineCap: .round, lineJoin: .round)
                            )
                            .opacity(animateChart ? 1 : 0)

                            // Data points
                            ForEach(Array(points.enumerated()), id: \.offset) { index, value in
                                let x = geo.size.width * CGFloat(index) / CGFloat(max(points.count - 1, 1))
                                let y = geo.size.height - ((CGFloat(value) - CGFloat(minVal)) / CGFloat(range) * geo.size.height)

                                ZStack {
                                    Circle()
                                        .fill(Color.SS.surfacePrimary)
                                        .frame(width: 8, height: 8)
                                    Circle()
                                        .fill(dotColor(value))
                                        .frame(width: 5, height: 5)
                                }
                                .position(x: x, y: y)
                                .opacity(animateChart ? 1 : 0)
                            }
                        }
                    } else {
                        VStack {
                            Spacer()
                            Text("Log symptoms to see your wellness trend")
                                .font(Font.SS.bodySmall)
                                .foregroundColor(Color.SS.textDisabled)
                                .frame(maxWidth: .infinity)
                            Spacer()
                        }
                    }
                }
                .frame(height: 130)

                // Day labels
                if engine.weeklyScores.count >= 2 {
                    HStack {
                        ForEach(engine.weeklyScores) { day in
                            Text(day.label)
                                .font(Font.SS.caption)
                                .foregroundColor(Color.SS.textDisabled)
                            if day.id != engine.weeklyScores.last?.id { Spacer() }
                        }
                    }
                }
            }
        }
        .onAppear {
            withAnimation(.easeOut(duration: 0.8).delay(0.2)) {
                animateChart = true
            }
        }
    }

    private var scoreColor: Color {
        switch Int(engine.currentScore) {
        case 0..<30: return Color.SS.error
        case 30..<50: return Color.SS.warning
        case 50..<70: return Color.SS.accent
        case 70..<85: return Color.SS.success
        default: return Color.SS.success
        }
    }

    private func dotColor(_ score: Double) -> Color {
        switch Int(score) {
        case 0..<30: return Color.SS.error
        case 30..<50: return Color.SS.warning
        case 50..<70: return Color.SS.accent
        default: return Color.SS.success
        }
    }
}

// MARK: - Baseline Score Card
// MARK: - Catmull-Rom Smoothed Path
struct SmoothedPath: Shape {
    let points: [Double]
    let minVal: Double
    let range: Double
    let size: CGSize
    let closed: Bool

    func path(in rect: CGRect) -> Path {
        guard points.count >= 2 else { return Path() }

        var path = Path()
        let cgPoints = points.enumerated().map { index, value -> CGPoint in
            let x = size.width * CGFloat(index) / CGFloat(max(points.count - 1, 1))
            let y = size.height - ((CGFloat(value) - CGFloat(minVal)) / CGFloat(range) * size.height)
            return CGPoint(x: x, y: y)
        }

        // Catmull-Rom spline interpolation
        path.move(to: cgPoints[0])

        for i in 0..<cgPoints.count - 1 {
            let p0 = i > 0 ? cgPoints[i - 1] : cgPoints[i]
            let p1 = cgPoints[i]
            let p2 = cgPoints[i + 1]
            let p3 = i + 2 < cgPoints.count ? cgPoints[i + 2] : cgPoints[i + 1]

            let tension: CGFloat = 0.3

            let cp1 = CGPoint(
                x: p1.x + (p2.x - p0.x) * tension,
                y: p1.y + (p2.y - p0.y) * tension
            )
            let cp2 = CGPoint(
                x: p2.x - (p3.x - p1.x) * tension,
                y: p2.y - (p3.y - p1.y) * tension
            )

            path.addCurve(to: p2, control1: cp1, control2: cp2)
        }

        if closed {
            // Close with vertical lines to bottom
            path.addLine(to: CGPoint(x: cgPoints.last!.x, y: size.height))
            path.addLine(to: CGPoint(x: cgPoints.first!.x, y: size.height))
            path.closeSubpath()
        }

        return path
    }
}

// MARK: - HealthKit Data Card
struct HealthDataCard: View {
    @ObservedObject var healthKit: HealthKitManager

    var body: some View {
        SSCard(padding: Spacing.md) {
            VStack(alignment: .leading, spacing: Spacing.sm) {
                HStack {
                    SSIconImage(name: "ss.heart", size: 14)
                        .foregroundColor(Color(hex: "EF4444"))
                    Text("Apple Health")
                        .font(Font.SS.labelMedium)
                        .foregroundColor(Color.SS.textTertiary)
                        .tracking(0.5)
                    Spacer()
                    Text("Today")
                        .font(Font.SS.caption)
                        .foregroundColor(Color.SS.textDisabled)
                }

                HStack(spacing: 0) {
                    HealthMetricItem(
                        icon: "ss.moon.zzz",
                        value: healthKit.sleepHours.map { String(format: "%.1f", $0) } ?? "--",
                        unit: "hrs",
                        label: "Sleep",
                        color: Color(hex: "818CF8")
                    )

                    Divider().frame(height: 32)

                    HealthMetricItem(
                        icon: "ss.heart",
                        value: healthKit.heartRate.map { "\(Int($0))" } ?? "--",
                        unit: "bpm",
                        label: "Heart Rate",
                        color: Color(hex: "EF4444")
                    )

                    Divider().frame(height: 32)

                    HealthMetricItem(
                        icon: "ss.figure.walk",
                        value: healthKit.stepCount.map { formatSteps($0) } ?? "--",
                        unit: "",
                        label: "Steps",
                        color: Color(hex: "34D399")
                    )

                    Divider().frame(height: 32)

                    HealthMetricItem(
                        icon: "ss.figure.run",
                        value: healthKit.activeMinutes.map { "\($0)" } ?? "--",
                        unit: "min",
                        label: "Exercise",
                        color: Color(hex: "FBBF24")
                    )
                }
            }
        }
    }

    private func formatSteps(_ count: Int) -> String {
        if count >= 1000 {
            return String(format: "%.1fk", Double(count) / 1000.0)
        }
        return "\(count)"
    }
}

struct HealthMetricItem: View {
    let icon: String
    let value: String
    let unit: String
    let label: String
    let color: Color

    var body: some View {
        VStack(spacing: 4) {
            SSIconImage(name: icon, size: 12)
                .foregroundColor(color)
            HStack(spacing: 2) {
                Text(value)
                    .font(Font.SS.dataSmall)
                    .foregroundColor(Color.SS.textPrimary)
                    .monospacedDigit()
                if !unit.isEmpty {
                    Text(unit)
                        .font(Font.SS.caption)
                        .foregroundColor(Color.SS.textDisabled)
                }
            }
            Text(label)
                .font(Font.SS.caption)
                .foregroundColor(Color.SS.textTertiary)
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Weather Card
struct WeatherCard: View {
    @ObservedObject var weatherService: WeatherService

    var body: some View {
        SSCard(padding: Spacing.md) {
            VStack(alignment: .leading, spacing: Spacing.sm) {
                HStack {
                    SSIconImage(name: weatherService.weatherIcon, size: 14)
                        .foregroundColor(Color(hex: "60A5FA"))
                    Text("Weather")
                        .font(Font.SS.labelMedium)
                        .foregroundColor(Color.SS.textTertiary)
                        .tracking(0.5)
                    Spacer()
                    Text(weatherService.weatherDescription)
                        .font(Font.SS.caption)
                        .foregroundColor(Color.SS.textSecondary)
                }

                HStack(spacing: 0) {
                    HealthMetricItem(
                        icon: "ss.sun",
                        value: weatherService.temperature.map { "\(Int($0))°" } ?? "--",
                        unit: "",
                        label: "Temp",
                        color: Color(hex: "F59E0B")
                    )

                    Divider().frame(height: 32)

                    HealthMetricItem(
                        icon: "ss.drop",
                        value: weatherService.humidity.map { "\($0)%" } ?? "--",
                        unit: "",
                        label: "Humidity",
                        color: Color(hex: "60A5FA")
                    )

                    Divider().frame(height: 32)

                    HealthMetricItem(
                        icon: "ss.wind",
                        value: weatherService.pressure.map { "\(Int($0))" } ?? "--",
                        unit: "hPa",
                        label: "Pressure",
                        color: Color(hex: "818CF8")
                    )
                }
            }
        }
    }
}

// MARK: - Flare-Up Banner
struct FlareUpBanner: View {
    let alert: FlareUpAlert
    var onTap: (() -> Void)? = nil
    let onDismiss: () -> Void
    @State private var appeared = false

    private var accentColor: Color {
        alert.severity.color
    }

    var body: some View {
        SSCard(padding: 0, cornerRadius: Radius.lg) {
            HStack(alignment: .top, spacing: Spacing.sm) {
                // Severity indicator bar
                RoundedRectangle(cornerRadius: 2)
                    .fill(accentColor)
                    .frame(width: 4)

                // Icon
                ZStack {
                    Circle()
                        .fill(accentColor.opacity(0.12))
                        .frame(width: 36, height: 36)

                    SSIconImage(name: "ss.flame", size: 18)
                        .foregroundColor(accentColor)
                        .scaleEffect(appeared ? 1.0 : 0.6)
                }
                .padding(.top, Spacing.xxs)

                // Content
                VStack(alignment: .leading, spacing: Spacing.xxs) {
                    HStack(spacing: Spacing.xs) {
                        Text("Flare-Up Detected")
                            .font(Font.SS.accentSmall)
                            .foregroundColor(accentColor)

                        SSChip(
                            label: alert.severity.rawValue,
                            color: accentColor,
                            isSelected: true
                        )
                    }

                    Text(alert.message)
                        .font(Font.SS.bodySmall)
                        .foregroundColor(Color.SS.textSecondary)
                        .lineSpacing(3)
                        .fixedSize(horizontal: false, vertical: true)

                    // Delta stat
                    HStack(spacing: Spacing.xxs) {
                        SSIconImage(name: "ss.arrow.up", size: 8)
                            .foregroundColor(accentColor)
                        Text("+\(String(format: "%.1f", alert.severityDelta)) vs baseline")
                            .font(Font.SS.caption)
                            .foregroundColor(Color.SS.textTertiary)
                            .monospacedDigit()
                    }
                    .padding(.top, Spacing.xxxs)

                    // Tap to view details
                    if onTap != nil {
                        HStack(spacing: 4) {
                            Text("Prepare for your visit")
                                .font(Font.SS.labelSmall)
                                .foregroundColor(accentColor)
                            SSIconImage(name: "ss.chevron.right", size: 8)
                                .foregroundColor(accentColor)
                        }
                        .padding(.top, Spacing.xxs)
                    }
                }

                Spacer(minLength: 0)

                // Dismiss button
                Button(action: {
                    SSHaptics.light()
                    onDismiss()
                }) {
                    SSIconImage(name: "ss.xmark", size: 10)
                        .foregroundColor(Color.SS.textTertiary)
                        .frame(width: 28, height: 28)
                        .background(Color.SS.surfaceSecondary)
                        .clipShape(Circle())
                }
                .accessibilityLabel("Dismiss flare-up alert")
                .buttonStyle(PlainButtonStyle())
                .padding(.top, Spacing.xxs)
            }
            .padding(Spacing.md)
        }
        .overlay(
            RoundedRectangle(cornerRadius: Radius.lg)
                .strokeBorder(accentColor.opacity(0.20), lineWidth: 1)
        )
        .onTapGesture {
            if let onTap = onTap {
                SSHaptics.light()
                onTap()
            }
        }
        .accessibilityLabel("View flare-up details and prepare for doctor visit")
        .onAppear {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
                appeared = true
            }
        }
    }
}

// MARK: - First-Launch Permissions Sheet
struct PermissionsSheet: View {
    @ObservedObject var healthKitManager: HealthKitManager
    @ObservedObject var notificationManager: NotificationManager
    @State private var healthEnabled = false
    @State private var notificationsEnabled = false
    @State private var step = 0 // 0 = intro, 1 = choosing, 2 = done
    @Environment(\.dismiss) var dismiss
    let onDone: () -> Void

    var body: some View {
        VStack(spacing: Spacing.xl) {
            // Handle
            Capsule()
                .fill(Color.SS.separatorStrong)
                .frame(width: 36, height: 4)
                .padding(.top, Spacing.sm)

            if step == 0 {
                introView
            } else if step == 1 {
                permissionsView
            } else {
                doneView
            }
        }
        .padding(.horizontal, Spacing.xl)
        .animation(.easeInOut(duration: 0.3), value: step)
    }

    private var introView: some View {
        VStack(spacing: Spacing.lg) {
            ZStack {
                Circle()
                    .fill(Color.SS.accentSubtle)
                    .frame(width: 80, height: 80)
                SSIconImage(name: "ss.sparkles", size: 32)
                    .foregroundStyle(Color.SS.gradientPrimary)
            }

            VStack(spacing: Spacing.xs) {
                Text("Make Symptly smarter")
                    .font(Font.SS.headlineMedium)
                    .foregroundColor(Color.SS.textPrimary)

                Text("A couple quick permissions help us give you better insights and timely reminders.")
                    .font(Font.SS.bodySmall)
                    .foregroundColor(Color.SS.textSecondary)
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)
            }

            SSButton(title: "Let's go", style: .primary) {
                withAnimation { step = 1 }
            }

            Button("Skip for now") {
                onDone()
                dismiss()
            }
            .font(Font.SS.labelMedium)
            .foregroundColor(Color.SS.textTertiary)
        }
    }

    private var permissionsView: some View {
        VStack(spacing: Spacing.lg) {
            VStack(spacing: Spacing.xs) {
                Text("Enable features")
                    .font(Font.SS.headlineMedium)
                    .foregroundColor(Color.SS.textPrimary)

                Text("You can change these anytime in Settings.")
                    .font(Font.SS.bodySmall)
                    .foregroundColor(Color.SS.textTertiary)
            }

            // HealthKit permission card
            PermissionRow(
                icon: "ss.heart",
                iconColor: Color(hex: "EF4444"),
                title: "Apple Health",
                subtitle: "Import sleep, heart rate, steps & exercise to correlate with your symptoms",
                isEnabled: $healthEnabled,
                action: {
                    Task {
                        await healthKitManager.requestAuthorization()
                        healthEnabled = healthKitManager.isAuthorized
                    }
                }
            )

            // Notifications permission card
            PermissionRow(
                icon: "ss.bell.badge",
                iconColor: Color.SS.accent,
                title: "Notifications",
                subtitle: "Daily check-in reminders, medication alerts & streak nudges",
                isEnabled: $notificationsEnabled,
                action: {
                    Task {
                        await notificationManager.requestAuthorization()
                        notificationsEnabled = notificationManager.isAuthorized
                    }
                }
            )

            Spacer()

            SSButton(title: "Continue", style: .primary) {
                withAnimation { step = 2 }
            }
        }
    }

    private var doneView: some View {
        VStack(spacing: Spacing.lg) {
            ZStack {
                Circle()
                    .fill(Color.SS.success.opacity(0.12))
                    .frame(width: 80, height: 80)
                SSIconImage(name: "ss.checkmark", size: 28)
                    .foregroundColor(Color.SS.success)
            }

            VStack(spacing: Spacing.xs) {
                Text("You're all set!")
                    .font(Font.SS.headlineMedium)
                    .foregroundColor(Color.SS.textPrimary)

                Text(healthEnabled || notificationsEnabled
                     ? "Your experience is now personalized. Start logging to unlock AI insights."
                     : "You can enable Health & Notifications anytime in Settings.")
                    .font(Font.SS.bodySmall)
                    .foregroundColor(Color.SS.textSecondary)
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)
            }

            SSButton(title: "Start tracking", style: .primary) {
                onDone()
                dismiss()
            }
        }
    }
}

// MARK: - Permission Row
struct PermissionRow: View {
    let icon: String
    let iconColor: Color
    let title: String
    let subtitle: String
    @Binding var isEnabled: Bool
    let action: () -> Void

    var body: some View {
        SSCard(padding: Spacing.md) {
            HStack(spacing: Spacing.md) {
                ZStack {
                    Circle()
                        .fill(iconColor.opacity(0.12))
                        .frame(width: 44, height: 44)
                    SSIconImage(name: icon, size: 18)
                        .foregroundColor(iconColor)
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(Font.SS.bodyMedium)
                        .foregroundColor(Color.SS.textPrimary)
                    Text(subtitle)
                        .font(Font.SS.caption)
                        .foregroundColor(Color.SS.textTertiary)
                        .lineSpacing(2)
                }

                Spacer()

                Button(action: {
                    SSHaptics.selection()
                    action()
                }) {
                    Text(isEnabled ? "Enabled" : "Enable")
                        .font(Font.SS.labelMedium)
                        .foregroundColor(isEnabled ? Color.SS.success : .white)
                        .padding(.horizontal, Spacing.sm)
                        .padding(.vertical, 6)
                        .background(
                            Capsule()
                                .fill(isEnabled ? Color.SS.success.opacity(0.12) : Color.SS.accent)
                        )
                }
                .disabled(isEnabled)
                .accessibilityLabel(isEnabled ? "\(title) enabled" : "Enable \(title)")
            }
        }
    }
}
