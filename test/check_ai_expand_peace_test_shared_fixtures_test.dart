import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:test/test.dart';

import '../tool/check_ai_expand_peace_test_shared_fixtures.dart';

const String _localOwnSnapshotBody =
    "import 'package:test/test.dart';\n\n"
    'AIWorldSnapshot _ownSnapshot({\n'
    '  required int oldWorldProvincesOwned,\n'
    '  required List<String> atWarWith,\n'
    '}) {\n'
    '  throw UnimplementedError();\n'
    '}\n\n'
    'void main() {}\n';

const String _localCriticalGameBody =
    "import 'package:test/test.dart';\n\n"
    'Game _criticalGame({required int ownProvinces}) {\n'
    '  throw UnimplementedError();\n'
    '}\n\n'
    'void main() {}\n';

const String _sharedImportBody =
    "import 'package:test/test.dart';\n"
    "import '../support/expand_phase_peace_test_support.dart';\n\n"
    'void main() {\n'
    '  final snap = ownSnapshot(\n'
    '    oldWorldProvincesOwned: 1,\n'
    "    atWarWith: const <String>['gp_rival'],\n"
    '  );\n'
    '  expect(snap.playerId, kExpandPeaceGpOwn);\n'
    '}\n';

void main() {
  group('runCheckAiExpandPeaceTestSharedFixtures', () {
    test('fails when an expand-peace pin redeclares _ownSnapshot', () {
      final temp = Directory.systemTemp.createTempSync('ai-peace-snap-');
      try {
        _writeSupportStub(temp);
        _writeExpandPeaceTest(
          temp,
          'critical_peace_test.dart',
          _localOwnSnapshotBody,
        );

        final errors = <String>[];
        final exitCode = runCheckAiExpandPeaceTestSharedFixtures(
          temp.path,
          info: (_) {},
          err: errors.add,
        );
        expect(exitCode, 1);
        expect(errors.join('\n'), contains('_ownSnapshot'));
        expect(errors.join('\n'), contains('ownSnapshot'));
      } finally {
        temp.deleteSync(recursive: true);
      }
    });

    test('fails when an expand-peace pin redeclares _criticalGame', () {
      final temp = Directory.systemTemp.createTempSync('ai-peace-crit-');
      try {
        _writeSupportStub(temp);
        _writeExpandPeaceTest(
          temp,
          'critical_peace_test.dart',
          _localCriticalGameBody,
        );

        final errors = <String>[];
        final exitCode = runCheckAiExpandPeaceTestSharedFixtures(
          temp.path,
          info: (_) {},
          err: errors.add,
        );
        expect(exitCode, 1);
        expect(errors.join('\n'), contains('_criticalGame'));
        expect(errors.join('\n'), contains('buildCriticalExpandPeaceGame'));
      } finally {
        temp.deleteSync(recursive: true);
      }
    });

    test('passes when pins import the shared expand-peace support', () {
      final temp = Directory.systemTemp.createTempSync('ai-peace-ok-');
      try {
        _writeSupportStub(temp);
        _writeExpandPeaceTest(
          temp,
          'critical_peace_test.dart',
          _sharedImportBody,
        );

        final exitCode = runCheckAiExpandPeaceTestSharedFixtures(
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
      final temp = Directory.systemTemp.createTempSync('ai-peace-missing-');
      try {
        final exitCode = runCheckAiExpandPeaceTestSharedFixtures(
          temp.path,
          info: (_) {},
          err: (_) {},
        );
        expect(exitCode, 1);
      } finally {
        temp.deleteSync(recursive: true);
      }
    });

    test('ignores non-peace expand_phase_planner test files', () {
      final temp = Directory.systemTemp.createTempSync('ai-peace-ignore-');
      try {
        _writeSupportStub(temp);
        final planning = Directory(
          p.join(temp.path, 'packages', 'colonizethis_ai', 'test', 'planning'),
        )..createSync(recursive: true);
        File(
          p.join(planning.path, 'expand_phase_planner_declare_war_test.dart'),
        ).writeAsStringSync(_localOwnSnapshotBody);

        final exitCode = runCheckAiExpandPeaceTestSharedFixtures(
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
    p.join(support.path, 'expand_phase_peace_test_support.dart'),
  ).writeAsStringSync(
    "const String kExpandPeaceGpOwn = 'gp_own';\n"
    'Object ownSnapshot({required int oldWorldProvincesOwned, '
    'required List<String> atWarWith}) => Object();\n',
  );
}

void _writeExpandPeaceTest(Directory temp, String name, String body) {
  final planning = Directory(
    p.join(temp.path, 'packages', 'colonizethis_ai', 'test', 'planning'),
  )..createSync(recursive: true);
  File(
    p.join(planning.path, 'expand_phase_planner_$name'),
  ).writeAsStringSync(body);
}
