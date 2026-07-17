import SwiftUI
import StoreKit

struct OnboardingContainerView: View {
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var dataStore: DataStore
    @Environment(\.requestReview) private var requestReview
    @State private var currentPage = 0
    @State private var answers: [String: Any] = [:]
    @State private var showContent = false

    private let totalPages = 13

    var body: some View {
        ZStack {
            Color.SS.background.ignoresSafeArea()

            // Subtle animated background
            OnboardingBackgroundView(page: currentPage)

            VStack(spacing: 0) {
                // Top bar with progress
                OnboardingProgressBar(
                    current: currentPage,
                    total: totalPages,
                    onBack: goBack
                )
                .padding(.top, Spacing.xs)

                // Page content
                TabView(selection: $currentPage) {
                    OnboardingWelcomePage()
                        .tag(0)
                    OnboardingGoalPage(answers: $answers)
                        .tag(1)
                    OnboardingSymptomsPage(answers: $answers)
                        .tag(2)
                    OnboardingFrequencyPage(answers: $answers)
                        .tag(3)
                    OnboardingImpactPage(answers: $answers)
                        .tag(4)
                    OnboardingLifestylePage(answers: $answers)
                        .tag(5)
                    OnboardingAgeSexPage(answers: $answers)
                        .tag(6)
                    OnboardingConditionsPage(answers: $answers)
                        .tag(7)
                    OnboardingSeverityPage(answers: $answers)
                        .tag(8)
                    OnboardingDurationPage(answers: $answers)
                        .tag(9)
                    OnboardingHealthRatingPage(answers: $answers)
                        .tag(10)
                    OnboardingPersonalizePage(answers: $answers)
                        .tag(11)
                    OnboardingScoreTeaser()
                        .tag(12)
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                .animation(.easeInOut(duration: 0.4), value: currentPage)

                // Bottom CTA
                VStack(spacing: Spacing.md) {
                    SSButton(
                        title: currentPage == totalPages - 1 ? "See Your Score" : "Continue",
                        icon: currentPage == totalPages - 1 ? "ss.sparkles" : nil,
                        style: .primary
                    ) {
                        advance()
                    }
                    .accessibilityLabel(currentPage == totalPages - 1 ? "See your wellness score" : "Continue to next step")
                }
                .padding(.horizontal, Spacing.xl)
                .padding(.bottom, Spacing.xxl)
            }
        }
        .opacity(showContent ? 1 : 0)
        .onAppear {
            withAnimation(.easeOut(duration: 0.5)) { showContent = true }
        }
    }

    private func advance() {
        SSHaptics.light()
        if currentPage < totalPages - 1 {
            withAnimation { currentPage += 1 }
            // Prompt review after the 3rd slide (user just moved to page 3)
            if currentPage == 3 {
                requestReview()
            }
        } else {
            // Store answers in appState + persist to CloudKit via DataStore
            appState.onboardingAnswers = answers
            dataStore.saveOnboardingProfile(answers)
            appState.completeOnboarding()
        }
    }

    private func goBack() {
        SSHaptics.selection()
        if currentPage > 0 {
            withAnimation { currentPage -= 1 }
        }
    }
}

// MARK: - Animated Background
struct OnboardingBackgroundView: View {
    let page: Int

    var body: some View {
        ZStack {
            // Floating orbs that shift per page
            Circle()
                .fill(Color.SS.accent.opacity(0.04))
                .frame(width: 300, height: 300)
                .blur(radius: 80)
                .offset(
                    x: CGFloat(page % 2 == 0 ? -80 : 80),
                    y: CGFloat(page * -30 + 100)
                )
                .animation(.easeInOut(duration: 1.5), value: page)

            Circle()
                .fill(Color.SS.violet.opacity(0.03))
                .frame(width: 250, height: 250)
                .blur(radius: 60)
                .offset(
                    x: CGFloat(page % 2 == 0 ? 100 : -60),
                    y: CGFloat(page * 20 - 50)
                )
                .animation(.easeInOut(duration: 1.5).delay(0.2), value: page)
        }
    }
}

// MARK: - Progress Bar
struct OnboardingProgressBar: View {
    let current: Int
    let total: Int
    var onBack: () -> Void

    var body: some View {
        HStack(spacing: Spacing.sm) {
            // Back button
            if current > 0 {
                SSIconButton(icon: "ss.chevron.left", size: 36, iconSize: 14, style: .ghost) {
                    onBack()
                }
                .accessibilityLabel("Go back to previous step")
                .transition(.opacity)
            } else {
                Spacer().frame(width: 36)
            }

            // Progress segments
            HStack(spacing: 4) {
                ForEach(0..<total, id: \.self) { index in
                    Capsule()
                        .fill(index <= current ? Color.SS.accent : Color.SS.surfaceTertiary)
                        .frame(height: 2)
                        .animation(.easeOut(duration: 0.3), value: current)
                }
            }

            // Page counter
            Text("\(current + 1)/\(total)")
                .font(Font.SS.labelSmall)
                .foregroundColor(Color.SS.textTertiary)
                .monospacedDigit()
                .frame(width: 36)
        }
        .padding(.horizontal, Spacing.md)
        .frame(height: 44)
    }
}
