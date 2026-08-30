// Case bodies for `expand_phase_planner_declare_war_test.dart` (Refs #4104 Slice C).

import 'package:colonizethis_ai/src/planning/expand_phase_planner.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';

import 'ai_planner_fixtures.dart';
import 'expand_phase_planner_declare_war_support.dart';
import 'test_game_factories.dart';

const String _gp1 = expandDeclareWarGp1;
const String _gp2 = expandDeclareWarGp2;
const String _gp3 = expandDeclareWarGp3;
const String _minor1 = expandDeclareWarMinor1;
const String _minor2 = expandDeclareWarMinor2;
const String _minor3 = expandDeclareWarMinor3;

void registerExpandPhasePlannerDeclareWarPriorityHeadCases() {
  group('planExpandDeclareWar', () {
    test('empty invadable list -> null', () {
      // No OW frontier means there is no province to expand into. The
      // function must short-circuit before any priority-arm scan or
      // treasury check.
      final game = buildExpandGame(
        gameIdLabel: 'expand-phase-planner-declare-war',
      );
      final snapshot = buildExpandSnapshot(atWarWith: const []);
      expect(planExpandDeclareWar(game: game, snapshot: snapshot), isNull);
    });

  });
}
