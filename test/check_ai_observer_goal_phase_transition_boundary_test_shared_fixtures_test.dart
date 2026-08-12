import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:test/test.dart';

import '../tool/check_ai_observer_goal_phase_transition_boundary_test_shared_fixtures.dart';

void main() {
  group('runCheckAiObserverGoalPhaseTransitionBoundaryTestSharedFixtures', () {
    test('fails when contract redeclares _scenarioGame', () {
      final temp = Directory.systemTemp.createTempSync('ai-ogptb-');
      try {
        _writeSupport(temp);
        _writeAdopter(
          temp,
          'observer_goal_phase_transition_boundary_test.dart',
          'Game _scenarioGame() {\n'
          '  throw UnimplementedError();\n'
          '}\n',
        );
        final errors = <String>[];
        final code =
            runCheckAiObserverGoalPhaseTransitionBoundaryTestSharedFixtures(
          temp.path,
          info: (_) {},
          err: errors.add,
        );
        expect(code, 1);
        expect(errors.join('\n'), contains('_scenarioGame'));
      } finally {
        temp.deleteSync(recursive: true);
      }
    });

    test('passes when adopters use shared factories', () {
      final temp = Directory.systemTemp.createTempSync('ai-ogptb-ok-');
      try {
        _writeSupport(temp);
        _writeAdopter(
          temp,
          'observer_goal_phase_transition_boundary_phase_cases.dart',
          "import '../support/observer_goal_phase_transition_boundary_test_support.dart';\n",
        );
        final code =
            runCheckAiObserverGoalPhaseTransitionBoundaryTestSharedFixtures(
          temp.path,
          info: (_) {},
          err: (_) {},
        );
        expect(code, 0);
      } finally {
        temp.deleteSync(recursive: true);
      }
    });

    test('fails when shared support is missing', () {
      final temp = Directory.systemTemp.createTempSync('ai-ogptb-miss-');
      try {
        final code =
            runCheckAiObserverGoalPhaseTransitionBoundaryTestSharedFixtures(
          temp.path,
          info: (_) {},
          err: (_) {},
        );
        expect(code, 1);
      } finally {
        temp.deleteSync(recursive: true);
      }
    });
  });
}

void _writeSupport(Directory temp) {
  final support = Directory(
    p.join(temp.path, 'packages', 'colonizethis_ai', 'test', 'support'),
  )..createSync(recursive: true);
  File(
    p.join(
      support.path,
      'observer_goal_phase_transition_boundary_test_support.dart',
    ),
  ).writeAsStringSync('// stub\n');
}

void _writeAdopter(Directory temp, String name, String body) {
  final planning = Directory(
    p.join(temp.path, 'packages', 'colonizethis_ai', 'test', 'planning'),
  )..createSync(recursive: true);
  File(p.join(planning.path, name)).writeAsStringSync(body);
}
