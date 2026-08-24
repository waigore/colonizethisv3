# More tile actions

**Screen ID:** `MAP30002` — stable; do not reassign.
**SPEC/ui** — Overflow list for tile radial remainder plus Province details. Implementation: `app/lib/features/game/widgets/map_radial/tile_more_actions_dialog.dart`.
**Widgetbook:** `More Tile Actions` → `widgetbook_host/lib/catalogs/catalog_tile_radial.dart`

## Widget contract

| Name | Type | Required | Description |
|------|------|----------|-------------|
| `placeLine` | `String` | yes | Place name for context. |
| `remainder` | `List<TileRadialSpokeView>` | yes | Conceivable catalog actions not already on `MAP30001`. |
| `onAction` | `ValueChanged<TileRadialCatalogAction>` | yes | Enabled row commit (same overlay events). |
| `onProvinceDetails` | `VoidCallback` | yes | Select tile and open/focus `MAP20001`. |

Local `showDialog` is allowed. Barrier / back pop the route; the host then dismisses `MAP30001`.

## Trigger conditions

More spoke on `MAP30001`, or secondary gesture when five wedges plus More cannot fit after clamp.

## Layout / wireframe

```
CtDialogShell
  title: More tile actions
  Province details (first row)
  remainder rows (catalog overflow from tile-radial-catalog.md)
```

No Station spy, Counter-espionage, Blockade, Beachhead, Move, Invade, Establish Consulate, or Offer Peace. Remainder may include Build road / railroad / port / fort, Purchase land, or Upgrade town when those are conceivable and did not fit on `MAP30001`. If remainder is empty, only Province details remains. Enabled **Build improvement** remainder rows show the next-yield gist (Refs #4627).

## Behavior

| Control | When enabled | Emits / calls |
|---------|--------------|---------------|
| Province details | Always | `reportMapTileTapped` / overlay open; close radial + dialog |
| Remainder row | Overlay enabled | Matching `OpenCivilianUnitsPanelEvent` shortcut fields |
| Disabled remainder | Visible | Tooltip only; no commit |
| Barrier | — | Dismiss |

## States and variants

| ID | Render |
|----|--------|
| `MAP30002` | Province details + optional remainder |
| `MAP30002` empty remainder | Province details only |
| `MAP30002` 320 dp | Wrap; no horizontal overflow |

## Widgetbook

Folder **More Tile Actions**. Use cases: empty remainder; remainder Prospect; remainder Build road overflow; 320 dp.

## Acceptance criteria

- Given More is activated, when the dialog opens, then it lists leftover catalog actions plus Province details and does not list excluded non-catalog actions. (`app/test/tile_more_actions_dialog_test.dart`)
- Given Province details, when activated, then `MAP20001` opens/updates for that tile and the radial/dialog close. (`app/test/tile_radial_host_test.dart`)
- Given an enabled remainder Explore row, when activated, then the UI emits the same Explore shortcut event as `MAP20001`. (`app/test/tile_radial_emit_test.dart`)
- Given an enabled Purchase land remainder row, when the dialog renders, then the qualitative payoff gist is default-visible (not tooltip-only). (`app/test/purchase_land_payoff_copy_test.dart`)
