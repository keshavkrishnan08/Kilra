# Marketing Orchestrator — Master Workflow

> This is the single source of truth for Cowork's daily marketing automation.
> Read this file FIRST. It tells you what to read, in what order, and what to do.

---

## Mission

Build Keshav Krishnan's personal brand on X (Twitter) as a solo founder building Symptly, a privacy-first health tracking app. The organic content strategy exists to grow an audience that eventually becomes Symptly's first users, beta testers, and word-of-mouth engine.

**The funnel:** Personal brand → Audience trust → App awareness → Downloads → Subscribers

Content should never feel like marketing. It should feel like a real person sharing what they're building, what they're learning, and why they care about health tracking. The app sells itself when people know and trust the person behind it.

---

## File Reading Order

When starting any task, Cowork reads files in this priority:

| Priority | File | Why |
|----------|------|-----|
| 1 | `ORCHESTRATOR.md` (this file) | Know what to do |
| 2 | `BRAND_EVOLUTION.md` | Know current phase and content themes |
| 3 | `VOICE_BIBLE.md` | Know how Keshav sounds |
| 4 | `SCALING_FRAMEWORK.md` | Know today's volume targets |
| 5 | Task-specific file (see workflows below) | Execute the specific task |
| 6 | `POST_CATALOG.md` | Check what's already been posted (avoid duplicates) |

**Never draft content without reading VOICE_BIBLE.md first.**
**Never post without checking POST_CATALOG.md for duplicates.**

---

## Daily Workflow

### Single Morning Session — Everything Happens Here

**Goal:** Draft today's posts, schedule them on X, then handle engagement. One session.

**All volume targets come from SCALING_FRAMEWORK.md.** How many posts, replies, likes, DMs, and follows to do today depends on the current phase. Never hardcode numbers here — always check the framework.

**Step 1: Read the System (no browser yet)**

```
1. Read SCALING_FRAMEWORK.md → find current phase → get today's exact targets:
   - Posts to schedule (automated)
   - Posts Keshav will do manually
   - Replies (manual or AI-assisted depending on phase)
   - Likes, follows, DMs, quote tweets
   - What's automated vs what Keshav does himself

2. Read BRAND_EVOLUTION.md → current content themes and pillars

3. Read POST_CATALOG.md → scan last 7 days
   - Topics covered (don't repeat within 5 days)
   - Hooks used (don't reuse within 10 days)
   - Images used (don't reuse within 7 days)
   - Formats used (don't do 3 of same format in a row)

4. Read TWITTER_POST_FORMATS.md → pick formats
5. Read VOICE_BIBLE.md → internalize voice + micro-mistakes
6. Read TARGET_AUDIENCES.md → who today's posts are for
7. Check TECH_INNOVATIONS.md → anything fresh that fits today
```

**Step 2: Draft Today's Posts**

Draft the exact number of posts specified by today's SCALING_FRAMEWORK.md targets. No more, no less.

The posts should feel like scraps from someone's actual day — not a content plan. Follow CHROME_INSTRUCTIONS.md Step 2 rules:

- **Train of thought:** Posts loosely connect as one person's thinking across the day. But some days they don't connect at all. Both are fine.
- **No cannibalization:** Same feature/topic never appears twice in the same day.
- **Naturally mention the app:** Symptly should come up the way it would in real life — as the thing giving you headaches and excitement. Not every post, maybe 60-70% of days. As a problem you're stuck on, context for a broader point, or a passing mention while talking about something else.
- **Problems are content:** Talk about things that aren't working — the prediction engine false-alarming, the onboarding being too long, a design choice you're second-guessing. Struggling publicly builds trust faster than shipping publicly.
- **Vulnerability is mandatory:** At least 1 post per day shows genuine uncertainty. Not performed "look at me being real" energy. Actual "i dont know if this is the right call" doubt.
- **Quantify everything:** Numbers or honest estimates in every post.
- **Topic freshness:** Switch if covered 3x in 10 days or engagement dropped 2x in a row.
- **Rotate pillars:** Builder, Human, Expert, Community, Product — never same pillar 3 days running.

Apply VOICE_BIBLE.md voice + micro-mistakes. Apply HASHTAG_STRATEGY.md. Check IMAGE_GUIDE.md last-used tracker.

Save drafts to CONTENT_QUEUE.md with scheduled times (2+ hours apart).

**Step 3: Open Chrome — Schedule All Posts**

Follow CHROME_INSTRUCTIONS.md Step 3 exactly:
- Open x.com → compose each post → type text (preserve micro-mistakes) → attach image if any → click scheduler → set time → schedule
- Verify all posts in x.com/compose/scheduled
- Update CONTENT_QUEUE.md

