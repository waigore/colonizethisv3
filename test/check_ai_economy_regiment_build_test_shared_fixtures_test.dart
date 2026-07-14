import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:test/test.dart';

import '../tool/check_ai_economy_regiment_build_test_shared_fixtures.dart';

const String _localRegimentRebuildBody =
    "import 'package:test/test.dart';\n\n"
    'Game _regimentRebuildProductionGame({required int treasury}) {\n'
    '  throw UnimplementedError();\n'
    '}\n\n'
    'void main() {}\n';

const String _localCastIronBody =
    "import 'package:test/test.dart';\n\n"
    'Game _castIronImprovementInputGame({required int treasury}) {\n'
    '  throw UnimplementedError();\n'
    '}\n\n'
    'void main() {}\n';

const String _sharedImportBody =
    "import 'package:test/test.dart';\n"
    "import 'economy_planner_regiment_build_input_support.dart';\n\n"
    'void main() {\n'
    '  final game = regimentRebuildProductionGame(treasury: 1);\n'
    '  expect(game.players, isNotEmpty);\n'
    '}\n';

void main() {
  group('runCheckAiEconomyRegimentBuildTestSharedFixtures', () {
    test('fails when a pin redeclares _regimentRebuildProductionGame', () {
      final temp = Directory.systemTemp.createTempSync('ai-econ-rebuild-');
      try {
        _writeSupportStub(temp);
        _writeEconomyRegimentTest(
          temp,
          'input_production_test.dart',
          _localRegimentRebuildBody,
        );

        final errors = <String>[];
        final exitCode = runCheckAiEconomyRegimentBuildTestSharedFixtures(
          temp.path,
          info: (_) {},
          err: errors.add,
        );
        expect(exitCode, 1);
        expect(errors.join('\n'), contains('_regimentRebuildProductionGame'));
        expect(errors.join('\n'), contains('regimentRebuildProductionGame'));
      } finally {
        temp.deleteSync(recursive: true);
      }
    });

    test('fails when a pin redeclares _castIronImprovementInputGame', () {
      final temp = Directory.systemTemp.createTempSync('ai-econ-castiron-');
      try {
        _writeSupportStub(temp);
        _writeEconomyRegimentTest(
          temp,
          'input_production_test.dart',
          _localCastIronBody,
        );

        final errors = <String>[];
        final exitCode = runCheckAiEconomyRegimentBuildTestSharedFixtures(
          temp.path,
          info: (_) {},
          err: errors.add,
        );
        expect(exitCode, 1);
        expect(errors.join('\n'), contains('_castIronImprovementInputGame'));
        expect(errors.join('\n'), contains('castIronImprovementInputGame'));
      } finally {
        temp.deleteSync(recursive: true);
      }
    });

    test('passes when pins import the shared economy regiment support', () {
      final temp = Directory.systemTemp.createTempSync('ai-econ-ok-');
      try {
        _writeSupportStub(temp);
        _writeEconomyRegimentTest(
          temp,
          'input_production_test.dart',
          _sharedImportBody,
        );

        final exitCode = runCheckAiEconomyRegimentBuildTestSharedFixtures(
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
      final temp = Directory.systemTemp.createTempSync('ai-econ-missing-');
      try {
        final exitCode = runCheckAiEconomyRegimentBuildTestSharedFixtures(
          temp.path,
          info: (_) {},
          err: (_) {},
        );
        expect(exitCode, 1);
      } finally {
        temp.deleteSync(recursive: true);
      }
    });

    test('ignores non-economy-regiment planner test files', () {
      final temp = Directory.systemTemp.createTempSync('ai-econ-ignore-');
      try {
        _writeSupportStub(temp);
        final planning = Directory(
          p.join(temp.path, 'packages', 'colonizethis_ai', 'test', 'planning'),
        )..createSync(recursive: true);
        File(
          p.join(planning.path, 'economy_planner_other_test.dart'),
        ).writeAsStringSync(_localRegimentRebuildBody);

        final exitCode = runCheckAiEconomyRegimentBuildTestSharedFixtures(
          temp.path,
          info: (_) {},
          err: (_) {},
        );
        expect(exitCode, 0);
      } finally {
        temp.deleteSync(recursive: true);
      }
    });
  });
}

void _writeSupportStub(Directory temp) {
  final planning = Directory(
    p.join(temp.path, 'packages', 'colonizethis_ai', 'test', 'planning'),
  )..createSync(recursive: true);
  File(
    p.join(planning.path, 'economy_planner_regiment_build_input_support.dart'),
  ).writeAsStringSync(
    'Game regimentRebuildProductionGame({required int treasury}) =>\n'
    '    throw UnimplementedError();\n',
  );
}

void _writeEconomyRegimentTest(Directory temp, String name, String body) {
  final planning = Directory(
    p.join(temp.path, 'packages', 'colonizethis_ai', 'test', 'planning'),
  )..createSync(recursive: true);
  File(
    p.join(planning.path, 'economy_planner_regiment_build_$name'),
  ).writeAsStringSync(body);
}
