import SwiftUI

struct SymptomDetailView: View {
    let entry: SymptomEntry
    @Environment(\.dismiss) var dismiss

    private var symptomData: Symptom? {
        Symptom.library.first(where: { $0.id == entry.symptomId || $0.name == entry.symptomName })
    }

    private var severityColor: Color {
        switch entry.severity {
        case 1...3: return Color.SS.severityMild
        case 4...6: return Color.SS.severityModerate
        case 7...8: return Color.SS.severitySevere
        default: return Color.SS.severityCritical
        }
    }

    private var severityLabel: String {
        switch entry.severity {
        case 1...2: return "Very Mild"
        case 3...4: return "Mild"
        case 5...6: return "Moderate"
        case 7...8: return "Severe"
        default: return "Very Severe"
        }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color.SS.background.ignoresSafeArea()

                ScrollView(showsIndicators: false) {
                    VStack(spacing: Spacing.xl) {
                        // Hero section
                        VStack(spacing: Spacing.md) {
                            ZStack {
                                Circle()
                                    .fill(severityColor.opacity(0.1))
                                    .frame(width: 100, height: 100)
                                Circle()
                                    .strokeBorder(severityColor.opacity(0.3), lineWidth: 1)
                                    .frame(width: 100, height: 100)

                                if let symptom = symptomData {
                                    SSIconImage(name: symptom.icon, size: 36)
                                        .foregroundColor(Color(hex: symptom.color))
                                } else {
                                    SSIconImage(name: "ss.ecg", size: 36)
                                        .foregroundColor(severityColor)
                                }
                            }

                            Text(entry.symptomName)
                                .font(Font.SS.displaySmall)
                                .foregroundColor(Color.SS.textPrimary)

                            // Timestamp
                            VStack(spacing: 2) {
                                Text(entry.timestamp, style: .date)
                                    .font(Font.SS.bodySmall)
                                    .foregroundColor(Color.SS.textSecondary)
                                Text(entry.timestamp, style: .time)
                                    .font(Font.SS.labelSmall)
                                    .foregroundColor(Color.SS.textTertiary)
                            }
                        }
                        .padding(.top, Spacing.lg)

                        // Severity card
                        SSCard(padding: Spacing.md) {
                            VStack(spacing: Spacing.sm) {
                                HStack {
                                    Text("Severity")
                                        .font(Font.SS.labelMedium)
                                        .foregroundColor(Color.SS.textTertiary)
                                        .tracking(0.5)
                                    Spacer()
                                    Text(severityLabel)
                                        .font(Font.SS.labelSmall)
                                        .foregroundColor(severityColor)
                                }

                                // Severity bar
                                GeometryReader { geo in
                                    ZStack(alignment: .leading) {
                                        RoundedRectangle(cornerRadius: 4)
                                            .fill(Color.SS.surfaceTertiary)
                                        RoundedRectangle(cornerRadius: 4)
                                            .fill(
                                                LinearGradient(
                                                    colors: [Color.SS.success, Color.SS.warning, Color.SS.error],
                                                    startPoint: .leading,
                                                    endPoint: .trailing
                                                )
                                            )
                                            .frame(width: geo.size.width * CGFloat(entry.severity) / 10.0)
                                    }
                                }
                                .frame(height: 8)

                                HStack {
                                    Text("\(entry.severity)")
                                        .font(Font.SS.dataLarge)
                                        .foregroundColor(severityColor)
                                    Text("/10")
                                        .font(Font.SS.labelSmall)
                                        .foregroundColor(Color.SS.textDisabled)
                                    Spacer()
                                }
                            }
                        }
                        .padding(.horizontal, Spacing.xl)

                        // Duration
                        if let duration = entry.duration {
                            SSCard(padding: Spacing.md) {
                                HStack(spacing: Spacing.md) {
                                    SSIconImage(name: "ss.clock", size: 18)
                                        .foregroundColor(Color.SS.accent)
                                        .frame(width: 28)
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text("Duration")
                                            .font(Font.SS.labelMedium)
                                            .foregroundColor(Color.SS.textTertiary)
                                            .tracking(0.5)
                                        Text(duration.rawValue)
                                            .font(Font.SS.bodyMedium)
                                            .foregroundColor(Color.SS.textPrimary)
                                    }
                                    Spacer()
                                }
                            }
                            .padding(.horizontal, Spacing.xl)
                        }

                        // Triggers
                        if !entry.triggers.isEmpty {
                            SSCard(padding: Spacing.md) {
                                VStack(alignment: .leading, spacing: Spacing.sm) {
                                    HStack {
                                        SSIconImage(name: "ss.sparkles", size: 14)
                                            .foregroundColor(Color.SS.warning)
                                        Text("Triggers")
                                            .font(Font.SS.labelMedium)
                                            .foregroundColor(Color.SS.textTertiary)
                                            .tracking(0.5)
                                    }

                                    FlowLayout(spacing: Spacing.xs) {
                                        ForEach(entry.triggers, id: \.self) { trigger in
                                            SSChip(label: trigger, color: Color.SS.warning)
                                        }
                                    }
                                }
                            }
                            .padding(.horizontal, Spacing.xl)
                        }

                        // Notes
                        if let notes = entry.notes, !notes.isEmpty {
                            SSCard(padding: Spacing.md) {
                                VStack(alignment: .leading, spacing: Spacing.sm) {
                                    HStack {
                                        SSIconImage(name: "ss.doc", size: 14)
                                            .foregroundColor(Color.SS.violet)
                                        Text("Notes")
                                            .font(Font.SS.labelMedium)
                                            .foregroundColor(Color.SS.textTertiary)
                                            .tracking(0.5)
                                    }

                                    Text(notes)
                                        .font(Font.SS.bodySmall)
                                        .foregroundColor(Color.SS.textSecondary)
                                        .lineSpacing(4)
                                }
                            }
                            .padding(.horizontal, Spacing.xl)
                        }

                        // Category info
                        if let symptom = symptomData {
                            SSCard(padding: Spacing.md) {
                                HStack(spacing: Spacing.md) {
                                    SSIconImage(name: symptom.category.icon, size: 18)
                                        .foregroundColor(symptom.category.color)
                                        .frame(width: 28)
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text("Category")
                                            .font(Font.SS.labelMedium)
                                            .foregroundColor(Color.SS.textTertiary)
                                            .tracking(0.5)
                                        Text(symptom.category.rawValue)
                                            .font(Font.SS.bodyMedium)
                                            .foregroundColor(Color.SS.textPrimary)
                                    }
                                    Spacer()
                                }
                            }
                            .padding(.horizontal, Spacing.xl)
                        }

                        Spacer(minLength: 60)
                    }
                }
            }
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
