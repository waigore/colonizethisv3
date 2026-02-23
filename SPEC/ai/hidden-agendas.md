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

Agenda applies **additive or multiplicative modifiers** to the same quantities that personality uses:

- **War declaration** — Warmonger: lower relation threshold to declare war; Peacemaker: strong negative modifier; Backstabber: bonus if target is ally.
- **Peace acceptance** — Peacemaker: accept at lower war-score threshold; Warmonger: higher threshold.
- **Alliance acceptance** — Isolationist: high decline chance; others unchanged or positive.
- **Build/order choice** — Tech Thief: boost spy/research orders; Envy: boost orders that mirror human’s recent builds or targets.
- **Treaty breaking** — Backstabber: more likely to break when beneficial; Warmonger: more likely to break peace early.

Expressed as weights or thresholds in config; SPEC requires each agenda type has defined effects in the above categories.

---

## Evidence and suspicion

When the game or AI performs an action, **evidence rules** (defined per agenda) may add points to that agenda’s suspicion counter for that AI (e.g. “declared war on weaker neighbor” → +2 Warmonger suspicion).

- Counters are **per (observer nation, subject AI, agenda type)**. Only the human observer’s view is stored; AI does not observe other AI’s evidence.
- **Suspicion levels** map total evidence score to a band: Unknown (0–2), Possible (3–5), Likely (6–8), Almost certain (9–10), Confirmed (10+). Display labels in dossier use these bands; “Confirmed” is a threshold, not revelation of true agenda.
- Evidence is deterministic (same actions → same evidence). Dossier projection is PlayerView-safe: only suspicion scores and capped evidence log exposed. See [ai-dossier.md](ai-dossier.md).

---

## Acceptance criteria

- **Assignment and immutability:** One agenda per AI; assigned at game start from `agendaSeed[P]` (derived from global game seed and `aiSeed[P]`). Stored in game state; no mid-game change.
- **Determinism:** Same global game seed and `aiSeed[P]` yield the same agenda. Same observable actions yield the same evidence points (replay- and save/load-consistent).
- **Behavior modifiers:** Each agenda type has defined effects in the spec categories: war declaration, peace acceptance, alliance acceptance, build/order choice, treaty breaking. Expressed as weights or thresholds in config.
- **Evidence and suspicion:** Evidence rules add points per (observer nation, subject AI, agenda type). Suspicion bands (Unknown, Possible, Likely, Almost certain, Confirmed) map total evidence score; display uses bands only. True agenda is never exposed to the player.
- **Dossier contract:** Only suspicion scores and capped evidence log are exposed (PlayerView-safe). See [ai-dossier.md](ai-dossier.md) and [ai-events-and-dossier.md](../program/ai-events-and-dossier.md).
