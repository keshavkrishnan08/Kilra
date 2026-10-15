import SwiftUI

// MARK: - ECG Pulse Line Shape
struct ECGPulseLine: Shape {
    var phase: CGFloat

    var animatableData: CGFloat {
        get { phase }
        set { phase = newValue }
    }

    func path(in rect: CGRect) -> Path {
        var path = Path()
        let midY = rect.midY
        let segmentWidth = rect.width / 3.0
        let offset = phase * segmentWidth

        // Draw two full heartbeat waveform cycles across the rect, shifted by phase
        for cycle in -1..<3 {
            let baseX = CGFloat(cycle) * segmentWidth - offset

            // Flat lead-in
            let startX = baseX
            let flatEnd = baseX + segmentWidth * 0.35
            if cycle == -1 && startX < rect.minX {
                path.move(to: CGPoint(x: rect.minX, y: midY))
            } else if path.isEmpty {
                path.move(to: CGPoint(x: startX, y: midY))
            } else {
                path.addLine(to: CGPoint(x: startX, y: midY))
            }
            path.addLine(to: CGPoint(x: flatEnd, y: midY))

            // Small P-wave bump
            let pPeak = baseX + segmentWidth * 0.42
            path.addQuadCurve(
                to: CGPoint(x: baseX + segmentWidth * 0.48, y: midY),
                control: CGPoint(x: pPeak, y: midY - rect.height * 0.12)
            )

            // Sharp QRS complex: Q dip, R peak, S dip
            let qX = baseX + segmentWidth * 0.50
            let rX = baseX + segmentWidth * 0.55
            let sX = baseX + segmentWidth * 0.60
            let postS = baseX + segmentWidth * 0.64

            path.addLine(to: CGPoint(x: qX, y: midY + rect.height * 0.10))
            path.addLine(to: CGPoint(x: rX, y: midY - rect.height * 0.45))
            path.addLine(to: CGPoint(x: sX, y: midY + rect.height * 0.18))
            path.addLine(to: CGPoint(x: postS, y: midY))

            // T-wave: gentle rounded bump
            let tPeak = baseX + segmentWidth * 0.74
            path.addQuadCurve(
                to: CGPoint(x: baseX + segmentWidth * 0.84, y: midY),
                control: CGPoint(x: tPeak, y: midY - rect.height * 0.18)
            )

            // Flat tail
            path.addLine(to: CGPoint(x: baseX + segmentWidth, y: midY))
        }

        return path
    }
}

// MARK: - Page 1: Welcome: Breathing concentric rings
struct OnboardingWelcomePage: View {
    @State private var animate = false
    @State private var ecgPhase: CGFloat = 0

    var body: some View {
        VStack(spacing: Spacing.xxl) {
            Spacer()

            ZStack {
                // Animated ECG waveform behind everything
                ECGPulseLine(phase: ecgPhase)
                    .stroke(Color.SS.accent.opacity(0.15), lineWidth: 1)
                    .frame(height: 60)
                    .clipped()
                    .onAppear {
                        withAnimation(.linear(duration: 2.0).repeatForever(autoreverses: false)) {
                            ecgPhase = 1.0
                        }
                    }

                ForEach(0..<4) { i in
                    Circle()
                        .stroke(
                            Color.SS.accent.opacity(Double(4 - i) * 0.08),
                            lineWidth: 0.5
                        )
                        .frame(
                            width: CGFloat(60 + i * 40),
                            height: CGFloat(60 + i * 40)
                        )
                        .scaleEffect(animate ? 1.0 : 0.85)
                        .animation(
                            .easeInOut(duration: 2.5)
                            .repeatForever(autoreverses: true)
                            .delay(Double(i) * 0.3),
                            value: animate
                        )
                }

                SSIconImage(name: "ss.ecg", size: 32)
                    .foregroundStyle(Color.SS.gradientPrimary)
                    .scaleEffect(animate ? 1.05 : 0.95)
                    .animation(
                        .easeInOut(duration: 1.8)
                        .repeatForever(autoreverses: true),
                        value: animate
                    )
            }
            .frame(height: 220)

            VStack(spacing: Spacing.md) {
                Text("Your symptoms\ntell a story")
                    .font(Font.SS.displayMedium)
                    .foregroundColor(Color.SS.textPrimary)
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)

                Text("Discover hidden patterns, identify triggers,\nand take control of your health journey")
                    .font(Font.SS.bodyMedium)
                    .foregroundColor(Color.SS.textSecondary)
                    .multilineTextAlignment(.center)
                    .lineSpacing(6)
            }

            VStack(spacing: Spacing.sm) {
                OnboardingFeatureRow(icon: "ss.tab.insights", text: "AI-powered pattern recognition")
                OnboardingFeatureRow(icon: "ss.bell.badge", text: "Smart symptom reminders")
                OnboardingFeatureRow(icon: "ss.doc.search", text: "Shareable health reports")
            }
            .padding(.horizontal, Spacing.xxl)

            Spacer()
            Spacer()
        }
        .padding(.horizontal, Spacing.xl)
        .onAppear { animate = true }
    }
}

struct OnboardingFeatureRow: View {
    let icon: String
    let text: String

    var body: some View {
        HStack(spacing: Spacing.sm) {
            SSIconImage(name: icon, size: 14)
                .foregroundColor(Color.SS.accent)
                .frame(width: 28)
            Text(text)
                .font(Font.SS.bodySmall)
                .foregroundColor(Color.SS.textSecondary)
                .tracking(0.3)
            Spacer()
        }
    }
}

// MARK: - Page 2: Goals: Horizontal scrolling card carousel
struct OnboardingGoalPage: View {
    @Binding var answers: [String: Any]
    @State private var selected: Set<String> = []
    @State private var appeared = false

    private let goals: [(icon: String, title: String, subtitle: String, color: Color)] = [
        ("ss.tab.insights", "Track symptoms", "Build a complete health picture", Color.SS.accent),
        ("ss.magnifying", "Find triggers", "Discover what causes flare-ups", Color(hex: "818CF8")),
        ("ss.doc", "Share with doctor", "Generate professional reports", Color(hex: "60A5FA")),
        ("ss.head.brain", "Understand my body", "Learn how your body responds", Color(hex: "F472B6")),
        ("ss.pills", "Monitor treatment", "See medication impact", Color(hex: "34D399")),
        ("ss.cat.mental", "Mental wellness", "Track mood & emotional health", Color(hex: "FBBF24")),
    ]

