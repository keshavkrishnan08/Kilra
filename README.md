# Symptly

**A SwiftUI symptom and wellness tracker. Log a symptom in four steps, check in on mood and
energy, and get a wellness score, tested trigger correlations, and a summary to bring to a doctor,
all computed on the phone.**

![Four Symptly screens from the iOS simulator: the first onboarding page, the personalization step with daily reminders and Apple Health sync, the home screen with a wellness score of 84, today's stats, and quick actions for logging a symptom, checking in, medications, and the journal, and the empty journal](docs/screens.png)

A doctor's visit compresses weeks of symptoms into "it has been bad lately." Memory is a poor
instrument for that: it overweights the last few days and forgets what came before a flare.
Symptly turns daily logs into a structured history (symptom, severity, duration, triggers, mood,
energy, sleep, weather) and then asks which of those factors actually go with worse days, using
significance tests rather than raw averages, so the patterns it shows have some evidence behind
them.

```
onboarding (13 steps)  ->  baseline score  ->  subscription
log a symptom: pick (29 built-in or custom) -> severity 1 to 10 -> duration, triggers, notes -> save
daily check-in: mood, energy, sleep, stress, water
context: Apple Health (sleep, heart rate, steps, exercise) and Open-Meteo weather
    ->  SwiftData store, synced through the user's own iCloud
    ->  wellness score (weighted formula, 5 to 95), 7-day trend, flare-up check
    ->  Welch t-tests and Pearson correlations for triggers, sleep, and mood; weather and medication comparisons
    ->  pattern type, symptom clusters, cyclical patterns, severity forecast
    ->  charts, doctor-prep summary, PDF report, CSV export
```

Log today. Show the pattern at the appointment.

## The core idea

1. **Logging has to be fast or it stops.** A symptom entry is four short steps: choose from 29
   built-in symptoms in 7 categories (pain, digestive, neurological, mental health, respiratory,
   skin, energy) or a custom one, set severity, add duration and any of 10 common triggers, and
   review.
2. **Correlations are tested, not eyeballed.** Trigger effects compare severities with and
   without the trigger using Welch's t-test and an effect size. Sleep and mood use Pearson
   correlation. A trigger is listed only when its effect is significant, has an effect size of at
   least 0.2, or moves average severity by a full point.
3. **Context comes from the phone.** Sleep, heart rate, steps, and exercise minutes are read from
   Apple Health. Temperature, humidity, pressure, and conditions come from Open-Meteo for the
   phone's approximate location. Insights then compare average severity on low- and
   high-pressure days, humid and dry days, and against sleep, steps, and medication use.
4. **The score explains itself.** The wellness score starts at 65 and moves with mood, energy,
   severity, symptom volume and variety, logging streak, and the Apple Health signals. The
   Insights screen shows the breakdown, so a user sees why it changed.
5. **The output is for a clinician.** Doctor Prep condenses a date range into key numbers, top
   symptoms, trigger highlights, medication compliance, and suggested questions, and the same
   data exports as a PDF report or CSV through the share sheet.

## What it does

| Area | In the code |
|---|---|
| Onboarding | 13 steps: symptom frequency, life areas, existing conditions, personalization (reminder time, Apple Health), then a baseline score reveal and the subscription screen |
| Home | Today's logged count, peak, average, and streak; the wellness score with a 7-day line; quick actions for symptom, check-in, medications, and journal; a flare-up alert when the last 3 days run worse than the 11 days before |
| Log | Four-step symptom entry with search and category filters, severity 1 to 10, duration, triggers (stress, poor sleep, weather, food, exercise, screen time, alcohol, caffeine, dehydration, medication), and notes |
| Insights | Score breakdown, top correlations, flare-up risk, pattern type (chronic, episodic, cyclical, improving, worsening, new onset), symptom clusters, and charts: severity distribution, heatmap, and trend; category breakdown and radar; mood and energy; sleep vs severity; time of day; trigger frequency; week over week; tomorrow's forecast |
| Doctor Prep | Date range, key numbers, top symptoms, trigger highlights, medication compliance, questions for your doctor, and a plain-text summary |
| Reports | A multi-section PDF (score, symptom table, severity distribution, triggers, check-ins, medications, health data, correlations) and a CSV export |
| Medications | Name, dosage, frequency, and time of day, with taken logs and reminders at 8 AM, 1 PM, 6 PM, 9 PM, or noon by time of day |
| Journal | Entries with title, body, optional mood, tags, and favorites |
| Notifications | A daily reminder at the chosen time, an 8 PM streak reminder, and medication reminders |
| Settings | Reminders, Apple Health, CSV export, clear all data, redo onboarding, recalculate the baseline |
| Subscription | StoreKit 2 with monthly and yearly products ($9.99 and $39.99 in the local StoreKit configuration) |

## How it works

**Persistence.** SwiftData with nine `@Model` types (profile, symptom entries, daily summaries,
medications and their logs, weather and health snapshots, custom symptoms, journal entries) in a
container configured for automatic CloudKit sync. A one-time migration moves older
`UserDefaults` data into the store.

**Wellness score.** `WellnessScoreEngine` computes each day from a 65 baseline: up to +20 for
mood and +15 for energy, up to -25 for average and peak severity, capped penalties for symptom
volume, variety, and entries today, an extra penalty when high severity meets high volume, up to
+12 for a logging streak, and small Apple Health bonuses for 7 to 9 hours of sleep, steps, and
exercise. An onboarding bias fades as real entries accumulate. The result is clamped to 5 to 95.

**Statistics.** `StatisticalAnalysis` implements Welch's t-test with Welch-Satterthwaite degrees
of freedom and p-values from the regularized incomplete beta function, Pearson correlation,
descriptive statistics, IQR outliers, and z-scores. `TimeSeriesAnalyzer` adds exponential and
double-exponential smoothing (alpha 0.3), moving averages, a 7-day trend and seasonal
decomposition, anomalies beyond 2 standard deviations of a 7-day window, and a short forecast.

**Pattern analysis.** `SymptomAnalysisEngine` classifies the overall pattern, scores each
trigger over the last 30 days by combining the severity gap with a Bayes estimate of a
high-severity day given the trigger, clusters symptoms from a same-day co-occurrence matrix, and
looks for cyclical timing. `SymptomPredictionEngine` estimates tomorrow's severity and likelihood
per symptom from the historical baseline, recent trend, day of week, active triggers, and mood,
energy, and sleep.

**Core ML model.** `train_wellness_model.py` trains a scikit-learn gradient-boosting regressor
(300 trees, depth 5) to predict the wellness score from eight inputs and converts it to
`WellnessScoreModel.mlmodel` with coremltools. The app bundles and loads it.

**Context.** `HealthKitManager` requests read access to sleep analysis, heart rate, step count,
and exercise time. `WeatherService` asks Core Location for a kilometer-accuracy fix and calls the
keyless Open-Meteo API for current temperature, humidity, surface pressure, and WMO weather code.

**Design system.** `Design/` holds the color tokens, typography, custom icon set, and shared
components used across every screen.

## Run it

Open `Symptly.xcodeproj` in Xcode and run the `Symptly` scheme on a simulator or device (iOS 17.0
or later). `Symptly/Resources/Symptly.storekit` lets you test the subscription locally. Apple
Health and iCloud need a signing team with those capabilities.

To regenerate the Core ML model:

```bash
pip install numpy scikit-learn coremltools
python3 train_wellness_model.py   # writes Symptly/ML/WellnessScoreModel.mlmodel
```

`generate_icons.py`, `regenerate_icons.py`, and `generate_screenshots.py` rebuild the app icon
set and the store-style marketing images with Pillow.

## Layout

```
Symptly/
  App/                    app entry, flow state (onboarding, score reveal, paywall, main), root view
  Models/                 value types and the SwiftData @Model classes
  Services/               DataStore, HealthKitManager, WeatherService, NotificationManager,
                          PDFReportGenerator, SubscriptionManager
  ML/                     WellnessScoreEngine, SymptomAnalysisEngine, SymptomPredictionEngine,
                          StatisticalAnalysis, TimeSeriesAnalyzer, MLTestHarness, WellnessScoreModel.mlmodel
  Views/                  Home and Insights, Symptoms, Journal, Medications, Insights/DoctorPrep,
                          History, Onboarding, Paywall, Settings
  Design/                 design system and shared components
  Resources/              local StoreKit configuration
SymptlyTests/             unit test target
SymptlyUITests/           UI test target
train_wellness_model.py   trains and exports the Core ML model
generate_*.py             icon and marketing image generators
screenshots/              simulator captures and store-style images
docs/                     privacy policy and support page
```

## Honesty

* The wellness score on screen comes from the weighted formula in `WellnessScoreEngine`. The
  bundled Core ML model is trained on synthetic data that follows the same formula, and the
  scoring path does not call it yet.
* Insights are the statistics and rules described above, run on the device. There is no language
  model and no server.
* Personal correlations rest on small samples over 30-day windows. They describe one person's log.
  They are not medical advice, and the app is not a diagnostic tool.
* Data leaves the phone in two ways: the SwiftData store syncs through the user's own iCloud
  account, and weather requests send approximate coordinates to Open-Meteo.
* The test targets contain only the Xcode template tests.
