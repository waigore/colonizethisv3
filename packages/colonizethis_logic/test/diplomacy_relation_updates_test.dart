import 'package:colonizethis_test/test.dart';
import 'package:colonizethis_logic/src/diplomacy/diplomacy_relation_lookup.dart';
import 'package:colonizethis_logic/src/diplomacy/diplomacy_relation_updates.dart';
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
}
