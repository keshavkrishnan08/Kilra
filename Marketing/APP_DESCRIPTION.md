# Symptly — Complete App Description

**iOS Health Tracking App** | Swift/SwiftUI | iOS 17+ | All ML on-device, zero cloud

---

## What Is Symptly?

Symptly is a privacy-first health tracking app that helps you understand your body through intelligent symptom logging, on-device machine learning, and actionable insights. Log how you feel, and the app does the hard work — finding patterns, predicting flare-ups, correlating your symptoms with sleep, weather, and activity. Walk into your next doctor's appointment with a complete picture instead of a blank stare.

Your health data never leaves your device. No cloud servers. No third-party analytics on your symptoms. Just you and your phone.

---

## Core Features

### 1. Symptom Logging

A guided 4-step flow for recording how you feel:

1. **Select a symptom** from 30+ built-in options across 7 categories, or add your own custom symptoms
2. **Rate severity** on a 1–10 scale with real-time visual feedback
3. **Add context** — triggers (stress, weather, food, hormones, etc.), duration, and freeform notes
4. **Review and save** — confirmation screen with everything at a glance

**Built-in symptom library (7 categories):**

| Category | Symptoms |
|----------|----------|
| Pain | Headache, Back Pain, Joint Pain, Chest Pain, Muscle Ache, Abdominal Pain |
| Digestive | Nausea, Bloating, Acid Reflux, Constipation, Diarrhea |
| Neurological | Dizziness, Brain Fog, Numbness, Tremors |
| Mental Health | Anxiety, Depression, Insomnia, Mood Swings |
| Respiratory | Shortness of Breath, Cough, Wheezing, Congestion |
| Skin | Rash, Itching, Dry Skin |
| Energy | Fatigue, Low Energy, Weakness |

Users can add unlimited custom symptoms beyond this library.

---

### 2. Daily Check-In

A quick daily snapshot that feeds the ML models:

- **Mood** (1–5 scale)
- **Energy level** (1–5)
- **Sleep hours**
- **Stress level** (1–5)
- **Water intake** (glasses)
- **General notes**

This data, combined with symptom entries, powers the wellness score and pattern detection.

---

### 3. Wellness Score (0–100)

A composite daily health metric computed by an on-device CoreML model with a heuristic fallback. Here's what goes into it:

| Factor | Weight | How It Works |
|--------|--------|--------------|
| Mood contribution | 20% | Higher mood → higher score |
| Severity penalty | 25% | Average + max symptom severity drags the score down |
| Energy contribution | 15% | Higher energy → higher score |
| Volume penalty | 15% | More symptom entries = exponential penalty |
| Streak bonus | 12% | Consistent logging rewards you |
| HealthKit bonuses | 10% | Good sleep, steps, and exercise boost the score |
| Diversity penalty | 8% | More unique symptoms in a day = worse |

The score starts at a baseline of 65 and adjusts from there. During onboarding, your answers create a personalized bias that gradually fades as real data accumulates (~60 logged entries). Scores are clamped between 5–95 for realism — nobody's a perfect 100, and nobody's truly a 0.

Users see a full **breakdown** showing exactly how each factor contributed. No black boxes.

---

### 4. AI Pattern Detection

The SymptomAnalysisEngine runs entirely on-device and discovers:

**Pattern Classification** — Each symptom gets one of 7 labels:
- **Chronic** — present >60% of days, gaps under 2.5 days
- **Episodic** — clear episodes separated by gaps of 5+ days
- **Cyclical** — repeating on a detectable cycle (autocorrelation-based, testing 3–35 day periods)
- **Improving** — negative trend (linear regression slope < -0.03)
- **Worsening** — positive trend (slope > 0.03)
- **New Onset** — less than 14 days of history
- **Unknown** — not enough data yet

**Trigger Risk Scores** — Bayesian inference identifies which triggers actually make things worse. For each trigger, the engine calculates:
- Risk score (0–1): severity difference between entries with and without the trigger
- Bayesian probability: P(high_severity | trigger)
- Average severity with vs. without
- Only surfaces triggers appearing 2+ times with risk > 0.1

**Symptom Clustering** — Co-occurrence analysis using Jaccard similarity finds symptoms that tend to appear together. If headaches and fatigue show up on the same days with ≥25% overlap, you'll know about it.

