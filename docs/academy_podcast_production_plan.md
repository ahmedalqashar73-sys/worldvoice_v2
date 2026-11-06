# 2026-11-06 approved WorldVoice English long-form podcast plan (supersedes old 5-minute plan for B1–C2)

**The sections below this heading are historical 15-episode, five-minute planning notes. They are NOT the current B1/B2/C1/C2 production requirement. Do not replace original source recordings with short audio, synthetic lengthening, or old drafts.**

## Approved delivery
- English only in this phase; A1, A2, rooms, live, messages and economy are out of scope.
- **30 independent original-source recordings per level** for **B1, B2, C1 and C2**, **120 total**. Every recording must be at least **10 minutes**. Genuine recordings lasting 20 minutes, 30 minutes, one hour or more are acceptable. Do not pad short audio.
- Final user experience: native streamable human audio; English transcript from the same original recording/source; Arabic translation beneath the English; source credit and original episode link; play/pause, seek, speed and next/previous.
- B1 sources: original 30-minute VOA Learning English Podcast series, March 2–31, 2025, listed in `assets/podcasts/voa_english_b1_long_form.json`. **30 official original audio-derived draft transcripts** were produced into `assets/podcasts/voa_english_b1_transcripts.json`; inspect actual availability and editorial status before calling them finished.
- B2, C1, C2 sources: 90 distinct original long-form NASA Houston We Have a Podcast recordings from NASA's official RSS with separate source pages, selected in `assets/podcasts/nasa_advanced_long_form.json` (30 per level). NASA does NOT CEFR-rate these: the initial selection by topic is provisional and needs pedagogical review.
- Original NASA pages carry English transcripts; the `nasa_advanced_transcripts.yml` workflow prepares **Arabic machine-draft translations in sequence B2 → C1 → C2** and writes per-level assets only after all 30 match their source recording and page. A missing source or invalid transcript fails closed.
- Never label machine-draft translation as reviewed. For B1, word-level cue candidates are derived from the genuine audio but need listening review. For B2–C2, **do not show automatic timing or fake highlighting before real audio alignment**; present English and Arabic as a parallel transcript instead.
- Media and rights: VOA original public-domain content and NASA government media have source credit and exceptions. NASA official RSS media may include copyrighted third-party music or identifiable voices. For commercial promotional or reuse purposes, review applicable rights and do not imply NASA/VOA endorsement. These links are streamed, not bundled.
- No paid source subscriptions or media purchases were approved.
- Keep all commits exclusively on repository `ahmedalqashar73-sys/worldvoice_v2`, branch `main`. Test with the Academy Podcast validation workflow. Do not claim a handset `flutter run` was executed unless it actually was.

---

# WorldVoice Academy — Podcast editorial production plan

Status: **production plan only**. No audio is considered published or ready to listen to until a rights-cleared, verified MP3 exists. Do not expose entries in the user-facing Podcast tab as playable episodes before audio QA.

## Approved editorial format
- Six CEFR levels in order: A1, A2, B1, B2, C1, C2.
- **15 self-contained episodes per level**: 90 total, about five minutes each (450 minutes / 7.5 hours total). Topics are independent; learners may listen in any sequence.
- Every episode features the **same two adult human voices** throughout the full program: one male host and one female host, commissioned and licensed to WorldVoice. Do not switch performers between episodes. Use human speech, not TTS, unless explicitly approved later.
- Natural spontaneous-sounding conversation, not a stiff alternating sentence exercise: brief reactions, follow-up questions, occasional interruptions where intelligible, natural pauses and warmth. Avoid third-party narration or a third character unless separately approved.
- Host roles stay fixed across all levels; A1–A2 clear, gentle pacing and accessible pronunciation; B1–B2 progressively more spontaneous exchange; C1–C2 nuanced discussion with precise vocabulary. Use human editorial review for CEFR appropriateness.
- One recording per episode: **target 4:45–5:15** (five minutes). Final duration must be measured from the produced audio, never inferred from scripts.
- Publish English transcript checked against actual recording, optional Arabic translation, individual speaker labels, 8–12 vocabulary items and 5 comprehension questions.
- Keep independent level filter, pause/replay, speed options, offline caching and original-audio credit where applicable. Store transcripts and audio in distinct assets for maintainability.
- Rights: written voice-talent release/contract covering in-app commercial distribution, offline caching and YouTube; no assumption that music, photos or third-party clips share those rights. Retain proof of the contract. Do not use other people's voices for cloning without explicit authorization.

