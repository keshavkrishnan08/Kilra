import SwiftUI

struct LogSymptomView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var dataStore: DataStore
    @State private var step: LogStep = .selectSymptom
    @State private var selectedSymptom: Symptom?
    @State private var severity: Double = 5
    @State private var notes: String = ""
    @State private var selectedTriggers: Set<String> = []
    @State private var selectedDuration: SymptomEntry.SymptomDuration?
    @State private var searchText = ""
    @State private var showSuccess = false
    @State private var feedbackMessage: (message: String, color: String)?

    enum LogStep {
        case selectSymptom, severity, details, review
    }

    var body: some View {
        ZStack {
            Color.SS.surfacePrimary.ignoresSafeArea()

            VStack(spacing: 0) {
                // Header
                HStack {
                    Button(action: {
                        if step == .selectSymptom { dismiss() }
                        else { goBack() }
                    }) {
                        SSIconImage(name: step == .selectSymptom ? "ss.xmark" : "ss.chevron.left", size: 16)
                            .foregroundColor(Color.SS.textSecondary)
                    }
                    .accessibilityLabel(step == .selectSymptom ? "Close symptom log" : "Go back to \(stepTitle)")

                    Spacer()

                    Text(stepTitle)
                        .font(Font.SS.titleSmall)
                        .foregroundColor(Color.SS.textPrimary)
                        .tracking(0.3)

                    Spacer()

                    // Step indicator
                    Text("\(stepNumber)/4")
                        .font(Font.SS.labelSmall)
                        .foregroundColor(Color.SS.textTertiary)
                        .monospacedDigit()
                }
                .padding(.horizontal, Spacing.xl)
                .padding(.vertical, Spacing.md)

                // Progress
                HStack(spacing: 4) {
                    ForEach(0..<4) { i in
                        Capsule()
                            .fill(i < stepNumber ? Color.SS.accent : Color.SS.surfaceTertiary)
                            .frame(height: 2)
                    }
                }
                .padding(.horizontal, Spacing.xl)
                .animation(.easeOut(duration: 0.2), value: step)

                // Content
                Group {
                    switch step {
                    case .selectSymptom:
                        SymptomSelectionView(
                            searchText: $searchText,
                            selectedSymptom: $selectedSymptom
                        )
                    case .severity:
                        SeveritySelectionView(
                            symptom: selectedSymptom!,
                            severity: $severity
                        )
                    case .details:
                        DetailsEntryView(
                            notes: $notes,
                            selectedTriggers: $selectedTriggers,
                            selectedDuration: $selectedDuration
                        )
                    case .review:
                        ReviewView(
                            symptom: selectedSymptom!,
                            severity: Int(severity),
                            notes: notes,
                            triggers: Array(selectedTriggers),
                            duration: selectedDuration
                        )
                    }
                }
                .transition(.asymmetric(
                    insertion: .move(edge: .trailing).combined(with: .opacity),
                    removal: .move(edge: .leading).combined(with: .opacity)
                ))

                Spacer()

                // Bottom CTA
                VStack(spacing: Spacing.sm) {
                    SSButton(
                        title: step == .review ? "Save Entry" : "Continue",
                        isEnabled: canAdvance
                    ) {
                        advance()
                    }

                    if step != .selectSymptom {
                        Button("Skip") { advance() }
                            .font(Font.SS.labelSmall)
                            .foregroundColor(Color.SS.textTertiary)
                            .accessibilityLabel("Skip \(stepTitle) step")
                    }
                }
                .padding(.horizontal, Spacing.xl)
                .padding(.bottom, Spacing.xl)
            }

            // Success overlay
            if showSuccess {
                SuccessOverlay(feedback: feedbackMessage)
                    .transition(.opacity)
            }
        }
        .animation(.easeInOut(duration: 0.3), value: step)
    }

    private var stepTitle: String {
        switch step {
        case .selectSymptom: return "Select Symptom"
        case .severity: return "Rate Severity"
        case .details: return "Add Details"
        case .review: return "Review"
        }
    }

    private var stepNumber: Int {
        switch step {
        case .selectSymptom: return 1
        case .severity: return 2
        case .details: return 3
        case .review: return 4
        }
    }

    private var canAdvance: Bool {
        switch step {
        case .selectSymptom: return selectedSymptom != nil
        default: return true
        }
    }

    private func advance() {
        SSHaptics.light()
        withAnimation {
            switch step {
            case .selectSymptom: step = .severity
            case .severity: step = .details
            case .details: step = .review
            case .review: saveEntry()
            }
        }
    }

    private func goBack() {
        SSHaptics.selection()
        withAnimation {
            switch step {
            case .severity: step = .selectSymptom
            case .details: step = .severity
            case .review: step = .details
            default: break
            }
        }
    }

    private func saveEntry() {
        guard let symptom = selectedSymptom else { return }
        let entry = SymptomEntry(
            id: UUID(),
            symptomId: symptom.id,
            symptomName: symptom.name,
            severity: Int(severity),
            timestamp: Date(),
            notes: notes.isEmpty ? nil : notes,
            triggers: Array(selectedTriggers),
            duration: selectedDuration,
            location: nil
        )
        dataStore.addEntry(entry)
        feedbackMessage = dataStore.feedbackForEntry(entry)
        SSHaptics.success()
        withAnimation { showSuccess = true }
        DispatchQueue.main.asyncAfter(deadline: .now() + (feedbackMessage != nil ? 2.5 : 1.5)) {
            dismiss()
        }
    }
}

