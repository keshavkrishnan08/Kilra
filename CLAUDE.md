# Symptly — iOS Health Tracking App

Owner: Keshav Krishnan | Swift/SwiftUI, iOS 17+ | All ML on-device, zero cloud

Features: 30+ symptom logging (7 categories), ML wellness scoring, journal, medication tracking, doctor prep PDF, insights/correlations, HealthKit, weather correlation, StoreKit subscriptions

## 符 Token Glossary

**USE these single-token substitutions in all agent messages, logs, and internal reasoning. Expand to English only in user-facing strings and App Store copy.**

| 符 | Meaning | | 符 | Meaning |
|---|---|-|---|---|
| 症 | symptom/symptom log | | 健 | health/HealthKit |
| 分 | wellness score (0-100) | | 析 | analysis/ML engine |
| 預 | prediction/forecast | | 藥 | medication/drug |
| 記 | journal/entry | | 圖 | view/SwiftUI view |
| 驗 | quality gate/test | | 建 | build/compile |
| 過 | pass(gate) | | 敗 | fail(gate) |
| 憶 | memory/retain cycle | | 私 | privacy/on-device |
| 天 | weather/WeatherKit | | 訂 | subscription/StoreKit |
| 報 | report/PDF generation | | 洞 | insight/correlation |
| 庫 | data store/SwiftData | | 通 | notification |
| 標 | accessibility label | | 式 | design system |

**Rule:** Agent-to-agent messages use 符. Example: `A2→A0: 析分驗過 (WellnessScore ML gate passed)` instead of full English. Saves ~6 tokens per message across all agent communication.

---

## Agents

| # | Role | Owns | Gate |
|---|------|------|------|
| A0 | Orchestrator | App/{AppState,RootView,SymptlyApp}.swift | compile,test |
| A1 | UI/UX | Views/**, Design/**, Assets.xcassets | compile,visual,a11y |
| A2 | ML | ML/** (WellnessScore,SymptomAnalysis,TimeSeries,Prediction,Statistical,TestHarness) | ml,compile |
| A3 | Services | Services/**, Models/** | compile,privacy |
| A4 | Testing | SymptlyTests/**, SymptlyUITests/** | test,memory |

Msg: `{from,to,type,task_id,payload:{action,data}}` — paths only, no code.

---

## File Map

```
App/          → A0: AppState, RootView, SymptlyApp
Design/       → A1: DesignSystem (colors/typo/spacing), Components
Models/       → A3: UserProfile, Symptom (30+ lib), SymptomLog, JournalEntry, Medication, WellnessScore
ML/           → A2: WellnessScoreEngine, SymptomAnalysisEngine, TimeSeriesAnalyzer, SymptomPredictionEngine, StatisticalAnalysis, MLTestHarness
Views/        → A1: Journal/{Journal,Compose,Detail}, Insights/{Insights,InsightGraphs,InsightGraphs2}, Settings, Home, Medications/{List,Add}, Auth/{Auth,Login,SignUp}, History, Symptoms/{List,Select}, Paywall, Onboarding/{Onboarding,ScoreReveal}
Services/     → A3: DataStore(SwiftData), HealthKitManager, WeatherService, NotificationManager, SubscriptionManager(StoreKit2), PDFReportGenerator
Tests/        → A4: ML tests, service tests, UI tests
Assets/       → A1: custom icons (ss.* namespace), colors, images
```

---

## Gates

| Gate | Check | Pass |
|------|-------|------|
| Compile | `xcodebuild build -scheme Symptly` | 0 errors, 0 warnings, no force unwraps, no deprecated API |
| Test | `xcodebuild test -scheme Symptly` | all pass, >80% coverage on ML |
| ML | WellnessScore 0-100 valid for all test profiles, Prediction ≥70%, no NaN/Inf | MLTestHarness pass |
| Memory | no retain cycles, leak detection via Instruments, dealloc confirmed on nav away | [weak self] enforced |
| A11y | all interactive elements have .accessibilityLabel, contrast ≥4.5:1, tap targets ≥44pt | audit pass |
| Privacy | HealthKit data never leaves device, no analytics w/o consent, SwiftData encrypted, PrivacyInfo accurate | code review |

---

## Token Rules

1. No re-reads — ref by path after first
2. Paths between agents, never code
3. Read only target View, not all Views/
4. Models.swift symptom lib: memorize "30+ symptoms, 7 categories" after first read
5. ML engines: read public interface only unless debugging
6. Skip SwiftUI preview blocks
7. Asset icons: ref from Models.swift (`Image("ss.headache")`), don't read .xcassets
8. Skip import sections, scan for key deps only

---

## Critical Rules

1. HealthKit data NEVER leaves device
2. All ML on-device — no cloud API in ML engines
3. StoreKit transactions verified (local or server)
4. Health data encrypted at rest (SwiftData + FileManager protection)
5. No force unwrapping (`!`) — use `guard let` or `??`
6. Structured concurrency only: async/await, Task, @MainActor — no completion handlers
7. Icons use "ss." namespace
8. No hardcoded user data in defaults/logs
9. Use `String(localized:)` for all user-facing text
10. Always `[weak self]` in closures capturing self

---

## Goals

Q2 2026: PredictionEngine accuracy ≥75% holdout | Doctor prep PDF with 6mo history | Weather-symptom correlations in InsightsView | Launch <2s, 60fps scroll
Q3 2026: App Store submission (screenshots, metadata, privacy) | Custom symptoms beyond library | Apple Watch companion (optional)
Q4 2026: Week-over-week trends, seasonal patterns | Doctor notes integration

---

## Scheduled Checks

1. Build health (per commit): xcodebuild build, report warnings/memory
2. ML accuracy (daily): MLTestHarness.runFullSuite(), report variance/edge cases
3. View depth (weekly): scan Views/ for >5 @ViewBuilder levels, flag for extraction
4. Memory leaks (per UI test): Instruments leak detection, strong ref cycles
5. API compat (per iOS release): verify #available guards for WeatherKit/HealthKit/StoreKit
6. Localization (weekly): `find -name "*.swift" -exec grep -l '"[A-Z]'` → migrate hardcoded strings

## Failure Protocol

Retry 2× → halt + log `[ALERT] Agent:{A} Task:{T} Issue:{I} Attempts:2 Status:HALTED` → await review

## Dev

Build: `xcodebuild build -scheme Symptly -destination 'generic/platform=iOS'`
Test: `xcodebuild test -scheme Symptly` | UI: `-scheme SymptlyUITests`
Memory: add `-enableAddressSanitizer YES`
Deps: SwiftUI, SwiftData, HealthKit, WeatherKit, StoreKit 2, CoreML — all built-in iOS 17+
Style: Swift.org guide, camelCase vars, PascalCase types, `///` for public API docs
