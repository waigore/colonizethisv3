// Filter/sort/determinism cases for defaultStartGpPeaceTargets (Refs #4602 Slice B).
// Registered from expand_phase_planner_default_start_peace_cases.dart.

import 'package:colonizethis_ai/src/planning/expand_phase_planner.dart';
import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_test/test.dart';
import '../support/expand_phase_peace_test_support.dart';

import 'expand_phase_planner_default_start_near_quota_peace_support.dart';

void registerExpandDefaultStartPeaceFilterSortCases() {
  group(
    'defaultStartGpPeaceTargets — atWarWith filter / sort / determinism',
    () {
      test('non-GP factions are filtered out of the returned list', () {
        // atWarWith mixes a tribe with a Great Power; the tribe must
        // be dropped because game.playerById(tribe_t1) == null. The
        // GP-only frontier is true (gp_a owns the only invadable OW)
        // so blocker exclusion drops gp_a as well → empty.
        final game = buildDefaultStartNearQuotaExpandPeaceGame(
          owOwners: const {
            defaultStartPeaceGpOwn: 7,
            defaultStartPeaceGpA: 1,
            defaultStartPeaceTribeT1: 0,
          },
          atWarPartners: const [defaultStartPeaceGpA],
          atWarWithExtraGp: false,
        );
        final snapshot = defaultStartPeaceSnapshot(
          oldWorldProvincesOwned: kObserverDefaultStartOldWorldProvincesPerGp,
          atWarWith: const [defaultStartPeaceTribeT1, defaultStartPeaceGpA],
          invadableProvinceIdsSorted: const ['oldWorld|gp_a_1'],
        );
        expect(
          defaultStartGpPeaceTargets(game: game, snapshot: snapshot),
          isEmpty,
          reason:
              'Tribes are filtered before sort via playerById; with a '
              'GP-only frontier the lone GP foe (the blocker) is also '
              'excluded so the result is empty.',
        );
      });

      test('multi-GP roster returns deterministically ascending output', () {
        // Three at-war GPs supplied out of order; gp_a is the blocker
        // (owns the only invadable OW). The canonical helper must
        // return [gp_b, gp_c] ascending across two consecutive calls
        // (Refs #2509 Must-have #7).
        final game = buildDefaultStartNearQuotaExpandPeaceGame(
          owOwners: const {
            defaultStartPeaceGpOwn: 7,
            defaultStartPeaceGpA: 1,
            defaultStartPeaceGpB: 0,
            defaultStartPeaceGpC: 0,
          },
          atWarPartners: const [
            defaultStartPeaceGpC,
            defaultStartPeaceGpA,
            defaultStartPeaceGpB,
          ],
        );
        final snapshot = defaultStartPeaceSnapshot(
          oldWorldProvincesOwned: kObserverDefaultStartOldWorldProvincesPerGp,
          atWarWith: const [
            defaultStartPeaceGpC,
            defaultStartPeaceGpA,
            defaultStartPeaceGpB,
          ],
          invadableProvinceIdsSorted: const ['oldWorld|gp_a_1'],
        );
        final first = defaultStartGpPeaceTargets(
          game: game,
          snapshot: snapshot,
        );
        final second = defaultStartGpPeaceTargets(
          game: game,
          snapshot: snapshot,
        );
        expect(
          first,
          const [defaultStartPeaceGpB, defaultStartPeaceGpC],
          reason:
              'On a GP-only frontier the blocker (gp_a) is excluded; '
              'remaining GPs return ascending across an out-of-order input.',
        );
        expect(
          second,
          first,
          reason:
              'Two consecutive canonical-helper invocations on identical '
              'inputs must return identical lists (Must-have #7).',
        );
      });
    },
  );
}