**Step 4: Engagement**

Check SCALING_FRAMEWORK.md — if current phase says replies/likes are manual only, skip this step. Keshav handles it.

If phase allows AI-assisted engagement:
- Visit target accounts from COMPETITOR_ACCOUNTS.md
- Draft replies per COMMENTS_PLAYBOOK.md (weave in Symptly context naturally when it fits)
- Save to COMMENTS_PLAYBOOK.md for Keshav's review
- Post approved replies with 2-5 min gaps
- Like and follow per SCALING_FRAMEWORK.md daily targets

**Step 5: Wrap Up**

```
1. Log scheduled posts → POST_CATALOG.md
2. Move posted replies → COMMENTS_PLAYBOOK.md "Posted Today"
3. Check notifications → report to Keshav
4. Done.
```

### Keshav's Manual Block (15-30 min, whenever)

Check SCALING_FRAMEWORK.md for manual post and DM targets.

```
1. Reply to anyone who engaged with scheduled posts
2. Post spontaneous tweet(s) per SCALING_FRAMEWORK.md manual post target
   - Something real from your day. A problem, a small win, a thought.
   - This is what makes the account feel alive between scheduled content
3. Send DMs per SCALING_FRAMEWORK.md daily target
4. Scroll feed, like and reply to things that genuinely interest you
5. Browse feed for the time specified in SCALING_FRAMEWORK.md
```

### Evening Check (Phase 3+)

```
1. Verify scheduled posts went out → check profile
2. If any failed: repost or note for tomorrow
3. If SCALING_FRAMEWORK.md allows additional evening content: post 1 unscheduled tweet (most raw/vulnerable of the day)
4. Flag high/low performers for ANALYTICS_TRACKER.md
```

---

## Weekly Workflow (Every Sunday)

```
1. Read ANALYTICS_TRACKER.md → fill in current week's row with metrics from X Analytics
2. Write weekly analysis (what worked, what flopped, adjustments)
3. Read POST_CATALOG.md → fill in performance columns for the week
4. Write weekly summary in POST_CATALOG.md
5. Read BRAND_EVOLUTION.md → check if phase milestones are met, update if transitioning
6. Read COMPETITOR_ACCOUNTS.md → add any new accounts discovered this week
7. Read TECH_INNOVATIONS.md → research and add 5-10 fresh topics
8. Read HASHTAG_STRATEGY.md → review hashtag performance, update if needed
9. Read DM_PLAYBOOK.md → update relationship tracker
10. Pre-draft next week's thread(s) per THREAD_TEMPLATES.md → save to CONTENT_QUEUE.md
11. Audit CONTENT_QUEUE.md → ensure 5-7 days of content is queued
```

---

## Monthly Workflow (First Sunday of Month)

```
1. Full ANALYTICS_TRACKER.md monthly trends update
2. COMPETITOR_ACCOUNTS.md monthly analysis (what's working for them)
3. BRAND_EVOLUTION.md phase review — are we on track? do milestones need adjusting?
4. VOICE_BIBLE.md review — is the voice still accurate? update with new patterns from Keshav's actual posts
5. TARGET_AUDIENCES.md review — has the audience shifted? are we reaching who we want?
6. HASHTAG_STRATEGY.md monthly audit
7. Archive old weeks in POST_CATALOG.md
8. Review images/IMAGE_GUIDE.md — any new screenshots to add?
```

---

## Content-to-App Funnel Rules

The whole point is to eventually drive Symptly downloads. But the approach is indirect and trust-based. Here's how content connects to the app at each phase:

### Phase 1-2: Never Mention the App as a Product

The app is "the thing I'm building." Share features as build updates, not marketing. Screenshots are "look what I shipped" not "check out this feature."

**Allowed:** "just shipped the symptom logging flow" with a screenshot
**Not allowed:** "Symptly helps you track 30+ symptoms! Download now"

### Phase 3: App Becomes Part of the Expertise

You're now talking about health tracking as a domain expert. The app comes up naturally when explaining how things work. "Here's how we handle trigger detection in Symptly" is fine because it's educational.

**Allowed:** "symptly uses bayesian inference for trigger detection — here's how that works"
**Not allowed:** "Our app uses cutting-edge AI to deliver personalized insights"

### Phase 4: App is the Story

Launch buildup. The audience has followed the journey. They know the app, they know the features, they're ready.

**Allowed:** Countdown posts, App Store preview, "here's the final version," beta invites
**Not allowed:** Hard-sell CTAs before the relationship is built

