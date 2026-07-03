# Dialogue and Mood (Phase 6)

**SPEC/ai** — Logic-level dialogue and portrait mood signaling. Source: this document; implementation (events, mood state machine): [ai-events-and-dossier.md](../program/ai-events-and-dossier.md). Portrait assets and UI layout are deferred to UI phases. Province identity (e.g. province id in DialogueEvent variables): [world-model-identity.md](../game/world-model-identity.md).

---

## Purpose

AI emits **events** that describe what to say and which mood to show. The UI (or test harness) resolves these to text and visuals. AI only produces structured event payloads; it does not load assets or render. For dialogue that **prompts the player to respond** (overtures, intervention, alliance offers), see [dialogue-management.md](dialogue-management.md) and [dialogue-content-and-yarn.md](dialogue-content-and-yarn.md); those flows tie into game actions and use the same content keys and variables where applicable.

---

## Dialogue categories

- **diplomatic** — Declaration of war, peace offer, alliance proposal, trade agreement, warning, demand, insult, compliment.
- **reactive** — Response to player action (forts on border, attack on ally, attack on minor, attack on tribe, tech first, colony founded, threat ignored, gift, spies caught).
- **event** — Commentary on game events (battle won/lost, colony founded, tech discovered, capital threatened, era transition).
- **agenda** — Hint at hidden motivation (personality + hidden agenda flavour).
- **negotiation** — Lines during active deal-making, keyed by mood and situation (opening, counter_offer, accepting, rejecting).

Dialogue content (localized strings) lives in data assets; AI selects **keys and context** only.

---

## DialogueEvent model (logic)

Emitted when a dialogue line should be shown. Consumed by UI or tooling.

| Field | Type | Meaning |
|-------|------|---------|
| leaderId | string | Which leader is speaking. **leaderId is the player (Great Power) id of the speaking faction** (e.g. 'gp1', 'gp2', or canonical leader id like 'victoria', 'napoleon'). This is the same as the player/faction id in game state. |
| category | string | One of the categories above. |
| situation | string | Sub-context (e.g. declare_war, peace_offer, battle_won). |
| era | string | discovery \| earlyModern \| imperial \| industrial (for era-appropriate phrasing). For events tied to a specific turn (e.g. battle_won / battle_lost, forts_on_border), the system derives this from the game’s turn-time mapping as `eraFromYear(mapping.yearAtTurn(turnNumber))` (see SPEC/game/turn-time-mapping.md). For era_change events, this is the new era value. |
| mood | string? | Optional; e.g. for negotiation. |
| variables | map string→string | Fill-in for templates (e.g. otherNation, province). When the key is `province` (or any province id), the value MUST be in prefixed form per [world-model-identity.md](../game/world-model-identity.md). |

Selection must be **deterministic** given game state and dialogue seed (same state + seed → same event). UI resolves (leaderId, category, situation, era, mood, variables) to a dialogue key and then to localized text.

---

## Portrait mood (signal only)

AI emits **PortraitMoodEvent** when the portrait mood should change. No asset paths or images in spec; UI chooses how to render (e.g. different portrait image or animation).

**Mood values:** considering, pleased, gracious, calculating, skeptical, impatient, irritated, dismissive.

Used when:
- **Negotiation** — During active deal-making, mood is driven by offer quality delta and stall count (see [ai-events-and-dossier.md](../program/ai-events-and-dossier.md) § Dialogue and Mood and the mood state machine in colonizethis_ai). On transition the system emits PortraitMoodEvent with fields leaderId, fromMood, toMood, durationMs per [ai-events-and-dossier.md](../program/ai-events-and-dossier.md) § PortraitMoodEvent.
- **Non-negotiation** — Base mood can be derived from relation level or last event (e.g. insulted → irritated). Optional emission for consistency.

Mood state machine (logic): given current mood, offerQualityDelta (-1..1), and stallCounter, compute next mood; on transition, emit event. All inputs must be deterministic (seeded or from game state).

### Mood State Machine Transition Rules

The mood state machine uses **stallCounter** (number of negotiation stalls with no progress) and **offerQualityDelta** (-1 to 1, positive = offer improved, negative = offer worsened) to compute the next mood. When the computed mood differs from current mood, emit a `PortraitMoodEvent`. Tie-breaking uses a seed for deterministic results.

| Condition | Next Mood | Notes |
|-----------|-----------|-------|
| `stallCounter >= 4` | `impatient` or `skeptical` | High stall count; random via seed |
| `stallCounter >= 2` | `calculating` | Medium stall count |
| `offerQualityDelta >= 0.5` | `pleased` or `gracious` | Strong positive offer; random via seed |
| `offerQualityDelta <= -0.5` | `irritated` or `dismissive` | Strong negative offer; random via seed |
| `offerQualityDelta <= -0.2` | `skeptical` | Moderate negative offer |
| `offerQualityDelta >= 0.2` | `considering` | Moderate positive offer |
| Otherwise (near zero) | `calculating` or `considering` | Default: if current is `calculating` or seed % 3 == 0 → `calculating`; else `considering` |

The default mood when opening diplomacy (no prior negotiation context) is `considering` (see `kDefaultMood` in implementation).

### Dialogue Seed Injection

The **dialogue seed** is derived from the per-turn seed hierarchy: `seeds.dialogueSeed = hash(globalGameSeed, aiSeed[P], T)` per the seeding rules in [ai-architecture.md](ai-architecture.md) § Seeding. This seed drives:
- **Strategic cadence:** Whether to emit optional agenda-flavoured commentary (checked via `dialogueSeed % kDialogueTurnsBetweenComments == 0`).
- **Mood tie-breaking:** When multiple moods are possible (e.g. stall >= 4 → impatient/skeptical), the LSB of the seed determines which.

