// Case bodies for `canPivotFromSoleGpWarAfterPeace` pin group (Refs #4310).

import 'package:colonizethis_ai/src/planning/expand_phase_planner.dart';
import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';

import '../support/expand_phase_planner_sole_gp_war_helpers_test_support.dart';

void registerExpandPhasePlannerSoleGpWarHelpersPivotCases() {
  group('canPivotFromSoleGpWarAfterPeace', () {
    test('returns true via the quota short-circuit with no minor pivot', () {
      final game = soleGpWarHelpersGameWithProvinces(
        owProvinces: soleGpWarHelpersGp1OwProvinces(
          kObserverConquestMinOwProvincesPerGp,
        ),
      );
      final snapshot = soleGpWarHelpersPivotSnapshotFor(
        oldWorldProvincesOwned: kObserverConquestMinOwProvincesPerGp,
      );
      expect(
        canPivotFromSoleGpWarAfterPeace(game: game, snapshot: snapshot),
        isTrue,
        reason:
            'A GP at the observer OW quota satisfies the leading `>=` '
            'short-circuit regardless of pivot availability; the '
            'consolidate-gains caller can then still consider a sole '
            'outgunned-GP peace target.',
      );
    });

    test('returns true above quota even with no minor pivot', () {
      final game = soleGpWarHelpersGameWithProvinces(
        owProvinces: soleGpWarHelpersGp1OwProvinces(
          kObserverConquestMinOwProvincesPerGp + 5,
        ),
      );
      final snapshot = soleGpWarHelpersPivotSnapshotFor(
        oldWorldProvincesOwned: kObserverConquestMinOwProvincesPerGp + 5,
      );
      expect(
        canPivotFromSoleGpWarAfterPeace(game: game, snapshot: snapshot),
        isTrue,
        reason:
            'Above-quota totals must keep returning true so consolidate '
            'callers see the same pivot availability the leading short '
            'circuit advertises.',
      );
    });

    test('returns true via the OW minorsOnMap arm when below quota', () {
      final game = soleGpWarHelpersGameWithProvinces(
        owProvinces: [
          ...soleGpWarHelpersGp1OwProvinces(8),
          const Province(
            id: 'oldWorld|minor1_a',
            regionId: 'oldWorld',
            ownerId: soleGpWarHelpersMinor1,
          ),
        ],
        minorNations: const [
          MinorNation(id: soleGpWarHelpersMinor1, displayName: 'M1'),
        ],
      );
      final snapshot = soleGpWarHelpersPivotSnapshotFor(
        oldWorldProvincesOwned: 8,
        invadableProvinceIdsSorted: const ['oldWorld|minor1_a'],
      );
      expect(
        canPivotFromSoleGpWarAfterPeace(game: game, snapshot: snapshot),
        isTrue,
        reason:
            'An OW-owning minor on the map provides the SPEC-authorized '
            'minor pivot when the GP peaces its sole GP foe. The '
            'predicate must return true via the `minorsOnMap` branch '
            'without consulting the invadable list.',
      );
    });

    test(
      'returns true via minorsOnMap even when that minor is already in atWarWith',
      () {
        final game = soleGpWarHelpersGameWithProvinces(
          owProvinces: [
            ...soleGpWarHelpersGp1OwProvinces(8),
            const Province(
              id: 'oldWorld|minor1_a',
              regionId: 'oldWorld',
              ownerId: soleGpWarHelpersMinor1,
            ),
          ],
          minorNations: const [
            MinorNation(id: soleGpWarHelpersMinor1, displayName: 'M1'),
          ],
        );
        final snapshot = soleGpWarHelpersPivotSnapshotFor(
          oldWorldProvincesOwned: 8,
          invadableProvinceIdsSorted: const ['oldWorld|minor1_a'],
          atWarWith: const [soleGpWarHelpersGp2, soleGpWarHelpersMinor1],
        );
        expect(
          canPivotFromSoleGpWarAfterPeace(game: game, snapshot: snapshot),
          isTrue,
          reason:
              'The helper is a pivot-availability check; whether the '
              'minor is currently in the at-war set is the higher-level '
              "collector's concern. Pinning this contract keeps that "
              'separation explicit.',
        );
      },
    );

    test(
      'returns true via the invadable-list arm when only an NW minor frontier exists',
      () {
        final game = soleGpWarHelpersGameWithProvinces(
          owProvinces: soleGpWarHelpersGp1OwProvinces(8),
          nwProvinces: const [
            Province(
              id: 'newWorld|minor1_a',
              regionId: 'newWorld',
              ownerId: soleGpWarHelpersMinor1,
            ),
          ],
          minorNations: const [
            MinorNation(id: soleGpWarHelpersMinor1, displayName: 'M1'),
          ],
        );
        final snapshot = soleGpWarHelpersPivotSnapshotFor(
          oldWorldProvincesOwned: 8,
          invadableProvinceIdsSorted: const ['newWorld|minor1_a'],
        );
        expect(
          canPivotFromSoleGpWarAfterPeace(game: game, snapshot: snapshot),
          isTrue,
          reason:
              'When no OW minor exists, an invadable-list province with '
              'a minor owner still satisfies the pivot check via the '
              'trailing `any`. Pinning this preserves the NW colonial '
              'minor frontier pivot path.',
        );
      },
    );

    test(
      'returns false when below quota with a GP-only invadable frontier and no minors',
      () {
        final game = soleGpWarHelpersGameWithProvinces(
          owProvinces: [
            ...soleGpWarHelpersGp1OwProvinces(8),
            for (var i = 1; i <= 3; i++)
              Province(
                id: 'oldWorld|gp2_$i',
                regionId: 'oldWorld',
                ownerId: soleGpWarHelpersGp2,
              ),
          ],
        );
        final snapshot = soleGpWarHelpersPivotSnapshotFor(
          oldWorldProvincesOwned: 8,
          invadableProvinceIdsSorted: const [
            'oldWorld|gp2_1',
            'oldWorld|gp2_2',
          ],
        );
        expect(
          canPivotFromSoleGpWarAfterPeace(game: game, snapshot: snapshot),
          isFalse,
          reason:
              'No minor anywhere and a GP-only invadable frontier means '
              'peacing the sole GP foe leaves no SPEC-legal pivot target. '
              "A regression that defaulted to true would peace the GP's "
              'only opponent and deadlock the EXPAND strategy.',
        );
      },
    );

    test(
      'returns false with empty invadable list and no minors when below quota',
      () {
        final game = soleGpWarHelpersGameWithProvinces(
          owProvinces: soleGpWarHelpersGp1OwProvinces(8),
        );
        final snapshot = soleGpWarHelpersPivotSnapshotFor(
          oldWorldProvincesOwned: 8,
        );
        expect(
          canPivotFromSoleGpWarAfterPeace(game: game, snapshot: snapshot),
          isFalse,
          reason:
              'An empty invadable list combined with no OW minor on the '
              'map provides no pivot; the trailing `any` is false and the '
              'predicate must reach the `return false` exit.',
        );
      },
    );

    test(
      'returns false just below quota with no pivot (boundary at quota - 1)',
      () {
        final owCount = kObserverConquestMinOwProvincesPerGp - 1;
        final game = soleGpWarHelpersGameWithProvinces(
          owProvinces: soleGpWarHelpersGp1OwProvinces(owCount),
        );
        final snapshot = soleGpWarHelpersPivotSnapshotFor(
          oldWorldProvincesOwned: owCount,
        );
        expect(
          canPivotFromSoleGpWarAfterPeace(game: game, snapshot: snapshot),
          isFalse,
          reason:
              'The quota comparison is `>=`, so ownOw = quota - 1 must '
              'NOT short-circuit to true. With no minor pivot, the '
              'predicate must reach the trailing `return false` exit.',
        );
      },
    );

    test('is deterministic across repeated calls (Must-have #7)', () {
      final game = soleGpWarHelpersGameWithProvinces(
        owProvinces: [
          ...soleGpWarHelpersGp1OwProvinces(8),
          const Province(
            id: 'oldWorld|minor1_a',
            regionId: 'oldWorld',
            ownerId: soleGpWarHelpersMinor1,
          ),
        ],
        minorNations: const [
          MinorNation(id: soleGpWarHelpersMinor1, displayName: 'M1'),
        ],
      );
      final snapshot = soleGpWarHelpersPivotSnapshotFor(
        oldWorldProvincesOwned: 8,
        invadableProvinceIdsSorted: const ['oldWorld|minor1_a'],
      );
      final first = canPivotFromSoleGpWarAfterPeace(
        game: game,
        snapshot: snapshot,
      );
      final second = canPivotFromSoleGpWarAfterPeace(
        game: game,
        snapshot: snapshot,
      );
      final third = canPivotFromSoleGpWarAfterPeace(
        game: game,
        snapshot: snapshot,
      );
      expect(first, isTrue);
      expect(second, first);
      expect(third, first);
    });
  });
}
