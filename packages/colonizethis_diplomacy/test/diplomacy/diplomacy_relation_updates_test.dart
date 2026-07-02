import 'package:colonizethis_test/test.dart';
import 'package:colonizethis_diplomacy/colonizethis_diplomacy.dart';
import 'package:colonizethis_diplomacy/src/diplomacy/diplomacy_relation_lookup.dart';
import 'package:colonizethis_diplomacy/src/diplomacy/diplomacy_relation_updates.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

import '../support/diplomacy_relation_fixtures.dart';

void main() {
  group('applyGrantAidModifier', () {
    test('updates existing relation when pair already present', () {
      final relations = [
        peaceRelation('gp1', 'gp2', 50, level: RelationLevel.neutral),
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
        peaceRelation('gp1', 'gp2', 60, level: RelationLevel.friendly),
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

  group('canonicalPairIds', () {
    test('orders ids canonically regardless of argument order', () {
      final a = canonicalPairIds('gp2', 'gp1');
      final b = canonicalPairIds('gp1', 'gp2');
      expect(a, b);
    });
  });

  group('applyGrantAidModifier with no existing relation', () {
    test('creates a new relation seeded from neutral + 5', () {
      final relations = applyGrantAidModifier(
        relations: const [],
        gpId: 'gp1',
        targetId: 'minor1',
        turn: 4,
      );
      expect(relations, hasLength(1));
      final rel = relations.single;
      expect(rel.score, relationScoreNeutral + 5);
      expect(rel.level, scoreToLevel(relationScoreNeutral + 5));
      expect(rel.lastInteractionTurn, 4);
    });
  });

  group('applySubsidyBoost with no existing relation', () {
    test('creates a new relation seeded from neutral + boost', () {
      final relations = applySubsidyBoost(
        relations: const [],
        payerId: 'gp1',
        targetId: 'tribe1',
        boost: 6,
        turn: 8,
      );
      expect(relations, hasLength(1));
      final rel = relations.single;
      expect(rel.score, relationScoreNeutral + 6);
      expect(rel.level, scoreToLevel(relationScoreNeutral + 6));
      expect(rel.lastInteractionTurn, 8);
    });
  });

  group('setWarStateForPair with no existing relation', () {
    test('creates a hostile at-war relation', () {
      final relations = setWarStateForPair(
        relations: const [],
        gpId: 'gp1',
        targetId: 'gp2',
        turn: 2,
      );
      expect(relations, hasLength(1));
      final rel = relations.single;
      expect(rel.state, RelationState.atWar);
      expect(rel.level, RelationLevel.hostile);
      expect(rel.sinceTurn, 2);
      expect(rel.formalAlliance, isFalse);
    });
  });

  group('setWarStateForPair clears a formal alliance (war invariant)', () {
    test('transitioning an allied pair to war drops formalAlliance', () {
      const allied = DiplomacyRelation(
        factionId1: 'gp1',
        factionId2: 'gp2',
        score: 80,
        level: RelationLevel.allied,
        formalAlliance: true,
      );
      final relations = setWarStateForPair(
        relations: const [allied],
        gpId: 'gp1',
        targetId: 'gp2',
        turn: 5,
      );
      final rel = relations.single;
      expect(rel.state, RelationState.atWar);
      expect(rel.formalAlliance, isFalse);
    });
  });

  group('warStateRelationUpdater via RelationUpsertIndex', () {
    test('positive: matches setWarStateForPair for a new pair', () {
      final viaList = setWarStateForPair(
        relations: const [],
        gpId: 'gp1',
        targetId: 'gp2',
        turn: 3,
      );
      final index = RelationUpsertIndex(const []);
      index.upsert(
        'gp1',
        'gp2',
        warStateRelationUpdater('gp1', 'gp2', 3),
      );
      final viaIndex = index.toList();
      expect(viaIndex, hasLength(1));
      final rel = viaIndex.single;
      expect(rel.state, viaList.single.state);
      expect(rel.level, viaList.single.level);
      expect(rel.score, viaList.single.score);
      expect(rel.sinceTurn, viaList.single.sinceTurn);
      expect(rel.formalAlliance, viaList.single.formalAlliance);
    });

    test('negative: peace updater requires an existing relation', () {
      expect(
        () => peaceRelationUpdater('gp1', 'gp2', 1)(null),
        throwsA(isA<TypeError>()),
      );
    });
  });

  group('RelationUpsertIndex', () {
    test('positive: updates an existing pair in place (canonical order)', () {
      final index = RelationUpsertIndex([rel('gp1', 'gp2', 40)]);
      index.upsert('gp2', 'gp1', (e) => e!.copyWith(score: 88));
      final result = index.toList();
      expect(result.length, 1);
      expect(result.single.score, 88);
    });

    test('positive: appends a new pair and reuses its index on later upserts', () {
      final index = RelationUpsertIndex([rel('gp1', 'gp2', 40)]);
      index.upsert('gp3', 'gp4', (e) {
        expect(e, isNull);
        return rel('gp3', 'gp4', 10);
      });
      index.upsert('gp3', 'gp4', (e) {
        expect(e, isNotNull);
        return e!.copyWith(score: 20);
      });
      final result = index.toList();
      expect(result.length, 2);
      expect(getRelationFromList(result, 'gp3', 'gp4')?.score, 20);
    });

    test('positive: matches sequential upsertRelation results', () {
      final start = [rel('a', 'b', 30), rel('c', 'd', 60)];

      var sequential = upsertRelation(
        start,
        'a',
        'b',
        (e) => e!.copyWith(score: e.score + 5),
      );
      sequential = upsertRelation(
        sequential,
        'e',
        'f',
        (e) => rel('e', 'f', 70),
      );
      sequential = upsertRelation(
        sequential,
        'c',
        'd',
        (e) => e!.copyWith(score: e.score - 10),
      );

      final index = RelationUpsertIndex(start)
        ..upsert('a', 'b', (e) => e!.copyWith(score: e.score + 5))
        ..upsert('e', 'f', (e) => rel('e', 'f', 70))
        ..upsert('c', 'd', (e) => e!.copyWith(score: e.score - 10));
      final batched = index.toList();

      expect(batched.length, sequential.length);
      for (var i = 0; i < sequential.length; i++) {
        expect(batched[i].factionId1, sequential[i].factionId1);
        expect(batched[i].factionId2, sequential[i].factionId2);
        expect(batched[i].score, sequential[i].score);
      }
    });

    test('negative: empty start list appends new relations only', () {
      final index = RelationUpsertIndex(const [])
        ..upsert('x', 'y', (e) {
          expect(e, isNull);
          return rel('x', 'y', 50);
        });
      expect(index.length, 1);
      expect(index.toList().single.score, 50);
    });

    test('negative: toList returns a defensive copy (no shared mutation)', () {
      final index = RelationUpsertIndex([rel('a', 'b', 50)]);
      final snapshot = index.toList();
      index.upsert('a', 'b', (e) => e!.copyWith(score: 99));
      expect(snapshot.single.score, 50);
      expect(index.toList().single.score, 99);
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
      final game = relationsOnlyGame(relations: relations);
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
            linearScanGetRelation(game, a, b),
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
      final game = relationsOnlyGame(overtureStates: overtures);
      expect(
        getOverture(game, 'gp1', 't1'),
        linearScanGetOverture(game, 'gp1', 't1'),
      );
      expect(
        getOverture(game, 'gp2', 't1'),
        linearScanGetOverture(game, 'gp2', 't1'),
      );
      expect(getOverture(game, 'gp1', 'missing'), isNull);
    });

    test(
      'after upsertRelation, new Game sees updated relation via getRelation',
      () {
        final g0 = relationsOnlyGame(
          relations: const [
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
      final game = relationsOnlyGame(
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
      );
      const owners = {'gp1', 'tribe_x', 'minor_y', 'nobody', ''};
      for (final id in owners) {
        expect(
          provinceCountOwnedBy(game, id),
          linearScanProvinceCountOwnedBy(game, id),
          reason: 'faction $id',
        );
      }
      expect(provinceCountOwnedBy(game, 'gp1'), 2);
      expect(provinceCountOwnedBy(game, 'minor_y'), 2);
    });

    test('copyWith new Game instance gets counts from its own worldState', () {
      final g0 = relationsOnlyGame(
        oldWorld: RegionData(
          provinces: [
            Province(id: 'oldWorld|p1', regionId: 'oldWorld', ownerId: 'm1'),
          ],
        ),
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
