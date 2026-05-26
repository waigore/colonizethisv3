# Pending intervention overlay (Flutter)

**Screen ID:** `OVL50001` — stable; do not reassign.
**SPEC/ui** — Blocking turn-resolution UI when `TurnResolutionPendingIntervention` is returned. Technical contract: [dialogue-system.md](../../program/dialogue-system.md). Yarn keys: [dialogue-content-and-yarn.md](../../ai/dialogue-content-and-yarn.md). Event bus: [app-event-bus.md](../../program/app-event-bus.md).

**Mockup:** [../mockups/OVL50001-pending-intervention-overlay.html](../mockups/OVL50001-pending-intervention-overlay.html)
---

## Responsibility

Present **all** `InterventionPrompt` rows for the current pending batch before the turn advances. Copy is **Jenny + Yarn** (archaic register, aligned with game-start intro). After each player choice, show a short **aggressor reaction** line (positive/neutral/negative tone per choice). On completion, the orchestration layer calls `GameService.resumeInterventionDecisions` with a matching `List<InterventionDecision>`.

---

## State ownership

- **Riverpod:** A single `pendingDiplomacyProvider` holds **at most one** blocking diplomacy gate (`overtures` \| `intervention` \| `call_to_arms`). See [pending-diplomacy-state.md](../pending-diplomacy-state.md).
- **GameScreen** watches that provider and stacks **one** blocking overlay. No cross-panel callbacks; optional `InterventionRequiredEvent` is informational only (tests / future listeners).

---

## Layout (modal)

- **Frame:** `CtDialogShell` centered over the game; `Material` scrim `Colors.black54`.
- **Phases:** (1) Yarn intro node — line(s) + Continue; (2) Per prompt: Yarn situation node (variables: aggressor, defender, intervening names) + Continue; (3) Three `CtNinePatchButton` actions: **Intervene**, **Do naught**, **Diplomatic protest** → map to `InterventionChoice`; (4) Yarn reaction node for that choice + Continue; repeat until all prompts decided; (5) implicit submit — parent receives full `InterventionDecision` list.

---

## Yarn nodes (app)

| Node | Role |
|------|------|
| `DialoguePoint/intervention_intro` | Opening; archaic; sets tone. |
| `DialoguePoint/intervention_situation` | Per-prompt context; uses `{$aggressorName}`, `{$defenderName}`, `{$interveningName}`. |
| `DialoguePoint/intervention_reaction_intervene` | Hostile / negative aggressor tone. |
| `DialoguePoint/intervention_reaction_do_nothing` | Dismissive / neutral tone. |
| `DialoguePoint/intervention_reaction_protest` | Cold formal / restrained negative tone. |

Variables are set on `YarnProject.variables` before `startDialogue`.

---

## Widgetbook

- **Use case:** `InterventionDialogueOverlay` with `skipIntroForTest: true`, one synthetic prompt, placeholder `Game` with matching player/minor ids, dark colonial theme.

---

## Acceptance criteria

- Given `pendingDiplomacyProvider` holds `PendingDiplomacyInterventionState` with N prompts, when the overlay mounts, then the UI layer runs the intro Yarn node before showing the first prompt’s situation and choices.
- Given the player has selected a choice for prompt k, when the reaction Yarn node finishes, then the UI layer either advances to prompt k+1 or, if k+1 == N, invokes the callback with N `InterventionDecision` values whose triples match the prompts and whose `InterventionChoice` values match the selections.
- Given Yarn fails to load, when the overlay is shown, then the UI layer shows an error affordance and still allows submitting decisions (degraded path) so the player is not soft-locked.
- Given turn resolution returns a different pending type after intervention resume, when the parent applies the result, then `pendingDiplomacyProvider` reflects only the new pending type (never two kinds at once).