    var body: some View {
        VStack(spacing: Spacing.xl) {
            VStack(spacing: Spacing.sm) {
                Text("What brings you here?")
                    .font(Font.SS.displaySmall)
                    .foregroundColor(Color.SS.textPrimary)

                Text("Tap all that resonate with you")
                    .font(Font.SS.bodySmall)
                    .foregroundColor(Color.SS.textTertiary)
                    .tracking(0.5)
            }
            .padding(.top, Spacing.xxl)

            // 2-column masonry-style cards with staggered heights
            ScrollView(showsIndicators: false) {
                LazyVGrid(columns: [
                    GridItem(.flexible(), spacing: Spacing.sm),
                    GridItem(.flexible(), spacing: Spacing.sm)
                ], spacing: Spacing.sm) {
                    ForEach(Array(goals.enumerated()), id: \.element.title) { index, goal in
                        let isOn = selected.contains(goal.title)
                        Button(action: {
                            SSHaptics.selection()
                            if isOn { selected.remove(goal.title) }
                            else { selected.insert(goal.title) }
                            answers["goals"] = Array(selected)
                        }) {
                            VStack(spacing: Spacing.sm) {
                                ZStack {
                                    Circle()
                                        .fill(isOn ? goal.color.opacity(0.15) : Color.SS.surfaceTertiary)
                                        .frame(width: 52, height: 52)

                                    SSIconImage(name: goal.icon, size: 22)
                                        .foregroundColor(isOn ? goal.color : Color.SS.textTertiary)
                                }

                                Text(goal.title)
                                    .font(Font.SS.accentSmall)
                                    .foregroundColor(isOn ? Color.SS.textPrimary : Color.SS.textSecondary)

                                Text(goal.subtitle)
                                    .font(Font.SS.caption)
                                    .foregroundColor(Color.SS.textTertiary)
                                    .multilineTextAlignment(.center)
                                    .lineLimit(2)
                            }
                            .padding(.vertical, Spacing.md)
                            .padding(.horizontal, Spacing.sm)
                            .frame(maxWidth: .infinity)
                            .frame(minHeight: index % 2 == 0 ? 160 : 140)
                            .background(
                                RoundedRectangle(cornerRadius: Radius.lg)
                                    .fill(isOn ? goal.color.opacity(0.06) : Color.SS.surfaceSecondary)
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: Radius.lg)
                                    .strokeBorder(
                                        isOn ? goal.color.opacity(0.5) : Color.SS.separator,
                                        lineWidth: isOn ? 1.5 : 0.5
                                    )
                            )
                        }
                        .buttonStyle(PlainButtonStyle())
                        .scaleEffect(appeared ? 1 : 0.8)
                        .opacity(appeared ? 1 : 0)
                        .animation(
                            .spring(response: 0.5, dampingFraction: 0.7).delay(Double(index) * 0.08),
                            value: appeared
                        )
                    }
                }
                .padding(.horizontal, Spacing.xl)

                Spacer(minLength: 120)
            }
        }
        .onAppear { appeared = true }
    }
}

// MARK: - Page 3: Symptoms: Category grid (already unique pattern)
struct OnboardingSymptomsPage: View {
    @Binding var answers: [String: Any]
    @State private var selectedCategories: Set<String> = []
    @State private var appeared = false

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: Spacing.xl) {
                VStack(spacing: Spacing.sm) {
                    Text("What do you\nexperience?")
                        .font(Font.SS.displaySmall)
                        .foregroundColor(Color.SS.textPrimary)
                        .multilineTextAlignment(.center)

                    Text("We'll customize your tracking dashboard")
                        .font(Font.SS.bodySmall)
                        .foregroundColor(Color.SS.textTertiary)
                        .tracking(0.5)
                }
                .padding(.top, Spacing.xl)

                LazyVGrid(columns: [
                    GridItem(.flexible(), spacing: Spacing.sm),
                    GridItem(.flexible(), spacing: Spacing.sm)
                ], spacing: Spacing.sm) {
                    ForEach(Array(SymptomCategory.allCases.enumerated()), id: \.element) { index, category in
                        OnboardingCategoryCard(
                            category: category,
                            isSelected: selectedCategories.contains(category.rawValue)
                        ) {
                            SSHaptics.selection()
                            if selectedCategories.contains(category.rawValue) {
                                selectedCategories.remove(category.rawValue)
                            } else {
                                selectedCategories.insert(category.rawValue)
                            }
                            answers["categories"] = Array(selectedCategories)
                        }
                        .scaleEffect(appeared ? 1 : 0.85)
                        .opacity(appeared ? 1 : 0)
                        .animation(
                            .spring(response: 0.4, dampingFraction: 0.75).delay(Double(index) * 0.05),
                            value: appeared
                        )
                    }
                }
                .padding(.horizontal, Spacing.xl)

                Spacer(minLength: 120)
            }
        }
        .onAppear { appeared = true }
    }
}

struct OnboardingCategoryCard: View {
    let category: SymptomCategory
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: Spacing.sm) {
                SSIconImage(name: category.icon, size: 24)
                    .foregroundColor(isSelected ? category.color : Color.SS.textTertiary)

                Text(category.rawValue)
                    .font(Font.SS.labelMedium)
                    .foregroundColor(isSelected ? Color.SS.textPrimary : Color.SS.textSecondary)
                    .tracking(0.3)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 100)
            .background(
                RoundedRectangle(cornerRadius: Radius.lg)
                    .fill(isSelected ? category.color.opacity(0.08) : Color.SS.surfaceSecondary)
            )
            .overlay(
                RoundedRectangle(cornerRadius: Radius.lg)
                    .strokeBorder(
                        isSelected ? category.color.opacity(0.4) : Color.SS.separator,
                        lineWidth: isSelected ? 1 : 0.5
                    )
            )
        }
        .buttonStyle(PlainButtonStyle())
        .animation(.easeOut(duration: 0.2), value: isSelected)
    }
}

// MARK: - Page 4: Frequency: Interactive animated bar chart
struct OnboardingFrequencyPage: View {
    @Binding var answers: [String: Any]
    @State private var selected: String = ""
    @State private var animateBars = false

    private let options = [
        ("Daily", 7),
        ("Several times a week", 4),
        ("Weekly", 1),
        ("Occasionally", 0),
        ("Rarely", 0),
    ]

    // Bar heights per selection
    private func barHeights(for option: String) -> [CGFloat] {
        switch option {
        case "Daily": return [0.9, 0.7, 0.85, 0.6, 0.95, 0.75, 0.8]
        case "Several times a week": return [0.8, 0, 0.6, 0.7, 0, 0.5, 0]
        case "Weekly": return [0, 0, 0, 0.7, 0, 0, 0]
        case "Occasionally": return [0, 0.5, 0, 0, 0, 0, 0.4]
        case "Rarely": return [0, 0, 0, 0, 0, 0.3, 0]
        default: return [0.3, 0.2, 0.4, 0.25, 0.35, 0.15, 0.3]
        }
    }

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: Spacing.xl) {
                VStack(spacing: Spacing.sm) {
                    Text("How often do symptoms\naffect you?")
                        .font(Font.SS.displaySmall)
                        .foregroundColor(Color.SS.textPrimary)
                        .multilineTextAlignment(.center)
                }
                .padding(.top, Spacing.xl)

                // Interactive bar chart
                HStack(alignment: .bottom, spacing: 8) {
                    let heights = barHeights(for: selected)
                    ForEach(0..<7, id: \.self) { day in
                        VStack(spacing: 6) {
                            RoundedRectangle(cornerRadius: 4)
                                .fill(
                                    heights[day] > 0
                                    ? Color.SS.accent.opacity(0.3 + heights[day] * 0.7)
                                    : Color.SS.surfaceTertiary
                                )
                                .frame(
                                    width: 32,
                                    height: max(8, heights[day] * 80)
                                )
                                .animation(.spring(response: 0.5, dampingFraction: 0.7).delay(Double(day) * 0.04), value: selected)

                            Text(["M","T","W","T","F","S","S"][day])
                                .font(Font.SS.caption)
                                .foregroundColor(Color.SS.textTertiary)
                        }
                    }
                }
                .frame(height: 120)
                .padding(.horizontal, Spacing.xxl)

                // Horizontal pill selectors
                VStack(spacing: Spacing.xs) {
                    ForEach(options, id: \.0) { option in
                        Button(action: {
                            SSHaptics.selection()
                            selected = option.0
                            answers["frequency"] = option.0
                        }) {
                            HStack {
                                Text(option.0)
                                    .font(Font.SS.bodyMedium)
                                    .foregroundColor(selected == option.0 ? Color.SS.textPrimary : Color.SS.textSecondary)

                                Spacer()

                                if selected == option.0 {
                                    SSIconImage(name: "ss.checkmark", size: 12)
                                        .foregroundColor(Color.SS.accent)
                                        .transition(.scale.combined(with: .opacity))
                                }
                            }
                            .padding(.horizontal, Spacing.lg)
                            .padding(.vertical, Spacing.md)
                            .background(
                                RoundedRectangle(cornerRadius: Radius.lg)
                                    .fill(selected == option.0 ? Color.SS.accentSubtle : Color.SS.surfaceSecondary)
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: Radius.lg)
                                    .strokeBorder(
                                        selected == option.0 ? Color.SS.accent.opacity(0.4) : Color.SS.separator,
                                        lineWidth: selected == option.0 ? 1 : 0.5
                                    )
                            )
                        }
                        .buttonStyle(PlainButtonStyle())
                        .animation(.easeOut(duration: 0.2), value: selected)
                    }
                }
                .padding(.horizontal, Spacing.xl)

                Spacer(minLength: 120)
            }
        }
    }
}

