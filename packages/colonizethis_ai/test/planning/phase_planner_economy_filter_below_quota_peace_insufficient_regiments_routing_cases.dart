// Active/suppression routing cases for
// resolvePhaseEconomyExpandBelowQuotaPeaceInsufficientRegimentsActive pins.

import 'package:colonizethis_ai/colonizethis_ai.dart';
import 'package:colonizethis_ai/src/planning/phase_planner_economy_filter.dart';
import 'package:colonizethis_data/colonizethis_data.dart'
    show kBelowQuotaPeaceMinRegimentsBeforeDeclareWar;
import 'package:colonizethis_test/test.dart';

import 'phase_planner_economy_filter_below_quota_peace_support.dart';

void registerPhasePlannerEconomyFilterBelowQuotaPeaceInsufficientRegimentsRoutingCases() {
  group(
    'resolvePhaseEconomyExpandBelowQuotaPeaceInsufficientRegimentsActive routing',
    () {
      test(
        'active under EXPAND and COLONIAL-lite when peace + small-regiment '
        '+ invadable arms hold',
        () {
          for (final phase in <ObserverGoalPhase>[
            ObserverGoalPhase.expand,
            ObserverGoalPhase.colonialLite,
          ]) {
            final outcome = PhasePlanOutcome(phase: phase);
            expect(
              resolvePhaseEconomyExpandBelowQuotaPeaceInsufficientRegimentsActive(
                phasePlan: outcome,
                regimentCount:
                    kBelowQuotaPeaceMinRegimentsBeforeDeclareWar - 1,
                atWarWithAnyGreatPower: false,
                hasInvadableProvinces: true,
              ),
              isTrue,
              reason:
                  '$phase: peace + small-regiment + invadable inputs '
                  'must route the EXPAND regiment-rebuild trap arm '
                  'identically to the legacy helper.',
            );
          }
        },
      );

      test(
        'suppressed under COLONIAL and DEVELOP even when peace + '
        'small-regiment + invadable arms hold',
        () {
          for (final phase in <ObserverGoalPhase>[
            ObserverGoalPhase.colonial,
            ObserverGoalPhase.develop,
          ]) {
            final outcome = PhasePlanOutcome(phase: phase);
            expect(
              resolvePhaseEconomyExpandBelowQuotaPeaceInsufficientRegimentsActive(
                phasePlan: outcome,
                regimentCount:
                    kBelowQuotaPeaceMinRegimentsBeforeDeclareWar - 1,
                atWarWithAnyGreatPower: false,
                hasInvadableProvinces: true,
              ),
              isFalse,
              reason:
                  '$phase: the EXPAND rebuild-trap arm must not leak '
                  'into COLONIAL or DEVELOP — at or above quota the '
                  'trap does not apply.',
            );
          }
        },
      );

      test(
        'suppressed when at war with any Great Power (legacy parity)',
        () {
          const outcome = PhasePlanOutcome(phase: ObserverGoalPhase.expand);
          expect(
            resolvePhaseEconomyExpandBelowQuotaPeaceInsufficientRegimentsActive(
              phasePlan: outcome,
              regimentCount: kBelowQuotaPeaceMinRegimentsBeforeDeclareWar - 1,
              atWarWithAnyGreatPower: true,
              hasInvadableProvinces: true,
            ),
            isFalse,
            reason:
                'Legacy isBelowQuotaPeaceInsufficientRegiments suppresses '
                'when atWarWithAnyGreatPower is true (the trap is a '
                '*peace* trap); the resolver must preserve that.',
          );
        },
      );

      test(
        'suppressed when regimentCount == 0 (legacy parity — zero-regiment '
        'arm belongs to the *zero* rebuild resolver, not this one)',
        () {
          const outcome = PhasePlanOutcome(phase: ObserverGoalPhase.expand);
          expect(
            resolvePhaseEconomyExpandBelowQuotaPeaceInsufficientRegimentsActive(
              phasePlan: outcome,
              regimentCount: 0,
              atWarWithAnyGreatPower: false,
              hasInvadableProvinces: true,
            ),
            isFalse,
            reason:
                'Legacy isBelowQuotaPeaceInsufficientRegiments requires '
                'regimentCount > 0; zero is the zero-regiments arm.',
          );
        },
      );

      test(
        'suppressed when regimentCount >= kBelowQuotaPeaceMin... '
        '(legacy parity — at or above the declare-war threshold)',
        () {
          const outcome = PhasePlanOutcome(phase: ObserverGoalPhase.expand);
          expect(
            resolvePhaseEconomyExpandBelowQuotaPeaceInsufficientRegimentsActive(
              phasePlan: outcome,
              regimentCount: kBelowQuotaPeaceMinRegimentsBeforeDeclareWar,
              atWarWithAnyGreatPower: false,
              hasInvadableProvinces: true,
            ),
            isFalse,
            reason:
                'Legacy isBelowQuotaPeaceInsufficientRegiments excludes '
                'regimentCount >= kBelowQuotaPeaceMin... — the GP can '
                'already mount a credible declare-war.',
          );
        },
      );

      test(
        'suppressed when no invadable provinces (legacy parity — without an '
        'OW frontier to invade, rebuilding regiments is not the right gate)',
        () {
          const outcome = PhasePlanOutcome(phase: ObserverGoalPhase.expand);
          expect(
            resolvePhaseEconomyExpandBelowQuotaPeaceInsufficientRegimentsActive(
              phasePlan: outcome,
              regimentCount: kBelowQuotaPeaceMinRegimentsBeforeDeclareWar - 1,
              atWarWithAnyGreatPower: false,
              hasInvadableProvinces: false,
            ),
            isFalse,
            reason:
                'Legacy isBelowQuotaPeaceInsufficientRegiments requires '
                'hasInvadableProvinces; an empty invadable frontier short-'
                'circuits the trap.',
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
              developPeaceTargetFactionIdsSorted: const <String>['gp3'],
            );
            expect(
              resolvePhaseEconomyExpandBelowQuotaPeaceInsufficientRegimentsActive(
                phasePlan: outcome,
                regimentCount:
                    kBelowQuotaPeaceMinRegimentsBeforeDeclareWar - 1,
                atWarWithAnyGreatPower: false,
                hasInvadableProvinces: true,
              ),
              isFalse,
              reason:
                  '$phase: populated COLONIAL / DEVELOP slots must not '
                  'flip the EXPAND rebuild-trap resolver — only '
                  'outcome.phase and the per-turn inputs decide.',
            );
          }
        },
      );
    },
  );
}
