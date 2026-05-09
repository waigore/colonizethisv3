import 'package:colonizethis_test/test.dart';
import 'package:colonizethis_logic/src/diplomacy/diplomacy_relation_lookup.dart';
import 'package:colonizethis_logic/src/diplomacy/diplomacy_relation_updates.dart';
import 'package:colonizethis_logic/src/world/province_lookup.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

DiplomacyRelation? _linearScanGetRelation(
  Game game,
  String factionId1,
  String factionId2,
) {
  final key = pairKey(factionId1, factionId2);
  for (final r in game.diplomacyRelations) {
    if (pairKey(r.factionId1, r.factionId2) == key) return r;
  }
  return null;
}

OvertureState? _linearScanGetOverture(Game game, String gpId, String targetId) {
  for (final o in game.overtureStates) {
    if (o.gpId == gpId && o.targetId == targetId) return o;
  }
  return null;
}

int _linearScanProvinceCountOwnedBy(Game game, String factionId) {
  var count = 0;
  for (final p in allProvinces(game.worldState)) {
    if (p.ownerId == factionId) count++;
  }
  return count;
}

void main() {
  group('applyGrantAidModifier', () {
    test('updates existing relation when pair already present', () {
      final relations = [
        DiplomacyRelation(
          factionId1: 'gp1',
          factionId2: 'gp2',
          score: 50,
          level: RelationLevel.neutral,
        ),
      ];
      final result = applyGrantAidModifier(
        relations: relations,
        gpId: 'gp1',
        targetId: 'gp2',
        turn: 2,
      );
      expect(result.length, 1);
      expect(result[0].score, 55);
      expect(result[0].lastInteractionTurn, 2);
    });
  });

  group('applySubsidyBoost', () {
    test('updates existing relation when pair already present', () {
      final relations = [
        DiplomacyRelation(
          factionId1: 'gp1',
          factionId2: 'gp2',
          score: 60,
          level: RelationLevel.friendly,
        ),
      ];
      final result = applySubsidyBoost(
        relations: relations,
        payerId: 'gp1',
        targetId: 'gp2',
        boost: 10,
        turn: 3,
      );
      expect(result.length, 1);
      expect(result[0].score, 70);
      expect(result[0].lastInteractionTurn, 3);
    });
  });

  group('AC-4 diplomacy relation / overture map lookup (Refs #2268)', () {
    test('getRelation matches linear scan for every pair in a mixed list', () {
      final relations = <DiplomacyRelation>[
        const DiplomacyRelation(
          factionId1: 'zebra',
          factionId2: 'alpha',
          score: 1,
        ),
        const DiplomacyRelation(
          factionId1: 'gp_b',
          factionId2: 'gp_a',
          score: 2,
        ),
        const DiplomacyRelation(factionId1: 'm1', factionId2: 'm2', score: 3),
      ];
      final game = Game(
        id: 't',
        worldState: WorldState(
          turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 1),
          oldWorld: const RegionData(),
          newWorld: const RegionData(),
        ),
        players: const [],
        diplomacyRelations: relations,
      );
      final ids = <String>{
        'zebra',
        'alpha',
        'gp_a',
        'gp_b',
        'm1',
        'm2',
        'solo',
      };
      for (final a in ids) {
        for (final b in ids) {
          if (a == b) continue;
          expect(
            getRelation(game, a, b),
            _linearScanGetRelation(game, a, b),
            reason: 'pair ($a,$b)',
          );
        }
      }
    });

    test('getOverture matches linear scan for representative keys', () {
      final overtures = <OvertureState>[
        const OvertureState(
          gpId: 'gp1',
          targetId: 't1',
          stage: OvertureStage.tradeConsulate,
        ),
        const OvertureState(
          gpId: 'gp2',
          targetId: 't1',
          stage: OvertureStage.embassy,
        ),
      ];
      final game = Game(
        id: 't',
        worldState: WorldState(
          turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 1),
          oldWorld: const RegionData(),
          newWorld: const RegionData(),
        ),
        players: const [],
        overtureStates: overtures,
      );
      expect(
        getOverture(game, 'gp1', 't1'),
        _linearScanGetOverture(game, 'gp1', 't1'),
      );
      expect(
        getOverture(game, 'gp2', 't1'),
        _linearScanGetOverture(game, 'gp2', 't1'),
      );
      expect(getOverture(game, 'gp1', 'missing'), isNull);
    });

    test(
      'after upsertRelation, new Game sees updated relation via getRelation',
      () {
        final g0 = Game(
          id: 't',
          worldState: WorldState(
            turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 1),
            oldWorld: const RegionData(),
            newWorld: const RegionData(),
          ),
          players: const [],
          diplomacyRelations: const [
            DiplomacyRelation(factionId1: 'a', factionId2: 'b', score: 40),
          ],
        );
        expect(getRelation(g0, 'a', 'b')?.score, 40);

        final nextRelations = upsertRelation(
          g0.diplomacyRelations,
          'a',
          'b',
          (e) => e!.copyWith(score: 88),
        );
        final g1 = g0.copyWith(diplomacyRelations: nextRelations);
        expect(getRelation(g1, 'b', 'a')?.score, 88);
      },
    );
  });

  group('AC-5 provinceCountOwnedBy histogram (Refs #2268)', () {
    test('cached counts match full scan for every owner in a two-region setup', () {
      final game = Game(
        id: 'g',
        worldState: WorldState(
          turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 1),
          oldWorld: RegionData(
            provinces: [
              Province(id: 'oldWorld|a', regionId: 'oldWorld', ownerId: 'gp1'),
              Province(id: 'oldWorld|b', regionId: 'oldWorld', ownerId: 'tribe_x'),
              Province(id: 'oldWorld|c', regionId: 'oldWorld', ownerId: null),
            ],
          ),
          newWorld: RegionData(
            provinces: [
              Province(id: 'newWorld|n1', regionId: 'newWorld', ownerId: 'gp1'),
              Province(id: 'newWorld|n2', regionId: 'newWorld', ownerId: 'minor_y'),
              Province(id: 'newWorld|n3', regionId: 'newWorld', ownerId: 'minor_y'),
            ],
          ),
        ),
        players: const [],
      );
      const owners = {'gp1', 'tribe_x', 'minor_y', 'nobody', ''};
      for (final id in owners) {
        expect(
          provinceCountOwnedBy(game, id),
          _linearScanProvinceCountOwnedBy(game, id),
          reason: 'faction $id',
        );
      }
      // Repeated reads use the same snapshot (histogram built once per Game).
      expect(provinceCountOwnedBy(game, 'gp1'), 2);
      expect(provinceCountOwnedBy(game, 'minor_y'), 2);
    });

    test('copyWith new Game instance gets counts from its own worldState', () {
      final g0 = Game(
        id: 'g',
        worldState: WorldState(
          turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 1),
          oldWorld: RegionData(
            provinces: [
              Province(id: 'oldWorld|p1', regionId: 'oldWorld', ownerId: 'm1'),
            ],
          ),
          newWorld: const RegionData(),
        ),
        players: const [],
      );
      expect(provinceCountOwnedBy(g0, 'm1'), 1);

      final g1 = g0.copyWith(
        worldState: g0.worldState.copyWith(
          oldWorld: RegionData(
            provinces: [
              Province(id: 'oldWorld|p1', regionId: 'oldWorld', ownerId: 'm1'),
              Province(id: 'oldWorld|p2', regionId: 'oldWorld', ownerId: 'm2'),
            ],
          ),
        ),
      );
      expect(provinceCountOwnedBy(g1, 'm1'), 1);
      expect(provinceCountOwnedBy(g1, 'm2'), 1);
      expect(provinceCountOwnedBy(g1, 'ghost'), 0);
    });
  });
}