**Cyclical Pattern Detection** — Autocorrelation tests across 3–35 day windows with tolerance = period/5. When a cycle is found (≥50% confidence), the app predicts your next expected occurrence.

---

### 5. Flare-Up Risk Prediction

A real-time probability (0–1) that a flare-up is coming, displayed as low / moderate / elevated / high:

| Signal | Max Contribution |
|--------|-----------------|
| Recent severity spike (3-day vs 30-day baseline) | +0.25 |
| Increasing entry volume | +0.20 |
| Low mood today | +0.15 |
| Low energy today | +0.10 |
| High-risk triggers currently active | +0.15 |
| Multiple unique symptoms in 2 days | +0.10 |
| Poor sleep (<5.5 hours) | +0.12 |
| Elevated heart rate (>85 bpm) | +0.08 |
| Very low activity (<1,500 steps) | +0.05 |
| Onboarding profile flare bias | up to +0.25 |

When flare-up risk is elevated, a banner appears on the Home dashboard linking directly to Doctor Prep.

---

### 6. Severity Predictions

The SymptomPredictionEngine forecasts future symptom severity using weighted features:

| Feature | Weight |
|---------|--------|
| Historical baseline | 25% |
| Recent 7-day trend | 25% |
| Active triggers | 13% |
| Mood/energy context | 13% |
| Day-of-week affinity | 12% |
| Seasonal/monthly pattern | 12% |
| HealthKit context (sleep, activity) | 10% |

Output: predicted severity (1–10), confidence score, and ranked contributing factors.

**Likelihood prediction** answers "Will I experience symptom X tomorrow?" by combining base frequency (35%), recency (30%), day-of-week affinity (20%), and recent trajectory (15%).

**7-day forecast** computes likelihood and severity for each symptom across the next week, with an overall daily risk score.

---

### 7. Time Series Analysis

The TimeSeriesAnalyzer provides the statistical backbone for charts and anomaly detection:

- **Smoothing**: Exponential Moving Average (EMA), Double EMA, Simple Moving Average (SMA)
- **Decomposition**: Additive decomposition into trend + seasonal + residual components
- **Anomaly detection**: Z-score based spike/dip detection (>2 standard deviations from local 7-day window)
- **Bollinger-style bands**: Rolling mean ± standard deviation for volatility visualization
- **Trend strength**: Linear regression slope, R² goodness-of-fit, direction classification, projected weekly change
- **Forecasting**: Linear extrapolation clamped to 1–10 severity
- **Seasonal averages**: Per-cycle patterns (e.g., day-of-week severity tendencies)

---

### 8. Statistical Analysis

Proper hypothesis testing — not naive averages:

- **Welch's t-test** (unequal variance): Compares two groups with t-statistic, p-value, Cohen's d effect size, and 95% confidence intervals
- **Pearson correlation**: Linear relationship measurement with r, r², p-value, and strength classification
- **Descriptive statistics**: Mean, median, SD, variance, quartiles, IQR, skewness, coefficient of variation, z-scores
- **Outlier detection**: IQR method for flagging unusual readings

---

### 9. Journal

A full health diary with:

- **Title and body** — freeform text with rich formatting
- **Mood rating** (1–5, optional) — tracked over time as a mood streak
- **Tags** — preset (Doctor Visit, Medication Change, Flare-Up, Good Day, Milestone, Question) plus custom tags
- **Favorites** — bookmark important entries with a star
- **Full-text search** — find entries by keyword
- **Filter by tag or favorites** — quick access to categories

Swipe actions for favoriting and deleting. Each entry shows a preview card with title, date, mood badge, and body snippet.

---

### 10. Medication Tracking

- **Add medications** with name, dosage, frequency (daily, twice daily, as needed, weekly, other), and time of day (morning, afternoon, evening, bedtime, with food)
- **Daily checkoff** — mark medications as taken with a tap, logged with timestamps
- **Active vs. past** — toggle medications inactive without deleting history
- **Medication reminders** — scheduled local notifications
- **Adherence tracking** — the ML engines factor medication compliance into insights

---

### 11. Apple Health Integration

Read-only access to HealthKit data (user-authorized):

