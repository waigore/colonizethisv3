# Victory panel

**Screen ID:** `GAME70001` — stable; do not reassign.
**SPEC/ui** — Mid-campaign victory conditions and Great Power standings toward the Old World province win. Implementation: `app/lib/features/game/screens/victory/victory_screen.dart`.
**Widgetbook:** `Victory Screen` → `widgetbook_host/lib/catalogs/catalog_data_screens.dart`

## Widget contract

| Name | Type | Required | Description |
|------|------|----------|-------------|
| `game` | `Game` | yes | Live campaign state |
| `humanPlayerId` | `String` | yes | Human Great Power id for row emphasis |

## Trigger conditions

- Left-rail **Victory** button (`kEmpireVictoryButtonKey`), always **last** among core empire buttons (after Technology).
- `MAP10001` tab-bar **Old World race chip** (same `NavigateToRouteEvent` payload as the left-rail button). See [old-world-race-chip.md](components/old-world-race-chip.md).
- `NavigateToRouteEvent(Routes.victory, {game, humanPlayerId})` from bus wiring on `GameScreen`.
- Route path: `/game/victory`.

## Layout / wireframe

Narrow (`< 600` dp): `CtDarkScaffold` → `CtTopBar` (← Map) → scroll: optional end-state banner, conditions, stacked standings then minimap.

Wide (`≥ 600` dp + map data): same header/conditions; standings and minimap in one equal-flex row. Without map data, standings are full width.

## Behavior

### Incoming

| Source | Condition | Result |
|--------|-----------|--------|
| Left rail Victory | always (non-debug seventh button) | `NavigateToRouteEvent` → `VictoryScreen` |
| Tab-bar Old World race chip | `Game.victory == null` | Same `NavigateToRouteEvent(Routes.victory, {game, humanPlayerId})` |
| Observe mode | global observe without player | `ObserveModeNotDefinedPanel` via shell guard |

### User actions

| Control | When enabled | Emits / calls | Side effects |
|---------|--------------|---------------|--------------|
| ← Map | always | `Navigator.pop` via `CtTopBar` | returns to map |
| GP row body tap | always | local `selectedPlayerId` | highlights faction OW provinces on minimap; emphasizes standings row |
| GP expand chevron | always | local expand/collapse | reveals power-score breakdown only |
| Political minimap hover/tap | map data available | local highlight + inspect line | shows origin inspect; GP-owned province tap also selects owning GP row |

### Open default

- On first build, `selectedPlayerId` is the human Great Power (`humanPlayerId` route arg).
- Minimap de-emphasizes non-selected owners; selected faction provinces render at full ownership colour.

### Conditions calendar remaining

Province-count line first. Live `gdd01` countdown: current year, last year 1800, remaining years, remaining full turns (`capTurn − current`). Cap turn: remaining 0, never negative. Omit countdown for infinite mode (keep bypass), halt/`victory`, or no 1800 turn on the mapping.

### Standings progress

- GP rows show `{count} / {threshold}` with a 0…threshold bar (caps at full at/above threshold). Sort: OW count desc, display-name asc.

### Selection linkage

Row body selects GP (map highlight). Chevron toggles breakdown only. GP-owned minimap tap selects that GP. Minor/unowned inspect keeps last GP. Narrow: one `VictoryScreenBody` selection for stacked cards.

## Political minimap

Old World only; tile cells from `buildVictoryOldWorldMapViewData`; hidden without map data. Owner colour / minor grey. Labels at centroids (ellipsize); capital outline; town dots. Hover/tap: founding vs captured via `originalOwnerId`, or founding-owner-unknown (no invented history).

## States and variants

`GAME70001` default mid-campaign; military complete (`victory`); calendar halt; infinite bypass. `GAME70001a` wide side-by-side; `GAME70001b` annotated minimap; `GAME70001c` rival GP selected.

## Acceptance criteria

- **Given** the map shell is visible, **when** the player inspects the left rail, **then** a Victory control is the **last** core empire button and opens `GAME70001` with `← Map`.
- **Given** conditions render, **when** shown, **then** the UI layer states a 31+ Old World province win in plain language (no “military victory” type label) and calendar-end rules; infinite bypass appears when `infiniteMode` is true.
- **Given** `gdd01` at turn 42 (year 1582), **when** conditions render, **then** the UI layer names year 1582, last year 1800, remaining years 218, remaining full turns 159, and does not use “near 1800 (turn 201)” as the only calendar sentence. Tests: `app/test/victory_panel_goldens_test.dart`, `app/test/campaign_calendar_clock_test.dart`.
- **Given** `infiniteMode`, **when** conditions render, **then** the UI layer omits remaining-years countdown and keeps the bypass line.
- **Given** cap turn 201 / year 1800 and not halted, **when** conditions render, **then** the UI layer states last campaign year with remaining 0.
- **Given** halt or `victory != null`, **when** conditions render, **then** the UI layer shows no positive remaining countdown.
- **Given** no 1800 start turn on the mapping, **when** conditions render, **then** the UI layer invents no halt countdown.
- **Given** multiple GPs, **when** standings render, **then** GPs sort by OW count desc / name asc, each `count / threshold`, human row emphasized, human selected on open.
- **Given** a collapsed GP row, **when** shown, **then** calendar-end totals are hidden; **when** expand is used, **then** province / regiment / ship totals and overall strength appear as calendar-end only (no `× weight =`); row-body tap selects the map without expand.
- **Given** a GP selected, **when** the minimap renders, **then** that faction is full colour and others de-emphasized.
- **Given** a GP-owned province tap, **when** inspect runs, **then** that GP row is selected and inspect text remains.
- **Given** standings header, **when** shown, **then** helper copy explains colour/map linkage.
- **Given** the minimap, **when** OW provinces render, **then** GP colour / minor grey match editorial-monocle chrome.
- **Given** `originalOwnerId`, **when** hover/tap, **then** founding vs captured is named; without origin, founding-owner-unknown (no invented history).
- **Given** mid-campaign or end-state, **when** copy is read, **then** “military victory” does not appear.
- **Given** width ≥ 600 dp and map data, **when** rendered, **then** standings and minimap are side-by-side below conditions.
- **Given** width < 600 dp, **when** rendered, **then** conditions, standings, minimap stack in that order.
- **Given** naming data, **when** OW land renders, **then** names at centroids (ellipsize), capital outlines, and town markers at `townTileKey`.

## Widgetbook

**Victory Screen** (`catalog_data_screens.dart`): default remaining; mobile wrap; wide `GAME70001a`; infinite (no countdown); last year remaining 0; rival `GAME70001c`; annotated minimap `GAME70001b`.

## References

- `SPEC/game/victory.md`
- `SPEC/game/turn-time-mapping.md`
- `SPEC/game/diplomacy.md` § Great Power power score
- `SPEC/ui/empire-buttons.md`
- `SPEC/ui/mobile-adaptation.md`
- `SPEC/ui/victory-overlay.md` (`OVL20001` military + calendar-complete variants)
