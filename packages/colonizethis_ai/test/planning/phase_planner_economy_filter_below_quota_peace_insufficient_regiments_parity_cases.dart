// Determinism and legacy-parity matrix cases for
// resolvePhaseEconomyExpandBelowQuotaPeaceInsufficientRegimentsActive pins.

import 'package:colonizethis_ai/colonizethis_ai.dart';
import 'package:colonizethis_ai/src/planning/phase_planner_economy_filter.dart';
import 'package:colonizethis_ai/src/planning/expand_phase_planner.dart'
    show isBelowQuotaPeaceInsufficientRegiments;
import 'package:colonizethis_data/colonizethis_data.dart'
    show
        kBelowQuotaPeaceMinRegimentsBeforeDeclareWar,
        kObserverConquestMinOwProvincesPerGp;
import 'package:colonizethis_test/test.dart';

void registerPhasePlannerEconomyFilterBelowQuotaPeaceInsufficientRegimentsParityCases() {
  group(
    'resolvePhaseEconomyExpandBelowQuotaPeaceInsufficientRegimentsActive parity',
    () {
      test(
        'deterministic across repeated calls (Must-have #7)',
        () {
          for (final phase in ObserverGoalPhase.values) {
            final outcome = PhasePlanOutcome(phase: phase);
            final a =
                resolvePhaseEconomyExpandBelowQuotaPeaceInsufficientRegimentsActive(
              phasePlan: outcome,
              regimentCount: 1,
              atWarWithAnyGreatPower: false,
              hasInvadableProvinces: true,
            );
            final b =
                resolvePhaseEconomyExpandBelowQuotaPeaceInsufficientRegimentsActive(
              phasePlan: outcome,
              regimentCount: 1,
              atWarWithAnyGreatPower: false,
              hasInvadableProvinces: true,
            );
            final c =
                resolvePhaseEconomyExpandBelowQuotaPeaceInsufficientRegimentsActive(
              phasePlan: outcome,
              regimentCount: 1,
              atWarWithAnyGreatPower: false,
              hasInvadableProvinces: true,
            );
            expect(a, b, reason: '$phase: two-call determinism');
            expect(b, c, reason: '$phase: three-call determinism');
          }
        },
      );

      test(
        'field-equal to legacy isBelowQuotaPeaceInsufficientRegiments under '
        'EXPAND across the per-turn input matrix the orchestrator can '
        'actually observe (OW < quota, gated by phase)',
        () {
          const phase = ObserverGoalPhase.expand;
          final outcome = PhasePlanOutcome(phase: phase);
          for (var ow = 0;
              ow < kObserverConquestMinOwProvincesPerGp;
              ow++) {
            for (final regimentCount in <int>[
              0,
              1,
              kBelowQuotaPeaceMinRegimentsBeforeDeclareWar - 1,
              kBelowQuotaPeaceMinRegimentsBeforeDeclareWar,
              kBelowQuotaPeaceMinRegimentsBeforeDeclareWar + 1,
            ]) {
              for (final atWar in <bool>[false, true]) {
                for (final hasInvadable in <bool>[false, true]) {
                  final phaseDerived =
                      resolvePhaseEconomyExpandBelowQuotaPeaceInsufficientRegimentsActive(
                    phasePlan: outcome,
                    regimentCount: regimentCount,
                    atWarWithAnyGreatPower: atWar,
                    hasInvadableProvinces: hasInvadable,
                  );
                  final legacy = isBelowQuotaPeaceInsufficientRegiments(
                    oldWorldProvincesOwned: ow,
                    regimentCount: regimentCount,
                    atWarWithAnyGreatPower: atWar,
                    hasInvadableProvinces: hasInvadable,
                  );
                  expect(
                    phaseDerived,
                    legacy,
                    reason:
                        'EXPAND ow=$ow regimentCount=$regimentCount '
                        'atWar=$atWar hasInvadable=$hasInvadable: '
                        'phase-derived resolver and legacy helper '
                        'must agree across the orchestrator-reachable '
                        'input matrix.',
                  );
                }
              }
            }
          }
        },
      );
    },
  );
}
