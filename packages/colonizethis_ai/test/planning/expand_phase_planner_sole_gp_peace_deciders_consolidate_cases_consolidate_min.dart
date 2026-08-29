// Topic-split cases from `expand_phase_planner_sole_gp_peace_deciders_consolidate_cases` (Refs #4669 Slice B).
import 'package:colonizethis_ai/src/planning/expand_phase_planner.dart';
import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';
import '../support/expand_phase_peace_test_support.dart';

import 'expand_phase_planner_sole_gp_peace_deciders_support.dart';

void registerExpandSoleGpPeaceDecidersConsolidateConsolidateMinCases() {
  group('consolidateGainsSoleGpPeaceTarget — consolidate-min boundary', () {
    test('returns null at own == consolidate-min - 1 with a huge lead', () {
      // own = 11 (= consolidate-min - 1), enemy = 1. Lead is 10 (≫ required
      // kConsolidateGainsSoleGpProvinceLead) but consolidate-min guard
      // short-circuits first.
      final game = buildOwnVsPartnerExpandPeaceGame(
        ownProvinces: kObserverConquestConsolidateMinOwProvinces - 1,
        partnerProvinces: 1,
      );
      final snapshot = ownSnapshot(
        oldWorldProvincesOwned: kObserverConquestConsolidateMinOwProvinces - 1,
        atWarWith: const [soleGpPeaceGpPartner],
      );
      expect(
        consolidateGainsSoleGpPeaceTarget(game: game, snapshot: snapshot),
        isNull,
        reason:
            'One province below kObserverConquestConsolidateMinOwProvinces '
            'must defer consolidate peace regardless of how large the '
            'enemy lead is. A regression that flipped `<` to `<=` would '
            'silently peace one province earlier than SPEC.',
      );
    });

    test(
      'returns enemy at exact consolidate-min boundary with sufficient lead',
      () {
        // own = consolidate-min, enemy = 1. Lead is consolidate-min - 1
        // (≥ kConsolidateGainsSoleGpProvinceLead). Locks the `>=`
        // boundary at the canonical-home function.
        final game = buildOwnVsPartnerExpandPeaceGame(
          ownProvinces: kObserverConquestConsolidateMinOwProvinces,
          partnerProvinces: 1,
        );
        final snapshot = ownSnapshot(
          oldWorldProvincesOwned: kObserverConquestConsolidateMinOwProvinces,
          atWarWith: const [soleGpPeaceGpPartner],
        );
        expect(
          consolidateGainsSoleGpPeaceTarget(game: game, snapshot: snapshot),
          soleGpPeaceGpPartner,
          reason:
              'Exactly at kObserverConquestConsolidateMinOwProvinces with a '
              'sufficient lead the canonical consolidate peace must fire.',
        );
      },
    );
  });

}
