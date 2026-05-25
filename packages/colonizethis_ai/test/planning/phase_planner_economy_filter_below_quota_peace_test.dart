// Unit tests for the EXPAND below-quota peace rebuild-trap resolvers
// in `phase_planner_economy_filter.dart` (Refs #2509 S5 — split out of
// `phase_planner_economy_filter_test.dart` to keep both files under the
// repo-lint `dart_file_non_comment_line_size` 1000-line cap; see
// `SPEC/program/repo-lint.md` § Dart files must stay at or below 1000
// non-comment lines).
//
// Pins the structural contract of
// `resolvePhaseEconomyExpandBelowQuotaPeaceInsufficientRegimentsActive`
// and `resolvePhaseEconomyExpandBelowQuotaPeaceZeroRegimentsRebuildActive`:
//
//   - Returns `true` only when phase ∈ {EXPAND, COLONIAL-lite} AND the
//     legacy `isBelowQuotaPeace*` arms hold for the per-turn inputs.
//   - Returns `false` under COLONIAL and DEVELOP regardless of
//     per-turn inputs (structural — at or above quota the rebuild
//     trap does not apply).
//   - Field-equal to the legacy `colonial_pressure.dart` helpers
//     under EXPAND / COLONIAL-lite where
//     `isBelowObserverConquestQuota(ow)` is already satisfied
//     structurally by the phase-entry guard.
//   - Reads only the documented inputs — sibling slots on
//     [PhasePlanOutcome] (COLONIAL acquisition, DEVELOP civilian
//     work, EXPAND frontier, ...) have no effect.
//   - Pure and deterministic across repeated calls (Refs #2509
//     Must-have #7).
//
// These resolvers replace the orchestrator's last two direct calls
// into `colonial_pressure.dart` from `_appendEconomyBuildOrders`
// (`expandQuotaPressure && isBelowQuotaPeaceInsufficientRegiments`
// and `expandQuotaPressure && isBelowQuotaPeaceZeroRegimentsRebuild`)
// and let the orchestrator drop the `colonial_pressure.dart` import
// entirely. Legacy parity tests below pin the field-equal contract
// across the matrix the legacy helpers actually answered for the
// orchestrator (the `isBelowObserverConquestQuota` first guard
// collapses into the phase gate because EXPAND / COLONIAL-lite phase
// entry requires `ow < kObserverConquestMinOwProvincesPerGp` by
// `observerGoalPhaseFor`).

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
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';

// Non-default content for the "structural exclusion ignores sibling
// slots" guards in both groups. The resolvers must read only
// `outcome.phase` (and their documented per-turn inputs), so populated
// COLONIAL slots under EXPAND / COLONIAL-lite / DEVELOP must still
// resolve to `false`. Duplicated from
// `phase_planner_economy_filter_test.dart` because the constants are
// file-private; keeping the test file self-contained avoids exposing
// fixture symbols through a shared library just for two test files.
const ColonialAcquisitionTarget _colonialAcquisitionPopulated =
    ColonialAcquisitionTarget(
      targetFactionId: 'tribe1',
      method: AcquisitionMethod.declareWar,
    );

const ColonialMilitaryPlan _colonialMilitaryPopulated = ColonialMilitaryPlan(
  priorityDestinationProvinceIdsSorted: <String>['newWorld|tribe1_a'],
  priorityTargetOwnerFactionIdsSorted: <String>['tribe1'],
);

const ColonialNavalPlan _colonialNavalPopulated = ColonialNavalPlan(
  priorityInvasionTransportProvinceIdsSorted: <String>['newWorld|tribe1_a'],
  priorityTargetOwnerFactionIdsSorted: <String>['tribe1'],
);

const List<WorkOrder> _colonialCivilianPopulated = <WorkOrder>[
  WorkOrder(
    unitId: 'm1',
    target: 'purchase_land',
    targetTileKey: 'newWorld|tribe1_a|0|0',
  ),
];

void main() {
  group(
    'resolvePhaseEconomyExpandBelowQuotaPeaceInsufficientRegimentsActive',
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
          // Pins the resolver against a hypothetical regression that
          // started leaking COLONIAL / DEVELOP slot content into the
          // EXPAND rebuild-trap routing. With every COLONIAL and DEVELOP
          // slot populated under a non-EXPAND/COLONIAL-lite phase,
          // the resolver must still return `false`.
          for (final phase in <ObserverGoalPhase>[
            ObserverGoalPhase.colonial,
            ObserverGoalPhase.develop,
          ]) {
            final outcome = PhasePlanOutcome(
              phase: phase,
              colonialAcquisitionTarget: _colonialAcquisitionPopulated,
              colonialPeaceTargetFactionIdsSorted: const <String>['gp2'],
              colonialMilitaryPlan: _colonialMilitaryPopulated,
              colonialNavalPlan: _colonialNavalPopulated,
              colonialCivilianWorkOrders: _colonialCivilianPopulated,
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
          // The orchestrator's prior code was
          //   expandQuotaPressure && isBelowQuotaPeace*(ow, ...)
          // EXPAND phase entry guarantees ow < quota
          // (`observerGoalPhaseFor` via
          // `kObserverConquestMinOwProvincesPerGp`). Iterate every
          // reachable `(ow ∈ [0, quota - 1], regimentCount ∈
          // {0, 1, threshold - 1, threshold, threshold + 1},
          // atWarWithAnyGreatPower ∈ {true, false},
          // hasInvadableProvinces ∈ {true, false})` combination and
          // pin field-equality against the legacy helper. The phase
          // gate is fixed to EXPAND here; the COLONIAL / DEVELOP cases
          // are covered by the suppression test above.
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
              colonialAcquisitionTarget: _colonialAcquisitionPopulated,
              colonialPeaceTargetFactionIdsSorted: const <String>['gp2'],
              colonialMilitaryPlan: _colonialMilitaryPopulated,
              colonialNavalPlan: _colonialNavalPopulated,
              colonialCivilianWorkOrders: _colonialCivilianPopulated,
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
