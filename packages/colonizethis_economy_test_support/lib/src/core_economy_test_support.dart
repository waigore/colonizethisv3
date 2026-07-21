// dart format off
// Shared builders for core economy unit tests (Refs #3836, #4108).
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/game_test_fixtures.dart';

export 'fixture_builders/game_builders.dart';

/// Minimal player fixture for build-cost and worker-economy suites.
Player corePlayer({String id = 'p1', String displayName = 'P', bool isHuman = true, int treasury = 0, Stockpile stockpile = const Stockpile(), Map<String, bool> techUnlocked = const {}}) {
  return Player(id: id, displayName: displayName, isHuman: isHuman, treasury: treasury, stockpile: stockpile, techUnlocked: techUnlocked);
}
/// Worker pool with tier defaults at zero except [peasants].
WorkerPool coreWorkerPool({int peasants = 0, int apprentices = 0, int journeymen = 0, int masters = 0}) {
  return WorkerPool(peasants: peasants, apprentices: apprentices, journeymen: journeymen, masters: masters);
}
/// Stockpile seeded from commodity-id → quantity deltas.
Stockpile stockpileWithDeltas(Map<CommodityId, int> deltas) {
  var stockpile = const Stockpile();
  for (final MapEntry(:key, :value) in deltas.entries) {
    stockpile = stockpile.applyDelta(key, value);
  }
  return stockpile;
}
var _tradeInterceptionFleetSeq = 0;
/// Deterministic fleet factory for trade-interception scan tests.
Fleet tradeInterceptionScanFleet({required String ownerId, required List<String> shipTypeIds, FleetMission mission = FleetMission.patrol, bool atSea = true}) {
  final seq = _tradeInterceptionFleetSeq++;
  return Fleet(id: 'fleet-$ownerId-$seq', ownerId: ownerId, seaZoneId: atSea ? 'sea1' : null, inPortAtProvinceId: atSea ? null : 'oldWorld|p1', regionId: 'oldWorld', shipTypeIds: shipTypeIds, mission: mission);
}
/// Resets the scan-fleet sequence counter between test groups.
void resetTradeInterceptionScanFleetSeq() {
  _tradeInterceptionFleetSeq = 0;
}
/// Thin wrapper over [TestFixtures.minimalGame] for sea-transport suites.
Game minimalEconomyGame({String id = 'g1', int turnNumber = 0, List<Player>? players, List<Fleet>? fleets}) => TestFixtures.minimalGame(
  id: id,
  turnNumber: turnNumber,
  players: players ?? const [Player(id: 'h1', displayName: 'Human', isHuman: true)],
  fleets: fleets ?? const [],
);
// dart format on
