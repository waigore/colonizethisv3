// Topic-split case module (Refs #4602 Slice B).

// Case bodies for `expand_phase_planner_military_test.dart` (Refs #4104 Slice C).

import 'package:colonizethis_ai/src/planning/expand_phase_planner.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';

import 'expand_phase_planner_military_support.dart';
import 'test_game_factories.dart';

const String _gp2 = expandMilitaryGp2;
const String _gp3 = expandMilitaryGp3;
const String _minor1 = expandMilitaryMinor1;
const String _minor2 = expandMilitaryMinor2;
const String _tribe1 = expandMilitaryTribe1;

void registerExpandPhasePlannerMilitaryPriorityLateCases() {
  group('planExpandMilitary', () {
    test('AC: no declared-war target, at-war minor owns invadable OW -> '
        'restrict to those provinces + sorted at-war owners', () {
      // Priority 2 fires when no declared target is given and at
      // least one at-war faction owns an OW invadable province. The
      // plan restricts to the union of those provinces and lists the
      // at-war owners sorted ascending.
      final game = buildExpandGame(
        gameIdLabel: 'expand-phase-planner-military',
        oldWorldProvinces: const [
          Province(id: 'oldWorld|m1_a', regionId: 'oldWorld', ownerId: _minor1),
        ],
        minorNations: const [MinorNation(id: _minor1, displayName: 'M1')],
      );
      final snapshot = buildExpandSnapshot(
        atWarWith: const [_minor1],
        invadableOw: const ['oldWorld|m1_a'],
      );
      expect(
        planExpandMilitary(game: game, snapshot: snapshot),
        const ExpandMilitaryPlan(
          priorityDestinationProvinceIdsSorted: <String>['oldWorld|m1_a'],
          priorityTargetOwnerFactionIdsSorted: <String>[_minor1],
        ),
        reason:
            'Priority 2 (at-war fallback): no declare-war target + '
            'an at-war minor owns one OW invadable -> plan restricts '
            'to that province and lists the at-war owner.',
      );
    });

    test('no declared-war target, multiple at-war owners (GP + minor) -> '
        'union of their invadable + sorted owners', () {
      // At-war fallback covers any faction class (GP, minor, tribe).
      // Two at-war owners contribute provinces; the plan unions them
      // and lists both owners sorted ascending.
      final game = buildExpandGame(
        gameIdLabel: 'expand-phase-planner-military',
        oldWorldProvinces: const [
          Province(id: 'oldWorld|gp2_0', regionId: 'oldWorld', ownerId: _gp2),
          Province(id: 'oldWorld|m1_a', regionId: 'oldWorld', ownerId: _minor1),
        ],
        minorNations: const [MinorNation(id: _minor1, displayName: 'M1')],
      );
      final snapshot = buildExpandSnapshot(
        atWarWith: const [_gp2, _minor1],
        invadableOw: const ['oldWorld|m1_a', 'oldWorld|gp2_0'],
      );
      expect(
        planExpandMilitary(game: game, snapshot: snapshot),
        ExpandMilitaryPlan(
          priorityDestinationProvinceIdsSorted: List<String>.unmodifiable(
            const <String>['oldWorld|gp2_0', 'oldWorld|m1_a'],
          ),
          priorityTargetOwnerFactionIdsSorted: List<String>.unmodifiable(
            const <String>[_gp2, _minor1],
          ),
        ),
        reason:
            'Priority 2 unions provinces across all at-war owners '
            '(GP + minor). Provinces and owners are both sorted '
            'ascending in the plan output.',
      );
    });

    test('at-war owner with no invadable contribution is dropped from owner '
        'list', () {
      // An at-war faction that does NOT own any invadable OW province
      // must NOT appear in priorityTargetOwnerFactionIdsSorted. This
      // pins the "owner list mirrors actual destinations" contract so
      // a downstream orchestrator never sees a phantom target.
      final game = buildExpandGame(
        gameIdLabel: 'expand-phase-planner-military',
        oldWorldProvinces: const [
          Province(id: 'oldWorld|m1_a', regionId: 'oldWorld', ownerId: _minor1),
        ],
        minorNations: const [
          MinorNation(id: _minor1, displayName: 'M1'),
          MinorNation(id: _minor2, displayName: 'M2'),
        ],
      );
      final snapshot = buildExpandSnapshot(
        // minor2 is at war but owns nothing in OW invadable, so should
        // be dropped from the owner list.
        atWarWith: const [_minor1, _minor2],
        invadableOw: const ['oldWorld|m1_a'],
      );
      expect(
        planExpandMilitary(game: game, snapshot: snapshot),
        const ExpandMilitaryPlan(
          priorityDestinationProvinceIdsSorted: <String>['oldWorld|m1_a'],
          priorityTargetOwnerFactionIdsSorted: <String>[_minor1],
        ),
        reason:
            'Only at-war owners that actually contribute an invadable '
            'province appear in priorityTargetOwnerFactionIdsSorted. '
            'minor2 is at war but contributes nothing so it is dropped.',
      );
    });

    test('no declared-war target, no at-war owners hold invadable -> '
        'defaultPlan', () {
      // Priority 2 fails when no at-war faction owns an invadable OW
      // province. Both priority arms exhausted -> defaultPlan; the
      // orchestrator falls back to legacy free-choice conquest.
      final game = buildExpandGame(
        gameIdLabel: 'expand-phase-planner-military',
        oldWorldProvinces: const [
          Province(id: 'oldWorld|m1_a', regionId: 'oldWorld', ownerId: _minor1),
        ],
        minorNations: const [
          MinorNation(id: _minor1, displayName: 'M1'),
          MinorNation(id: _minor2, displayName: 'M2'),
        ],
      );
      final snapshot = buildExpandSnapshot(
        // minor2 is at war but does NOT own the invadable province.
        atWarWith: const [_minor2],
        invadableOw: const ['oldWorld|m1_a'],
      );
      expect(
        planExpandMilitary(game: game, snapshot: snapshot),
        same(ExpandMilitaryPlan.defaultPlan),
        reason:
            'No declare-war target + no at-war faction owning an '
            'OW invadable -> defaultPlan (the orchestrator falls '
            'back to the legacy free-choice conquest behaviour).',
      );
    });
  });
}
