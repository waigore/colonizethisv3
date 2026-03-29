# Pending intervention (ctterm)

**SPEC/tui** — Dedicated screen when `resolveTurnForGame` returns `TurnResolutionPendingIntervention`. Mirrors [pending-overtures.md](pending-overtures.md) and [pending-call-to-arms.md](pending-call-to-arms.md). Program contract: [dialogue-system.md](../../program/dialogue-system.md).

---

## Responsibility

Block the TUI until the human submits one choice per `InterventionPrompt`, then call **`resumeTurnResolutionWithInterventionDecisions`** with the same `Game`, `Orders`, topology, and tile maps as the pending call. **No Yarn runtime** in ctterm; copy is **static archaic English** aligned with [dialogue-content-and-yarn.md](../../ai/dialogue-content-and-yarn.md) (same meaning as app Yarn; TUI resolves from inline strings per TUI dialogue spec).

---

## Route

- **Enum:** `CttermRoute.pendingIntervention`.
- **Screen ID:** `100022` (see [ctterm.md](../ctterm.md)).

---

## Layout

- Title: e.g. `War and intervention`.
- Body: explain that a GP has attacked a Minor/Tribe where the player has interest; list each prompt with **aggressor / defender / your power** display names from `Game`.
- Per row: current choice **Intervene / Do naught / Protest** (one active row).
- Keys: **[I]** Intervene **[O]** Do naught **[P]** Protest **[Up/Down]** select row **[Enter]** submit all.

---

## Navigation

- **Shell** does not map Escape on this route to in-game shell (blocking, same as pending overtures).
- **App state:** `ctterm_app` holds `List<InterventionPrompt>?` and navigates here from `onEndTurn` or from resume chains when the next pending type is intervention.

---

## Acceptance criteria

- Given `resolveTurnForGame` returns `TurnResolutionPendingIntervention` with N prompts, when the shell runs end-turn, then the app navigates to `pendingIntervention` and stores the updated `Game` plus the prompt list.
- Given the user presses Enter with valid per-row choices, when `onInterventionDecisions` runs, then the app calls `resumeTurnResolutionWithInterventionDecisions` with N `InterventionDecision` rows matching the prompts.
- Given resume returns `TurnResolutionPendingOvertures` or `TurnResolutionPendingCallToArms`, when the app handles the result, then the app navigates to the corresponding pending route and clears intervention state.
