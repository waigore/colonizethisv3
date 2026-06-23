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
    show kWorkTargetBuildImprovement;
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