// MARK: - Page 5: Impact: Orbital ring layout
struct OnboardingImpactPage: View {
    @Binding var answers: [String: Any]
    @State private var selected: Set<String> = []
    @State private var orbitAnimate = false

    private let impacts: [(icon: String, label: String, color: Color)] = [
        ("ss.bed", "Sleep", Color(hex: "818CF8")),
        ("ss.briefcase", "Work", Color(hex: "60A5FA")),
        ("ss.figure.walk", "Activity", Color(hex: "34D399")),
        ("ss.person.2", "Social", Color(hex: "F472B6")),
        ("ss.fork.knife", "Diet", Color(hex: "FBBF24")),
        ("ss.cat.neuro", "Focus", Color(hex: "A78BFA")),
    ]

    var body: some View {
        VStack(spacing: Spacing.xl) {
            VStack(spacing: Spacing.sm) {
                Text("What areas of life\nare affected?")
                    .font(Font.SS.displaySmall)
                    .foregroundColor(Color.SS.textPrimary)
                    .multilineTextAlignment(.center)

                Text("This helps us provide better insights")
                    .font(Font.SS.bodySmall)
                    .foregroundColor(Color.SS.textTertiary)
                    .tracking(0.5)
            }
            .padding(.top, Spacing.xl)

            // Orbital layout: icons arranged in a circle
            ZStack {
                // Outer orbit ring
                Circle()
                    .stroke(Color.SS.separator, lineWidth: 0.5)
                    .frame(width: 260, height: 260)

                // Subtle spinning dot on orbit
                Circle()
                    .fill(Color.SS.accent.opacity(0.3))
                    .frame(width: 4, height: 4)
                    .offset(y: -130)
                    .rotationEffect(.degrees(orbitAnimate ? 360 : 0))
                    .animation(.linear(duration: 12).repeatForever(autoreverses: false), value: orbitAnimate)

                // Center label
                VStack(spacing: 4) {
                    Text("\(selected.count)")
                        .font(.system(size: 32, weight: .ultraLight, design: .monospaced))
                        .foregroundColor(Color.SS.textPrimary)
                        .contentTransition(.numericText())
                    Text("areas")
                        .font(Font.SS.caption)
                        .foregroundColor(Color.SS.textTertiary)
                }

                // Impact items arranged in circle
                ForEach(Array(impacts.enumerated()), id: \.element.label) { index, impact in
                    let angle = (Double(index) / Double(impacts.count)) * 360.0 - 90.0
                    let radians = angle * .pi / 180.0
                    let radius: CGFloat = 120
                    let x = cos(radians) * radius
                    let y = sin(radians) * radius
                    let isOn = selected.contains(impact.label)

                    Button(action: {
                        SSHaptics.selection()
                        if isOn { selected.remove(impact.label) }
                        else { selected.insert(impact.label) }
                        answers["impacts"] = Array(selected)
                    }) {
                        VStack(spacing: 4) {
                            ZStack {
                                Circle()
                                    .fill(isOn ? impact.color.opacity(0.15) : Color.SS.surfaceSecondary)
                                    .frame(width: 56, height: 56)
                                Circle()
                                    .strokeBorder(
                                        isOn ? impact.color : Color.SS.separator,
                                        lineWidth: isOn ? 1.5 : 0.5
                                    )
                                    .frame(width: 56, height: 56)
                                SSIconImage(name: impact.icon, size: 22)
                                    .foregroundColor(isOn ? impact.color : Color.SS.textTertiary)
                            }
                            Text(impact.label)
                                .font(Font.SS.caption)
                                .foregroundColor(isOn ? Color.SS.textPrimary : Color.SS.textTertiary)
                        }
                    }
                    .buttonStyle(PlainButtonStyle())
                    .offset(x: x, y: y)
                    .animation(.spring(response: 0.3), value: isOn)
                }
            }
            .frame(height: 320)

            Spacer()
            Spacer(minLength: 120)
        }
        .onAppear { orbitAnimate = true }
    }
}

// MARK: - Page 6: Lifestyle: Circular gauge dials
struct OnboardingLifestylePage: View {
    @Binding var answers: [String: Any]
    @State private var sleepHours: Double = 7
    @State private var stressLevel: Double = 5
    @State private var exerciseLevel: Double = 3

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: Spacing.xl) {
                VStack(spacing: Spacing.sm) {
                    Text("Tell us about\nyour lifestyle")
                        .font(Font.SS.displaySmall)
                        .foregroundColor(Color.SS.textPrimary)
                        .multilineTextAlignment(.center)

                    Text("This baseline helps identify correlations")
                        .font(Font.SS.bodySmall)
                        .foregroundColor(Color.SS.textTertiary)
                        .tracking(0.5)
                }
                .padding(.top, Spacing.xl)

                // Three circular gauges side by side
                HStack(spacing: Spacing.md) {
                    CircularGauge(
                        icon: "ss.moon.zzz",
                        label: "Sleep",
                        value: sleepHours,
                        displayText: String(format: "%.0fh", sleepHours),
                        maxValue: 12,
                        color: Color(hex: "818CF8")
                    )
                    CircularGauge(
                        icon: "ss.head.brain",
                        label: "Stress",
                        value: stressLevel,
                        displayText: "\(Int(stressLevel))",
                        maxValue: 10,
                        color: Color(hex: "F472B6")
                    )
                    CircularGauge(
                        icon: "ss.figure.run",
                        label: "Exercise",
                        value: exerciseLevel,
                        displayText: "\(Int(exerciseLevel))d",
                        maxValue: 7,
                        color: Color(hex: "34D399")
                    )
                }
                .padding(.horizontal, Spacing.lg)

                // Slider controls below
                VStack(spacing: Spacing.lg) {
                    GaugeSlider(
                        label: "Average sleep",
                        value: $sleepHours,
                        range: 3...12,
                        step: 0.5,
                        unit: "hrs",
                        color: Color(hex: "818CF8")
                    )
                    GaugeSlider(
                        label: "Stress level",
                        value: $stressLevel,
                        range: 1...10,
                        step: 1,
                        unit: "/10",
                        color: Color(hex: "F472B6")
                    )
                    GaugeSlider(
                        label: "Exercise days",
                        value: $exerciseLevel,
                        range: 0...7,
                        step: 1,
                        unit: "per week",
                        color: Color(hex: "34D399")
                    )
                }
                .padding(.horizontal, Spacing.xl)

                Spacer(minLength: 120)
            }
            .onChange(of: sleepHours) { answers["sleep"] = sleepHours }
            .onChange(of: stressLevel) { answers["stress"] = stressLevel }
            .onChange(of: exerciseLevel) { answers["exercise"] = exerciseLevel }
        }
    }
}

