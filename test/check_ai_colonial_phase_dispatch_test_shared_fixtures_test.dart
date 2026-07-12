import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:test/test.dart';

import '../tool/check_ai_colonial_phase_dispatch_test_shared_fixtures.dart';

const String _localColonialLiteBody =
    "import 'package:test/test.dart';\n\n"
    'Game _colonialLiteGame() {\n'
    '  throw UnimplementedError();\n'
    '}\n\n'
    'void main() {}\n';

const String _sharedImportBody =
    "import 'package:test/test.dart';\n"
    "import '../support/colonial_phase_planner_test_support.dart';\n\n"
    'void main() {\n'
    '  final game = buildPhasePlannerDispatchColonialLiteGame();\n'
    '  expect(game.players, isNotEmpty);\n'
    '}\n';

void main() {
  group('runCheckAiColonialPhaseDispatchTestSharedFixtures', () {
    test('fails when dispatch redeclares _colonialLiteGame', () {
      final temp = Directory.systemTemp.createTempSync('ai-disp-lite-');
      try {
        _writeSupportStub(temp);
        _writeDispatchTest(temp, _localColonialLiteBody);
        final errors = <String>[];
        final exitCode = runCheckAiColonialPhaseDispatchTestSharedFixtures(
          temp.path,
          info: (_) {},
          err: errors.add,
        );
        expect(exitCode, 1);
        expect(errors.join('\n'), contains('_colonialLiteGame'));
        expect(
          errors.join('\n'),
          contains('buildPhasePlannerDispatchColonialLiteGame'),
        );
      } finally {
        temp.deleteSync(recursive: true);
      }
    });

    test('passes when dispatch imports shared colonial support', () {
      final temp = Directory.systemTemp.createTempSync('ai-disp-ok-');
      try {
        _writeSupportStub(temp);
        _writeDispatchTest(temp, _sharedImportBody);
        final exitCode = runCheckAiColonialPhaseDispatchTestSharedFixtures(
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
      final temp = Directory.systemTemp.createTempSync('ai-disp-missing-');
      try {
        final exitCode = runCheckAiColonialPhaseDispatchTestSharedFixtures(
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
    p.join(support.path, 'colonial_phase_planner_test_support.dart'),
  ).writeAsStringSync(
    'Object buildPhasePlannerDispatchColonialLiteGame() => Object();\n'
    'Object buildPhasePlannerDispatchColonialGame() => Object();\n',
  );
}

void _writeDispatchTest(Directory temp, String body) {
  final planning = Directory(
    p.join(temp.path, 'packages', 'colonizethis_ai', 'test', 'planning'),
  )..createSync(recursive: true);
  File(
    p.join(planning.path, 'phase_planner_dispatch_test.dart'),
  ).writeAsStringSync(body);
}
