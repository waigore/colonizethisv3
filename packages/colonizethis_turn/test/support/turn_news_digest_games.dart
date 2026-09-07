import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/game_test_fixtures.dart';

/// Minimal games for turn news digest tests (`test/turn/turn_news_digest_test.dart`).
///
/// Refs waigore/colonizethis#2216.
const turnNewsTwoGpPlayers = [
  Player(id: 'gp1', displayName: 'A', isHuman: true, treasury: 0),
  Player(id: 'gp2', displayName: 'B', isHuman: false, treasury: 0),
];

const _gp1Solo = [
  Player(id: 'gp1', displayName: 'A', isHuman: true, treasury: 0),
];

Game turnNewsMinimalGame({required int turn}) {
  return TestFixtures.minimalGame(id: 'g', turnNumber: turn, players: _gp1Solo);
}

Game turnNewsTwoGpGame({required int turn, required RelationState relState}) {
  return TestFixtures.minimalGame(
    id: 'g',
    turnNumber: turn,
    players: turnNewsTwoGpPlayers,
    diplomacyRelations: [
      DiplomacyRelation(factionId1: 'gp1', factionId2: 'gp2', state: relState),
    ],
  );
}

Game turnNewsGameWithProvinceOwner({
  required int turn,
  required String fullProvinceId,
  required String regionId,
  required String? ownerId,
}) {
  return TestFixtures.minimalGame(
    id: 'g',
    turnNumber: turn,
    oldWorld: RegionData(
      provinces: [
        Province(id: fullProvinceId, regionId: regionId, ownerId: ownerId),
      ],
    ),
    players: turnNewsTwoGpPlayers,
  );
}

({Game start, Game end}) turnNewsProvinceOwnershipPair({
  required String regionId,
  required String localPid,
  required int startTurn,
  required String? startOwner,
  required String? endOwner,
}) {
  final fullPid = ProvinceId.full(regionId, localPid);
  return (
    start: turnNewsGameWithProvinceOwner(
      turn: startTurn,
      fullProvinceId: fullPid,
      regionId: regionId,
      ownerId: startOwner,
    ),
    end: turnNewsGameWithProvinceOwner(
      turn: startTurn + 1,
      fullProvinceId: fullPid,
      regionId: regionId,
      ownerId: endOwner,
    ),
  );
}

Game turnNewsOvertureGame({required int turn, required OvertureStage stage}) {
  return TestFixtures.minimalGame(
    id: 'g',
    turnNumber: turn,
    players: _gp1Solo,
    overtureStates: [OvertureState(gpId: 'gp1', targetId: 'm1', stage: stage)],
  );
}

({Game start, Game end}) turnNewsOvertureAdvancePair() {
  return (
    start: turnNewsOvertureGame(turn: 0, stage: OvertureStage.none),
    end: turnNewsOvertureGame(turn: 1, stage: OvertureStage.tradeConsulate),
  );
}

({Game start, Game end}) turnNewsSeaZoneFleetPair() {
  const regionId = kRegionOldWorld;
  const localSea = 'seaA';
  final fleet = Fleet(
    id: 'fl1',
    ownerId: 'gp1',
    regionId: regionId,
    seaZoneId: localSea,
    ships: const [ShipInstance(id: 'ship_1', typeId: 'carrack')],
  );
  final start = TestFixtures.minimalGame(
    id: 'g',
    turnNumber: 0,
    players: _gp1Solo,
  );
  return (
    start: start,
    end: start.copyWith(
      worldState: start.worldState.copyWith(
        turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 1),
        fleets: [fleet],
      ),
    ),
  );
}

Game turnNewsGameWithProvinceVis({
  required int turn,
  required String fullProvinceId,
  required String regionId,
  required String localProvinceId,
  required String visibility,
  List<String> revealDone = const [],
}) {
  final tileKey = '$regionId|$localProvinceId|0|0';
  return Game(
    id: 'g',
    worldState: WorldState(
      turnState: TurnState(phase: TurnPhase.orders, turnNumber: turn),
      oldWorld: RegionData(
        provinces: [
          Province(id: fullProvinceId, regionId: regionId, ownerId: 'gp1'),
        ],
      ),
      newWorld: const RegionData(),
      tileKeysByRegionAndProvince: {
        regionId: {
          fullProvinceId: [tileKey],
        },
      },
      playerVisibilityByTile: {
        'gp1': {tileKey: visibility},
      },
      newsDigestProvinceRevealDoneIds: revealDone,
    ),
    players: _gp1Solo,
  );
}
