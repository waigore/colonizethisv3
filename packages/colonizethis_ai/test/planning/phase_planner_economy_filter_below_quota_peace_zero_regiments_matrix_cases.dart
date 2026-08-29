// Matrix parity case bodies for
// `phase_planner_economy_filter_below_quota_peace_zero_regiments_cases.dart`.

import 'package:colonizethis_ai/colonizethis_ai.dart';
import 'package:colonizethis_ai/src/planning/phase_planner_economy_filter.dart';
import 'package:colonizethis_ai/src/planning/expand_phase_planner.dart'
    show
        isBelowQuotaPeaceInsufficientRegiments,
        isBelowQuotaPeaceZeroRegimentsRebuild;
import 'package:colonizethis_data/colonizethis_data.dart'
    show
        kBelowQuotaPeaceMinRegimentsBeforeDeclareWar,
        kObserverConquestMinOwProvincesPerGp;
import 'package:colonizethis_test/test.dart';

void registerPhasePlannerEconomyFilterBelowQuotaPeaceZeroRegimentsMatrixCases() {
  group(
    'resolvePhaseEconomyExpandBelowQuotaPeaceZeroRegimentsRebuildActive',
    () {
      test(
        'deterministic across repeated calls (Must-have #7)',
        () {
          for (final phase in ObserverGoalPhase.values) {
            final outcome = PhasePlanOutcome(phase: phase);
            final a =
                resolvePhaseEconomyExpandBelowQuotaPeaceZeroRegimentsRebuildActive(
              phasePlan: outcome,
              regimentCount: 0,
              hasInvadableProvinces: true,
            );
            final b =
                resolvePhaseEconomyExpandBelowQuotaPeaceZeroRegimentsRebuildActive(
              phasePlan: outcome,
              regimentCount: 0,
              hasInvadableProvinces: true,
            );
            final c =
                resolvePhaseEconomyExpandBelowQuotaPeaceZeroRegimentsRebuildActive(
              phasePlan: outcome,
              regimentCount: 0,
              hasInvadableProvinces: true,
            );
            expect(a, b, reason: '$phase: two-call determinism');
            expect(b, c, reason: '$phase: three-call determinism');
          }
        },
      );

      test(
        'field-equal to legacy isBelowQuotaPeaceZeroRegimentsRebuild '
        'under EXPAND across the per-turn input matrix the orchestrator '
        'can actually observe',
        () {
          const phase = ObserverGoalPhase.expand;
          final outcome = PhasePlanOutcome(phase: phase);
          for (var ow = 0;
              ow < kObserverConquestMinOwProvincesPerGp;
              ow++) {
            for (final regimentCount in <int>[0, 1, 5]) {
              for (final hasInvadable in <bool>[false, true]) {
                final phaseDerived =
                    resolvePhaseEconomyExpandBelowQuotaPeaceZeroRegimentsRebuildActive(
                  phasePlan: outcome,
                  regimentCount: regimentCount,
                  hasInvadableProvinces: hasInvadable,
                );
                final legacy = isBelowQuotaPeaceZeroRegimentsRebuild(
                  oldWorldProvincesOwned: ow,
                  regimentCount: regimentCount,
                  hasInvadableProvinces: hasInvadable,
                );
                expect(
                  phaseDerived,
                  legacy,
                  reason:
                      'EXPAND ow=$ow regimentCount=$regimentCount '
                      'hasInvadable=$hasInvadable: phase-derived '
                      'resolver and legacy helper must agree.',
                );
              }
            }
          }
        },
      );

      test(
        'mutually exclusive with the insufficient-regiments resolver '
        'across the EXPAND-reachable input matrix (the legacy helpers '
        'partition regimentCount == 0 vs 0 < regimentCount < threshold)',
        () {
          const phase = ObserverGoalPhase.expand;
          final outcome = PhasePlanOutcome(phase: phase);
          for (final regimentCount in <int>[
            0,
            1,
            kBelowQuotaPeaceMinRegimentsBeforeDeclareWar - 1,
            kBelowQuotaPeaceMinRegimentsBeforeDeclareWar,
          ]) {
            for (final atWar in <bool>[false, true]) {
              for (final hasInvadable in <bool>[false, true]) {
                final zero =
                    resolvePhaseEconomyExpandBelowQuotaPeaceZeroRegimentsRebuildActive(
                  phasePlan: outcome,
                  regimentCount: regimentCount,
                  hasInvadableProvinces: hasInvadable,
                );
                final insufficient =
                    resolvePhaseEconomyExpandBelowQuotaPeaceInsufficientRegimentsActive(
                  phasePlan: outcome,
                  regimentCount: regimentCount,
                  atWarWithAnyGreatPower: atWar,
                  hasInvadableProvinces: hasInvadable,
                );
                expect(
                  zero && insufficient,
                  isFalse,
                  reason:
                      'regimentCount=$regimentCount atWar=$atWar '
                      'hasInvadable=$hasInvadable: the two EXPAND '
                      'rebuild-trap arms must never both fire — the '
                      'legacy partition is strict on '
                      'regimentCount ∈ {0} vs (0, threshold).',
                );
              }
            }
          }
        },
      );
    },
  );
}
