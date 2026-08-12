// Case bodies (later) for expand_phase_planner_focus_minor_target_test (Refs #3997 Phase 8).
// Pins canonical homes for stalledFocusMinorTarget /
// belowQuotaActiveMinorWarTarget (Refs #2509 S1).

import 'package:colonizethis_ai/src/perception/perception_snapshot.dart';
import 'package:colonizethis_ai/src/planning/expand_phase_planner.dart'
    as diplomacy_planner_peace_targets;
import 'package:colonizethis_ai/src/planning/expand_phase_planner.dart';
import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';
import '../support/expand_phase_peace_test_support.dart';

import '../support/expand_phase_planner_focus_minor_target_test_support.dart';

void registerExpandPhasePlannerFocusMinorTargetLaterCases() {
  group('belowQuotaActiveMinorWarTarget — fire path', () {
    test(
      'returns the focused minor below quota (delegates to stalledFocusMinorTarget)',
      () {
        // ownOw < quota → outer guard passes → result mirrors
        // stalledFocusMinorTarget exactly.
        final game = expandPhasePlannerFocusMinorTargetGame(
          ownProvinces: kObserverConquestMinOwProvincesPerGp - 2,
          minorOwnedInvadables: const {
            kFocusMinorMinorAlpha: ['oldWorld|alpha_1', 'oldWorld|alpha_2'],
            kFocusMinorMinorBeta: ['oldWorld|beta_1'],
          },
          atWarMinors: const [kFocusMinorMinorAlpha, kFocusMinorMinorBeta],
        );
        final snapshot = ownSnapshot(
          oldWorldProvincesOwned: kObserverConquestMinOwProvincesPerGp - 2,
          atWarWith: const [kFocusMinorMinorAlpha, kFocusMinorMinorBeta],
          invadableProvinceIdsSorted: const [
            'oldWorld|alpha_1',
            'oldWorld|alpha_2',
            'oldWorld|beta_1',
          ],
        );
        expect(
          belowQuotaActiveMinorWarTarget(game: game, snapshot: snapshot),
          kFocusMinorMinorAlpha,
          reason:
              'Below quota → outer guard passes → result mirrors '
              'stalledFocusMinorTarget which prefers minor_alpha (2 '
              'invadable provinces vs minor_beta\'s 1).',
        );
      },
    );

    test('returns null below quota when focused-minor scan finds nothing', () {
      // Below quota but no at-war minor owns an invadable province →
      // stalledFocusMinorTarget returns null → the wrapper passes
      // that null through unchanged.
      final game = expandPhasePlannerFocusMinorTargetGame(
        ownProvinces: kObserverConquestMinOwProvincesPerGp - 2,
        minorOwnedInvadables: const {
          kFocusMinorMinorAlpha: ['oldWorld|alpha_home'],
        },
        atWarMinors: const [kFocusMinorMinorAlpha],
      );
      final snapshot = ownSnapshot(
        oldWorldProvincesOwned: kObserverConquestMinOwProvincesPerGp - 2,
        atWarWith: const [kFocusMinorMinorAlpha],
        invadableProvinceIdsSorted: const [],
      );
      expect(
        belowQuotaActiveMinorWarTarget(game: game, snapshot: snapshot),
        isNull,
        reason:
            'Below quota but the inner focused-minor scan finds no '
            'candidate (empty invadable list) → the wrapper must '
            'return null instead of inventing a target.',
      );
    });
  });

  group('Determinism (Must-have #7)', () {
    test('stalledFocusMinorTarget returns identical results on repeat', () {
      final game = expandPhasePlannerFocusMinorTargetGame(
        ownProvinces: 7,
        minorOwnedInvadables: const {
          kFocusMinorMinorAlpha: ['oldWorld|alpha_1'],
          kFocusMinorMinorBeta: ['oldWorld|beta_1', 'oldWorld|beta_2'],
        },
        atWarMinors: const [kFocusMinorMinorAlpha, kFocusMinorMinorBeta],
      );
      final snapshot = ownSnapshot(
        oldWorldProvincesOwned: 7,
        atWarWith: const [kFocusMinorMinorAlpha, kFocusMinorMinorBeta],
        invadableProvinceIdsSorted: const [
          'oldWorld|alpha_1',
          'oldWorld|beta_1',
          'oldWorld|beta_2',
        ],
      );
      final first = stalledFocusMinorTarget(game: game, snapshot: snapshot);
      final second = stalledFocusMinorTarget(game: game, snapshot: snapshot);
      expect(first, equals(second));
      expect(first, kFocusMinorMinorBeta);
    });

    test(
      'belowQuotaActiveMinorWarTarget returns identical results on repeat',
      () {
        final game = expandPhasePlannerFocusMinorTargetGame(
          ownProvinces: kObserverConquestMinOwProvincesPerGp - 2,
          minorOwnedInvadables: const {
            kFocusMinorMinorAlpha: ['oldWorld|alpha_1', 'oldWorld|alpha_2'],
          },
          atWarMinors: const [kFocusMinorMinorAlpha],
        );
        final snapshot = ownSnapshot(
          oldWorldProvincesOwned: kObserverConquestMinOwProvincesPerGp - 2,
          atWarWith: const [kFocusMinorMinorAlpha],
          invadableProvinceIdsSorted: const [
            'oldWorld|alpha_1',
            'oldWorld|alpha_2',
          ],
        );
        final first = belowQuotaActiveMinorWarTarget(
          game: game,
          snapshot: snapshot,
        );
        final second = belowQuotaActiveMinorWarTarget(
          game: game,
          snapshot: snapshot,
        );
        expect(first, equals(second));
        expect(first, kFocusMinorMinorAlpha);
      },
    );
  });

  group('Stub delegation parity', () {
    test('stalledFocusMinorTarget stub mirrors canonical across fixtures', () {
      final fixtures = <({Game game, AIWorldSnapshot snapshot, String label})>[
        (
          label: 'no at-war minor',
          game: expandPhasePlannerFocusMinorTargetGame(
            ownProvinces: 7,
            minorOwnedInvadables: const {
              kFocusMinorMinorAlpha: ['oldWorld|alpha_1'],
            },
            peacefulMinors: const [kFocusMinorMinorAlpha],
            atWarTribes: const [kFocusMinorTribeOne],
          ),
          snapshot: ownSnapshot(
            oldWorldProvincesOwned: 7,
            atWarWith: const [kFocusMinorTribeOne],
            invadableProvinceIdsSorted: const ['oldWorld|alpha_1'],
          ),
        ),
        (
          label: 'fire path with strict-greater winner',
          game: expandPhasePlannerFocusMinorTargetGame(
            ownProvinces: 7,
            minorOwnedInvadables: const {
              kFocusMinorMinorAlpha: ['oldWorld|alpha_1'],
              kFocusMinorMinorBeta: ['oldWorld|beta_1', 'oldWorld|beta_2'],
            },
            atWarMinors: const [kFocusMinorMinorAlpha, kFocusMinorMinorBeta],
          ),
          snapshot: ownSnapshot(
            oldWorldProvincesOwned: 7,
            atWarWith: const [kFocusMinorMinorAlpha, kFocusMinorMinorBeta],
            invadableProvinceIdsSorted: const [
              'oldWorld|alpha_1',
              'oldWorld|beta_1',
              'oldWorld|beta_2',
            ],
          ),
        ),
        (
          label: 'tie preserves iteration order',
          game: expandPhasePlannerFocusMinorTargetGame(
            ownProvinces: 7,
            minorOwnedInvadables: const {
              kFocusMinorMinorAlpha: ['oldWorld|alpha_1'],
              kFocusMinorMinorGamma: ['oldWorld|gamma_1'],
            },
            atWarMinors: const [kFocusMinorMinorAlpha, kFocusMinorMinorGamma],
          ),
          snapshot: ownSnapshot(
            oldWorldProvincesOwned: 7,
            atWarWith: const [kFocusMinorMinorAlpha, kFocusMinorMinorGamma],
            invadableProvinceIdsSorted: const [
              'oldWorld|alpha_1',
              'oldWorld|gamma_1',
            ],
          ),
        ),
      ];
      for (final fixture in fixtures) {
        final canonical = stalledFocusMinorTarget(
          game: fixture.game,
          snapshot: fixture.snapshot,
        );
        final stub = diplomacy_planner_peace_targets.stalledFocusMinorTarget(
          game: fixture.game,
          snapshot: fixture.snapshot,
        );
        expect(
          stub,
          equals(canonical),
          reason:
              'Stub-canonical parity broken for fixture '
              '"${fixture.label}". The legacy '
              'stalledExpansionDistractionPeaceTargets and '
              'belowQuotaMultiMinorDistractionPeaceTargets consumers '
              'depend on this parity until the now-completed S1 deletion.',
        );
      }
    });

    test(
      'belowQuotaActiveMinorWarTarget stub mirrors canonical across fixtures',
      () {
        final fixtures =
            <({Game game, AIWorldSnapshot snapshot, String label})>[
              (
                label: 'outer guard at quota',
                game: expandPhasePlannerFocusMinorTargetGame(
                  ownProvinces: kObserverConquestMinOwProvincesPerGp,
                  minorOwnedInvadables: const {
                    kFocusMinorMinorAlpha: ['oldWorld|alpha_1'],
                  },
                  atWarMinors: const [kFocusMinorMinorAlpha],
                ),
                snapshot: ownSnapshot(
                  oldWorldProvincesOwned: kObserverConquestMinOwProvincesPerGp,
                  atWarWith: const [kFocusMinorMinorAlpha],
                  invadableProvinceIdsSorted: const ['oldWorld|alpha_1'],
                ),
              ),
              (
                label: 'fire path below quota',
                game: expandPhasePlannerFocusMinorTargetGame(
                  ownProvinces: kObserverConquestMinOwProvincesPerGp - 2,
                  minorOwnedInvadables: const {
                    kFocusMinorMinorAlpha: ['oldWorld|alpha_1', 'oldWorld|alpha_2'],
                  },
                  atWarMinors: const [kFocusMinorMinorAlpha],
                ),
                snapshot: ownSnapshot(
                  oldWorldProvincesOwned:
                      kObserverConquestMinOwProvincesPerGp - 2,
                  atWarWith: const [kFocusMinorMinorAlpha],
                  invadableProvinceIdsSorted: const [
                    'oldWorld|alpha_1',
                    'oldWorld|alpha_2',
                  ],
                ),
              ),
              (
                label: 'below quota with no focused minor',
                game: expandPhasePlannerFocusMinorTargetGame(
                  ownProvinces: kObserverConquestMinOwProvincesPerGp - 2,
                  minorOwnedInvadables: const {
                    kFocusMinorMinorAlpha: ['oldWorld|alpha_home'],
                  },
                  atWarMinors: const [kFocusMinorMinorAlpha],
                ),
                snapshot: ownSnapshot(
                  oldWorldProvincesOwned:
                      kObserverConquestMinOwProvincesPerGp - 2,
                  atWarWith: const [kFocusMinorMinorAlpha],
                  invadableProvinceIdsSorted: const [],
                ),
              ),
            ];
        for (final fixture in fixtures) {
          final canonical = belowQuotaActiveMinorWarTarget(
            game: fixture.game,
            snapshot: fixture.snapshot,
          );
          final stub = diplomacy_planner_peace_targets
              .belowQuotaActiveMinorWarTarget(
                game: fixture.game,
                snapshot: fixture.snapshot,
              );
          expect(
            stub,
            equals(canonical),
            reason:
                'Stub-canonical parity broken for fixture '
                '"${fixture.label}". The diplomatic-candidate-scoring '
                'below-quota minor-front-hold consumer depends on '
                'this parity until the now-completed S1 deletion.',
          );
        }
      },
    );
  });
}
