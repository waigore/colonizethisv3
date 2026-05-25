# Quick Battle Screen

**Screen ID:** `CMPT20001` — stable; do not reassign.
**SPEC/ui** — Tactical mini-game screen that runs a single Quick Battle from deployment to result. Game model: [quick-battle.md](../game/quick-battle.md). Resolver pipeline: [quick-battle-resolution.md](../program/quick-battle-resolution.md). Combat mode entry: [combat-mode-choice-dialog.md](combat-mode-choice-dialog.md). Final result presentation: [quick-battle-result-dialog.md](quick-battle-result-dialog.md). Sub-views: [quick-battle-deployment-view.md](quick-battle-deployment-view.md), [quick-battle-action-selector.md](quick-battle-action-selector.md). Dialog wiring: [app-ui-wiring.md](../program/app-ui-wiring.md). Implementation: `app/lib/features/game/combat/quick_battle_screen.dart`.
**Widgetbook:** `Quick Battle` → `app/lib/widgetbook/catalog.dart` (see § Widgetbook).

---

## Widget contract

`QuickBattleScreen` is a `StatefulWidget` (`app/lib/features/game/combat/quick_battle_screen.dart`) presented inside a `CtDialogShell` (max width 400 dp, max height 500 dp).

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `input` | `QuickBattleInput` | yes | Battle context (factions, deployments, province, max rounds, seed) built upstream by the combat pipeline (see [quick-battle-resolution.md](../program/quick-battle-resolution.md)). |
| `onComplete` | `ValueChanged<QuickBattleResult>` | yes | Invoked exactly once when the user dismisses the result view via Continue. |
| `interactive` | `bool` | no (default `false`) | When `true`, the player picks an action via [quick-battle-action-selector.md](quick-battle-action-selector.md) before resolving. When `false`, the screen runs the resolver with default actions (Volley Fire) automatically on mount. |

The widget is presentational with respect to game state — it does not read providers; resolution runs in-process through `colonizethis_logic.resolveQuickBattle`.

---

## Trigger conditions

- The screen is opened by the combat phase resolver when the player has chosen Quick Battle for a province (see [combat-mode-choice-dialog.md](combat-mode-choice-dialog.md)) or when a capital siege forces Quick Battle.
- The screen is **not** registered as an `OpenDialogEvent` id in `app/lib/core/services/app_event_handler_scope.dart`. The orchestrating combat flow constructs `QuickBattleScreen` directly (or via a future typed event) and supplies `onComplete` to feed the result back into the combat pipeline.
- While `turnResolutionBlockingProvider == true`, normal bus-driven dialogs are gated per [app-ui-wiring.md](../program/app-ui-wiring.md) § Turn resolution in progress; Quick Battle invocation must coordinate with that gate (typically the combat phase pauses turn-resolution UI dismissal until the screen completes).

---

## Layout / wireframe

### Round phase (interactive or headless, before result)

```text
+------------------------------------------------+
| CtDialogShell (max 400 x 500 dp)               |
| +--------------------------------------------+ |
| | Round X of Y           (titleMedium)       | |
| |                                            | |
| | QuickBattleDeploymentView                  | |
| |   (attacker block, then defender block)    | |
| |                                            | |
| | -- if interactive == true --               | |
| | QuickBattleActionSelector(cpRemaining: 3)  | |
| |                                            | |
| | -- if interactive == false --              | |
| | [ Resolve (Auto) ]   (CtNinePatchButton)   | |
| +--------------------------------------------+ |
+------------------------------------------------+
```

- Outer container: `CtDialogShell(maxWidth: 400, maxHeight: 500)`.
- Inner column: `Column(mainAxisSize: min, crossAxisAlignment: stretch)`.
- Title text: `appL10n(context).quickBattle_round(_round, widget.input.maxRounds)`.
- 12 dp gap before the deployment view; 12 dp gap before the action selector or auto-resolve button.

