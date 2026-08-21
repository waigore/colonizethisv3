# Tile context radial

**Screen ID:** `MAP30001` — stable; do not reassign.
**SPEC/ui** — Map-attached radial for overlay Tile shortcuts. Implementation: `app/lib/features/game/widgets/map_radial/tile_context_radial.dart`.
**Widgetbook:** `Tile Context Radial` → `widgetbook_host/lib/catalogs/catalog_tile_radial.dart`

## Widget contract

| Name | Type | Required | Description |
|------|------|----------|-------------|
| `placeLine` | `String` | yes | Same Place string as MAP10001 hover readout. |
| `wedges` | `List<TileRadialSpokeView>` | yes | At most five conceivable catalog actions. |
| `onWedge` | `ValueChanged<TileRadialCatalogAction>` | yes | Enabled commit. Disabled wedges do not call this. |
| `onMore` | `VoidCallback` | yes | Opens `MAP30002`. |
| `onDismiss` | `VoidCallback` | yes | Outside tap, Esc, pan, or spoke after commit. |

## Trigger conditions

Flutter shell opens this overlay when `canMutateViaUi` is true, work-target selection is off, and a right-click or ~500 ms long-press hits a tile after army / fleet / civilian marker tests miss. Flame reports tile key plus local offset only. Primary tap still uses `onMapTileTappedForDetail` → `MAP20001`. Observe / `canMutateViaUi == false` does not open it.

## Layout / wireframe

```
Stack (viewport)
  barrier (tap outside → dismiss)
  Positioned (clamped)
    hub: Place line (Ct text, --fg)
    wedges ≥ 44 dp: up to five catalog actions (see tile-radial-catalog.md)
    More spoke
```

Editorial-monocle tokens only (`EditorialMonoclePalette`). No Material dialog chrome. Labels are player words, not icon-only. Catalog: Explore → Prospect → Build improvement → Build road → Purchase land → Upgrade town → Build port → Build railroad → Build fort ([tile-radial-catalog.md](components/tile-radial-catalog.md)).

## Behavior

### Incoming

| Source | Condition | Result |
|--------|-----------|--------|
| Secondary pointer | Marker miss, mutate allowed | Open radial for that tile key |
| Long-press | Pan slop not exceeded | Same |
| Layout too small | Five wedges + More cannot fit | Skip; open `MAP30002` |

### User actions → outcomes

| Control | When enabled | Emits / calls | Side effects |
|---------|--------------|---------------|--------------|
| Catalog wedge (nine actions) | Overlay `enabled` | Same `OpenCivilianUnitsPanelEvent` shortcut fields as `MAP20001` | Dismiss radial |
| Disabled wedge | Visible teachable gate | None | Tooltip / semantics only (overlay refusal copy) |
| More | Always | Open `MAP30002` | Dismiss radial |
| Outside / Esc / pan | — | Dismiss | No order |

## States and variants

| ID | Render |
|----|--------|
| `MAP30001` | 0–5 wedges + More |
| `MAP30001` empty | Hub + More only |
| `MAP30001` disabled | Visible disabled wedge, no commit |
| `MAP30001` overflow | Five wedges; remainder on `MAP30002` |
| `MAP30001` 320 dp | Clamp; else `MAP30002` |

## Widgetbook

Folder **Tile Context Radial**. Use cases: enabled three wedges; Prospect enabled Explore disabled; empty catalog More-only; sea-zone few shortcuts; five wedges with remainder; 320 dp clamp.

## Acceptance criteria

- Given mutate is allowed and markers miss, when the player right-clicks or long-presses a tile, then `MAP30001` opens for that tile key and does not start army, fleet, or civilian-marker flows. (`app/test/ct_region_map_tile_radial_secondary_test.dart`, `app/test/tile_radial_host_test.dart`)
- Given the radial renders, then it shows at most five catalog wedges plus More and does not pad inconceivable actions. (`app/test/tile_context_radial_test.dart`, `app/test/tile_radial_catalog_test.dart`)
- Given an enabled Explore spoke, when activated, then the UI emits `OpenCivilianUnitsPanelEvent(explorerOnly: true, exploreShortcutTargetTileKey: tileKey)`. (`app/test/tile_radial_emit_test.dart`)
- Given a disabled visible wedge, when activated, then no order is committed and overlay refusal copy is shown. (`app/test/tile_context_radial_test.dart`)
- Given a primary tap, when it completes, then `MAP20001` still opens and the radial does not. (`app/test/ct_region_map_tile_radial_secondary_test.dart`)
- Given work-target selection or `canMutateViaUi == false`, when secondary gesture fires, then the radial does not open. (`app/test/game_map_area_selection_mode_lightweight_test.dart`, `app/test/tile_radial_host_test.dart`)
