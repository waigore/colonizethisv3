import 'package:colonizethis_ai/src/planning/build_planner.dart';
import 'package:colonizethis_ai/src/planning/goal_manager.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';

import 'planner_context_test_helper.dart';

void main() {
  group('pickBuildOrder', () {
    test('prefers regiment when behind victory pace and conquer goal', () {
      const candidates = [
        BuildUnitOrder(
          unitType: 'sloop',
          isMilitary: false,
          spawnProvinceId: 'oldWorld|p1',
        ),
        BuildUnitOrder(
          unitType: 'grenadiers',
          isMilitary: true,
          spawnProvinceId: 'oldWorld|p1',
        ),
      ];
      const config = AIConfig(
        leaderId: 'napoleon',
        personalityId: 'napoleon',
        hiddenAgendaId: 'warmonger',
      );
      final ctx = buildTestPlannerContext(
        nationId: 'gp1',
        config: config,
        primaryGoal: StrategicGoal.conquer,
      );
      final chosen = pickBuildOrder(
        ctx: ctx,
        buildCandidates: candidates,
        cargoPreference: CargoPreference.none,
        seed: 1,
        provincesToVictory: 20,
      );
      expect(chosen?.unitType, 'grenadiers');
    });
  });
}
