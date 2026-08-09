// Case bodies for resolvePhaseEconomyExpandBelowQuotaPeaceZeroRegimentsRebuildActive
// pins in `phase_planner_economy_filter_below_quota_peace_test.dart`.

import 'package:colonizethis_ai/colonizethis_ai.dart';
import 'package:colonizethis_ai/src/planning/colonial_phase_planner.dart';
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

import 'phase_planner_economy_filter_below_quota_peace_support.dart';

void registerPhasePlannerEconomyFilterBelowQuotaPeaceZeroRegimentsCases() {
  group(
    'resolvePhaseEconomyExpandBelowQuotaPeaceZeroRegimentsRebuildActive',
    () {
      test(
        'active under EXPAND and COLONIAL-lite when '
        'regimentCount == 0 + invadable arms hold',
        () {
          for (final phase in <ObserverGoalPhase>[
            ObserverGoalPhase.expand,
            ObserverGoalPhase.colonialLite,
          ]) {
            final outcome = PhasePlanOutcome(phase: phase);
            expect(
              resolvePhaseEconomyExpandBelowQuotaPeaceZeroRegimentsRebuildActive(
                phasePlan: outcome,
                regimentCount: 0,
                hasInvadableProvinces: true,
              ),
              isTrue,
              reason:
                  '$phase: zero regiments + invadable inputs must '
                  'route the EXPAND zero-regiment rebuild arm '
                  'identically to the legacy helper.',
            );
          }
        },
      );

      test(
        'suppressed under COLONIAL and DEVELOP even when '
        'regimentCount == 0 + invadable arms hold',
        () {
          for (final phase in <ObserverGoalPhase>[
            ObserverGoalPhase.colonial,
            ObserverGoalPhase.develop,
          ]) {
            final outcome = PhasePlanOutcome(phase: phase);
            expect(
              resolvePhaseEconomyExpandBelowQuotaPeaceZeroRegimentsRebuildActive(
                phasePlan: outcome,
                regimentCount: 0,
                hasInvadableProvinces: true,
              ),
              isFalse,
              reason:
                  '$phase: zero-regiment rebuild arm must not leak '
                  'into COLONIAL or DEVELOP — at or above quota the '
                  'trap does not apply.',
            );
          }
        },
      );

      test(
        'suppressed when regimentCount > 0 (legacy parity)',
        () {
          const outcome = PhasePlanOutcome(phase: ObserverGoalPhase.expand);
          expect(
            resolvePhaseEconomyExpandBelowQuotaPeaceZeroRegimentsRebuildActive(
              phasePlan: outcome,
              regimentCount: 1,
              hasInvadableProvinces: true,
            ),
            isFalse,
            reason:
                'Legacy isBelowQuotaPeaceZeroRegimentsRebuild requires '
                'regimentCount == 0; one is the insufficient-regiment '
                'arm of the rebuild trap, not the zero-regiment arm.',
          );
        },
      );

      test(
        'suppressed when no invadable provinces (legacy parity)',
        () {
          const outcome = PhasePlanOutcome(phase: ObserverGoalPhase.expand);
          expect(
            resolvePhaseEconomyExpandBelowQuotaPeaceZeroRegimentsRebuildActive(
              phasePlan: outcome,
              regimentCount: 0,
              hasInvadableProvinces: false,
            ),
            isFalse,
            reason:
                'Legacy isBelowQuotaPeaceZeroRegimentsRebuild requires '
                'hasInvadableProvinces; an empty invadable frontier '
                'short-circuits the trap.',
          );
        },
      );

      test(
        'reads only the documented inputs — populated sibling slots on '
        'PhasePlanOutcome do not flip the resolver',
        () {
          for (final phase in <ObserverGoalPhase>[
            ObserverGoalPhase.colonial,
            ObserverGoalPhase.develop,
          ]) {
            final outcome = PhasePlanOutcome(
              phase: phase,
              colonialAcquisitionTarget:
                  belowQuotaPeaceColonialAcquisitionPopulated,
              colonialPeaceTargetFactionIdsSorted: const <String>['gp2'],
              colonialMilitaryPlan: belowQuotaPeaceColonialMilitaryPopulated,
              colonialNavalPlan: belowQuotaPeaceColonialNavalPopulated,
              colonialCivilianWorkOrders: belowQuotaPeaceColonialCivilianPopulated,
            );
            expect(
              resolvePhaseEconomyExpandBelowQuotaPeaceZeroRegimentsRebuildActive(
                phasePlan: outcome,
                regimentCount: 0,
                hasInvadableProvinces: true,
              ),
              isFalse,
              reason:
                  '$phase: populated COLONIAL slots must not flip the '
                  'zero-regiment rebuild resolver — only outcome.phase '
                  'and the per-turn inputs decide.',
            );
          }
        },
      );

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
          // Mirrors the EXPAND parity test for the
          // insufficient-regiments resolver. EXPAND phase entry
          // structurally satisfies the legacy
          // `isBelowObserverConquestQuota(ow)` guard, so every
          // reachable `(ow ∈ [0, quota - 1], regimentCount ∈
          // {0, 1, 5}, hasInvadableProvinces ∈ {true, false})`
          // combination must agree between phase-derived and legacy.
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
          // The legacy `isBelowQuotaPeaceZeroRegimentsRebuild` arm is
          // strictly `regimentCount == 0`; the legacy
          // `isBelowQuotaPeaceInsufficientRegiments` arm is strictly
          // `0 < regimentCount < threshold`. The two arms cannot both
          // be true for any single per-turn input. Pin that invariant
          // on the phase-derived path so a future merge that
          // accidentally broadened either resolver would flip this red.
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
