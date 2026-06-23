// Shared lightweight, hand-built [Game] fixtures for app panel widget tests.
//
// These avoid the ~7-11s procedural map generation paid by
// `getDebugInitGameResult()` once per test isolate (Refs #3656). Panels that
// only render from a `Game` (no generated map/topology data) can build the
// minimum shape their assertions read instead of generating a full game.
//
// Modeled on `app/test/production_panel_test_fixtures.dart`; generalize
// incrementally per family rather than adding a monolithic config up front.

import 'package:colonizethis_logic/colonizethis_logic.dart'
    show kWorkTargetBuildImprovement, homeFleetIdFor;
import 'package:colonizethis_models/colonizethis_models.dart';

/// Default human great-power id used by the lightweight panel fixtures.
const String kPanelTestHumanPlayerId = 'gp1';

/// A single human [Player] with no stockpile/worker customization.
Player panelTestHumanPlayer({
  String id = kPanelTestHumanPlayerId,
  String displayName = 'Test Human',
}) {
  return Player(id: id, displayName: displayName, isHuman: true);
}

/// Builds a lightweight [Game] with explicit per-region provinces/units and
/// fleets. No map generation, topology, or tile data is produced; route any
/// test that needs real generated map/topology data to the serialized-fixture
/// path or the documented `getDebugInitGameResult()` allowlist instead.
Game buildPanelTestGame({
  List<Player>? players,
  List<Province> oldWorldProvinces = const [],
  List<Unit> oldWorldUnits = const [],
  List<Province> newWorldProvinces = const [],
  List<Unit> newWorldUnits = const [],
  List<Fleet> fleets = const [],
  List<Army> armies = const [],
  Map<String, String> portsByProvinceSeaboard = const {},
  Map<String, Map<String, List<String>>> tileKeysByRegionAndProvince =
      const {},
  Map<String, String> seaZoneDisplayNameById = const {},
  String id = 'panel-widget-test',
  TurnState turnState = const TurnState(
    phase: TurnPhase.orders,
    turnNumber: 1,
  ),
}) {
  return Game(
    id: id,
    worldState: WorldState(
      turnState: turnState,
      oldWorld: RegionData(
        provinces: oldWorldProvinces,
        units: oldWorldUnits,
      ),
      newWorld: RegionData(
        provinces: newWorldProvinces,
        units: newWorldUnits,
      ),
      fleets: fleets,
      armies: armies,
      portsByProvinceSeaboard: portsByProvinceSeaboard,
      tileKeysByRegionAndProvince: tileKeysByRegionAndProvince,
      seaZoneDisplayNameById: seaZoneDisplayNameById,
    ),
    players: players ?? [panelTestHumanPlayer()],
  );
}

/// Lightweight game shaped for the `civilian_units_panel_test_part*` family.
///
/// Covers what those parts read from `game`:
/// - one human player ([kPanelTestHumanPlayerId]) owning idle civilians of the
///   types the panel groups/labels (Builder, Explorer, Engineer, Merchant), in
///   **both** regions, each with a `tileKey` and a `locationProvinceId`;
/// - allowed work targets exist for those types so the assign-menu assertions
///   run;
/// - one in-progress (working) civilian so the in-progress cancel path renders.
///
/// A non-owning player id (e.g. `'no-such-player'`) exercises the empty state.
Game buildCivilianPanelTestGame() {
  const human = kPanelTestHumanPlayerId;
  const p1 = 'oldWorld|p1';
  const np1 = 'newWorld|np1';
  return buildPanelTestGame(
    id: 'civilian-panel-widget-test',
    oldWorldProvinces: const [
      Province(
        id: p1,
        regionId: 'oldWorld',
        ownerId: human,
        displayName: 'Alpha',
      ),
      Province(
        id: 'oldWorld|p2',
        regionId: 'oldWorld',
        ownerId: human,
        displayName: 'Beta',
      ),
    ],
    oldWorldUnits: [
      Unit(
        id: 'civ_builder',
        type: kUnitTypeBuilder,
        ownerId: human,
        locationProvinceId: p1,
        tileKey: 'oldWorld|p1|0|0',
      ),
      Unit(
        id: 'civ_explorer',
        type: kUnitTypeExplorer,
        ownerId: human,
        locationProvinceId: p1,
        tileKey: 'oldWorld|p1|0|1',
      ),
      Unit(
        id: 'civ_engineer',
        type: kUnitTypeEngineer,
        ownerId: human,
        locationProvinceId: p1,
        tileKey: 'oldWorld|p1|1|0',
      ),
      Unit(
        id: 'civ_merchant',
        type: kUnitTypeMerchant,
        ownerId: human,
        locationProvinceId: p1,
        tileKey: 'oldWorld|p1|1|1',
      ),
      Unit(
        id: 'civ_working',
        type: kUnitTypeBuilder,
        ownerId: human,
        locationProvinceId: p1,
        tileKey: 'oldWorld|p1|2|0',
        status: UnitStatus.working,
        currentWork: const CurrentWork(
          workTarget: kWorkTargetBuildImprovement,
          tileKey: 'oldWorld|p1|2|0',
          totalTurns: 5,
          remainingTurns: 2,
        ),
      ),
    ],
    newWorldProvinces: const [
      Province(
        id: np1,
        regionId: 'newWorld',
        ownerId: human,
        displayName: 'Gamma',
      ),
    ],
    newWorldUnits: [
      Unit(
        id: 'civ_explorer_nw',
        type: kUnitTypeExplorer,
        ownerId: human,
        locationProvinceId: np1,
        tileKey: 'newWorld|np1|0|0',
      ),
    ],
  );
}

