import SwiftUI

struct SplashView: View {
    @State private var logoOpacity: Double = 0
    @State private var logoScale: Double = 0.85
    @State private var ringProgress: Double = 0
    @State private var taglineOpacity: Double = 0
    @State private var glowPulse: Bool = false

    var body: some View {
        ZStack {
            Color.SS.background.ignoresSafeArea()

            // Background glow — matches paywall
            ZStack {
                Ellipse()
                    .fill(Color.SS.accent.opacity(glowPulse ? 0.08 : 0.04))
                    .frame(width: 400, height: 300)
                    .blur(radius: 80)
                    .offset(y: -100)
                Ellipse()
                    .fill(Color.SS.violet.opacity(glowPulse ? 0.06 : 0.02))
                    .frame(width: 300, height: 200)
                    .blur(radius: 60)
                    .offset(x: 50, y: -60)
            }
            .ignoresSafeArea()

            VStack(spacing: Spacing.xxl) {
                Spacer()

                // Logo
                ZStack {
                    // Animated ring
                    Circle()
                        .stroke(Color.SS.accent.opacity(0.15), lineWidth: 1)
                        .frame(width: 100, height: 100)

                    Circle()
                        .trim(from: 0, to: ringProgress)
                        .stroke(
                            AngularGradient(
                                colors: [Color.SS.accent, Color.SS.violet, Color.SS.accent],
                                center: .center
                            ),
                            style: StrokeStyle(lineWidth: 2, lineCap: .round)
                        )
                        .frame(width: 100, height: 100)
                        .rotationEffect(.degrees(-90))

                    SSIconImage(name: "ss.ecg", size: 36)
                        .foregroundStyle(Color.SS.gradientPrimary)
                }
                .opacity(logoOpacity)
                .scaleEffect(logoScale)

                // App name
                VStack(spacing: Spacing.xs) {
                    Text("Symptly")
                        .font(.system(size: 32, weight: .semibold, design: .rounded))
                        .foregroundColor(Color.SS.textPrimary)

                    Text("HEALTH TRACKING")
                        .font(.system(size: 11, weight: .medium))
                        .tracking(4)
                        .foregroundColor(Color.SS.accent)
                }
                .opacity(logoOpacity)

                // Tagline
                Text("Understand your body")
                    .font(Font.SS.bodySmall)
                    .foregroundColor(Color.SS.textTertiary)
                    .tracking(1)
                    .opacity(taglineOpacity)

                Spacer()
                Spacer()
            }
        }
        .onAppear {
            withAnimation(.easeOut(duration: 1.0)) {
                logoOpacity = 1
                logoScale = 1
                glowPulse = true
            }
            withAnimation(.easeOut(duration: 1.4).delay(0.2)) {
                ringProgress = 1
            }
            withAnimation(.easeOut(duration: 0.8).delay(0.6)) {
                taglineOpacity = 1
            }
        }
    }
}
