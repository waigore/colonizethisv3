# Overture Dialogue Overlay

**Screen ID:** `OVL30001` — stable; do not reassign.
**SPEC/ui** — Blocking overlay for pending overture offers before the turn advances. Implementation: `app/lib/features/game/dialogue/overture_dialogue_overlay.dart`.
**Widgetbook:** `Overture Dialogue Overlay` → `app/lib/widgetbook/catalog.dart`. Provider: [`pending-diplomacy-state.md`](pending-diplomacy-state.md). Host: [`game-screen.md`](game-screen.md). Asset: `kDialogueOvertureAsset`.

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
- Maintains `_accepted: List<bool>` (default `true`) — one entry per pending overture — toggled by the row-level Accept and Reject buttons in phase 2.

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
|   Material(color: Colors.black54)                         |
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
|             Text(game_overture_title, titleMedium)        |
|             Text(game_overture_intro, bodyMedium)         |
|             ListView.builder (shrinkWrap, no scroll)      |
|               Row                                         |
|                 Expanded(Text(game_overture_offerLine))   |
|                 CtNinePatchButton(game_overture_accept)   |
|                 CtNinePatchButton(game_overture_reject)   |
|             Align(centerRight)                            |
|               CtNinePatchButton(game_callToArms_submit)   |
+-----------------------------------------------------------+
*phase 1 uses `maxWidth: 520` only; phase 2 also sets
 `maxHeight: 500` so the shell stays bounded with long lists.
```

Error mode renders the same `Stack` but the `CtDialogShell` body is the localized error message (`l10n.game_overture_loadError`) plus a single Continue button (`l10n.game_intervention_continue`).

---

## States and variants

| State | Trigger | Render |
|-------|---------|--------|
| Loading (phase 1) | `!_introDone && _loadError == null && _view == null` | `Stack` with `widget.child`, scrim, and `CtLoadingIndicator` inside `CtDialogShell`. |
| Presenting line (phase 1) | `!_introDone && _view!.currentLine != null` | Line text + right-aligned Continue button; tap calls `_view!.advanceLine()`. |
| Presenting choice (phase 1) | `!_introDone && _view!.currentLine == null && _view!.currentChoice != null` | Vertical stack of one `CtNinePatchButton` per `choice.options[i]`; tap calls `_view!.selectOption(i)`. |
| Transient (phase 1) | `!_introDone && _view!.currentLine == null && _view!.currentChoice == null` | `CtLoadingIndicator` inside the shell. |
| Offer list (phase 2) | `_introDone && _loadError == null` | Title + intro + one Accept/Reject row per `pendingOvertures[i]`; Accept sets `_accepted[i] = true`, Reject sets `_accepted[i] = false`. Submit calls `onDecisions(...)` with one `OvertureDecision` per offer using the current `_accepted` value. |
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
| Accept / Reject toggles | Phase 2 | Updates `_accepted` list | — |
| Submit | Phase 2 | `onDecisions(List<OvertureDecision>)` once | Host calls `resumeOvertureDecisions` and clears pending state. |

No direct `AppEventBus` or `Navigator` usage in the overlay.

---

## Components

- `CtDialogShell` (`app/lib/widgets/ct_dialog_shell.dart`) — frame.
- `CtNinePatchButton` (`app/lib/widgets/ct_nine_patch_button.dart`) — Continue, option, Accept, Reject, Submit buttons (no Material buttons in dialogue chrome).
- `CtLoadingIndicator` (`app/lib/widgets/ct_loading_indicator.dart`) — phase-1 loading and transient placeholder.
- `CtDialogueView` ([`ct-dialogue-view.md`](ct-dialogue-view.md)) — the Jenny adapter that owns line / choice state during phase 1.
- `jenny.DialogueRunner` — Jenny's runner; receives the single `CtDialogueView` in `dialogueViews:`.
- Localized strings via `appL10n(context)`: `game_overture_loadError`, `game_intervention_continue`, `game_overture_title`, `game_overture_intro`, `game_overture_offerLine(offerer, stage)`, `game_overture_accept`, `game_overture_reject`, and `game_callToArms_submit` (shared Submit label).

---

## Side effects (logging)

- Logger prefix: `dialogue` via `packageLogger('dialogue')` unless the caller injects a `CtLogger`.
- Failures inside `_loadAndRunIntro` are logged at `level == error` with `ui:dialogue: failed to load overture intro`, including the original exception and stack trace.

---

## Acceptance Criteria (Given–When–Then)

- Given an `OvertureDialogueOverlay` is mounted with `skipIntroForTest: true` and exactly one pending overture from offerer `gp_spain` at stage `tradeConsulate`,
  When the widget tree settles,
  Then the overlay renders one offer row inside a `CtDialogShell`, the row displays the localized `game_overture_offerLine` text built from `gp_spain.displayName` and the localized `tradeConsulate` stage label, and Accept / Reject `CtNinePatchButton`s are visible alongside a Submit `CtNinePatchButton`.

- Given the overlay is in phase 2 with `n` pending overtures and the default `_accepted` list of all `true`,
  When the user taps **Submit** without changing any toggle,
  Then `onDecisions` is invoked exactly once with a `List<OvertureDecision>` of length `n`, each entry has `accepted == true`, and the `offererGpId` / `targetFactionId` / `stage` fields exactly match the corresponding `pendingOvertures[i]`.

- Given the overlay is in phase 2 with two pending overtures,
  When the user taps **Reject** on the second row and then **Submit**,
  Then `onDecisions` is invoked exactly once with `decisions[0].accepted == true` and `decisions[1].accepted == false`, and no further widget rebuild changes the order of the decisions.

- Given the overlay's Yarn asset load fails (`_loadError != null` with any exception),
  When the widget rebuilds after `setState`,
  Then the overlay renders the error variant: a `CtDialogShell` with `game_overture_loadError(<error>)` and a single Continue `CtNinePatchButton`.

- Given the overlay is in the error variant,
  When the user taps the error-state Continue button,
  Then `onDecisions` is invoked exactly once with one `OvertureDecision` per `pendingOvertures` entry (`accepted == true` by default) so the host can still resume turn resolution.

- Given the overlay is mounted with a custom `CtLogger`,
  When `_loadAndRunIntro` throws,
  Then the failure is reported via the injected logger only (no `print`, no fallback `packageLogger('dialogue')` allocation).

- Given the overlay is constructed with an empty `pendingOvertures` list,
  When the player advances the phase-1 intro to completion (or `skipIntroForTest == true`),
  Then phase 2 renders the title / intro labels and Submit, the offer list view contains zero rows, and tapping Submit invokes `onDecisions` with an empty list.

---

## Widgetbook

Catalog directory: `Overture Dialogue Overlay` (registered in `app/lib/widgetbook/catalog.dart` via `overtureDialogueOverlayDirectories` in `catalog_part4.dart`). Required use cases:

1. **Default — two pending overtures** — wraps a localized `widgetbook_gameShell` child in `OvertureDialogueOverlay` with `skipIntroForTest: true` so the story renders phase 2 immediately without depending on the production Yarn asset. The story exercises Accept/Reject toggles and the Submit button across two offers from different offerers.

The story analyzes cleanly with no hardcoded UI strings: title, intro, offer line, Accept, Reject, and Submit labels are sourced from `appL10n(context)`.
