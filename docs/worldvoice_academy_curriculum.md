# WorldVoice Academy — Curriculum Blueprint (A1 → C2)

**Scope:** learning and course screens only. Do not alter Rooms, Live, chat, rewards or wallet to implement Academy.

## Product promise

WorldVoice Academy is a guided curriculum, not a vocabulary list. A beginner begins with a supported greeting and conversation, practices comprehension and pronunciation, reads an illustrated-style graded story, and receives meaningful feedback. The instructor persona is warm but grounded; completing self-study is not a certified CEFR qualification.

Inspired by the **CEFR Companion Volume (Council of Europe)** and the general **learning-path**, **guided conversation**, and **graded story-reader** interaction patterns (not another product's characters, artwork, text, names or proprietary stories). Language instruction is original and reviewed per locale.

## Long-term level plan

| Level | Intended skill outcome | Planned units | Core topics | Performance checkpoint |
|---|---|---:|---|---|
| Pre-A1 onboarding | Script awareness / greetings | 4 preparatory mini-units | Letters/sounds, first greetings, introductions, basic numbers | Recognize and say first phrases |
| A1 beginner | Introduce yourself and understand familiar phrases | 12 | Greetings, family, numbers, time, home, food, daily routine, shopping, city, hobbies, weather, travel | Introductory conversation and simple reader comprehension |
| A2 elementary | Handle routine social tasks | 12 | Requests, invitations, transport, health, directions, messages, work, past events | Everyday situation simulation and graded story |
| B1 intermediate | Narrate events, reasons and experiences | 16 | Opinions, plans, storytelling, travel problems, culture, online communication | 3–5 minute explanation, narrative summary, reading quiz |
| B2 upper intermediate | Discuss abstract topics and defend views | 16 | Debate, interviews, nuanced grammar, media, longer readings | Supported structured debate and analytical writing |
| C1 advanced | Communicate flexibly in social and professional contexts | 20 | Academic/professional discourse, idioms, register, inference, long-form articles | Oral presentation, persuasive writing, advanced reading |
| C2 proficiency | Understand subtle meaning and communicate precisely | 20 | Literary nuance, complex inference, paraphrase, stylistic precision | Multi-text synthesis and extended high-level performance |

Counts above are **curriculum targets**, not shipped lessons. Currently shipped content is 2 A1 units × 6 lesson kinds × 5 languages = **60 activities**. Incomplete content must stay visibly marked **Planned**, never selectable as a finished course.

Language-specific objectives, writing systems, honorifics, sound contrasts, morphology and cultural situations must be adapted independently for English, Spanish, French, Mandarin Chinese and Korean; support for more languages follows editorial review, not automated literal translation.

## Lesson sequence for each unit (recommended 15–25 min)

1. **Dialogue first (2 min):** learner enters a real situation (greeting at a café, introducing a friend). A character speaks in the target language, the learner chooses the fitting reply, receives correct/incorrect feedback, and can replay native-language TTS. Beginner prompts have Arabic guidance; support fades at higher levels.
2. **Words in context (4 min):** 5–12 curated terms displayed as original text, accurate pronunciation notation, Arabic gloss and normal/slow audio. No grey low-contrast text. Use appropriate romanization (Pinyin Mandarin, Revised Romanization Korean).
3. **Retrieval practice (3 min):** match meaning, choose correct word, construct a short phrase, and recall after interleaved practice. Incorrect responses reappear in the same session.
4. **Grammar micro-lesson (3 min):** one pattern demonstrated in dialogue, a pair of examples, a short use-it question.
5. **Storybook (5–8 min):** original, age-appropriate, level-controlled story with readable page turns. Each page has original language text, optional Arabic assistance and same-language audio. Provide word-level vocabulary lookups as editorial content becomes available. Keep narration playable without turning pages unexpectedly.
6. **End-of-story comprehension (2 min):** at least one question answered correctly to finish the reading activity; save progress via the existing private AcademyProgressService to avoid changing user data models.
7. **Listening/speaking and review (3–5 min):** short real-life audio prompts; meaningful self-recording or speaking practice when quality verification is available; revision schedule 1, 3, 7, 14, 30 days.

## Stories: not PDF-only

Default format is an **in-app book reader**, because fixed PDFs cannot expose comfortable native-font resizing, text-to-speech, glossary tap, controlled page navigation and integrated checks as easily. Later, offer optional downloadable PDF with the *same* original story and illustrations if users request offline printing. Images should be authored assets, compressed and cached; never display internet-only fake book pages as content.

Reading progression:
- A1: 4–8 short pages; 1–3 simple sentences each; strong context; optional translation.
- A2: 6–12 pages; simple multi-step plot.
- B1: 8–16 pages; meaningful character motivation, several events.
- B2: 10–24 pages; nuance, implied meaning, cause and effect.
- C1/C2: chapters, styles, ambiguity, analysis, argumentation.

Proposed original serial story families (translate **adaptively**, not word for word): *The Lost Notebook*, *The Hidden Message*, *A Small Act of Kindness*, *The City Train*, *A Letter from Tomorrow*. Keep people/place names consistent across episodes; ensure each vocabulary list is authentic to its target language.

## Assessment and progress

- Entry placement is optional; a true beginner can choose a path without an exam.
- Practice can give immediate non-monetary feedback. Do not turn coins or gifts into language qualification.
- Unit completion: all required exercises finished and comprehension passed.
- Level completion: mastery of listening, reading, writing, speaking checked with calibrated proficiency tasks. A checklist alone cannot claim CEFR certification.
- Progress remains inside the existing `users/{uid}/academy_progress` records. Retain stable legacy IDs. New checkpoints need separately designed Firestore rules before storing their results.
- Daily learning goal: optional 5, 10 or 20 minutes. Use review reminders only with clear opt-in.

## Concrete delivery batches

**Batch 1 — interactive pilot:** A1 beginning dialogues in the existing five courses; immersive story reader for existing stories; curriculum-roadmap cards clearly distinguishing playable and planned levels; tests covering scope and basic interaction. Do **not** touch room-related paths.

**Batch 2 — content depth:** 12 reviewed A1 units per language, original graded episodic stories with approved illustration assets, phrase construction, spaced review and proper speaking assessment.

**Batch 3 — A2 then B1:** release content only after quality review and practical checks.

**Batch 4 — B2/C1/C2:** extended writing, reading and discourse assessment with qualified-language review. Do not advertise a graduation certificate until the assessment is demonstrably credible.

## Acceptance checks

- From Learn → course → start conversation → first vocabulary lesson → storybook, no placeholder pages.
- Each story has cover, back/next, page number, normal/slow listening, translation reveal and comprehension feedback.
- English, Spanish, Mandarin, French and Korean all render their own scripts correctly.
- On device, audio is in the target language (language pack may be required); no audio errors are disguised as success.
- Dark and light themes remain readable on narrow Android displays; back navigation and screen-reader labels work.
- No changes outside `lib/features/learn/**`, `test/academy_*.dart` and curriculum documentation. No modification of Rooms/Live behavior.
