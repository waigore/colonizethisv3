// Guard and precedence feedstock declare-war bias pins (Refs #4669 Slice B).

import 'package:colonizethis_ai/src/planning/expand_phase_planner.dart';
import 'package:colonizethis_ai_contracts/colonizethis_ai_contracts.dart'
    show sellerNeedsImprovementInputFeedstockTileAcquisition;
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';

import '../support/expand_feedstock_seller_test_support.dart';
import 'expand_phase_planner_declare_war_feedstock_bias_fixture.dart';

const _groupName =
    'planExpandDeclareWar feedstock-tile acquisition target bias '
    '(Refs #2847 § EXPAND feedstock-tile acquisition declare-war target bias)';

void registerExpandPhasePlannerDeclareWarFeedstockBiasGuardCases() {
  group(_groupName, () {
    test('acquisition residual inactive (baseline GP) -> no bias, '
        'lexicographic pick returned', () {
      final game = buildExpandFeedstockDeclareWarBiasGame(
        resourceByTileKey: const {
          kFeedstockBiasGrainTile: 'grain',
          kFeedstockBiasWoolTile: 'wool',
          'oldWorld|p0|1|0': 'timber',
          'oldWorld|m1|0|0': 'grain',
          'oldWorld|m2|0|0': 'timber',
        },
        minorProvinces: [
          feedstockBiasMinorProvince('oldWorld|m1', kFeedstockBiasMinor1),
          feedstockBiasMinorProvince('oldWorld|m2', kFeedstockBiasMinor2),
        ],
        minorNations: const [
          MinorNation(id: kFeedstockBiasMinor1, displayName: 'M1'),
          MinorNation(id: kFeedstockBiasMinor2, displayName: 'M2'),
        ],
      );
      expect(
        sellerNeedsImprovementInputFeedstockTileAcquisition(
          game,
          kFeedstockBiasSellerId,
        ),
        isFalse,
        reason: 'Precondition: the acquisition residual is inactive.',
      );
      final snapshot = feedstockBiasSnapshot(
        atWarWith: const [kFeedstockBiasMinor1, kFeedstockBiasMinor2],
        invadableOw: const ['oldWorld|m1', 'oldWorld|m2'],
      );
      expect(
        planExpandDeclareWar(game: game, snapshot: snapshot),
        kFeedstockBiasMinor1,
        reason:
            'With the residual inactive, '
            'expandSellerFeedstockTileAcquisitionTarget returns null, so '
            'the unbiased lexicographic pick (minor1) is returned. The +6 '
            'OW conquest baseline GPs are never redirected.',
      );
    });

    test(
      'feedstock owner sits in a lower-priority arm -> bias does not cross '
      'arm precedence',
      () {
        final game = buildExpandFeedstockDeclareWarBiasGame(
          resourceByTileKey: const {
            kFeedstockBiasGrainTile: 'grain',
            kFeedstockBiasWoolTile: 'wool',
            'oldWorld|m1|0|0': 'grain',
            'oldWorld|m2|0|0': 'grain',
            'oldWorld|m3|0|0': 'timber',
          },
          minorProvinces: [
            feedstockBiasMinorProvince('oldWorld|m1', kFeedstockBiasMinor1),
            feedstockBiasMinorProvince('oldWorld|m2', kFeedstockBiasMinor2),
            feedstockBiasMinorProvince('oldWorld|m3', kFeedstockBiasMinor3),
          ],
          minorNations: const [
            MinorNation(id: kFeedstockBiasMinor1, displayName: 'M1'),
            MinorNation(id: kFeedstockBiasMinor2, displayName: 'M2'),
            MinorNation(id: kFeedstockBiasMinor3, displayName: 'M3'),
          ],
          sellerTreasury: 9999,
        );
        expect(
          sellerNeedsImprovementInputFeedstockTileAcquisition(
            game,
            kFeedstockBiasSellerId,
          ),
          isTrue,
        );
        final snapshot = feedstockBiasSnapshot(
          atWarWith: const [kFeedstockBiasMinor3],
          invadableOw: const ['oldWorld|m1', 'oldWorld|m2', 'oldWorld|m3'],
          adjacentOwners: const [kFeedstockBiasMinor1, kFeedstockBiasMinor2],
        );
        expect(
          planExpandDeclareWar(game: game, snapshot: snapshot),
          kFeedstockBiasMinor1,
          reason:
              'Arm 1 (adjacent not-at-war minor1/minor2) fires first. The '
              'feedstock owner minor3 belongs to the lower-priority arm 2, '
              'so it is not an arm-1 candidate: the bias only redirects '
              'within the firing arm and returns minor1.',
        );
      },
    );

    test('determinism: identical inputs yield identical output', () {
      final game = buildExpandFeedstockDeclareWarBiasGame(
        resourceByTileKey: const {
          kFeedstockBiasGrainTile: 'grain',
          kFeedstockBiasWoolTile: 'wool',
          'oldWorld|m1|0|0': 'grain',
          'oldWorld|m2|0|0': 'timber',
        },
        minorProvinces: [
          feedstockBiasMinorProvince('oldWorld|m1', kFeedstockBiasMinor1),
          feedstockBiasMinorProvince('oldWorld|m2', kFeedstockBiasMinor2),
        ],
        minorNations: const [
          MinorNation(id: kFeedstockBiasMinor1, displayName: 'M1'),
          MinorNation(id: kFeedstockBiasMinor2, displayName: 'M2'),
        ],
      );
      final snapshot = feedstockBiasSnapshot(
        atWarWith: const [kFeedstockBiasMinor1, kFeedstockBiasMinor2],
        invadableOw: const ['oldWorld|m1', 'oldWorld|m2'],
      );
      final first = planExpandDeclareWar(game: game, snapshot: snapshot);
      final second = planExpandDeclareWar(game: game, snapshot: snapshot);
      expect(first, kFeedstockBiasMinor2);
      expect(second, kFeedstockBiasMinor2, reason: 'Same inputs -> same output.');
    });
  });
}
