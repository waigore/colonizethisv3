# Hidden Agendas (Phase 6)

**SPEC/ai** — Secret agenda per AI, behavior modifiers, and discovery. Source: GDD 10e. Data/events: [ai-events-and-dossier.md](../program/ai-events-and-dossier.md).

---

## Principles

- **One agenda per AI** — Assigned at game start; fixed for the game.
- **Deterministic assignment** — Use `agendaSeed[P] = hash(globalGameSeed, aiSeed[P])` to select from the agenda list. No runtime randomness. Same save → same assignment.
- **Behavior-driven** — Agenda modifies AI decisions (war/peace, alliances, espionage, build targets), not only dialogue.
- **Discoverable** — Evidence is accumulated from observable actions; dossier exposes suspicion levels, never the true agenda.

---

## Agenda types

| Id | Behavior effect (summary) |
|----|----------------------------|
| warmonger | Attacks weaker neighbors; breaks peace early; favors army over economy. |
| isolationist | Declines alliances; cancels alliances; minimal trade; internal focus. |
| backstabber | Attacks allies when weak; breaks treaties after benefit; keeps high relations before strike. |
| tech_thief | High spy usage; prioritizes espionage tech; catches up to player tech. |
| peacemaker | Offers peace earlier; intervenes in others’ wars; defensive alliances only. |
| envy | Mirrors player builds and objectives; competes on same victory path; may attack if player ahead. |

---

## Assignment

At game start, for each AI Great Power `P`:

1. Compute `agendaSeed[P]` from game seed and `aiSeed[P]`.
2. Map seed to one of six agenda ids (deterministic shuffle or index). More than six AI players: agendas may repeat.
3. Store `hiddenAgenda[P]` in game state; never expose to human players. Only suspicion scores and evidence are visible (see dossier).

---

## Behavior modifiers

The full per-order diplomatic scoring model these modifiers feed into is normative in [diplomacy-planner.md](diplomacy-planner.md); the agenda/personality modifier definitions and ACs below remain the source of truth for the modifier values themselves.

Agenda applies **additive or multiplicative modifiers** to the same quantities that personality uses:

- **War declaration** — Warmonger: lower relation threshold to declare war; Peacemaker: strong negative modifier; Backstabber: bonus if target is ally.
  - **Relation threshold:** AI only considers declaring war on a faction when relation score ≤ max score for that agenda. Default (base) 50; Warmonger 70 (more willing); Peacemaker 30 (only when hostile); Backstabber 100 (can declare on allies).
  - **Target-specific scoring:** When scoring declare-war candidates, add bonus when target is a weaker neighbor (Warmonger) or when target is allied (Backstabber). Config: `declareWarTargetBonusWeakerNeighbor` (warmonger default +30), `declareWarTargetBonusAlly` (backstabber default +25).
