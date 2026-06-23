# Overture Dialogue Overlay

**Screen ID:** `OVL30001` — stable; do not reassign.
**SPEC/ui** — Blocking overlay for pending overture offers before the turn advances. Implementation: `app/lib/features/game/dialogue/overture_dialogue_overlay.dart`.
**Widgetbook:** `Overture Dialogue Overlay` → `app/lib/widgetbook/catalog.dart`. Provider: [`pending-diplomacy-state.md`](pending-diplomacy-state.md). Host: [`game-screen.md`](game-screen.md). Asset: `kDialogueOvertureAsset`.

**Mockup:** [mockups/OVL30001-game-overture-overlay.html](mockups/OVL30001-game-overture-overlay.html)
---

## Widget contract

`OvertureDialogueOverlay` is a `StatefulWidget` (`app/lib/features/game/dialogue/overture_dialogue_overlay.dart`). It wraps an arbitrary `child` and, while the overture flow is running, paints a dim scrim plus a centered `CtDialogShell` on top of that child.

| Constructor parameter | Type | Required | Description |
|-----------------------|------|----------|-------------|
| `game` | `Game` | yes | Active game state, used to resolve `offererGpId -> displayName` for offer rows via `Player.displayName` (falls back to the id when no player matches). |
| `pendingOvertures` | `List<OvertureOffer>` | yes | One or more pending overtures targeting the human-controlled faction. The list length defines the number of Accept/Reject rows rendered in phase 2 and the initial size of the per-offer `_accepted` toggle list. |
| `onDecisions` | `void Function(List<OvertureDecision>)` | yes | Invoked exactly once when the player taps **Submit**, with one `OvertureDecision` per input `OvertureOffer`, preserving order. Consumers forward decisions to `service.resumeOvertureDecisions(...)`. |
| `child` | `Widget` | yes | The underlying screen content; remains mounted while the overlay is presented so host route state is preserved across the dialogue. |
| `logger` | `CtLogger?` | no | Optional logger override; defaults to `packageLogger('dialogue')`. |
| `skipIntroForTest` | `bool` | no, default `false` | Test seam that bypasses the Yarn asset load and jumps straight to the offer list. Production code (including `GameScreen`) must leave this `false`. |

Internal state ownership (phase 1 — intro):

- Owns at most one `CtDialogueView` and one `jenny.DialogueRunner` during the Yarn intro phase.
- Reads the Yarn source from `kDialogueOvertureAsset` (`assets/dialogue/overture.yarn`) via `rootBundle`; the asset bundle is not configurable in production but the intro itself can be bypassed with `skipIntroForTest`.
- Hard-codes the intro node id `DialoguePoint/overture_target_response`; throws a `StateError` (caught and surfaced as `_loadError`) when the node is missing from the parsed asset.
- Maintains `_accepted: List<bool?>` (default `null` for every entry — i.e. undecided) — one entry per pending overture — toggled by the row-level Accept and Reject buttons in phase 2. Accept tap sets the entry to `true`; Reject tap sets it to `false`. Per issue #2867 R23 the Submit button stays disabled until **every** entry is non-null.

---

## Trigger conditions

- **Entry:** Rendered by `GameScreen` when `pendingDiplomacyProvider` exposes `PendingOvertures(offers)` (see [`pending-diplomacy-state.md`](pending-diplomacy-state.md) and [`game-screen.md`](game-screen.md)). The notifier is replaced wholesale on each turn-resolution result, so a single overlay instance handles all offers for one resume cycle.
- **Asset load:** During `initState`, when `skipIntroForTest == false`, the widget starts an async `_loadAndRunIntro()` flow that (1) loads the Yarn asset text via `rootBundle.loadString`, (2) parses the `YarnProject`, (3) verifies the `DialoguePoint/overture_target_response` node exists, (4) constructs the `CtDialogueView`, (5) starts the `DialogueRunner` on the overture node, and (6) on `runner.startDialogue` resolution sets `_introDone = true`.
- **Failure:** Any throw inside `_loadAndRunIntro` (asset missing, parse error, node missing) is logged with `level == error` (including stack trace) and stored in `_loadError`, which switches the build into the error variant.
- **Dismissal:** Exclusively driven by the player tapping **Submit** in the phase-2 form (or **Continue** on the error affordance). The overlay does not auto-dismiss when `_introDone` flips; it transitions to phase 2 and waits for player input.

