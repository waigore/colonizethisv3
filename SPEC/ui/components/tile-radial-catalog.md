# Tile radial catalog (component)

**SPEC/ui/components** — Conceivable `MAP20001` civilian work shortcuts for `MAP30001` / `MAP30002`. Implementation: `app/lib/features/game/widgets/map_radial/tile_radial_catalog.dart`. Not a screen. Does not invent orders or extra `OpenCivilianUnitsPanelEvent` fields.

## Catalog

Nine actions, in this priority after enablement (canonical `kTileRadialCatalogOrder`):

1. Explore
2. Prospect
3. Build improvement
4. Build road
5. Purchase land
6. Upgrade town
7. Build port
8. Build railroad
9. Build fort

Conceivable means overlay `showIcon == true` for that slot (`ProvinceActionStateCalculator` for the eight inline actions). **Upgrade town:** conceivable only when the selected tile **is** the province town tile **and** overlay `provinceUpgradeTownActionState.showControl` is true (same source as `MAP20001`: `GameMapAreaStateLogicProvinceActions.provinceUpgradeTownActionState`). Hidden overlay icons never appear.

Do **not** include Station spy, Counter-espionage, Blockade, Beachhead, Move, Invade, Establish Consulate, or Offer Peace.

## Ranking

1. Filter to conceivable actions.
2. Sort **enabled** before **disabled-but-visible**, then by the catalog order above.
3. Take at most **five** wedges for `MAP30001`. Remainder goes to `MAP30002` with **Province details**. Core three are not guaranteed a `MAP30001` wedge when displaced by enabled later catalog actions under the five-wedge cap.

## Layout size

Each wedge is at least 44 dp. Always count a **More** spoke in addition to action wedges. If five wedges plus More cannot fit in the viewport after clamp, skip `MAP30001` and open `MAP30002` directly.

## Acceptance criteria

- Given Explore and Prospect `showIcon` are true and Build improvement is hidden, when ranking runs, then wedges are those two only (enabled before disabled) plus no remainder. (`app/test/tile_radial_catalog_test.dart`)
- Given all three core `showIcon` are true, Prospect enabled, Explore disabled-but-visible, when ranking runs, then Prospect precedes Explore, then Build improvement. (`app/test/tile_radial_catalog_test.dart`)
- Given more than five conceivable catalog actions, when ranking runs, then `MAP30001` shows five wedges (enabled before disabled, then catalog order) and the remainder is for `MAP30002`. (`app/test/tile_radial_catalog_test.dart`)
- Given a viewport smaller than five wedges plus More after clamp, when the host opens, then it shows `MAP30002` and not `MAP30001`. (`app/test/tile_radial_host_test.dart`)
