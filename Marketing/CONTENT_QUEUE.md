# Content Queue: Ready to Post

> Pre-loaded content waiting to be posted. Cowork adds drafts here during morning block. Chrome posts from here on schedule. After posting, entries move to POST_CATALOG.md.

---

## How This File Works

1. **Cowork (morning):** Drafts 3-5 posts → adds to "Today's Queue" with status `ready`
2. **Chrome (scheduled):** Reads next `ready` post → posts it → Cowork updates status to `posted`
3. **End of day:** Cowork moves all `posted` entries to POST_CATALOG.md and clears this section
4. **Weekly:** Cowork pre-loads 5-7 days of content in the "Upcoming" section

---

## Today's Queue

| # | Scheduled Time | Post Text | Format | Topic | Image | Hashtags | Status | Actual Post Time |
|---|---------------|-----------|--------|-------|-------|----------|--------|-----------------|
| | 8:00 AM | | | | | | ready | |
| | 12:30 PM | | | | | | ready | |
| | 3:30 PM | | | | | | ready | |
| | 5:30 PM | | | | | | ready | |
| | 9:00 PM | | | | | | ready | |

**Status options:** `draft` → `ready` → `posting` → `posted` → `moved to catalog`

---

## Pre-Loaded Content: Week 1 (Phase 1: The Builder)

> Day 1-7 starter content. All posts follow VOICE_BIBLE.md voice, TWITTER_POST_FORMATS.md formats, quantified, vulnerability-first where appropriate. Micro-mistakes applied per guide.

### Day 1

**Post 1 (8:00 AM), Introduction**
> been building a health tracking app for the last 3 months. solo. using AI for about 80% of the code. figured its time to start sharing what thats actually like
>
> the app is called symptly, tracks 30+ symptoms, finds patterns with on-device ML, and generates doctor prep reports. your health data never leaves your phone
>
> more coming. this is day 1 of sharing the journey

Format: tweet | Topic: build | Image: home_dashboard.png | Tags: #buildinpublic
Status: ready

**Post 2 (12:30 PM), Tool reveal**
> my entire stack for building an ios app solo in 2026:
> - claude code (writes ~80% of the code)
> - swiftui (no storyboards ever)
> - swiftdata + cloudkit for persistence
> - coreml for on-device ML
> - zero third party dependencies
>
> total cost: $20/mo for claude. everything else is built into ios

Format: tweet | Topic: ai-tool | Image: none | Tags: #vibecoding #buildinpublic
Status: ready

**Post 3 (5:30 PM), Vulnerable/personal**
> the weird thing about building alone is theres nobody to tell you if youre doing it right. you just ship something and hope the silence doesnt mean its bad
>
> day 87 of finding out

Format: tweet | Topic: personal | Image: none | Tags: none
Status: ready

### Day 2

**Post 1 (8:00 AM), Feature showcase**
> built the symptom logging flow today. 4 steps: pick a symptom from 30+ options across 7 categories, rate severity 1-10, add triggers and duration, review and save
>
> the whole thing takes maybe 15 seconds. tried to make it fast because nobody wants to spend 2 minutes logging a headache when they already have a headache

Format: image | Topic: build | Image: symptom_select.png | Tags: #buildinpublic
Status: ready

**Post 2 (12:30 PM), AI tools honest take**
> thing about vibe coding nobody mentions: you still have to understand every line. i accepted a batch of AI suggestions without reading them carefully last week and spent 3 hours untangling the mess
>
> AI writes fast. reviewing AI output is the actual skill

Format: tweet | Topic: ai-tool | Image: none | Tags: #vibecoding
Status: ready

**Post 3 (5:30 PM), Health empathy**
> most people track their symptoms in their head. "i think tuesdays are worse" or "maybe dairy triggers it." but memory is terrible at patterns. you remember the worst days and forget the medium ones
>
> thats why i log everything. 47 days of data told me things i never wouldve guessed

Format: tweet | Topic: health | Image: none | Tags: none
Status: ready

### Day 3

**Post 1 (8:00 AM), Technical/ML**
> the wellness score algorithm was my favorite thing to build. it takes mood, energy, symptom severity, sleep, steps, and exercise, weights them differently, and outputs a score from 0-100
>
> severity penalty is the heaviest at 25%. streak bonus rewards consistency at 12%. the score starts at 65 and adjusts from there
>
> no black box. you can see exactly what contributed to your number