---

## Layout / wireframe

```text
+-----------------------------------------------------------+
| Stack                                                     |
|   widget.child                                            |
|   Material(color: EditorialMonoclePalette.dialogScrim)    |
|     Center                                                |
|       CtDialogShell(maxWidth: 520, maxHeight: 500*)       |
|         Padding(all: 20)                                  |
|           Column(mainAxisSize: min)                       |
|             -- phase 1: presenting line --                |
|             Text(line.text, bodyLarge)                    |
|             SizedBox(height: 16)                          |
|             Align(centerRight)                            |
|               CtNinePatchButton(Continue)                 |
|             -- phase 1: presenting choice --              |
|             ListView of                                   |
|               CtNinePatchButton(option.text)              |
|             -- phase 1: transient / loading --            |
|             CtLoadingIndicator                            |
|             -- phase 2: offer list --                     |
|             Text(game_overture_title, titleMedium,        |
|                  --accent, letter-spacing 0.05em)         |
|             CtBrassDivider                                |
|             Text(game_overture_intro, bodyMedium,         |
|                  --muted, italic)                         |
|             ListView.builder (shrinkWrap, no scroll)      |
|               Column(crossAxisAlignment: stretch) -- per offer
|                 Row(                                      |
|                   Text(offerer, --accent),                |
|                   Text(": ", --muted),                    |
|                   Text(stage, --muted)                    |
|                 )                                         |
|                 Wrap(alignment: end, spacing: 12)         |
|                   Row(CtToggleSwitch(--success glow)      |
|                       + Text(game_overture_accept))       |
|                   Row(CtToggleSwitch(--danger  glow)      |
|                       + Text(game_overture_reject))       |
|             Align(centerRight)                            |
|               CtNinePatchButton(game_callToArms_submit)   |
+-----------------------------------------------------------+
*phase 1 uses `maxWidth: 520` only; phase 2 also sets
 `maxHeight: 500` so the shell stays bounded with long lists.
```

