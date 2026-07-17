import SwiftUI

struct MedicationView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var dataStore: DataStore
    @EnvironmentObject var notificationManager: NotificationManager
    @State private var showAddSheet = false
    @State private var showDeleteConfirmation = false
    @State private var medicationToDelete: Medication?

    private var activeMeds: [Medication] {
        dataStore.medications.filter(\.isActive)
    }

    private var inactiveMeds: [Medication] {
        dataStore.medications.filter { !$0.isActive }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color.SS.background.ignoresSafeArea()

                ScrollView(showsIndicators: false) {
                    VStack(spacing: Spacing.xl) {
                        // Today's medications
                        if !activeMeds.isEmpty {
                            VStack(alignment: .leading, spacing: Spacing.sm) {
                                HStack {
                                    Text("Today")
                                        .font(Font.SS.headlineSmall)
                                        .foregroundColor(Color.SS.textPrimary)
                                    Spacer()
                                    let taken = activeMeds.filter { dataStore.isMedicationTakenToday($0.id) }.count
                                    Text("\(taken)/\(activeMeds.count)")
                                        .font(Font.SS.labelSmall)
                                        .foregroundColor(Color.SS.accent)
                                        .monospacedDigit()
                                }
                                .padding(.horizontal, Spacing.xl)

                                ForEach(activeMeds) { med in
                                    MedicationCheckRow(medication: med, dataStore: dataStore)
                                        .padding(.horizontal, Spacing.xl)
                                }
                            }
                        }

                        // Active medications list
                        VStack(alignment: .leading, spacing: Spacing.sm) {
                            Text("Active Medications")
                                .font(Font.SS.headlineSmall)
                                .foregroundColor(Color.SS.textPrimary)
                                .padding(.horizontal, Spacing.xl)

                            if activeMeds.isEmpty {
                                SSCard {
                                    SSEmptyState(
                                        icon: "ss.pills",
                                        title: "No medications",
                                        subtitle: "Add your medications to track them alongside symptoms",
                                        actionTitle: "Add Medication",
                                        action: { showAddSheet = true }
                                    )
                                }
                                .padding(.horizontal, Spacing.xl)
                            } else {
                                ForEach(activeMeds) { med in
                                    MedicationCard(medication: med, dataStore: dataStore, notificationManager: notificationManager, onDelete: { m in medicationToDelete = m; showDeleteConfirmation = true })
                                        .padding(.horizontal, Spacing.xl)
                                }
                            }
                        }

                        // Past medications
                        if !inactiveMeds.isEmpty {
                            VStack(alignment: .leading, spacing: Spacing.sm) {
                                Text("Past Medications")
                                    .font(Font.SS.labelMedium)
                                    .foregroundColor(Color.SS.textTertiary)
                                    .tracking(0.5)
                                    .padding(.horizontal, Spacing.xl)

                                ForEach(inactiveMeds) { med in
                                    MedicationCard(medication: med, dataStore: dataStore, notificationManager: notificationManager, onDelete: { m in medicationToDelete = m; showDeleteConfirmation = true })
                                        .padding(.horizontal, Spacing.xl)
                                        .opacity(0.6)
                                }
                            }
                        }

                        Spacer(minLength: 60)
                    }
                    .padding(.top, Spacing.md)
                }
            }
            .navigationTitle("Medications")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showAddSheet = true }) {
                        SSIconImage(name: "ss.tab.plus", size: 16)
                            .foregroundColor(Color.SS.accent)
                    }
                    .accessibilityLabel("Add new medication")
                }
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Done") { dismiss() }
                        .foregroundColor(Color.SS.accent)
                        .accessibilityLabel("Done, close medications")
                }
            }
            .sheet(isPresented: $showAddSheet) {
                AddMedicationSheet(dataStore: dataStore, notificationManager: notificationManager)
                    .presentationDetents([.large])
                    .presentationDragIndicator(.visible)
            }
            .alert("Delete Medication", isPresented: $showDeleteConfirmation) {
                Button("Cancel", role: .cancel) { medicationToDelete = nil }
                Button("Delete", role: .destructive) {
                    if let med = medicationToDelete {
                        notificationManager.cancelMedicationReminder(for: med.id)
                        withAnimation { dataStore.deleteMedication(med) }
                    }
                    medicationToDelete = nil
                }
            } message: {
                Text("Are you sure you want to delete \(medicationToDelete?.name ?? "this medication")?")
            }
            .onAppear {
                Task {
                    await notificationManager.rescheduleAllMedicationReminders(medications: dataStore.medications)
                }
            }
        }
    }
}

// MARK: - Medication Check Row (today's tracking)
struct MedicationCheckRow: View {
    let medication: Medication
    let dataStore: DataStore
    @State private var taken: Bool = false

