# Quick Battle Action Selector

**SPEC/ui** — CP-based action picker rendered inside [Quick Battle Screen](quick-battle-screen.md) when the player drives Quick Battle interactively. Game model: [quick-battle.md](../game/quick-battle.md) § Turn structure and actions. Resolver: [quick-battle-resolution.md](../program/quick-battle-resolution.md).

---

## Widget contract

`QuickBattleActionSelector` is a presentational `StatelessWidget` (`app/lib/features/game/combat/quick_battle_action_selector.dart`).

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `cpRemaining` | `int` | yes | Command Points (CP) currently available to the side. Integer in range `0..3`. |
| `onActionSelected` | `ValueChanged<QuickBattleAction>` | yes | Invoked exactly once when the player taps an enabled action button. |

The widget owns no internal state; CP is pushed in by the parent (`QuickBattleScreen` for current phase, AI/observer overrides in future).

---

## Trigger conditions

The widget is mounted by `QuickBattleScreen` only when `interactive == true`. In headless / non-interactive mode (`interactive == false`), the parent renders a `CtNinePatchButton` labeled `Resolve (Auto)` instead and never instantiates this widget.

---

## Layout / wireframe

```text
+----------------------------------------------------+
| Command Points: <cpRemaining>     (titleSmall)     |
| +------------------------------------------------+ |
| | Wrap (spacing 8, runSpacing 8)                 | |
| | [ Volley Fire (1 CP) ] [ Defend (1 CP) ]       | |
| | [ Maneuver (1 CP) ] [ Fall Back (2 CP) ]       | |
| | [ Assault (2 CP) ]                             | |
| +------------------------------------------------+ |
+----------------------------------------------------+
```

- Outer layout: `Column(crossAxisAlignment: start, mainAxisSize: min)`.
- CP label: `Text` styled with `Theme.of(context).textTheme.titleSmall`, formatted via `appL10n(context).quickBattle_commandPoints(cpRemaining)`. Foreground color resolves to the canonical dark-theme `--muted` token via `EditorialMonoclePalette.muted` (per `SPEC/ui/pixel-art-ui-catalog.md` § Editorial-monocle palette). Hard-coded hex colors or unmodified `titleSmall` foreground colors are regressions.
- 8 dp vertical gap, then a `Wrap(spacing: 8, runSpacing: 8)` of action buttons.
- Buttons are `CtNinePatchButton`s with localized labels (`appL10n(context).quickBattle_actionWithCost(label, cost)`); Material `ElevatedButton`/`TextButton` are not permitted.

### Action catalog (current phase)

| Action | CP cost | Label key |
|--------|---------|-----------|
| `QuickBattleAction.volleyFire` | `1` | `quickBattle_action_volleyFire` |
| `QuickBattleAction.defendEntrench` | `1` | `quickBattle_action_defend` |
| `QuickBattleAction.maneuver` | `1` | `quickBattle_action_maneuver` |
| `QuickBattleAction.fallBackRefuseFlank` | `2` | `quickBattle_action_fallBack` |
| `QuickBattleAction.assaultCharge` | `2` | `quickBattle_action_assault` |

The action set, ordering, and CP costs above match [quick-battle.md](../game/quick-battle.md) § Turn structure and actions and must stay in sync with `QuickBattleAction` enum values.

---

## States and variants

| State | Trigger | Render |
|-------|---------|--------|
| Full CP | `cpRemaining == 3` | All five buttons enabled. |
| Reduced CP (`1 ≤ cpRemaining < 2`) | One CP left after a 2-CP action. | 1-CP buttons (Volley Fire, Defend, Maneuver) enabled; 2-CP buttons disabled. |
| Reduced CP (`cpRemaining == 2`) | Two CP left. | All five buttons enabled. |
| Spent (`cpRemaining == 0`) | Side has spent all CP this round. | All buttons disabled (`CtNinePatchButton.onPressed == null`). |
| Negative `cpRemaining` | Defensive: parent passes a negative value. | All buttons disabled. |

A button is **enabled** iff `cpRemaining >= cost(action)`; otherwise the button renders disabled (`onPressed: null`). The widget does not deduct CP itself; the parent updates `cpRemaining` after each tap.

---

## Navigation

- **Entry:** Mounted by `QuickBattleScreen` when `interactive == true`.
- **Exit:** When the user taps an enabled action button, the widget invokes `onActionSelected(action)` once. The parent decides what happens next (e.g., apply the action, recompute CP, advance round).
- **Cross-panel events:** None. The widget does not call `AppEventBus.emit`, `Navigator.push`, or `showDialog`.

---

## Components

- `CtNinePatchButton` (shared pixel-art button; `app/lib/widgets/ct_nine_patch_button.dart`).
- `Wrap` for responsive button layout.
- `Text` styled with `titleSmall`.
- No Material buttons (`ElevatedButton`, `TextButton`, etc.) per UXD 02 / pixel-art component rule.

---

## Acceptance Criteria (Given–When–Then)

- Given a `QuickBattleActionSelector` with `cpRemaining = 3` is mounted,
  When the UI layer renders the widget,
  Then the UI layer displays five `CtNinePatchButton`s in this order — Volley Fire (1 CP), Defend (1 CP), Maneuver (1 CP), Fall Back (2 CP), Assault (2 CP) — and every button has a non-null `onPressed`.

- Given a `QuickBattleActionSelector` with `cpRemaining = 1`,
  When the UI layer renders the widget,
  Then the buttons for `volleyFire`, `defendEntrench`, and `maneuver` are enabled (non-null `onPressed`), and the buttons for `fallBackRefuseFlank` and `assaultCharge` are disabled (`onPressed == null`).

- Given a `QuickBattleActionSelector` with `cpRemaining = 0`,
  When the UI layer renders the widget,
  Then all five action buttons are disabled (`onPressed == null`) and the CP label reads `Command Points: 0` (or its localized equivalent).

- Given a `QuickBattleActionSelector` with `cpRemaining = 3` and an `onActionSelected` callback,
  When the user taps the Volley Fire button,
  Then the UI layer invokes `onActionSelected(QuickBattleAction.volleyFire)` exactly once and does not invoke any other callback or emit any `AppEvent`.

- Given a `QuickBattleActionSelector` with `cpRemaining = -1` (defensive value supplied by parent),
  When the UI layer renders the widget,
  Then all five action buttons are disabled (`onPressed == null`) and the widget does not throw.

- Given a `QuickBattleActionSelector` is mounted,
  When the UI layer renders the widget,
  Then the widget contains no `ElevatedButton`, `TextButton`, or `OutlinedButton` (Material) widgets.

- Given a `QuickBattleActionSelector` is mounted under `AppThemes.editorialMonocle`,
  When the UI layer renders the CP indicator `Text`,
  Then its `style.color` resolves to `EditorialMonoclePalette.muted` and its `style` is based on `Theme.of(context).textTheme.titleSmall` (the dark-theme `--muted` token; no hard-coded hex literals).

---

## Widgetbook

Catalog directory: `Quick Battle Action Selector` (registered in `app/lib/widgetbook/catalog.dart`). At least one default use case with `cpRemaining = 3` (all actions enabled). Additional use cases are encouraged for `cpRemaining = 1` (mixed enabled/disabled) and `cpRemaining = 0` (all disabled).
