# Quick Battle Deployment View

**SPEC/ui** — Read-only view that visualizes attacker and defender lane / line composition for a Quick Battle. Used as a sub-view inside [Quick Battle Screen](quick-battle-screen.md). Game model: [quick-battle.md](../game/quick-battle.md). Resolver: [quick-battle-resolution.md](../program/quick-battle-resolution.md).

---

## Widget contract

`QuickBattleDeploymentView` is a presentational `StatelessWidget` (`app/lib/features/game/combat/quick_battle_deployment_view.dart`).

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `attackerDeployment` | `QuickBattleDeployment` | yes | Side composition; one entry per `QuickBattleGroup` (lane, line, unit ids, cohesion). |
| `defenderDeployment` | `QuickBattleDeployment` | yes | Same shape as attacker. |
| `attackerName` | `String` | no (default `'Attacker'`) | Header label for the attacker block. |
| `defenderName` | `String` | no (default `'Defender'`) | Header label for the defender block. |

The widget does not own state, callbacks, or business logic. It only renders the supplied composition.

---

## Trigger conditions

The widget is mounted by `QuickBattleScreen` whenever its result view is not active (rounds 1..N). It is **not** registered as a dialog id and is never opened directly via `OpenDialogEvent`.

---

## Layout / wireframe

```text
+------------------------------------------------+
| Attacker (titleMedium)                         |
| +--------------------------------------------+ |
| | CtPanel (12 dp padding)                    | |
| |                                            | |
| | [Center Front: 3 units (Cohesion 3)]       | |
| | [Center Front: 2 units]                    | |
| +--------------------------------------------+ |
|                                                |
| Defender (titleMedium)                         |
| +--------------------------------------------+ |
| | CtPanel (12 dp padding)                    | |
| |                                            | |
| | [Center Front: 4 units (Cohesion 3)]       | |
| +--------------------------------------------+ |
+------------------------------------------------+
```

- Outer layout: `Column` with `crossAxisAlignment: stretch` and `mainAxisSize: min`.
- 16 dp vertical spacing between attacker and defender blocks.
- Each side: title `Text` (theme `titleMedium`) followed by a `CtPanel` containing a `Wrap(spacing: 12, runSpacing: 8)` of group rows.
- Each group row uses the theme's `bodySmall` style with the canonical dark-theme `--muted` token resolved through `EditorialMonoclePalette.muted` (per `SPEC/ui/pixel-art-ui-catalog.md` § Editorial-monocle palette). Hard-coded hex colors or unmodified `bodySmall` foreground colors are regressions.
- Each group row formats as `<Lane> <Line>: <unitCount> units[ (Cohesion <c>)]`. The cohesion suffix is suppressed when `cohesion <= 0`.

### Lane and line labels

- Lane: `LEFT → 'Left'`, `CENTER → 'Center'`, `RIGHT → 'Right'`, `RESERVE → 'Reserve'`.
- Line: `FRONT → 'Front'`, `SUPPORT → 'Support'`.

The widget renders all groups returned by the resolver input. The current Quick Battle phase only populates `CENTER + FRONT` groups (see [quick-battle.md](../game/quick-battle.md) § Battlefield layout); any future expansion to `LEFT/RIGHT/RESERVE` and `SUPPORT` is rendered automatically without code changes here.

---

## States and variants

| State | Trigger | Render |
|-------|---------|--------|
| Default | Both deployments contain at least one group. | Two stacked side blocks with all groups listed. |
| Empty side | A side's `groups` list is empty. | Side title shown; `CtPanel` body renders an empty `Wrap` (no group rows). |
| Cohesion 0 | A group's `cohesion` is `0`. | Row text omits the `(Cohesion <c>)` suffix. |
| Custom names | `attackerName` / `defenderName` provided. | Headers display the supplied strings instead of `'Attacker'` / `'Defender'`. |

Both sides always render in the order **attacker → defender** to match resolver semantics.

---

## Navigation

- **Entry:** Always rendered as a child inside `QuickBattleScreen` when the round phase is active.
- **Exit:** None. The widget is removed from the tree when `QuickBattleScreen` switches to its result view (`onComplete`) or is dismissed.
- **Cross-panel events:** None. The widget does not subscribe to or emit `AppEventBus` events; cross-screen behavior belongs to `QuickBattleScreen`.

---

## Components

- `CtPanel` (shared pixel-art panel; `app/lib/widgets/ct_panel.dart`).
- `Text` from `Theme.of(context).textTheme.titleMedium` and `bodySmall`.
- No `CtNinePatchButton` here; this view is purely informational.

---

## Acceptance Criteria (Given–When–Then)

- Given a `QuickBattleDeploymentView` with an attacker deployment containing one `QuickBattleGroup(lane: center, line: front, unitIds: [3 ids], cohesion: 3)` and `attackerName: 'Castile'`,
  When the UI layer renders the widget,
  Then the UI layer displays the header text `Castile` followed by a `CtPanel` containing a row whose text equals `Center Front: 3 units (Cohesion 3)`.

- Given a `QuickBattleDeploymentView` with a defender group whose `cohesion` is `0`,
  When the UI layer renders the widget,
  Then the row for that group displays `<Lane> <Line>: <n> units` with no `(Cohesion ...)` suffix.

- Given a `QuickBattleDeploymentView` constructed without `attackerName` or `defenderName`,
  When the UI layer renders the widget,
  Then the attacker header displays the literal string `Attacker` and the defender header displays the literal string `Defender`.

- Given a `QuickBattleDeploymentView` whose attacker `groups` list is empty,
  When the UI layer renders the widget,
  Then the attacker header is shown, a `CtPanel` is rendered, and no group rows appear inside that panel.

- Given a `QuickBattleDeploymentView` with attacker groups for lanes `center` and `right` and lines `front` and `support`,
  When the UI layer renders the widget,
  Then each group row uses the canonical labels `Left/Center/Right/Reserve` for lane and `Front/Support` for line, and groups appear in the order returned by `attackerDeployment.groups` (no client-side sort).

- Given a `QuickBattleDeploymentView` with at least one non-empty deployment group on either side,
  When the UI layer renders the widget,
  Then every group-row `Text` widget resolves its `style.color` to `EditorialMonoclePalette.muted` (the `--muted` token), independent of the ambient theme.

- Given a `QuickBattleDeploymentView` is mounted with non-null deployments,
  When the user views the screen,
  Then the widget does not emit any `AppEvent`, does not call `Navigator.push`, and does not call `showDialog`.

- Given a `QuickBattleDeploymentView` is mounted with at least one attacker group,
  When the UI layer renders the widget under `AppThemes.editorialMonocle`,
  Then every per-group `Text` row resolves its foreground color to `EditorialMonoclePalette.muted` and its `style` is based on `Theme.of(context).textTheme.bodySmall` (the dark-theme `--muted` token; no hard-coded hex literals).

---

## Widgetbook

Catalog directory: `Quick Battle Deployment View` (registered alongside other combat catalog folders in `app/lib/widgetbook/catalog.dart`). At least one default use case with both attacker and defender groups configured at `CENTER + FRONT`. Mobile viewport may be added if the layout differs meaningfully on narrow widths.