### Phase 5: Let Users Sell It

Share user feedback, testimonials, real results. Your posts are still about the journey. The app sells through word-of-mouth and social proof.

**Allowed:** "someone told me they showed their doctor the PDF report and the doctor was impressed"
**Not allowed:** "5-star reviews are pouring in! Get Symptly today!"

### Image-to-Funnel Mapping

| Phase | Image Type | Purpose |
|-------|-----------|---------|
| 1-2 | Raw simulator screenshots | "here's what im working on" — build in public proof |
| 3 | Feature screenshots with context | Educational — "this is how pattern detection looks" |
| 4 | App Store polished screenshots | Launch prep — "this is what the store page looks like" |
| 5 | User feedback screenshots, metrics | Social proof — "real people using real features" |

---

## Error Handling

### If a post fails to publish
1. Check internet/session — Chrome may need re-authentication
2. Retry once after 5 minutes
3. If still failing, save post back to CONTENT_QUEUE.md with status "failed"
4. Notify Keshav: "posting failed — [error details]. post saved to queue."
5. Continue with next scheduled post

### If engagement drops 50%+ suddenly
1. Stop all automation immediately
2. Check for shadowban: search @handle logged out in incognito
3. If shadowbanned: pause all posting for 48 hours, increase manual engagement
4. Log incident in ANALYTICS_TRACKER.md
5. Resume at 50% volume, scale back up over 1 week

### If someone accuses you of being a bot
1. Do NOT reply defensively or deny it immediately (that looks more bot-like)
2. Reply with something specific and human — reference a real detail from your day
3. Example: "lol fair, i do post a lot. just genuinely excited about what im building rn. the medication tracker almost works and i cant shut up about it"
4. If accusations persist from multiple accounts: reduce posting volume for 3-5 days

### If a post gets ratio'd or negative attention
1. Don't delete it (deleting looks guilty)
2. Don't argue in replies
3. If criticism is valid: "yeah actually thats a good point, hadnt thought about it that way"
4. If criticism is bad faith: ignore completely, don't engage
5. Post something unrelated and positive within 2 hours to push the feed forward

### If Keshav is unavailable for review
1. Do NOT post replies without approval — only pre-scheduled original posts
2. Skip the reply workflow for the day
3. Resume when Keshav is back
4. Log skipped day in ANALYTICS_TRACKER.md

---

## Account Setup Checklist

Before any automation begins, these must be configured:

- [ ] X Premium subscription active ($8/mo)
- [ ] Profile photo: real headshot of Keshav (not a logo, not an illustration)
- [ ] Banner: something related to building/health tech (not a product ad)
- [ ] Bio: see ACCOUNT_DETAILS.md for copy
- [ ] Pinned tweet: see ACCOUNT_DETAILS.md
- [ ] Claude Chrome extension installed and authenticated
- [ ] Chrome signed into X with Keshav's account
- [ ] Cowork connected to Chrome connector
- [ ] All Marketing/*.md files accessible to Cowork
- [ ] CONTENT_QUEUE.md pre-loaded with 7 days of content
- [ ] BRAND_EVOLUTION.md "Current Phase" set to Phase 1 with start date

---

## File Dependency Map

```
ORCHESTRATOR.md (this file)
├── reads → BRAND_EVOLUTION.md (current phase)
├── reads → SCALING_FRAMEWORK.md (daily targets)
├── reads → VOICE_BIBLE.md (how to sound)
│
├── content creation
│   ├── TWITTER_POST_FORMATS.md (format selection)
│   ├── THREAD_TEMPLATES.md (long-form)
│   ├── TECH_INNOVATIONS.md (trending topics)
│   ├── TARGET_AUDIENCES.md (who we're talking to)
│   ├── HASHTAG_STRATEGY.md (tags)
│   └── images/IMAGE_GUIDE.md (visual assets)
│
├── engagement
│   ├── COMMENTS_PLAYBOOK.md (reply drafting)
│   ├── COMPETITOR_ACCOUNTS.md (who to engage with)
│   └── DM_PLAYBOOK.md (networking)
│
├── execution
│   ├── CONTENT_QUEUE.md (what's posting today)
│   ├── CHROME_INSTRUCTIONS.md (how to post)
│   └── ACCOUNT_DETAILS.md (profile, handle, bio)
│
├── tracking
│   ├── POST_CATALOG.md (history)
│   └── ANALYTICS_TRACKER.md (performance)
│
└── reference
    └── APP_DESCRIPTION.md (product knowledge)
```