struct CircularGauge: View {
    let icon: String
    let label: String
    let value: Double
    let displayText: String
    let maxValue: Double
    let color: Color

    var body: some View {
        VStack(spacing: Spacing.sm) {
            ZStack {
                Circle()
                    .stroke(Color.SS.surfaceTertiary, lineWidth: 3)
                    .frame(width: 90, height: 90)

                Circle()
                    .trim(from: 0, to: value / maxValue)
                    .stroke(
                        color,
                        style: StrokeStyle(lineWidth: 3, lineCap: .round)
                    )
                    .frame(width: 90, height: 90)
                    .rotationEffect(.degrees(-90))
                    .animation(.easeOut(duration: 0.4), value: value)

                VStack(spacing: 2) {
                    SSIconImage(name: icon, size: 14)
                        .foregroundColor(color)
                    Text(displayText)
                        .font(Font.SS.dataMedium)
                        .foregroundColor(Color.SS.textPrimary)
                        .contentTransition(.numericText())
                }
            }

            Text(label)
                .font(Font.SS.caption)
                .foregroundColor(Color.SS.textTertiary)
        }
        .frame(maxWidth: .infinity)
    }
}

struct GaugeSlider: View {
    let label: String
    @Binding var value: Double
    let range: ClosedRange<Double>
    let step: Double
    let unit: String
    let color: Color

    var body: some View {
        VStack(spacing: 6) {
            HStack {
                Text(label)
                    .font(Font.SS.labelSmall)
                    .foregroundColor(Color.SS.textSecondary)
                Spacer()
                Text(step == 1 ? "\(Int(value)) \(unit)" : String(format: "%.1f \(unit)", value))
                    .font(Font.SS.labelSmall)
                    .foregroundColor(color)
                    .monospacedDigit()
            }
            Slider(value: $value, in: range, step: step)
                .tint(color)
                .onChange(of: value) { SSHaptics.selection() }
        }
    }
}

// MARK: - Page 7: Age & Sex: Big number stepper + horizontal pills
struct OnboardingAgeSexPage: View {
    @Binding var answers: [String: Any]
    @State private var age: Double = 30
    @State private var selectedSex: String = ""

    private let sexOptions = ["Male", "Female", "Non-binary", "Skip"]

    var body: some View {
        VStack(spacing: Spacing.xxl) {
            VStack(spacing: Spacing.sm) {
                Text("A bit about you")
                    .font(Font.SS.displaySmall)
                    .foregroundColor(Color.SS.textPrimary)

                Text("Helps personalize your health insights")
                    .font(Font.SS.bodySmall)
                    .foregroundColor(Color.SS.textTertiary)
                    .tracking(0.5)
            }
            .padding(.top, Spacing.xxl)

            // Large age display with +/- steppers
            VStack(spacing: Spacing.md) {
                Text("AGE")
                    .font(Font.SS.caption)
                    .foregroundColor(Color.SS.textDisabled)
                    .tracking(2)

                HStack(spacing: Spacing.xxl) {
                    Button(action: {
                        if age > 13 { age -= 1; SSHaptics.selection() }
                        answers["age"] = age
                    }) {
                        Circle()
                            .fill(Color.SS.surfaceSecondary)
                            .frame(width: 52, height: 52)
                            .overlay(
                                Text("−")
                                    .font(.system(size: 24, weight: .light))
                                    .foregroundColor(Color.SS.textSecondary)
                            )
                            .overlay(
                                Circle().strokeBorder(Color.SS.separator, lineWidth: 0.5)
                            )
                    }

                    Text("\(Int(age))")
                        .font(.system(size: 72, weight: .ultraLight, design: .monospaced))
                        .foregroundColor(Color.SS.textPrimary)
                        .contentTransition(.numericText())
                        .frame(width: 120)

                    Button(action: {
                        if age < 90 { age += 1; SSHaptics.selection() }
                        answers["age"] = age
                    }) {
                        Circle()
                            .fill(Color.SS.surfaceSecondary)
                            .frame(width: 52, height: 52)
                            .overlay(
                                Text("+")
                                    .font(.system(size: 24, weight: .light))
                                    .foregroundColor(Color.SS.textSecondary)
                            )
                            .overlay(
                                Circle().strokeBorder(Color.SS.separator, lineWidth: 0.5)
                            )
                    }
                }

                // Fine-tune slider
                Slider(value: $age, in: 13...90, step: 1)
                    .tint(Color.SS.accent)
                    .padding(.horizontal, Spacing.xxl)
                    .onChange(of: age) { answers["age"] = age }
            }

            // Sex selection: horizontal pill buttons
            VStack(spacing: Spacing.md) {
                Text("BIOLOGICAL SEX")
                    .font(Font.SS.caption)
                    .foregroundColor(Color.SS.textDisabled)
                    .tracking(2)

                HStack(spacing: Spacing.xs) {
                    ForEach(sexOptions, id: \.self) { option in
                        let isOn = selectedSex == option
                        Button(action: {
                            SSHaptics.selection()
                            selectedSex = option
                            answers["sex"] = option
                        }) {
                            Text(option)
                                .font(Font.SS.labelMedium)
                                .foregroundColor(isOn ? Color.SS.background : Color.SS.textSecondary)
                                .padding(.horizontal, Spacing.md)
                                .padding(.vertical, Spacing.sm)
                                .background(
                                    Capsule()
                                        .fill(isOn ? Color.SS.accent : Color.SS.surfaceSecondary)
                                )
                                .overlay(
                                    Capsule()
                                        .strokeBorder(isOn ? Color.clear : Color.SS.separator, lineWidth: 0.5)
                                )
                        }
                        .buttonStyle(PlainButtonStyle())
                        .animation(.easeOut(duration: 0.2), value: isOn)
                    }
                }
            }

            Spacer()
            Spacer(minLength: 120)
        }
    }
}

// MARK: - Page 8: Health Conditions: Flowing tag chips
struct OnboardingConditionsPage: View {
    @Binding var answers: [String: Any]
    @State private var selected: Set<String> = []
    @State private var appeared = false

