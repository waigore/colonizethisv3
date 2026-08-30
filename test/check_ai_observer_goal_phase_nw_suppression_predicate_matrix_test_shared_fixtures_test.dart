import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:test/test.dart';

import '../tool/check_ai_observer_goal_phase_nw_suppression_predicate_matrix_test_shared_fixtures.dart';

void main() {
  group(
      'runCheckAiObserverGoalPhaseNwSuppressionPredicateMatrixTestSharedFixtures',
      () {
    test('fails when adopter redeclares _gameWithTribeNw', () {
      final temp = Directory.systemTemp.createTempSync('ai-nwsm-game-');
      try {
        _writeSupport(temp);
        _writeAdopter(
          temp,
          'observer_goal_phase_nw_suppression_predicate_game_matrix_test.dart',
          'Game _gameWithTribeNw({required int turnNumber}) {\n'
          '  throw UnimplementedError();\n'
          '}\n',
        );
        final errors = <String>[];
        final code =
            runCheckAiObserverGoalPhaseNwSuppressionPredicateMatrixTestSharedFixtures(
          temp.path,
          info: (_) {},
          err: errors.add,
        );
        expect(code, 1);
        expect(errors.join('\n'), contains('_gameWithTribeNw'));
      } finally {
        temp.deleteSync(recursive: true);
      }
    });

    test('passes when adopter uses shared factories', () {
      final temp = Directory.systemTemp.createTempSync('ai-nwsm-ok-');
      try {
        _writeSupport(temp);
        _writeAdopter(
          temp,
          'observer_goal_phase_nw_suppression_predicate_game_matrix_test.dart',
          "import '../support/observer_goal_phase_nw_suppression_predicate_matrix_test_support.dart';\n",
        );
        final code =
            runCheckAiObserverGoalPhaseNwSuppressionPredicateMatrixTestSharedFixtures(
          temp.path,
          info: (_) {},
          err: (_) {},
        );
        expect(code, 0);
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
      'observer_goal_phase_nw_suppression_predicate_matrix_test_support.dart',
    ),
  ).writeAsStringSync('// stub\n');
}

void _writeAdopter(Directory temp, String name, String body) {
  final planning = Directory(
    p.join(temp.path, 'packages', 'colonizethis_ai', 'test', 'planning'),
  )..createSync(recursive: true);
  File(p.join(planning.path, name)).writeAsStringSync(body);
}
