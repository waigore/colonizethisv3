import 'dart:io';

import 'package:colonizethis_test/test.dart';
import 'package:sim_scenarios/scenario_runner.dart';

File _scenarioFile(String name) {
  final fromToolDir = File('scenarios/$name');
  if (fromToolDir.existsSync()) return fromToolDir;
  return File('tool/sim_scenarios/scenarios/$name');
}

void main() {
  group('naval behavior scenarios (json)', () {
    test('surviving fleets preserve mission after combat', () async {
      final runner = ScenarioRunner();
      final result = await runner.runFile(
        _scenarioFile('naval_behavior_preserve_mission.json'),
      );

      expect(
        result.passed,
        isTrue,
        reason: result.failures.join('\n'),
      );
      final game = result.finalState;
      expect(game, isNotNull);

      final p1Fleets =
          game!.worldState.fleets.where((f) => f.ownerId == 'gp1').toList();
      final p2Fleets =
          game.worldState.fleets.where((f) => f.ownerId == 'gp2').toList();

      if (p1Fleets.isNotEmpty) {
        expect(p1Fleets.first.mission.name, 'patrol');
      }
      if (p2Fleets.isNotEmpty) {
        expect(p2Fleets.first.mission.name, 'blockade');
      }
    });

    test('hostile adjacent zone is never selected as retreat destination', () async {
      final runner = ScenarioRunner();
      final result = await runner.runFile(
        _scenarioFile('naval_behavior_hostile_adjacent_not_retreat.json'),
      );

      expect(
        result.passed,
        isTrue,
        reason: result.failures.join('\n'),
      );
      final game = result.finalState;
      expect(game, isNotNull);

      final sideFleetsInSea2 = game!.worldState.fleets.where(
        (f) =>
            (f.ownerId == 'gp1' || f.ownerId == 'gp2') && f.seaZoneId == 'sea2',
      );
      expect(sideFleetsInSea2, isEmpty);
    });

    test('no legal retreat keeps survivors in battle sea zone', () async {
      final runner = ScenarioRunner();
      final result = await runner.runFile(
        _scenarioFile('naval_behavior_no_legal_retreat_stays.json'),
      );

      expect(
        result.passed,
        isTrue,
        reason: result.failures.join('\n'),
      );
      final game = result.finalState;
      expect(game, isNotNull);

      final sideFleets = game!.worldState.fleets.where(
        (f) => f.ownerId == 'gp1' || f.ownerId == 'gp2',
      );
      for (final fleet in sideFleets) {
        expect(fleet.seaZoneId, 'sea1');
      }
    });
  });
}
