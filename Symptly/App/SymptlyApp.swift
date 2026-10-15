import SwiftUI
import SwiftData

@main
struct SymptlyApp: App {
    let container: ModelContainer
    @StateObject private var appState = AppState()
    @StateObject private var subscriptionManager = SubscriptionManager()
    @StateObject private var healthKitManager = HealthKitManager()
    @StateObject private var notificationManager = NotificationManager()
    @StateObject private var dataStore: DataStore
    @StateObject private var weatherService = WeatherService()
    private let colorScheme: ColorScheme? = .light

    init() {
        let schema = Schema([
            PersistedOnboardingProfile.self,
            PersistedSymptomEntry.self,
            PersistedDailySummary.self,
            PersistedMedication.self,
            PersistedMedicationLog.self,
            PersistedWeatherSnapshot.self,
            PersistedHealthSnapshot.self,
            PersistedCustomSymptom.self,
            PersistedJournalEntry.self
        ])
        let config = ModelConfiguration(
            schema: schema,
            cloudKitDatabase: .automatic
        )
        let modelContainer: ModelContainer
        do {
            modelContainer = try ModelContainer(for: schema, configurations: config)
        } catch {
            fatalError("Failed to initialize SwiftData container: \(error.localizedDescription)")
        }
        self.container = modelContainer
        _dataStore = StateObject(wrappedValue: DataStore(modelContext: modelContainer.mainContext))
    }

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(appState)
                .environmentObject(subscriptionManager)
                .environmentObject(healthKitManager)
                .environmentObject(notificationManager)
                .environmentObject(dataStore)
                .environmentObject(weatherService)
                .preferredColorScheme(colorScheme)
                .onReceive(subscriptionManager.$purchasedProductIDs) { ids in
                    if !ids.isEmpty && !appState.hasActiveSubscription {
                        appState.activateSubscription()
                    } else if ids.isEmpty && appState.hasActiveSubscription {
                        // Subscription expired or was revoked: lock access
                        appState.hasActiveSubscription = false
                        UserDefaults.standard.set(false, forKey: "hasActiveSubscription")
                        appState.determineFlow()
                    }
                }
                .onAppear {
                    // Sync onboarding answers from CloudKit if local is empty
                    if appState.onboardingAnswers.isEmpty,
                       let cloudAnswers = dataStore.loadOnboardingAnswers() {
                        appState.onboardingAnswers = cloudAnswers
                        if !appState.hasCompletedOnboarding {
                            appState.hasCompletedOnboarding = true
                            UserDefaults.standard.set(true, forKey: "hasCompletedOnboarding")
                            appState.determineFlow()
                        }
                    }
                }
                .onReceive(NotificationCenter.default.publisher(for: UIApplication.willEnterForegroundNotification)) { _ in
                    // Re-check subscription status every time app comes to foreground
                    Task { await subscriptionManager.refreshSubscriptionStatus() }
                }
        }
        .modelContainer(container)
    }
}