    private let conditions: [(icon: String, label: String, color: Color)] = [
        ("ss.cat.respiratory", "Asthma", Color(hex: "60A5FA")),
        ("ss.cat.mental", "Anxiety", Color(hex: "A78BFA")),
        ("ss.cat.mental", "Depression", Color(hex: "818CF8")),
        ("ss.cat.digestive", "IBS / Digestive", Color(hex: "FBBF24")),
        ("ss.headache", "Migraines", Color(hex: "F472B6")),
        ("ss.jointpain", "Chronic pain", Color(hex: "EF4444")),
        ("ss.heart", "Heart condition", Color(hex: "EC4899")),
        ("ss.pills", "Autoimmune", Color(hex: "6366F1")),
        ("ss.wind", "Allergies", Color(hex: "34D399")),
        ("ss.bed", "Sleep disorder", Color(hex: "818CF8")),
        ("ss.fatigue", "Chronic fatigue", Color(hex: "F97316")),
        ("ss.cat.skin", "Skin condition", Color(hex: "FB923C")),
        ("ss.ecg", "None of these", Color.SS.textTertiary),
    ]

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: Spacing.xl) {
                VStack(spacing: Spacing.sm) {
                    Text("Any existing\nconditions?")
                        .font(Font.SS.displaySmall)
                        .foregroundColor(Color.SS.textPrimary)
                        .multilineTextAlignment(.center)

                    Text("Select all that apply, stays private")
                        .font(Font.SS.bodySmall)
                        .foregroundColor(Color.SS.textTertiary)
                        .tracking(0.5)
                }
                .padding(.top, Spacing.xl)

                // Flowing chip layout
                FlowLayout(spacing: Spacing.xs) {
                    ForEach(Array(conditions.enumerated()), id: \.element.label) { index, condition in
                        let isOn = selected.contains(condition.label)
                        Button(action: {
                            SSHaptics.selection()
                            if condition.label == "None of these" {
                                selected = ["None of these"]
                            } else {
                                selected.remove("None of these")
                                if isOn { selected.remove(condition.label) }
                                else { selected.insert(condition.label) }
                            }
                            answers["conditions"] = Array(selected)
                        }) {
                            HStack(spacing: 6) {
                                SSIconImage(name: condition.icon, size: 14)
                                    .foregroundColor(isOn ? condition.color : Color.SS.textTertiary)
                                Text(condition.label)
                                    .font(Font.SS.labelMedium)
                                    .foregroundColor(isOn ? Color.SS.textPrimary : Color.SS.textSecondary)
                            }
                            .padding(.horizontal, Spacing.md)
                            .padding(.vertical, Spacing.sm)
                            .background(
                                Capsule()
                                    .fill(isOn ? condition.color.opacity(0.1) : Color.SS.surfaceSecondary)
                            )
                            .overlay(
                                Capsule()
                                    .strokeBorder(
                                        isOn ? condition.color.opacity(0.5) : Color.SS.separator,
                                        lineWidth: isOn ? 1 : 0.5
                                    )
                            )
                        }
                        .buttonStyle(PlainButtonStyle())
                        .scaleEffect(appeared ? 1 : 0.7)
                        .opacity(appeared ? 1 : 0)
                        .animation(
                            .spring(response: 0.4, dampingFraction: 0.7).delay(Double(index) * 0.04),
                            value: appeared
                        )
                    }
                }
                .padding(.horizontal, Spacing.xl)

                Spacer(minLength: 120)
            }
        }
        .onAppear { appeared = true }
    }
}

// MARK: - Page 9: Severity: Thermometer visualization
struct OnboardingSeverityPage: View {
    @Binding var answers: [String: Any]
    @State private var severity: Double = 5
    @State private var bubblesAnimate = false

    var body: some View {
        VStack(spacing: Spacing.xl) {
            VStack(spacing: Spacing.sm) {
                Text("How severe are\nyour symptoms?")
                    .font(Font.SS.displaySmall)
                    .foregroundColor(Color.SS.textPrimary)
                    .multilineTextAlignment(.center)

                Text("On a typical bad day")
                    .font(Font.SS.bodySmall)
                    .foregroundColor(Color.SS.textTertiary)
                    .tracking(0.5)
            }
            .padding(.top, Spacing.xxl)

            // Thermometer + label
            HStack(spacing: Spacing.xxl) {
                // Vertical thermometer
                ZStack(alignment: .bottom) {
                    // Track
                    RoundedRectangle(cornerRadius: 20)
                        .fill(Color.SS.surfaceTertiary)
                        .frame(width: 40, height: 240)

                    // Fill
                    RoundedRectangle(cornerRadius: 20)
                        .fill(
                            LinearGradient(
                                colors: [Color.SS.success, Color.SS.warning, Color.SS.error],
                                startPoint: .bottom,
                                endPoint: .top
                            )
                        )
                        .frame(width: 40, height: max(24, CGFloat(severity / 10.0) * 240))
                        .animation(.spring(response: 0.4), value: severity)
                        .overlay(
                            // Rising bubbles inside the thermometer fill
                            ZStack {
                                if severity > 2 {
                                    ForEach(0..<4, id: \.self) { i in
                                        let diameter: CGFloat = [3.0, 5.0, 4.0, 6.0][i]
                                        let xOffset: CGFloat = [-8.0, 6.0, -3.0, 10.0][i]
                                        let baseOpacity: Double = [0.5, 0.7, 0.4, 0.6][i]
                                        let delay: Double = [0.0, 0.6, 1.2, 1.8][i]

                                        Circle()
                                            .fill(Color.white.opacity(baseOpacity))
                                            .frame(width: diameter, height: diameter)
                                            .offset(
                                                x: xOffset,
                                                y: bubblesAnimate ? -max(24, CGFloat(severity / 10.0) * 240) * 0.4 : 0
                                            )
                                            .opacity(bubblesAnimate ? 0 : 1)
                                            .animation(
                                                .easeOut(duration: 2.0)
                                                .repeatForever(autoreverses: false)
                                                .delay(delay),
                                                value: bubblesAnimate
                                            )
                                    }
                                }
                            }
                            .clipped(),
                            alignment: .bottom
                        )

                    // Bulb at bottom
                    Circle()
                        .fill(severityColor)
                        .frame(width: 48, height: 48)
                        .offset(y: 12)
                        .overlay(
                            SSIconImage(name: "ss.ecg", size: 18)
                                .foregroundColor(.white)
                                .offset(y: 12)
                        )
                }
                .frame(height: 280)
                .onAppear { bubblesAnimate = true }

                // Labels and value
                VStack(alignment: .leading, spacing: Spacing.lg) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("\(Int(severity))")
                            .font(.system(size: 56, weight: .ultraLight, design: .monospaced))
                            .foregroundColor(severityColor)
                            .contentTransition(.numericText())

                        Text(severityLabel)
                            .font(Font.SS.titleMedium)
                            .foregroundColor(severityColor)

                        Text("out of 10")
                            .font(Font.SS.caption)
                            .foregroundColor(Color.SS.textTertiary)
                    }

                    // Descriptive text
                    Text(severityDescription)
                        .font(Font.SS.bodySmall)
                        .foregroundColor(Color.SS.textSecondary)
                        .lineSpacing(4)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding(.horizontal, Spacing.xxl)

            // Slider
            Slider(value: $severity, in: 1...10, step: 1)
                .tint(severityColor)
                .padding(.horizontal, Spacing.xxl)
                .onChange(of: severity) {
                    SSHaptics.selection()
                    answers["severityBaseline"] = severity
                }

            HStack {
                Text("Mild")
                    .font(Font.SS.caption)
                    .foregroundColor(Color.SS.textTertiary)
                Spacer()
                Text("Severe")
                    .font(Font.SS.caption)
                    .foregroundColor(Color.SS.textTertiary)
            }
            .padding(.horizontal, Spacing.xxl)

            Spacer(minLength: 120)
        }
    }

