import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:test/test.dart';

import '../tool/check_ai_colonial_acquisition_test_shared_fixtures.dart';

const String _localAcquisitionGameBody =
    "import 'package:test/test.dart';\n\n"
    'Game _acquisitionGame({required int treasury}) {\n'
    '  throw UnimplementedError();\n'
    '}\n\n'
    'void main() {}\n';

const String _localFriendlyBody =
    "import 'package:test/test.dart';\n\n"
    'DiplomacyRelation _friendly(String a, String b) {\n'
    '  throw UnimplementedError();\n'
    '}\n\n'
    'void main() {}\n';

const String _sharedImportBody =
    "import 'package:test/test.dart';\n"
    "import '../support/colonial_acquisition_test_support.dart';\n\n"
    'void main() {\n'
    '  final game = buildColonialAcquisitionGame();\n'
    '  expect(game.players, isNotEmpty);\n'
    '}\n';

void main() {
  group('runCheckAiColonialAcquisitionTestSharedFixtures', () {
    test('fails when an acquisition pin redeclares _acquisitionGame', () {
      final temp = Directory.systemTemp.createTempSync('ai-acq-game-');
      try {
        _writeSupportStub(temp);
        _writeAcquisitionTest(
          temp,
          'colony_test.dart',
          _localAcquisitionGameBody,
        );

        final errors = <String>[];
        final exitCode = runCheckAiColonialAcquisitionTestSharedFixtures(
          temp.path,
          info: (_) {},
          err: errors.add,
        );
        expect(exitCode, 1);
        expect(errors.join('\n'), contains('_acquisitionGame'));
        expect(errors.join('\n'), contains('buildColonialAcquisitionGame'));
      } finally {
        temp.deleteSync(recursive: true);
      }
    });

    test('fails when an acquisition pin redeclares _friendly', () {
      final temp = Directory.systemTemp.createTempSync('ai-acq-friendly-');
      try {
        _writeSupportStub(temp);
        _writeAcquisitionTest(temp, 'colony_test.dart', _localFriendlyBody);

        final errors = <String>[];
        final exitCode = runCheckAiColonialAcquisitionTestSharedFixtures(
          temp.path,
          info: (_) {},
          err: errors.add,
        );
        expect(exitCode, 1);
        expect(errors.join('\n'), contains('_friendly'));
        expect(errors.join('\n'), contains('colonialAcquisitionFriendly'));
      } finally {
        temp.deleteSync(recursive: true);
      }
    });

    test('passes when pins import the shared acquisition support', () {
      final temp = Directory.systemTemp.createTempSync('ai-acq-ok-');
      try {
        _writeSupportStub(temp);
        _writeAcquisitionTest(temp, 'colony_test.dart', _sharedImportBody);

        final exitCode = runCheckAiColonialAcquisitionTestSharedFixtures(
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
      final temp = Directory.systemTemp.createTempSync('ai-acq-missing-');
      try {
        final exitCode = runCheckAiColonialAcquisitionTestSharedFixtures(
          temp.path,
          info: (_) {},
          err: (_) {},
        );
        expect(exitCode, 1);
      } finally {
        temp.deleteSync(recursive: true);
      }
    });

    test('ignores non-acquisition colonial planner test files', () {
      final temp = Directory.systemTemp.createTempSync('ai-acq-ignore-');
      try {
        _writeSupportStub(temp);
        final planning = Directory(
          p.join(temp.path, 'packages', 'colonizethis_ai', 'test', 'planning'),
        )..createSync(recursive: true);
        File(
          p.join(planning.path, 'colonial_phase_planner_military_test.dart'),
        ).writeAsStringSync(_localAcquisitionGameBody);

        final exitCode = runCheckAiColonialAcquisitionTestSharedFixtures(
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
  final support = Directory(
    p.join(temp.path, 'packages', 'colonizethis_ai', 'test', 'support'),
  )..createSync(recursive: true);
  File(
    p.join(support.path, 'colonial_acquisition_test_support.dart'),
  ).writeAsStringSync(
    'Game buildColonialAcquisitionGame() => throw UnimplementedError();\n',
  );
}

void _writeAcquisitionTest(Directory temp, String name, String body) {
  final planning = Directory(
    p.join(temp.path, 'packages', 'colonizethis_ai', 'test', 'planning'),
  )..createSync(recursive: true);
  File(
    p.join(planning.path, 'colonial_phase_planner_acquisition_$name'),
  ).writeAsStringSync(body);
}
