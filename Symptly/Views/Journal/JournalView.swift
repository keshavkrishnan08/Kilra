import SwiftUI

struct JournalView: View {
    @EnvironmentObject var dataStore: DataStore
    @State private var showContent = false
    @State private var showCompose = false
    @State private var editingEntry: JournalEntry? = nil
    @State private var selectedFilter: JournalFilter = .all
    @State private var selectedTagFilter: String? = nil
    @State private var selectedEntry: JournalEntry? = nil

    enum JournalFilter: String, CaseIterable {
        case all = "All"
        case favorites = "Favorites"
        case tagged = "Tagged"
    }

    private var filteredEntries: [JournalEntry] {
        let sorted = dataStore.journalEntries.sorted { $0.timestamp > $1.timestamp }
        switch selectedFilter {
        case .all:
            return sorted
        case .favorites:
            return sorted.filter { $0.isFavorite }
        case .tagged:
            guard let tag = selectedTagFilter else { return sorted }
            return sorted.filter { $0.tags.contains(tag) }
        }
    }

    private var allTags: [String] {
        let tags = Set(dataStore.journalEntries.flatMap(\.tags))
        return tags.sorted()
    }

    // Last 7 days of mood data for the streak dots
    private var moodStreak: [(date: Date, mood: Int?)] {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        return (0..<7).reversed().map { offset in
            let date = calendar.date(byAdding: .day, value: -offset, to: today) ?? today
            let entry = dataStore.journalEntries.first {
                calendar.isDate($0.timestamp, inSameDayAs: date) && $0.mood != nil
            }
            return (date, entry?.mood)
        }
    }

    var body: some View {
        ZStack {
            Color.SS.background.ignoresSafeArea()

            VStack(spacing: 0) {
                SSNavigationBar(
                    title: "Journal",
                    subtitle: "Your health diary",
                    trailingIcon: "ss.tab.plus",
                    trailingAction: {
                        SSHaptics.light()
                        editingEntry = nil
                        showCompose = true
                    }
                )

                if dataStore.journalEntries.isEmpty {
                    Spacer()
                    SSEmptyState(
                        icon: "ss.doc.richtext",
                        title: "Your journal is empty",
                        subtitle: "Start journaling to track your health story. Capture moods, symptoms, and milestones in your own words.",
                        actionTitle: "Write First Entry"
                    ) {
                        SSHaptics.light()
                        editingEntry = nil
                        showCompose = true
                    }
                    Spacer()
                } else {
                    ScrollView(showsIndicators: false) {
                        VStack(spacing: Spacing.lg) {
                            // Mood streak
                            moodStreakRow
                                .padding(.horizontal, Spacing.xl)

                            // Filter chips
                            filterChipsRow
                                .padding(.horizontal, Spacing.xl)

                            // Entry list
                            LazyVStack(spacing: Spacing.sm) {
                                ForEach(filteredEntries) { entry in
                                    JournalEntryCard(entry: entry) {
                                        SSHaptics.selection()
                                        selectedEntry = entry
                                    }
                                    .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                                        Button(role: .destructive) {
                                            SSHaptics.medium()
                                            withAnimation { dataStore.deleteJournalEntry(entry) }
                                        } label: {
                                            Text("Delete")
                                        }
                                        .accessibilityLabel("Delete journal entry: \(entry.title)")
                                    }
                                    .swipeActions(edge: .leading, allowsFullSwipe: true) {
                                        Button {
                                            SSHaptics.selection()
                                            withAnimation { dataStore.toggleFavorite(entry) }
                                        } label: {
                                            Text(entry.isFavorite ? "Unfavorite" : "Favorite")
                                        }
                                        .tint(Color.SS.warning)
                                        .accessibilityLabel(entry.isFavorite ? "Remove from favorites: \(entry.title)" : "Add to favorites: \(entry.title)")
                                    }
                                }
                            }
                            .padding(.horizontal, Spacing.xl)

                            Spacer(minLength: 120)
                        }
                        .padding(.top, Spacing.sm)
                    }
                }
            }
        }
        .opacity(showContent ? 1 : 0)
        .onAppear {
            withAnimation(.easeOut(duration: 0.3)) { showContent = true }
        }
        .sheet(isPresented: $showCompose) {
            JournalComposeView(entry: editingEntry)
                .environmentObject(dataStore)
                .presentationDetents([.large])
                .presentationDragIndicator(.visible)
                .presentationBackground(Color.SS.surfacePrimary)
        }
        .sheet(item: $selectedEntry) { entry in
            JournalDetailView(entry: entry) { updated in
                editingEntry = updated
                selectedEntry = nil
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
                    showCompose = true
                }
            }
            .environmentObject(dataStore)
            .presentationDetents([.large])
            .presentationDragIndicator(.visible)
            .presentationBackground(Color.SS.surfacePrimary)
        }
    }

    // MARK: - Mood Streak Row
    private var moodStreakRow: some View {
        SSCard(padding: Spacing.md) {
            VStack(alignment: .leading, spacing: Spacing.sm) {
                HStack {
                    SSIconImage(name: "ss.mood.4", size: 14)
                        .foregroundColor(Color.SS.violet)
                    Text("Mood This Week")
                        .font(Font.SS.labelMedium)
                        .foregroundColor(Color.SS.textTertiary)
                        .tracking(0.5)
                    Spacer()
                }

                HStack(spacing: Spacing.sm) {
                    ForEach(Array(moodStreak.enumerated()), id: \.offset) { _, day in
                        VStack(spacing: 4) {
                            moodDot(mood: day.mood)
                            Text(dayLabel(day.date))
                                .font(Font.SS.caption)
                                .foregroundColor(Color.SS.textDisabled)
                        }
                        .frame(maxWidth: .infinity)
                    }
                }
            }
        }
    }

    private func moodDot(mood: Int?) -> some View {
        Group {
            if let mood = mood {
                Circle()
                    .fill(moodColor(mood))
                    .frame(width: 14, height: 14)
                    .overlay(
                        Circle()
                            .strokeBorder(moodColor(mood).opacity(0.3), lineWidth: 2)
                            .frame(width: 20, height: 20)
                    )
            } else {
                Circle()
                    .strokeBorder(Color.SS.separator, lineWidth: 1.5)
                    .frame(width: 14, height: 14)
            }
        }
    }

    private func dayLabel(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEE"
        return String(formatter.string(from: date).prefix(2))
    }

    // MARK: - Filter Chips
    private var filterChipsRow: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: Spacing.xs) {
                // Main filters
                ForEach([JournalFilter.all, .favorites], id: \.self) { filter in
                    Button(action: {
                        SSHaptics.selection()
                        withAnimation {
                            selectedFilter = filter
                            selectedTagFilter = nil
                        }
                    }) {
                        SSChip(
                            label: filter.rawValue,
                            color: Color.SS.accent,
                            isSelected: selectedFilter == filter && selectedTagFilter == nil
                        )
                    }
                    .buttonStyle(PlainButtonStyle())
                    .accessibilityLabel("Filter journal: \(filter.rawValue)")
                }

                // Tag filters
                ForEach(allTags, id: \.self) { tag in
                    Button(action: {
                        SSHaptics.selection()
                        withAnimation {
                            selectedFilter = .tagged
                            selectedTagFilter = tag
                        }
                    }) {
                        SSChip(
                            label: tag,
                            color: Color.SS.violet,
                            isSelected: selectedFilter == .tagged && selectedTagFilter == tag
                        )
                    }
                    .buttonStyle(PlainButtonStyle())
                    .accessibilityLabel("Filter by tag: \(tag)")
                }
            }
        }
    }
}