// MARK: - Symptom Selection
struct SymptomSelectionView: View {
    @EnvironmentObject var dataStore: DataStore
    @Binding var searchText: String
    @Binding var selectedSymptom: Symptom?
    @State private var selectedCategory: SymptomCategory?

    private var filteredSymptoms: [Symptom] {
        var symptoms = Symptom.library + dataStore.customSymptoms
        if let category = selectedCategory {
            symptoms = symptoms.filter { $0.category == category }
        }
        if !searchText.isEmpty {
            symptoms = symptoms.filter { $0.name.localizedCaseInsensitiveContains(searchText) }
        }
        return symptoms
    }

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: Spacing.md) {
                // Search
                SSTextField(placeholder: "Search symptoms...", text: $searchText, icon: "ss.magnifying")
                    .padding(.horizontal, Spacing.xl)
                    .padding(.top, Spacing.md)

                // Category filter
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: Spacing.xs) {
                        SSChip(
                            label: "All",
                            color: Color.SS.accent,
                            isSelected: selectedCategory == nil
                        )
                        .onTapGesture {
                            SSHaptics.selection()
                            selectedCategory = nil
                        }
                        .accessibilityLabel("Filter by All categories")

                        ForEach(SymptomCategory.allCases, id: \.self) { category in
                            SSChip(
                                label: category.rawValue,
                                color: category.color,
                                isSelected: selectedCategory == category
                            )
                            .onTapGesture {
                                SSHaptics.selection()
                                selectedCategory = selectedCategory == category ? nil : category
                            }
                            .accessibilityLabel("Filter by \(category.rawValue) category")
                        }
                    }
                    .padding(.horizontal, Spacing.xl)
                }

                // Symptoms grid
                if filteredSymptoms.isEmpty {
                    VStack(spacing: Spacing.sm) {
                        SSIconImage(name: "ss.magnifying", size: 24)
                            .foregroundColor(Color.SS.textDisabled)
                        Text("No symptoms found")
                            .font(Font.SS.bodyMedium)
                            .foregroundColor(Color.SS.textTertiary)
                        Text("Try a different search or category")
                            .font(Font.SS.caption)
                            .foregroundColor(Color.SS.textDisabled)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.top, Spacing.xxxl)
                } else {
                    LazyVGrid(columns: [
                        GridItem(.flexible(), spacing: Spacing.xs),
                        GridItem(.flexible(), spacing: Spacing.xs),
                        GridItem(.flexible(), spacing: Spacing.xs)
                    ], spacing: Spacing.xs) {
                        ForEach(filteredSymptoms) { symptom in
                            SymptomPickerCard(
                                symptom: symptom,
                                isSelected: selectedSymptom?.id == symptom.id
                            ) {
                                SSHaptics.selection()
                                selectedSymptom = symptom
                            }
                        }
                    }
                    .padding(.horizontal, Spacing.xl)
                }

                Spacer(minLength: 100)
            }
        }
    }
}

