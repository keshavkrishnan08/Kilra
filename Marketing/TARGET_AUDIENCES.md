# Target Audiences: Who We're Talking To

> Cowork references this before drafting content. Different audiences respond to different hooks, language, and proof points. Know who you're writing for.

---

## Primary Audiences

### 1. Indie Builders & Vibe Coders

**Who:** Solo developers, indie hackers, people building side projects or startups with AI tools. Ages 20-35 mostly. Active on tech Twitter. Many building in public.

**Where they hang out:** Twitter, Indie Hackers, Hacker News, Reddit (r/SideProject, r/indiehackers), Discord communities

**What they care about:**
- What tools you're using and whether they actually work
- Real metrics, not vanity numbers
- The unglamorous parts of shipping: bugs, decisions, late nights
- Stack choices and why you made them
- How fast you're moving and what's slowing you down

**What makes them follow you:**
- You're building something real, not just talking about building
- You share specific technical details without being condescending
- You're honest about failures and wrong turns
- You respond when they comment

**Example post that hooks them:**

> built my entire ML pipeline for symptom prediction today. bayesian trigger detection, time series decomposition, the whole thing. all on-device, no cloud
>
> used claude for the statistical analysis functions and honestly it handled welchs t-test better than i would have from scratch. took maybe 2 hours for what wouldve been a full weekend

**What to avoid:** Don't talk about "users" abstractly. Don't use marketing language. Don't pretend everything is going great when it isn't.

---

### 2. Chronic Illness & Health-Conscious Community

**Who:** People managing chronic conditions (migraines, IBS, anxiety, chronic fatigue, autoimmune conditions). Also people who track their health proactively. Ages 25-50. Lots of women. Lots of invisible illness.

**Where they hang out:** Twitter health communities, Reddit (r/ChronicPain, r/migraine, r/IBS), Facebook groups, Instagram wellness space, TikTok health creators

**What they care about:**
- Feeling heard and believed about their symptoms
- Finding patterns in what triggers their bad days
- Being prepared for doctor appointments (this is huge)
- Privacy: they dont want their health data sold
- Ease of use: they're often logging symptoms while feeling terrible

**What makes them follow you:**
- You understand the emotional side, not just the technical side
- You built features that solve their actual frustrations
- You prioritize privacy and explain why clearly
- You dont talk down to them or oversimplify their experience

**Example post that hooks them:**

> the most common thing i hear from people with chronic conditions: "i cant remember what i told my doctor last time"
>
> thats why symptly generates a doctor prep PDF with your full symptom history, triggers, medication adherence, and suggested questions. you walk in prepared instead of trying to remember through brain fog

**What to avoid:** Never say "just track your symptoms and you'll feel better." Never promise medical outcomes. Never be dismissive about how hard chronic illness is. Never use the word "journey."

---

### 3. AI & Machine Learning Enthusiasts

**Who:** Developers and tech enthusiasts interested in practical ML applications. Not just researchers, people who want to see ML doing real things for real people. Ages 22-40.

**Where they hang out:** Twitter (ML Twitter, AI Twitter), Reddit (r/MachineLearning, r/LocalLLaMA), Hacker News, YouTube (technical channels), Substack

**What they care about:**
- How you're actually implementing ML, not just using APIs
- On-device vs cloud tradeoffs
- Real accuracy numbers and validation methods
- Interesting problem domains (health is interesting)
- Whether the ML actually improves the product or is just hype

**What makes them follow you:**
- You share real technical details about your ML pipeline
- You're transparent about accuracy, limitations, edge cases
- You built something that actually uses ML meaningfully
- You can explain complex concepts without dumbing them down too much

**Example post that hooks them:**

> my symptom prediction engine uses 7 weighted features to forecast severity. historical baseline (25%), recent trend (25%), day-of-week affinity (12%), active triggers (13%), mood context (13%), seasonal pattern (12%), healthkit data (10%)
>
> the interesting part is the onboarding bias that fades as real data accumulates. starts strong at ~60 entries it's basically gone. prevents cold start from ruining predictions

**What to avoid:** Don't oversell your ML as "AI-powered" without substance. Don't claim accuracy you can't prove. Don't handwave the technical details for this audience, they'll call you on it.

---

### 4. Health Tech Professionals

**Who:** People working in digital health, healthtech startups, medical professionals interested in technology. Ages 30-50. More LinkedIn than Twitter but crossover exists.

**Where they hang out:** Twitter (healthtech circles), LinkedIn, conferences (HLTH, HIMSS), Substack health newsletters

**What they care about:**
- Regulatory compliance (HIPAA, health data privacy)
- Clinical validation and evidence
- Patient engagement and adherence
- Integration with existing health ecosystems (HealthKit, EHR)
- Business model viability in health

**What makes them follow you:**
- You're building something that addresses a real clinical gap
- You take privacy seriously and can articulate why
- You understand the difference between wellness and medical
- You're thoughtful about disclaimers and scope

**Example post that hooks them:**

> symptly reads sleep, heart rate, steps, and exercise from apple health. all read-only, all on-device. we never upload health data anywhere
>
> the correlation engine needs at least 5 days of data and a 0.5 severity difference before surfacing any findings. didn't want to show spurious correlations and have someone change their behavior over noise

**What to avoid:** Don't claim to diagnose or treat anything. Don't ignore regulatory reality. Don't pretend you're building an EHR or clinical tool when you're building a wellness tracker.

---

## Secondary Audiences

### 5. App Store Browsers

**Who:** General consumers who find you through the App Store, not Twitter. They need to understand the value proposition in seconds.

**Relevance to Twitter:** Low direct overlap, but your Twitter presence builds the social proof (reviews, downloads, word-of-mouth) that makes App Store browsers convert.

**Key message for this audience:** "Track symptoms, find patterns, prepare for doctor visits. Your data stays on your phone."

---

### 6. Potential Collaborators & Investors

**Who:** Other founders, angel investors, health-focused VCs, accelerator scouts. They're lurking on Twitter watching your build-in-public content.

**What hooks them:** Consistency, clear thinking, technical depth, authentic metrics (even small ones), and a founder who can articulate the problem clearly.

**You don't post for them directly.** They find you through your normal content. The best founder-audience post is one that makes an investor think "this person really understands the problem" without ever mentioning fundraising.

---

## Audience Mix by Brand Phase

| Phase (from BRAND_EVOLUTION.md) | Primary Audience | Secondary |
|--------------------------------|-----------------|-----------|
| Phase 1: The Builder | Indie Builders & Vibe Coders | ML Enthusiasts |
| Phase 2: The Journey | Indie Builders, ML Enthusiasts | Chronic Illness Community |
| Phase 3: The Expert | Chronic Illness Community, Health Tech | Indie Builders |
| Phase 4: Launch Build | All audiences equally | App Store Browsers (indirect) |
| Phase 5: Launch & Growth | Chronic Illness Community | All others |

---

## Content Customization by Audience

When Cowork drafts a post, check: who is this for?

| If audience is... | Lead with... | Proof is... | Tone is... |
|------------------|-------------|------------|-----------|
| Indie Builders | What you built, how, with what tool | Screenshots, code decisions, metrics | Casual, technical, self-deprecating |
| Chronic Illness | The problem, the frustration, the empathy | User quotes, feature demos, privacy assurances | Warm, genuine, careful |
| ML Enthusiasts | The algorithm, the data, the approach | Accuracy numbers, architecture choices, tradeoffs | Technical, honest about limitations |
| Health Tech | The gap in care, the approach, the compliance | Privacy architecture, clinical thinking, disclaimers | Professional but human |
