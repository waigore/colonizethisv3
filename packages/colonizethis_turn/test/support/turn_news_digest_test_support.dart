import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';

/// Asserts two digests carry the same resolved turn and identical ordered lines.
void expectDigestLinesEqual(TurnNewsDigest a, TurnNewsDigest b) {
  expect(a.resolvedTurnNumber, b.resolvedTurnNumber);
  expect(a.lines.length, b.lines.length);
  for (var i = 0; i < a.lines.length; i++) {
    expectLineEqual(a.lines[i], b.lines[i]);
  }
}

/// Asserts two news lines are the same kind with equal payload fields.
void expectLineEqual(TurnNewsLine x, TurnNewsLine y) {
  expect(x.runtimeType, y.runtimeType);
  switch ((x, y)) {
    case (
      TurnNewsProvinceCapturedLine(
        provinceId: final ap,
        previousOwnerId: final a1,
        newOwnerId: final a2,
      ),
      TurnNewsProvinceCapturedLine(
        provinceId: final bp,
        previousOwnerId: final b1,
        newOwnerId: final b2,
      ),
    ):
      expect(ap, bp);
      expect(a1, b1);
      expect(a2, b2);
    case (
      TurnNewsDiplomacyLine(
        factionIdA: final aa,
        factionIdB: final ab,
        kind: final ak,
      ),
      TurnNewsDiplomacyLine(
        factionIdA: final ba,
        factionIdB: final bb,
        kind: final bk,
      ),
    ):
      expect(aa, ba);
      expect(ab, bb);
      expect(ak, bk);
    case (
      TurnNewsOvertureAdvancedLine(
        offererGpId: final ao,
        targetFactionId: final at,
        newStage: final as_,
      ),
      TurnNewsOvertureAdvancedLine(
        offererGpId: final bo,
        targetFactionId: final bt,
        newStage: final bs,
      ),
    ):
      expect(ao, bo);
      expect(at, bt);
      expect(as_, bs);
    case (
      TurnNewsProvinceDiscoveredLine(provinceId: final ap),
      TurnNewsProvinceDiscoveredLine(provinceId: final bp),
    ):
      expect(ap, bp);
    case (
      TurnNewsSeaZoneFleetLine(seaZoneId: final az),
      TurnNewsSeaZoneFleetLine(seaZoneId: final bz),
    ):
      expect(az, bz);
    default:
      fail('Unexpected line pair: $x vs $y');
  }
}

/// Minimal games for turn news digest tests (`test/turn/turn_news_digest_test.dart`).
///
/// Refs waigore/colonizethis#2216.
Game turnNewsMinimalGame({required int turn}) {
  return Game(
    id: 'g',
    worldState: WorldState(
      turnState: TurnState(phase: TurnPhase.orders, turnNumber: turn),
      oldWorld: const RegionData(),
      newWorld: const RegionData(),
    ),
    players: const [
      Player(id: 'gp1', displayName: 'A', isHuman: true, treasury: 0),
    ],
  );
}

Game turnNewsTwoGpGame({required int turn, required RelationState relState}) {
  return Game(
    id: 'g',
    worldState: WorldState(
      turnState: TurnState(phase: TurnPhase.orders, turnNumber: turn),
      oldWorld: const RegionData(),
      newWorld: const RegionData(),
    ),
    players: turnNewsTwoGpPlayers,
    diplomacyRelations: [
      DiplomacyRelation(factionId1: 'gp1', factionId2: 'gp2', state: relState),
    ],
  );
}

const turnNewsTwoGpPlayers = [
  Player(id: 'gp1', displayName: 'A', isHuman: true, treasury: 0),
  Player(id: 'gp2', displayName: 'B', isHuman: false, treasury: 0),
];

Game turnNewsGameWithProvinceOwner({
  required int turn,
  required String fullProvinceId,
  required String regionId,
  required String? ownerId,
}) {
  return Game(
    id: 'g',
    worldState: WorldState(
      turnState: TurnState(phase: TurnPhase.orders, turnNumber: turn),
      oldWorld: RegionData(
        provinces: [
          Province(id: fullProvinceId, regionId: regionId, ownerId: ownerId),
        ],
      ),
      newWorld: const RegionData(),
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

Game turnNewsOvertureGame({
  required int turn,
  required OvertureStage stage,
}) {
  return Game(
    id: 'g',
    worldState: WorldState(
      turnState: TurnState(phase: TurnPhase.orders, turnNumber: turn),
      oldWorld: const RegionData(),
      newWorld: const RegionData(),
    ),
    players: const [
      Player(id: 'gp1', displayName: 'A', isHuman: true, treasury: 0),
    ],
    overtureStates: [
      OvertureState(gpId: 'gp1', targetId: 'm1', stage: stage),
    ],
  );
}

({Game start, Game end}) turnNewsOvertureAdvancePair() {
  return (
    start: turnNewsOvertureGame(
      turn: 0,
      stage: OvertureStage.none,
    ),
    end: turnNewsOvertureGame(
      turn: 1,
      stage: OvertureStage.tradeConsulate,
    ),
  );
}

({Game start, Game end}) turnNewsSeaZoneFleetPair() {
  const regionId = 'oldWorld';
  const localSea = 'seaA';
  final fleet = Fleet(
    id: 'fl1',
    ownerId: 'gp1',
    regionId: regionId,
    seaZoneId: localSea,
    ships: const [ShipInstance(id: 'ship_1', typeId: 'carrack')],
  );
  return (
    start: Game(
      id: 'g',
      worldState: const WorldState(
        turnState: TurnState(phase: TurnPhase.orders, turnNumber: 0),
        oldWorld: RegionData(),
        newWorld: RegionData(),
      ),
      players: const [
        Player(id: 'gp1', displayName: 'A', isHuman: true, treasury: 0),
      ],
    ),
    end: Game(
      id: 'g',
      worldState: WorldState(
        turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 1),
        oldWorld: const RegionData(),
        newWorld: const RegionData(),
        fleets: [fleet],
      ),
      players: const [
        Player(id: 'gp1', displayName: 'A', isHuman: true, treasury: 0),
      ],
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
    players: const [
      Player(id: 'gp1', displayName: 'A', isHuman: true, treasury: 0),
    ],
  );
}