struct SymptomPickerCard: View {
    let symptom: Symptom
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                SSIconImage(name: symptom.icon, size: 20)
                    .foregroundColor(isSelected ? Color(hex: symptom.color) : Color.SS.textTertiary)

                Text(symptom.name)
                    .font(Font.SS.labelSmall)
                    .foregroundColor(isSelected ? Color.SS.textPrimary : Color.SS.textSecondary)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, Spacing.sm)
            .background(
                RoundedRectangle(cornerRadius: Radius.md)
                    .fill(isSelected ? Color(hex: symptom.color).opacity(0.08) : Color.SS.surfaceSecondary)
            )
            .overlay(
                RoundedRectangle(cornerRadius: Radius.md)
                    .strokeBorder(
                        isSelected ? Color(hex: symptom.color).opacity(0.4) : Color.SS.separator,
                        lineWidth: isSelected ? 1 : 0.5
                    )
            )
        }
        .buttonStyle(PlainButtonStyle())
        .accessibilityLabel("Select \(symptom.name) symptom")
        .animation(.easeOut(duration: 0.15), value: isSelected)
    }
}

// MARK: - Severity Selection
struct SeveritySelectionView: View {
    let symptom: Symptom
    @Binding var severity: Double

    var body: some View {
        VStack(spacing: Spacing.xxxl) {
            Spacer()

            // Large severity number
            ZStack {
                Circle()
                    .stroke(severityColor.opacity(0.15), lineWidth: 2)
                    .frame(width: 160, height: 160)

                Circle()
                    .trim(from: 0, to: severity / 10)
                    .stroke(
                        severityColor,
                        style: StrokeStyle(lineWidth: 2, lineCap: .round)
                    )
                    .frame(width: 160, height: 160)
                    .rotationEffect(.degrees(-90))

                VStack(spacing: 4) {
                    Text("\(Int(severity))")
                        .font(.system(size: 56, weight: .ultraLight, design: .monospaced))
                        .foregroundColor(Color.SS.textPrimary)
                        .contentTransition(.numericText())

                    Text(severityLabel)
                        .font(Font.SS.labelMedium)
                        .foregroundColor(severityColor)
                        .tracking(0.5)
                }
            }
            .animation(.easeOut(duration: 0.2), value: severity)

            // Slider
            VStack(spacing: Spacing.md) {
                Slider(value: $severity, in: 1...10, step: 1)
                    .tint(severityColor)
                    .onChange(of: severity) { SSHaptics.selection() }
                    .accessibilityLabel("Symptom severity")
                    .accessibilityValue("Set severity to \(Int(severity)) out of 10")

                HStack {
                    Text("Mild")
                        .font(Font.SS.caption)
                        .foregroundColor(Color.SS.textTertiary)
                    Spacer()
                    Text("Severe")
                        .font(Font.SS.caption)
                        .foregroundColor(Color.SS.textTertiary)
                }
            }
            .padding(.horizontal, Spacing.xl)

            Spacer()
        }
    }

    private var severityLabel: String {
        switch Int(severity) {
        case 1...2: return "Barely noticeable"
        case 3...4: return "Mild"
        case 5...6: return "Moderate"
        case 7...8: return "Severe"
        default: return "Very severe"
        }
    }

    private var severityColor: Color {
        switch Int(severity) {
        case 1...2: return Color.SS.severityNone
        case 3...4: return Color.SS.severityMild
        case 5...6: return Color.SS.severityModerate
        case 7...8: return Color.SS.severitySevere
        default: return Color.SS.severityCritical
        }
    }
}

// MARK: - Details Entry
struct DetailsEntryView: View {
    @Binding var notes: String
    @Binding var selectedTriggers: Set<String>
    @Binding var selectedDuration: SymptomEntry.SymptomDuration?

