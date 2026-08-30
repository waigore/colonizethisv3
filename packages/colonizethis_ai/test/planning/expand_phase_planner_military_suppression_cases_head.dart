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

void registerExpandPhasePlannerMilitarySuppressionHeadCases() {
  group('planExpandMilitary', () {
    test(
      'declared-war target wins over at-war fallback (priority 1 over 2)',
      () {
        // Both arms could fire (target owns invadable AND another at-war
        // faction owns invadable), but priority 1 (declare-war target)
        // takes precedence and excludes the at-war non-target from the
        // owner list.
        final game = buildExpandGame(
          gameIdLabel: 'expand-phase-planner-military',
          oldWorldProvinces: const [
            Province(
              id: 'oldWorld|m1_a',
              regionId: 'oldWorld',
              ownerId: _minor1,
            ),
            Province(
              id: 'oldWorld|m2_a',
              regionId: 'oldWorld',
              ownerId: _minor2,
            ),
          ],
          minorNations: const [
            MinorNation(id: _minor1, displayName: 'M1'),
            MinorNation(id: _minor2, displayName: 'M2'),
          ],
        );
        final snapshot = buildExpandSnapshot(
          atWarWith: const [_minor1, _minor2],
          invadableOw: const ['oldWorld|m1_a', 'oldWorld|m2_a'],
        );
        expect(
          planExpandMilitary(
            game: game,
            snapshot: snapshot,
            declaredWarTargetFactionId: _minor1,
          ),
          const ExpandMilitaryPlan(
            priorityDestinationProvinceIdsSorted: <String>['oldWorld|m1_a'],
            priorityTargetOwnerFactionIdsSorted: <String>[_minor1],
          ),
          reason:
              'Priority 1 (declare-war target) wins over priority 2 '
              '(at-war fallback). minor2 is at war and owns an invadable '
              'province but is correctly excluded from the plan because '
              'a declare-war target is given.',
        );
      },
    );

  });
}
