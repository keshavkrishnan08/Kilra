# Thread Templates: High-Engagement Long-Form

> Threads get ~3x engagement of single tweets. Aim for 2-4 threads per week once in Phase 2+.
> Cowork drafts threads using these templates. Keshav reviews and adds personal details.

---

## Thread Rules

1. **Hook tweet is everything.** If the first tweet doesn't stop the scroll, nobody reads the rest. Spend 50% of your effort on tweet 1.
2. **5-8 tweets is the sweet spot.** Under 5 feels thin. Over 10 and people drop off.
3. **Each tweet should stand alone.** If someone screenshots just one tweet from the thread, it should still make sense and be interesting.
4. **End with something human, not a CTA.** "follow for more" kills threads. End with a thought, a question, or a feeling.
5. **No micro-mistakes in threads.** Threads feel intentional and polished. Save the typos for casual tweets.
6. **One image per thread is fine.** Put it in tweet 2 or 3, not tweet 1 (text-only hooks perform better).

---

## Template 1: The Build Story

**Structure:** What I built → Why → How → What I learned → What's next

**Example:**

> **Tweet 1 (hook):**
> i built an on-device ML engine that predicts symptom flare-ups before they happen. no cloud, no API calls, everything runs on your phone.
>
> here's how it works and what i got wrong along the way:

> **Tweet 2:**
> the flare-up predictor looks at 10 signals: recent severity spikes, entry volume changes, mood drops, sleep quality, heart rate, step count, active triggers, symptom diversity, and your baseline profile.
>
> each signal contributes a weighted probability. the final score maps to low / moderate / elevated / high risk.

> **Tweet 3:**
> the hardest part wasn't the math. it was deciding how much weight to give each signal.
>
> early versions weighted sleep too heavily, every bad night predicted a flare-up. turns out sleep alone isn't enough. you need the combination of poor sleep + active triggers + severity trend to actually predict anything useful.

> **Tweet 4:**
> another thing i got wrong: cold start. when someone first downloads the app, you have zero data. predicting anything felt irresponsible.
>
> solution: use onboarding answers to create a baseline bias that fades as real data accumulates. by ~60 logged entries the bias is basically gone and the model runs on actual patterns.

> **Tweet 5:**
> the test suite generates synthetic patients with configurable severity trends, trigger probabilities, and cyclical patterns. then validates the engine catches what it should.
>
> current accuracy on the test harness: predictions match expected risk level ~73% of the time. not perfect but better than guessing.

> **Tweet 6:**
> the thing nobody tells you about building ML for health: accuracy matters less than trust. if the app says "elevated flare-up risk" and the user feels fine, they stop trusting it.
>
> so i added transparency. you can see exactly which signals contributed and how much. no black box.

> **Tweet 7:**
> still iterating on this. the prediction gets better as users log more data, which creates a nice feedback loop. but it also means the first two weeks feel less useful.
>
> working on ways to surface other value during that ramp-up period so people stick around long enough for the predictions to get good.

---

## Template 2: The Lessons Thread

**Structure:** Big claim → 5-7 specific lessons with context → honest reflection

**Example:**

> **Tweet 1 (hook):**
> 3 months of building a health app solo. here are 7 things i know now that i wish i knew at the start:

> **Tweet 2:**
> 1. privacy isn't a feature, it's architecture. i decided early that health data never leaves the device. that one decision shaped everything, SwiftData instead of Firebase, CoreML instead of cloud APIs, on-device processing for every analysis.
>
> you can't bolt on privacy later.

> **Tweet 3:**
> 2. onboarding is your first impression and your data pipeline. the 13-page onboarding quiz isn't just getting to know the user. every answer feeds the ML engine's baseline predictions.
>
> if i made onboarding shorter, predictions would be worse. tradeoff.

> **Tweet 4:**
> 3. your ML model is only as good as your test harness. i built a synthetic data generator that creates fake patients with configurable patterns. without it i would've shipped a wellness score that returned 104/100 and thought it was fine.

> **Tweet 5:**
> 4. design systems save you on day 30, not day 1. the first week i resisted building a proper design system. "i'll just use system colors." by week 3 i had 14 different grays. built the design system. never looked back.

> **Tweet 6:**
> 5. health apps have a unique retention problem. people feel better → stop tracking → lose their data → get worse → come back angry they lost their streak. the streak bonus in the wellness score is my attempt at solving this but im not sure its enough yet.

> **Tweet 7:**
> 6. doctor prep reports are the sleeper feature. i almost cut them. turns out "walk into your appointment with a PDF of your last 6 months" is the thing people get most excited about. listen to what users actually want, not what you think is technically impressive.

