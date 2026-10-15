import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var dataStore: DataStore
    @EnvironmentObject var healthKitManager: HealthKitManager
    @EnvironmentObject var notificationManager: NotificationManager
    @AppStorage("notificationsEnabled") private var notificationsEnabled = true
    @AppStorage("healthKitEnabled") private var healthKitEnabled = true
    private let appearanceMode: Int = 1
    @State private var reminderTime = Date()
    @State private var showResetAlert = false
    @State private var showExportSheet = false
    @State private var showPrivacyPolicy = false
    @State private var showTerms = false
    @State private var showHelpCenter = false
    @State private var showContactSupport = false
    @State private var showRatePrompt = false
    @State private var showImportPicker = false
    @State private var showDeleteDataAlert = false
    @State private var showPaywall = false

    var body: some View {
        ZStack {
            Color.SS.background.ignoresSafeArea()

            VStack(spacing: 0) {
                SSNavigationBar(title: "Settings")

                ScrollView(showsIndicators: false) {
                    VStack(spacing: Spacing.xl) {
                        // Profile card
                        ProfileCard()
                            .padding(.horizontal, Spacing.xl)

                        // Subscription status
                        SubscriptionStatusCard(showPaywall: $showPaywall)
                            .padding(.horizontal, Spacing.xl)

                        // Tracking section
                        SettingsSection(title: "TRACKING") {
                            SettingsToggleRow(
                                icon: "ss.bell.badge",
                                title: "Reminders",
                                subtitle: "Daily logging prompts",
                                isOn: $notificationsEnabled,
                                color: Color.SS.accent
                            )

                            if notificationsEnabled {
                                SettingsDateRow(
                                    icon: "ss.clock",
                                    title: "Reminder Time",
                                    date: $reminderTime,
                                    color: Color.SS.violet
                                )
                            }

                            SettingsToggleRow(
                                icon: "ss.cat.mental",
                                title: "Apple Health",
                                subtitle: "Sync sleep, activity, heart rate",
                                isOn: $healthKitEnabled,
                                color: Color(hex: "EF4444")
                            )
                        }

                        // Privacy section
                        SettingsSection(title: "PRIVACY & SECURITY") {
                            SettingsNavRow(
                                icon: "ss.hand.raised",
                                title: "Privacy Policy",
                                color: Color.SS.textSecondary
                            ) {
                                SSHaptics.selection()
                                showPrivacyPolicy = true
                            }

                            SettingsNavRow(
                                icon: "ss.doc",
                                title: "Terms of Service",
                                color: Color.SS.textSecondary
                            ) {
                                SSHaptics.selection()
                                showTerms = true
                            }
                        }

                        // Data section
                        SettingsSection(title: "DATA") {
                            SettingsNavRow(
                                icon: "ss.export",
                                title: "Export Data",
                                subtitle: "Download as CSV",
                                color: Color.SS.accent
                            ) {
                                SSHaptics.light()
                                showExportSheet = true
                            }

                            SettingsNavRow(
                                icon: "ss.trash",
                                title: "Clear All Data",
                                subtitle: "\(dataStore.entries.count) entries",
                                color: Color.SS.error
                            ) {
                                SSHaptics.medium()
                                showDeleteDataAlert = true
                            }
                        }

                        // Support section
                        SettingsSection(title: "SUPPORT") {
                            SettingsNavRow(
                                icon: "ss.question",
                                title: "Help Center",
                                color: Color.SS.textSecondary
                            ) {
                                SSHaptics.selection()
                                showHelpCenter = true
                            }

                            SettingsNavRow(
                                icon: "ss.envelope",
                                title: "Contact Support",
                                color: Color.SS.textSecondary
                            ) {
                                SSHaptics.selection()
                                showContactSupport = true
                            }

                            SettingsNavRow(
                                icon: "ss.star",
                                title: "Rate the App",
                                color: Color.SS.warning
                            ) {
                                SSHaptics.selection()
                                requestAppReview()
                            }
                        }

                        // Danger zone
                        SettingsSection(title: "ACCOUNT") {
                            Button(action: {
                                SSHaptics.medium()
                                showResetAlert = true
                            }) {
                                HStack {
                                    SSIconImage(name: "ss.trash", size: 16)
                                        .foregroundColor(Color.SS.error)
                                        .frame(width: 28)
                                    Text("Reset App")
                                        .font(Font.SS.bodyMedium)
                                        .foregroundColor(Color.SS.error)
                                    Spacer()
                                }
                                .padding(.vertical, Spacing.sm)
                            }
                        }

                        // Debug / Preview
                        SettingsSection(title: "PREVIEW") {
                            SettingsNavRow(
                                icon: "ss.crown",
                                title: "Preview Paywall",
                                subtitle: "View subscription screen",
                                color: Color.SS.accent
                            ) {
                                SSHaptics.selection()
                                showPaywall = true
                            }
                        }

                        // Onboarding
                        SettingsSection(title: "ABOUT YOU") {
                            SettingsNavRow(
                                icon: "ss.person",
                                title: "Redo Onboarding",
                                subtitle: "Recalculate your baseline",
                                color: Color.SS.accent
                            ) {
                                SSHaptics.selection()
                                appState.resetOnboarding()
                            }
                        }

                        // App version
                        VStack(spacing: Spacing.xs) {
                            SSIconImage(name: "ss.ecg", size: 20)
                                .foregroundStyle(Color.SS.gradientPrimary)
                            Text("Symptly")
                                .font(Font.SS.labelMedium)
                                .foregroundColor(Color.SS.textTertiary)
                            Text("Version 1.0.0 (1)")
                                .font(Font.SS.caption)
                                .foregroundColor(Color.SS.textDisabled)
                            Text("Made with care for your health")
                                .font(Font.SS.caption)
                                .foregroundColor(Color.SS.textDisabled)
                                .padding(.top, Spacing.xxs)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.top, Spacing.md)

                        Spacer(minLength: 120)
                    }
                }
            }
        }
        .alert("Reset App", isPresented: $showResetAlert) {
            Button("Cancel", role: .cancel) {}
            Button("Reset", role: .destructive) {
                dataStore.clearAllData()
                appState.resetApp()
            }
        } message: {
            Text("This will erase all data and restart from onboarding. Your subscription stays active through your Apple ID.")
        }
        .alert("Clear All Data", isPresented: $showDeleteDataAlert) {
            Button("Cancel", role: .cancel) {}
            Button("Clear", role: .destructive) {
                dataStore.clearAllData()
                SSHaptics.success()
            }
        } message: {
            Text("This will delete all \(dataStore.entries.count) symptom entries, journals, medications, and check-ins. This cannot be undone.")
        }
        .sheet(isPresented: $showExportSheet) {
            ShareSheet(items: [dataStore.exportCSV()])
        }
        .sheet(isPresented: $showPrivacyPolicy) {
            InfoSheetView(title: "Privacy Policy", content: privacyPolicyText)
        }
        .sheet(isPresented: $showTerms) {
            InfoSheetView(title: "Terms of Service", content: termsOfServiceText)
        }
        .sheet(isPresented: $showHelpCenter) {
            InfoSheetView(title: "Help Center", content: helpCenterText)
        }
        .sheet(isPresented: $showContactSupport) {
            InfoSheetView(title: "Contact Support", content: contactSupportText)
        }
        .onChange(of: notificationsEnabled) {
            Task {
                if notificationsEnabled {
                    await notificationManager.requestAuthorization()
                    if notificationManager.isAuthorized {
                        await notificationManager.scheduleDailyReminder(at: reminderTime)
                        await notificationManager.scheduleStreakReminder()
                    }
                } else {
                    notificationManager.cancelAllNotifications()
                }
            }
        }
        .onChange(of: reminderTime) {
            if notificationsEnabled {
                Task {
                    await notificationManager.scheduleDailyReminder(at: reminderTime)
                }
            }
        }
        .onChange(of: healthKitEnabled) {
            Task {
                if healthKitEnabled {
                    await healthKitManager.requestAuthorization()
                } // HealthKit doesn't support revoking, user must disable in Settings.app
            }
        }
        .sheet(isPresented: $showPaywall) {
            PaywallView()
        }
        .onAppear {
            notificationManager.registerCategories()
        }
    }

    private func requestAppReview() {
        #if canImport(UIKit)
        if let scene = UIApplication.shared.connectedScenes.first(where: { $0.activationState == .foregroundActive }) as? UIWindowScene {
            SKStoreReviewController.requestReview(in: scene)
        }
        #endif
    }

    private var privacyPolicyText: String {
        """
        Symptly Privacy Policy

        Your health data stays on your device. We do not transmit, store, or share any symptom data with third parties.

        Data Storage: All symptom entries, daily check-ins, and personal information are stored locally on your device using encrypted storage.

        HealthKit: If enabled, we read sleep, heart rate, steps, and exercise data from Apple Health. This data is only used locally for insights and is never uploaded.

        Analytics: We collect anonymous usage analytics (screen views, feature usage) to improve the app. No personal or health data is included.

        Contact: keshav-krishnan@outlook.com
        """
    }

    private var termsOfServiceText: String {
        """
        Symptly Terms of Service

        Symptly is a health tracking tool, not a medical device. It is not intended to diagnose, treat, cure, or prevent any disease.

        Always consult a qualified healthcare provider for medical advice. Do not rely solely on this app for health decisions.

        By using Symptly, you agree to these terms and acknowledge that the app provides informational insights only.

        Subscriptions auto-renew unless cancelled at least 24 hours before the end of the current period. Manage subscriptions in your Apple ID settings.
        """
    }

    private var helpCenterText: String {
        """
        Help Center

        Getting Started
        Tap the + button to log your first symptom. Select the symptom, rate its severity, add optional details, and save.

        Daily Check-In
        The home screen includes a daily check-in for mood and energy. Both must be selected to save.

        History
        View all past entries in the History tab. Swipe left on any entry to delete it. Use time filters to narrow your view.

        Insights
        The Insights tab shows patterns, correlations, and trends based on your logged data. More entries lead to better insights.

        Export
        Export your data as CSV from Settings > Data > Export Data. Share the file with your healthcare provider.
        """
    }

    private var contactSupportText: String {
        """
        Contact Support

        Email: keshav-krishnan@outlook.com

        Response time: We aim to respond within 24 hours.

        When contacting support, please include:
        - Your device model
        - iOS version
        - A description of the issue

        For urgent matters, please visit our website at keshav-krishnan@outlook.com.
        """
    }
}

