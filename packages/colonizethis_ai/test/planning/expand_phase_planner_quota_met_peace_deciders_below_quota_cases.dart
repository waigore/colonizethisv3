// Case bodies for quotaMetBelowQuotaAtWarPeaceTargets pins in
// `expand_phase_planner_quota_met_peace_deciders_test.dart`.

import 'package:colonizethis_ai/src/planning/expand_phase_planner.dart';
import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';

import 'expand_phase_planner_quota_met_peace_deciders_support.dart';

void registerExpandPhasePlannerQuotaMetPeaceDecidersBelowQuotaCases() {
  group('quotaMetBelowQuotaAtWarPeaceTargets — own-OW below-quota guard', () {
    test('returns const [] at own == quota - 1 even with two below-quota '
        'GP enemies at war', () {
      // `isBelowObserverConquestQuota` is true at own == quota - 1 so the
      // outer guard must short-circuit before the at-war filter runs.
      final game = buildQuotaMetPeaceDecidersGame(
        provincesByOwner: {
          quotaMetPeaceGpOwn: kObserverConquestMinOwProvincesPerGp - 1,
          quotaMetPeaceGpPartner: 5,
          quotaMetPeaceGpThird: 6,
        },
        players: const [
          Player(id: quotaMetPeaceGpOwn, displayName: 'GP_OWN', isHuman: false),
          Player(id: quotaMetPeaceGpPartner, displayName: 'P', isHuman: false),
          Player(id: quotaMetPeaceGpThird, displayName: 'T', isHuman: false),
        ],
      );
      final snapshot = quotaMetPeaceDecidersFocusSnapshot(
        focusOw: kObserverConquestMinOwProvincesPerGp - 1,
        atWarWith: const [quotaMetPeaceGpPartner, quotaMetPeaceGpThird],
      );
      expect(
        quotaMetBelowQuotaAtWarPeaceTargets(game: game, snapshot: snapshot),
        isEmpty,
        reason:
            'Below the observer quota the canonical helper must short-'
            'circuit before evaluating targets. A regression that '
            'flipped `<` to `<=` would silently re-engage quota-met '
            'peace one province early and weaken the observer-gate '
            'sequencing the SPEC requires.',
      );
    });
  });

  group('quotaMetBelowQuotaAtWarPeaceTargets — at-quota fire path', () {
    test('returns the sole below-quota GP enemy at own == quota boundary', () {
      // own = quota → `isBelowObserverConquestQuota` is false; the lone
      // below-quota GP enemy surfaces.
      final game = buildQuotaMetPeaceDecidersGame(
        provincesByOwner: {
          quotaMetPeaceGpOwn: kObserverConquestMinOwProvincesPerGp,
          quotaMetPeaceGpPartner: 5,
        },
        players: const [
          Player(id: quotaMetPeaceGpOwn, displayName: 'GP_OWN', isHuman: false),
          Player(id: quotaMetPeaceGpPartner, displayName: 'P', isHuman: false),
        ],
      );
      final snapshot = quotaMetPeaceDecidersFocusSnapshot(
        focusOw: kObserverConquestMinOwProvincesPerGp,
        atWarWith: const [quotaMetPeaceGpPartner],
      );
      expect(
        quotaMetBelowQuotaAtWarPeaceTargets(game: game, snapshot: snapshot),
        [quotaMetPeaceGpPartner],
        reason:
            'Exactly at kObserverConquestMinOwProvincesPerGp (10 OW today) '
            'the canonical helper must fire toward a below-quota GP enemy. '
            'A regression that pushed the threshold to `> quota` would '
            'silently delay the futile-bullying-war exit by one province.',
      );
    });
  });

  group('quotaMetBelowQuotaAtWarPeaceTargets — at-war faction filters', () {
    test(
      'filters out at-war minors (only Great Power targets are returned)',
      () {
        // A minor in `atWarWith` must not surface; the helper is GP-vs-GP
        // peace only. A regression that dropped the
        // `game.playerById(...) != null` guard would surface "minor1".
        final game = buildQuotaMetPeaceDecidersGame(
          provincesByOwner: {
            quotaMetPeaceGpOwn: kObserverConquestMinOwProvincesPerGp + 2,
            quotaMetPeaceMinor1: 3,
          },
          players: const [
            Player(id: quotaMetPeaceGpOwn, displayName: 'GP_OWN', isHuman: false),
          ],
          minorNations: const [
            MinorNation(id: quotaMetPeaceMinor1, displayName: 'M'),
          ],
        );
        final snapshot = quotaMetPeaceDecidersFocusSnapshot(
          focusOw: kObserverConquestMinOwProvincesPerGp + 2,
          atWarWith: const [quotaMetPeaceMinor1],
        );
        expect(
          quotaMetBelowQuotaAtWarPeaceTargets(game: game, snapshot: snapshot),
          isEmpty,
          reason:
              'Minors and tribes are not in the GP-vs-GP futile-bullying war '
              'family this canonical helper exits. A regression that '
              'dropped the playerById guard would silently sweep a minor '
              'war into the GP peace list.',
        );
      },
    );

    test(
      'filters out a GP target whose own holdings are at observer quota',
      () {
        // Two enemies: one at quota (filtered) and one below quota (kept).
        final game = buildQuotaMetPeaceDecidersGame(
          provincesByOwner: {
            quotaMetPeaceGpOwn: kObserverConquestMinOwProvincesPerGp + 2,
            quotaMetPeaceGpPartner: kObserverConquestMinOwProvincesPerGp,
            quotaMetPeaceGpThird: kObserverConquestMinOwProvincesPerGp - 1,
          },
          players: const [
            Player(id: quotaMetPeaceGpOwn, displayName: 'GP_OWN', isHuman: false),
            Player(id: quotaMetPeaceGpPartner, displayName: 'Q', isHuman: false),
            Player(id: quotaMetPeaceGpThird, displayName: 'L', isHuman: false),
          ],
        );
        final snapshot = quotaMetPeaceDecidersFocusSnapshot(
          focusOw: kObserverConquestMinOwProvincesPerGp + 2,
          atWarWith: const [quotaMetPeaceGpPartner, quotaMetPeaceGpThird],
        );
        expect(
          quotaMetBelowQuotaAtWarPeaceTargets(game: game, snapshot: snapshot),
          [quotaMetPeaceGpThird],
          reason:
              'A GP exactly at kObserverConquestMinOwProvincesPerGp is no '
              'longer below the quota and must not appear in the futile-'
              'bullying peace list. A regression that flipped `<` to `<=` '
              'on the per-target check would silently sweep in peers who '
              'already completed their own observer quota.',
        );
      },
    );
  });

  group('quotaMetBelowQuotaAtWarPeaceTargets — sort determinism', () {
    test(
      'returns ascending factionId order regardless of at-war list order',
      () {
        // Intentionally pass the at-war list in reverse sort order so a
        // regression that dropped `..sort()` would surface as a flipped
        // result.
        final game = buildQuotaMetPeaceDecidersGame(
          provincesByOwner: {
            quotaMetPeaceGpOwn: kObserverConquestMinOwProvincesPerGp + 1,
            quotaMetPeaceGpPartner: 4,
            quotaMetPeaceGpThird: 5,
          },
          players: const [
            Player(id: quotaMetPeaceGpOwn, displayName: 'GP_OWN', isHuman: false),
            Player(id: quotaMetPeaceGpPartner, displayName: 'A', isHuman: false),
            Player(id: quotaMetPeaceGpThird, displayName: 'B', isHuman: false),
          ],
        );
        final snapshot = quotaMetPeaceDecidersFocusSnapshot(
          focusOw: kObserverConquestMinOwProvincesPerGp + 1,
          atWarWith: const [quotaMetPeaceGpThird, quotaMetPeaceGpPartner],
        );
        expect(
          quotaMetBelowQuotaAtWarPeaceTargets(game: game, snapshot: snapshot),
          [quotaMetPeaceGpPartner, quotaMetPeaceGpThird],
          reason:
              'Multi-target results must be sorted ascending so '
              'downstream offer-peace scoring and trace logs are '
              'independent of the iteration order of '
              'snapshot.threats.atWarWith. Dropping the sort would '
              'surface as the reverse order.',
        );
      },
    );

    test('is deterministic across repeated calls (Must-have #7)', () {
      final game = buildQuotaMetPeaceDecidersGame(
        provincesByOwner: {
          quotaMetPeaceGpOwn: kObserverConquestMinOwProvincesPerGp + 1,
          quotaMetPeaceGpPartner: 4,
          quotaMetPeaceGpThird: 5,
        },
        players: const [
          Player(id: quotaMetPeaceGpOwn, displayName: 'GP_OWN', isHuman: false),
          Player(id: quotaMetPeaceGpPartner, displayName: 'A', isHuman: false),
          Player(id: quotaMetPeaceGpThird, displayName: 'B', isHuman: false),
        ],
      );
      final snapshot = quotaMetPeaceDecidersFocusSnapshot(
        focusOw: kObserverConquestMinOwProvincesPerGp + 1,
        atWarWith: const [quotaMetPeaceGpThird, quotaMetPeaceGpPartner],
      );
      final first = quotaMetBelowQuotaAtWarPeaceTargets(
        game: game,
        snapshot: snapshot,
      );
      final second = quotaMetBelowQuotaAtWarPeaceTargets(
        game: game,
        snapshot: snapshot,
      );
      final third = quotaMetBelowQuotaAtWarPeaceTargets(
        game: game,
        snapshot: snapshot,
      );
      expect(first, [quotaMetPeaceGpPartner, quotaMetPeaceGpThird]);
      expect(second, first);
      expect(third, first);
    });
  });
}
