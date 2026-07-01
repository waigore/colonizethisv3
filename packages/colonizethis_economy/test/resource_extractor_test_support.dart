// Shared fixture helper for `resource_extractor_part*_test.dart`.
//
// Hoists the single-owned-province `computeExtraction` setup that was copied
// verbatim across the four split resource-extractor suites so each scenario
// only declares the inputs it actually varies (tile state, town dev, tech,
// prospected tiles). Refs #3661 (economy test dedup, step 5).

import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/game_test_fixtures.dart';
import 'package:colonizethis_world/src/world/connectivity_resolver.dart';

export 'package:colonizethis_economy_test_support/colonizethis_economy_test_support.dart'
    show singleTileMap;

/// `{playerId: ConnectivityResult(...)}` for the single-player extraction
/// setup. Hoists the `{'pl1': ConnectivityResult(connected: {…})}` wrapper
/// repeated across the resource-extractor suites; [pathTransportCap] and
/// [connectedByRoadRule] keep their `ConnectivityResult` defaults. Refs #3661.
Map<String, ConnectivityResult> connectivityFor(
  Set<String> connected, {
  Map<String, int> pathTransportCap = const {},
  Set<String> connectedByRoadRule = const {},
  String playerId = 'pl1',
}) => {
  playerId: ConnectivityResult(
    connected: connected,
    pathTransportCap: pathTransportCap,
    connectedByRoadRule: connectedByRoadRule,
  ),
};

/// Single-owned-province extraction setup: player `pl1` ("Spain") owns
/// `oldWorld|p1` (capital tile at 0,0) at [townDevelopmentLevel]. Pairs with a
/// single-region `tileMapByRegion` for `computeExtraction` resource tests; pass
/// [techUnlocked] for tech-cap cases and [playerProspectedTiles] for minerals.
Game resourceExtractorGame({
  required TileMapState tileState,
  int townDevelopmentLevel = 4,
  Map<String, bool>? techUnlocked,
  Map<String, Set<String>>? playerProspectedTiles,
  String playerId = 'pl1',
}) {
  final player = Player(
    id: playerId,
    displayName: 'Spain',
    isHuman: true,
    capitalProvinceId: 'oldWorld|p1',
    capitalTile: const CapitalTile(
      regionId: 'oldWorld',
      provinceId: 'oldWorld|p1',
      x: 0,
      y: 0,
    ),
    techUnlocked: techUnlocked,
  );
  return TestFixtures.minimalGame(
    id: 'g1',
    capitalTileGrainBonusPerTurn: 0,
    oldWorld: RegionData(
      provinces: [
        Province(
          id: 'oldWorld|p1',
          regionId: 'oldWorld',
          ownerId: playerId,
          townDevelopmentLevel: townDevelopmentLevel,
        ),
      ],
    ),
    tileState: tileState,
    playerProspectedTiles: playerProspectedTiles,
    players: [player],
  );
}
