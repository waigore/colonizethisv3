# Dialogue and Mood (Phase 6)

**SPEC/ai** — Logic-level dialogue and portrait mood signaling. Source: this document; implementation (events, mood state machine): [ai-events-and-dossier.md](../program/ai-events-and-dossier.md). Portrait assets and UI layout are deferred to UI phases. Province identity (e.g. province id in DialogueEvent variables): [world-model-identity.md](../game/world-model-identity.md).

---

## Purpose

AI emits **events** that describe what to say and which mood to show. The UI (or test harness) resolves these to text and visuals. AI only produces structured event payloads; it does not load assets or render.

---

## Dialogue categories

- **diplomatic** — Declaration of war, peace offer, alliance proposal, trade agreement, warning, demand, insult, compliment.
- **reactive** — Response to player action (forts on border, attack on ally, tech first, colony founded, threat ignored, gift, spies caught).
- **event** — Commentary on game events (battle won/lost, colony founded, tech discovered, capital threatened, era transition).
- **agenda** — Hint at hidden motivation (personality + hidden agenda flavour).
- **negotiation** — Lines during active deal-making, keyed by mood and situation (opening, counter_offer, accepting, rejecting).

Dialogue content (localized strings) lives in data assets; AI selects **keys and context** only.

---

## DialogueEvent model (logic)

Emitted when a dialogue line should be shown. Consumed by UI or tooling.

| Field | Type | Meaning |
|-------|------|---------|
| leaderId | string | Which leader is speaking. |
| category | string | One of the categories above. |
| situation | string | Sub-context (e.g. declare_war, peace_offer, battle_won). |
| era | string | discovery \| earlyModern \| imperial \| industrial (for era-appropriate phrasing). |
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

---

## When to emit

- **DialogueEvent:** When AI performs a diplomatic action (declare war, offer peace, etc.), when a game event triggers commentary (battle result, era change), when player action triggers reactive banter, or when agenda-flavoured line is chosen (e.g. at dialogue seed interval).
- **PortraitMoodEvent:** When negotiation mood transitions; optionally when opening/closing diplomacy screen with a base mood.

- **Strategic AI cadence (agenda/comment + base mood):** Strategic AI may emit **optional** agenda-flavoured commentary and a matching base PortraitMoodEvent on a **deterministic schedule** derived from the dialogue seed. For MVP, this schedule is: _once every `kDialogueTurnsBetweenComments` turns per AI leader_, where `kDialogueTurnsBetweenComments = 7` (defined in `colonizethis_data` dialogue catalog). Concretely, when the strategic AI layer runs for a leader and `dialogueSeed % kDialogueTurnsBetweenComments == 0`, it may emit a single `DialogueEvent(category: 'agenda', situation: 'comment')` and a `PortraitMoodEvent` with base mood `considering`. This schedule is deterministic given the seed and may be made ruleset-configurable in a later phase.

Emission is synchronous from AI turn or from resolution hooks; no async side effects. Order of events is deterministic for replay.

---

## Acceptance criteria

- **Emission by category:** DialogueEvent and PortraitMoodEvent are emitted per spec categories/situations: event, reactive, diplomatic, negotiation, agenda (see § Dialogue categories and § When to emit).
- **Determinism:** Same game state and dialogue seed produce the same sequence of events; replay and save/load restore or recompute consistently.
- **Strategic cadence:** Optional strategic agenda/comment lines and base PortraitMoodEvent emissions follow the documented cadence: they are emitted only when `dialogueSeed % kDialogueTurnsBetweenComments == 0` for the current leader, with `kDialogueTurnsBetweenComments` defined in the dialogue catalog (MVP = 7).
- **Province identity:** When DialogueEvent (or any event) variables include a province id, the value MUST be in prefixed form per [world-model-identity.md](../game/world-model-identity.md).
- **Mood values:** PortraitMoodEvent and DialogueEvent mood fields use only the fixed set: considering, pleased, gracious, calculating, skeptical, impatient, irritated, dismissive.
- **UI contract:** UI resolves event fields (leaderId, category, situation, era, mood, variables) to dialogue keys and localized text only; no asset paths or image references in events.
