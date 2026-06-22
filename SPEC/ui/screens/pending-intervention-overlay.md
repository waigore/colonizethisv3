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

- **Frame:** `CtDialogShell` centered over the game. The scrim + centered-shell scaffold itself follows the canonical [`CtFullScreenDialogueShell` component spec](../components/ct-full-screen-dialogue-shell.md), shared with the overture, call-to-arms, and game-start intro overlays (Refs #2914 S2 / S9).
- **Scrim:** `Material` color resolves to the canonical dark-theme dialog scrim token `EditorialMonoclePalette.dialogScrim` (`oklch(8% 0.01 30 / 0.70)` per `SPEC/ui/pixel-art-ui-catalog.md` § Dialog scrim). Hard-coded `Colors.black54` is a regression and forbidden — issue #2867 R1 (universal dialog pattern) and #2858 § Dialog scrim. The scrim token applies to every phase below (intro, situation, choice, reaction, degraded error).
- **Chrome header (every phase):** Each `CtDialogShell` column is preceded by a small fixed header band rendered in this order:
  1. `Text` widget with the localized `Pending Intervention` title (l10n key `game_intervention_overlayTitle`) styled in `EditorialMonoclePalette.accent` with `letterSpacing = fontSize × 0.05` (canonical 0.05em per #2867 R2). The title `Text` carries the stable key `ValueKey<String>('interventionOverlayTitle')` so widget tests can locate it without matching localized strings.
  2. `SizedBox(height: 8)` gap.
  3. `CtBrassDivider` carrying the stable key `ValueKey<String>('interventionOverlayBrassDivider')` (#2867 R26b).
  4. `SizedBox(height: 12)` gap before the phase-specific body.
  - The header band MUST render on every phase of the overlay, including the degraded error panel, the Yarn-loading state, every Yarn line/choice page, every per-prompt situation page, every choice picker, and every aggressor reaction page. This guarantees the player always sees the dialog identity and a brass-trimmed visual anchor regardless of which sub-state is on screen.
- **Phases:** (1) Yarn intro node — line(s) + Continue; (2) Per prompt: Yarn situation node (variables: aggressor, defender, intervening names) + Continue; (3) Three `CtNinePatchButton` actions: **Intervene**, **Do naught**, **Diplomatic protest** → map to `InterventionChoice`; (4) Yarn reaction node for that choice + Continue; repeat until all prompts decided; (5) implicit submit — parent receives full `InterventionDecision` list.
  - Every Yarn line/choice page (phases 1, 2, 4) is rendered by the shared `CtDialogueLineChoiceBody` ([`../ct-dialogue-view.md`](../ct-dialogue-view.md) § Combined line+choice presentation): when a node's `-> Continue` choice step is presented, the immediately preceding narrative line (the retained `contextLine`) stays visible above the `Continue` button instead of disappearing into an option-only step (Refs #3628). In a multi-line node (the intro), only the line immediately preceding the choice accompanies it.
- **Choice-button styling (#2867 R26b):** Differentiated emphasis so the player reads the affordance at a glance. **Intervene** uses default primary `CtNinePatchButton` chrome. **Diplomatic protest** and **Do naught** use `CtNinePatchButton.mutedVariant: true` (secondary). No choice button uses `dangerVariant` (reserved for declare-war / exit flows). All three keep the canonical 48 dp tap-target and engraved-label drop-shadow contract; the muted token contract lives in [`pixel-art-ui-catalog.md`](../pixel-art-ui-catalog.md) § *CtNinePatchButton* (Muted variant).

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

### Dark editorial-monocle chrome (#2867 S9)

- Given the intervention overlay mounts in any phase (Yarn loading, Yarn line, Yarn choice, situation, choice picker, reaction, or degraded error), when the widget tree is inspected, then The UI layer finds exactly one `Material` descendant wrapping the centered `CtDialogShell` whose `color` resolves to `EditorialMonoclePalette.dialogScrim` and zero `Material` descendants wrapping the centered `CtDialogShell` whose `color == Colors.black54`.
- Given the intervention overlay's Yarn-loading panel is on screen, when the widget tree is inspected, then The UI layer finds exactly one `Text` widget keyed by `ValueKey<String>('interventionOverlayTitle')` whose `data == AppLocalizations.game_intervention_overlayTitle` and whose resolved `TextStyle.color == EditorialMonoclePalette.accent`, and exactly one `CtBrassDivider` keyed by `ValueKey<String>('interventionOverlayBrassDivider')` rendered below the title.
- Given the intervention overlay shows the per-prompt choice picker (Intervene / Do naught / Diplomatic protest), when the widget tree is inspected, then The UI layer finds exactly one `Text` keyed by `ValueKey<String>('interventionOverlayTitle')` with `style.color == EditorialMonoclePalette.accent` and exactly one `CtBrassDivider` keyed by `ValueKey<String>('interventionOverlayBrassDivider')` above the three `CtNinePatchButton` choice rows.
- Given the intervention overlay falls back to the degraded error panel because Yarn failed to load, when the widget tree is inspected, then The UI layer still finds the keyed title `Text` and `CtBrassDivider` so the error panel reads as the same dialog identity.
- Given the title `Text` keyed `ValueKey<String>('interventionOverlayTitle')` is mounted, when its resolved `TextStyle` is read, then `style.letterSpacing == (style.fontSize ?? 16) * 0.05` exactly (no hard-coded literal value separate from `fontSize`) so the canonical 0.05em letter-spacing per #2867 R2 scales with theme `titleMedium` overrides.

### Choice-button styling (#2867 R26b)

- Given the per-prompt choice picker is on screen, when the picker tree is inspected, then exactly one `CtNinePatchButton` (Intervene) has `dangerVariant: false` AND `mutedVariant: false`, exactly two (Do naught, Diplomatic protest) have `mutedVariant: true` AND `dangerVariant: false`, and zero have `dangerVariant: true`.

### 320 dp viewport pin (#2870 S8 / S10)

- Given an `InterventionDialogueOverlay` is mounted at `kMinViewportWidth × 640` (320 × 640 dp) with one `InterventionPrompt` and a failing asset bundle (forcing the degraded error panel) so the overlay routes deterministically through its shared `_buildScrimmedShell` chrome helper, when the widget tree settles, then `WidgetTester.takeException()` is `null` (no `RenderFlex` overflow exception escapes the framework — the same contract pinned by `dialogs_320dp_min_viewport_test.dart`, `overture_dialogue_overlay_320dp_min_viewport_test.dart`, and `call_to_arms_dialogue_overlay_320dp_min_viewport_test.dart`), the keyed `Pending Intervention` title (`ValueKey<String>('interventionOverlayTitle')`) and `CtBrassDivider` (`ValueKey<String>('interventionOverlayBrassDivider')`) chrome anchors render, and the localized `game_intervention_loadError` body line plus `game_intervention_continue` action label render end-to-end inside the centered `CtFullScreenDialogueShell` + `CtDialogShell` content column. Because every phase of the overlay (Yarn loading, Yarn line, Yarn choice, situation, choice picker, reaction, degraded error) composes its body inside the same `_buildScrimmedShell` helper above the same title + brass-divider header, this single positive pin proves the 320 dp chrome contract for every phase (`SPEC/ui/mobile-adaptation.md` § 7).
