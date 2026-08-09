// Direct unit coverage for the shared EXPAND stalled-expansion peace pivot
// resolver `resolveStalledMinorOrGpBlockerPivot` (Refs #3717 expand-peace
// scoring-skeleton dedup).
//
// The resolver is the single source of truth for the
// `provinceOwner = getProvinceOwnerMap(game)` →
// `minorsOwnInvadable = anyInvadableProvinceOwnedByMinor(...)` →
// `gpBlockerFocus = isStalledOldWorldGpBlockerFocus(...)` →
// `if (!minorsOwnInvadable && !gpBlockerFocus) return <empty>;` skeleton that
// was duplicated verbatim across `stalledStrongerGpBlockerPeaceTarget` and
// `stalledExpansionDistractionPeaceTargets`. These tests pin both pivot arms
// (minor-on-frontier and stalled GP-blocker-focus), the not-applicable
// short-circuit, equivalence with the underlying predicates the resolver
// composes, and determinism (Refs #2509 Must-have #7).

import 'package:colonizethis_ai/src/planning/expand_phase_planner.dart';
import 'package:colonizethis_ai/src/planning/planning_helpers.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';
import '../support/expand_phase_peace_test_support.dart';

const String _gpOwn = 'gp4';
const String _gpBlocker = 'gp3';
const String _minor1 = 'minor1';