    private var severityColor: Color {
        switch Int(severity) {
        case 1...3: return Color.SS.success
        case 4...6: return Color.SS.warning
        case 7...8: return Color(hex: "F97316")
        default: return Color.SS.error
        }
    }

    private var severityLabel: String {
        switch Int(severity) {
        case 1...2: return "Very mild"
        case 3...4: return "Mild"
        case 5...6: return "Moderate"
        case 7...8: return "Severe"
        default: return "Very severe"
        }
    }

    private var severityDescription: String {
        switch Int(severity) {
        case 1...3: return "Symptoms are present but don't significantly impact daily life."
        case 4...6: return "Noticeable symptoms that sometimes interfere with activities."
        case 7...8: return "Symptoms frequently disrupt work, sleep, or daily routines."
        default: return "Debilitating symptoms that severely limit your functioning."
        }
    }
}

// MARK: - Page 10: Duration: Horizontal timeline with dots
struct OnboardingDurationPage: View {
    @Binding var answers: [String: Any]
    @State private var selected: String = ""
    @State private var appeared = false

    private let durations: [(label: String, short: String, months: Int)] = [
        ("Less than a month", "<1mo", 1),
        ("1-3 months", "1-3mo", 2),
        ("3-6 months", "3-6mo", 5),
        ("6-12 months", "6-12mo", 9),
        ("1-3 years", "1-3yr", 24),
        ("3+ years", "3yr+", 48),
    ]

    var body: some View {
        VStack(spacing: Spacing.xl) {
            VStack(spacing: Spacing.sm) {
                Text("How long have you\nhad symptoms?")
                    .font(Font.SS.displaySmall)
                    .foregroundColor(Color.SS.textPrimary)
                    .multilineTextAlignment(.center)

                Text("Your best estimate is fine")
                    .font(Font.SS.bodySmall)
                    .foregroundColor(Color.SS.textTertiary)
                    .tracking(0.5)
            }
            .padding(.top, Spacing.xxl)

            // Horizontal timeline: fits screen width
            HStack(spacing: 0) {
                ForEach(Array(durations.enumerated()), id: \.element.label) { index, duration in
                    let isOn = selected == duration.label
                    let isPast = {
                        guard let selectedIdx = durations.firstIndex(where: { $0.label == selected }) else { return false }
                        return index <= selectedIdx
                    }()

                    VStack(spacing: Spacing.sm) {
                        // Timeline dot and connector
                        HStack(spacing: 0) {
                            if index > 0 {
                                Rectangle()
                                    .fill(isPast ? Color.SS.accent : Color.SS.surfaceTertiary)
                                    .frame(height: 2)
                                    .animation(.easeOut(duration: 0.3), value: selected)
                            }

                            Circle()
                                .fill(isOn ? Color.SS.accent : isPast ? Color.SS.accent.opacity(0.5) : Color.SS.surfaceTertiary)
                                .frame(width: isOn ? 16 : 10, height: isOn ? 16 : 10)
                                .overlay(
                                    Circle()
                                        .fill(Color.SS.background)
                                        .frame(width: 5, height: 5)
                                        .opacity(isOn ? 1 : 0)
                                )
                                .animation(.spring(response: 0.3), value: isOn)

                            if index < durations.count - 1 {
                                Rectangle()
                                    .fill(isPast && !isOn ? Color.SS.accent : Color.SS.surfaceTertiary)
                                    .frame(height: 2)
                                    .animation(.easeOut(duration: 0.3), value: selected)
                            }
                        }

                        // Label
                        Text(duration.short)
                            .font(isOn ? Font.SS.accentSmall : Font.SS.caption)
                            .foregroundColor(isOn ? Color.SS.accent : Color.SS.textTertiary)
                            .animation(.easeOut(duration: 0.2), value: isOn)
                    }
                    .frame(maxWidth: .infinity)
                    .onTapGesture {
                        SSHaptics.selection()
                        selected = duration.label
                        answers["duration"] = duration.label
                    }
                    .accessibilityLabel("Select duration \(duration.label)")
                }
            }
            .padding(.horizontal, Spacing.lg)

            // Selected duration card
            if !selected.isEmpty {
                SSCard(padding: Spacing.lg) {
                    HStack(spacing: Spacing.md) {
                        Circle()
                            .fill(Color.SS.accentSubtle)
                            .frame(width: 44, height: 44)
                            .overlay(
                                SSIconImage(name: "ss.clock", size: 18)
                                    .foregroundColor(Color.SS.accent)
                            )

                        VStack(alignment: .leading, spacing: 4) {
                            Text(selected)
                                .font(Font.SS.titleMedium)
                                .foregroundColor(Color.SS.textPrimary)
                            Text(durationContext)
                                .font(Font.SS.bodySmall)
                                .foregroundColor(Color.SS.textTertiary)
                        }

                        Spacer()
                    }
                }
                .padding(.horizontal, Spacing.xl)
                .transition(.scale(scale: 0.95).combined(with: .opacity))
            }

            Spacer()
            Spacer(minLength: 120)
        }
    }

    private var durationContext: String {
        switch selected {
        case "Less than a month": return "Early tracking gives the best insights"
        case "1-3 months": return "Enough history to spot initial patterns"
        case "3-6 months": return "Seasonal patterns may be emerging"
        case "6-12 months": return "A rich dataset for deeper analysis"
        case "1-3 years": return "Long-term tracking reveals trends"
        case "3+ years": return "Comprehensive history for advanced insights"
        default: return ""
        }
    }
}

// MARK: - Page 11: Health Rating: Emoji face scale
struct OnboardingHealthRatingPage: View {
    @Binding var answers: [String: Any]
    @State private var rating: Int = 3
    @State private var appeared = false

    private let faces: [(icon: String, label: String, color: Color)] = [
        ("ss.mood.1", "Poor", Color.SS.error),
        ("ss.mood.2", "Fair", Color(hex: "F97316")),
        ("ss.mood.3", "Okay", Color.SS.warning),
        ("ss.mood.4", "Good", Color.SS.accent),
        ("ss.mood.5", "Great", Color.SS.success),
    ]

