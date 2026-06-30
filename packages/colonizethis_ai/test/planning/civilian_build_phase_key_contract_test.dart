// Locks the cross-package contract between `ObserverGoalPhase` (colonizethis_ai)
// and the civilian-build phase-key constants (colonizethis_data). The build
// planner passes `phase.name` into `civilianBuildPhaseMultiplier`; because
// `colonizethis_data` cannot depend on `colonizethis_ai`, the keys in
// `kCivilianBuildPhaseMultiplierByPhaseType` are stable enum-name strings. A
// rename on either side would silently neutralize the phase multiplier, so this
// test fails fast if the names drift (Refs #3793 slice 3, SPEC § Scoring model).
import 'package:colonizethis_ai/src/planning/observer_goal_phase.dart';
import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';

void main() {
  group('ObserverGoalPhase.name ↔ civilian build phase key (Refs #3793)', () {
    test('every phase key constant equals the matching enum name', () {
      expect(ObserverGoalPhase.expand.name, kCivilianBuildPhaseExpand);
      expect(
        ObserverGoalPhase.colonialLite.name,
        kCivilianBuildPhaseColonialLite,
      );
      expect(ObserverGoalPhase.colonial.name, kCivilianBuildPhaseColonial);
      expect(ObserverGoalPhase.develop.name, kCivilianBuildPhaseDevelop);
    });

    test('every ObserverGoalPhase resolves a phase multiplier (no unknowns)', () {
      // For each phase name, a favored type must score the favored multiplier so
      // the map is wired for every phase the AI can pass.
      const favoredByPhase = {
        kCivilianBuildPhaseExpand: kUnitTypeBuilder,
        kCivilianBuildPhaseColonialLite: kUnitTypeBuilder,
        kCivilianBuildPhaseColonial: kUnitTypeExplorer,
        kCivilianBuildPhaseDevelop: kUnitTypeEngineer,
      };
      for (final phase in ObserverGoalPhase.values) {
        final favored = favoredByPhase[phase.name];
        expect(favored, isNotNull, reason: 'no favored type for ${phase.name}');
        expect(
          civilianBuildPhaseMultiplier(favored!, phase.name),
          kCivilianBuildPhaseMultiplierFavored,
          reason: 'phase ${phase.name} should favor $favored',
        );
      }
    });
  });
}
