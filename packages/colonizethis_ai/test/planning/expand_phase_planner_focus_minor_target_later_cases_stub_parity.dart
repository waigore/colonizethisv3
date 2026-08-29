// Topic-split cases from `expand_phase_planner_focus_minor_target_later_cases` (Refs #4669 Slice B).
import 'package:colonizethis_ai/src/perception/perception_snapshot.dart';
import 'package:colonizethis_ai/src/planning/expand_phase_planner.dart'
    as diplomacy_planner_peace_targets;
import 'package:colonizethis_ai/src/planning/expand_phase_planner.dart';
import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';
import '../support/expand_phase_peace_test_support.dart';

import '../support/expand_phase_planner_focus_minor_target_test_support.dart';

void registerExpandPhasePlannerFocusMinorTargetLaterStubParityCases() {
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
                    kFocusMinorMinorAlpha: [
                      'oldWorld|alpha_1',
                      'oldWorld|alpha_2',
                    ],
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