// MARK: - Info Sheet
struct InfoSheetView: View {
    @Environment(\.dismiss) var dismiss
    let title: String
    let content: String

    var body: some View {
        NavigationStack {
            ZStack {
                Color.SS.background.ignoresSafeArea()

                ScrollView(showsIndicators: false) {
                    Text(content)
                        .font(Font.SS.bodyMedium)
                        .foregroundColor(Color.SS.textSecondary)
                        .lineSpacing(6)
                        .padding(Spacing.xl)
                }
            }
            .navigationTitle(title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { dismiss() }
                        .foregroundColor(Color.SS.accent)
                }
            }
        }
    }
}

// MARK: - StoreKit Import
#if canImport(StoreKit)
import StoreKit
#endif

// MARK: - Profile Card
struct ProfileCard: View {
    @EnvironmentObject var appState: AppState

    var body: some View {
        SSCard(padding: Spacing.md) {
            HStack(spacing: Spacing.md) {
                ZStack {
                    Circle()
                        .fill(Color.SS.gradientPrimary)
                        .frame(width: 56, height: 56)

                    SSIconImage(name: "ss.person", size: 22)
                        .foregroundColor(.white)
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text("Your Profile")
                        .font(Font.SS.titleMedium)
                        .foregroundColor(Color.SS.textPrimary)

                    Text("Baseline: \(appState.computeBaselineScore())/100")
                        .font(Font.SS.labelSmall)
                        .foregroundColor(Color.SS.textTertiary)
                }

                Spacer()
            }
        }
    }
}