void main() {
  group('resolveStalledMinorOrGpBlockerPivot — pivot applies', () {
    test('minor owns invadable frontier → minorsOwnInvadable arm', () {
      final game = buildPivotExpandPeaceGame(
        ownPlayerId: _gpOwn,
        provinces: [
          ...oldWorldProvincesForExpandPeaceMatrix(_gpOwn, 7),
          const Province(
            id: 'oldWorld|inv1',
            regionId: 'oldWorld',
            ownerId: _minor1,
          ),
        ],
        atWarFactionIds: const [_gpBlocker],
        minorNations: const [MinorNation(id: _minor1, displayName: 'M1')],
      );
      final snapshot = ownSnapshot(
        playerId: _gpOwn,
        oldWorldProvincesOwned: 7,
        atWarWith: const [_gpBlocker],
        invadableProvinceIdsSorted: const ['oldWorld|inv1'],
      );

      final pivot = resolveStalledMinorOrGpBlockerPivot(
        game: game,
        snapshot: snapshot,
      );

      expect(pivot, isNotNull);
      expect(pivot!.minorsOwnInvadable, isTrue);
      // Minor on the frontier ⇒ frontier is not GP-only ⇒ no GP-blocker focus.
      expect(pivot.gpBlockerFocus, isFalse);
      expect(pivot.provinceOwner['oldWorld|inv1'], _minor1);
    });

    test('GP-only below-quota frontier → gpBlockerFocus arm', () {
      final game = buildPivotExpandPeaceGame(
        ownPlayerId: _gpOwn,
        provinces: [
          ...oldWorldProvincesForExpandPeaceMatrix(_gpOwn, 7),
          ...oldWorldProvincesForExpandPeaceMatrix(_gpBlocker, 10),
          const Province(
            id: 'oldWorld|inv1',
            regionId: 'oldWorld',
            ownerId: _gpBlocker,
          ),
        ],
        atWarFactionIds: const [_gpBlocker],
        extraGpIds: const {_gpBlocker},
      );
      final snapshot = ownSnapshot(
        playerId: _gpOwn,
        oldWorldProvincesOwned: 7,
        atWarWith: const [_gpBlocker],
        invadableProvinceIdsSorted: const ['oldWorld|inv1'],
      );

      final pivot = resolveStalledMinorOrGpBlockerPivot(
        game: game,
        snapshot: snapshot,
      );

      expect(pivot, isNotNull);
      expect(pivot!.minorsOwnInvadable, isFalse);
      expect(pivot.gpBlockerFocus, isTrue);
      expect(pivot.provinceOwner['oldWorld|inv1'], _gpBlocker);
    });
  });

  group('resolveStalledMinorOrGpBlockerPivot — pivot does not apply', () {
    test('unowned invadable frontier → null (neither arm fires)', () {
      final game = buildPivotExpandPeaceGame(
        ownPlayerId: _gpOwn,
        provinces: [
          ...oldWorldProvincesForExpandPeaceMatrix(_gpOwn, 7),
          const Province(
            id: 'oldWorld|inv1',
            regionId: 'oldWorld',
            ownerId: null,
          ),
        ],
        atWarFactionIds: const [_gpBlocker],
      );
      final snapshot = ownSnapshot(
        playerId: _gpOwn,
        oldWorldProvincesOwned: 7,
        atWarWith: const [_gpBlocker],
        invadableProvinceIdsSorted: const ['oldWorld|inv1'],
      );

      expect(
        resolveStalledMinorOrGpBlockerPivot(game: game, snapshot: snapshot),
        isNull,
        reason:
            'No minor owns invadable land and the frontier is not GP-only '
            '(unowned) ⇒ neither pivot arm applies.',
      );
    });

    test('empty invadable frontier → null', () {
      final game = buildPivotExpandPeaceGame(
        ownPlayerId: _gpOwn,
        provinces: oldWorldProvincesForExpandPeaceMatrix(_gpOwn, 7),
        atWarFactionIds: const [_gpBlocker],
      );
      final snapshot = ownSnapshot(
        playerId: _gpOwn,
        oldWorldProvincesOwned: 7,
        atWarWith: const [_gpBlocker],
        invadableProvinceIdsSorted: const [],
      );

      expect(
        resolveStalledMinorOrGpBlockerPivot(game: game, snapshot: snapshot),
        isNull,
      );
    });
  });

  group('resolveStalledMinorOrGpBlockerPivot — equivalence + determinism', () {
    test('fields equal the predicates the resolver composes', () {
      final game = buildPivotExpandPeaceGame(
        ownPlayerId: _gpOwn,
        provinces: [
          ...oldWorldProvincesForExpandPeaceMatrix(_gpOwn, 7),
          ...oldWorldProvincesForExpandPeaceMatrix(_gpBlocker, 10),
          const Province(
            id: 'oldWorld|inv1',
            regionId: 'oldWorld',
            ownerId: _gpBlocker,
          ),
        ],
        atWarFactionIds: const [_gpBlocker],
        extraGpIds: const {_gpBlocker},
      );
      final snapshot = ownSnapshot(
        playerId: _gpOwn,
        oldWorldProvincesOwned: 7,
        atWarWith: const [_gpBlocker],
        invadableProvinceIdsSorted: const ['oldWorld|inv1'],
      );

      final pivot = resolveStalledMinorOrGpBlockerPivot(
        game: game,
        snapshot: snapshot,
      );

      expect(pivot, isNotNull);
      expect(
        pivot!.gpBlockerFocus,
        isStalledOldWorldGpBlockerFocus(game: game, snapshot: snapshot),
      );
      expect(
        pivot.minorsOwnInvadable,
        anyInvadableProvinceOwnedByMinor(
          game: game,
          snapshot: snapshot,
          provinceOwner: pivot.provinceOwner,
        ),
      );
    });

    test('identical results on repeat', () {
      final game = buildPivotExpandPeaceGame(
        ownPlayerId: _gpOwn,
        provinces: [
          ...oldWorldProvincesForExpandPeaceMatrix(_gpOwn, 7),
          const Province(
            id: 'oldWorld|inv1',
            regionId: 'oldWorld',
            ownerId: _minor1,
          ),
        ],
        atWarFactionIds: const [_gpBlocker],
        minorNations: const [MinorNation(id: _minor1, displayName: 'M1')],
      );
      final snapshot = ownSnapshot(
        playerId: _gpOwn,
        oldWorldProvincesOwned: 7,
        atWarWith: const [_gpBlocker],
        invadableProvinceIdsSorted: const ['oldWorld|inv1'],
      );

      final first = resolveStalledMinorOrGpBlockerPivot(
        game: game,
        snapshot: snapshot,
      );
      final second = resolveStalledMinorOrGpBlockerPivot(
        game: game,
        snapshot: snapshot,
      );

      expect(first, isNotNull);
      expect(second, isNotNull);
      expect(first!.minorsOwnInvadable, second!.minorsOwnInvadable);
      expect(first.gpBlockerFocus, second.gpBlockerFocus);
      expect(first.provinceOwner, equals(second.provinceOwner));
    });
  });
}