> **Tweet 8:**
> 7. building alone is harder than the code. some days the loneliest part isnt debugging a weird SwiftData crash at midnight. its having nobody to high-five when something finally works.
>
> if you're building solo, find your people. even just a few DMs make a difference.

---

## Template 3: The Explainer

**Structure:** Complex concept → Simple breakdown → Why it matters → Real example

**Example:**

> **Tweet 1 (hook):**
> most health apps show you a chart and call it "insights." here's what actual pattern detection looks like under the hood.
>
> (warning: some math ahead but i'll keep it readable)

> **Tweet 2:**
> step 1: classify the pattern. is this symptom chronic, episodic, cyclical, improving, worsening, or too new to tell?
>
> we use linear regression slope, gap analysis, and autocorrelation to figure this out. if the slope is positive (>0.03) and consistent, it's worsening. negative slope = improving.

> **Tweet 3:**
> step 2: find your triggers. most apps just ask "what triggered this?" and show a count. that's useless.
>
> we use bayesian inference: P(high_severity | trigger). basically, when stress is present, how much worse are your symptoms compared to when it isn't? that difference is your trigger risk score.

> **Tweet 4:**
> step 3: find symptom clusters. if headaches and fatigue always show up on the same days, that matters.
>
> we compute jaccard similarity (overlap / total) between every symptom pair. if it's above 25% with at least 2 co-occurrences, we surface it as a cluster.

> **Tweet 5:**
> step 4: detect anomalies. a random bad day is different from a trend change.
>
> z-score anomaly detection compares each data point to a local 7-day window. if it's >2 standard deviations from the local mean, it's flagged as a spike or dip. this is how we separate noise from signal.

> **Tweet 6:**
> all of this runs on your phone. no cloud server, no API call, no data leaving the device.
>
> that's a deliberate choice. your health patterns are nobody's business but yours.

---

## Template 4: The Honest Journey

**Structure:** Vulnerable opening → Specific moments → What you're learning → No neat conclusion

**Example:**

> **Tweet 1 (hook):**
> some weeks building feels like flying. this was not one of those weeks. here's an honest recap of what happened:

> **Tweet 2:**
> monday: rewrote the medication tracking UI for the third time. still dont love it. the problem is showing "active medications" and "today's doses" without the screen feeling cluttered. every layout i try has a different tradeoff.

> **Tweet 3:**
> tuesday-wednesday: discovered my SwiftData model was silently dropping medication logs when the app backgrounded. spent two days figuring out it was a context save timing issue. fix was 3 lines of code.
>
> two days. three lines.

> **Tweet 4:**
> thursday: had a good conversation with someone who manages 5 medications daily. they said the hardest part isnt remembering to take them, its remembering whether they already took them this morning.
>
> completely changed how i think about the check-off UI.

> **Tweet 5:**
> friday: shipped nothing. sat in a coffee shop and sketched the next 4 features on paper. sometimes the most productive thing is stepping away from the keyboard.

> **Tweet 6:**
> the thing about building solo is there's nobody to tell you "this is normal" or "that approach is wrong." you just kind of figure it out and hope you're not wasting weeks on the wrong things.
>
> anyway. back at it monday.

---

## Template 5: The Comparison / Hot Take

**Structure:** Observation → Your experience → The nuance everyone misses → Your stance

**Example:**

> **Tweet 1 (hook):**
> every health app markets itself as "AI-powered" now. most of them are running basic conditional averages and calling it machine learning.
>
> here's the difference between real pattern detection and marketing copy:

> Continue with specific technical comparisons, what "AI-powered" actually requires, and where the bar should be. End with what you built and why it's different, but lead with the education, not the pitch.

---

## Thread Scheduling

| Phase | Threads/Week | Best Days | Best Time |
|-------|-------------|-----------|-----------|
| Phase 1 | 1 | Wednesday or Thursday | 12-1 PM EST |
| Phase 2 | 2 | Tuesday + Thursday | 12-1 PM or 3-4 PM EST |
| Phase 3 | 2-3 | Tue + Thu + optional Saturday | Varies |
| Phase 4-5 | 3-4 | Spread across the week | Varies based on analytics |

---

## Thread Performance Tracking

| # | Date | Topic | Template Used | Tweets in Thread | Impressions (tweet 1) | Total Impressions | Likes | Replies | RTs | Bookmarks | Drop-off Point |
|---|------|-------|--------------|-----------------|----------------------|------------------|-------|---------|-----|-----------|----------------|
| | | | | | | | | | | | |

**Drop-off point:** which tweet in the thread had the biggest impression drop from the previous tweet. This tells you where people stopped reading. Optimize future threads based on this.
