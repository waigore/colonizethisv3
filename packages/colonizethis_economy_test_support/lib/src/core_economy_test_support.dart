// Shared builders for core economy unit tests (Refs #3836).

import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

/// Minimal player fixture for build-cost and worker-economy suites.
Player corePlayer({
  String id = 'p1',
  String displayName = 'P',
  bool isHuman = true,
  int treasury = 0,
  Stockpile stockpile = const Stockpile(),
  Map<String, bool> techUnlocked = const {},
}) {
  return Player(
    id: id,
    displayName: displayName,
    isHuman: isHuman,
    treasury: treasury,
    stockpile: stockpile,
    techUnlocked: techUnlocked,
  );
}

/// Worker pool with tier defaults at zero except [peasants].
WorkerPool coreWorkerPool({
  int peasants = 0,
  int apprentices = 0,
  int journeymen = 0,
  int masters = 0,
}) {
  return WorkerPool(
    peasants: peasants,
    apprentices: apprentices,
    journeymen: journeymen,
    masters: masters,
  );
}

/// Stockpile seeded from commodity-id → quantity deltas.
Stockpile stockpileWithDeltas(Map<CommodityId, int> deltas) {
  var stockpile = const Stockpile();
  for (final MapEntry(:key, :value) in deltas.entries) {
    stockpile = stockpile.applyDelta(key, value);
  }
  return stockpile;
}

/// Two-player game skeleton for trade-interception tests.
Game tradeInterceptionGame({
  String id = 'g1',
  List<Fleet> fleets = const [],
  List<DiplomacyRelation> diplomacyRelations = const [],
  List<Player>? players,
  RelationState defaultRelation = RelationState.atPeace,
}) {
  final resolvedPlayers = players ??
      const [
        Player(id: 'p1', displayName: 'A', isHuman: true),
        Player(id: 'p2', displayName: 'B', isHuman: true),
      ];
  final resolvedRelations = diplomacyRelations.isNotEmpty
      ? diplomacyRelations
      : [
          DiplomacyRelation(
            factionId1: 'p1',
            factionId2: 'p2',
            state: defaultRelation,
          ),
        ];
  return Game(
    id: id,
    worldState: WorldState(
      turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 1),
      oldWorld: const RegionData(),
      newWorld: const RegionData(),
      fleets: fleets,
    ),
    players: resolvedPlayers,
    diplomacyRelations: resolvedRelations,
  );
}

/// Enemy patrol fleet with optional privateering tech on player p2.
Game tradeInterceptionPrivateeringGame({
  required bool enemyHasPrivateering,
  String gameId = 'g1',
}) {
  return Game(
    id: gameId,
    worldState: WorldState(
      turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 1),
      oldWorld: const RegionData(),
      newWorld: const RegionData(),
      fleets: [
        Fleet(
          id: 'enemy',
          ownerId: 'p2',
          seaZoneId: 'sea1',
          regionId: 'oldWorld',
          shipTypeIds: const ['sloop'],
          mission: FleetMission.patrol,
        ),
        Fleet(
          id: 'mine',
          ownerId: 'p1',
          seaZoneId: 'sea1',
          regionId: 'oldWorld',
          shipTypeIds: const ['fluyte'],
        ),
      ],
    ),
    players: [
      const Player(id: 'p1', displayName: 'A', isHuman: true),
      Player(
        id: 'p2',
        displayName: 'B',
        isHuman: false,
        techUnlocked: enemyHasPrivateering
            ? const {kTechIdPrivateeringCompanies: true}
            : const {},
      ),
    ],
    diplomacyRelations: const [
      DiplomacyRelation(
        factionId1: 'p1',
        factionId2: 'p2',
        state: RelationState.atWar,
      ),
    ],
  );
}

var _tradeInterceptionFleetSeq = 0;

/// Deterministic fleet factory for trade-interception scan tests.
Fleet tradeInterceptionScanFleet({
  required String ownerId,
  required List<String> shipTypeIds,
  FleetMission mission = FleetMission.patrol,
  bool atSea = true,
}) {
  final seq = _tradeInterceptionFleetSeq++;
  return Fleet(
    id: 'fleet-$ownerId-$seq',
    ownerId: ownerId,
    seaZoneId: atSea ? 'sea1' : null,
    inPortAtProvinceId: atSea ? null : 'oldWorld|p1',
    regionId: 'oldWorld',
    shipTypeIds: shipTypeIds,
    mission: mission,
  );
}

/// Resets the scan-fleet sequence counter between test groups.
void resetTradeInterceptionScanFleetSeq() {
  _tradeInterceptionFleetSeq = 0;
}
