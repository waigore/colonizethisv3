# Dialogue Presentation (ctterm / TUI)

**SPEC/tui** — How ctterm presents AI–human dialogue points. Same dialogue model and contract as the Flutter app. Dialogue model: [dialogue-management.md](../ai/dialogue-management.md). Content: [dialogue-content-and-yarn.md](../ai/dialogue-content-and-yarn.md). Technical contract: [dialogue-system.md](../program/dialogue-system.md). Screen IDs: [ctterm.md](ctterm.md) § Screen IDs.

---

## Responsibility

ctterm presents **PendingDialoguePoint**s from the same contract as the app. It does **not** use Jenny or Yarn; it resolves **contentKey** and payload **variables** via **data assets** (localized strings) and shows **text + choice list**. On selection, ctterm calls the **same resume API** (e.g. resumeTurnResolutionWithOvertureDecisions) with the same outcome types so game behaviour is identical to the app.

---

## Presentation

- **Modal (blocking):** A **dedicated screen** (e.g. Pending Overtures 100019, or a generic “Dialogue” screen 100021). Title, body text, and a list of choices. Keyboard: Up/Down to move selection, Enter to submit; shortcut keys (e.g. A/R for Accept/Reject) where defined. No Escape to back out of blocking dialogue; the user must submit a choice to proceed.
- **Overlay (non-blocking):** Status area or inline panel showing the message and a single “Dismiss” or “Continue” action. Optional; if space is limited, non-blocking dialogue may be shown in the same full-screen dialogue layout but with no turn block.

---

## Content resolution

- **contentKey** (e.g. `DialoguePoint/overture_target_response/embassy`) is used to look up:
  - Title and body text (with variable substitution: offererName, stage, province, etc.).
  - Ordered list of choices; each choice has a **label** (e.g. “Accept”, “Reject”) and an **outcome id** (e.g. accept, reject) that maps to the correct DialogueOutcome.
- Data source: same ruleset/localization data as used for DialogueEvent resolution, or a dedicated dialogue table keyed by contentKey. No Yarn runtime; only string lookup and substitution. Province ids in variables are **prefixed** per world-model-identity.

---

## Screens and routing

- **Pending Overtures (100019):** Current screen for TurnResolutionPendingOvertures. Becomes the **modal dialogue screen** for dialogue points of kind **overture_target_response**. Content is derived from pendingOvertures (offerer, target, stage); choices are Accept/Reject per offer; on Submit, ctterm calls resumeTurnResolutionWithOvertureDecisions. See [pending-overtures.md](screens/pending-overtures.md).
- **Generic dialogue screen (optional):** For other blocking kinds (intervention_choice, alliance_offer_response), ctterm may use the same screen ID with different content, or a new screen ID (e.g. 100021 “Dialogue”). Same pattern: title, body, choices, submit → resume API.
- **Non-blocking:** Shown in status line, event log, or a small overlay panel; log prefix `tui:dialogue:` per ctterm logging rules.

---

## Keyboard and accessibility

- **Blocking dialogue:** Up/Down (or W/S) to change selection; Enter to submit; optional letter shortcuts (A/R, I/D/P for intervention). No Escape to cancel; must submit.
- **Non-blocking:** Enter or Space to dismiss; optional key to focus the message area.

---

## Acceptance criteria

- **Given** turn resolution returns TurnResolutionPendingOvertures, **when** ctterm navigates to the Pending Overtures screen, **then** the screen shows title and body resolved from the dialogue contentKey and variables (offerer name, stage), and a list of choices (Accept/Reject) per offer; on Submit, ctterm calls resumeTurnResolutionWithOvertureDecisions with the selected OvertureDecision(s).
- **Given** a PendingDialoguePoint of kind **intervention_choice**, **when** ctterm presents it, **then** the TUI shows resolved text and choices (Intervene, Do Nothing, Diplomatic Protest); on selection, ctterm calls the intervention resume API with the corresponding InterventionChoice.
- **Given** a non-blocking dialogue point (dialogue_flavour), **when** ctterm presents it, **then** the TUI may show it in the event feed or a dismissible overlay; no resume API is called.
- **Same contract:** The outcome objects (OvertureDecision, InterventionChoice, etc.) passed to the resume API by ctterm are identical in shape and meaning to those from the Flutter app so that logic behaviour is identical.
- **Logging:** Dialogue presentation and resume actions use the `tui:dialogue:` (or `tui:game:`) prefix per [ctterm.md](ctterm.md) and [ctdev-logging.md](../program/ctdev-logging.md).
