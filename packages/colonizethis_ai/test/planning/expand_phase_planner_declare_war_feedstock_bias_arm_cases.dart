// Arm-level feedstock declare-war bias pins (Refs #4669 Slice B).

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

void registerExpandPhasePlannerDeclareWarFeedstockBiasArmCases() {
  group(_groupName, () {
    test(
      'arm 2 (already-at-war minors): biased to the feedstock-province owner '
      'over the lexicographically lower candidate',
      () {
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
        expect(
          sellerNeedsImprovementInputFeedstockTileAcquisition(
            game,
            kFeedstockBiasSellerId,
          ),
          isTrue,
          reason: 'Precondition: the acquisition residual is active.',
        );
        final snapshot = feedstockBiasSnapshot(
          atWarWith: const [kFeedstockBiasMinor1, kFeedstockBiasMinor2],
          invadableOw: const ['oldWorld|m1', 'oldWorld|m2'],
        );
        expect(
          planExpandDeclareWar(game: game, snapshot: snapshot),
          kFeedstockBiasMinor2,
          reason:
              'Arm 2 fires (treasury 0, already-at-war minors on invadable '
              'OW). The within-arm tiebreak is biased to minor2 because it '
              'owns the conquest-reachable feedstock province, overriding '
              'the lexicographically lower minor1.',
        );
      },
    );

    test(
      'arm 1 (adjacent not-at-war minors): biased to the feedstock-province '
      'owner over the lexicographically lower candidate',
      () {
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
          sellerTreasury: 9999,
        );
        expect(
          sellerNeedsImprovementInputFeedstockTileAcquisition(
            game,
            kFeedstockBiasSellerId,
          ),
          isTrue,
          reason:
              'Precondition: the acquisition residual is active even with a '
              'funded treasury (the gate is treasury-independent).',
        );
        final snapshot = feedstockBiasSnapshot(
          atWarWith: const [],
          invadableOw: const ['oldWorld|m1', 'oldWorld|m2'],
          adjacentOwners: const [kFeedstockBiasMinor1, kFeedstockBiasMinor2],
        );
        expect(
          planExpandDeclareWar(game: game, snapshot: snapshot),
          kFeedstockBiasMinor2,
          reason:
              'Arm 1 fires (treasury >= cheapest, adjacent not-at-war minors '
              'on invadable OW). The within-arm tiebreak is biased to minor2 '
              'because it owns the conquest-reachable feedstock province.',
        );
      },
    );
  });
}
