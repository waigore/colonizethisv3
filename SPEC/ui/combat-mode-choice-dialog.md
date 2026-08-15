# Combat Mode Choice Dialog

**Screen ID:** `CMPT10001` — stable; do not reassign.
**SPEC/ui** — Modal for Auto-Resolve vs Quick Battle. Game: [quick-battle.md](../game/quick-battle.md), [siege-mechanics.md](../game/siege-mechanics.md). Resolver: [quick-battle-resolution.md](../program/quick-battle-resolution.md). Wiring: [app-ui-wiring.md](../program/app-ui-wiring.md). Intel: [components/combat-mode-choice-intel.md](components/combat-mode-choice-intel.md). Follow-up: [quick-battle-screen.md](quick-battle-screen.md).
**Mockup:** [mockups/CMPT10001-combat-mode-choice.html](mockups/CMPT10001-combat-mode-choice.html)
**Widgetbook:** `Combat Mode Choice Dialog` → `widgetbook_host/lib/catalogs/catalog_screens_combat_mode_choice.dart`

## Widget contract

`CombatModeChoiceDialog` (`app/lib/features/game/widgets/combat/combat_mode_choice_dialog.dart`) in `CtDialogShell`. Stateful only for the Details toggle.

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `bus` | `AppEventBus` | yes | Emits `CombatModeChosenEvent(CombatMode)` then `Navigator.pop`. |
| `provinceName` | `String` | yes | Title via `quickBattle_combatAt`. Empty interpolates as-is. |
| `isCapitalSiege` | `bool` | yes | `true`: hide Auto-Resolve and its meaning line. |
| `landForceFeedingWarning` | `String?` | no | Underfed italic line (#4242). Builder may compute from params `game` / `humanPlayerId` / `topology` / `draftOrders`. |
| `intel` | `CombatModeChoiceIntel?` | no | Force/fort/Details. Null omits those; mode-meaning still shows. |
| `detailsInitiallyOpen` | `bool` | no | Widgetbook Details-open story. Default false. |

Builder: `buildCombatModeChoiceDialog` in `app_event_handler_scope_lifecycle.dart`. Params: `provinceName`, `isCapitalSiege`, optional feeding string or snapshot fields, plus intel keys in the component spec. Open via `OpenDialogEvent(combatModeChoiceDialogId, params)` only.

## Layout / wireframe

```text
CtDialogShell
  Column(min, start)
    title  Combat at <provinceName>   titleMedium --accent letterSpacing 0.05
    CtGap.m
    prompt  chooseCombatMode | capitalSiegeQuickBattleOnly   bodyMedium --muted
    [Your army: N]
    [Defenders: N | Attackers: N | Defenders unknown]
    [Open field | Wood/Stone/Modern fort siege]
    [Auto-Resolve meaning]     omitted when capital siege
    [Quick Battle meaning]
    [underfed italic --muted]
    [Details / Hide  CtActionTextButton]
    [indented type counts when Details open]
    CtGap.l
    Wrap(end, 8, 8)  [Auto-Resolve --muted] [Quick Battle --accent]
```

Buttons are `CtNinePatchButton`. No Material buttons. No win-percent or predicted-winner copy. Never `moveArmy_unopposedCapture`.

## Behavior

| Control | When enabled | Emits / calls |
|---------|--------------|---------------|
| Auto-Resolve | not capital siege | `CombatModeChosenEvent(autoResolve)` then pop |
| Quick Battle | always | `CombatModeChosenEvent(quickBattle)` then pop |
| Details | intel != null | toggles type lines; no bus |

Meaning keys: `quickBattle_autoResolveMeaning` (decides at once), `quickBattle_quickBattleMeaning` (player gives orders). Enemy labels: attacker `moveArmy_defendersRegiments`; defender `combatMode_attackersRegiments`. Own: `moveArmy_yourArmyRegiments`. Fort: `moveArmyFortLabelForLevel`.

## States and variants

| ID | Trigger | Render |
|----|---------|--------|
| CMPT10001 | regular | Both buttons; Auto-Resolve meaning shown |
| CMPT10001a | capital siege | Quick Battle only; Auto-Resolve meaning omitted |
| CMPT10001b | underfed | Italic feeding line; modes stay enabled |
| CMPT10001c | attacker full intel | Own + defenders + fort |
| CMPT10001d | attacker unknown intel | Own + Defenders unknown; no fort; Details has no enemy types |
| CMPT10001e | defender full intel | Own + attackers + fort |
| CMPT10001f | Details open | Type lines for own and, when the enemy line is shown, enemy |
| CMPT10001g | intel null / name fail-closed | Prompt + meanings (+ feeding); no force/fort/Details |

## Components

- `CtDialogShell`, `CtNinePatchButton`, `CtActionTextButton`, `CtGap`
- [combat-mode-choice-intel.md](components/combat-mode-choice-intel.md)

## Dark-theme treatment

`AppThemes.editorialMonocle` only. Title `--accent` + 0.05 tracking; body/meanings/force `--muted`; Quick Battle label `--accent`; Auto-Resolve label `--muted`. Colors from `EditorialMonoclePalette`.

## Widgetbook

Folder `Combat Mode Choice Dialog`. Use cases: **Regular province**; **Capital siege**; **Attacker full intel**; **Attacker unknown intel**; **Defender full intel**; **Details open**. Each uses a fresh `AppEventBus.create()`. Existing **Quick Battle** folder still hosts the two original mode-choice stories.

## Acceptance criteria

- Given `OpenDialogEvent` with Lisbon and `isCapitalSiege: false`, when the UI layer renders, then title, choose-mode prompt, both `CtNinePatchButton`s, and both meaning lines render, and `moveArmy_unopposedCapture` does not.
- Given capital siege, when the UI layer renders, then Auto-Resolve button and Auto-Resolve meaning are absent, Quick Battle remains, and force/fort follow intel rules.
- Given attacker full intel with owner `N > 0`, when the UI layer renders, then own count, `moveArmy_defendersRegiments(N)`, and the fort label render.
- Given attacker unknown intel, when the UI layer renders, then Defenders unknown shows, fort type does not, and own count still shows.
- Given defender full intel, when the UI layer renders, then own count uses in-province human total and enemy uses `combatMode_attackersRegiments`, not `moveArmy_defendersRegiments`.
- Given Details closed, when the UI layer renders, then type lines are hidden; when the player taps Details and the enemy line is shown, then own and enemy type lines appear.
- Given intel null, when the UI layer renders, then force/fort/Details are omitted and meanings still render.
- Given underfed copy, when the UI layer renders, then that line remains and both modes stay enabled.
- Given width `kMinViewportWidth` (320 dp) with force/fort/meanings and both buttons, when the UI layer renders, then there is no horizontal overflow.
- Given Auto-Resolve or Quick Battle tap, when the player chooses, then the dialog emits the matching `CombatModeChosenEvent` once and pops.
- Given editorial-monocle, when the UI layer renders, then title is `--accent` 0.05, body `--muted`, Auto-Resolve label `--muted`, Quick Battle label `--accent`, one `CtDialogShell`, zero Material buttons.
- Given CMPT10001 attacker-full, attacker-unknown, defender-full, Details-open, capital-siege, and 320 dp intel variants under `AppThemes.editorialMonocle`, when `app/test/combat_mode_choice_intel_goldens_test.dart` captures each keyed `RepaintBoundary`, then each `matchesGoldenFile` baseline under `app/test/goldens/combat_mode_choice_*.png` matches the committed PNG (Refs #4438).
