import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:test/test.dart';

import '../tool/check_ai_observer_goal_phase_colonial_lite_preconditions_test_shared_fixtures.dart';

void main() {
  group('runCheckAiObserverGoalPhaseColonialLitePreconditionsTestSharedFixtures',
      () {
    test('fails when adopter redeclares _gameWithNwOwner', () {
      final temp = Directory.systemTemp.createTempSync('ai-clp-game-');
      try {
        _writeSupport(temp);
        _writeAdopter(
          temp,
          'observer_goal_phase_colonial_lite_preconditions_test.dart',
          'Game _gameWithNwOwner({required int turnNumber}) {\n'
          '  throw UnimplementedError();\n'
          '}\n',
        );
        final errors = <String>[];
        final code =
            runCheckAiObserverGoalPhaseColonialLitePreconditionsTestSharedFixtures(
          temp.path,
          info: (_) {},
          err: errors.add,
        );
        expect(code, 1);
        expect(errors.join('\n'), contains('_gameWithNwOwner'));
      } finally {
        temp.deleteSync(recursive: true);
      }
    });

    test('passes when adopter uses shared factories', () {
      final temp = Directory.systemTemp.createTempSync('ai-clp-ok-');
      try {
        _writeSupport(temp);
        _writeAdopter(
          temp,
          'observer_goal_phase_colonial_lite_preconditions_test.dart',
          "import '../support/observer_goal_phase_colonial_lite_preconditions_test_support.dart';\n",
        );
        final code =
            runCheckAiObserverGoalPhaseColonialLitePreconditionsTestSharedFixtures(
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
      'observer_goal_phase_colonial_lite_preconditions_test_support.dart',
    ),
  ).writeAsStringSync('// stub\n');
}

void _writeAdopter(Directory temp, String name, String body) {
  final planning = Directory(
    p.join(temp.path, 'packages', 'colonizethis_ai', 'test', 'planning'),
  )..createSync(recursive: true);
  File(p.join(planning.path, name)).writeAsStringSync(body);
}