    var body: some View {
        SSCard(padding: Spacing.sm) {
            HStack(spacing: Spacing.md) {
                Button(action: {
                    SSHaptics.medium()
                    taken.toggle()
                    let log = MedicationLog(
                        id: UUID(),
                        medicationId: medication.id,
                        medicationName: medication.name,
                        timestamp: Date(),
                        taken: taken,
                        notes: nil
                    )
                    dataStore.logMedication(log)
                }) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 6)
                            .strokeBorder(taken ? Color.SS.accent : Color.SS.separator, lineWidth: taken ? 1.5 : 0.5)
                            .frame(width: 28, height: 28)
                        if taken {
                            RoundedRectangle(cornerRadius: 6)
                                .fill(Color.SS.accentSubtle)
                                .frame(width: 28, height: 28)
                            SSIconImage(name: "ss.checkmark", size: 12)
                                .foregroundColor(Color.SS.accent)
                        }
                    }
                }
                .buttonStyle(PlainButtonStyle())
                .accessibilityLabel(taken ? "Mark \(medication.name) as not taken" : "Mark \(medication.name) as taken")

                VStack(alignment: .leading, spacing: 2) {
                    Text(medication.name)
                        .font(Font.SS.bodyMedium)
                        .foregroundColor(taken ? Color.SS.textTertiary : Color.SS.textPrimary)
                        .strikethrough(taken)
                    Text("\(medication.dosage) · \(medication.timeOfDay.rawValue)")
                        .font(Font.SS.caption)
                        .foregroundColor(Color.SS.textTertiary)
                }

                Spacer()
            }
        }
        .onAppear {
            taken = dataStore.isMedicationTakenToday(medication.id)
        }
    }
}

// MARK: - Medication Card
struct MedicationCard: View {
    let medication: Medication
    let dataStore: DataStore
    let notificationManager: NotificationManager
    var onDelete: ((Medication) -> Void)? = nil

    var body: some View {
        SSCard(padding: Spacing.md) {
            HStack(spacing: Spacing.md) {
                Circle()
                    .fill(Color.SS.accent.opacity(0.1))
                    .frame(width: 44, height: 44)
                    .overlay(
                        SSIconImage(name: "ss.pills", size: 18)
                            .foregroundColor(Color.SS.accent)
                    )

                VStack(alignment: .leading, spacing: 4) {
                    Text(medication.name)
                        .font(Font.SS.bodyMedium)
                        .foregroundColor(Color.SS.textPrimary)

                    HStack(spacing: Spacing.xs) {
                        Text(medication.dosage)
                            .font(Font.SS.labelSmall)
                            .foregroundColor(Color.SS.textTertiary)
                        Text("·")
                            .foregroundColor(Color.SS.textDisabled)
                        Text(medication.frequency.rawValue)
                            .font(Font.SS.labelSmall)
                            .foregroundColor(Color.SS.textTertiary)
                        Text("·")
                            .foregroundColor(Color.SS.textDisabled)
                        Text(medication.timeOfDay.rawValue)
                            .font(Font.SS.labelSmall)
                            .foregroundColor(Color.SS.textTertiary)
                    }
                }

                Spacer()

                SSIconImage(name: "ss.chevron.right", size: 10)
                    .foregroundColor(Color.SS.textDisabled)
            }
        }
        .swipeActions(edge: .trailing) {
            Button(role: .destructive) {
                SSHaptics.medium()
                if let onDelete {
                    onDelete(medication)
                } else {
                    notificationManager.cancelMedicationReminder(for: medication.id)
                    withAnimation { dataStore.deleteMedication(medication) }
                }
            } label: {
                Text("Delete")
            }

            Button {
                SSHaptics.selection()
                var updated = medication
                updated.isActive.toggle()
                dataStore.updateMedication(updated)
                if updated.isActive {
                    Task { await notificationManager.scheduleMedicationReminder(for: updated) }
                } else {
                    notificationManager.cancelMedicationReminder(for: updated.id)
                }
            } label: {
                Text(medication.isActive ? "Archive" : "Reactivate")
            }
            .tint(Color.SS.warning)
        }
    }
}

// MARK: - Add Medication Sheet
struct AddMedicationSheet: View {
    let dataStore: DataStore
    let notificationManager: NotificationManager
    @Environment(\.dismiss) var dismiss
    @State private var name = ""
    @State private var dosage = ""
    @State private var frequency: Medication.MedicationFrequency = .daily
    @State private var timeOfDay: Medication.MedicationTime = .morning
    @State private var notes = ""
    @State private var remindersEnabled = true

