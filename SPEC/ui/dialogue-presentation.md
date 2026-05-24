# Dialogue Presentation (Flutter / Flame)

**SPEC/ui** — How the Flutter app presents AI–human dialogue using Flame and Jenny. Dialogue model: [dialogue-management.md](../ai/dialogue-management.md). Content: [dialogue-content-and-yarn.md](../ai/dialogue-content-and-yarn.md). Technical contract: [dialogue-system.md](../program/dialogue-system.md). Pixel-art catalog: [pixel-art-ui-catalog.md](pixel-art-ui-catalog.md). Jenny adapter contract: [ct-dialogue-view.md](ct-dialogue-view.md). Per-overlay specs: [game-start-intro-overlay.md](game-start-intro-overlay.md), [overture-dialogue-overlay.md](overture-dialogue-overlay.md), [call-to-arms-dialogue-overlay.md](call-to-arms-dialogue-overlay.md), [screens/pending-intervention-overlay.md](screens/pending-intervention-overlay.md), [pending-diplomacy-state.md](pending-diplomacy-state.md).

---

## Responsibility

The app presents **PendingDialoguePoint**s from the dialogue system. It uses **Jenny** (Flame’s Yarn-based dialogue module) for scripted lines and options, and the project’s **pixel-art catalog** (CtDialogShell, CtNinePatchButton) for framing. Presentation **mode** (modal vs overlay) is determined by the dialogue point’s presentationMode and blocking flag.

---

## Stack

- **Flame:** Game world and overlays. Dialogue is shown as a Flame **component** or **overlay** so it integrates with the game loop and can sit over the map/HUD.
- **Jenny:** DialogueRunner + DialogueView (or equivalent). Loads `.yarn` assets; runs nodes keyed by contentKey; handles lines and options; invokes custom commands when the player picks an option so the app can map to **DialogueOutcome** and call the resume API.
- **Flutter (shell):** Where a full-screen or modal is required, the dialogue may be presented in a Flutter route or overlay that uses **CtDialogShell** and CtNinePatchButton for consistency with the rest of the UI.

---

## Modal presentation

- **When:** dialogue point has `presentationMode == 'modal'` or `blocking == true` (default to modal).
- **How:** Full-screen or large modal that captures focus until the player makes a choice (or dismisses for non-blocking flavour). Use **CtDialogShell** as the frame; interior shows Jenny’s DialogueView (speaker, line text, option buttons built with **CtNinePatchButton** or equivalent).
- **Placement:** Centred over the game view or over the main app shell; no game interaction until dismissed. Blocking dialogue must be impossible to miss (no tiny corner popup).

---

## Overlay presentation

- **When:** dialogue point has `presentationMode == 'overlay'` and optionally `blocking == false`.
- **How:** A compact dialogue panel (e.g. bottom or side of the screen) over the game world, using CtDialogShell and pixel-art buttons. Jenny runs in a reduced form (single line + options) or the app renders from resolved content without full Yarn for very short messages. Player may continue to view the map; for blocking overlay (if ever used), the overlay still must collect a choice before proceeding.
- **Use case:** Non-blocking flavour dialogue, or optional “news” style messages that don’t block turn resolution.

---

## Jenny integration

- **Assets:** `.yarn` files under `assets/dialogue/` (or path defined in TDD). Loaded by the DialogueRunner in Flame’s `onLoad` or when the dialogue system initializes.
- **Node selection:** When a PendingDialoguePoint is received, the app maps **contentKey** to a Yarn **node name** (see dialogue-content-and-yarn.md). Set **variables** (offererName, stage, province, era) on the runner from the payload, then start the node.
- **Options → outcome:** When the player selects an option, Jenny runs a custom command or the app’s DialogueView handler maps the selection to the correct **DialogueOutcome** (e.g. OvertureDecision, InterventionChoice) and calls the **resume API**. No game state is changed in the UI layer; only the outcome is passed to logic.
- **Flavour (no choice):** For `dialogue_flavour`, the node may have a single “Continue” or “Dismiss” option that closes the dialogue without calling any resume API.

---

## Component structure

- **Dialogue overlay / modal component:** Owns the DialogueRunner and a view that displays the current line and options. Receives PendingDialoguePoint(s); starts the appropriate node; on option selected, emits outcome to the game/orchestration layer which calls the resume API. Built from CtDialogShell and catalog components; no Material dialog widgets.
- **Placement:** Managed by the game screen or a top-level orchestrator that decides modal vs overlay based on presentationMode and blocking. When turn resolution returns TurnResolutionPendingOvertures, the orchestrator converts to PendingDialoguePoint(s) and shows the dialogue (modal) until the user submits OvertureDecisions.
- **Pending diplomacy state:** The app uses a **single** Riverpod notifier for at most one blocking gate (overtures, intervention, or call to arms); see [pending-diplomacy-state.md](pending-diplomacy-state.md). `GameScreen` shows one overlay according to that state.

---

## Acceptance criteria

- **Given** a blocking dialogue point (e.g. overture_target_response), **when** the app presents it, **then** the app shows a **modal** dialogue (CtDialogShell) with Jenny-driven content (node from contentKey), and the player cannot proceed until they select an option that triggers the resume API with the correct outcome type.
- **Given** a non-blocking dialogue point with presentationMode **overlay**, **when** the app presents it, **then** the app may show a compact overlay (CtDialogShell or equivalent) over the game; dismissing or selecting “Continue” does not call the resume API; game flow is not blocked.
- **Given** the player selects “Accept” (or “Reject”) in an overture dialogue, **then** the app calls **resumeTurnResolutionWithOvertureDecisions** with an OvertureDecision list matching the selection(s); no Material AlertDialog or Dialog is used.
- **Pixel-art:** All visible dialogue chrome (frame, buttons) uses CtDialogShell and CtNinePatchButton (or catalog equivalents) per [pixel-art-ui-catalog.md](pixel-art-ui-catalog.md).
