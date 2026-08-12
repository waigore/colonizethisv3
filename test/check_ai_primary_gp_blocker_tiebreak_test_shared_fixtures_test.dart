import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:test/test.dart';

import '../tool/check_ai_primary_gp_blocker_tiebreak_test_shared_fixtures.dart';

void main() {
  group('runCheckAiPrimaryGpBlockerTiebreakTestSharedFixtures', () {
    test('fails when contract redeclares _gameForOwBlocker', () {
      final temp = Directory.systemTemp.createTempSync('ai-pgbt-ow-');
      try {
        _writeSupport(temp);
        _writeAdopter(
          temp,
          'primary_gp_blocker_tiebreak_test.dart',
          'Game _gameForOwBlocker(List<Province> p) {\n'
          '  throw UnimplementedError();\n'
          '}\n',
        );
        final errors = <String>[];
        final code = runCheckAiPrimaryGpBlockerTiebreakTestSharedFixtures(
          temp.path,
          info: (_) {},
          err: errors.add,
        );
        expect(code, 1);
        expect(errors.join('\n'), contains('_gameForOwBlocker'));
      } finally {
        temp.deleteSync(recursive: true);
      }
    });

    test('fails when contract redeclares _gameForNwBlocker', () {
      final temp = Directory.systemTemp.createTempSync('ai-pgbt-nw-');
      try {
        _writeSupport(temp);
        _writeAdopter(
          temp,
          'primary_gp_blocker_tiebreak_test.dart',
          'Game _gameForNwBlocker(List<Province> p) {\n'
          '  throw UnimplementedError();\n'
          '}\n',
        );
        final errors = <String>[];
        final code = runCheckAiPrimaryGpBlockerTiebreakTestSharedFixtures(
          temp.path,
          info: (_) {},
          err: errors.add,
        );
        expect(code, 1);
        expect(errors.join('\n'), contains('_gameForNwBlocker'));
      } finally {
        temp.deleteSync(recursive: true);
      }
    });

    test('fails when contract redeclares _expandSnapshotForOw', () {
      final temp = Directory.systemTemp.createTempSync('ai-pgbt-exp-');
      try {
        _writeSupport(temp);
        _writeAdopter(
          temp,
          'primary_gp_blocker_tiebreak_test.dart',
          'AIWorldSnapshot _expandSnapshotForOw({required List<String> i}) {\n'
          '  throw UnimplementedError();\n'
          '}\n',
        );
        final errors = <String>[];
        final code = runCheckAiPrimaryGpBlockerTiebreakTestSharedFixtures(
          temp.path,
          info: (_) {},
          err: errors.add,
        );
        expect(code, 1);
        expect(errors.join('\n'), contains('_expandSnapshotForOw'));
      } finally {
        temp.deleteSync(recursive: true);
      }
    });

    test('fails when contract redeclares _colonialSnapshotForNw', () {
      final temp = Directory.systemTemp.createTempSync('ai-pgbt-col-');
      try {
        _writeSupport(temp);
        _writeAdopter(
          temp,
          'primary_gp_blocker_tiebreak_test.dart',
          'AIWorldSnapshot _colonialSnapshotForNw({required List<String> i}) {\n'
          '  throw UnimplementedError();\n'
          '}\n',
        );
        final errors = <String>[];
        final code = runCheckAiPrimaryGpBlockerTiebreakTestSharedFixtures(
          temp.path,
          info: (_) {},
          err: errors.add,
        );
        expect(code, 1);
        expect(errors.join('\n'), contains('_colonialSnapshotForNw'));
      } finally {
        temp.deleteSync(recursive: true);
      }
    });

    test('passes when adopters use shared factories', () {
      final temp = Directory.systemTemp.createTempSync('ai-pgbt-ok-');
      try {
        _writeSupport(temp);
        _writeAdopter(
          temp,
          'primary_gp_blocker_tiebreak_test.dart',
          "import '../support/primary_gp_blocker_tiebreak_test_support.dart';\n",
        );
        final code = runCheckAiPrimaryGpBlockerTiebreakTestSharedFixtures(
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
      final temp = Directory.systemTemp.createTempSync('ai-pgbt-miss-');
      try {
        final code = runCheckAiPrimaryGpBlockerTiebreakTestSharedFixtures(
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
    p.join(support.path, 'primary_gp_blocker_tiebreak_test_support.dart'),
  ).writeAsStringSync('// stub\n');
}

void _writeAdopter(Directory temp, String name, String body) {
  final planning = Directory(
    p.join(temp.path, 'packages', 'colonizethis_ai', 'test', 'planning'),
  )..createSync(recursive: true);
  File(p.join(planning.path, name)).writeAsStringSync(body);
}