| Data | How It's Used |
|------|--------------|
| Sleep hours | Wellness score bonus, flare-up risk signal, sleep-severity correlations |
| Average heart rate | Elevated HR (>85 bpm) adds flare-up risk |
| Step count | Activity level correlation, low activity (<1,500 steps) flagged |
| Active exercise minutes | Wellness score bonus, exercise-severity correlation |

HealthKit data feeds into the Home dashboard, ML engines, and insight correlations. It never leaves your device.

---

### 12. Weather Correlation

Using the free Open-Meteo API (no API key required, no health data sent):

- **Temperature** — cold vs. warm severity differences
- **Barometric pressure** — low vs. high pressure impact
- **Humidity** — humid vs. dry conditions
- **Weather code** — mapped to clear/cloudy/rain/snow/storm icons

Correlations require ≥5 days of data and ≥0.5 severity difference to avoid spurious findings. Weather shows on the Home dashboard and in Insight correlations.

---

### 13. Insights Dashboard

The analysis hub. Everything the ML engines produce lands here:

**Wellness Score Card** — your current metric with weekly trend chart

**AI Insights** — automatically generated actionable discoveries:
- Top symptom identification with severity classification
- Symptom co-occurrence patterns
- Streak milestones (3-day, 7-day celebrations)
- Trigger correlations ("Stress makes symptoms 30% worse")
- Lifestyle impact (sleep, stress, exercise correlations)
- Hydration patterns
- Duration trends
- Medication impact analysis

**13+ Chart Types:**
- Severity donut chart (mild / moderate / severe / critical distribution)
- Category breakdown bar chart
- Weekly comparison (entries per week)
- Trigger impact rankings
- Mood & energy trend lines
- Sleep-severity scatter plot with trendline
- Time-of-day symptom heatmap
- 7-day severity forecast
- 21-day EMA severity trend with particle effects
- Symptom frequency pie chart
- Daily entry count bars
- Weekly mood distribution
- Day-of-week × hour severity heatmap

All charts animate on load — donuts grow, bars scale, lines trim.

---

### 14. Doctor Prep

Generate a comprehensive visit summary:

- **Configurable date range** — 7 days, 30 days, 90 days, 1 year, or custom
- **Key metrics** — total entries, average severity, most frequent symptom, worst day
- **Ranked symptom table** — sorted by frequency with trend indicators (improving / stable / worsening)
- **Trigger highlights** — top 3 triggers by severity impact, with exact numbers
- **Auto-generated questions** — suggested talking points based on your data:
  - Worsening symptoms → "Should we adjust treatment?"
  - Strong triggers → "Are there preventive measures?"
  - Sleep correlations → "Could sleep quality be a factor?"
  - Medication compliance issues → "Should we simplify my regimen?"
- **Share and copy** — export as text via share sheet or clipboard

**PDF Report** (via PDFReportGenerator):
- Multi-page professional document with page numbers
- Wellness score, symptom summary tables, severity distribution histograms
- Trigger analysis, daily check-in summaries, HealthKit trends
- Medication list, weather/activity correlations
- Color-coded by symptom category, alternating row backgrounds
- Shareable via Mail, AirDrop, or any system share target

---

### 15. History & Timeline

Browse all past symptom entries with:

- **Time range selector** — 7D, 30D, 90D, 1Y
- **Severity trend chart** — bars or line, bucketed by day/week/month
- **Summary stats** — total entries, average severity, unique symptoms
- **Day-of-week × hour heatmap** — color intensity maps frequency and severity
- **Full entry list** — descending by date, with severity badges and duration labels

---

### 16. Notifications

Local-only push notifications:

- **Daily reminder** at a user-configurable time, with rotating friendly messages
- **Streak reminder** at 8 PM if no entries logged that day
- **Medication reminders** — tied to medication schedule
- Fully optional. Respects system notification settings.

---

## Onboarding

A 13-page guided wizard that builds your health profile:

| Page | What It Captures |
|------|-----------------|
| 0 | Welcome — animated ECG + breathing rings |
| 1 | Health goals — multi-select from 6 options |
| 2 | Primary symptoms — select from 30+ library |
| 3 | Symptom frequency — daily, weekly, occasionally, rarely |
| 4 | Life impact — work, sleep, relationships, etc. |
| 5 | Lifestyle habits — exercise, diet, stress, sleep |
| 6 | Age and biological sex |
| 7 | Pre-existing conditions |
| 8 | Typical severity range |
| 9 | Flare-up duration |
| 10 | Overall health self-rating |
| 11 | Personal health notes and goals |
| 12 | Score teaser — "Ready to see your score?" |

