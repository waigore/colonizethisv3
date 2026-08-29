// Topic-split cases from `expand_phase_planner_sole_gp_peace_deciders_consolidate_cases` (Refs #4669 Slice B).
import 'package:colonizethis_ai/src/planning/expand_phase_planner.dart';
import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';
import '../support/expand_phase_peace_test_support.dart';

import 'expand_phase_planner_sole_gp_peace_deciders_support.dart';

void registerExpandSoleGpPeaceDecidersConsolidateLeadBoundaryCases() {
  group('consolidateGainsSoleGpPeaceTarget — lead boundary', () {
    test(
      'returns null at own == enemyOw + (lead - 1) with consolidate-min met',
      () {
        // own = consolidate-min, enemy = consolidate-min - (lead - 1)
        //                              = consolidate-min - 2.
        // Lead is exactly kConsolidateGainsSoleGpProvinceLead - 1 → null.
        final game = buildOwnVsPartnerExpandPeaceGame(
          ownProvinces: kObserverConquestConsolidateMinOwProvinces,
          partnerProvinces:
              kObserverConquestConsolidateMinOwProvinces -
              (kConsolidateGainsSoleGpProvinceLead - 1),
        );
        final snapshot = ownSnapshot(
          oldWorldProvincesOwned: kObserverConquestConsolidateMinOwProvinces,
          atWarWith: const [soleGpPeaceGpPartner],
        );
        expect(
          consolidateGainsSoleGpPeaceTarget(game: game, snapshot: snapshot),
          isNull,
          reason:
              'Lead of exactly (kConsolidateGainsSoleGpProvinceLead - 1) '
              'is one province short of the required gap. The canonical '
              'consolidate peace must defer.',
        );
      },
    );

    test('returns enemy at own == enemyOw + lead boundary', () {
      // own = consolidate-min, enemy = consolidate-min - lead. Lead is
      // exactly kConsolidateGainsSoleGpProvinceLead → enemy.
      final game = buildOwnVsPartnerExpandPeaceGame(
        ownProvinces: kObserverConquestConsolidateMinOwProvinces,
        partnerProvinces:
            kObserverConquestConsolidateMinOwProvinces -
            kConsolidateGainsSoleGpProvinceLead,
      );
      final snapshot = ownSnapshot(
        oldWorldProvincesOwned: kObserverConquestConsolidateMinOwProvinces,
        atWarWith: const [soleGpPeaceGpPartner],
      );
      expect(
        consolidateGainsSoleGpPeaceTarget(game: game, snapshot: snapshot),
        soleGpPeaceGpPartner,
        reason:
            'Lead of exactly kConsolidateGainsSoleGpProvinceLead at the '
            'consolidate-min boundary must fire the canonical peace. A '
            'regression that tightened the gap to `>` would silently '
            'delay consolidate peace past the SPEC-authorized "lock '
            'observer gains" trigger.',
      );
    });

    test('is deterministic across repeated calls (Must-have #7)', () {
      final game = buildOwnVsPartnerExpandPeaceGame(
        ownProvinces: kObserverConquestConsolidateMinOwProvinces,
        partnerProvinces: 1,
      );
      final snapshot = ownSnapshot(
        oldWorldProvincesOwned: kObserverConquestConsolidateMinOwProvinces,
        atWarWith: const [soleGpPeaceGpPartner],
      );
      final first = consolidateGainsSoleGpPeaceTarget(
        game: game,
        snapshot: snapshot,
      );
      final second = consolidateGainsSoleGpPeaceTarget(
        game: game,
        snapshot: snapshot,
      );
      final third = consolidateGainsSoleGpPeaceTarget(
        game: game,
        snapshot: snapshot,
      );
      expect(first, soleGpPeaceGpPartner);
      expect(second, first);
      expect(third, first);
    });
  });
}
