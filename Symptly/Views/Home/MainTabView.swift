import SwiftUI

struct MainTabView: View {
    @State private var selectedTab: Tab = .home
    @State private var showLogSymptom = false

    enum Tab: String, CaseIterable {
        case home, journal, add, insights, settings

        var icon: String {
            switch self {
            case .home: return "ss.tab.home"
            case .journal: return "ss.tab.history"
            case .add: return "ss.tab.plus"
            case .insights: return "ss.tab.insights"
            case .settings: return "ss.tab.settings"
            }
        }

        var selectedIcon: String {
            switch self {
            case .home: return "ss.tab.home.fill"
            case .journal: return "ss.tab.history"
            case .add: return "ss.tab.plus"
            case .insights: return "ss.tab.insights"
            case .settings: return "ss.tab.settings.fill"
            }
        }

        var label: String {
            switch self {
            case .home: return "Home"
            case .journal: return "Journal"
            case .add: return "Log"
            case .insights: return "Insights"
            case .settings: return "Settings"
            }
        }
    }

    var body: some View {
        ZStack(alignment: .bottom) {
            // Content
            Group {
                switch selectedTab {
                case .home:
                    HomeView(showLogSymptom: $showLogSymptom, selectedTab: $selectedTab)
                case .journal:
                    JournalView()
                case .add:
                    Color.clear // Handled by sheet
                case .insights:
                    InsightsView()
                case .settings:
                    SettingsView()
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)

            // Custom Tab Bar
            SSTabBar(selectedTab: $selectedTab, showLogSymptom: $showLogSymptom)
        }
        .ignoresSafeArea(.keyboard)
        .sheet(isPresented: $showLogSymptom) {
            LogSymptomView()
                .presentationDetents([.large])
                .presentationDragIndicator(.visible)
                .presentationBackground(Color.SS.surfacePrimary)
        }
    }
}

// MARK: - Custom Tab Bar
struct SSTabBar: View {
    @Binding var selectedTab: MainTabView.Tab
    @Binding var showLogSymptom: Bool

    var body: some View {
        HStack(spacing: 0) {
            ForEach(MainTabView.Tab.allCases, id: \.self) { tab in
                if tab == .add {
                    // Center action button
                    Button(action: {
                        SSHaptics.medium()
                        showLogSymptom = true
                    }) {
                        ZStack {
                            Circle()
                                .fill(Color.SS.accent)
                                .frame(width: 52, height: 52)
                                .ssShadow(.glow)

                            SSIconImage(name: "ss.tab.plus", size: 20)
                                .foregroundColor(Color.SS.background)
                        }
                        .offset(y: -12)
                    }
                    .accessibilityLabel("Log new symptom")
                    .frame(maxWidth: .infinity)
                } else {
                    Button(action: {
                        SSHaptics.selection()
                        withAnimation(.easeOut(duration: 0.15)) {
                            selectedTab = tab
                        }
                    }) {
                        VStack(spacing: 4) {
                            SSIconImage(name: selectedTab == tab ? tab.selectedIcon : tab.icon, size: 18)
                                .foregroundColor(
                                    selectedTab == tab ? Color.SS.accent : Color.SS.textTertiary
                                )

                            Text(tab.label)
                                .font(Font.SS.caption)
                                .foregroundColor(
                                    selectedTab == tab ? Color.SS.accent : Color.SS.textTertiary
                                )
                        }
                        .frame(maxWidth: .infinity)
                        .frame(height: 52)
                    }
                    .accessibilityLabel("Switch to \(tab.label) tab")
                }
            }
        }
        .padding(.horizontal, Spacing.xs)
        .padding(.top, Spacing.xs)
        .padding(.bottom, Spacing.xxl)
        .background(
            Rectangle()
                .fill(Color.SS.surfacePrimary)
                .overlay(
                    Rectangle()
                        .fill(Color.SS.separator)
                        .frame(height: 0.5),
                    alignment: .top
                )
                .ignoresSafeArea()
        )
    }
}
