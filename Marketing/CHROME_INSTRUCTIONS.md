# Chrome Automation Instructions — Step-by-Step

> Exact steps for Claude Chrome to execute the daily marketing workflow.
> One morning session: draft posts, schedule them on X, then handle engagement.

---

## Prerequisites

- [ ] Chrome is open and signed into x.com with Keshav's account
- [ ] Claude Chrome extension is active (pinned)
- [ ] Chrome connector enabled in Claude Desktop settings
- [ ] X Premium active (required for scheduled posts)

---

## The Morning Session

### Step 1: Read the System (No Browser Yet)

```
1. Read SCALING_FRAMEWORK.md → find current phase and today's exact targets
   - How many posts to schedule today
   - How many replies
   - How many likes
   - What's automated vs manual in this phase

2. Read BRAND_EVOLUTION.md → current content themes and pillars

3. Read POST_CATALOG.md → last 7 days
   - What topics were covered
   - What hooks were used
   - What images were attached
   - What formats were used

4. Read VOICE_BIBLE.md → internalize Keshav's voice

5. Read CONTENT_QUEUE.md → check for any pre-loaded drafts
```

**The number of posts, replies, and likes today comes from SCALING_FRAMEWORK.md — not from this file.** If the scaling framework says 1-2 posts today, draft 1-2. If it says 5-6, draft 5-6. Never override the growth targets.

---

### Step 2: Draft Today's Posts

Draft the number of posts specified by SCALING_FRAMEWORK.md for today's phase.

**The Train of Thought Rule:**

Today's posts should feel like scraps from the same person's day. Not a content calendar. Not marketing. Just someone who happens to be building something and thinks out loud online.

The loose thread connecting them might be:
- A problem you're stuck on → the workaround you tried → asking the audience what they'd do
- Something you shipped → a related frustration → a broader reflection on why it matters
- A tool you used → what went wrong with it → what you learned

But some days there's no thread. Some days you post about your ML engine in the morning and your mood at night and they have nothing to do with each other. That's fine. Real people don't theme their days.

**Naturally Mention the App and Its Problems:**

Not every post is about Symptly. But across the week, the app should come up the way it would in real life — as the thing you're working on that gives you both headaches and excitement.

Ways to weave it in naturally:

- As context for a broader point: "been working through this with the wellness scoring in symptly — turns out clamping a score to 0-100 is harder than it sounds when you have 7 weighted inputs fighting each other"
- As a problem you're stuck on: "the flare-up predictor keeps false-alarming on bad sleep alone. need to figure out how to require multiple signals before showing elevated risk. anyone dealt with multi-signal thresholds?"
- As a passing mention: "shipped a small fix to symptly this morning, now back to staring at the onboarding flow"
- As background to a tool discussion: "used claude to rewrite my time series analyzer for the health app im building. took 20 minutes for what wouldve been a full day"

Don't force it. If today's posts are about AI tools or personal founder stuff, the app doesn't need to appear at all. It should come up maybe 60-70% of days, not 100%.

**Anti-Cannibalization:**
- Never the exact same topic twice in a day
- If posts share a theme, each needs a different angle (technical → emotional → engagement)
- If a topic appeared 3+ times in the last 10 days, switch
- Never the same content pillar 3 days running

**Emotional Arc (when posting 3+ per day):**
- Earlier posts: reflective, technical, or observational
- Middle posts: practical, useful, or a short story
- Later posts: vulnerable, personal, or a question

**Apply to every draft:**
- "Quantify Everything" — specific numbers or honest estimates
- "Vulnerability First" — at least 1 post per day shows uncertainty
- VOICE_BIBLE.md — micro-mistakes in casual posts, natural voice
- HASHTAG_STRATEGY.md — max 2 tags, none on casual posts
- IMAGE_GUIDE.md — attach image to max 1-2 posts, check last-used tracker

Save drafts to CONTENT_QUEUE.md with scheduled times.

**Example — Phase 1 day (1-2 posts, all manual):**

> post 1 (afternoon): "3 months into building a health tracking app solo. using claude for maybe 80% of the code. the other 20% is me debugging what claude got wrong. today's problem: the severity slider snaps to integers but the ML engine wants decimals. small stuff but it adds up"

Just one post. That's it. Phase 1 is about showing up consistently, not flooding the feed.

**Example — Phase 3 day (5-6 scheduled + 1-3 manual):**

> 8:30 AM: "realized the trigger analysis was using simple averages instead of bayesian inference. switched it over yesterday — now instead of 'stress appeared 12 times' it says 'when stress is present, severity is 2.3 points higher on average.' way more useful for the user"

> 11:00 AM: "honest question for anyone building consumer health products: how do you handle the line between 'helpful insight' and 'medical advice'? symptly says things like 'elevated flare-up risk' but i dont want someone to mistake that for a diagnosis. where do you draw it"

> 1:30 PM: "my favorite feature in symptly that nobody will care about: the test harness generates synthetic patients with configurable severity trends and validates every ML engine against them. 25 tests, all automated. users will never see it. but its the reason the wellness score doesn't return 104/100 anymore"

> 4:30 PM: "stack update — zero third party dependencies. swiftui, swiftdata, coreml, healthkit, storekit 2, weatherkit. all built into ios 17. total cost of my dependency management: $0"

> 8:00 PM: "some days the hardest part of building alone is having nobody to show things to. i shipped the doctor prep PDF today and it generates a full 6-month symptom summary with charts and trigger analysis. its maybe the most useful thing ive built. and i just... closed my laptop and went to make dinner"

