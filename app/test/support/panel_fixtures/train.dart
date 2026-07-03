// Shared lightweight, hand-built [Game] fixtures for app panel widget tests.
//
// Split into focused modules under `panel_fixtures/`; import via
// `panel_test_fixtures.dart` barrel (Refs #3847).

import 'package:colonizethis_data/colonizethis_data.dart'
    show unlockingTechByRegimentId, unlockingTechByShipId;
import 'package:colonizethis_logic/colonizethis_logic.dart' show homeFleetIdFor;
import 'package:colonizethis_models/colonizethis_models.dart';

import 'core.dart';

/// Lightweight game shaped for the train-at-capital dialog family
/// (`train_military_dialog_test`, `train_naval_dialog_test`,
/// `train_civilians_dialog_test`, `train_dialog_base_test`,
/// `train_dialog_inline_cost_tooltip_test`,
/// `train_dialogs_320dp_min_viewport_test`).
///
/// The train dialogs and the unit panels that open them read only `game.players`
/// (the human with a **capital**, plus the owning player's units/fleets) — no
/// generated map/topology data. The human player is pre-equipped so the dialogs
/// render full trainable rows even when a test passes the base game directly
/// (the cost-tooltip and 320 dp suites build the dialog without a rich
/// `copyWith`):
/// - a **capital** in the old world ([CapitalTile] + `capitalProvinceId`) so
///   `hasCapital` is true and the resource bar / steppers render;
/// - **all regiment and ship unlocking tech** so every Train Military / Train
///   Naval row (and its commodity cost icons/tooltips) renders;
/// - generous `treasury`, `peasants`, and `stockpile` so rows are affordable by
///   default (suites that need a deficit override via `copyWith`).
///
/// It also carries an old-world [Army] (two regiments), a home [Fleet] in port
/// at the capital plus a non-home fleet at sea, and idle civilians at the
/// capital, so the Military / Naval / Civilian panels render their Train pill
/// and open the matching dialog. A non-human opponent (`gp2`) keeps
/// "other players" filters non-vacuous.
Game buildTrainPanelTestGame() {
  const human = kPanelTestHumanPlayerId;
  const ow = 'oldWorld';
  const nw = 'newWorld';
  const capProvince = 'oldWorld|cap';
  const oldPort = 'oldWorld|p2';
  const newPort = 'newWorld|np1';
  const seaZoneId = 'sz0';
  const type = kPanelTestRegimentType;
  final homeFleetId = homeFleetIdFor(human);
  final techUnlocked = <String, bool>{
    for (final techId in unlockingTechByRegimentId.values) techId: true,
    for (final techId in unlockingTechByShipId.values) techId: true,
  };
  const stockpile = Stockpile(
    quantities: {
      'fabric': 1000,
      'castIron': 1000,
      'lumber': 1000,
      'horses': 1000,
      'steel': 1000,
      'bronze': 1000,
      'coal': 1000,
      'paper': 1000,
    },
  );
  return buildPanelTestGame(
    id: 'train-panel-widget-test',
    oldWorldProvinces: const [
      Province(
        id: capProvince,
        regionId: ow,
        ownerId: human,
        displayName: 'Capital',
        townTileKey: 'oldWorld|cap|0|0',
      ),
      Province(
        id: oldPort,
        regionId: ow,
        ownerId: human,
        displayName: 'Porto',
        townTileKey: 'oldWorld|p2|0|0',
      ),
    ],
    oldWorldUnits: [
      Unit(
        id: 'reg_old_1',
        type: type,
        ownerId: human,
        locationProvinceId: capProvince,
        medals: 1,
      ),
      Unit(
        id: 'reg_old_2',
        type: type,
        ownerId: human,
        locationProvinceId: capProvince,
        medals: 2,
      ),
      Unit(
        id: 'civ_builder',
        type: kUnitTypeBuilder,
        ownerId: human,
        locationProvinceId: capProvince,
        tileKey: 'oldWorld|cap|1|0',
      ),
      Unit(
        id: 'civ_explorer',
        type: kUnitTypeExplorer,
        ownerId: human,
        locationProvinceId: capProvince,
        tileKey: 'oldWorld|cap|1|1',
      ),
    ],
    newWorldProvinces: const [
      Province(
        id: newPort,
        regionId: nw,
        ownerId: human,
        displayName: 'Newhaven',
        townTileKey: 'newWorld|np1|0|0',
      ),
    ],
    armies: const [
      Army(
        id: 'army_old',
        ownerId: human,
        regionId: ow,
        stationedProvinceId: capProvince,
        regimentUnitIds: ['reg_old_1', 'reg_old_2'],
        isHomeArmy: false,
      ),
    ],
    fleets: [
      Fleet(
        id: homeFleetId,
        ownerId: human,
        regionId: ow,
        inPortAtProvinceId: capProvince,
        ships: const [
          ShipInstance(id: 'h1', typeId: 'carrack'),
          ShipInstance(id: 'h2', typeId: 'galleon'),
        ],
      ),
      Fleet(
        id: 'fleet_nh1',
        ownerId: human,
        regionId: ow,
        seaZoneId: seaZoneId,
        ships: const [
          ShipInstance(id: 'n1', typeId: 'carrack'),
          ShipInstance(id: 'n2', typeId: 'carrack'),
        ],
      ),
    ],
    portsByProvinceSeaboard: const {
      'oldWorld|cap|$seaZoneId': 'oldWorld|cap|0|0',
    },
    tileKeysByRegionAndProvince: const {
      ow: {
        capProvince: ['oldWorld|cap|0|0'],
        oldPort: ['oldWorld|p2|0|0'],
      },
      nw: {
        newPort: ['newWorld|np1|0|0'],
      },
    },
    seaZoneDisplayNameById: const {'oldWorld|$seaZoneId': 'Northern Sea'},
    players: [
      Player(
        id: human,
        displayName: 'Test Human',
        isHuman: true,
        capitalProvinceId: capProvince,
        capitalTile: const CapitalTile(
          regionId: ow,
          provinceId: capProvince,
          x: 0,
          y: 0,
        ),
        treasury: 50000,
        techUnlocked: techUnlocked,
        workerPool: const WorkerPool(peasants: 20),
        stockpile: stockpile,
      ),
      const Player(id: 'gp2', displayName: 'Rival Power', isHuman: false),
    ],
  );
}

/// Lightweight game shaped for the in-game unit-panel chrome family
/// (`unit_panels_320dp_min_viewport_test`,
/// `unit_panels_widgetbook_dark_chrome_test`).
///
/// These suites mount the Civilian / Military / Naval `UnitsPanelShell` (and the
/// Widgetbook Train dialogs) together and assert **chrome only** — the panel
/// title text, the absence of banned Material chrome, no `RenderFlex` overflow,
/// and the editorial-monocle dark theme — never reading generated
/// map/topology data. The combined train fixture already carries a single human
/// (with a capital, all train tech, and treasury/stockpile) plus civilians, an
/// army with regiments, and home/non-home fleets across both regions, so it is
/// exactly the multi-family shape these panels render. A `const MapTopology()`
/// replaces the debug-init `combinedTopology` the assertions never inspect.
Game buildUnitPanelsTestGame() => buildTrainPanelTestGame();
