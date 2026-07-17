import SwiftUI
import StoreKit

struct PaywallView: View {
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var subscriptionManager: SubscriptionManager
    @Environment(\.requestReview) private var requestReview
    @State private var selectedPlan: Int = 0 // Default to yearly (best value)
    @State private var isLoading = false
    @State private var showFeatures = false
    @State private var animateGlow = false
    @State private var showTerms = false
    @State private var showPrivacy = false
    @State private var appeared = false

    private let plans: [SubscriptionPlan] = [
        SubscriptionPlan(
            name: "Yearly",
            price: "$39.99",
            period: "per year",
            savings: "Save 67%",
            features: [
                "Unlimited symptom & journal logging",
                "AI pattern detection & predictions",
                "Doctor-ready PDF health reports",
                "Weather & HealthKit correlations",
                "Priority email support"
            ],
            isPopular: true,
            productId: "com.symptly.yearly",
            pricePerMonth: "$3.33"
        ),
        SubscriptionPlan(
            name: "Monthly",
            price: "$9.99",
            period: "per month",
            savings: nil,
            features: [
                "Unlimited symptom & journal logging",
                "AI pattern detection & predictions",
                "Doctor-ready PDF health reports",
                "Weather & HealthKit correlations"
            ],
            isPopular: false,
            productId: "com.symptly.monthly",
            pricePerMonth: "$9.99"
        ),
    ]

