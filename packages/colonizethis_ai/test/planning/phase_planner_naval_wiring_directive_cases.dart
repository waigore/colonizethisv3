// Case bodies for `phase_planner_naval_wiring_test.dart` (Refs #4291 Slice D).
// Registered from the thin contract; pin coverage preserved 1:1.

// Unit tests for `phase_planner_naval_filter.dart` and naval planner
// orchestrator wiring (Refs #2509 S5).

import 'package:colonizethis_ai/colonizethis_ai.dart';
import 'package:colonizethis_ai/src/planning/colonial_phase_planner.dart';
import 'package:colonizethis_ai/src/planning/naval_planner.dart';
import 'package:colonizethis_ai/src/planning/phase_planner_naval_filter.dart';
import 'package:colonizethis_ai/src/planning/planner_context.dart';
import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';

import '../support/domain_planner_test_fake_api.dart';
import '../support/planner_test_helpers.dart';

const ColonialNavalPlan _colonialNavalPriority = ColonialNavalPlan(
  priorityInvasionTransportProvinceIdsSorted: <String>['newWorld|tribe1_a'],
  priorityTargetOwnerFactionIdsSorted: <String>['tribe1'],
);

const ColonialLiteNavalPlan _colonialLiteNavalPriority = ColonialLiteNavalPlan(
  priorityNwProvinceIdsSorted: <String>['newWorld|tribe2_b'],
  priorityTargetOwnerFactionIdsSorted: <String>['tribe2'],
);


void registerPhasePlannerNavalWiringDirectiveCases() {
  group('resolvePhaseNavalDirective', () {
    test('EXPAND structurally suppresses colonial pressure', () {
      const outcome = PhasePlanOutcome(phase: ObserverGoalPhase.expand);
      final r = resolvePhaseNavalDirective(phasePlan: outcome);
      expect(r.colonialPreferenceActive, isFalse);
      expect(r.priorityNwProvinceIdsSorted, isEmpty);
    });

    test('DEVELOP structurally suppresses colonial pressure', () {
      const outcome = PhasePlanOutcome(phase: ObserverGoalPhase.develop);
      final r = resolvePhaseNavalDirective(phasePlan: outcome);
      expect(r.colonialPreferenceActive, isFalse);
      expect(r.priorityNwProvinceIdsSorted, isEmpty);
    });

    test('COLONIAL surfaces invasion-transport priority list', () {
      const outcome = PhasePlanOutcome(
        phase: ObserverGoalPhase.colonial,
        colonialNavalPlan: _colonialNavalPriority,
      );
      final r = resolvePhaseNavalDirective(phasePlan: outcome);
      expect(r.colonialPreferenceActive, isTrue);
      expect(
        r.priorityNwProvinceIdsSorted,
        _colonialNavalPriority.priorityInvasionTransportProvinceIdsSorted,
      );
    });

    test('COLONIAL fallthrough (defaultPlan) keeps preference active', () {
      const outcome = PhasePlanOutcome(phase: ObserverGoalPhase.colonial);
      final r = resolvePhaseNavalDirective(phasePlan: outcome);
      expect(
        r.colonialPreferenceActive,
        isTrue,
        reason:
            'COLONIAL phase entry already gated by hasColonialAcquisitionTargets; '
            'naval pressure stays on for exploration / cargo even if no '
            'invasion-transport priority arm fired this turn.',
      );
      expect(r.priorityNwProvinceIdsSorted, isEmpty);
    });

    test('COLONIAL-lite surfaces tribe/minor naval focus list', () {
      const outcome = PhasePlanOutcome(
        phase: ObserverGoalPhase.colonialLite,
        colonialLiteNavalPlan: _colonialLiteNavalPriority,
      );
      final r = resolvePhaseNavalDirective(phasePlan: outcome);
      expect(r.colonialPreferenceActive, isTrue);
      expect(
        r.priorityNwProvinceIdsSorted,
        _colonialLiteNavalPriority.priorityNwProvinceIdsSorted,
      );
    });

    test('COLONIAL-lite fallthrough (defaultPlan) keeps preference active', () {
      const outcome = PhasePlanOutcome(phase: ObserverGoalPhase.colonialLite);
      final r = resolvePhaseNavalDirective(phasePlan: outcome);
      expect(
        r.colonialPreferenceActive,
        isTrue,
        reason:
            'COLONIAL-lite entry already gated by globalNewWorldHasNonGpOwnership; '
            'the spec explicitly allows colonial naval/cargo even when the '
            'tribe/minor priority arm has no active candidates this turn.',
      );
      expect(r.priorityNwProvinceIdsSorted, isEmpty);
    });

    test('Mutual exclusivity: COLONIAL ignores COLONIAL-lite slot', () {
      const outcome = PhasePlanOutcome(
        phase: ObserverGoalPhase.colonial,
        colonialLiteNavalPlan: _colonialLiteNavalPriority,
      );
      final r = resolvePhaseNavalDirective(phasePlan: outcome);
      expect(
        r.priorityNwProvinceIdsSorted,
        isEmpty,
        reason:
            'Full COLONIAL drives invasion transport via colonialNavalPlan; '
            'colonialLiteNavalPlan must never leak into COLONIAL even when '
            'the slot is non-default (structural mutual exclusion).',
      );
    });

    test('Mutual exclusivity: COLONIAL-lite ignores COLONIAL slot', () {
      const outcome = PhasePlanOutcome(
        phase: ObserverGoalPhase.colonialLite,
        colonialNavalPlan: _colonialNavalPriority,
      );
      final r = resolvePhaseNavalDirective(phasePlan: outcome);
      expect(
        r.priorityNwProvinceIdsSorted,
        isEmpty,
        reason:
            'COLONIAL-lite suppresses NW invasion transport per spec '
            '("Never suggest invasion transport or NW army staging here"); '
            'colonialNavalPlan slot must not leak into COLONIAL-lite.',
      );
    });

    test('EXPAND ignores both colonial naval slots (structural)', () {
      const outcome = PhasePlanOutcome(
        phase: ObserverGoalPhase.expand,
        colonialNavalPlan: _colonialNavalPriority,
        colonialLiteNavalPlan: _colonialLiteNavalPriority,
      );
      final r = resolvePhaseNavalDirective(phasePlan: outcome);
      expect(r.colonialPreferenceActive, isFalse);
      expect(r.priorityNwProvinceIdsSorted, isEmpty);
    });

    test('DEVELOP ignores both colonial naval slots (structural)', () {
      const outcome = PhasePlanOutcome(
        phase: ObserverGoalPhase.develop,
        colonialNavalPlan: _colonialNavalPriority,
        colonialLiteNavalPlan: _colonialLiteNavalPriority,
      );
      final r = resolvePhaseNavalDirective(phasePlan: outcome);
      expect(r.colonialPreferenceActive, isFalse);
      expect(r.priorityNwProvinceIdsSorted, isEmpty);
    });

    test('deterministic for identical inputs (Must-have #7)', () {
      const outcome = PhasePlanOutcome(
        phase: ObserverGoalPhase.colonial,
        colonialNavalPlan: _colonialNavalPriority,
      );
      final a = resolvePhaseNavalDirective(phasePlan: outcome);
      final b = resolvePhaseNavalDirective(phasePlan: outcome);
      expect(a.colonialPreferenceActive, b.colonialPreferenceActive);
      expect(a.priorityNwProvinceIdsSorted, b.priorityNwProvinceIdsSorted);
    });
  });

}