Phase 2 chrome uses the dark editorial-monocle tokens from `SPEC/ui/pixel-art-ui-catalog.md` § Editorial-monocle palette (also referenced by issue #2867 R2 and R21–R22):

- **Scrim:** All three rendered states (phase 1 line/choice/loading, phase 2 offer list, error) wrap the centered `CtDialogShell` in `Material(color: EditorialMonoclePalette.dialogScrim)`, the canonical `--dialog-scrim` token (`oklch(8% 0.01 30 / 0.70)` per `SPEC/ui/pixel-art-ui-catalog.md` § Dialog scrim and `SPEC/ui/dialog-scrim.md` if present). The legacy `Colors.black54` Material fallback MUST NOT appear in the overlay subtree (#2867 R1 / #2858 § Dialog scrim).
- **Title row:** `Text(game_overture_title)` rendered with `theme.textTheme.titleMedium` color overridden to `EditorialMonoclePalette.accent` and `letter-spacing == fontSize * 0.05` so the canonical `0.05em` letter-spacing resolves at any text scale.
- **Title → intro separator:** A `CtBrassDivider` is rendered between the title row and the intro `Text` per #2867 R21 (no extra padding inside the divider; vertical breathing room is supplied by 8 dp `SizedBox`es above and below).
- **Intro line:** `Text(game_overture_intro)` rendered with `theme.textTheme.bodyMedium` color overridden to `EditorialMonoclePalette.muted` and `fontStyle: FontStyle.italic` per #2867 R5.
- **Offer row label:** The offerer name and stage label are split into two `Text` widgets within a flex row so they can carry distinct colors (#2867 R22). The offerer name renders in `EditorialMonoclePalette.accent`; the stage label renders in `EditorialMonoclePalette.muted`. A `Text(": ")` separator (also `--muted`) keeps the formatted line readable. The full `game_overture_offerLine` localized template is no longer composed in the widget — the per-offer row composes the two parts directly.
- **Accept / Reject toggles (#2867 R22):** Each per-offer body renders the decision controls as two mutually exclusive `CtToggleSwitch` widgets — one labeled Accept (`game_overture_accept`) and one labeled Reject (`game_overture_reject`). The Accept toggle passes `onGlowColor: EditorialMonoclePalette.success` so its on-state knob halo paints the canonical `--success` glow; the Reject toggle passes `onGlowColor: EditorialMonoclePalette.danger` so its on-state knob halo paints `--danger`. The labels beside each toggle render in the matching palette token (`--success` for Accept, `--danger` for Reject) using `theme.textTheme.bodySmall`. Toggling is tristate-aware: tapping a currently-off toggle commits the row's `_accepted[i]` slot to `true` (Accept) or `false` (Reject) and turns the opposite toggle off via the shared state slot; tapping a currently-on toggle reverts the row to `null` (undecided) so the #2867 R23 Submit gate re-engages. Toggle keys are stable for tests: `overtureAcceptToggle_<i>` and `overtureRejectToggle_<i>` per row index `i`.
- **Offer row layout (stacked at narrow widths):** Each per-offer body is a `Column(crossAxisAlignment: stretch)` containing the labels `Row` above an end-aligned `Wrap(alignment: WrapAlignment.end, spacing: 12, runSpacing: 8)` that holds the two labeled `CtToggleSwitch` rows (Accept-side + Reject-side). The stacked `Column(Row + Wrap)` mirrors `SPEC/ui/call-to-arms-dialogue-overlay.md` § Layout / wireframe so the two toggle rows flow onto a second run at narrow viewports (`kMinViewportWidth` 320 dp) instead of overflowing horizontally, and the labels `Row` always has the full content column width to wrap on (issue #2870 S8 / S10; `SPEC/ui/mobile-adaptation.md` § 7).

Error mode renders the same `Stack` but the `CtDialogShell` body is the localized error message (`l10n.game_overture_loadError`) plus a single Continue button (`l10n.game_intervention_continue`).

---

## States and variants

| State | Trigger | Render |
|-------|---------|--------|
| Loading (phase 1) | `!_introDone && _loadError == null && _view == null` | `Stack` with `widget.child`, scrim, and `CtLoadingIndicator` inside `CtDialogShell`. |
| Presenting combined line+option (phase 1) | `!_introDone && _view!.currentLine != null && _view!.pendingSingleOptionLabel != null` (the overture intro: one line then `-> Continue`) | Intro line text + **one** right-aligned `CtNinePatchButton` labelled with the Yarn option text (`Continue`); tap calls `_view!.confirmCombinedLineOption()`, advancing the line and selecting the sole option in one action. Rendered via the shared `CtDialogueLineChoiceBody` — the intro is shown once and confirmed once, with no separate choice step (Refs #3628). |
| Presenting line (phase 1) | `!_introDone && _view!.currentLine != null && _view!.pendingSingleOptionLabel == null` | Line text + right-aligned Continue button; tap calls `_view!.advanceLine()`. |
| Presenting choice (phase 1) | `!_introDone && _view!.currentLine == null && _view!.currentChoice != null` (only choices with `n >= 2` options) | The retained `_view!.contextLine.text` (the immediately preceding intro line) **above** a vertical stack of one `CtNinePatchButton` per `choice.options[i]`; tap calls `_view!.selectOption(i)`. Rendered via the shared `CtDialogueLineChoiceBody` so the intro line and the option(s) appear together (Refs #3628). |
| Transient (phase 1) | `!_introDone && _view!.currentLine == null && _view!.currentChoice == null` | When `_view!.contextLine != null`, the retained line text above a `CtLoadingIndicator`; otherwise `CtLoadingIndicator` alone, inside the shell. |
| Offer list (phase 2) | `_introDone && _loadError == null` | Title + intro + one Accept/Reject `CtToggleSwitch` row per `pendingOvertures[i]`; every entry starts undecided (`_accepted[i] == null`, so both toggles render in their off state). Tapping the Accept toggle commits `_accepted[i] = true` (Accept on, Reject off); tapping the Reject toggle commits `_accepted[i] = false` (Reject on, Accept off); tapping a currently-on toggle reverts the row to `null`. Submit is **disabled** while any entry is still `null` (issue #2867 R23); when every entry is non-null, Submit becomes enabled and a tap calls `onDecisions(...)` with one `OvertureDecision` per offer using the resolved `_accepted!` value. |
| Error | `_loadError != null` | Localized error text (`game_overture_loadError`) + single Continue button; tapping Continue invokes `_submit()` immediately (so the host advances even when the Yarn asset is broken). |

Exactly one variant is rendered at a time. Phase 2 is the only state in which Accept / Reject toggles are interactive; phase 1 has no offer rows.

---

## Behavior

### Incoming (what shows this UI)

| Source | Condition | Result |
|--------|-----------|--------|
| `pendingDiplomacyProvider` | `PendingDiplomacyOvertures` with non-empty `offers` | `GameScreen` wraps content in `OvertureDialogueOverlay`. |

### User actions → outcomes

| Control / gesture | When enabled | Emits / calls | Side effects |
|-------------------|--------------|---------------|--------------|
| Yarn Continue / options | Phase 1 intro | Jenny runner advances | — |
| Accept `CtToggleSwitch` (`overtureAcceptToggle_<i>`) | Phase 2 | When tapped while off, sets `_accepted[i] = true` (which turns the Reject toggle off via shared state); when tapped while on, sets `_accepted[i] = null` (reverts to undecided) | Re-evaluates Submit enable state. |
| Reject `CtToggleSwitch` (`overtureRejectToggle_<i>`) | Phase 2 | When tapped while off, sets `_accepted[i] = false`; when tapped while on, sets `_accepted[i] = null` (reverts to undecided) | Re-evaluates Submit enable state. |
| Submit | Phase 2; **disabled** until every `_accepted[i]` is non-null (#2867 R23) | `onDecisions(List<OvertureDecision>)` once | Host calls `resumeOvertureDecisions` and clears pending state. |

No direct `AppEventBus` or `Navigator` usage in the overlay.

---

## Components

- `CtFullScreenDialogueShell` ([`components/ct-full-screen-dialogue-shell.md`](components/ct-full-screen-dialogue-shell.md)) — canonical scrim + centered `CtDialogShell` scaffold reused by every blocking dialogue overlay; pins the `EditorialMonoclePalette.dialogScrim` token so individual overlays do not redeclare it (Refs #2914 S2 / S9).
- `CtDialogShell` (`app/lib/widgets/ct_dialog_shell.dart`) — frame.
- `CtBrassDivider` (`app/lib/widgets/ct_brass_divider.dart`) — phase 2 title → intro separator (#2867 R21).
- `CtNinePatchButton` (`app/lib/widgets/ct_nine_patch_button.dart`) — Continue, option, and Submit buttons (no Material buttons in dialogue chrome). Accept and Reject affordances are `CtToggleSwitch` per #2867 R22.
- `CtToggleSwitch` (`app/lib/widgets/ct_toggle_switch.dart`) — phase 2 per-offer Accept / Reject controls (#2867 R22). The Accept toggle is constructed with `onGlowColor: EditorialMonoclePalette.success`; the Reject toggle is constructed with `onGlowColor: EditorialMonoclePalette.danger` so the canonical on-state knob halo paints the corresponding semantic palette token (resolved by the catalog `onGlowColor` override; see `SPEC/ui/pixel-art-ui-catalog.md` § `CtToggleSwitch`).
- `CtLoadingIndicator` (`app/lib/widgets/ct_loading_indicator.dart`) — phase-1 loading and transient placeholder.
- `CtDialogueView` ([`ct-dialogue-view.md`](ct-dialogue-view.md)) — the Jenny adapter that owns line / choice state during phase 1.
- `jenny.DialogueRunner` — Jenny's runner; receives the single `CtDialogueView` in `dialogueViews:`.
- `EditorialMonoclePalette` (`app/lib/config/editorial_monocle_palette.dart`) — `accent` (title + offerer name), `muted` (intro + stage label + colon separator) phase-2 colors per the dark editorial-monocle palette.
- Localized strings via `appL10n(context)`: `game_overture_loadError`, `game_intervention_continue`, `game_overture_title`, `game_overture_intro`, `game_overture_accept`, `game_overture_reject`, and `game_callToArms_submit` (shared Submit label). The `game_overture_offerLine(offerer, stage)` template is **no longer** consumed by phase 2 — the offer row paints `offerer` and `stage` as two distinct `Text` widgets so they can carry different colors per #2867 R22.

---

## Side effects (logging)

- Logger prefix: `dialogue` via `packageLogger('dialogue')` unless the caller injects a `CtLogger`.
- Failures inside `_loadAndRunIntro` are logged at `level == error` with `ui:dialogue: failed to load overture intro`, including the original exception and stack trace.

---

## Acceptance Criteria (Given–When–Then)

- Given an `OvertureDialogueOverlay` is mounted with the phase-1 intro Yarn node (a narrative line immediately followed by `-> Continue`, loaded via an injected `assetBundle`),
  When the overlay renders the phase-1 intro body,
  Then the intro line text and a **single** `Continue` option button render together inside one `CtDialogShell` step (no separate Continue line step and no option-only step), one tap advances to phase 2, and the combined layout matches the `matchesGoldenFile` baseline `app/test/goldens/dialogue_combined_overture_intro_choice.png` (Refs #3628 AC-5 golden coverage).

- Given an `OvertureDialogueOverlay` is mounted with `skipIntroForTest: true` and exactly one pending overture from offerer `gp_spain` at stage `tradeConsulate`,
  When the widget tree settles,
  Then the overlay renders one offer row inside a `CtDialogShell`, the row contains a `Text` widget whose content equals `gp_spain.displayName` rendered in `EditorialMonoclePalette.accent` and a `Text` widget whose content equals the localized `tradeConsulate` stage label rendered in `EditorialMonoclePalette.muted`, and two `CtToggleSwitch` widgets (one keyed `overtureAcceptToggle_0` and one keyed `overtureRejectToggle_0`) are visible alongside a Submit `CtNinePatchButton`.

- Given an `OvertureDialogueOverlay` is mounted in phase 2 with at least one pending overture,
  When the widget tree settles,
  Then the row's Accept `CtToggleSwitch` (`overtureAcceptToggle_<i>`) reports `onGlowColor == EditorialMonoclePalette.success` and the row's Reject `CtToggleSwitch` (`overtureRejectToggle_<i>`) reports `onGlowColor == EditorialMonoclePalette.danger`, satisfying the #2867 R22 contract that the Accept toggle paints a `--success` halo when on and the Reject toggle paints a `--danger` halo when on.

- Given the overlay is in phase 2 with one pending overture (`_accepted[0] == null`),
  When the user taps the Accept toggle for that row,
  Then `_accepted[0]` becomes `true`, the Accept toggle reports `value == true`, the Reject toggle reports `value == false`, and the on-state knob of the Accept toggle paints a glow whose RGB channels resolve to `EditorialMonoclePalette.success`.

- Given the overlay is in phase 2 with one pending overture (`_accepted[0] == null`),
  When the user taps the Reject toggle for that row,
  Then `_accepted[0]` becomes `false`, the Reject toggle reports `value == true`, the Accept toggle reports `value == false`, and the on-state knob of the Reject toggle paints a glow whose RGB channels resolve to `EditorialMonoclePalette.danger`.

- Given the overlay is in phase 2 with one pending overture and the user has already tapped Accept (`_accepted[0] == true`),
  When the user taps the Accept toggle again (currently on),
  Then `_accepted[0]` reverts to `null`, both toggles return to their off state, and the Submit `CtNinePatchButton` reports `enabled == false` (#2867 R23 re-engages).

- Given an `OvertureDialogueOverlay` is mounted in phase 2 (`skipIntroForTest: true`),
  When the widget tree is inspected,
  Then the `CtDialogShell` ancestor `Material` widget has `color == EditorialMonoclePalette.dialogScrim` (the canonical `--dialog-scrim` token per `SPEC/ui/pixel-art-ui-catalog.md` § Dialog scrim).

- Given an `OvertureDialogueOverlay` is mounted in phase 2 (`skipIntroForTest: true`),
  When every `Material` widget descendant of the `OvertureDialogueOverlay` subtree is inspected,
  Then no descendant has `color == Colors.black54` (regression guard; the legacy Material default scrim MUST NOT leak into the overture overlay per #2867 R1).

- Given the overlay is in phase 2 (`skipIntroForTest: true`),
  When the widget tree is inspected,
  Then the phase-2 body contains exactly one `CtBrassDivider` rendered between the localized `game_overture_title` title `Text` and the localized `game_overture_intro` intro `Text`, the title `Text.style.color` equals `EditorialMonoclePalette.accent`, the title `Text.style.letterSpacing` equals `style.fontSize! * 0.05` (canonical `0.05em` per #2867 R2), and the intro `Text.style.color` equals `EditorialMonoclePalette.muted` with `fontStyle == FontStyle.italic`.

- Given the overlay is in phase 2 with `n >= 1` pending overtures and every `_accepted[i]` defaults to `null`,
  When the widget tree settles before any Accept / Reject tap,
  Then the Submit `CtNinePatchButton` reports `enabled == false` so the player cannot submit decisions that have not been made (issue #2867 R23).

- Given the overlay is in phase 2 with two pending overtures and every `_accepted[i]` is still `null`,
  When the user taps Accept on the first row but leaves the second row undecided,
  Then the Submit `CtNinePatchButton` remains `enabled == false` and `onDecisions` has not been invoked (issue #2867 R23 negative case).

- Given the overlay is in phase 2 with two pending overtures,
  When the user taps Accept on the first row and Reject on the second row,
  Then the Submit `CtNinePatchButton` becomes `enabled == true`, tapping Submit invokes `onDecisions` exactly once with `decisions[0].accepted == true` and `decisions[1].accepted == false`, and the order matches `pendingOvertures` exactly.

- Given the overlay is in phase 2 with `n` pending overtures and every row has been resolved via Accept / Reject tap,
  When the user taps Submit once,
  Then `onDecisions` is invoked exactly once with a `List<OvertureDecision>` of length `n`, and each entry's `offererGpId` / `targetFactionId` / `stage` exactly match the corresponding `pendingOvertures[i]`.

- Given the overlay's Yarn asset load fails (`_loadError != null` with any exception),
  When the widget rebuilds after `setState`,
  Then the overlay renders the error variant: a `CtDialogShell` with `game_overture_loadError(<error>)` and a single Continue `CtNinePatchButton`.

- Given the overlay is in the error variant,
  When the user taps the error-state Continue button,
  Then `onDecisions` is invoked exactly once with one `OvertureDecision` per `pendingOvertures` entry; each entry uses `accepted == true` as the deterministic degraded fallback so the host can still resume turn resolution even though the Yarn intro asset failed to load. The R23 "non-null decision" gating applies only to the interactive phase-2 list; the error-state Continue button has no such gate because the player has no per-offer choice in this variant.

- Given the overlay is mounted with a custom `CtLogger`,
  When `_loadAndRunIntro` throws,
  Then the failure is reported via the injected logger only (no `print`, no fallback `packageLogger('dialogue')` allocation).

- Given the overlay is constructed with an empty `pendingOvertures` list,
  When the player advances the phase-1 intro to completion (or `skipIntroForTest == true`),
  Then phase 2 renders the title / intro labels and Submit, the offer list view contains zero rows, and tapping Submit invokes `onDecisions` with an empty list.

- Given an `OvertureDialogueOverlay` is mounted in phase 2 (`skipIntroForTest: true`) with one or more pending overtures at a `kMinViewportWidth × 640` (320 × 640 dp) viewport,
  When the widget tree settles,
  Then `WidgetTester.takeException()` is `null` (no `RenderFlex` overflow exception escapes the framework — the same contract pinned by `dialogs_320dp_min_viewport_test.dart` and `call_to_arms_dialogue_overlay_320dp_min_viewport_test.dart`), every per-offer body lays out as the stacked `Column(Row(offerer + ": " + stage) + Wrap(Accept toggle + Reject toggle))` from § Layout / wireframe so the labeled `CtToggleSwitch` rows flow onto a second run rather than overflowing horizontally, and the localized `game_overture_title`, `game_overture_accept`, `game_overture_reject`, and `game_callToArms_submit` labels still render end-to-end so the layout actually exercises the phase-2 body at the minimum viewport (`SPEC/ui/mobile-adaptation.md` § 7 / Refs #2870 S8 + S10 for OVL30001).

---

## Widgetbook

Catalog directory: `Overture Dialogue Overlay` (registered in `app/lib/widgetbook/catalog.dart` via `overtureDialogueOverlayDirectories` in `catalog_part4.dart`). Required use cases:

1. **Default — two pending overtures** — wraps a localized `widgetbook_gameShell` child in `OvertureDialogueOverlay` with `skipIntroForTest: true` so the story renders phase 2 immediately without depending on the production Yarn asset. The story exercises Accept/Reject toggles and the Submit button across two offers from different offerers.

The story analyzes cleanly with no hardcoded UI strings: title, intro, offer line, Accept, Reject, and Submit labels are sourced from `appL10n(context)`.