When multiple events can be emitted in one turn (e.g. era change + battle results), each event source independently uses the same dialogue seed; there is no combination rule—the seed is simply consumed by each decision point.

### Agenda Dialogue Cadence

Agenda-flavoured dialogue (optional commentary on a leader's hidden agenda) is emitted on a deterministic schedule: **once every `kDialogueTurnsBetweenComments` turns per AI leader**, where `kDialogueTurnsBetweenComments = 7`. Concretely, when the strategic AI layer runs for a leader and `dialogueSeed % kDialogueTurnsBetweenComments == 0`, it may emit a single `DialogueEvent(category: 'agenda', situation: 'comment')` and a matching `PortraitMoodEvent` with base mood `considering`. This schedule is deterministic given the seed and may be made ruleset-configurable in a later phase.

---

## When to emit

- **DialogueEvent:** When AI performs a diplomatic action (declare war, offer peace, etc.), when a game event triggers commentary (battle result, era change), when player action triggers reactive banter, or when agenda-flavoured line is chosen (see § Agenda Dialogue Cadence).
- **PortraitMoodEvent:** When negotiation mood transitions; optionally when opening/closing diplomacy screen with a base mood.

Emission is synchronous from AI turn or from resolution hooks; no async side effects. Order of events is deterministic for replay.

---

## Situation coverage matrix (implementation truth table)

Canonical `situation` strings are stable for `dialogueKeyForEvent`.

| Category | Situation | Status | Hook | Notes |
|---|---|---|---|---|
| reactive | forts_on_border | implemented | build/work fort completion | Human-built fort adjacent to AI-owned province. |
| reactive | attack_on_ally | implemented | combat phase detection | Human attacks a Great Power that holds a **formal alliance** with an AI speaker (`DiplomacyRelation.formalAlliance == true`, at peace). The informal `RelationLevel.allied` relation band (score 76–100) does **not** by itself trigger this — only a treaty from a resolved `Alliance` order does. See [SPEC/game/diplomacy.md](../game/diplomacy.md) § Alliances. |
| reactive | attack_on_minor | implemented | combat phase detection | Human attacks a Minor Nation province; AI speaker reacts when tied to the Minor via an embassy or the informal `RelationLevel.allied` band (Minors/Tribes do not form formal Great-Power alliances). |
| reactive | attack_on_tribe | implemented | combat phase detection | Human attacks a Tribe province; AI speaker reacts when tied to the Tribe via an embassy or the informal `RelationLevel.allied` band (Minors/Tribes do not form formal Great-Power alliances). |
| reactive | tech_first | implemented | research-complete detection | Human is first faction in match to unlock a tech. |
| reactive | spies_caught | implemented | counter-spy kill resolution | AI owner of target province speaks when human spy is removed by counter-spy. |
| reactive | spies_defected | implemented | counter-espionage defection resolution | AI defector speaks when a human spy defects via counter-espionage. |
| reactive | colony_founded | deferred | n/a | Not separately observable as a player-action hook in current turn pipeline. |
| reactive | threat_ignored | deferred | n/a | No canonical "threat issued/ignored" state transition is currently recorded. |
| reactive | gift | deferred | n/a | No distinct gift action hook currently exists in diplomacy resolution. |
| event | battle_won / battle_lost | implemented | land/naval battle resolution | Existing deterministic event dialogue path. |
| event | era_change | implemented | end-of-turn era transition | Existing deterministic event dialogue path. |
| event | tech_discovered | implemented | research-complete detection | AI discoverer emits commentary. |
| event | capital_threatened | implemented | combat conflict pre-resolution | AI capital is targeted by at least one human attacker this turn. |
| event | colony_founded | implemented | province ownership transition | Province owner changes from null to AI in New World. |

---

## Acceptance criteria

- **Emission by category:** DialogueEvent and PortraitMoodEvent are emitted per spec categories/situations: event, reactive, diplomatic, negotiation, agenda (see § Dialogue categories and § When to emit).
- **Determinism:** Same game state and dialogue seed produce the same sequence of events; replay and save/load restore or recompute consistently.
- **Strategic cadence:** Optional strategic agenda/comment lines and base PortraitMoodEvent emissions follow the documented cadence: they are emitted only when `dialogueSeed % kDialogueTurnsBetweenComments == 0` for the current leader, with `kDialogueTurnsBetweenComments = 7` (defined in the dialogue catalog).
- **Province identity:** When DialogueEvent (or any event) variables include a province id, the value MUST be in prefixed form per [world-model-identity.md](../game/world-model-identity.md).
- **Mood values:** PortraitMoodEvent and DialogueEvent mood fields use only the fixed set: considering, pleased, gracious, calculating, skeptical, impatient, irritated, dismissive.
- **UI contract:** UI resolves event fields (leaderId, category, situation, era, mood, variables) to dialogue keys and localized text only; no asset paths or image references in events.
- **attack_on_ally requires a formal alliance (positive):** Given an AI Great Power speaker holds a formal alliance with another Great Power defender (`DiplomacyRelation.formalAlliance == true`, `RelationState.atPeace`), when the human attacks the defender, then the system emits one `attack_on_ally` reactive DialogueEvent for that AI speaker.
- **attack_on_ally suppressed without a formal alliance (negative):** Given an AI Great Power speaker is at peace with another Great Power defender at the informal `RelationLevel.allied` band (relation score 76–100) but with `DiplomacyRelation.formalAlliance == false`, when the human attacks the defender, then the system emits no `attack_on_ally` DialogueEvent for that speaker.
