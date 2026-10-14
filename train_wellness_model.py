#!/usr/bin/env python3
"""
Train a GradientBoostingRegressor to predict a Wellness Score (0-100)
from daily health-tracking inputs, then export it as a CoreML .mlmodel.

Inputs
------
symptom_count   (Int)    – symptoms logged in past 7 days
avg_severity    (Double) – mean severity (1-10) over past 7 days
max_severity    (Int)    – worst severity today
streak          (Int)    – consecutive logging days
mood            (Int)    – today's mood (1-5)
energy          (Int)    – today's energy (1-5)
unique_symptoms (Int)    – distinct symptom types in past 7 days
entries_today   (Int)    – symptoms logged today

Output
------
wellness_score  (Double) – 0-100
"""

import numpy as np
from sklearn.ensemble import GradientBoostingRegressor
from sklearn.model_selection import train_test_split
from sklearn.metrics import mean_absolute_error, r2_score
import coremltools as ct
import os

# ── reproducibility ──────────────────────────────────────────────
np.random.seed(42)
N = 6000  # training samples

# ── 1. Generate synthetic data ───────────────────────────────────

# Draw raw features from realistic distributions
symptom_count   = np.random.randint(0, 30, size=N)           # 0-29 symptoms in 7d
avg_severity    = np.round(np.random.uniform(1.0, 10.0, N), 2)
max_severity    = np.random.randint(1, 11, size=N)           # 1-10
streak          = np.random.randint(0, 120, size=N)           # 0-119 days
mood            = np.random.randint(1, 6, size=N)             # 1-5
energy          = np.random.randint(1, 6, size=N)             # 1-5
unique_symptoms = np.random.randint(0, 15, size=N)            # 0-14 types
entries_today   = np.random.randint(0, 10, size=N)            # 0-9

# Ensure logical constraints:
# unique_symptoms should not exceed symptom_count
unique_symptoms = np.minimum(unique_symptoms, symptom_count)
# max_severity should be >= avg_severity (roughly)
max_severity = np.maximum(max_severity, np.ceil(avg_severity).astype(int))
# entries_today should not exceed symptom_count
entries_today = np.minimum(entries_today, symptom_count)

# ── 2. Build a ground-truth wellness score with realistic correlations ──

# Positive contributors  (mood, energy, streak)
# Negative contributors  (symptom_count, avg_severity, max_severity, unique_symptoms, entries_today)

base_score = (
    # Mood and energy are strong positive signals (each 1-5 → contribute up to ~20 pts)
    4.0 * mood
    + 4.0 * energy
    # Streak rewards consistency: diminishing returns via sqrt
    + 1.5 * np.sqrt(streak)
    # Symptom burden pulls the score down
    - 1.2 * symptom_count
    - 3.0 * avg_severity
    - 1.5 * max_severity
    - 1.0 * unique_symptoms
    - 1.5 * entries_today
)

# Interaction: high severity + many symptoms is extra punishing
interaction_penalty = 0.15 * symptom_count * avg_severity

# Normalize into 0-100 range
raw = base_score - interaction_penalty
# Shift so the theoretical min lands near 0
raw_shifted = raw - raw.min()
# Scale so the theoretical max lands near 100
raw_scaled = 100.0 * raw_shifted / (raw_shifted.max() + 1e-9)

# Add Gaussian noise (std ~4 pts) for realism
noise = np.random.normal(0, 4.0, size=N)
wellness_score = np.clip(raw_scaled + noise, 0, 100).round(1)

# ── 3. Assemble feature matrix ──────────────────────────────────

feature_names = [
    "symptom_count",
    "avg_severity",
    "max_severity",
    "streak",
    "mood",
    "energy",
    "unique_symptoms",
    "entries_today",
]

X = np.column_stack([
    symptom_count,
    avg_severity,
    max_severity,
    streak,
    mood,
    energy,
    unique_symptoms,
    entries_today,
])
y = wellness_score

# ── 4. Train / evaluate ─────────────────────────────────────────

X_train, X_test, y_train, y_test = train_test_split(
    X, y, test_size=0.2, random_state=42
)

model = GradientBoostingRegressor(
    n_estimators=300,
    max_depth=5,
    learning_rate=0.1,
    subsample=0.8,
    random_state=42,
)
model.fit(X_train, y_train)

y_pred = model.predict(X_test)
mae = mean_absolute_error(y_test, y_pred)
r2 = r2_score(y_test, y_pred)

print(f"Test MAE : {mae:.2f}")
print(f"Test R²  : {r2:.4f}")
print()

# Feature importances
for name, imp in sorted(
    zip(feature_names, model.feature_importances_), key=lambda x: -x[1]
):
    print(f"  {name:20s}  {imp:.4f}")

# ── 5. Convert to CoreML ────────────────────────────────────────

coreml_model = ct.converters.sklearn.convert(
    model,
    input_features=feature_names,
    output_feature_names="wellness_score",
)

# Metadata
coreml_model.author = "Symptly"
coreml_model.short_description = (
    "Predicts a 0-100 Wellness Score from daily symptom-tracking inputs."
)

# Input descriptions
input_desc = {
    "symptom_count":   "Number of symptoms logged in the past 7 days",
    "avg_severity":    "Average symptom severity (1-10) over the past 7 days",
    "max_severity":    "Maximum symptom severity recorded today",
    "streak":          "Consecutive days the user has logged symptoms",
    "mood":            "Today's self-reported mood (1-5)",
    "energy":          "Today's self-reported energy level (1-5)",
    "unique_symptoms": "Number of distinct symptom types in the past 7 days",
    "entries_today":   "Number of symptom entries logged today",
}
for feat, desc in input_desc.items():
    coreml_model.input_description[feat] = desc

coreml_model.output_description["wellness_score"] = (
    "Predicted wellness score (0-100)"
)

# Save
output_dir = os.path.join(
    os.path.dirname(__file__),
    "Symptly", "ML",
)
os.makedirs(output_dir, exist_ok=True)
output_path = os.path.join(output_dir, "WellnessScoreModel.mlmodel")
coreml_model.save(output_path)

print(f"\nModel saved → {output_path}")
