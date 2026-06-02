// Unit tests for `phase_planner_economy_filter.dart`
// (Refs #2509 S5 — companion to `phase_planner_conquest_wiring_test.dart`
// for the conquest-side `resolvePhaseConquestColonialPressureActive` pin).
//
// The EXPAND below-quota peace rebuild-trap resolvers
// (`resolvePhaseEconomyExpandBelowQuotaPeaceInsufficientRegimentsActive`,
// `resolvePhaseEconomyExpandBelowQuotaPeaceZeroRegimentsRebuildActive`)
// are pinned in the sibling file
// `phase_planner_economy_filter_below_quota_peace_test.dart` so both
// files stay under the repo-lint
// `dart_file_non_comment_line_size` 1000-line cap (SPEC/program/repo-lint.md).
//
// Pins the structural contract of `resolvePhaseEconomyColonialPressureActive`:
//
//   - Returns `true` *only* under `ObserverGoalPhase.colonial`.
//   - Returns `false` under `ObserverGoalPhase.expand`,
//     `ObserverGoalPhase.colonialLite`, and `ObserverGoalPhase.develop`.
//   - Reads only `outcome.phase` — sibling slots (`colonialCivilianWorkOrders`,
//     `colonialMilitaryPlan`, `colonialNavalPlan`, ...) have no effect.
//   - Pure and deterministic across repeated calls (Refs #2509 Must-have #7).
//
// COLONIAL-lite suppression is the *correctness* pin: a tuning regression that
// fans out the legacy `hasColonialAcquisitionTargets && !stalledFocus &&
// !shouldSuppressNW` semantic into the new resolver (returning `true` under
// COLONIAL-lite when not stalled) would weaken the OW quota push under the
// safeguard, contradicting issue #2509 § COLONIAL-lite "Begin NW penetration
// without weakening OW push". A negative-control test pins COLONIAL-lite at
// `isFalse` even when every COLONIAL slot in `PhasePlanOutcome` is populated.
//
// Pins the structural contract of `resolvePhaseEconomyDevelopActive`:
//
//   - Returns `true` *only* under `ObserverGoalPhase.develop`.
//   - Returns `false` under `ObserverGoalPhase.expand`,
//     `ObserverGoalPhase.colonialLite`, and `ObserverGoalPhase.colonial`.
//   - Reads only `outcome.phase` — sibling slots (DEVELOP civilian-work,
//     COLONIAL acquisition / military / naval / civilian, EXPAND
//     economy / military) have no effect.
//   - Pure and deterministic across repeated calls (Refs #2509 Must-have #7).
//   - Disjoint from `resolvePhaseEconomyColonialPressureActive`: at most
//     one of the two resolvers returns `true` for any given outcome.
//
// The DEVELOP resolver replaces the per-player-turn
// `isObserverDevelopPhase(snapshot, game: ctx.game)` recompute in
// `_runEconomyDomainPlanners`. The dispatcher already resolved
// `observerGoalPhaseFor` once via `runPhasePlanners`, so phase-derived
// `true/false` is field-equal to the legacy compute across every
// `ObserverGoalPhase` value — these tests pin that invariant so a
// future regression cannot silently re-introduce the per-call recompute
// or drift the resolver away from the dispatcher's phase resolution.

import 'package:colonizethis_ai/colonizethis_ai.dart';
import 'package:colonizethis_ai/src/planning/colonial_phase_planner.dart';
import 'package:colonizethis_ai/src/planning/expand_phase_planner.dart'
    show ExpandEconomyPlan;
import 'package:colonizethis_ai/src/planning/phase_planner_conquest_filter.dart';
import 'package:colonizethis_ai/src/planning/phase_planner_economy_filter.dart';
import 'package:colonizethis_data/colonizethis_data.dart'
    show kColonialBuildOrderThresholdWhenOwnedNwUnderPressure;
import 'package:colonizethis_logic/ai_api.dart' show kWorkTargetBuildImprovement;
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';

