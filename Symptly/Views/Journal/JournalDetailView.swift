import SwiftUI

struct JournalDetailView: View {
    @EnvironmentObject var dataStore: DataStore
    @Environment(\.dismiss) private var dismiss

    let entry: JournalEntry
    var onEdit: ((JournalEntry) -> Void)? = nil

    @State private var showContent = false
    @State private var showDeleteConfirmation = false

    var body: some View {
        ZStack {
            Color.SS.background.ignoresSafeArea()

            VStack(spacing: 0) {
                // Header
                HStack {
                    Button(action: {
                        SSHaptics.light()
                        dismiss()
                    }) {
                        SSIconImage(name: "ss.chevron.down", size: 14)
                            .foregroundColor(Color.SS.textSecondary)
                            .frame(width: 38, height: 38)
                            .background(
                                Circle().fill(Color.SS.surfacePrimary)
                            )
                            .overlay(
                                Circle().strokeBorder(Color.SS.separator, lineWidth: 1)
                            )
                    }
                    .accessibilityLabel("Dismiss journal detail")

                    Spacer()

                    HStack(spacing: Spacing.sm) {
                        // Edit button
                        Button(action: {
                            SSHaptics.light()
                            dismiss()
                            onEdit?(entry)
                        }) {
                            SSIconImage(name: "ss.tab.settings", size: 14)
                                .foregroundColor(Color.SS.accent)
                                .frame(width: 38, height: 38)
                                .background(
                                    Circle().fill(Color.SS.accentSubtle)
                                )
                                .overlay(
                                    Circle().strokeBorder(Color.SS.accent.opacity(0.2), lineWidth: 1)
                                )
                        }
                        .accessibilityLabel("Edit journal entry")

                        // Favorite toggle
                        Button(action: {
                            SSHaptics.selection()
                            withAnimation { dataStore.toggleFavorite(entry) }
                        }) {
                            let isFav = dataStore.journalEntries.first(where: { $0.id == entry.id })?.isFavorite ?? entry.isFavorite
                            Image(systemName: isFav ? "star.fill" : "star")
                                .font(.system(size: 14))
                                .foregroundColor(isFav ? Color.SS.warning : Color.SS.textTertiary)
                                .frame(width: 38, height: 38)
                                .background(
                                    Circle().fill(Color.SS.surfacePrimary)
                                )
                                .overlay(
                                    Circle().strokeBorder(Color.SS.separator, lineWidth: 1)
                                )
                        }
                        .accessibilityLabel(entry.isFavorite ? "Remove from favorites" : "Add to favorites")
                    }
                }
                .padding(.horizontal, Spacing.lg)
                .padding(.vertical, Spacing.md)

                SSDivider()

                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: Spacing.xl) {
                        // Date + mood header
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(formattedDate(entry.timestamp))
                                    .font(Font.SS.labelMedium)
                                    .foregroundColor(Color.SS.textTertiary)
                                    .tracking(0.5)
                                Text(formattedTime(entry.timestamp))
                                    .font(Font.SS.caption)
                                    .foregroundColor(Color.SS.textDisabled)
                            }

                            Spacer()

                            if let mood = entry.mood {
                                HStack(spacing: 6) {
                                    SSIconImage(name: "ss.mood.\(mood)", size: 20)
                                        .foregroundColor(moodColor(mood))
                                    Text(moodLabel(mood))
                                        .font(Font.SS.accentSmall)
                                        .foregroundColor(moodColor(mood))
                                }
                                .padding(.horizontal, Spacing.sm)
                                .padding(.vertical, Spacing.xs)
                                .background(
                                    Capsule()
                                        .fill(moodColor(mood).opacity(0.10))
                                )
                            }
                        }
                        .padding(.horizontal, Spacing.xl)

                        // Title
                        Text(entry.title)
                            .font(Font.SS.headlineLarge)
                            .foregroundColor(Color.SS.textPrimary)
                            .padding(.horizontal, Spacing.xl)

                        // Body text
                        if !entry.body.isEmpty {
                            Text(entry.body)
                                .font(Font.SS.bodyLarge)
                                .foregroundColor(Color.SS.textSecondary)
                                .lineSpacing(6)
                                .padding(.horizontal, Spacing.xl)
                        }

                        // Tags
                        if !entry.tags.isEmpty {
                            SSDivider()
                                .padding(.horizontal, Spacing.xl)

                            VStack(alignment: .leading, spacing: Spacing.sm) {
                                Text("Tags")
                                    .font(Font.SS.labelMedium)
                                    .foregroundColor(Color.SS.textTertiary)
                                    .tracking(0.5)

                                FlowLayout(spacing: Spacing.xs) {
                                    ForEach(entry.tags, id: \.self) { tag in
                                        SSChip(label: tag, color: Color.SS.violet)
                                    }
                                }
                            }
                            .padding(.horizontal, Spacing.xl)
                        }

                        SSDivider()
                            .padding(.horizontal, Spacing.xl)

                        // Delete button
                        Button(action: {
                            SSHaptics.medium()
                            showDeleteConfirmation = true
                        }) {
                            HStack(spacing: Spacing.xs) {
                                Image(systemName: "trash")
                                    .font(.system(size: 13))
                                Text("Delete Entry")
                                    .font(Font.SS.bodySmall)
                            }
                            .foregroundColor(Color.SS.error)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, Spacing.sm)
                        }
                        .accessibilityLabel("Delete journal entry")
                        .padding(.horizontal, Spacing.xl)

                        Spacer(minLength: Spacing.xxxl)
                    }
                    .padding(.top, Spacing.lg)
                }
            }
        }
        .opacity(showContent ? 1 : 0)
        .onAppear {
            withAnimation(.easeOut(duration: 0.25)) { showContent = true }
        }
        .alert("Delete Entry?", isPresented: $showDeleteConfirmation) {
            Button("Cancel", role: .cancel) { }
            Button("Delete", role: .destructive) {
                SSHaptics.medium()
                dataStore.deleteJournalEntry(entry)
                dismiss()
            }
        } message: {
            Text("This can't be undone. Your journal entry will be permanently removed.")
        }
    }

    private func formattedDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE, MMMM d, yyyy"
        return formatter.string(from: date)
    }

    private func formattedTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a"
        return formatter.string(from: date)
    }
}