## Level-based language targets
| Level | Speech & teaching target | Approximate spoken word count for five minutes |
|---|---|---:|
| A1 | Short everyday questions and clear replies, practical repetition, slower natural pace | 420–500 |
| A2 | Everyday situations, past/future plans, reasons and preferences | 470–540 |
| B1 | Personal narratives, comparisons, explanations and problem-solving | 530–600 |
| B2 | Natural exchanges, supported opinions, nuanced transitions and light disagreements | 590–680 |
| C1 | Extended arguments, idiomatic phrasing, qualification and precision | 650–750 |
| C2 | Complex ideas, subtle distinctions, counterarguments and careful synthesis | 680–790 |

> Counts are editorial guidelines, not substitutes for timing the final recording. Keep both voices intelligible at every level.

## Episode slate

### A1 · 15 independent five-minute episodes

01. **Meeting a New Friend** — `en-a1-pod-001`
02. **A Morning at Home** — `en-a1-pod-002`
03. **At the Coffee Shop** — `en-a1-pod-003`
04. **Where Is the Bus Stop?** — `en-a1-pod-004`
05. **My Family and Yours** — `en-a1-pod-005`
06. **What's the Weather Like?** — `en-a1-pod-006`
07. **Choosing a Birthday Gift** — `en-a1-pod-007`
08. **Food We Love** — `en-a1-pod-008`
09. **My Weekend Plans** — `en-a1-pod-009`
10. **A Visit to the Market** — `en-a1-pod-010`
11. **Finding a Classroom** — `en-a1-pod-011`
12. **A New Neighbor** — `en-a1-pod-012`
13. **Favorite Sports** — `en-a1-pod-013`
14. **Talking About Our Jobs** — `en-a1-pod-014`
15. **A Nice Day at the Park** — `en-a1-pod-015`

### A2 · 15 independent five-minute episodes

01. **Planning a Weekend Trip** — `en-a2-pod-001`
02. **Cooking Together** — `en-a2-pod-002`
03. **The Train Is Late** — `en-a2-pod-003`
04. **A Surprise Invitation** — `en-a2-pod-004`
05. **Choosing a New Phone** — `en-a2-pod-005`
06. **A Busy Day at Work** — `en-a2-pod-006`
07. **Learning to Drive** — `en-a2-pod-007`
08. **A Visit to the Doctor** — `en-a2-pod-008`
09. **Helping a Friend Move** — `en-a2-pod-009`
10. **What Should We Watch?** — `en-a2-pod-010`
11. **Shopping on a Budget** — `en-a2-pod-011`
12. **A Day at the Museum** — `en-a2-pod-012`
13. **A Small Travel Mistake** — `en-a2-pod-013`
14. **Our Favorite Traditions** — `en-a2-pod-014`
15. **Organizing a Study Group** — `en-a2-pod-015`

### B1 · 15 independent five-minute episodes

01. **My First Day in a New City** — `en-b1-pod-001`
02. **Working from Home** — `en-b1-pod-002`
03. **A Trip That Went Wrong** — `en-b1-pod-003`
04. **Should We Spend Less?** — `en-b1-pod-004`
05. **How We Learn Languages** — `en-b1-pod-005`
06. **Making Friends Abroad** — `en-b1-pod-006`
07. **Planning a Community Event** — `en-b1-pod-007`
08. **Changing a Daily Habit** — `en-b1-pod-008`
09. **Why We Love Stories** — `en-b1-pod-009`
10. **A Difficult Conversation** — `en-b1-pod-010`
11. **Volunteering on Saturday** — `en-b1-pod-011`
12. **Choosing the Right Career** — `en-b1-pod-012`
13. **A Social Media Break** — `en-b1-pod-013`
14. **Dealing with a Delay** — `en-b1-pod-014`
15. **Our City in Ten Years** — `en-b1-pod-015`

### B2 · 15 independent five-minute episodes

