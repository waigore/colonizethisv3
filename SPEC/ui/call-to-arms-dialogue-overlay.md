# Call to Arms Dialogue Overlay

**SPEC/ui** — Modal blocking overlay shown when turn resolution returns one or more pending **call to arms** decisions that a human-controlled faction must accept (Join) or refuse for each of its allies before the turn can advance. The overlay has **no Yarn intro phase**: it presents the per-call list immediately. Modal presentation rules: [`dialogue-presentation.md`](dialogue-presentation.md). Source provider: [`pending-diplomacy-state.md`](pending-diplomacy-state.md). Host screen / wrap order: [`game-screen.md`](game-screen.md) § States and variants. Pixel-art chrome: [`pixel-art-ui-catalog.md`](pixel-art-ui-catalog.md).

---

## Widget contract

`CallToArmsDialogueOverlay` is a `StatefulWidget` (`app/lib/features/game/dialogue/call_to_arms_dialogue_overlay.dart`). It wraps an arbitrary `child` and, while the call-to-arms flow is open, paints a dim scrim plus a centered `CtDialogShell` on top of that child.

| Constructor parameter | Type | Required | Description |
|-----------------------|------|----------|-------------|
| `game` | `Game` | yes | Active game state, used to resolve `defenderGpId` and `aggressorGpId` to display names via `game.playerById(...).displayName` (falls back to the raw id if no player matches). |
| `pending` | `List<CallToArmsPending>` | yes | One or more pending call-to-arms decisions targeting the human-controlled faction's ally. The list length defines the number of Join/Refuse rows rendered and the initial size of the per-call `_join` toggle list. |
| `onDecisions` | `void Function(List<CallToArmsDecision>)` | yes | Invoked exactly once when the player taps **Submit**, with one `CallToArmsDecision` per input `CallToArmsPending`, preserving order. Consumers forward decisions to `service.resumeCallToArmsDecisions(...)`. |
| `child` | `Widget` | yes | The underlying screen content; remains mounted while the overlay is presented so host route state is preserved across the decision flow. |

Internal state ownership:

- Maintains `_join: List<bool>` (default `true`) — one entry per pending call — toggled by the row-level Join and Refuse buttons.
- Does **not** own a `CtDialogueView`, `DialogueRunner`, or any Yarn asset. There is no intro phase; the overlay renders the decision list as soon as it is mounted.

---

## Trigger conditions

- **Entry:** Rendered by `GameScreen` when `pendingDiplomacyProvider` exposes `PendingCallToArms(pending)` (see [`pending-diplomacy-state.md`](pending-diplomacy-state.md) and [`game-screen.md`](game-screen.md)). The notifier is replaced wholesale on each turn-resolution result, so a single overlay instance handles all calls for one resume cycle.
- **Asset load:** None. The overlay has no Yarn integration, no Jenny `DialogueRunner`, and does not call `rootBundle.loadString`. No failure path needs an error affordance.
- **Dismissal:** Exclusively driven by the player tapping **Submit**. The overlay does not provide a per-call dismiss or close button; the player must resolve every row before submitting (rows always carry a current `_join[i]` value, so Submit is always enabled).

---

## Layout / wireframe

```text
+-----------------------------------------------------------+
| Stack                                                     |
|   widget.child                                            |
|   Material(color: Colors.black54)                         |
|     Center                                                |
|       CtDialogShell(maxWidth: 520, maxHeight: 500)        |
|         Padding(all: 20)                                  |
|           Column(mainAxisSize: min)                       |
|             Text(game_callToArms_title, titleMedium)      |
|             Text(game_callToArms_intro, bodyMedium)       |
|             ListView.builder (shrinkWrap, no scroll)      |
|               Row(crossAxisAlignment: start)              |
|                 Expanded(Text(game_callToArms_prompt))    |
|                 CtNinePatchButton(game_callToArms_join)   |
|                 CtNinePatchButton(game_callToArms_refuse) |
|             Align(centerRight)                            |
|               CtNinePatchButton(game_callToArms_submit)   |
+-----------------------------------------------------------+
```

The prompt text in each row is the localized `game_callToArms_prompt(defenderName, aggressorName)`. Names are resolved from `game.playerById(...)` — if the lookup fails the raw id is shown so the row never collapses to an empty string.

---

## States and variants