- **Peace acceptance** — Peacemaker: accept at lower war-score threshold; Warmonger: higher threshold.
- **Alliance acceptance** — Isolationist: high decline chance; others unchanged or positive.
- **Build/order choice** — Tech Thief: boost spy/research orders; Envy: boost orders that mirror human’s recent builds or targets.
- **Treaty breaking** — Backstabber: more likely to break when beneficial; Warmonger: more likely to break peace early.
  - **Break-alliance scoring (Refs #3758 R6):** When the diplomacy planner scores a `breakAlliance` candidate (voluntary end of a formal alliance), the candidate score starts from the neutral base (50) and is adjusted by: `+ getAgendaTreatyBreakingModifier(agendaId)` (Backstabber +25, Warmonger +20 — both lean toward breaking), `- getAgendaAllianceAcceptanceModifier(agendaId)` (Isolationist −40 inverts to **+40** because the isolationist "cancels alliances"; Peacemaker +10 inverts to **−10** because the peacemaker keeps defensive alliances), and `- (allianceTendency - 50)` so high-alliance-tendency personalities resist breaking and low-tendency personalities lean toward it. A default agenda with a neutral (50) `allianceTendency` personality yields the neutral base score.
  - **Boycott scoring (Refs #3758 R5):** When the diplomacy planner scores a `boycott` candidate (a colony trade embargo against another Great Power; SPEC/game/diplomacy.md § Boycott), the candidate score starts from the neutral base (50) and is adjusted by: `+ getAgendaTreatyBreakingModifier(agendaId)` (Backstabber +25, Warmonger +20 — both lean toward the hostile economic action), `- getAgendaPeaceAcceptanceModifier(agendaId)` (Peacemaker +30 inverts to **−30** because the peacemaker avoids hostile economic coercion; Warmonger −25 inverts to **+25**), and `+ (warLikelihood - 50)` so high-`warLikelihood` personalities lean toward boycotting and low-`warLikelihood` personalities resist. A default agenda with a neutral (50) `warLikelihood` personality yields the neutral base score. Deeper economic weighting (the target GP's trade volume with the issuer's colonies, and the relative economic damage to issuer vs target) is deferred to a follow-up slice (Refs #3758 R5/R12 treasury awareness); this scoring is the agenda/personality-aware baseline.

Expressed as weights or thresholds in config; SPEC requires each agenda type has defined effects in the above categories.

---

## Evidence and suspicion

When the game or AI performs an action, **evidence rules** (defined per agenda) may add points to that agenda’s suspicion counter for that AI (e.g. “declared war on weaker neighbor” → +2 Warmonger suspicion).

- Counters are **per (observer nation, subject AI, agenda type)**. Only the human observer’s view is stored; AI does not observe other AI’s evidence.
- **Suspicion levels** map total evidence score to a band: Unknown (0–2), Possible (3–5), Likely (6–8), Almost certain (9–10), Confirmed (10+). Display labels in dossier use these bands; “Confirmed” is a threshold, not revelation of true agenda.
- Evidence is deterministic (same actions → same evidence). Dossier projection is PlayerView-safe: only suspicion scores and capped evidence log exposed. See [ai-dossier.md](ai-dossier.md).

**Evidence rule coverage (current product)**  
Evidence rules are evaluated during turn resolution (see [ai-events-and-dossier.md](../program/ai-events-and-dossier.md)) with deterministic, PlayerView-safe deltas:

- **War declaration** — Warmonger when the target is a weaker Great Power (+2) or any GP target (+1 battle-oriented signal as implemented). **Backstabber** when the AI declared war on a prior ally (+3), or when the AI declared war on a Great Power toward whom it had **`callToArmsRefused`** in the same turn or within the prior **3** turns (+3; “broke obligation then struck”). Implementation: `evidenceForDeclareWar`, diplomatic history.
- **Peace offer** — Peacemaker (+1).
- **Land / naval battle victory (attacker)** — Warmonger per implemented rules.
- **Isolationist** — AI refuses **call to arms** while still at peace with the defender (+2). `evidenceForIsolationistCallToArmsRefuse`. GP–GP **alliance** orders resolve immediately in current product (no separate accept/decline step); isolationist “alliance decline” evidence is represented by this **call-to-arms** refusal path until bilateral alliance negotiation exists.
- **Tech thief** — **Removed:** `steal_tech` spy work no longer exists (Refs #3834). Passive spy RP boost and counter-espionage replace prior evidence hooks; Tech Thief agenda evidence rules for steal attempts are retired until a replacement signal is specified.
- **Envy** — AI completes a tech **or** an extraction **build_improvement** (tile with a resource in the extraction-cap set) in the **same tech-catalog category** the human most recently completed (research completion **or** extraction build), within **2** turns after that human completion (same turn counts): **+1** per qualifying completion, **max +3** total envy suspicion for that AI subject in that turn. Mirror tracking uses `Game.lastHumanCompletedResearchCategory` / `lastHumanResearchCategoryCompletionTurn` (historical JSON names); research phase calls `evidenceForEnvyResearchMirror`; extraction builds contribute category **gathering** via `envyMirrorTechCategoryForExtractionResource` in `colonizethis_data` / `tech_extraction.dart`.

---

## Acceptance criteria

- **Assignment and immutability:** One agenda per AI; assigned at game start from `agendaSeed[P]` (derived from global game seed and `aiSeed[P]`). Stored in game state; no mid-game change.
- **Determinism:** Same global game seed and `aiSeed[P]` yield the same agenda. Same observable actions yield the same evidence points (replay- and save/load-consistent).
- **Behavior modifiers:** Each agenda type has defined effects in the spec categories: war declaration, peace acceptance, alliance acceptance, build/order choice, treaty breaking. Expressed as weights or thresholds in config.
- **War declaration (relation threshold and target scoring):** Declare-war candidates are scored only when relation score ≤ agenda’s `declareWarMaxRelationScore` (default 50; warmonger 70; peacemaker 30). When scoring declare-war, warmonger receives bonus for target in weakNeighbors; backstabber receives bonus for allied target. Implementation uses config for thresholds and bonuses; diplomacy planner filters or zero-scores out-of-threshold declare-war and applies target bonuses.
- **Break-alliance scoring (treaty breaking):** Given two `breakAlliance` candidates with identical game context and the same `allianceTendency` personality, when the diplomacy planner scores them under a **backstabber** agenda vs a **default** (no-modifier) agenda, then the backstabber score is strictly greater than the default score (by the backstabber treaty-breaking modifier, +25).
- **Break-alliance scoring (peacemaker resists):** Given a `breakAlliance` candidate, when the diplomacy planner scores it under a **peacemaker** agenda vs a **default** agenda with the same personality, then the peacemaker score is strictly less than the default score (peacemaker alliance-acceptance +10 inverts to −10).
- **Break-alliance scoring (isolationist cancels alliances):** Given a `breakAlliance` candidate, when the diplomacy planner scores it under an **isolationist** agenda vs a **default** agenda with the same personality, then the isolationist score is strictly greater than the default score (isolationist alliance-acceptance −40 inverts to +40).
- **Break-alliance scoring (alliance tendency resists):** Given two otherwise-identical `breakAlliance` candidates scored under the same agenda but with personality `allianceTendency` 80 vs 50, when the diplomacy planner scores them, then the `allianceTendency`-80 score is strictly less than the `allianceTendency`-50 score.
- **Boycott scoring (neutral baseline):** Given a `boycott` candidate, when the diplomacy planner scores it under a **default** (no-modifier) agenda with a neutral (50) `warLikelihood` personality, then the score is the neutral base (50).
- **Boycott scoring (treaty breaking):** Given two `boycott` candidates with identical game context and the same `warLikelihood` personality, when the diplomacy planner scores them under a **backstabber** agenda vs a **default** agenda, then the backstabber score is strictly greater than the default score (by the backstabber treaty-breaking modifier, +25).
- **Boycott scoring (warmonger leans in):** Given a `boycott` candidate, when the diplomacy planner scores it under a **warmonger** agenda vs a **default** agenda with the same personality, then the warmonger score is strictly greater than the default score (treaty-breaking +20 and peace-acceptance −25 inverted to +25).
- **Boycott scoring (peacemaker resists):** Given a `boycott` candidate, when the diplomacy planner scores it under a **peacemaker** agenda vs a **default** agenda with the same personality, then the peacemaker score is strictly less than the default score (peacemaker peace-acceptance +30 inverts to −30).
- **Boycott scoring (war likelihood leans in):** Given two otherwise-identical `boycott` candidates scored under the same agenda but with personality `warLikelihood` 80 vs 50, when the diplomacy planner scores them, then the `warLikelihood`-80 score is strictly greater than the `warLikelihood`-50 score.
- **Evidence and suspicion:** Evidence rules add points per (observer nation, subject AI, agenda type). Suspicion bands (Unknown, Possible, Likely, Almost certain, Confirmed) map total evidence score; display uses bands only. True agenda is never exposed to the player. Evidence rule coverage matches **Evidence rule coverage (current product)** above (including spy, call-to-arms refuse, treaty-break attack window, and envy mirror for research plus extraction **build_improvement**).
- **Dossier contract:** Only suspicion scores and capped evidence log are exposed (PlayerView-safe). See [ai-dossier.md](ai-dossier.md) and [ai-events-and-dossier.md](../program/ai-events-and-dossier.md).

## Implementation

- **Assignment at game start:** Performed during setup; see [game-setup-pipeline.md](../program/game-setup-pipeline.md) (Build state or equivalent step).
- **Evidence, dossier, and events:** Event data, evidence rules, and dossier projection are defined in [ai-events-and-dossier.md](../program/ai-events-and-dossier.md).
- **Phase 6 AI:** Agenda is consumed in AI order generation; see [ai-planner.md](../program/ai-planner.md) (Phase 6, agenda sub-seed and behavior).
