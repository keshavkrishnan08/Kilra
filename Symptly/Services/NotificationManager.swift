import SwiftUI
import UserNotifications

@MainActor
final class NotificationManager: ObservableObject {
    @Published var isAuthorized = false
    @Published var pendingNotifications: [UNNotificationRequest] = []

    private let center = UNUserNotificationCenter.current()

    func requestAuthorization() async {
        do {
            let granted = try await center.requestAuthorization(options: [.alert, .badge, .sound])
            isAuthorized = granted
        } catch {
            print("Notification auth failed: \(error)")
        }
    }

    func scheduleDailyReminder(at time: Date) async {
        if !isAuthorized {
            await requestAuthorization()
        }
        guard isAuthorized else { return }

        // Remove existing reminders
        center.removeAllPendingNotificationRequests()

        let calendar = Calendar.current
        let components = calendar.dateComponents([.hour, .minute], from: time)

        let messages: [(title: String, body: String)] = [
            ("How's your day going? 🌿", "A quick check-in helps spot patterns you'd never notice otherwise."),
            ("Your health diary misses you 💚", "30 seconds is all it takes — log how you're feeling right now."),
            ("Time for your daily check-in ✨", "Track your mood and symptoms to unlock smarter insights."),
            ("Quick wellness check! 🩺", "Rate your mood and energy — your future self will thank you."),
            ("Hey, how are you feeling? 🌱", "Even a simple log helps your AI get smarter about your health."),
        ]
        let pick = messages[Calendar.current.component(.day, from: Date()) % messages.count]

        let content = UNMutableNotificationContent()
        content.title = pick.title
        content.body = pick.body
        content.sound = .default
        content.badge = 1
        content.categoryIdentifier = "DAILY_REMINDER"

        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: true)
        let request = UNNotificationRequest(
            identifier: "daily_reminder",
            content: content,
            trigger: trigger
        )

        do {
            try await center.add(request)
        } catch {
            print("Failed to schedule reminder: \(error)")
        }
    }

    func scheduleStreakReminder() async {
        let content = UNMutableNotificationContent()
        content.title = "Your streak is on the line! 🔥"
        content.body = "You haven't logged today yet. One quick entry keeps your streak alive and your insights accurate."
        content.sound = .default
        content.categoryIdentifier = "STREAK_REMINDER"

        // Schedule for 8 PM if no entries today
        var components = DateComponents()
        components.hour = 20
        components.minute = 0

        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: true)
        let request = UNNotificationRequest(
            identifier: "streak_reminder",
            content: content,
            trigger: trigger
        )

        do {
            try await center.add(request)
        } catch {
            print("Failed to schedule streak reminder: \(error)")
        }
    }

    func cancelAllNotifications() {
        center.removeAllPendingNotificationRequests()
        center.removeAllDeliveredNotifications()
    }

    // MARK: - Medication Reminders

    func scheduleMedicationReminder(for medication: Medication) async {
        if !isAuthorized {
            await requestAuthorization()
        }
        guard isAuthorized, medication.isActive else { return }

        // Cancel any existing reminders for this medication first
        cancelMedicationReminder(for: medication.id)

        let times = reminderTimes(for: medication)
        for (suffix, components) in times {
            let content = UNMutableNotificationContent()
            content.title = "Time for \(medication.name) 💊"
            content.body = "\(medication.dosage) — \(medication.timeOfDay.rawValue). Tap to mark as taken."
            content.sound = .default
            content.categoryIdentifier = "MEDICATION_REMINDER"

            let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: true)
            let identifier = "med_\(medication.id.uuidString)_\(suffix)"
            let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)

            do {
                try await center.add(request)
            } catch {
                print("Failed to schedule medication reminder: \(error)")
            }
        }
    }

    func cancelMedicationReminder(for medicationId: UUID) {
        let prefix = "med_\(medicationId.uuidString)"
        center.getPendingNotificationRequests { requests in
            let matching = requests
                .map(\.identifier)
                .filter { $0.hasPrefix(prefix) }
            self.center.removePendingNotificationRequests(withIdentifiers: matching)
            self.center.removeDeliveredNotifications(withIdentifiers: matching)
        }
    }

    func rescheduleAllMedicationReminders(medications: [Medication]) async {
        // Remove all existing medication notifications
        let requests = await center.pendingNotificationRequests()
        let medIdentifiers = requests
            .map(\.identifier)
            .filter { $0.hasPrefix("med_") }
        center.removePendingNotificationRequests(withIdentifiers: medIdentifiers)

        // Schedule reminders for every active medication
        let activeMeds = medications.filter(\.isActive)
        for med in activeMeds {
            await scheduleMedicationReminder(for: med)
        }
    }

    /// Maps a medication's frequency and timeOfDay to one or more (suffix, DateComponents) pairs.
    private func reminderTimes(for medication: Medication) -> [(String, DateComponents)] {
        // Twice-daily overrides the single timeOfDay — schedule morning + evening
        if medication.frequency == .twiceDaily {
            var morning = DateComponents()
            morning.hour = 8
            morning.minute = 0
            var evening = DateComponents()
            evening.hour = 18
            evening.minute = 0
            return [("morning", morning), ("evening", evening)]
        }

        var components = DateComponents()
        let suffix: String

        switch medication.timeOfDay {
        case .morning:
            components.hour = 8
            components.minute = 0
            suffix = "morning"
        case .afternoon:
            components.hour = 13
            components.minute = 0
            suffix = "afternoon"
        case .evening:
            components.hour = 18
            components.minute = 0
            suffix = "evening"
        case .bedtime:
            components.hour = 21
            components.minute = 30
            suffix = "bedtime"
        case .withFood:
            components.hour = 12
            components.minute = 0
            suffix = "withfood"
        }

        return [(suffix, components)]
    }

    // MARK: - Categories

    func registerCategories() {
        let logAction = UNNotificationAction(
            identifier: "LOG_ACTION",
            title: "Log Symptom",
            options: [.foreground]
        )

        let dismissAction = UNNotificationAction(
            identifier: "DISMISS_ACTION",
            title: "Dismiss",
            options: []
        )

        let dailyCategory = UNNotificationCategory(
            identifier: "DAILY_REMINDER",
            actions: [logAction, dismissAction],
            intentIdentifiers: []
        )

        let takenAction = UNNotificationAction(
            identifier: "MED_TAKEN_ACTION",
            title: "Taken",
            options: [.foreground]
        )

        let skipAction = UNNotificationAction(
            identifier: "MED_SKIP_ACTION",
            title: "Skip",
            options: []
        )

        let medicationCategory = UNNotificationCategory(
            identifier: "MEDICATION_REMINDER",
            actions: [takenAction, skipAction],
            intentIdentifiers: []
        )

        center.setNotificationCategories([dailyCategory, medicationCategory])
    }
}