Format: image | Topic: build | Image: insights_score.png | Tags: #buildinpublic #coreml
Status: ready

**Post 2 (12:30 PM), Honest struggle**
> spent 2 days debugging a wellness score that kept returning 104/100. turns out the clamping function i wrote... wasnt actually clamping. it was just passing the value through
>
> the fix was literally changing one operator. 2 days for one character
>
> shipping is humbling

Format: tweet | Topic: build | Image: none | Tags: none
Status: ready

**Post 3 (5:30 PM), Question/engagement**
> genuine question for anyone tracking their health: do you actually remember to log symptoms consistently or does it fall off after a week?
>
> trying to figure out the right reminder system. daily nudge vs smart timing vs just trusting people to build the habit

Format: tweet | Topic: engagement | Image: none | Tags: none
Status: ready

### Day 4

**Post 1 (8:00 AM), Before/after design**
> redesigned the home dashboard 3 times before landing on this. the first version had too much data. the second was too empty. this one shows your wellness score, weekly trend, and quick actions without overwhelming you
>
> sometimes the hardest part is deciding what to leave out

Format: image | Topic: build | Image: home_dashboard.png | Tags: #buildinpublic #iosdev
Status: ready

**Post 2 (12:30 PM), AI tool specific**
> used claude to write the entire statistical analysis module. welchs t-test, pearson correlation, descriptive stats, outlier detection. ~400 lines of swift
>
> reviewed every function, wrote test cases for each one. all passed first try. this would've been a full weekend of work, took about 2 hours
>
> the future of building is knowing what to ask for

Format: tweet | Topic: ai-tool | Image: none | Tags: #vibecoding
Status: ready

**Post 3 (5:30 PM), Vulnerable**
> some days i wonder if anyone actually needs another health app. theres probably 200 of them on the app store already
>
> then i remember that none of them do on-device ML pattern detection with zero cloud servers. and that the doctor prep PDF feature doesnt exist anywhere else ive looked
>
> so i keep building

Format: tweet | Topic: personal | Image: none | Tags: none
Status: ready

### Day 5

**Post 1 (8:00 AM), Privacy angle**
> made a decision on day 1 that shaped everything: health data never leaves the device. no firebase. no analytics on symptoms. no cloud ML
>
> that one rule meant swiftdata instead of a cloud db, coreml instead of openai, and on-device processing for every analysis
>
> privacy isnt a feature you add later. its architecture you choose upfront

Format: tweet | Topic: build | Image: none | Tags: #healthtech #privacyfirst
Status: ready

**Post 2 (12:30 PM), Engagement**
> which of these would make you actually open a health app every day:
>
> A) seeing your wellness score change
> B) getting a "your streak is at risk" notification
> C) discovering a new pattern in your data
> D) medication reminders

Format: tweet (poll) | Topic: engagement | Image: none | Tags: none
Status: ready

**Post 3 (5:30 PM), Weekly recap**
> week 1 sharing the build publicly:
> - showed the symptom logging flow (4 steps, 15 seconds)
> - talked about vibe coding honestly (its great until it isnt)
> - shared the wellness score algorithm breakdown
> - admitted a 2-day bug was a 1-character fix
>
> 5 posts in and it already feels good to not build in silence anymore

Format: tweet | Topic: build | Image: none | Tags: #buildinpublic
Status: ready

### Day 6-7

> Cowork drafts these on Day 4 based on what performed well in Days 1-5. Adjust format and topic mix based on early engagement signals.

---

## Upcoming Queue (Next Week)

> Cowork pre-loads this during Sunday weekly workflow.

| Day | Post 1 Topic | Post 2 Topic | Post 3 Topic | Thread? |
|-----|-------------|-------------|-------------|---------|
| Mon | | | | |
| Tue | | | | |
| Wed | | | | Yes, Template 1 or 4 |
| Thu | | | | |
| Fri | | | | |
| Sat | | | | |
| Sun | | | | |

---

## Queue Rules

1. Never queue more than 7 days ahead: content should stay fresh and reactive
2. Leave 1-2 slots per day empty for spontaneous posts from Keshav
3. If a queued post feels stale by its scheduled day, replace it
4. Weekend posts should be more casual/personal than weekday posts
5. At least 1 post per day should have no hashtags and no image (feels spontaneous)
6. Never queue the same format 3 days in a row