    var body: some View {
        ZStack {
            Color.SS.background.ignoresSafeArea()

            // Background glow
            ZStack {
                Ellipse()
                    .fill(Color.SS.accent.opacity(animateGlow ? 0.08 : 0.04))
                    .frame(width: 400, height: 300)
                    .blur(radius: 80)
                    .offset(y: -100)
                Ellipse()
                    .fill(Color.SS.violet.opacity(animateGlow ? 0.06 : 0.02))
                    .frame(width: 300, height: 200)
                    .blur(radius: 60)
                    .offset(x: 50, y: -60)
            }
            .ignoresSafeArea()

            VStack(spacing: 0) {
                Spacer()

                // Hero — emotionally compelling, connects to score
                VStack(spacing: Spacing.md) {
                    // Animated crown with ring
                    ZStack {
                        Circle()
                            .stroke(Color.SS.accent.opacity(0.2), lineWidth: 1)
                            .frame(width: 70, height: 70)
                        Circle()
                            .trim(from: 0, to: animateGlow ? 0.75 : 0)
                            .stroke(
                                AngularGradient(colors: [Color.SS.accent, Color.SS.violet], center: .center),
                                style: StrokeStyle(lineWidth: 2, lineCap: .round)
                            )
                            .frame(width: 70, height: 70)
                            .rotationEffect(.degrees(-90))
                            .animation(.easeOut(duration: 1.2).delay(0.3), value: animateGlow)

                        SSIconImage(name: "ss.crown", size: 26)
                            .foregroundStyle(Color.SS.gradientPrimary)
                    }
                    .opacity(appeared ? 1 : 0)
                    .offset(y: appeared ? 0 : 20)

                    VStack(spacing: 6) {
                        Text("Your insights are\nready to unlock")
                            .font(Font.SS.displaySmall)
                            .foregroundColor(Color.SS.textPrimary)
                            .multilineTextAlignment(.center)
                            .lineSpacing(2)

                        let score = appState.computeBaselineScore()
                        Text("Score: \(score)/100 — see what's behind it")
                            .font(Font.SS.labelSmall)
                            .foregroundColor(Color.SS.accent)
                            .lineLimit(1)
                            .minimumScaleFactor(0.8)
                    }
                    .opacity(appeared ? 1 : 0)
                    .offset(y: appeared ? 0 : 15)

                    // Outcome-focused bullets
                    VStack(alignment: .leading, spacing: 10) {
                        PaywallBullet("Discover what triggers your worst days")
                        PaywallBullet("Walk into doctor visits fully prepared")
                        PaywallBullet("See how sleep & weather affect you")
                        PaywallBullet("Track everything — spots patterns faster")
                    }
                    .padding(.top, Spacing.xs)
                    .opacity(appeared ? 1 : 0)
                    .offset(y: appeared ? 0 : 10)
                }

                Spacer()

                // Plan selector — clear savings comparison
                VStack(spacing: Spacing.sm) {
                    HStack(spacing: Spacing.sm) {
                        ForEach(Array(plans.enumerated()), id: \.offset) { index, plan in
                            Button(action: {
                                SSHaptics.selection()
                                withAnimation(.easeOut(duration: 0.2)) { selectedPlan = index }
                            }) {
                                VStack(spacing: 6) {
                                    // Badge
                                    if plan.isPopular {
                                        Text("MOST POPULAR")
                                            .font(.system(size: 9, weight: .bold))
                                            .tracking(1)
                                            .foregroundColor(selectedPlan == index ? .white : Color.SS.accent)
                                    } else {
                                        Text(" ")
                                            .font(.system(size: 9, weight: .bold))
                                    }

                                    Text(plan.name)
                                        .font(Font.SS.accentSmall)
                                        .foregroundColor(selectedPlan == index ? .white : Color.SS.textPrimary)

                                    // Price prominent
                                    Text(plan.pricePerMonth)
                                        .font(.system(size: 24, weight: .bold, design: .rounded))
                                        .foregroundColor(selectedPlan == index ? .white : Color.SS.textPrimary)
                                    Text("per month")
                                        .font(Font.SS.caption)
                                        .foregroundColor(selectedPlan == index ? .white.opacity(0.7) : Color.SS.textTertiary)

                                    // Savings or billed info
                                    if let savings = plan.savings {
                                        Text(savings)
                                            .font(.system(size: 11, weight: .bold))
                                            .foregroundColor(selectedPlan == index ? .white : Color.SS.accent)
                                            .padding(.top, 2)
                                    } else {
                                        Text("Billed monthly")
                                            .font(Font.SS.caption)
                                            .foregroundColor(selectedPlan == index ? .white.opacity(0.6) : Color.SS.textDisabled)
                                            .padding(.top, 2)
                                    }
                                }
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, Spacing.md)
                                .background(
                                    RoundedRectangle(cornerRadius: Radius.lg)
                                        .fill(selectedPlan == index
                                              ? AnyShapeStyle(Color.SS.accent)
                                              : AnyShapeStyle(Color.SS.surfacePrimary))
                                )
                                .overlay(
                                    RoundedRectangle(cornerRadius: Radius.lg)
                                        .strokeBorder(
                                            selectedPlan == index ? Color.clear : Color.SS.separator,
                                            lineWidth: 0.5
                                        )
                                )
                                .ssShadow(selectedPlan == index ? .glow : .subtle)
                            }
                            .buttonStyle(PlainButtonStyle())
                            .accessibilityLabel("Select \(plan.name) plan, \(plan.price) \(plan.period)")
                        }
                    }
                    .padding(.horizontal, Spacing.xl)
                    .opacity(appeared ? 1 : 0)
                    .offset(y: appeared ? 0 : 20)
                }

                Spacer().frame(height: Spacing.md)

                // CTA + legal — pinned bottom
                VStack(spacing: Spacing.xs) {
                    SSButton(
                        title: "Continue — \(plans[selectedPlan].price)/\(selectedPlan == 0 ? "yr" : "mo")",
                        style: .primary,
                        isLoading: isLoading || subscriptionManager.isLoading
                    ) {
                        purchase()
                    }
                    .accessibilityLabel("Subscribe for \(plans[selectedPlan].price) \(plans[selectedPlan].period)")
                    .padding(.horizontal, Spacing.xl)
                    .opacity(appeared ? 1 : 0)

                    Text("Cancel anytime · Auto-renews \(plans[selectedPlan].period)")
                        .font(Font.SS.caption)
                        .foregroundColor(Color.SS.textTertiary)
                        .padding(.top, 2)

                    HStack(spacing: Spacing.md) {
                        Button("Restore") { restore() }
                            .accessibilityLabel("Restore previous purchase")
                        Button("Terms") { showTerms = true }
                            .accessibilityLabel("View terms of service")
                        Button("Privacy") { showPrivacy = true }
                            .accessibilityLabel("View privacy policy")
                    }
                    .font(Font.SS.caption)
                    .foregroundColor(Color.SS.textDisabled)
                    .padding(.bottom, Spacing.lg)
                }
            }
        }
        .onAppear {
            animateGlow = true
            withAnimation(.easeOut(duration: 0.6)) { appeared = true }
        }
        .sheet(isPresented: $showTerms) {
            InfoSheetView(title: "Terms of Service", content: """
            Symptly Terms of Service

            Symptly is a health tracking tool, not a medical device. It is not intended to diagnose, treat, cure, or prevent any disease.

            Always consult a qualified healthcare provider for medical advice. Do not rely solely on this app for health decisions.

            By using Symptly, you agree to these terms and acknowledge that the app provides informational insights only.

            Subscriptions auto-renew unless cancelled at least 24 hours before the end of the current period. Manage subscriptions in your Apple ID settings.
            """)
        }
        .sheet(isPresented: $showPrivacy) {
            InfoSheetView(title: "Privacy Policy", content: """
            Symptly Privacy Policy

            Your health data stays on your device. We do not transmit, store, or share any symptom data with third parties.

            Data Storage: All symptom entries, daily check-ins, and personal information are stored locally on your device using encrypted storage.

            HealthKit: If enabled, we read sleep, heart rate, steps, and exercise data from Apple Health. This data is only used locally for insights and is never uploaded.

            Analytics: We collect anonymous usage analytics (screen views, feature usage) to improve the app. No personal or health data is included.

            Contact: keshav-krishnan@outlook.com
            """)
        }
    }

    private func purchase() {
        let plan = plans[selectedPlan]
        SSHaptics.medium()

        // Find the matching StoreKit product
        if let product = subscriptionManager.products.first(where: { $0.id == plan.productId }) {
            Task {
                do {
                    let transaction = try await subscriptionManager.purchase(product)
                    if transaction != nil {
                        SSHaptics.success()
                        appState.activateSubscription()
                        requestReview()
                    }
                } catch {
                    SSHaptics.light()
                }
            }
        } else {
            // Fallback: products may not have loaded yet (e.g. sandbox/testing)
            isLoading = true
            Task {
                await subscriptionManager.loadProducts()
                if let product = subscriptionManager.products.first(where: { $0.id == plan.productId }) {
                    do {
                        let transaction = try await subscriptionManager.purchase(product)
                        isLoading = false
                        if transaction != nil {
                            SSHaptics.success()
                            appState.activateSubscription()
                            requestReview()
                        }
                    } catch {
                        isLoading = false
                        SSHaptics.light()
                    }
                } else {
                    isLoading = false
                }
            }
        }
    }

    private func restore() {
        Task {
            await subscriptionManager.restorePurchases()
            if subscriptionManager.hasActiveSubscription {
                SSHaptics.success()
                appState.activateSubscription()
            }
        }
    }
}

// MARK: - Feature Bullet
struct PaywallBullet: View {
    let text: String
    init(_ text: String) { self.text = text }

    var body: some View {
        HStack(spacing: 10) {
            SSIconImage(name: "ss.checkmark", size: 11)
                .foregroundColor(Color.SS.accent)
            Text(text)
                .font(Font.SS.bodySmall)
                .foregroundColor(Color.SS.textSecondary)
        }
    }
}

// MARK: - Star Shape
struct StarShape: Shape {
    func path(in rect: CGRect) -> Path {
        let center = CGPoint(x: rect.midX, y: rect.midY)
        let outerRadius = min(rect.width, rect.height) / 2
        let innerRadius = outerRadius * 0.4
        let points = 5
        var path = Path()

        for i in 0..<(points * 2) {
            let angle = (Double(i) * .pi / Double(points)) - (.pi / 2)
            let radius = i.isMultiple(of: 2) ? outerRadius : innerRadius
            let point = CGPoint(
                x: center.x + CGFloat(cos(angle)) * radius,
                y: center.y + CGFloat(sin(angle)) * radius
            )
            if i == 0 {
                path.move(to: point)
            } else {
                path.addLine(to: point)
            }
        }
        path.closeSubpath()
        return path
    }
}

