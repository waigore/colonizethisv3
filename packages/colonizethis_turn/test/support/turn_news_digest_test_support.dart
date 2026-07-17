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
    players: const [
      Player(id: 'gp1', displayName: 'A', isHuman: true, treasury: 0),
      Player(id: 'gp2', displayName: 'B', isHuman: false, treasury: 0),
    ],
    diplomacyRelations: [
      DiplomacyRelation(factionId1: 'gp1', factionId2: 'gp2', state: relState),
    ],
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