/// Lightweight game shaped for the `victory_overlay_*` family.
///
/// `VictoryOverlay` / `VictoryPanel` only read `game.playerById(winnerId)` with
/// a `game.players.first` fallback, so the fixture just needs a deterministic
/// players list: the human ([kPanelTestHumanPlayerId]) first (used as the
/// `winnerPlayerId` and the unknown-winner fallback name) plus one AI opponent
/// so the winner-lookup path is non-vacuous. No map/topology data is required.
Game buildVictoryPanelTestGame() {
  return buildPanelTestGame(
    id: 'victory-panel-widget-test',
    players: [
      panelTestHumanPlayer(),
      Player(id: 'gp2', displayName: 'Rival Power', isHuman: false),
    ],
  );
}

/// Military regiment type id used by the lightweight military fixture. Matches
/// the regiment ids the `military_units_panel_test_part*` mini-games use, so
/// `isMilitaryUnit`/`regimentTypeDisplayName` resolve identically.
const String kPanelTestRegimentType = 'musketeers';

/// Lightweight game shaped for the `military_units_panel_test_part*` family.
///
/// Covers what those parts read from `game` / `humanPlayerIdWithUnits`:
/// - one human player ([kPanelTestHumanPlayerId]) owning military regiments in
///   **both** regions, each grouped under a non-home [Army] stationed in a
///   province that carries a `displayName` and a `townTileKey` (so region
///   headers, "N regiments · province" subtitles, Move/Split actions, and the
///   Locate tile-key all render exactly as with a generated map);
/// - the old-world army has two regiments so Split renders; the new-world army
///   keeps a single regiment to exercise the minimal block.
///
/// A non-owning player id (e.g. `'no-such-player'`) exercises the empty state.
/// No fleets are included: the part-family assertions only gate on land
/// military presence, so the lighter shape keeps coverage intact.
Game buildMilitaryPanelTestGame() {
  const human = kPanelTestHumanPlayerId;
  const oldProvince = 'oldWorld|p1';
  const newProvince = 'newWorld|np1';
  const type = kPanelTestRegimentType;
  return buildPanelTestGame(
    id: 'military-panel-widget-test',
    oldWorldProvinces: const [
      Province(
        id: oldProvince,
        regionId: 'oldWorld',
        ownerId: human,
        displayName: 'Alpha',
        townTileKey: 'oldWorld|p1|0|0',
      ),
    ],
    oldWorldUnits: [
      Unit(
        id: 'reg_old_1',
        type: type,
        ownerId: human,
        locationProvinceId: oldProvince,
        medals: 1,
      ),
      Unit(
        id: 'reg_old_2',
        type: type,
        ownerId: human,
        locationProvinceId: oldProvince,
        medals: 2,
      ),
    ],
    newWorldProvinces: const [
      Province(
        id: newProvince,
        regionId: 'newWorld',
        ownerId: human,
        displayName: 'Gamma',
        townTileKey: 'newWorld|np1|0|0',
      ),
    ],
    newWorldUnits: [
      Unit(
        id: 'reg_new_1',
        type: type,
        ownerId: human,
        locationProvinceId: newProvince,
        medals: 0,
      ),
    ],
    armies: const [
      Army(
        id: 'army_old',
        ownerId: human,
        regionId: 'oldWorld',
        stationedProvinceId: oldProvince,
        regimentUnitIds: ['reg_old_1', 'reg_old_2'],
        isHomeArmy: false,
      ),
      Army(
        id: 'army_new',
        ownerId: human,
        regionId: 'newWorld',
        stationedProvinceId: newProvince,
        regimentUnitIds: ['reg_new_1'],
        isHomeArmy: false,
      ),
    ],
  );
}

/// Lightweight game shaped for the `naval_units_panel_test_part*` family.
///
/// Covers what those parts read from `game` / `humanPlayerIdWithFleets`:
/// - one human player ([kPanelTestHumanPlayerId]) with a defined
///   `capitalProvinceId` + `capitalTile` in the **old world** (so the panel can
///   resolve and label the Home Fleet);
/// - a Home Fleet ([homeFleetIdFor]) in port at the capital carrying two ships,
///   so the Split action and split flow render for the home row;
/// - a **non-home** fleet (`fleet_nh1`) at sea in the old world with two ships,
///   so the `Fleet <id>` row renders with Move/Split actions and the empty
///   `humanPlayerIdWithFleets` fleet filters are non-vacuous;
/// - provinces in **both** regions carrying `townTileKey`, plus
///   `portsByProvinceSeaboard` / `tileKeysByRegionAndProvince` entries so
///   sea-zone and port locate tile keys resolve like a generated map.
///
/// A non-owning player id (e.g. `'no-such-player'`) exercises the empty state.
/// This is the shape the heavier `naval_units_panel_test_part1` map-derived
/// assertions need; lighter parts simply ignore the unused richness.
Game buildNavalPanelTestGame() {
  const human = kPanelTestHumanPlayerId;
  const ow = 'oldWorld';
  const nw = 'newWorld';
  const capProvince = 'oldWorld|cap';
  const oldPort = 'oldWorld|p2';
  const newPort = 'newWorld|np1';
  const seaZoneId = 'sz0';
  final homeFleetId = homeFleetIdFor(human);
  return buildPanelTestGame(
    id: 'naval-panel-widget-test',
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
    newWorldProvinces: const [
      Province(
        id: newPort,
        regionId: nw,
        ownerId: human,
        displayName: 'Newhaven',
        townTileKey: 'newWorld|np1|0|0',
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
    players: const [
      Player(
        id: human,
        displayName: 'Test Human',
        isHuman: true,
        capitalProvinceId: capProvince,
        capitalTile: CapitalTile(
          regionId: ow,
          provinceId: capProvince,
          x: 0,
          y: 0,
        ),
      ),
    ],
  );
}
