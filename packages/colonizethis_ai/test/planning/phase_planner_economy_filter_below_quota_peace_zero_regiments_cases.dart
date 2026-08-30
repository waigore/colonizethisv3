// Case bodies for resolvePhaseEconomyExpandBelowQuotaPeaceZeroRegimentsRebuildActive
// pins in `phase_planner_economy_filter_below_quota_peace_test.dart`.

import 'package:colonizethis_ai/colonizethis_ai.dart';
import 'package:colonizethis_ai/src/planning/phase_planner_economy_filter.dart';
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
    },
  );
}