01. **Is Remote Work Better?** — `en-b2-pod-001`
02. **Travel and Local Culture** — `en-b2-pod-002`
03. **What Makes a Good Teacher?** — `en-b2-pod-003`
04. **Technology and Personal Privacy** — `en-b2-pod-004`
05. **A More Sustainable Lifestyle** — `en-b2-pod-005`
06. **Should Cities Limit Cars?** — `en-b2-pod-006`
07. **Why People Change Careers** — `en-b2-pod-007`
08. **Can Social Media Build Community?** — `en-b2-pod-008`
09. **The Value of Creative Hobbies** — `en-b2-pod-009`
10. **Saving Money Without Missing Life** — `en-b2-pod-010`
11. **Learning from Failure** — `en-b2-pod-011`
12. **What Makes News Trustworthy?** — `en-b2-pod-012`
13. **The Challenge of Teamwork** — `en-b2-pod-013`
14. **Food Traditions in a Global World** — `en-b2-pod-014`
15. **How AI Changes Everyday Work** — `en-b2-pod-015`

### C1 · 15 independent five-minute episodes

01. **Language and Identity** — `en-c1-pod-001`
02. **Whose History Gets Told?** — `en-c1-pod-002`
03. **When Algorithms Make Choices** — `en-c1-pod-003`
04. **The Future of Public Spaces** — `en-c1-pod-004`
05. **Privacy Versus Convenience** — `en-c1-pod-005`
06. **How to Talk About Uncertainty** — `en-c1-pod-006`
07. **The Ethics of Travel** — `en-c1-pod-007`
08. **What Counts as Meaningful Work?** — `en-c1-pod-008`
09. **Can Art Bring Communities Together?** — `en-c1-pod-009`
10. **The Problem with Easy Answers** — `en-c1-pod-010`
11. **Education and Equal Opportunity** — `en-c1-pod-011`
12. **Trust in Public Information** — `en-c1-pod-012`
13. **Community Responses to Climate Change** — `en-c1-pod-013`
14. **Who Should Be Accountable?** — `en-c1-pod-014`
15. **Why Listening Changes Arguments** — `en-c1-pod-015`

### C2 · 15 independent five-minute episodes

01. **When Evidence Is Incomplete** — `en-c2-pod-001`
02. **Fairness Beyond Average Results** — `en-c2-pod-002`
03. **Who Owns Cultural Stories?** — `en-c2-pod-003`
04. **The Limits of Technological Solutions** — `en-c2-pod-004`
05. **Freedom of Expression and Responsibility** — `en-c2-pod-005`
06. **Risk and Public Decision-Making** — `en-c2-pod-006`
07. **Scientific Integrity Under Pressure** — `en-c2-pod-007`
08. **Language as a Form of Power** — `en-c2-pod-008`
09. **Ethics of Collecting Personal Data** — `en-c2-pod-009`
10. **The Trade-offs of Urban Development** — `en-c2-pod-010`
11. **Who Benefits from Innovation?** — `en-c2-pod-011`
12. **What Society Owes Future Generations** — `en-c2-pod-012`
13. **The Meaning of Consent** — `en-c2-pod-013`
14. **Building Agreement Without Consensus** — `en-c2-pod-014`
15. **Why Good Judgement Resists Certainty** — `en-c2-pod-015`

## Production workflow

1. Commission the same English-speaking male and female voice performers for all recordings and secure explicit contractual rights.
2. Write an original two-host script for each topic, with target vocabulary and level review; translate it to Arabic independently.
3. Record a single five-minute A1 pilot with both performers in a quiet room, with clean mic levels and consistent acoustics.
4. Edit breaths and noise conservatively; check loudness consistency, diction and conversation realism. No long intro music.
5. Verify final MP3 duration and speech/transcript match; review rights documentation before including any audio in the app or on YouTube.
6. Test Android streaming, replays, speed, offline download, transcript toggle and app background behavior on the original main branch.
7. Complete all 15 A1 episodes before progressing to A2, then B1, B2, C1 and C2. Do not publish empty or unrecorded entries as if playable.

## Existing external-content pilot status

The earlier 29-second VOA snippet was explicitly rejected for the five-minute series and must not appear as a published WorldVoice podcast. VOA original work may be used separately with clear attribution, but downloaded lessons do not guarantee the exact two-voice, no-narrator, five-minute format. See https://learningenglish.voanews.com/p/6861.html for original VOA terms.