After onboarding, the app computes a **baseline wellness score** from your answers. This score animates in a dramatic reveal — spinning rings, particle effects, counting up from 0 — before presenting the subscription paywall.

**Baseline score formula** (starts at 65):
- Age adjustments (+3 for <25, -4 for >75)
- Health rating impact (±3 per point from midline)
- Severity baseline penalty
- Stress penalty
- Sleep deviation from optimal 7–8 hours
- Exercise bonus
- Frequency adjustments (daily -8, rarely +5)
- Duration adjustments (3+ years -10, <1 month +3)
- Impact area count penalty
- Condition count penalty
- Symptom category count penalty
- Final clamp: 12–88

This bias gradually fades as you log real data, fully disappearing around 60 entries.

---

## Subscriptions

Two plans via StoreKit 2:

| Plan | Price | Per Month | Features |
|------|-------|-----------|----------|
| **Yearly** (recommended) | $39.99/yr | $3.33/mo | Unlimited logging, AI patterns, doctor PDF, weather/HealthKit correlations, priority support |
| **Monthly** | $9.99/mo | $9.99/mo | Unlimited logging, AI patterns, doctor PDF, weather/HealthKit correlations |

- Auto-renewing with cancellation anytime
- Restore purchases across devices
- Transaction verification for security
- Subscription status checked on every app foreground

---

## Design System

### Color Palette

| Role | Light Mode | Dark Mode |
|------|-----------|-----------|
| Background | #FAF9F6 (warm off-white) | #111318 (near-black) |
| Accent | #00C49A (teal) | #00C49A (teal) |
| Violet | #7C5CFC | #7C5CFC |
| Success | #22C55E | #22C55E |
| Warning | #F59E0B | #F59E0B |
| Error | #EF4444 | #EF4444 |

Gradients flow from teal to violet. Severity colors scale green → yellow → orange → red.

### Typography

Rounded display fonts for headlines (friendly, approachable). Clean sans-serif for body text. Monospaced for data metrics. Full scale from 11pt captions to 42pt display.

### Spacing

Systematic scale: 2pt (xxxs) through 80pt (hero). Section spacing at 56pt. Consistent 24pt (xl) minimum between content groups.

### Components

- **SSButton** — primary, secondary, ghost, danger, and accent gradient styles. 52pt height, loading spinner, haptic feedback.
- **SSTextField** — animated focus border, optional icon, secure toggle
- **SSCard** — surface background with subtle shadow and separator border
- **SSChip** — capsule tags with selected/unselected states
- **SSProgressRing** — circular progress with customizable color and width
- **SSNavigationBar** — centered title with optional leading/trailing actions
- **SSEmptyState** — icon + title + subtitle + optional action button
- **SSToast** — temporary bottom-anchored notification

### Haptics

Five levels: light, medium, soft, success, and selection. Used throughout — tapping buttons, advancing steps, saving entries, completing purchases.

### Accessibility

- All interactive elements have `.accessibilityLabel`
- Touch targets ≥ 44pt
- Contrast ratios ≥ 4.5:1
- Status communicated via color + icon (never color alone)

---

## Architecture

### Data Layer

- **SwiftData** for persistence with CloudKit sync for cross-device backup
- Encrypted at rest (FileManager + SwiftData protection)
- Single `DataStore` service handles all CRUD operations
- Migration support from legacy UserDefaults storage

### Models

| Model | Purpose |
|-------|---------|
| SymptomEntry | Individual symptom log (symptom, severity, triggers, duration, notes) |
| DailySummary | Daily check-in (mood, energy, sleep, stress, water, notes) |
| Medication | Drug definition (name, dosage, frequency, time, active status) |
| MedicationLog | Adherence record (timestamp, taken/missed) |
| JournalEntry | Diary entry (title, body, mood, tags, favorite flag) |
| WeatherSnapshot | Daily weather (temp, humidity, pressure, code) |
| HealthSnapshot | Daily HealthKit data (sleep, heart rate, steps, exercise) |
| CustomSymptom | User-created symptoms beyond the built-in library |
| OnboardingProfile | Onboarding answers for baseline calculation |