    private let commonTriggers = [
        "Stress", "Poor sleep", "Weather", "Food", "Exercise",
        "Screen time", "Alcohol", "Caffeine", "Dehydration", "Medication"
    ]

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: Spacing.xl) {
                // Duration
                VStack(alignment: .leading, spacing: Spacing.sm) {
                    Text("Duration")
                        .font(Font.SS.labelMedium)
                        .foregroundColor(Color.SS.textTertiary)
                        .tracking(0.5)
                        .padding(.horizontal, Spacing.xl)

                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: Spacing.xs) {
                            ForEach(SymptomEntry.SymptomDuration.allCases, id: \.self) { duration in
                                SSChip(
                                    label: duration.rawValue,
                                    isSelected: selectedDuration == duration
                                )
                                .onTapGesture {
                                    SSHaptics.selection()
                                    selectedDuration = selectedDuration == duration ? nil : duration
                                }
                                .accessibilityLabel("Select duration \(duration.rawValue)")
                            }
                        }
                        .padding(.horizontal, Spacing.xl)
                    }
                }
                .padding(.top, Spacing.md)

                // Triggers
                VStack(alignment: .leading, spacing: Spacing.sm) {
                    Text("Possible triggers")
                        .font(Font.SS.labelMedium)
                        .foregroundColor(Color.SS.textTertiary)
                        .tracking(0.5)
                        .padding(.horizontal, Spacing.xl)

                    FlowLayout(spacing: Spacing.xs) {
                        ForEach(commonTriggers, id: \.self) { trigger in
                            SSChip(
                                label: trigger,
                                color: Color.SS.violet,
                                isSelected: selectedTriggers.contains(trigger)
                            )
                            .onTapGesture {
                                SSHaptics.selection()
                                if selectedTriggers.contains(trigger) {
                                    selectedTriggers.remove(trigger)
                                } else {
                                    selectedTriggers.insert(trigger)
                                }
                            }
                            .accessibilityLabel("\(selectedTriggers.contains(trigger) ? "Remove" : "Add") \(trigger) trigger")
                        }
                    }
                    .padding(.horizontal, Spacing.xl)
                }

                // Notes
                VStack(alignment: .leading, spacing: Spacing.sm) {
                    Text("Notes")
                        .font(Font.SS.labelMedium)
                        .foregroundColor(Color.SS.textTertiary)
                        .tracking(0.5)

                    TextEditor(text: $notes)
                        .font(Font.SS.bodySmall)
                        .foregroundColor(Color.SS.textPrimary)
                        .frame(minHeight: 100)
                        .scrollContentBackground(.hidden)
                        .padding(Spacing.sm)
                        .background(Color.SS.surfaceSecondary)
                        .overlay(
                            RoundedRectangle(cornerRadius: Radius.md)
                                .strokeBorder(Color.SS.separator, lineWidth: 0.5)
                        )
                        .clipShape(RoundedRectangle(cornerRadius: Radius.md))
                }
                .padding(.horizontal, Spacing.xl)

                Spacer(minLength: 100)
            }
        }
    }
}

// MARK: - Flow Layout
struct FlowLayout: Layout {
    var spacing: CGFloat

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let result = arrange(proposal: proposal, subviews: subviews)
        return result.size
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = arrange(proposal: proposal, subviews: subviews)
        for (index, subview) in subviews.enumerated() {
            if index < result.positions.count {
                subview.place(at: CGPoint(
                    x: bounds.minX + result.positions[index].x,
                    y: bounds.minY + result.positions[index].y
                ), proposal: .unspecified)
            }
        }
    }

    private func arrange(proposal: ProposedViewSize, subviews: Subviews) -> (positions: [CGPoint], size: CGSize) {
        let maxWidth = proposal.width ?? .infinity
        var positions: [CGPoint] = []
        var x: CGFloat = 0
        var y: CGFloat = 0
        var maxHeight: CGFloat = 0
        var rowHeight: CGFloat = 0

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if x + size.width > maxWidth && x > 0 {
                x = 0
                y += rowHeight + spacing
                rowHeight = 0
            }
            positions.append(CGPoint(x: x, y: y))
            rowHeight = max(rowHeight, size.height)
            x += size.width + spacing
            maxHeight = max(maxHeight, y + rowHeight)
        }

        return (positions, CGSize(width: maxWidth, height: maxHeight))
    }
}

