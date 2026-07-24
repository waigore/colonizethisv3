import 'package:colonizethis_test/test.dart';
import 'package:colonizethis_diplomacy/colonizethis_diplomacy.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

import 'package:colonizethis_diplomacy_test_support/colonizethis_diplomacy_test_support.dart';

void main() {
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
