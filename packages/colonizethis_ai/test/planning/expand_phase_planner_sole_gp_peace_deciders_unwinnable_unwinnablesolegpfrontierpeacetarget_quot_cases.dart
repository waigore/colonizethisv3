// unwinnableSoleGpFrontierPeaceTarget — quota / pivot guards (Refs #4602 Slice B).

import 'package:colonizethis_ai/src/planning/expand_phase_planner.dart';
import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';
import '../support/expand_phase_peace_test_support.dart';
import 'expand_phase_planner_sole_gp_peace_deciders_support.dart';

void
registerSoleGpPeaceDecidersUnwinnableUnwinnablesolegpfrontierpeacetargetQuotCases() {
  group('unwinnableSoleGpFrontierPeaceTarget — quota / pivot guards', () {
    test(
      'returns null at the observer OW quota even with a stronger sole GP',
      () {
        // At exactly kObserverConquestMinOwProvincesPerGp the EXPAND-only
        // forced shortcut must exit; consolidation diplomacy now owns the
        // decision.
        final game = buildOwnVsPartnerExpandPeaceGame(
          ownProvinces: kObserverConquestMinOwProvincesPerGp,
          partnerProvinces: kObserverConquestMinOwProvincesPerGp + 5,
        );
        final snapshot = ownSnapshot(
          oldWorldProvincesOwned: kObserverConquestMinOwProvincesPerGp,
          atWarWith: const [soleGpPeaceGpPartner],
        );
        expect(
          unwinnableSoleGpFrontierPeaceTarget(game: game, snapshot: snapshot),
          isNull,
          reason:
              'At-or-above the observer OW quota exits the canonical '
              'unwinnable-sole-GP shortcut so consolidation diplomacy '
              'decides when to peace.',
        );
      },
    );

    test('returns null when canPivotFromSoleGpWarAfterPeace is false', () {
      // Below quota, no minors anywhere, every invadable is GP-owned →
      // the pivot guard short-circuits to false and the forced peace
      // shortcut must defer.
      final game = buildOwnVsPartnerExpandPeaceGame(
        ownProvinces: 6,
        partnerProvinces: 12,
      );
      final snapshot = ownSnapshot(
        oldWorldProvincesOwned: 6,
        atWarWith: const [soleGpPeaceGpPartner],
        invadableProvinceIdsSorted: const [
          'oldWorld|${soleGpPeaceGpPartner}_1',
        ],
      );
      expect(
        unwinnableSoleGpFrontierPeaceTarget(game: game, snapshot: snapshot),
        isNull,
        reason:
            'canPivotFromSoleGpWarAfterPeace=false (no OW minors, every '
            'invadable GP-owned) must short-circuit the canonical forced '
            'peace path before any deficit comparison.',
      );
    });
  });
}