// MARK: - Mood Color Helper
func moodColor(_ mood: Int) -> Color {
    switch mood {
    case 1: return Color(hex: "EF4444")
    case 2: return Color(hex: "F97316")
    case 3: return Color(hex: "EAB308")
    case 4: return Color(hex: "22C55E")
    case 5: return Color(hex: "10B981")
    default: return Color.SS.textDisabled
    }
}

// MARK: - Mood Label Helper
func moodLabel(_ mood: Int) -> String {
    switch mood {
    case 1: return "Awful"
    case 2: return "Bad"
    case 3: return "Okay"
    case 4: return "Good"
    case 5: return "Great"
    default: return ""
    }
}

// MARK: - Journal Entry Card
struct JournalEntryCard: View {
    let entry: JournalEntry
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            SSCard(padding: Spacing.md) {
                VStack(alignment: .leading, spacing: Spacing.sm) {
                    // Top row: title + favorite
                    HStack(alignment: .top) {
                        Text(entry.title)
                            .font(Font.SS.accentMedium)
                            .foregroundColor(Color.SS.textPrimary)
                            .lineLimit(1)

                        Spacer()

                        if entry.isFavorite {
                            Image(systemName: "star.fill")
                                .font(.system(size: 12))
                                .foregroundColor(Color.SS.warning)
                        }
                    }

                    // Body preview
                    if !entry.body.isEmpty {
                        Text(entry.body)
                            .font(Font.SS.bodySmall)
                            .foregroundColor(Color.SS.textSecondary)
                            .lineLimit(2)
                            .lineSpacing(4)
                    }

                    // Bottom row: mood + tags + timestamp
                    HStack(spacing: Spacing.sm) {
                        // Mood indicator
                        if let mood = entry.mood {
                            HStack(spacing: 4) {
                                SSIconImage(name: "ss.mood.\(mood)", size: 14)
                                    .foregroundColor(moodColor(mood))
                                Text(moodLabel(mood))
                                    .font(Font.SS.caption)
                                    .foregroundColor(moodColor(mood))
                            }
                        }

                        // Tags
                        if !entry.tags.isEmpty {
                            HStack(spacing: 4) {
                                ForEach(entry.tags.prefix(2), id: \.self) { tag in
                                    Text(tag)
                                        .font(Font.SS.caption)
                                        .foregroundColor(Color.SS.violet)
                                        .padding(.horizontal, 6)
                                        .padding(.vertical, 2)
                                        .background(
                                            Capsule()
                                                .fill(Color.SS.violetSubtle)
                                        )
                                }
                                if entry.tags.count > 2 {
                                    Text("+\(entry.tags.count - 2)")
                                        .font(Font.SS.caption)
                                        .foregroundColor(Color.SS.textTertiary)
                                }
                            }
                        }

                        Spacer()

                        // Timestamp
                        Text(relativeDate(entry.timestamp))
                            .font(Font.SS.caption)
                            .foregroundColor(Color.SS.textDisabled)
                    }
                }
            }
        }
        .buttonStyle(PlainButtonStyle())
        .accessibilityLabel("Open journal entry: \(entry.title)")
    }

    private func relativeDate(_ date: Date) -> String {
        let calendar = Calendar.current
        if calendar.isDateInToday(date) {
            let formatter = DateFormatter()
            formatter.dateFormat = "h:mm a"
            return formatter.string(from: date)
        } else if calendar.isDateInYesterday(date) {
            return "Yesterday"
        } else {
            let formatter = DateFormatter()
            formatter.dateFormat = "MMM d"
            return formatter.string(from: date)
        }
    }
}