    var body: some View {
        NavigationStack {
            ZStack {
                Color.SS.background.ignoresSafeArea()

                ScrollView(showsIndicators: false) {
                    VStack(spacing: Spacing.lg) {
                        // Name
                        VStack(alignment: .leading, spacing: Spacing.xs) {
                            Text("Medication Name")
                                .font(Font.SS.labelMedium)
                                .foregroundColor(Color.SS.textSecondary)
                            TextField("e.g. Ibuprofen", text: $name)
                                .font(Font.SS.bodyMedium)
                                .padding(Spacing.md)
                                .background(
                                    RoundedRectangle(cornerRadius: Radius.md)
                                        .fill(Color.SS.surfaceSecondary)
                                )
                        }

                        // Dosage
                        VStack(alignment: .leading, spacing: Spacing.xs) {
                            Text("Dosage")
                                .font(Font.SS.labelMedium)
                                .foregroundColor(Color.SS.textSecondary)
                            TextField("e.g. 200mg", text: $dosage)
                                .font(Font.SS.bodyMedium)
                                .padding(Spacing.md)
                                .background(
                                    RoundedRectangle(cornerRadius: Radius.md)
                                        .fill(Color.SS.surfaceSecondary)
                                )
                        }

                        // Frequency
                        VStack(alignment: .leading, spacing: Spacing.xs) {
                            Text("Frequency")
                                .font(Font.SS.labelMedium)
                                .foregroundColor(Color.SS.textSecondary)

                            FlowLayout(spacing: Spacing.xs) {
                                ForEach(Medication.MedicationFrequency.allCases, id: \.self) { freq in
                                    Button(action: {
                                        SSHaptics.selection()
                                        frequency = freq
                                    }) {
                                        Text(freq.rawValue)
                                            .font(Font.SS.labelMedium)
                                            .foregroundColor(frequency == freq ? Color.SS.background : Color.SS.textSecondary)
                                            .padding(.horizontal, Spacing.md)
                                            .padding(.vertical, Spacing.sm)
                                            .background(
                                                Capsule()
                                                    .fill(frequency == freq ? Color.SS.accent : Color.SS.surfaceSecondary)
                                            )
                                    }
                                    .buttonStyle(PlainButtonStyle())
                                    .accessibilityLabel("Set frequency to \(freq.rawValue)")
                                }
                            }
                        }

                        // Time of day
                        VStack(alignment: .leading, spacing: Spacing.xs) {
                            Text("Time of Day")
                                .font(Font.SS.labelMedium)
                                .foregroundColor(Color.SS.textSecondary)

                            FlowLayout(spacing: Spacing.xs) {
                                ForEach(Medication.MedicationTime.allCases, id: \.self) { time in
                                    Button(action: {
                                        SSHaptics.selection()
                                        timeOfDay = time
                                    }) {
                                        Text(time.rawValue)
                                            .font(Font.SS.labelMedium)
                                            .foregroundColor(timeOfDay == time ? Color.SS.background : Color.SS.textSecondary)
                                            .padding(.horizontal, Spacing.md)
                                            .padding(.vertical, Spacing.sm)
                                            .background(
                                                Capsule()
                                                    .fill(timeOfDay == time ? Color.SS.accent : Color.SS.surfaceSecondary)
                                            )
                                    }
                                    .buttonStyle(PlainButtonStyle())
                                    .accessibilityLabel("Set time of day to \(time.rawValue)")
                                }
                            }
                        }

                        // Reminders
                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Reminders")
                                    .font(Font.SS.bodyMedium)
                                    .foregroundColor(Color.SS.textPrimary)
                                Text("Get notified when it's time to take this medication")
                                    .font(Font.SS.caption)
                                    .foregroundColor(Color.SS.textTertiary)
                            }
                            Spacer()
                            Toggle("", isOn: $remindersEnabled)
                                .labelsHidden()
                                .tint(Color.SS.accent)
                                .accessibilityLabel("Medication reminders")
                                .accessibilityValue(remindersEnabled ? "Enabled" : "Disabled")
                        }
                        .padding(Spacing.md)
                        .background(
                            RoundedRectangle(cornerRadius: Radius.md)
                                .fill(Color.SS.surfaceSecondary)
                        )

                        // Notes
                        VStack(alignment: .leading, spacing: Spacing.xs) {
                            Text("Notes (optional)")
                                .font(Font.SS.labelMedium)
                                .foregroundColor(Color.SS.textSecondary)
                            TextField("Any additional details", text: $notes, axis: .vertical)
                                .font(Font.SS.bodySmall)
                                .lineLimit(2...4)
                                .padding(Spacing.md)
                                .background(
                                    RoundedRectangle(cornerRadius: Radius.md)
                                        .fill(Color.SS.surfaceSecondary)
                                )
                        }

                        // Save button
                        SSButton(title: "Add Medication", icon: "ss.pills", style: .primary) {
                            save()
                        }
                        .disabled(name.isEmpty || dosage.isEmpty)
                        .opacity(name.isEmpty || dosage.isEmpty ? 0.5 : 1)

                        Spacer(minLength: 40)
                    }
                    .padding(.horizontal, Spacing.xl)
                    .padding(.top, Spacing.lg)
                }
            }
            .navigationTitle("Add Medication")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { dismiss() }
                        .foregroundColor(Color.SS.textSecondary)
                        .accessibilityLabel("Cancel adding medication")
                }
            }
        }
    }

    private func save() {
        let medication = Medication(
            id: UUID(),
            name: name.trimmingCharacters(in: .whitespaces),
            dosage: dosage.trimmingCharacters(in: .whitespaces),
            frequency: frequency,
            timeOfDay: timeOfDay,
            notes: notes.isEmpty ? nil : notes,
            startDate: Date(),
            isActive: true
        )
        dataStore.addMedication(medication)
        if remindersEnabled {
            Task { await notificationManager.scheduleMedicationReminder(for: medication) }
        }
        SSHaptics.success()
        dismiss()
    }
}