// MARK: - Subscription Status Card
struct SubscriptionStatusCard: View {
    @EnvironmentObject var appState: AppState
    @Binding var showPaywall: Bool

    var body: some View {
        SSAccentCard {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: Spacing.xs) {
                        SSIconImage(name: "ss.crown", size: 12)
                            .foregroundColor(Color.SS.accent)
                        Text(appState.hasActiveSubscription ? "PRO" : "FREE")
                            .font(.system(size: 11, weight: .medium))
                            .tracking(2)
                            .foregroundColor(Color.SS.accent)
                    }

                    Text(appState.hasActiveSubscription ? "Active Plan" : "Limited Features")
                        .font(Font.SS.bodyMedium)
                        .foregroundColor(Color.SS.textPrimary)

                    Text(appState.hasActiveSubscription ? "All features unlocked" : "Upgrade for full access")
                        .font(Font.SS.labelSmall)
                        .foregroundColor(Color.SS.textTertiary)
                }

                Spacer()

                Button(action: {
                    SSHaptics.selection()
                    if appState.hasActiveSubscription {
                        if let url = URL(string: "https://apps.apple.com/account/subscriptions") {
                            UIApplication.shared.open(url)
                        }
                    } else {
                        showPaywall = true
                    }
                }) {
                    Text(appState.hasActiveSubscription ? "Manage" : "Upgrade")
                        .font(Font.SS.labelMedium)
                        .foregroundColor(Color.SS.accent)
                        .padding(.horizontal, Spacing.sm)
                        .padding(.vertical, Spacing.xxs + 2)
                        .overlay(
                            Capsule()
                                .strokeBorder(Color.SS.accent.opacity(0.3), lineWidth: 0.5)
                        )
                }
            }
        }
    }
}

