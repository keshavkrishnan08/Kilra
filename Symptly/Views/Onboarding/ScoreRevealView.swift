import SwiftUI

struct ScoreRevealView: View {
    @EnvironmentObject var appState: AppState
    @State private var phase: RevealPhase = .loading
    @State private var animatedScore: Int = 0
    @State private var ringProgress: Double = 0
    @State private var showPaywall = false
    @State private var loadingRotation: Double = 0
    @State private var particleAnimate = false

    private enum RevealPhase {
        case loading
        case counting
        case paywallInterrupt
    }

    private var baselineScore: Int {
        appState.computeBaselineScore()
    }

    var body: some View {
        ZStack {
            Color.SS.background.ignoresSafeArea()

            // Background glow
            ZStack {
                Circle()
                    .fill(Color.SS.accent.opacity(0.06))
                    .frame(width: 400, height: 400)
                    .blur(radius: 100)

                Circle()
                    .fill(Color.SS.violet.opacity(0.04))
                    .frame(width: 300, height: 300)
                    .blur(radius: 80)
                    .offset(x: 60, y: -40)
            }

            // Main content
            VStack(spacing: Spacing.xxl) {
                Spacer()

                switch phase {
                case .loading:
                    loadingView
                case .counting, .paywallInterrupt:
                    scoreView
                }

                Spacer()
                Spacer()
            }

            // Paywall overlay slides up
            if showPaywall {
                PaywallView()
                    .transition(.move(edge: .bottom))
            }
        }
        .onAppear {
            startRevealSequence()
        }
    }

    // MARK: - Loading Phase
    private var loadingView: some View {
        VStack(spacing: Spacing.xl) {
            // Spinning rings
            ZStack {
                // Outer ring
                Circle()
                    .stroke(Color.SS.surfaceTertiary, lineWidth: 2)
                    .frame(width: 120, height: 120)

                Circle()
                    .trim(from: 0, to: 0.3)
                    .stroke(
                        Color.SS.accent,
                        style: StrokeStyle(lineWidth: 2, lineCap: .round)
                    )
                    .frame(width: 120, height: 120)
                    .rotationEffect(.degrees(loadingRotation))

                // Inner ring (opposite direction)
                Circle()
                    .trim(from: 0, to: 0.2)
                    .stroke(
                        Color.SS.violet,
                        style: StrokeStyle(lineWidth: 1.5, lineCap: .round)
                    )
                    .frame(width: 90, height: 90)
                    .rotationEffect(.degrees(-loadingRotation * 0.7))

                SSIconImage(name: "ss.sparkles", size: 28)
                    .foregroundStyle(Color.SS.gradientPrimary)
            }

            VStack(spacing: Spacing.sm) {
                Text("Analyzing your profile")
                    .font(Font.SS.titleMedium)
                    .foregroundColor(Color.SS.textPrimary)

                Text("Calculating your wellness baseline...")
                    .font(Font.SS.bodySmall)
                    .foregroundColor(Color.SS.textTertiary)
            }
        }
        .onAppear {
            withAnimation(.linear(duration: 1.5).repeatForever(autoreverses: false)) {
                loadingRotation = 360
            }
            // Haptic pulses during loading
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { SSHaptics.light() }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) { SSHaptics.light() }
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { SSHaptics.light() }
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.4) { SSHaptics.medium() }
        }
    }

    // MARK: - Score Counting Phase
    private var scoreView: some View {
        VStack(spacing: Spacing.xl) {
            // Score ring
            ZStack {
                // Decorative particles
                ForEach(0..<8, id: \.self) { i in
                    Circle()
                        .fill(Color.SS.accent.opacity(0.3))
                        .frame(width: 4, height: 4)
                        .offset(y: particleAnimate ? -100 : -70)
                        .rotationEffect(.degrees(Double(i) * 45))
                        .opacity(particleAnimate ? 0 : 0.6)
                        .animation(
                            .easeOut(duration: 1.5)
                            .repeatForever(autoreverses: false)
                            .delay(Double(i) * 0.15),
                            value: particleAnimate
                        )
                }

                // Background ring
                Circle()
                    .stroke(Color.SS.surfaceTertiary, lineWidth: 4)
                    .frame(width: 180, height: 180)

                // Progress ring
                Circle()
                    .trim(from: 0, to: ringProgress)
                    .stroke(
                        AngularGradient(
                            colors: [Color.SS.accent, Color.SS.violet, Color.SS.accent],
                            center: .center
                        ),
                        style: StrokeStyle(lineWidth: 4, lineCap: .round)
                    )
                    .frame(width: 180, height: 180)
                    .rotationEffect(.degrees(-90))

                // Score number
                VStack(spacing: 4) {
                    Text("\(animatedScore)")
                        .font(.system(size: 64, weight: .ultraLight, design: .monospaced))
                        .foregroundColor(Color.SS.textPrimary)
                        .contentTransition(.numericText())

                    Text("out of 100")
                        .font(Font.SS.labelSmall)
                        .foregroundColor(Color.SS.textTertiary)
                }
            }

            VStack(spacing: Spacing.sm) {
                Text("Your Wellness Score")
                    .font(Font.SS.displaySmall)
                    .foregroundColor(Color.SS.textPrimary)

                Text("Based on your health profile")
                    .font(Font.SS.bodySmall)
                    .foregroundColor(Color.SS.textTertiary)
            }
        }
    }

    // MARK: - Sequence
    private func startRevealSequence() {
        // Phase 1: Loading (1.8 seconds)
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.8) {
            SSHaptics.success()
            withAnimation(.easeOut(duration: 0.4)) {
                phase = .counting
            }
            particleAnimate = true
            startCounting()
        }
    }

    private func startCounting() {
        let target = baselineScore
        let totalDuration: Double = 1.6
        let steps = min(target, 60)
        let interval = totalDuration / Double(steps)

        // Count up with accelerating then decelerating pace
        for step in 0..<steps {
            let progress = Double(step) / Double(steps)
            // Ease-out timing: start fast, slow near end
            let easedDelay = totalDuration * (1.0 - pow(1.0 - progress, 2.5))

            DispatchQueue.main.asyncAfter(deadline: .now() + easedDelay) {
                let currentValue = Int(Double(target) * Double(step + 1) / Double(steps))
                withAnimation(.easeOut(duration: interval)) {
                    animatedScore = currentValue
                    ringProgress = Double(currentValue) / 100.0
                }

                // Haptic ticks during count
                if step % 8 == 0 {
                    SSHaptics.selection()
                }
            }
        }

        // After ~1.5 seconds of counting, interrupt with paywall
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            SSHaptics.medium()
            appState.completeScoreReveal()
            withAnimation(.spring(response: 0.5, dampingFraction: 0.85)) {
                phase = .paywallInterrupt
                showPaywall = true
            }
        }
    }
}
