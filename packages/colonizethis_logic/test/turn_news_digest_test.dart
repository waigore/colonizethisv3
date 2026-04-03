import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:test/test.dart';

void main() {
  group('buildTurnNewsDigestForComplete', () {
    test('Given victory on end state When build Then digest is null', () {
      final start = _minimalGame(turn: 5);
      final end = start.copyWith(
        victory: const VictoryState(
          winnerPlayerId: 'gp1',
          type: VictoryType.military,
          turnNumber: 5,
        ),
      );
      final r = buildTurnNewsDigestForComplete(start: start, end: end);
      expect(r.digest, isNull);
      expect(r.game, same(end));
    });

    test('Given relation atPeace to atWar When build Then war line', () {
      final start = _twoGpGame(
        turn: 0,
        relState: RelationState.atPeace,
      );
      final end = _twoGpGame(
        turn: 1,
        relState: RelationState.atWar,
      );
      final r = buildTurnNewsDigestForComplete(start: start, end: end);
      expect(r.digest, isNotNull);
      final warLines = r.digest!.lines.whereType<TurnNewsDiplomacyLine>();
      expect(warLines, hasLength(1));
      expect(warLines.single.kind, TurnNewsDiplomacyKind.war);
      expect(
        {warLines.single.factionIdA, warLines.single.factionIdB},
        equals({'gp1', 'gp2'}),
      );
    });

    test('Given first province reveal When build Then discovery line and id tracked',
        () {
      const regionId = 'oldWorld';
      const localPid = 'P1';
      final fullPid = ProvinceId.full(regionId, localPid);
      final start = _gameWithProvinceVis(
        turn: 0,
        fullProvinceId: fullPid,
        regionId: regionId,
        localProvinceId: localPid,
        visibility: 'unknown',
      );
      final end = _gameWithProvinceVis(
        turn: 1,
        fullProvinceId: fullPid,
        regionId: regionId,
        localProvinceId: localPid,
        visibility: 'revealed',
      );
      final r = buildTurnNewsDigestForComplete(start: start, end: end);
      expect(
        r.game.worldState.newsDigestProvinceRevealDoneIds,
        contains(fullPid),
      );
      final disc = r.digest!.lines.whereType<TurnNewsProvinceDiscoveredLine>();
      expect(disc, hasLength(1));
      expect(disc.single.provinceId, fullPid);
    });

    test('Given province already in reveal done When reveal again Then no second discovery',
        () {
      const regionId = 'oldWorld';
      const localPid = 'P1';
      final fullPid = ProvinceId.full(regionId, localPid);
      final start = _gameWithProvinceVis(
        turn: 1,
        fullProvinceId: fullPid,
        regionId: regionId,
        localProvinceId: localPid,
        visibility: 'unknown',
        revealDone: [fullPid],
      );
      final end = _gameWithProvinceVis(
        turn: 2,
        fullProvinceId: fullPid,
        regionId: regionId,
        localProvinceId: localPid,
        visibility: 'revealed',
        revealDone: [fullPid],
      );
      final r = buildTurnNewsDigestForComplete(start: start, end: end);
      final disc = r.digest!.lines.whereType<TurnNewsProvinceDiscoveredLine>();
      expect(disc, isEmpty);
    });
  });
}

Game _minimalGame({required int turn}) {
  return Game(
    id: 'g',
    worldState: WorldState(
      turnState: TurnState(phase: TurnPhase.orders, turnNumber: turn),
      oldWorld: const RegionData(),
      newWorld: const RegionData(),
    ),
    players: const [
      Player(
        id: 'gp1',
        displayName: 'A',
        isHuman: true,
        treasury: 0,
      ),
    ],
  );
}

Game _twoGpGame({required int turn, required RelationState relState}) {
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
      DiplomacyRelation(
        factionId1: 'gp1',
        factionId2: 'gp2',
        state: relState,
      ),
    ],
  );
}

Game _gameWithProvinceVis({
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
        regionId: {localProvinceId: [tileKey]},
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
