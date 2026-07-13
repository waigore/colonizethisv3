import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:test/test.dart';

import '../tool/check_ai_phase_planner_nw_suppression_test_shared_fixtures.dart';

void main() {
  group('runCheckAiPhasePlannerNwSuppressionTestSharedFixtures', () {
    test('fails when expand NW-suppression redeclares _expandSnapshot', () {
      final temp = Directory.systemTemp.createTempSync('ai-nw-expand-');
      try {
        _writeSupportStub(temp);
        _writeExpandTest(
          temp,
          "import 'package:test/test.dart';\n\n"
          'AIWorldSnapshot _expandSnapshot() {\n'
          '  throw UnimplementedError();\n'
          '}\n\n'
          'void main() {}\n',
        );
        final errors = <String>[];
        final exitCode =
            runCheckAiPhasePlannerNwSuppressionTestSharedFixtures(
              temp.path,
              info: (_) {},
              err: errors.add,
            );
        expect(exitCode, 1);
        expect(errors.join('\n'), contains('_expandSnapshot'));
        expect(
          errors.join('\n'),
          contains('buildExpandPhaseNwSuppressionSnapshot'),
        );
      } finally {
        temp.deleteSync(recursive: true);
      }
    });

    test('fails when develop NW-suppression redeclares _developGame', () {
      final temp = Directory.systemTemp.createTempSync('ai-nw-develop-');
      try {
        _writeSupportStub(temp);
        _writeDevelopTest(
          temp,
          "import 'package:test/test.dart';\n\n"
          'Game _developGame() {\n'
          '  throw UnimplementedError();\n'
          '}\n\n'
          'void main() {}\n',
        );
        final errors = <String>[];
        final exitCode =
            runCheckAiPhasePlannerNwSuppressionTestSharedFixtures(
              temp.path,
              info: (_) {},
              err: errors.add,
            );
        expect(exitCode, 1);
        expect(errors.join('\n'), contains('_developGame'));
        expect(
          errors.join('\n'),
          contains('buildDevelopPhaseNwSuppressionGame'),
        );
      } finally {
        temp.deleteSync(recursive: true);
      }
    });

    test('passes when NW-suppression pins import shared builders', () {
      final temp = Directory.systemTemp.createTempSync('ai-nw-ok-');
      try {
        _writeSupportStub(temp);
        _writeExpandTest(
          temp,
          "import 'package:test/test.dart';\n"
          "import '../support/phase_planner_nw_suppression_test_support.dart';\n\n"
          'void main() {\n'
          '  final game = buildExpandPhaseNwSuppressionGame();\n'
          '  final snap = buildExpandPhaseNwSuppressionSnapshot();\n'
          '  expect(game.players, isNotEmpty);\n'
          '  expect(snap.playerId, isNotEmpty);\n'
          '}\n',
        );
        _writeDevelopTest(
          temp,
          "import 'package:test/test.dart';\n"
          "import '../support/phase_planner_nw_suppression_test_support.dart';\n\n"
          'void main() {\n'
          '  final game = buildDevelopPhaseNwSuppressionGame();\n'
          '  final snap = buildDevelopPhaseNwSuppressionSnapshot();\n'
          '  expect(game.players, isNotEmpty);\n'
          '  expect(snap.playerId, isNotEmpty);\n'
          '}\n',
        );
        final exitCode =
            runCheckAiPhasePlannerNwSuppressionTestSharedFixtures(
              temp.path,
              info: (_) {},
              err: (_) {},
            );
        expect(exitCode, 0);
      } finally {
        temp.deleteSync(recursive: true);
      }
    });

    test('fails when the shared support file is missing', () {
      final temp = Directory.systemTemp.createTempSync('ai-nw-missing-');
      try {
        final exitCode =
            runCheckAiPhasePlannerNwSuppressionTestSharedFixtures(
              temp.path,
              info: (_) {},
              err: (_) {},
            );
        expect(exitCode, 1);
      } finally {
        temp.deleteSync(recursive: true);
      }
    });
  });
}

void _writeSupportStub(Directory temp) {
  final support = Directory(
    p.join(temp.path, 'packages', 'colonizethis_ai', 'test', 'support'),
  )..createSync(recursive: true);
  File(
    p.join(support.path, 'phase_planner_nw_suppression_test_support.dart'),
  ).writeAsStringSync(
    'Object buildExpandPhaseNwSuppressionGame() => Object();\n'
    'Object buildExpandPhaseNwSuppressionSnapshot() => Object();\n'
    'Object buildDevelopPhaseNwSuppressionGame() => Object();\n'
    'Object buildDevelopPhaseNwSuppressionSnapshot() => Object();\n',
  );
}

void _writeExpandTest(Directory temp, String body) {
  final planning = Directory(
    p.join(temp.path, 'packages', 'colonizethis_ai', 'test', 'planning'),
  )..createSync(recursive: true);
  File(
    p.join(planning.path, 'expand_phase_planner_nw_suppression_test.dart'),
  ).writeAsStringSync(body);
}

void _writeDevelopTest(Directory temp, String body) {
  final planning = Directory(
    p.join(temp.path, 'packages', 'colonizethis_ai', 'test', 'planning'),
  )..createSync(recursive: true);
  File(
    p.join(planning.path, 'develop_phase_planner_nw_suppression_test.dart'),
  ).writeAsStringSync(body);
}