Five posts. Connected loosely (ML, health product questions, technical pride, loneliness of solo building) but each stands alone. App comes up naturally in 4 of 5. The evening post is the most vulnerable.

---

### Step 3: Open Chrome — Schedule All Posts

```
1. Navigate to https://x.com
   - Confirm logged into Keshav's account

2. For each post:
   a. Click "Post" button → compose modal opens
   b. Type post text EXACTLY as drafted (preserve micro-mistakes, do NOT let spellcheck modify)
   c. If image specified: click image icon → navigate to Marketing/images/ → select file → wait for upload
   d. Click calendar/clock icon in compose toolbar → "Schedule" panel appears
   e. Set DATE to today
   f. Set TIME to the scheduled time from CONTENT_QUEUE.md
   g. Confirm timezone matches Keshav's local timezone
   h. Click "Confirm" → blue button changes to "Schedule" → click "Schedule"
   i. Confirmation: "Your post will be sent on [date] at [time]"

3. For threads:
   a. Open compose
   b. Type tweet 1
   c. Click "+" button → type tweet 2 → repeat for all tweets
   d. Attach image to specified tweet (click into that tweet first)
   e. Click calendar/clock → schedule → all tweets post together

4. For polls:
   a. Open compose
   b. Type question text
   c. Click bar chart icon → fill in 2-4 options → set 24h duration
   d. Schedule as above

5. After all posts scheduled:
   - Navigate to https://x.com/compose/scheduled
   - Verify all posts queued with correct times
   - Verify times are 2+ hours apart
   - Verify emotional arc reads naturally if someone saw them all
   - Update CONTENT_QUEUE.md → mark all "scheduled"
```

**Time spacing — pull from SCALING_FRAMEWORK.md targets:**

| If scheduling... | Spread across |
|-----------------|---------------|
| 1-2 posts | Afternoon + evening (don't cluster in the morning) |
| 3-4 posts | Morning, early afternoon, late afternoon/evening |
| 5-6 posts | Morning, late morning, early afternoon, late afternoon, evening |
| 7+ posts | Every 2 hours starting 8 AM through 9 PM |

Vary by ±15 min daily. Never post at the exact same minute two days in a row.

---

### Step 4: Engagement

Check SCALING_FRAMEWORK.md for today's reply and like targets. If current phase says "manual only" for engagement, skip this — Keshav handles it himself.

**Replying (when phase allows AI-assisted replies):**

```
1. Read COMPETITOR_ACCOUNTS.md → HIGH priority accounts
2. Visit each account's profile
3. Scan their last 3-5 posts (24-48 hours old)
4. Draft replies per COMMENTS_PLAYBOOK.md strategies
   - Match the post type to the right reply approach
   - Apply humanization + micro-imperfections
   - Weave in Keshav's perspective naturally
     (e.g., replying to a build-in-public post: "been hitting the same wall
      with my health app — the cold start problem is real")
5. Save drafts to COMMENTS_PLAYBOOK.md "Pending Replies"
6. Notify Keshav for review
7. Post approved replies — 2-5 min randomized gaps, max 6 per 30-min window
```

**Likes:**

```
- Like 2-3 posts per target account engaged with
- 10-30 sec gaps between likes
- Stay within daily target from SCALING_FRAMEWORK.md
```

**Follows:**

```
- Only follow accounts you genuinely want to see
- Max per SCALING_FRAMEWORK.md daily targets
- 1-3 min gaps between follows
```

**Notifications check:**

```
- Navigate to https://x.com/notifications
- Report to Cowork: new followers, replies to our posts, mentions
```

---

### Step 5: Wrap Up

```
1. Log all scheduled posts → POST_CATALOG.md
2. Move posted replies → COMMENTS_PLAYBOOK.md "Posted Today"
3. Update CONTENT_QUEUE.md statuses
4. Done. Close session.
```

---

## Keshav's Manual Block (15-30 min, whenever)

Separate from the morning session. On his phone.

```
1. Check replies to scheduled posts → respond personally
2. Post 1 spontaneous tweet — whatever is actually on his mind
   (this is what separates a real account from a scheduled one)
3. Send DMs per DM_PLAYBOOK.md targets from SCALING_FRAMEWORK.md
4. Scroll feed 5-10 min, like/reply to things that genuinely interest him
```

---

## Evening Check (Phase 3+)

```
1. Verify scheduled posts went out → check profile
2. If any failed: repost or note for tomorrow
3. If SCALING_FRAMEWORK.md allows a night post:
   - Post directly (not scheduled) — this should feel unplanned
   - Most casual/vulnerable post of the day
4. Note high/low performers for weekly ANALYTICS_TRACKER.md
```

---

## Troubleshooting

| Problem | Solution |
|---------|----------|
| Scheduler icon missing | X Premium may not be active |
| "Something went wrong" | Wait 60 sec, retry once. If fails, post live instead |
| Scheduled post didn't go out | Check x.com/compose/scheduled — reschedule or post live |
| Rate limited | Stop 15 min. Resume at 50% volume |
| Session expired | Stop everything. Notify Keshav. Do not attempt login |
| Image upload fails | Schedule without image. Note in POST_CATALOG.md |

---

## Security Rules

1. Never store or transmit Keshav's password — Chrome uses existing session
2. Never access DM content without explicit permission
3. Never change account settings without explicit instruction
4. Never delete posts unless Keshav requests it
5. Never block or mute without approval
6. If session expires, stop. Notify. Wait.
7. Never post replies without Keshav's approval — scheduled posts are pre-approved via CONTENT_QUEUE.md, replies always need review
