# Tile radial catalog (component)

**SPEC/ui/components** — Conceivable `MAP20001` Tile shortcuts for `MAP30001` / `MAP30002`. Implementation: `app/lib/features/game/widgets/map_radial/tile_radial_catalog.dart`. Not a screen. Does not invent orders or extra `OpenCivilianUnitsPanelEvent` fields.

## Catalog

Only three actions, in this priority after enablement:

1. Explore
2. Prospect
3. Build improvement

Conceivable means `ProvinceActionStateCalculator` `showIcon == true` for that slot. Hidden overlay icons never appear. Do not include Spy station, Blockade, Beachhead, Move, Invade, Establish Consulate, Build road / railroad / port / fort, Purchase land, or Upgrade town.

## Ranking

1. Filter to conceivable actions.
2. Sort **enabled** before **disabled-but-visible**, then by the catalog order above.
3. Take at most **five** wedges. Remainder (empty with a three-action catalog) goes to `MAP30002`.

## Layout size

Each wedge is at least 44 dp. Always count a **More** spoke in addition to action wedges. If three action wedges plus More cannot fit in the viewport after clamp, skip `MAP30001` and open `MAP30002` directly.

## Acceptance criteria

- Given Explore and Prospect `showIcon` are true and Build improvement is hidden, when ranking runs, then wedges are those two only (enabled before disabled) plus no remainder. (`app/test/tile_radial_catalog_test.dart`)
- Given all three `showIcon` are true, Prospect enabled, Explore disabled-but-visible, when ranking runs, then Prospect precedes Explore, then Build improvement. (`app/test/tile_radial_catalog_test.dart`)
- Given a viewport smaller than three wedges plus More after clamp, when the host opens, then it shows `MAP30002` and not `MAP30001`. (`app/test/tile_radial_host_test.dart`)