### Services

| Service | Responsibility |
|---------|---------------|
| DataStore | SwiftData persistence, CloudKit sync, correlation queries |
| HealthKitManager | HealthKit authorization and daily data fetching |
| WeatherService | Location + Open-Meteo API for current conditions |
| NotificationManager | Local notification scheduling and permissions |
| SubscriptionManager | StoreKit 2 product loading, purchasing, restoring, verification |
| PDFReportGenerator | Multi-page doctor visit PDF creation |

### ML Engines (All On-Device)

| Engine | What It Does |
|--------|-------------|
| WellnessScoreEngine | CoreML wellness scoring with heuristic fallback |
| SymptomAnalysisEngine | Pattern classification, trigger analysis, clustering, flare-up risk |
| TimeSeriesAnalyzer | Smoothing, decomposition, anomaly detection, trend analysis |
| SymptomPredictionEngine | Severity and likelihood forecasting |
| StatisticalAnalysis | Welch's t-test, Pearson correlation, descriptive statistics |
| MLTestHarness | Synthetic data generation + 25-test validation suite |

### App Flow

```
Splash (2.2s) → Onboarding (13 pages) → Score Reveal → Paywall → Main App
                                                                    │
                                          ┌─────────────────────────┼─────────────────────────┐
                                          │                         │                         │
                                        Home                    Journal                   Insights
                                     (Dashboard)              (Diary)                   (AI Analysis)
                                          │                         │                         │
                                    ┌─────┼─────┐            ┌─────┼─────┐            ┌─────┼─────┐
                                    │     │     │            │     │     │            │     │     │
                                  Quick  Check  Meds       Compose Detail Search    Charts Doctor Forecast
                                  Actions -In   Today                                      Prep
                                    │
                              ┌─────┼─────┐
                              │           │
                           Log         Settings
                          Symptom
```

### Navigation

Custom 5-tab bottom bar:
1. **Home** — dashboard with wellness score, quick actions, check-in
2. **Journal** — health diary with tags and mood tracking
3. **Add** (center, floating teal button) — opens symptom logging sheet
4. **Insights** — AI analysis, charts, correlations, doctor prep
5. **Settings** — profile, notifications, data, privacy, support

---

## Privacy & Security

| Principle | Implementation |
|-----------|---------------|
| Health data stays on-device | SwiftData local storage, no cloud transmission of health info |
| HealthKit read-only | Sleep, heart rate, steps, exercise — never uploaded |
| Weather: location only | Coordinates sent to Open-Meteo for local weather, no health data attached |
| Encrypted at rest | SwiftData + FileManager data protection |
| No third-party health analytics | Anonymous usage analytics only (screen views, feature usage) |
| Subscription via Apple | StoreKit 2 with transaction verification through Apple servers |
| CloudKit sync (optional) | Apple's encrypted iCloud for cross-device, still no third-party access |

---

## Technical Stack

- **Language**: Swift
- **UI**: SwiftUI (iOS 17+)
- **Persistence**: SwiftData + CloudKit
- **ML**: CoreML (on-device)
- **Health**: HealthKit (read-only)
- **Weather**: Open-Meteo API (free, no key)
- **Payments**: StoreKit 2
- **Notifications**: UNUserNotificationCenter (local only)
- **PDF**: UIGraphicsPDFRenderer
- **Minimum**: iOS 17.0

All frameworks are built-in Apple APIs — zero third-party dependencies.

---

## Quality Gates

| Gate | Criteria |
|------|----------|
| Compile | 0 errors, 0 warnings, no force unwraps, no deprecated APIs |
| Test | All pass, >80% coverage on ML engines |
| ML | Wellness scores valid 0–100, predictions ≥70% confidence, no NaN/Inf |
| Memory | No retain cycles, `[weak self]` enforced in all closures |
| Accessibility | All labels present, ≥4.5:1 contrast, ≥44pt targets |
| Privacy | HealthKit data never leaves device, no hardcoded user data |

---

*Built by Keshav Krishnan. Made with care for your health.*
