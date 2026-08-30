# Dialogue System — Technical Contract

**SPEC/program** — Data structures, emission points, and resume contract for AI–human dialogue. Game/AI design: [dialogue-management.md](../ai/dialogue-management.md), [dialogue-content-and-yarn.md](../ai/dialogue-content-and-yarn.md). Province identity: [world-model-identity.md](../game/world-model-identity.md).

---

## Responsibility

Define the **dialogue point** model used by the Flutter app, how resolution (or game loop) produces dialogue points, and how the client submits **outcomes** to resume. Logic lives in colonizethis_logic (or shared); the app UI consumes the same contract. Presentation (Yarn/Jenny) is constructed only while the overlay is shown and disposed on dismiss; load sits inside the game-app 1 s surface budget ([ui-surface-budget.md](ui-surface-budget.md)).

---

## Data model

### PendingDialoguePoint

Represents one dialogue that the player must or may respond to. Emitted when conditions in [dialogue-management.md](../ai/dialogue-management.md) are met.

| Field | Type | Meaning |
|-------|------|---------|
| kind | string | One of: `overture_target_response`, `intervention_choice`, `alliance_offer_response`, `dialogue_flavour`. |
| blocking | bool | If true, resolution suspends until outcome is submitted. |
| presentationMode | string | `modal` \| `overlay`; see dialogue-management.md. |
| contentKey | string | Key for content (Yarn node name or data lookup); e.g. `DialoguePoint/overture_target_response/embassy`. |
| payload | (kind-specific) | Opaque payload for this kind. Used to build UI and to validate outcome. |

**Payload by kind:**

- **overture_target_response:** List of offers (each: offererGpId, targetFactionId, stage). Same data as existing OvertureOffer in colonizethis_logic; may be a single offer or multiple. Outcome: one OvertureDecision per offer.
- **intervention_choice:** aggressorGpId, defenderFactionId (Minor/Tribe), interveningGpId. Outcome: **InterventionDecision** (or equivalent triple + InterventionChoice) applied in the Diplomacy phase via **resumeTurnResolutionWithInterventionDecisions** (not combat).
- **alliance_offer_response:** offererGpId, targetGpId. Outcome: AllianceDecision (accept, refuse).
- **dialogue_flavour:** DialogueEvent fields (leaderId, category, situation, era, mood?, variables). No outcome; dismiss only.
- **game_start_intro:** No payload (or minimal, e.g. gameId for "already shown" tracking). Emitted by the app when entering in-game; blocking at UI level until dismissed. No outcome; dismiss only.

Payloads use ids only; no UI strings. Province ids in payload are **prefixed** per world-model-identity.

### DialogueOutcome (sealed)

The player’s response, to be applied by the resolver.

- **OvertureDecision** — existing type; one per overture offer (offererGpId, targetFactionId, stage, accepted).
- **InterventionChoice** — existing enum (intervene, doNothing, protest); plus context (e.g. attackingGpId, defenderFactionId) so the resolver knows which battle.
- **AllianceDecision** — accept \| refuse; plus offererGpId, targetGpId.

Implementation may use a sealed class or tagged union. The **resume API** accepts a list of outcomes; the resolver applies each and continues.

---

## Emission and blocking

- **Overture (blocking):** When the Diplomacy phase encounters an Establish Overture whose target is a human GP, the phase returns DiplomacyPhaseResult with non-null **pendingOvertures**. Turn resolution returns **TurnResolutionPendingOvertures**. This is **equivalent to** emitting one or more PendingDialoguePoint(s) of kind `overture_target_response` with blocking true. The app **maps** TurnResolutionPendingOvertures to the dialogue model and presents accordingly; it calls **resumeTurnResolutionWithOvertureDecisions** with the collected OvertureDecision list. Presentation: [dialogue-presentation.md](../ui/dialogue-presentation.md).
- **Intervention (blocking):** When the **Diplomacy phase** applies a GP `Declare War` on a Minor/Tribe and a **human** GP has an Embassy or purchased land there, turn resolution returns **TurnResolutionPendingIntervention** with one prompt per required human. The app maps this to PendingDialoguePoint(s) of kind `intervention_choice` and calls **resumeTurnResolutionWithInterventionDecisions** with **InterventionDecision** list; the resolver re-runs the Diplomacy phase and continues the turn.
- **Alliance (blocking):** When an alliance proposal targets a human GP, resolution emits a PendingDialoguePoint of kind `alliance_offer_response` and suspends; resume with AllianceDecision.
- **Flavour (non-blocking):** [DialogueEvent](ai-events-and-dossier.md) is emitted during AI order generation or resolution. The app may show it as a non-blocking PendingDialoguePoint (presentationMode overlay or modal). No resume; game flow does not wait.

Emission order is deterministic given game state and phase. Same state → same set of dialogue points.

---

## Resume API

- **Overture:** Existing **resumeTurnResolutionWithOvertureDecisions**(game, pendingOvertures, decisions, …). Returns TurnResolutionResult; may be Complete or again PendingOvertures.
- **Intervention:** **resumeTurnResolutionWithInterventionDecisions** (and **applyInterventionAgainstAggressor** / legacy **applyInterventionChoice** for combat-adjacent tests). The dialogue system supplies **InterventionDecision** rows matching **InterventionPrompt** from **TurnResolutionPendingIntervention**.
- **Alliance:** To be added when alliance_offer_response is implemented; signature analogous to overture resume.

A **unified** resume API that accepts List<DialogueOutcome> and dispatches by outcome type may be introduced in a later phase so the app need not branch on dialogue kind. Until then, each blocking kind has its own resume entry point.

---

## Contract for the Flutter app

- The app receives dialogue point data (kind, blocking, presentationMode, contentKey, payload). For overtures, that data is derived from TurnResolutionPendingOvertures (game, pendingOvertures).
- The app resolves **contentKey** + payload variables to displayable text and choices via Jenny + Yarn (and supporting data where applicable).
- The app calls the **resume** API with the outcome types (OvertureDecision, InterventionChoice, etc.) defined by logic.
- Determinism: replay and save/load must reproduce or recompute the same dialogue point set from persisted state; only the player’s choices affect subsequent state.

---

## Acceptance criteria

- **Given** turn resolution returns TurnResolutionPendingOvertures with N offers, **when** the app presents the dialogue, **then** the app builds PendingDialoguePoint(s) of kind `overture_target_response` with contentKey derived from offer stage(s), and calls resumeTurnResolutionWithOvertureDecisions with N OvertureDecision(s) matching the user’s choices.
- **Given** a PendingDialoguePoint of kind `intervention_choice`, **when** the player selects an option, **then** the client calls **resumeTurnResolutionWithInterventionDecisions** with an **InterventionDecision** that includes aggressorGpId, defenderMinorOrTribeId, interveningGpId, and the chosen **InterventionChoice**, before the turn continues past the Diplomacy phase.
- **Given** a non-blocking dialogue point (dialogue_flavour), **when** the client shows it, **then** no resume API is called; game flow is not blocked.
- **Province identity:** Any payload that carries a province id uses prefixed form per [world-model-identity.md](../game/world-model-identity.md).
- **Determinism:** Same game state and phase produce the same dialogue point set; only player-supplied outcomes change subsequent state.