// Non-default content for every full-COLONIAL slot used by the
// "structural exclusion ignores sibling slots" guards. The resolver must
// read only `outcome.phase`, so populated COLONIAL slots under EXPAND /
// COLONIAL-lite / DEVELOP must still resolve to `false`.
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
  group('resolvePhaseEconomyColonialPressureActive', () {
    test('active only under COLONIAL', () {
      expect(
        resolvePhaseEconomyColonialPressureActive(
          phasePlan: const PhasePlanOutcome(phase: ObserverGoalPhase.colonial),
        ),
        isTrue,
        reason:
            'COLONIAL phase entry is already gated by '
            'hasColonialAcquisitionTargets at observerGoalPhaseFor; the '
            'economy boost (lower civilian threshold, force '
            'runFullAiCivilianWork, BuildPickInput.colonialPressure cargo '
            'bonus) is structurally on for the full NW push.',
      );
    });

    test('suppressed under EXPAND, COLONIAL-lite, and DEVELOP', () {
      for (final phase in <ObserverGoalPhase>[
        ObserverGoalPhase.expand,
        ObserverGoalPhase.colonialLite,
        ObserverGoalPhase.develop,
      ]) {
        expect(
          resolvePhaseEconomyColonialPressureActive(
            phasePlan: PhasePlanOutcome(phase: phase),
          ),
          isFalse,
          reason:
              '$phase must not engage the colonial economy boost. '
              'COLONIAL-lite suppression is the SPEC-aligned correctness '
              'pin: issue #2509 § COLONIAL-lite forbids weakening the OW '
              'push by biasing economy/build toward NW cargo while still '
              'below the OW quota.',
        );
      }
    });

    test('reads only outcome.phase — populated COLONIAL slots under EXPAND / '
        'COLONIAL-lite / DEVELOP do not flip the resolver to true', () {
      // The PhasePlanOutcome dispatcher already enforces that COLONIAL
      // slots are unreachable under EXPAND / COLONIAL-lite / DEVELOP
      // (see SPEC § Suppression matrix). This guard pins the resolver
      // against a hypothetical regression that started leaking COLONIAL
      // slot content into other phases — even with every COLONIAL slot
      // populated, the resolver still routes off `outcome.phase` only.
      for (final phase in <ObserverGoalPhase>[
        ObserverGoalPhase.expand,
        ObserverGoalPhase.colonialLite,
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
          resolvePhaseEconomyColonialPressureActive(phasePlan: outcome),
          isFalse,
          reason:
              '$phase: COLONIAL slots populated must not flip the '
              'resolver — only outcome.phase decides.',
        );
      }
    });

    test('deterministic across repeated calls (Must-have #7)', () {
      // The resolver is pure on `outcome.phase` so identical inputs must
      // yield identical booleans across any number of invocations.
      for (final phase in ObserverGoalPhase.values) {
        final outcome = PhasePlanOutcome(phase: phase);
        final a = resolvePhaseEconomyColonialPressureActive(phasePlan: outcome);
        final b = resolvePhaseEconomyColonialPressureActive(phasePlan: outcome);
        final c = resolvePhaseEconomyColonialPressureActive(phasePlan: outcome);
        expect(a, b, reason: '$phase: two-call determinism');
        expect(b, c, reason: '$phase: three-call determinism');
      }
    });

    test('parity with resolvePhaseConquestColonialPressureActive across all '
        'phases — economy and conquest mirror each other to keep COLONIAL '
        'the sole NW-pressure phase', () {
      // Architectural parity pin: if a future slice diverges the
      // economy and conquest resolvers (for example by enabling
      // colonial economy under COLONIAL-lite while keeping conquest
      // suppression), the orchestrator's NW-pressure semantics would
      // become inconsistent across passes. This test forces both
      // resolvers to share the same "COLONIAL-only" contract until a
      // deliberate, SPEC-authorized split lands.
      for (final phase in ObserverGoalPhase.values) {
        final outcome = PhasePlanOutcome(phase: phase);
        final economy = resolvePhaseEconomyColonialPressureActive(
          phasePlan: outcome,
        );
        final conquest = resolvePhaseConquestColonialPressureActive(
          phasePlan: outcome,
        );
        expect(
          economy,
          conquest,
          reason:
              '$phase: economy and conquest NW-pressure resolvers must '
              'agree (both gate on phase == colonial).',
        );
      }
    });
  });

  group('resolvePhaseEconomyDevelopActive', () {
    test('active only under DEVELOP', () {
      expect(
        resolvePhaseEconomyDevelopActive(
          phasePlan: const PhasePlanOutcome(phase: ObserverGoalPhase.develop),
        ),
        isTrue,
        reason:
            'DEVELOP phase entry is already gated by '
            '`!hasColonialAcquisitionTargets && OW >= quota` at '
            'observerGoalPhaseFor; the orchestrator economy pass must '
            'lower the civilian threshold to '
            'kDevelopCivilianWorkThresholdCap and force '
            'runFullAiCivilianWork only under DEVELOP, matching the '
            'legacy isObserverDevelopPhase compute.',
      );
    });

    test('suppressed under EXPAND, COLONIAL-lite, and COLONIAL', () {
      for (final phase in <ObserverGoalPhase>[
        ObserverGoalPhase.expand,
        ObserverGoalPhase.colonialLite,
        ObserverGoalPhase.colonial,
      ]) {
        expect(
          resolvePhaseEconomyDevelopActive(
            phasePlan: PhasePlanOutcome(phase: phase),
          ),
          isFalse,
          reason:
              '$phase must not engage the DEVELOP economy gate. '
              'The DEVELOP improvement cap and forced '
              'runFullAiCivilianWork are structurally inactive '
              'outside DEVELOP — EXPAND and COLONIAL-lite keep the '
              'OW-focused civilian threshold; COLONIAL drives '
              'civilian work via colonialCivilianWorkOrders and the '
              'COLONIAL build cap (issue #2509 § Observer goal '
              'phases).',
        );
      }
    });

    test('reads only outcome.phase — populated DEVELOP / COLONIAL / EXPAND '
        'slots under non-DEVELOP phases do not flip the resolver to true', () {
      // The PhasePlanOutcome dispatcher already enforces structural
      // phase separation: DEVELOP slots are only populated under
      // DEVELOP, COLONIAL slots only under COLONIAL, EXPAND slots only
      // under EXPAND / COLONIAL-lite. This guard pins the resolver
      // against a hypothetical regression that started leaking slot
      // content into phases other than the one that produced it —
      // even with every sibling slot populated, the resolver must
      // route off `outcome.phase` only.
      const developCivilianWorkOrders = <WorkOrder>[
        WorkOrder(
          unitId: 'b1',
          target: kWorkTargetBuildImprovement,
          targetTileKey: 'oldWorld|portugal_a|0|0',
        ),
      ];
      for (final phase in <ObserverGoalPhase>[
        ObserverGoalPhase.expand,
        ObserverGoalPhase.colonialLite,
        ObserverGoalPhase.colonial,
      ]) {
        final outcome = PhasePlanOutcome(
          phase: phase,
          colonialAcquisitionTarget: _colonialAcquisitionPopulated,
          colonialPeaceTargetFactionIdsSorted: const <String>['gp2'],
          colonialMilitaryPlan: _colonialMilitaryPopulated,
          colonialNavalPlan: _colonialNavalPopulated,
          colonialCivilianWorkOrders: _colonialCivilianPopulated,
          developPeaceTargetFactionIdsSorted: const <String>['gp3'],
          developCivilianWorkOrders: developCivilianWorkOrders,
        );
        expect(
          resolvePhaseEconomyDevelopActive(phasePlan: outcome),
          isFalse,
          reason:
              '$phase: populated DEVELOP / COLONIAL slots must not '
              'flip the resolver — only outcome.phase decides.',
        );
      }
    });

    test('deterministic across repeated calls (Must-have #7)', () {
      // The resolver is pure on `outcome.phase` so identical inputs
      // must yield identical booleans across any number of
      // invocations.
      for (final phase in ObserverGoalPhase.values) {
        final outcome = PhasePlanOutcome(phase: phase);
        final a = resolvePhaseEconomyDevelopActive(phasePlan: outcome);
        final b = resolvePhaseEconomyDevelopActive(phasePlan: outcome);
        final c = resolvePhaseEconomyDevelopActive(phasePlan: outcome);
        expect(a, b, reason: '$phase: two-call determinism');
        expect(b, c, reason: '$phase: three-call determinism');
      }
    });

    test(
      'disjoint from resolvePhaseEconomyColonialPressureActive — at most '
      'one of the two economy resolvers returns true for any given phase',
      () {
        // The two economy resolvers gate disjoint orchestrator
        // decisions (DEVELOP improvement cap vs COLONIAL acquisition
        // pressure boost). A future regression that fired both
        // simultaneously would mean the same player turn is treated as
        // both DEVELOP and COLONIAL, contradicting the phase-planner
        // single-goal architecture (issue #2509 § Single-goal
        // replacement "Each phase planner is a pure function … no
        // cross-phase score merging").
        for (final phase in ObserverGoalPhase.values) {
          final outcome = PhasePlanOutcome(phase: phase);
          final develop = resolvePhaseEconomyDevelopActive(phasePlan: outcome);
          final colonial = resolvePhaseEconomyColonialPressureActive(
            phasePlan: outcome,
          );
          expect(
            develop && colonial,
            isFalse,
            reason:
                '$phase: develop and colonial-pressure economy '
                'resolvers must never both return true (phases are '
                'mutually exclusive per outcome.phase).',
          );
        }
      },
    );
  });

  group('resolvePhaseEconomyExpandQuotaPressureActive', () {
    test('active only under EXPAND and COLONIAL-lite', () {
      for (final phase in <ObserverGoalPhase>[
        ObserverGoalPhase.expand,
        ObserverGoalPhase.colonialLite,
      ]) {
        expect(
          resolvePhaseEconomyExpandQuotaPressureActive(
            phasePlan: PhasePlanOutcome(phase: phase),
          ),
          isTrue,
          reason:
              '$phase: below-quota OW build-pass arms (stalled threshold, '
              'GP-blocker focus, quota peace rebuild) are structurally on.',
        );
      }
    });

    test('suppressed under COLONIAL and DEVELOP', () {
      for (final phase in <ObserverGoalPhase>[
        ObserverGoalPhase.colonial,
        ObserverGoalPhase.develop,
      ]) {
        expect(
          resolvePhaseEconomyExpandQuotaPressureActive(
            phasePlan: PhasePlanOutcome(phase: phase),
          ),
          isFalse,
          reason:
              '$phase: OW quota pressure build arms must not leak from '
              'EXPAND / COLONIAL-lite once the GP is at or above quota '
              'or in DEVELOP improvement push.',
        );
      }
    });

    test('field-equal to resolvePhaseConquestExtraPassesActive across all '
        'phases', () {
      for (final phase in ObserverGoalPhase.values) {
        final outcome = PhasePlanOutcome(phase: phase);
        expect(
          resolvePhaseEconomyExpandQuotaPressureActive(phasePlan: outcome),
          resolvePhaseConquestExtraPassesActive(phasePlan: outcome),
          reason:
              '$phase: economy and conquest below-quota resolvers must '
              'agree (both gate on phase ∈ {EXPAND, COLONIAL-lite}).',
        );
      }
    });

    test('reads only outcome.phase — populated EXPAND slots under COLONIAL / '
        'DEVELOP do not flip the resolver to true', () {
      const expandEconomyPopulated = ExpandEconomyPlan(
        forceCheapestRegimentBuild: true,
        boostTreasuryRecoveryCargo: true,
      );
      for (final phase in <ObserverGoalPhase>[
        ObserverGoalPhase.colonial,
        ObserverGoalPhase.develop,
      ]) {
        final outcome = PhasePlanOutcome(
          phase: phase,
          expandEconomyPlan: expandEconomyPopulated,
          expandDeclareWarTargetFactionId: 'minor1',
        );
        expect(
          resolvePhaseEconomyExpandQuotaPressureActive(phasePlan: outcome),
          isFalse,
          reason:
              '$phase: non-default expandEconomyPlan must not enable '
              'below-quota OW build routing outside EXPAND / COLONIAL-lite.',
        );
      }
    });

    test('deterministic across repeated calls (Must-have #7)', () {
      for (final phase in ObserverGoalPhase.values) {
        final outcome = PhasePlanOutcome(phase: phase);
        final a = resolvePhaseEconomyExpandQuotaPressureActive(
          phasePlan: outcome,
        );
        final b = resolvePhaseEconomyExpandQuotaPressureActive(
          phasePlan: outcome,
        );
        expect(a, b, reason: '$phase: two-call determinism');
      }
    });
  });

  group('resolvePhaseEconomyColonialBuildOrderThresholdCap', () {
    // The resolver replaces the per-call
    // `colonialBuildOrderThresholdCap(snapshot.colonial)` invocation in
    // `_appendEconomyBuildOrders` (previously hosted in the now-deleted
    // `colonial_pressure.dart`). The legacy helper had two arms keyed
    // on `hasColonialAcquisitionTargets(colonial)`; the orchestrator
    // only invoked the helper inside the outer
    // `if (colonialPressure)` guard, where `colonialPressure` is the
    // dispatched `resolvePhaseEconomyColonialPressureActive` (active
    // only under COLONIAL). COLONIAL phase entry is itself gated on
    // `hasColonialAcquisitionTargets` via `observerGoalPhaseFor`, so
    // the first legacy arm
    // (`kColonialBuildOrderThresholdWhenOwnedNwUnderPressure`) was the
    // only reachable arm — the second (no-acquisition fallback)
    // required `!hasColonialAcquisitionTargets`, which is structurally
    // unreachable at the orchestrator's call site. The fallback
    // constant has since been retired from `colonizethis_data`
    // (Refs #2509). The phase-derived `int?` is therefore field-equal
    // to the legacy compute at the orchestrator's only call site
    // across every reachable `(ObserverGoalPhase, ColonialSummary)`
    // pair.
    test('returns kColonialBuildOrderThresholdWhenOwnedNwUnderPressure under '
        'COLONIAL with newWorldProvincesOwned > 0', () {
      const outcome = PhasePlanOutcome(phase: ObserverGoalPhase.colonial);
      const colonial = ColonialSummary(newWorldProvincesOwned: 1);
      expect(
        resolvePhaseEconomyColonialBuildOrderThresholdCap(
          phasePlan: outcome,
          colonial: colonial,
        ),
        kColonialBuildOrderThresholdWhenOwnedNwUnderPressure,
        reason:
            'COLONIAL phase entry is gated on hasColonialAcquisitionTargets '
            'so the only reachable legacy arm under the orchestrator '
            'guard returns the under-pressure cap when at least one NW '
            'province is owned.',
      );
    });

    test('returns null under COLONIAL with newWorldProvincesOwned == 0', () {
      const outcome = PhasePlanOutcome(phase: ObserverGoalPhase.colonial);
      const colonial = ColonialSummary();
      expect(
        resolvePhaseEconomyColonialBuildOrderThresholdCap(
          phasePlan: outcome,
          colonial: colonial,
        ),
        isNull,
        reason:
            'Legacy colonialBuildOrderThresholdCap returns null when '
            'newWorldProvincesOwned == 0; the phase-derived resolver '
            'must preserve that.',
      );
    });

    test('returns null under EXPAND, COLONIAL-lite, and DEVELOP regardless of '
        'newWorldProvincesOwned (structural NW-economy suppression)', () {
      // Mirrors `resolvePhaseEconomyColonialPressureActive` suppression
      // matrix: NW-owned GPs in EXPAND no longer receive the colonial
      // cap outside COLONIAL. The legacy
      // `colonialBuildOrderThresholdCap` had a fallback arm (since
      // retired from `colonizethis_data`) that returned a higher cap
      // when `hasColonialAcquisitionTargets` was false, but that branch
      // was unreachable at the orchestrator's call site because the
      // outer guard requires `colonialPressure` (COLONIAL only). The
      // phase-derived resolver collapses to `null` for every
      // non-COLONIAL phase, preserving the behaviour the orchestrator
      // actually observed.
      for (final phase in <ObserverGoalPhase>[
        ObserverGoalPhase.expand,
        ObserverGoalPhase.colonialLite,
        ObserverGoalPhase.develop,
      ]) {
        for (final nwOwned in <int>[0, 1, 5]) {
          final outcome = PhasePlanOutcome(phase: phase);
          final colonial = ColonialSummary(
            newWorldProvincesOwned: nwOwned,
          );
          expect(
            resolvePhaseEconomyColonialBuildOrderThresholdCap(
              phasePlan: outcome,
              colonial: colonial,
            ),
            isNull,
            reason:
                '$phase with newWorldProvincesOwned=$nwOwned: colonial '
                'cap must be structurally suppressed outside COLONIAL.',
          );
        }
      }
    });

    test('reads only outcome.phase and colonial.newWorldProvincesOwned — '
        'sibling slots on PhasePlanOutcome do not flip the resolver', () {
      // Pins the resolver against a hypothetical regression that
      // started leaking COLONIAL slot content into EXPAND /
      // COLONIAL-lite / DEVELOP. Even with every COLONIAL slot
      // populated, the resolver must still route off `outcome.phase`
      // only and ignore the populated acquisition / military / naval /
      // civilian slots when the active phase is not COLONIAL.
      for (final phase in <ObserverGoalPhase>[
        ObserverGoalPhase.expand,
        ObserverGoalPhase.colonialLite,
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
        const colonial = ColonialSummary(newWorldProvincesOwned: 3);
        expect(
          resolvePhaseEconomyColonialBuildOrderThresholdCap(
            phasePlan: outcome,
            colonial: colonial,
          ),
          isNull,
          reason:
              '$phase: populated COLONIAL slots must not flip the resolver '
              '— only outcome.phase decides the COLONIAL-only gate.',
        );
      }
    });

    test('deterministic across repeated calls (Must-have #7)', () {
      // The resolver is pure on `(outcome.phase,
      // colonial.newWorldProvincesOwned)` so identical inputs must
      // yield identical `int?` resolutions across any number of
      // invocations. Iterates every phase x {0, 1, 5} NW-ownership
      // combination so a future regression that introduced
      // non-determinism (random tiebreak, mutable shared state, ...)
      // would be caught.
      for (final phase in ObserverGoalPhase.values) {
        for (final nwOwned in <int>[0, 1, 5]) {
          final outcome = PhasePlanOutcome(phase: phase);
          final colonial = ColonialSummary(
            newWorldProvincesOwned: nwOwned,
          );
          final a = resolvePhaseEconomyColonialBuildOrderThresholdCap(
            phasePlan: outcome,
            colonial: colonial,
          );
          final b = resolvePhaseEconomyColonialBuildOrderThresholdCap(
            phasePlan: outcome,
            colonial: colonial,
          );
          final c = resolvePhaseEconomyColonialBuildOrderThresholdCap(
            phasePlan: outcome,
            colonial: colonial,
          );
          expect(
            a,
            b,
            reason: '$phase nwOwned=$nwOwned: two-call determinism',
          );
          expect(
            b,
            c,
            reason: '$phase nwOwned=$nwOwned: three-call determinism',
          );
        }
      }
    });

    test('returns the under-pressure constant, never the retired '
        'no-acquisition fallback value (18)', () {
      // Pins the structural invariant that the legacy no-acquisition
      // fallback arm is unreachable through the phase-derived path.
      // The retired fallback constant (since removed from
      // `colonizethis_data`; Refs #2509) carried the value 18 — the
      // under-pressure cap (`kColonialBuildOrderThresholdWhenOwnedNwUnderPressure`)
      // is 15, so a future regression that wired a mistakenly higher
      // numeric cap would flip this pin to red even if the
      // COLONIAL-only suppression matrix stayed intact. Exhaustive
      // over the reachable NW-ownership range to also pin the
      // constant against any phase-keyed tier blend.
      const outcome = PhasePlanOutcome(phase: ObserverGoalPhase.colonial);
      for (final nwOwned in <int>[1, 2, 5, 20]) {
        final colonial = ColonialSummary(newWorldProvincesOwned: nwOwned);
        final cap = resolvePhaseEconomyColonialBuildOrderThresholdCap(
          phasePlan: outcome,
          colonial: colonial,
        );
        expect(
          cap,
          kColonialBuildOrderThresholdWhenOwnedNwUnderPressure,
          reason:
              'nwOwned=$nwOwned: COLONIAL with any positive NW ownership '
              'must return the under-pressure cap.',
        );
        expect(
          cap,
          isNot(18),
          reason:
              'nwOwned=$nwOwned: the retired no-acquisition fallback '
              'value (18) is unreachable through the phase-derived '
              'path because COLONIAL phase entry requires '
              'hasColonialAcquisitionTargets.',
        );
      }
    });
  });

  group('resolvePhaseEconomyExpandGpBlockerFocusActive', () {
    test('active under EXPAND when expand frontier slots are set', () {
      const outcome = PhasePlanOutcome(
        phase: ObserverGoalPhase.expand,
        expandGpOnlyInvadableFrontierActive: true,
      );
      expect(
        resolvePhaseEconomyExpandGpBlockerFocusActive(phasePlan: outcome),
        isTrue,
      );
    });

    test('active under COLONIAL-lite when expand frontier slots are set', () {
      const outcome = PhasePlanOutcome(
        phase: ObserverGoalPhase.colonialLite,
        expandGpOnlyInvadableFrontierActive: true,
      );
      expect(
        resolvePhaseEconomyExpandGpBlockerFocusActive(phasePlan: outcome),
        isTrue,
      );
    });

    test('inactive under EXPAND when gp-only frontier is false', () {
      const outcome = PhasePlanOutcome(
        phase: ObserverGoalPhase.expand,
        expandGpOnlyInvadableFrontierActive: false,
      );
      expect(
        resolvePhaseEconomyExpandGpBlockerFocusActive(phasePlan: outcome),
        isFalse,
      );
    });

    test('inactive under COLONIAL and DEVELOP even when frontier slots set',
        () {
      const populated = PhasePlanOutcome(
        phase: ObserverGoalPhase.colonial,
        expandGpOnlyInvadableFrontierActive: true,
        expandPrimaryInvadableGpBlockerFactionId: 'gp2',
      );
      expect(
        resolvePhaseEconomyExpandGpBlockerFocusActive(phasePlan: populated),
        isFalse,
      );
      expect(
        resolvePhaseEconomyExpandGpBlockerFocusActive(
          phasePlan: const PhasePlanOutcome(
            phase: ObserverGoalPhase.develop,
            expandGpOnlyInvadableFrontierActive: true,
            expandPrimaryInvadableGpBlockerFactionId: 'gp2',
          ),
        ),
        isFalse,
      );
    });

    test('deterministic across repeated calls (Must-have #7)', () {
      const outcome = PhasePlanOutcome(
        phase: ObserverGoalPhase.expand,
        expandGpOnlyInvadableFrontierActive: true,
      );
      expect(
        resolvePhaseEconomyExpandGpBlockerFocusActive(phasePlan: outcome),
        resolvePhaseEconomyExpandGpBlockerFocusActive(phasePlan: outcome),
      );
    });
  });

  group('expandPrimaryInvadableGpBlockerFromPhasePlan', () {
    test('returns blocker id when focus active', () {
      const outcome = PhasePlanOutcome(
        phase: ObserverGoalPhase.expand,
        expandGpOnlyInvadableFrontierActive: true,
        expandPrimaryInvadableGpBlockerFactionId: 'gp2',
      );
      expect(
        expandPrimaryInvadableGpBlockerFromPhasePlan(phasePlan: outcome),
        'gp2',
      );
    });

    test('returns null when focus inactive', () {
      const outcome = PhasePlanOutcome(
        phase: ObserverGoalPhase.expand,
        expandGpOnlyInvadableFrontierActive: false,
        expandPrimaryInvadableGpBlockerFactionId: 'gp2',
      );
      expect(
        expandPrimaryInvadableGpBlockerFromPhasePlan(phasePlan: outcome),
        isNull,
      );
    });

    test('returns null under COLONIAL even when slots populated', () {
      const outcome = PhasePlanOutcome(
        phase: ObserverGoalPhase.colonial,
        expandGpOnlyInvadableFrontierActive: true,
        expandPrimaryInvadableGpBlockerFactionId: 'gp2',
      );
      expect(
        expandPrimaryInvadableGpBlockerFromPhasePlan(phasePlan: outcome),
        isNull,
      );
    });

    test('deterministic across repeated calls (Must-have #7)', () {
      const outcome = PhasePlanOutcome(
        phase: ObserverGoalPhase.colonialLite,
        expandGpOnlyInvadableFrontierActive: true,
        expandPrimaryInvadableGpBlockerFactionId: 'gp3',
      );
      expect(
        expandPrimaryInvadableGpBlockerFromPhasePlan(phasePlan: outcome),
        expandPrimaryInvadableGpBlockerFromPhasePlan(phasePlan: outcome),
      );
    });
  });
}