    var body: some View {
        VStack(spacing: Spacing.xxl) {
            VStack(spacing: Spacing.sm) {
                Text("Rate your overall\nhealth right now")
                    .font(Font.SS.displaySmall)
                    .foregroundColor(Color.SS.textPrimary)
                    .multilineTextAlignment(.center)

                Text("Be honest, no wrong answers")
                    .font(Font.SS.bodySmall)
                    .foregroundColor(Color.SS.textTertiary)
                    .tracking(0.5)
            }
            .padding(.top, Spacing.xxl)

            // Large selected face
            ZStack {
                Circle()
                    .fill(faces[rating - 1].color.opacity(0.08))
                    .frame(width: 160, height: 160)

                Circle()
                    .strokeBorder(faces[rating - 1].color.opacity(0.2), lineWidth: 1)
                    .frame(width: 160, height: 160)

                VStack(spacing: Spacing.sm) {
                    SSIconImage(name: faces[rating - 1].icon, size: 56)
                        .foregroundColor(faces[rating - 1].color)

                    Text(faces[rating - 1].label)
                        .font(Font.SS.titleMedium)
                        .foregroundColor(faces[rating - 1].color)
                }
            }
            .animation(.spring(response: 0.4), value: rating)

            // 5 face selector row
            HStack(spacing: Spacing.md) {
                ForEach(Array(faces.enumerated()), id: \.element.label) { index, face in
                    let isOn = rating == index + 1
                    Button(action: {
                        SSHaptics.medium()
                        rating = index + 1
                        // Map 1-5 faces to 1-10 scale for model
                        answers["healthRating"] = Double(rating * 2)
                    }) {
                        VStack(spacing: 6) {
                            SSIconImage(name: face.icon, size: isOn ? 36 : 28)
                                .foregroundColor(isOn ? face.color : Color.SS.textDisabled)

                            Text("\(index + 1)")
                                .font(Font.SS.caption)
                                .foregroundColor(isOn ? face.color : Color.SS.textDisabled)
                        }
                        .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(PlainButtonStyle())
                    .scaleEffect(isOn ? 1.15 : 1.0)
                    .animation(.spring(response: 0.3, dampingFraction: 0.6), value: isOn)
                }
            }
            .padding(.horizontal, Spacing.xl)

            // Context text
            Text(ratingDescription)
                .font(Font.SS.bodySmall)
                .foregroundColor(Color.SS.textSecondary)
                .multilineTextAlignment(.center)
                .lineSpacing(4)
                .padding(.horizontal, Spacing.xxl)
                .animation(.easeOut(duration: 0.2), value: rating)

            Spacer()
            Spacer(minLength: 120)
        }
    }

    private var ratingDescription: String {
        switch rating {
        case 1: return "Significant health challenges affecting daily life. We'll help you track and understand them."
        case 2: return "Below average but managing. Tracking will reveal where to focus."
        case 3: return "Room for improvement. Let's find what areas need attention."
        case 4: return "Mostly good with occasional issues. Fine-tuning will help."
        case 5: return "Feeling great! Let's maintain and optimize your health."
        default: return ""
        }
    }
}

// MARK: - Page 12: Personalize: Toggle cards (kept unique)
struct OnboardingPersonalizePage: View {
    @Binding var answers: [String: Any]
    @State private var reminderTime = Date()
    @State private var enableNotifications = true
    @State private var enableHealthKit = true
    @State private var showNotification = false
    @State private var glowNotification = false

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: Spacing.xl) {
                VStack(spacing: Spacing.sm) {
                    Text("Personalize your\nexperience")
                        .font(Font.SS.displaySmall)
                        .foregroundColor(Color.SS.textPrimary)
                        .multilineTextAlignment(.center)

                    Text("You can change these anytime in settings")
                        .font(Font.SS.bodySmall)
                        .foregroundColor(Color.SS.textTertiary)
                        .tracking(0.5)
                }
                .padding(.top, Spacing.xl)

                // Animated mock notification preview
                HStack(spacing: Spacing.sm) {
                    // App icon
                    RoundedRectangle(cornerRadius: Radius.sm)
                        .fill(Color.SS.accent)
                        .frame(width: 36, height: 36)
                        .overlay(
                            SSIconImage(name: "ss.ecg", size: 18)
                                .foregroundColor(.white)
                        )

                    VStack(alignment: .leading, spacing: 2) {
                        HStack {
                            Text("Symptly")
                                .font(Font.SS.labelMedium)
                                .foregroundColor(Color.SS.textPrimary)

                            Spacer()

                            Text("now")
                                .font(Font.SS.labelSmall)
                                .foregroundColor(Color.SS.textTertiary)
                        }

                        Text("Time for your daily check-in")
                            .font(Font.SS.bodySmall)
                            .foregroundColor(Color.SS.textSecondary)
                            .lineLimit(1)
                    }
                }
                .padding(Spacing.md)
                .background(
                    RoundedRectangle(cornerRadius: Radius.lg)
                        .fill(Color.SS.surfacePrimary)
                        .overlay(
                            RoundedRectangle(cornerRadius: Radius.lg)
                                .stroke(Color.SS.separator, lineWidth: 0.5)
                        )
                        .shadow(
                            color: glowNotification
                                ? Color.SS.accent.opacity(0.25)
                                : Color.black.opacity(0.08),
                            radius: glowNotification ? 12 : 8,
                            x: 0,
                            y: glowNotification ? 0 : 4
                        )
                )
                .padding(.horizontal, Spacing.xl)
                .offset(x: showNotification ? 0 : UIScreen.main.bounds.width)
                .opacity(showNotification ? 1 : 0)
                .animation(
                    .spring(response: 0.6, dampingFraction: 0.7, blendDuration: 0),
                    value: showNotification
                )
                .animation(
                    .easeInOut(duration: 0.8),
                    value: glowNotification
                )
                .onAppear {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
                        showNotification = true

                        // Trigger a single pulse glow after the slide-in completes
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.7) {
                            glowNotification = true
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
                                glowNotification = false
                            }
                        }
                    }
                }

                VStack(spacing: Spacing.sm) {
                    SSCard {
                        HStack {
                            SSIconImage(name: "ss.bell.badge", size: 18)
                                .foregroundColor(Color.SS.accent)
                                .frame(width: 28)

                            VStack(alignment: .leading, spacing: 2) {
                                Text("Daily reminders")
                                    .font(Font.SS.bodyMedium)
                                    .foregroundColor(Color.SS.textPrimary)
                                Text("Never forget to log symptoms")
                                    .font(Font.SS.labelSmall)
                                    .foregroundColor(Color.SS.textTertiary)
                            }

                            Spacer()

                            Toggle("", isOn: $enableNotifications)
                                .tint(Color.SS.accent)
                                .labelsHidden()
                        }
                    }

                    if enableNotifications {
                        SSCard {
                            HStack {
                                SSIconImage(name: "ss.clock", size: 18)
                                    .foregroundColor(Color.SS.violet)
                                    .frame(width: 28)

                                Text("Reminder time")
                                    .font(Font.SS.bodyMedium)
                                    .foregroundColor(Color.SS.textPrimary)

                                Spacer()

                                DatePicker("", selection: $reminderTime, displayedComponents: .hourAndMinute)
                                    .labelsHidden()
                                    .tint(Color.SS.accent)
                            }
                        }
                        .transition(.opacity.combined(with: .move(edge: .top)))
                    }

                    SSCard {
                        HStack {
                            SSIconImage(name: "ss.heart", size: 18)
                                .foregroundColor(Color(hex: "EF4444"))
                                .frame(width: 28)

                            VStack(alignment: .leading, spacing: 2) {
                                Text("Apple Health sync")
                                    .font(Font.SS.bodyMedium)
                                    .foregroundColor(Color.SS.textPrimary)
                                Text("Import sleep, activity & heart data")
                                    .font(Font.SS.labelSmall)
                                    .foregroundColor(Color.SS.textTertiary)
                            }

                            Spacer()

                            Toggle("", isOn: $enableHealthKit)
                                .tint(Color.SS.accent)
                                .labelsHidden()
                        }
                    }
                }
                .padding(.horizontal, Spacing.xl)
                .animation(.easeOut(duration: 0.3), value: enableNotifications)

                Spacer(minLength: 120)
            }
        }
    }
}

