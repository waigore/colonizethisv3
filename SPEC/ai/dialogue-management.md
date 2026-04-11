# Dialogue Management — When, Where, and How

**SPEC/ai** — Defines when and where AI–human dialogue points appear, whether they block turn resolution, and how they are presented. Ties dialogue to game/diplo actions. Content and wording: [dialogue-content-and-yarn.md](dialogue-content-and-yarn.md). Technical flow: [dialogue-system.md](../program/dialogue-system.md). Province identity: [world-model-identity.md](../game/world-model-identity.md).

---

## Purpose

A single dialogue model covers **all** AI–human interactions: overtures, intervention choices, alliance offers, reactive banter, and future types. Each dialogue point has **conditions** (when/where it appears), **blocking** vs **non-blocking** behaviour, and **presentation mode** (overlay vs modal/screen). The Flutter app (Jenny/Flame) consumes this model.

---

## Dialogue point kinds (game action tie-in)

Each kind corresponds to a concrete game or diplo action. The resolver (or AI) emits a dialogue point when the condition for that kind is met; the player’s response is translated into an **outcome** that the game applies.

| Kind | When / condition | Blocking | Outcome type | Reference |
|------|------------------|----------|--------------|-----------|
| **overture_target_response** | Human GP is target of an Establish Overture; turn resolution during Diplomacy phase. | Yes | OvertureDecision (accept/reject per offer) | [diplomacy.md](../game/diplomacy.md), [diplomacy-resolution.md](../program/diplomacy-resolution.md) |
| **intervention_choice** | Human GP has Embassy or purchased land in Minor/Tribe; another GP declared war on that Minor/Tribe in the Diplomacy phase. | Yes | InterventionDecision (triple + InterventionChoice) | [diplomacy.md](../game/diplomacy.md) § Intervention |
| **alliance_offer_response** | Human GP receives alliance proposal from another GP; must accept or refuse. | Yes | AllianceDecision (accept / refuse) | [diplomacy.md](../game/diplomacy.md) § Alliances |
| **dialogue_flavour** | AI emits a DialogueEvent that does not require a choice (commentary, declaration, event reaction). | No | None (dismiss only) | [dialogue-and-mood.md](dialogue-and-mood.md) |
| **game_start_intro** | First time the player enters the in-game screen after creating or loading a game. | Yes (UI block) | None (dismiss only) | This document § First dialogue emission point |

Additional kinds (e.g. **join_empire_offer_response**, **ultimatum_response**) may be added in later phases; each must define condition, blocking, and outcome type in the program spec.

---

## First dialogue emission point

The **first** point at which a dialogue event is generated is **game start**: when the player is about to begin play (after creating a new game or loading a save), the app must show a **game_start_intro** dialogue **before** any game interaction is allowed.

- **Condition:** The in-game screen has just been entered (first time in this session for this game). New game and load game both trigger it.
- **Content:** Archaic language. The message states that the **age of imperialism is rapidly approaching** and **challenges the player to usher in glory for their nation**. Exact wording is in dialogue content assets and [dialogue-content-and-yarn.md](dialogue-content-and-yarn.md).
- **Blocking:** The player must dismiss the message (e.g. "Begin" or "I shall") before the game can start; no orders, end turn, or other game actions are available until dismissed.
- **Outcome:** None; dismiss only. No resume API; this is a UI-level block only.

---

## Conditions (where in the game)

- **overture_target_response:** During **turn resolution**, **Diplomacy phase**, when processing Establish Overture orders whose target is a human-controlled Great Power. One dialogue point per pending offer (or one combined point with multiple offers per existing contract).
- **intervention_choice:** During **turn resolution**, **Diplomacy phase**, after a Great Power’s `Declare War` on a Minor/Tribe is applied, for each human GP (other than the aggressor) with Embassy or purchased land in that Minor/Tribe. One dialogue point per pending **InterventionPrompt**.
- **alliance_offer_response:** During **turn resolution**, **Diplomacy phase**, when an alliance proposal targets a human-controlled GP. One dialogue point per proposal.
- **dialogue_flavour:** When AI emits a **DialogueEvent** during order generation or resolution; may be shown at end-of-phase, in a notification area, or when the player opens a relevant screen. No turn block.
- **game_start_intro:** When the app has just navigated to the in-game screen after creating a new game or loading a save; once per game session (or once per game id, as defined by the client). No turn resolution; emitted by the client when transitioning to in-game.

Conditions are evaluated deterministically from game state and phase; same state and phase produce the same set of dialogue points.

---

## Blocking vs non-blocking

- **Blocking:** Turn resolution **suspends** until the app has presented the dialogue, collected the player’s response(s), and called the **resume** API with the corresponding outcome(s). The resolver then continues.
- **Non-blocking:** Dialogue is shown for information or atmosphere; the player may dismiss without making a game-affecting choice. No resume API; game flow does not wait.

Only dialogue points with a defined **outcome type** and a resume contract are blocking. **dialogue_flavour** is always non-blocking.

---

## Presentation mode

The **dialogue point** carries a **presentation mode** so the client can choose how to show it. Mode is chosen per **kind** or per **content key** (see dialogue-content-and-yarn.md); no per-event override in the first version.

| Mode | Meaning | App (Flutter/Flame) |
|------|---------|---------------------|
| **modal** | Full attention; blocks view until dismissed or choice made. | Full-screen or modal dialog (e.g. CtDialogShell); Jenny dialogue view. |
| **overlay** | Shown over the game (e.g. corner or centre); player can continue to look at the world. | Flame overlay (e.g. dialogue box over map); Jenny in a compact panel. |

- **Blocking** dialogue points use **modal** by default so the player cannot miss them. Ruleset or content config may allow **overlay** for blocking in special cases.
- **Non-blocking** dialogue may use **overlay** (e.g. toast or small dialogue box) or **modal** (e.g. “News from …” popup). Configurable per content key or kind.

Implementation: [dialogue-system.md](../program/dialogue-system.md) defines the payload; [dialogue-presentation.md](../ui/dialogue-presentation.md) defines how the app interprets the mode.

---

## Acceptance criteria

- **Given** the Diplomacy phase is running and an Establish Overture order targets a human-controlled GP, **when** the resolver evaluates overture offers, **then** the system emits a blocking dialogue point of kind **overture_target_response** with payload sufficient to build OvertureDecision(s), and turn resolution suspends until the app calls the resume API with those decisions.
- **Given** the Diplomacy phase has applied a Great Power’s declaration of war on a Minor or Tribe and a human GP has an intervention trigger (Embassy or purchased land), **when** the resolver evaluates intervention, **then** the system returns **TurnResolutionPendingIntervention** (or equivalent blocking result) with payload sufficient to build **InterventionDecision** row(s), and resolution suspends until the app calls **resumeTurnResolutionWithInterventionDecisions**.
- **Given** a dialogue point has **blocking** true, **when** the app presents it, **then** the app uses the **modal** presentation mode unless configured otherwise, and does not advance game state until the player has responded and the resume API has been called.
- **Given** a dialogue point has **blocking** false (e.g. **dialogue_flavour**), **when** the app presents it, **then** the app may use overlay or modal per config, and no resume API is invoked; game flow does not wait.
- **Determinism:** Given the same game state and phase, the set of dialogue points emitted (kind, count, payloads) is identical across runs; only the player’s choices affect subsequent state.
