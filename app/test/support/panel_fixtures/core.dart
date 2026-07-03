// Shared lightweight, hand-built [Game] fixtures for app panel widget tests.
//
// Split into focused modules under `panel_fixtures/`; import via
// `panel_test_fixtures.dart` barrel (Refs #3847).

import 'package:colonizethis_models/colonizethis_models.dart';

/// Default human great-power id used by the lightweight panel fixtures.
const String kPanelTestHumanPlayerId = 'gp1';

/// Military regiment type id used by the lightweight military fixture. Matches
/// the regiment ids the `military_units_panel_*` mini-games use, so
/// `isMilitaryUnit`/`regimentTypeDisplayName` resolve identically.
const String kPanelTestRegimentType = 'musketeers';

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
  List<Tribe> tribes = const [],
  List<MinorNation> minorNations = const [],
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
    tribes: tribes,
    minorNations: minorNations,
  );
}
