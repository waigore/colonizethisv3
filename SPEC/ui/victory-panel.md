# Victory panel

**Screen ID:** `GAME70001` — stable; do not reassign.
**SPEC/ui** — Mid-campaign victory conditions and Great Power standings toward military victory. Implementation: `app/lib/features/game/screens/victory/victory_screen.dart`.
**Widgetbook:** `Victory Screen` → `widgetbook_host/lib/catalogs/catalog_data_screens.dart`

## Widget contract

| Name | Type | Required | Description |
|------|------|----------|-------------|
| `game` | `Game` | yes | Live campaign state |
| `humanPlayerId` | `String` | yes | Human Great Power id for row emphasis |

## Trigger conditions

- Left-rail **Victory** button (`kEmpireVictoryButtonKey`), always **last** among core empire buttons (after Technology).
- `NavigateToRouteEvent(Routes.victory, {game, humanPlayerId})` from bus wiring on `GameScreen`.
- Route path: `/game/victory`.

## Layout / wireframe

### Narrow (`< kNarrowBreakpoint`, 600 dp)

```
CtDarkScaffold
  CtTopBar (← Map, victory icon, "Victory")
  SingleChildScrollView (compact padding)
    [optional] end-state banner
    conditions card
    Column
      standings card
      political minimap card (when map data available)
```

### Wide (`≥ kNarrowBreakpoint`, 600 dp, map data available)

```
CtDarkScaffold
  CtTopBar
  SingleChildScrollView (compact padding)
    [optional] end-state banner
    conditions card
    Row (standings left, minimap right, equal flex)
      standings card
      political minimap card
```

When map data is unavailable, standings render full width at all breakpoints.

## Behavior

### Incoming

| Source | Condition | Result |
|--------|-----------|--------|
| Left rail Victory | always (non-debug seventh button) | `NavigateToRouteEvent` → `VictoryScreen` |
| Observe mode | global observe without player | `ObserveModeNotDefinedPanel` via shell guard |

### User actions

| Control | When enabled | Emits / calls | Side effects |
|---------|--------------|---------------|--------------|
| ← Map | always | `Navigator.pop` via `CtTopBar` | returns to map |
| GP row tap | always | local expand/collapse | reveals power-score breakdown |
| Political minimap hover/tap | map data available | local highlight + inspect line | shows original vs captured copy per `originalOwnerId` |

## Political minimap

- **Scope:** Old World only; one cell per map tile painted with owning faction colour from `factionOwnershipColorMapForOldWorld` (minor nations use grey palette entries).
- **Data:** Built from persisted tile map + topology via `buildVictoryOldWorldMapViewData`; section hidden when map data is unavailable (e.g. lightweight widget-test fixtures).
- **Annotations:** Each land province shows its display name at the tile-centroid (ellipsized when the footprint is small). Provinces containing a faction's **current** capital (`capitalMarkers`) render a bright province-outline border. Each province town (`townMarkers` from `Province.townTileKey`) renders a simplified editorial-monocle marker dot.
- **Inspect:** Hover (pointer) or tap selects a land province and shows whether it is still the **original** owner's province or was **captured**, naming the founding owner when `Province.originalOwnerId` is present; legacy saves without origin show **Origin unavailable** copy (no invented capture history).

## States and variants

| ID | Variant | Trigger | Render difference |
|----|---------|---------|-------------------|
| `GAME70001` | default | mid-campaign | conditions + standings; no end-state banner |
| `GAME70001` | military complete | `Game.victory != null` | end-state banner names military winner |
| `GAME70001` | calendar halt | `calendarCampaignHalted` | end-state banner names declared power-score winner or tie |
| `GAME70001` | infinite mode | `Game.infiniteMode` | conditions include infinite bypass line |
| `GAME70001a` | wide side-by-side | viewport ≥ 600 dp + map data | standings and minimap in one row below conditions |
| `GAME70001b` | annotated minimap | map data with naming / capitals / towns | province labels, capital borders, town dots on minimap |

## Acceptance criteria

- **Given** the map shell is visible, **when** the player inspects the left rail, **then** a Victory control is present as the **last** core empire button and opens `GAME70001` with `← Map` return.
- **Given** the Victory panel is open, **when** the conditions section renders, **then** military victory requires **31 or more Old World provinces** prominently, calendar-end rules are stated, and infinite-mode bypass copy appears when `infiniteMode` is true.
- **Given** multiple Great Powers, **when** standings render, **then** only GPs appear sorted by OW count descending with display-name tie-break, each showing OW count, and the human row is emphasized.
- **Given** a GP row is collapsed, **when** shown, **then** power score is hidden; **when** expanded, **then** total power score and province / regiment / ship breakdown appear with copy distinguishing power score from the OW military meter.
- **Given** the political minimap is shown, **when** Old World provinces render, **then** each province uses the owning GP's colour and Minor-owned provinces use grey, in chrome consistent with the editorial-monocle L&F.
- **Given** `originalOwnerId` is present, **when** the player hovers or taps a province on the political minimap, **then** the UI states whether it is still the original owner's province or was captured, naming the founding owner; **given** legacy data without origin, **when** inspect is used, **then** the UI shows origin-unavailable copy without inventing capture history.
- **Given** viewport width is at least `kNarrowBreakpoint` (600 dp) and map data is available, **when** the Victory panel renders, **then** Great Power standings and the political minimap appear side-by-side below the conditions block with compact section spacing.
- **Given** viewport width is below 600 dp, **when** the Victory panel renders, **then** conditions, standings, and minimap remain stacked vertically in that order.
- **Given** the political minimap is shown with naming data, **when** Old World land provinces render, **then** each province's display name appears at its centroid (readable or ellipsized when the footprint is small), capital provinces are outlined, and town markers appear at each `townTileKey`.

## References

- `SPEC/game/victory.md`
- `SPEC/game/turn-time-mapping.md`
- `SPEC/game/diplomacy.md` § Great Power power score
- `SPEC/ui/empire-buttons.md`
- `SPEC/ui/mobile-adaptation.md`
- `SPEC/ui/victory-overlay.md` (`OVL20001` post-military overlay unchanged)
