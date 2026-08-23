// Case bodies for `expand_phase_planner_default_start_futile_minor_peace_test.dart` (Refs #4602 Slice B).

import 'package:colonizethis_ai/src/planning/expand_phase_planner.dart';
import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';
import '../support/expand_phase_peace_test_support.dart';

const String _gpOwn = 'gp_own';
const String _gpRival = 'gp_rival';
const String _minor1 = 'minor1';
const String _minor2 = 'minor2';

void registerDefaultStartFutileMinorPeaceGuardCases() {
  group('defaultStartFutileMinorPeaceTargets — outer guards', () {
    test('returns const [] when above the observer OW quota', () {
      // At-quota gp_own with one at-war minor that owns no invadable OW
      // (futile minor by the mixed-frontier rule), but the above-quota
      // guard fires first so the quota-met collectors own the decision.
      final game = buildDefaultStartFutileMinorExpandPeaceGame(
        ownProvinces: kObserverConquestMinOwProvincesPerGp,
        minorOwProvincesByMinorId: const {_minor1: []},
        atWarMinorIds: const [_minor1],
      );
      final snapshot = ownSnapshot(
        oldWorldProvincesOwned: kObserverConquestMinOwProvincesPerGp,
        atWarWith: const [_minor1],
        invadableProvinceIdsSorted: const ['oldWorld|future_target'],
      );
      expect(
        defaultStartFutileMinorPeaceTargets(game: game, snapshot: snapshot),
        isEmpty,
        reason:
            'Above the observer OW quota the canonical EXPAND default-start '
            'futile-minor pivot must short-circuit so the quota-met '
            'futile-peace collectors take over.',
      );
    });

    test('returns const [] strictly above the default-start +1 band', () {
      // gp_own at kObserverDefaultStartOldWorldProvincesPerGp + 2 — the
      // default-start band is exceeded but still below quota; the
      // near-quota / stalled-band collectors own the decision in that
      // shape.
      const ownOw = kObserverDefaultStartOldWorldProvincesPerGp + 2;
      final game = buildDefaultStartFutileMinorExpandPeaceGame(
        ownProvinces: ownOw,
        minorOwProvincesByMinorId: const {_minor1: []},
        atWarMinorIds: const [_minor1],
      );
      final snapshot = ownSnapshot(
        oldWorldProvincesOwned: ownOw,
        atWarWith: const [_minor1],
        invadableProvinceIdsSorted: const ['oldWorld|gp_target'],
      );
      expect(
        defaultStartFutileMinorPeaceTargets(game: game, snapshot: snapshot),
        isEmpty,
        reason:
            'Strictly above the default-start +1 band the decider must '
            'short-circuit so the near-quota / stalled-band collectors '
            'select peace targets instead.',
      );
    });

    test('returns const [] when invadableProvinceIdsSorted is empty', () {
      // gp_own at default-start size with a futile minor in atWarWith but
      // no invadable OW provinces at all — no futile-minor diagnosis is
      // possible so the decider must short-circuit.
      final game = buildDefaultStartFutileMinorExpandPeaceGame(
        ownProvinces: kObserverDefaultStartOldWorldProvincesPerGp,
        minorOwProvincesByMinorId: const {_minor1: []},
        atWarMinorIds: const [_minor1],
      );
      final snapshot = ownSnapshot(
        oldWorldProvincesOwned: kObserverDefaultStartOldWorldProvincesPerGp,
        atWarWith: const [_minor1],
        invadableProvinceIdsSorted: const [],
      );
      expect(
        defaultStartFutileMinorPeaceTargets(game: game, snapshot: snapshot),
        isEmpty,
        reason:
            'With no invadable OW the futile-minor pivot cannot be '
            'diagnosed so the decider must short-circuit.',
      );
    });
  });

  group(
    'defaultStartFutileMinorPeaceTargets — GP-only invadable frontier arm',
    () {
      test(
        'peaces every at-war minor sorted ascending when frontier is GP-only',
        () {
          // gp_own at default-start size with two at-war minors that own
          // zero OW and a GP rival owning the only invadable OW province.
          // isOldWorldGpOnlyInvadableFrontier is true (minor1, minor2 do
          // NOT own the invadable OW; only gp_rival does) so the
          // GP-only arm fires and every at-war minor is peaced. The
          // returned list must be sorted ascending by minor factionId.
          final game = buildDefaultStartFutileMinorExpandPeaceGame(
            ownProvinces: kObserverDefaultStartOldWorldProvincesPerGp,
            rivalGpProvinces: 1,
            minorOwProvincesByMinorId: const {_minor2: [], _minor1: []},
            atWarMinorIds: const [_minor1, _minor2],
          );
          final snapshot = ownSnapshot(
            oldWorldProvincesOwned: kObserverDefaultStartOldWorldProvincesPerGp,
            atWarWith: const [_minor2, _minor1],
            invadableProvinceIdsSorted: const ['oldWorld|${_gpRival}_1'],
          );
          expect(
            defaultStartFutileMinorPeaceTargets(game: game, snapshot: snapshot),
            const [_minor1, _minor2],
            reason:
                'On a GP-only invadable frontier the futile-minor pivot '
                'peaces every at-war minor (no minor pivot remains) and '
                'returns them sorted ascending by factionId.',
          );
        },
      );

      test(
        'returns const [] when no at-war minors are present on GP-only arm',
        () {
          // gp_own at default-start size on a GP-only invadable frontier
          // but with no at-war minors at all — the GP-only arm runs but
          // yields no peace targets.
          final game = buildDefaultStartFutileMinorExpandPeaceGame(
            ownProvinces: kObserverDefaultStartOldWorldProvincesPerGp,
            rivalGpProvinces: 1,
            atWarMinorIds: const [],
          );
          final snapshot = ownSnapshot(
            oldWorldProvincesOwned: kObserverDefaultStartOldWorldProvincesPerGp,
            atWarWith: const [_gpRival],
            invadableProvinceIdsSorted: const ['oldWorld|${_gpRival}_1'],
          );
          expect(
            defaultStartFutileMinorPeaceTargets(game: game, snapshot: snapshot),
            isEmpty,
            reason:
                'With no at-war minors the GP-only arm must return an '
                'empty list — at-war GPs are not in scope for this '
                'futile-minor decider.',
          );
        },
      );

      test('GP-only arm filters non-minor entries out of atWarWith', () {
        // gp_own at default-start size with both a minor and an at-war
        // GP in `atWarWith`. On the GP-only arm, only the minor
        // factionId survives the `game.minorNations.any` filter; the
        // GP must be excluded so the GP arm is not silently broadened.
        final game = buildDefaultStartFutileMinorExpandPeaceGame(
          ownProvinces: kObserverDefaultStartOldWorldProvincesPerGp,
          rivalGpProvinces: 1,
          minorOwProvincesByMinorId: const {_minor1: []},
          atWarMinorIds: const [_minor1],
        );
        final snapshot = ownSnapshot(
          oldWorldProvincesOwned: kObserverDefaultStartOldWorldProvincesPerGp,
          atWarWith: const [_minor1, _gpRival],
          invadableProvinceIdsSorted: const ['oldWorld|${_gpRival}_1'],
        );
        expect(
          defaultStartFutileMinorPeaceTargets(game: game, snapshot: snapshot),
          const [_minor1],
          reason:
              'A regression that broadened "at-war minor" to "any at-war '
              'faction" would include gp_rival here, undermining the '
              'EXPAND-phase declare-war push toward the GP blocker.',
        );
      });
    },
  );
}