// MARK: - Settings Section
struct SettingsSection<Content: View>: View {
    let title: String
    @ViewBuilder let content: () -> Content

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.xs) {
            Text(title)
                .font(Font.SS.caption)
                .foregroundColor(Color.SS.textDisabled)
                .tracking(1.5)
                .padding(.horizontal, Spacing.xl)

            SSCard(padding: Spacing.sm) {
                VStack(spacing: 0) {
                    content()
                }
            }
            .padding(.horizontal, Spacing.xl)
        }
    }
}

// MARK: - Settings Rows
struct SettingsToggleRow: View {
    let icon: String
    let title: String
    var subtitle: String? = nil
    @Binding var isOn: Bool
    var color: Color = Color.SS.accent

    var body: some View {
        HStack(spacing: Spacing.sm) {
            SSIconImage(name: icon, size: 16)
                .foregroundColor(color)
                .frame(width: 28)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(Font.SS.bodyMedium)
                    .foregroundColor(Color.SS.textPrimary)
                if let subtitle = subtitle {
                    Text(subtitle)
                        .font(Font.SS.caption)
                        .foregroundColor(Color.SS.textTertiary)
                }
            }

            Spacer()

            Toggle("", isOn: $isOn)
                .tint(Color.SS.accent)
                .labelsHidden()
                .accessibilityLabel(title)
                .onChange(of: isOn) { SSHaptics.selection() }
        }
        .padding(.vertical, Spacing.xs)
    }
}

struct SettingsNavRow: View {
    let icon: String
    let title: String
    var subtitle: String? = nil
    var color: Color = Color.SS.textSecondary
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: Spacing.sm) {
                SSIconImage(name: icon, size: 16)
                    .foregroundColor(color)
                    .frame(width: 28)

                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(Font.SS.bodyMedium)
                        .foregroundColor(Color.SS.textPrimary)
                    if let subtitle = subtitle {
                        Text(subtitle)
                            .font(Font.SS.caption)
                            .foregroundColor(Color.SS.textTertiary)
                    }
                }

                Spacer()

                SSIconImage(name: "ss.chevron.right", size: 10)
                    .foregroundColor(Color.SS.textDisabled)
            }
            .padding(.vertical, Spacing.xs)
        }
    }
}

struct SettingsDateRow: View {
    let icon: String
    let title: String
    @Binding var date: Date
    var color: Color = Color.SS.accent

    var body: some View {
        HStack(spacing: Spacing.sm) {
            SSIconImage(name: icon, size: 16)
                .foregroundColor(color)
                .frame(width: 28)

            Text(title)
                .font(Font.SS.bodyMedium)
                .foregroundColor(Color.SS.textPrimary)

            Spacer()

            DatePicker("", selection: $date, displayedComponents: .hourAndMinute)
                .labelsHidden()
                .tint(Color.SS.accent)
                .accessibilityLabel(title)
        }
        .padding(.vertical, Spacing.xs)
    }
}
