# Old World race chip

**SPEC/ui/components** — Always-visible `MAP10001` tab-bar control showing Old World province counts toward the 31-province win. No new screen ID. Refs #4451.

## Purpose

Let the player see `N / 31` for their court (and a rival leader when that court is ahead) without opening `GAME70001`. Calendar-end overall strength stays on the optional players bar, on request only.

## Widget contract

| Name | Type | Required | Description |
|------|------|----------|-------------|
| `snapshot` | `OldWorldRaceSnapshot` | yes | Focus count, threshold, optional rival |
| `narrow` | `bool` | no | Compact copy when viewport `< 600` dp |
| `onTap` | `VoidCallback?` | no | Opens `GAME70001` |

`OldWorldRaceSnapshot.fromGame(game, focusPlayerId)` uses `oldWorldProvinceCountOwnedBy` and `kMilitaryVictoryOldWorldProvinceThreshold`. Rival cue only when another Great Power’s Old World count is **strictly greater** than the focus court. Tied or human-ahead: no rival cue. Global observe uses the current Old World leader as focus (no rival cue). Hidden when `Game.victory != null`.

## Layout / wireframe

```
[victory icon 18]  {count} / {threshold}[ · {rivalName} {rivalCount} / {threshold}]
```

Narrow: `{count}/{threshold}` and ` · {rivalName} {rivalCount}` (no second threshold). Max width 108 dp narrow / 220 dp wide; `FittedBox` scale-down if needed. The tab-bar trailing cluster (treasury, cargo, race, toggles) also uses `FittedBox` scale-down so 320 dp does not overflow. Family: treasury/cargo (monospace `--accent-dim`, 1 px `--border` left rule).

Tab-bar order: `treasury → cargo → labour/feeding → race chip → players-bar toggle → news`.

## Behavior

| Control | When enabled | Emits / calls |
|---------|--------------|---------------|
| Tap / activate | `Game.victory == null` | `NavigateToRouteEvent(Routes.victory, {game, humanPlayerId})` — same args as left-rail Victory |
| Tooltip / semantics | chip visible | Plain-language Old World race; tap opens Victory |

Does not emit overlay bus events. Does not auto-open, nag at end of turn, or float a second standings panel.

## Consumers

- `GameTabBar` / `GameMapControls` on `MAP10001`
- Widgetbook **Game Tab Bar**

## Widgetbook

Folder: **Game Tab Bar** — `widgetbook_host/lib/catalogs/catalog_game_chrome.dart`

| Use case | What it proves |
|----------|----------------|
| Old World race — human ahead | Focus `N / 31`; no rival cue |
| Old World race — rival ahead | Rival name + `N / 31` |
| Old World race — players bar hidden | Chip visible while players-bar toggle is off |
| Old World race — 320 dp rival ahead | Compact copy; no overflow |

Folder: **Players Bar** — `Human GP highlighted — Old World N / 31` shows default chip numbers as `N / 31`.

## Acceptance criteria (Given–When–Then)

- **Given** a mid-campaign map with `Game.victory == null`, **when** the tab bar renders, **then** the UI layer shows the focus Great Power’s Old World count and the 31 threshold as `N / 31` (not a power-score integer). Tests: `app/test/old_world_race_chip_test.dart`.
- **Given** another Great Power holds more Old World provinces than the focus court, **when** the chip renders, **then** the UI layer also names that leader and their `N / 31`.
- **Given** the focus court leads or ties, **when** the chip renders, **then** the UI layer omits the rival cue.
- **Given** the player activates the chip, **when** navigation runs, **then** the UI layer emits `NavigateToRouteEvent(Routes.victory, {game, humanPlayerId})`.
- **Given** `showPlayersBar == false`, **when** the map loads, **then** the race chip remains visible.
- **Given** `Game.victory != null`, **when** the map renders, **then** the race chip is not mounted.
- **Given** a 320–360 dp viewport, **when** the tab bar renders, **then** the race chip does not overflow or collide with treasury, cargo, or news. Golden: `app/test/goldens/old_world_race_chip_320dp.png`.

## Tests

- `app/test/old_world_race_snapshot_test.dart`
- `app/test/old_world_race_chip_test.dart`
- `app/test/old_world_race_chip_goldens_test.dart`

## Related

- [empire-overview.md](../empire-overview.md) § Tab bar chrome / § Players bar
- [victory-panel.md](../victory-panel.md) § Trigger conditions
- [victory.md](../../game/victory.md)
