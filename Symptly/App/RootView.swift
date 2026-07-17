import SwiftUI

struct RootView: View {
    @EnvironmentObject var appState: AppState
    @State private var showSplash = true

    var body: some View {
        ZStack {
            Color.SS.background.ignoresSafeArea()

            if showSplash {
                SplashView()
                    .transition(.opacity)
            } else {
                switch appState.currentFlow {
                case .splash:
                    SplashView()
                        .transition(.asymmetric(
                            insertion: .opacity,
                            removal: .move(edge: .leading).combined(with: .opacity)
                        ))
                case .onboarding:
                    OnboardingContainerView()
                        .transition(.asymmetric(
                            insertion: .move(edge: .trailing),
                            removal: .move(edge: .leading).combined(with: .opacity)
                        ))
                case .scoreReveal:
                    ScoreRevealView()
                        .transition(.asymmetric(
                            insertion: .move(edge: .trailing),
                            removal: .opacity
                        ))
                case .paywall:
                    PaywallView()
                        .transition(.asymmetric(
                            insertion: .move(edge: .bottom),
                            removal: .move(edge: .leading).combined(with: .opacity)
                        ))
                case .main:
                    MainTabView()
                        .transition(.asymmetric(
                            insertion: .scale(scale: 0.95).combined(with: .opacity),
                            removal: .opacity
                        ))
                }
            }
        }
        .animation(.easeInOut(duration: 0.5), value: appState.currentFlow)
        .animation(.easeInOut(duration: 0.8), value: showSplash)
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.2) {
                withAnimation { showSplash = false }
            }
        }
    }
}
