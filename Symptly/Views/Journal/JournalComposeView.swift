import SwiftUI

struct JournalComposeView: View {
    @EnvironmentObject var dataStore: DataStore
    @Environment(\.dismiss) private var dismiss

    let entry: JournalEntry?

    @State private var title: String = ""
    @State private var bodyText: String = ""
    @State private var selectedMood: Int? = nil
    @State private var selectedTags: Set<String> = []
    @State private var customTagText: String = ""
    @State private var showContent = false
    @State private var headerScale: CGFloat = 0.95
    @FocusState private var titleFocused: Bool
    @FocusState private var bodyFocused: Bool

    private let presetTags = [
        "Doctor Visit",
        "Medication Change",
        "Flare-Up",
        "Good Day",
        "Milestone",
        "Question"
    ]

    private let moodIcons = ["ss.mood.1", "ss.mood.2", "ss.mood.3", "ss.mood.4", "ss.mood.5"]
    private let moodLabels = ["Awful", "Bad", "Okay", "Good", "Great"]

    private var isEditing: Bool { entry != nil }

    private var canSave: Bool {
        !title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    private var dateString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE, MMM d"
        return formatter.string(from: Date())
    }

    private var timeString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a"
        return formatter.string(from: Date())
    }

    var body: some View {
        ZStack {
            Color.SS.background.ignoresSafeArea()

            VStack(spacing: 0) {
                // Header with accent bar
                VStack(spacing: 0) {
                    // Top accent gradient bar
                    Rectangle()
                        .fill(
                            LinearGradient(
                                colors: [Color.SS.accent, Color.SS.violet],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(height: 3)

                    // Navigation bar
                    HStack {
                        Button(action: {
                            SSHaptics.light()
                            dismiss()
                        }) {
                            SSIconImage(name: "ss.xmark", size: 14)
                                .foregroundColor(Color.SS.textSecondary)
                                .frame(width: 32, height: 32)
                                .background(
                                    Circle().fill(Color.SS.surfaceSecondary)
                                )
                        }
                        .accessibilityLabel("Close journal editor")

                        Spacer()

                        VStack(spacing: 1) {
                            Text(isEditing ? "Edit Entry" : "New Entry")
                                .font(Font.SS.titleSmall)
                                .foregroundColor(Color.SS.textPrimary)
                            Text(dateString)
                                .font(Font.SS.caption)
                                .foregroundColor(Color.SS.textTertiary)
                        }

                        Spacer()

                        Button(action: saveEntry) {
                            Text("Save")
                                .font(Font.SS.accentMedium)
                                .foregroundColor(canSave ? Color.SS.background : Color.SS.textDisabled)
                                .padding(.horizontal, Spacing.md)
                                .padding(.vertical, Spacing.xs)
                                .background(
                                    Capsule()
                                        .fill(canSave ? Color.SS.accent : Color.SS.surfaceTertiary)
                                )
                        }
                        .disabled(!canSave)
                        .accessibilityLabel("Save journal entry")
                    }
                    .padding(.horizontal, Spacing.lg)
                    .padding(.vertical, Spacing.sm)
                }

                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: Spacing.lg) {
                        // Time badge
                        HStack {
                            SSIconImage(name: "ss.clock", size: 12)
                                .foregroundColor(Color.SS.textDisabled)
                            Text(timeString)
                                .font(Font.SS.caption)
                                .foregroundColor(Color.SS.textDisabled)
                        }
                        .padding(.horizontal, Spacing.xl)
                        .padding(.top, Spacing.sm)

                        // Title field
                        TextField("How are you feeling?", text: $title)
                            .font(.system(size: 24, weight: .light))
                            .foregroundColor(Color.SS.textPrimary)
                            .focused($titleFocused)
                            .padding(.horizontal, Spacing.xl)

                        // Body editor
                        ZStack(alignment: .topLeading) {
                            if bodyText.isEmpty {
                                Text("Write about your day, symptoms, thoughts...")
                                    .font(Font.SS.bodyMedium)
                                    .foregroundColor(Color.SS.textTertiary)
                                    .padding(.top, 8)
                                    .padding(.leading, 5)
                            }

                            TextEditor(text: $bodyText)
                                .font(Font.SS.bodyMedium)
                                .foregroundColor(Color.SS.textPrimary)
                                .focused($bodyFocused)
                                .scrollContentBackground(.hidden)
                                .frame(minHeight: 120)
                                .lineSpacing(6)
                        }
                        .padding(.horizontal, Spacing.xl)

                        // Mood selector card
                        VStack(alignment: .leading, spacing: Spacing.sm) {
                            Text("MOOD")
                                .font(Font.SS.caption)
                                .foregroundColor(Color.SS.textDisabled)
                                .tracking(1.5)
                                .padding(.horizontal, Spacing.xl)

                            SSCard(padding: Spacing.md) {
                                HStack(spacing: 0) {
                                    ForEach(0..<5) { index in
                                        let moodValue = index + 1
                                        let isSelected = selectedMood == moodValue

                                        Button(action: {
                                            SSHaptics.selection()
                                            withAnimation(.spring(response: 0.35, dampingFraction: 0.7)) {
                                                selectedMood = selectedMood == moodValue ? nil : moodValue
                                            }
                                        }) {
                                            VStack(spacing: 6) {
                                                ZStack {
                                                    Circle()
                                                        .fill(isSelected ? moodColor(moodValue).opacity(0.12) : Color.clear)
                                                        .frame(width: 48, height: 48)

                                                    SSIconImage(
                                                        name: moodIcons[index],
                                                        size: isSelected ? 28 : 22
                                                    )
                                                    .foregroundColor(
                                                        isSelected ? moodColor(moodValue) : Color.SS.textTertiary
                                                    )
                                                }

                                                Text(moodLabels[index])
                                                    .font(Font.SS.caption)
                                                    .foregroundColor(
                                                        isSelected ? moodColor(moodValue) : Color.SS.textDisabled
                                                    )
                                            }
                                            .frame(maxWidth: .infinity)
                                            .opacity(
                                                selectedMood == nil || isSelected ? 1 : 0.35
                                            )
                                        }
                                        .buttonStyle(PlainButtonStyle())
                                        .accessibilityLabel("Select mood: \(moodLabels[index])")
                                    }
                                }
                            }
                            .padding(.horizontal, Spacing.xl)
                        }

                        // Tags section
                        VStack(alignment: .leading, spacing: Spacing.sm) {
                            Text("TAGS")
                                .font(Font.SS.caption)
                                .foregroundColor(Color.SS.textDisabled)
                                .tracking(1.5)
                                .padding(.horizontal, Spacing.xl)

                            SSCard(padding: Spacing.md) {
                                VStack(alignment: .leading, spacing: Spacing.md) {
                                    FlowLayout(spacing: Spacing.xs) {
                                        ForEach(presetTags, id: \.self) { tag in
                                            Button(action: {
                                                SSHaptics.selection()
                                                withAnimation(.easeOut(duration: 0.15)) {
                                                    if selectedTags.contains(tag) {
                                                        selectedTags.remove(tag)
                                                    } else {
                                                        selectedTags.insert(tag)
                                                    }
                                                }
                                            }) {
                                                SSChip(
                                                    label: tag,
                                                    color: tagColor(tag),
                                                    isSelected: selectedTags.contains(tag)
                                                )
                                            }
                                            .buttonStyle(PlainButtonStyle())
                                            .accessibilityLabel("Toggle tag: \(tag)")
                                        }
                                    }

                                    // Custom tag input
                                    HStack(spacing: Spacing.xs) {
                                        TextField("Add custom tag...", text: $customTagText)
                                            .font(Font.SS.bodySmall)
                                            .foregroundColor(Color.SS.textPrimary)
                                            .padding(.horizontal, Spacing.sm)
                                            .padding(.vertical, Spacing.xs)
                                            .background(
                                                RoundedRectangle(cornerRadius: Radius.sm)
                                                    .fill(Color.SS.surfaceSecondary)
                                            )
                                            .overlay(
                                                RoundedRectangle(cornerRadius: Radius.sm)
                                                    .strokeBorder(Color.SS.separator, lineWidth: 0.5)
                                            )
                                            .submitLabel(.done)
                                            .onSubmit(addCustomTag)

                                        if !customTagText.trimmingCharacters(in: .whitespaces).isEmpty {
                                            Button(action: addCustomTag) {
                                                SSIconImage(name: "ss.tab.plus", size: 14)
                                                    .foregroundColor(Color.SS.accent)
                                                    .frame(width: 32, height: 32)
                                                    .background(
                                                        Circle().fill(Color.SS.accentSubtle)
                                                    )
                                            }
                                            .accessibilityLabel("Add custom tag")
                                            .transition(.scale.combined(with: .opacity))
                                        }
                                    }
                                }
                            }
                            .padding(.horizontal, Spacing.xl)
                        }

                        // Writing prompt
                        if !isEditing && title.isEmpty && bodyText.isEmpty {
                            VStack(alignment: .leading, spacing: Spacing.xs) {
                                Text("PROMPTS")
                                    .font(Font.SS.caption)
                                    .foregroundColor(Color.SS.textDisabled)
                                    .tracking(1.5)

                                VStack(spacing: Spacing.xs) {
                                    PromptButton(text: "What made today better or worse?") {
                                        title = "What made today better or worse?"
                                        bodyFocused = true
                                    }
                                    PromptButton(text: "Any new symptoms or changes?") {
                                        title = "Any new symptoms or changes?"
                                        bodyFocused = true
                                    }
                                    PromptButton(text: "How did I sleep last night?") {
                                        title = "How did I sleep last night?"
                                        bodyFocused = true
                                    }
                                }
                            }
                            .padding(.horizontal, Spacing.xl)
                            .transition(.opacity)
                        }

                        Spacer(minLength: Spacing.xxxl)
                    }
                    .padding(.top, Spacing.xs)
                }
            }
        }
        .opacity(showContent ? 1 : 0)
        .onAppear {
            if let entry = entry {
                title = entry.title
                bodyText = entry.body
                selectedMood = entry.mood
                selectedTags = Set(entry.tags)
            }
            withAnimation(.easeOut(duration: 0.3)) {
                showContent = true
                headerScale = 1.0
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                if !isEditing { titleFocused = true }
            }
        }
    }

    private func saveEntry() {
        guard canSave else { return }
        SSHaptics.success()

        let trimmedTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedBody = bodyText.trimmingCharacters(in: .whitespacesAndNewlines)

        if let existing = entry {
            var updated = existing
            updated.title = trimmedTitle
            updated.body = trimmedBody
            updated.mood = selectedMood
            updated.tags = Array(selectedTags)
            dataStore.updateJournalEntry(updated)
        } else {
            let newEntry = JournalEntry(
                id: UUID(),
                title: trimmedTitle,
                body: trimmedBody,
                mood: selectedMood,
                tags: Array(selectedTags),
                timestamp: Date(),
                isFavorite: false
            )
            dataStore.addJournalEntry(newEntry)
        }

        dismiss()
    }

    private func addCustomTag() {
        let tag = customTagText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !tag.isEmpty else { return }
        SSHaptics.light()
        withAnimation {
            selectedTags.insert(tag)
            customTagText = ""
        }
    }

    private func tagColor(_ tag: String) -> Color {
        switch tag {
        case "Doctor Visit": return Color.SS.info
        case "Medication Change": return Color.SS.violet
        case "Flare-Up": return Color.SS.error
        case "Good Day": return Color.SS.success
        case "Milestone": return Color.SS.warning
        case "Question": return Color.SS.accent
        default: return Color.SS.accent
        }
    }
}

// MARK: - Writing Prompt Button
private struct PromptButton: View {
    let text: String
    let action: () -> Void

    var body: some View {
        Button(action: {
            SSHaptics.selection()
            action()
        }) {
            HStack(spacing: Spacing.sm) {
                SSIconImage(name: "ss.pencil", size: 12)
                    .foregroundColor(Color.SS.accent)

                Text(text)
                    .font(Font.SS.bodySmall)
                    .foregroundColor(Color.SS.textSecondary)

                Spacer()

                SSIconImage(name: "ss.chevron.right", size: 8)
                    .foregroundColor(Color.SS.textDisabled)
            }
            .padding(.horizontal, Spacing.md)
            .padding(.vertical, Spacing.sm)
            .background(
                RoundedRectangle(cornerRadius: Radius.md)
                    .fill(Color.SS.surfaceSecondary)
                    .overlay(
                        RoundedRectangle(cornerRadius: Radius.md)
                            .strokeBorder(Color.SS.separator, lineWidth: 0.5)
                    )
            )
        }
        .buttonStyle(PlainButtonStyle())
        .accessibilityLabel("Use prompt: \(text)")
    }
}

// FlowLayout is defined in LogSymptomView.swift and shared across the app
