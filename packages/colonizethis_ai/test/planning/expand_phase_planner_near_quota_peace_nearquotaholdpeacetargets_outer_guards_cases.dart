// nearQuotaHoldPeaceTargets — outer guards (Refs #4602 Slice B).

import 'package:colonizethis_ai/src/perception/perception_snapshot.dart';
import 'package:colonizethis_ai/src/planning/expand_phase_planner.dart';
import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';
import '../support/expand_phase_peace_test_support.dart';
import 'expand_phase_planner_default_start_near_quota_peace_support.dart';

void registerNearQuotaPeaceNearquotaholdpeacetargetsOuterGuardsCases() {
  group('nearQuotaHoldPeaceTargets — outer guards', () {
    test('returns const [] when at the observer OW quota', () {
      // OW == kObserverConquestMinOwProvincesPerGp → not below quota →
      // canonical helper short-circuits.
      final game = buildDefaultStartNearQuotaExpandPeaceGame(
        owOwners: const {defaultStartPeaceGpOwn: 10, defaultStartPeaceGpA: 1},
        atWarPartners: const [defaultStartPeaceGpA],
      );
      final snapshot = defaultStartPeaceSnapshot(
        oldWorldProvincesOwned: kObserverConquestMinOwProvincesPerGp,
        atWarWith: const [defaultStartPeaceGpA],
        invadableProvinceIdsSorted: const ['oldWorld|gp_a_1'],
      );
      expect(
        nearQuotaHoldPeaceTargets(game: game, snapshot: snapshot),
        isEmpty,
        reason:
            'At quota the EXPAND near-quota hold-gains pivot is out of '
            'scope; the canonical helper must return empty so quota-met '
            'collectors govern post-quota wars.',
      );
    });

    test('returns const [] when below the stalled-band threshold', () {
      // OW = kObserverDefaultStartOldWorldProvincesPerGp (default
      // start) → !isStalledOldWorldExpansion → empty so the
      // default-start collector owns the decision.
      final game = buildDefaultStartNearQuotaExpandPeaceGame(
        owOwners: const {defaultStartPeaceGpOwn: 7, defaultStartPeaceGpA: 1},
        atWarPartners: const [defaultStartPeaceGpA],
      );
      final snapshot = defaultStartPeaceSnapshot(
        oldWorldProvincesOwned: kObserverDefaultStartOldWorldProvincesPerGp,
        atWarWith: const [defaultStartPeaceGpA],
        invadableProvinceIdsSorted: const ['oldWorld|gp_a_1'],
      );
      expect(
        nearQuotaHoldPeaceTargets(game: game, snapshot: snapshot),
        isEmpty,
        reason:
            'Below the stalled-band threshold the default-start '
            'collector (defaultStartGpPeaceTargets) owns the EXPAND '
            'pivot; the canonical near-quota helper must short-circuit.',
      );
    });

    test('returns const [] when no Great Powers are at war', () {
      // gp_own at 8 OW → in stalled band, below quota → both outer
      // guards pass. atWarWith carries only a tribe → playerById
      // filter empties the gp-war set → const [].
      final game = buildDefaultStartNearQuotaExpandPeaceGame(
        owOwners: const {
          defaultStartPeaceGpOwn: 8,
          defaultStartPeaceTribeT1: 0,
        },
        atWarPartners: const [],
      );
      final snapshot = defaultStartPeaceSnapshot(
        oldWorldProvincesOwned: kStalledOldWorldProvinceThreshold - 1,
        atWarWith: const [defaultStartPeaceTribeT1],
      );
      expect(
        nearQuotaHoldPeaceTargets(game: game, snapshot: snapshot),
        isEmpty,
        reason:
            'A tribe-only atWarWith leaves an empty GP-war set after '
            'playerById filtering; the canonical helper must short-circuit '
            'before any blocker / frontier scan.',
      );
    });
  });
}