// MARK: - Review View
struct ReviewView: View {
    let symptom: Symptom
    let severity: Int
    let notes: String
    let triggers: [String]
    let duration: SymptomEntry.SymptomDuration?

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: Spacing.lg) {
                // Summary card
                SSCard(padding: Spacing.lg) {
                    VStack(spacing: Spacing.md) {
                        HStack {
                            SSIconImage(name: symptom.icon, size: 24)
                                .foregroundColor(Color(hex: symptom.color))

                            VStack(alignment: .leading, spacing: 2) {
                                Text(symptom.name)
                                    .font(Font.SS.headlineMedium)
                                    .foregroundColor(Color.SS.textPrimary)
                                Text(symptom.category.rawValue)
                                    .font(Font.SS.labelSmall)
                                    .foregroundColor(Color.SS.textTertiary)
                            }

                            Spacer()

                            VStack(spacing: 2) {
                                Text("\(severity)")
                                    .font(Font.SS.dataLarge)
                                    .foregroundColor(Color.SS.textPrimary)
                                Text("/10")
                                    .font(Font.SS.labelSmall)
                                    .foregroundColor(Color.SS.textTertiary)
                            }
                        }

                        SSSeverityBar(severity: severity)

                        SSDivider()

                        if let duration = duration {
                            ReviewRow(label: "Duration", value: duration.rawValue)
                        }

                        if !triggers.isEmpty {
                            ReviewRow(label: "Triggers", value: triggers.joined(separator: ", "))
                        }

                        if !notes.isEmpty {
                            ReviewRow(label: "Notes", value: notes)
                        }

                        ReviewRow(label: "Time", value: Date().formatted(date: .abbreviated, time: .shortened))
                    }
                }
                .padding(.horizontal, Spacing.xl)
                .padding(.top, Spacing.md)

                Spacer(minLength: 100)
            }
        }
    }
}

struct ReviewRow: View {
    let label: String
    let value: String

    var body: some View {
        HStack(alignment: .top) {
            Text(label)
                .font(Font.SS.labelMedium)
                .foregroundColor(Color.SS.textTertiary)
                .frame(width: 80, alignment: .leading)

            Text(value)
                .font(Font.SS.bodySmall)
                .foregroundColor(Color.SS.textSecondary)
                .lineSpacing(4)

            Spacer()
        }
    }
}

// MARK: - Success Overlay
struct SuccessOverlay: View {
    var feedback: (message: String, color: String)? = nil
    @State private var animate = false
    @State private var showFeedback = false

    var body: some View {
        ZStack {
            Color.SS.overlayHeavy.ignoresSafeArea()

            VStack(spacing: Spacing.lg) {
                ZStack {
                    Circle()
                        .fill(Color.SS.accent.opacity(0.1))
                        .frame(width: 100, height: 100)
                        .scaleEffect(animate ? 1.2 : 0.8)
                        .opacity(animate ? 0 : 1)

                    SSIconImage(name: "ss.checkmark.circle", size: 60)
                        .foregroundColor(Color.SS.accent)
                        .scaleEffect(animate ? 1 : 0.5)
                }

                Text("Saved")
                    .font(Font.SS.headlineMedium)
                    .foregroundColor(Color.SS.textPrimary)
                    .opacity(animate ? 1 : 0)

                // Post-logging contextual feedback
                if let feedback = feedback, showFeedback {
                    Text(feedback.message)
                        .font(Font.SS.bodySmall)
                        .foregroundColor(Color(hex: feedback.color))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, Spacing.xxl)
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                }
            }
        }
        .onAppear {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
                animate = true
            }
            if feedback != nil {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
                    withAnimation(.easeOut(duration: 0.3)) {
                        showFeedback = true
                    }
                }
            }
        }
    }
}