### Result phase (after resolver returns)

```text
+------------------------------------------------+
| CtDialogShell                                  |
| +--------------------------------------------+ |
| | <Winner text>                (titleMedium) | |
| | (Optional) Province captured!  (bold)      | |
| |                                            | |
| | <Attacker> casualties: <n>                 | |
| | <Defender> casualties: <n>                 | |
| |                                            | |
| |                              [ Continue ]  | |
| +--------------------------------------------+ |
+------------------------------------------------+
```

- Winner text comes from `QuickBattleResult.winner` mapped to `quickBattle_attackerWins`, `quickBattle_defenderHolds`, or `quickBattle_mutualExhaustion`.
- `provinceCaptured` line appears only when `result.provinceFlips == true`.
- Continue button (`CtNinePatchButton`) invokes `onComplete(result)` exactly once.

---

## Behavior

### Incoming

| Source | Condition | Result |
|--------|-----------|--------|
| Combat phase orchestrator constructs `QuickBattleScreen` | The player chose `CombatMode.quickBattle` via [combat-mode-choice-dialog.md](combat-mode-choice-dialog.md), or a capital siege forced Quick Battle, or AI / observer paths request a headless run | The screen mounts inside a `CtDialogShell`; `interactive` is forwarded by the orchestrator. |
| First frame after mount with `interactive == false` | The constructor passed `interactive: false` | `initState` calls `_runWithDefaults`, which invokes `resolveQuickBattle(input)` with default Volley Fire actions and stores the result in `_result`. |
| First frame after mount with `interactive == true` | The constructor passed `interactive: true` | `_result` stays `null`; round-phase widgets render and wait for the action selector. |

### User actions → outcomes

| Control / gesture | When enabled | Emits / calls | Side effects |
|-------------------|--------------|---------------|--------------|
| Resolve (Auto) `CtNinePatchButton` | `interactive == false && _result == null` (manual fallback before auto-resolve completes) | Calls `_runWithDefaults`, which calls `resolveQuickBattle(input)` once | Result phase renders winner, casualties, and Continue. |
| Action button inside `QuickBattleActionSelector` | `interactive == true && _result == null` and the action's CP fits in `cpRemaining: 3` | `_onActionSelected(action)` calls `resolveQuickBattle(input, roundActions: [action, VolleyFire, VolleyFire])` | Result phase renders winner, casualties, and Continue. |
| Continue `CtNinePatchButton` (result phase) | `_result != null` | Calls `onComplete(_result!)` exactly once (guarded by `_completionInvoked` so subsequent taps are no-ops) | Orchestrator forwards the result back into the combat pipeline (often via `OpenDialogEvent(quickBattleResultDialogId)`); the host removes the screen from the widget tree. |

The screen never reads providers, never emits bus events, and never handles Android back; the orchestrator owns the lifecycle through `onComplete`.

---

## States and variants

| Mode | Trigger | Behavior |
|------|---------|----------|
| Headless / AI | `interactive == false` | `initState` calls `_runWithDefaults`, which invokes `resolveQuickBattle(input)` with default round actions and transitions directly to the result phase. The Resolve (Auto) button remains visible during the same frame as a manual fallback. |
| Interactive | `interactive == true` | Round phase renders `QuickBattleActionSelector` with `cpRemaining: 3`. Tapping an action invokes `_onActionSelected`, which calls `resolveQuickBattle` with three rounds of explicit actions (the chosen action followed by two default Volley Fire rounds) and transitions to the result phase. |
| Result | `_result != null` (after either path) | Round-phase widgets are unmounted; result view renders winner, optional province-capture line, casualties, and Continue. |

The current Quick Battle phase only deploys `CENTER + FRONT` units (see [quick-battle.md](../game/quick-battle.md) § Battlefield layout). The screen still renders any `LEFT/RIGHT/RESERVE` or `SUPPORT` groups returned by future resolver inputs without code changes.