// MARK: - Helix Shape (double-helix sine curves)
struct HelixShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let center = CGPoint(x: rect.midX, y: rect.midY)
        let radius: CGFloat = min(rect.width, rect.height) / 2.0
        let steps = 360
        let helixLobes = 6.0

        // First strand
        for i in 0...steps {
            let angle = Double(i) / Double(steps) * 2.0 * .pi
            let helixOffset = sin(angle * helixLobes) * radius * 0.15
            let r = radius * 0.75 + helixOffset
            let x = center.x + CGFloat(cos(angle)) * r
            let y = center.y + CGFloat(sin(angle)) * r
            if i == 0 {
                path.move(to: CGPoint(x: x, y: y))
            } else {
                path.addLine(to: CGPoint(x: x, y: y))
            }
        }

        // Second strand (phase-shifted by pi for interweaving effect)
        for i in 0...steps {
            let angle = Double(i) / Double(steps) * 2.0 * .pi
            let helixOffset = sin(angle * helixLobes + .pi) * radius * 0.15
            let r = radius * 0.75 + helixOffset
            let x = center.x + CGFloat(cos(angle)) * r
            let y = center.y + CGFloat(sin(angle)) * r
            if i == 0 {
                path.move(to: CGPoint(x: x, y: y))
            } else {
                path.addLine(to: CGPoint(x: x, y: y))
            }
        }

        return path
    }
}

// MARK: - Page 13: Score Teaser: Locked score with pulsing rings
struct OnboardingScoreTeaser: View {
    @State private var animate = false
    @State private var pulseRing = false
    @State private var shimmer = false
    @State private var helixRotation: Double = 0

    var body: some View {
        VStack(spacing: Spacing.xxl) {
            Spacer()

            ZStack {
                // Rotating double-helix behind everything
                HelixShape()
                    .stroke(Color.SS.accent.opacity(0.08), lineWidth: 0.5)
                    .frame(width: 200, height: 200)
                    .rotationEffect(.degrees(helixRotation))
                    .onAppear {
                        withAnimation(.linear(duration: 20.0).repeatForever(autoreverses: false)) {
                            helixRotation = 360
                        }
                    }

                HelixShape()
                    .stroke(Color(hex: "8B5CF6").opacity(0.06), lineWidth: 0.5)
                    .frame(width: 200, height: 200)
                    .rotationEffect(.degrees(-helixRotation))

                // Pulsing outer rings
                ForEach(0..<4) { i in
                    Circle()
                        .stroke(
                            Color.SS.accent.opacity(Double(4 - i) * 0.06),
                            lineWidth: 0.5
                        )
                        .frame(
                            width: CGFloat(80 + i * 50),
                            height: CGFloat(80 + i * 50)
                        )
                        .scaleEffect(pulseRing ? 1.05 : 0.95)
                        .animation(
                            .easeInOut(duration: 2.0)
                            .repeatForever(autoreverses: true)
                            .delay(Double(i) * 0.25),
                            value: pulseRing
                        )
                }

                // Inner glow circle
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [Color.SS.accent.opacity(0.15), Color.clear],
                            center: .center,
                            startRadius: 20,
                            endRadius: 70
                        )
                    )
                    .frame(width: 140, height: 140)

                // Locked score
                VStack(spacing: 4) {
                    SSIconImage(name: "ss.lock", size: 28)
                        .foregroundStyle(Color.SS.gradientPrimary)
                        .scaleEffect(animate ? 1.0 : 0.8)
                        .opacity(animate ? 1 : 0)
                        .animation(.spring(response: 0.8, dampingFraction: 0.6).delay(0.3), value: animate)

                    Text("??")
                        .font(.system(size: 36, weight: .ultraLight, design: .monospaced))
                        .foregroundColor(Color.SS.accent)
                        .opacity(animate ? 1 : 0)
                        .animation(.easeOut(duration: 0.6).delay(0.5), value: animate)
                }
            }
            .frame(height: 260)

            VStack(spacing: Spacing.md) {
                Text("Your Wellness Score\nis ready")
                    .font(Font.SS.displayMedium)
                    .foregroundColor(Color.SS.textPrimary)
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)

                Text("Sign in to reveal your personalized\nbaseline health score")
                    .font(Font.SS.bodyMedium)
                    .foregroundColor(Color.SS.textSecondary)
                    .multilineTextAlignment(.center)
                    .lineSpacing(6)
            }

            VStack(spacing: Spacing.sm) {
                ScoreFeatureRow(icon: "ss.ecg", text: "Personalized wellness baseline")
                ScoreFeatureRow(icon: "ss.tab.insights", text: "AI-driven health insights")
                ScoreFeatureRow(icon: "ss.tab.history", text: "Track progress over time")
            }
            .padding(.horizontal, Spacing.xxl)

            Spacer()
            Spacer()
        }
        .padding(.horizontal, Spacing.xl)
        .onAppear {
            animate = true
            pulseRing = true
        }
    }
}

struct ScoreFeatureRow: View {
    let icon: String
    let text: String

    var body: some View {
        HStack(spacing: Spacing.sm) {
            SSIconImage(name: icon, size: 14)
                .foregroundColor(Color.SS.accent)
                .frame(width: 28)
            Text(text)
                .font(Font.SS.bodySmall)
                .foregroundColor(Color.SS.textSecondary)
                .tracking(0.3)
            Spacer()
            SSIconImage(name: "ss.checkmark", size: 10)
                .foregroundColor(Color.SS.accent.opacity(0.5))
        }
    }
}

// MARK: - Reusable Slider (kept for any future use)
struct OnboardingSlider: View {
    let icon: String
    let label: String
    @Binding var value: Double
    let range: ClosedRange<Double>
    let step: Double
    let unit: String
    let color: Color

    var body: some View {
        VStack(spacing: Spacing.md) {
            HStack {
                SSIconImage(name: icon, size: 16)
                    .foregroundColor(color)
                Text(label)
                    .font(Font.SS.bodyMedium)
                    .foregroundColor(Color.SS.textSecondary)
                Spacer()
                HStack(spacing: 2) {
                    Text(step == 1 ? "\(Int(value))" : String(format: "%.1f", value))
                        .font(Font.SS.dataMedium)
                        .foregroundColor(Color.SS.textPrimary)
                        .contentTransition(.numericText())
                    Text(unit)
                        .font(Font.SS.labelSmall)
                        .foregroundColor(Color.SS.textTertiary)
                }
            }
            Slider(value: $value, in: range, step: step)
                .tint(color)
                .onChange(of: value) { SSHaptics.selection() }
        }
        .padding(Spacing.md)
        .background(
            RoundedRectangle(cornerRadius: Radius.lg)
                .fill(Color.SS.surfaceSecondary)
                .overlay(
                    RoundedRectangle(cornerRadius: Radius.lg)
                        .strokeBorder(Color.SS.separator, lineWidth: 0.5)
                )
        )
    }
}