| State | Trigger | Render |
|-------|---------|--------|
| Decision list | Overlay is mounted with `pending.length >= 1` | One Join/Refuse row per `pending[i]`; Join sets `_join[i] = true`, Refuse sets `_join[i] = false`. Submit calls `onDecisions(...)` with one `CallToArmsDecision` per pending using the current `_join` value. |
| Empty decision list | Overlay is mounted with `pending.length == 0` | The shell still renders the title / intro labels and a Submit button; Submit invokes `onDecisions` with an empty list so the host can clear the pending provider. |

There are no loading, transient, or error variants; absence of a Yarn dependency is what differentiates this overlay from [`overture-dialogue-overlay.md`](overture-dialogue-overlay.md) and [`game-start-intro-overlay.md`](game-start-intro-overlay.md).

---

## Navigation and bus

- The overlay does **not** read or emit `AppEventBus` events directly.
- All navigation side effects flow through the `onDecisions` callback. The host (`GameScreen`) is responsible for forwarding the resulting `List<CallToArmsDecision>` to `service.resumeCallToArmsDecisions(...)` and for clearing the pending-diplomacy provider on the resulting `TurnResolutionResult` per [`pending-diplomacy-state.md`](pending-diplomacy-state.md).
- The overlay does not interact with `Navigator` for any reason: no `pushNamed`, no `pop`, no `popUntil`. The host route remains mounted; only the scrim is removed when the host clears the pending state on a successful resume.

---

## Components

- `CtDialogShell` (`app/lib/widgets/ct_dialog_shell.dart`) — frame.
- `CtNinePatchButton` (`app/lib/widgets/ct_nine_patch_button.dart`) — Join, Refuse, Submit buttons (no Material buttons in dialogue chrome).
- Localized strings via `appL10n(context)`: `game_callToArms_title`, `game_callToArms_intro`, `game_callToArms_prompt(defender, aggressor)`, `game_callToArms_join`, `game_callToArms_refuse`, and `game_callToArms_submit`.

---

## Side effects (logging)

- The overlay does not log directly; all logging is delegated to underlying widgets and the host orchestrator.

---

## Acceptance Criteria (Given–When–Then)

- Given a `CallToArmsDialogueOverlay` is mounted with exactly one pending call where `defenderGpId == 'gp_portugal'` and `aggressorGpId == 'gp_spain'` and a `Game` whose `playerById` returns players with display names `Portugal` and `Spain`,
  When the widget tree settles,
  Then the overlay renders one row inside a `CtDialogShell` whose prompt is the localized `game_callToArms_prompt('Portugal', 'Spain')`, with Join, Refuse, and Submit `CtNinePatchButton`s visible.

- Given the overlay is mounted with `n` pending calls and the default `_join` list of all `true`,
  When the user taps **Submit** without changing any toggle,
  Then `onDecisions` is invoked exactly once with a `List<CallToArmsDecision>` of length `n`, each entry has `accepted == true`, and the `allyGpId` / `defenderGpId` / `aggressorGpId` fields exactly match the corresponding `pending[i]`.

- Given the overlay is mounted with two pending calls,
  When the user taps **Refuse** on the first row and **Join** (already selected) on the second row, then taps **Submit**,
  Then `onDecisions` is invoked exactly once with `decisions[0].accepted == false` and `decisions[1].accepted == true`, and the list order matches `pending` exactly.

- Given the overlay is constructed with an empty `pending` list,
  When the widget tree settles,
  Then the shell renders only the title / intro labels and the Submit button (no rows), and tapping Submit invokes `onDecisions` with an empty list.

- Given the overlay is mounted with one pending call whose `defenderGpId` does not correspond to any player in `game.players`,
  When the widget tree settles,
  Then the prompt row displays the raw `defenderGpId` string in the slot reserved for the defender name (no crash, no empty placeholder).

---

## Widgetbook

Catalog directory: `Call to Arms Dialogue Overlay` (registered in `app/lib/widgetbook/catalog.dart` via `callToArmsDialogueOverlayDirectories` in `catalog_part4.dart`). Required use cases:

1. **Default — two pending calls** — wraps a localized `widgetbook_gameShell` child in `CallToArmsDialogueOverlay` with a small in-memory `Game` and two `CallToArmsPending` entries from different aggressor / defender combinations. The story exercises Join/Refuse toggles and the Submit button across two rows.

The story analyzes cleanly with no hardcoded UI strings: title, intro, prompt, Join, Refuse, and Submit labels are sourced from `appL10n(context)`.