---

## Navigation

- **Entry points:**
  - Combat phase orchestrator after the player chooses `CombatMode.quickBattle` via [combat-mode-choice-dialog.md](combat-mode-choice-dialog.md), or when `isCapitalSiege == true` (forced Quick Battle, see [siege-mechanics.md](../game/siege-mechanics.md)).
  - Future AI / observer paths may construct the screen with `interactive: false` to run the resolver inside a dialog tree without user input.
- **Exit:** Always via `onComplete(QuickBattleResult)` once the user taps Continue. The orchestrator typically follows up by emitting `OpenDialogEvent(quickBattleResultDialogId)` so the result is presented through the canonical dialog registry (`QuickBattleResultDialog`), or by applying the result directly when no further confirmation is needed.
- **Hardware back / dismiss:** The screen does not handle Android back; the orchestrator keeps the screen alive until `onComplete` fires.

---

## Components

- `CtDialogShell` (`app/lib/widgets/ct_dialog_shell.dart`).
- `CtNinePatchButton` (Resolve (Auto) and Continue).
- [`QuickBattleDeploymentView`](quick-battle-deployment-view.md) — sub-view rendered every round.
- [`QuickBattleActionSelector`](quick-battle-action-selector.md) — sub-view rendered only when `interactive == true`.
- Localized strings via `appL10n(context).quickBattle_*`.
- No Material buttons.

---

## Acceptance Criteria (Given–When–Then)

- Given a `QuickBattleScreen` is mounted with valid `input`, `onComplete` callback, and `interactive: false`,
  When the framework runs the first frame,
  Then the screen calls `resolveQuickBattle(input)` once and transitions to the result view; the result view renders the winner text, the casualty counts for both sides, and a Continue `CtNinePatchButton`.

- Given a `QuickBattleScreen` is mounted with `interactive: false`,
  When the user taps the Continue button on the result view,
  Then the screen invokes `onComplete(result)` exactly once with the resolver's `QuickBattleResult` and does not invoke `onComplete` a second time on subsequent taps.

- Given a `QuickBattleScreen` is mounted with `interactive: true`,
  When the framework runs the first frame,
  Then the screen does not call `resolveQuickBattle`, displays `QuickBattleDeploymentView` and `QuickBattleActionSelector(cpRemaining: 3)`, and does not display the Resolve (Auto) button.

- Given a `QuickBattleScreen` is mounted with `interactive: true` and `cpRemaining = 3`,
  When the user taps the Volley Fire action button,
  Then the screen calls `resolveQuickBattle(input, roundActions: [VolleyFire, VolleyFire, VolleyFire])` and transitions to the result view.

- Given a `QuickBattleScreen` is mounted with an `input.maxRounds == 3`,
  When the round phase is rendered,
  Then the title text equals the localized `quickBattle_round(1, 3)` string.

- Given a `QuickBattleResult` returned by the resolver has `provinceFlips == true`,
  When the result view renders,
  Then the result view displays the localized `quickBattle_provinceCaptured` line in bold above the casualty counts.

- Given a `QuickBattleResult` returned by the resolver has `provinceFlips == false`,
  When the result view renders,
  Then the result view does not display the `quickBattle_provinceCaptured` line.

- Given a `QuickBattleScreen` is mounted,
  When the framework runs `build`,
  Then the widget tree contains exactly one `CtDialogShell` with `maxWidth: 400` and `maxHeight: 500` and no Material `ElevatedButton`, `TextButton`, or `OutlinedButton`.

---

## Widgetbook

Catalog directory: `Quick Battle Screen` (registered in `app/lib/widgetbook/catalog.dart`). At least one default use case constructs a non-interactive `QuickBattleScreen` with a sample `QuickBattleInput` (two factions, three or more units per side at `CENTER + FRONT`) and a no-op `onComplete`. Additional use cases are encouraged for the interactive variant.
