import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:test/test.dart';

import '../tool/check_ai_mutual_exhausted_stalemate_test_shared_fixtures.dart';

void main() {
  group('runCheckAiMutualExhaustedStalemateTestSharedFixtures', () {
    test('fails when adopter redeclares _exhaustedStalemateGame', () {
      final temp = Directory.systemTemp.createTempSync('ai-mes-game-');
      try {
        _writeSupport(temp);
        _writeAdopter(
          temp,
          'diplomacy_planner_mutual_exhausted_peace_targets_cases.dart',
          'Game _exhaustedStalemateGame() {\n'
          '  throw UnimplementedError();\n'
          '}\n',
        );
        final errors = <String>[];
        final code = runCheckAiMutualExhaustedStalemateTestSharedFixtures(
          temp.path,
          info: (_) {},
          err: errors.add,
        );
        expect(code, 1);
        expect(errors.join('\n'), contains('_exhaustedStalemateGame'));
      } finally {
        temp.deleteSync(recursive: true);
      }
    });

    test('fails when adopter redeclares _snapshotForOwn', () {
      final temp = Directory.systemTemp.createTempSync('ai-mes-snap-');
      try {
        _writeSupport(temp);
        _writeAdopter(
          temp,
          'diplomatic_candidate_scoring_mutual_exhausted_offer_peace_test.dart',
          'AIWorldSnapshot _snapshotForOwn() {\n'
          '  throw UnimplementedError();\n'
          '}\n',
        );
        final errors = <String>[];
        final code = runCheckAiMutualExhaustedStalemateTestSharedFixtures(
          temp.path,
          info: (_) {},
          err: errors.add,
        );
        expect(code, 1);
        expect(errors.join('\n'), contains('_snapshotForOwn'));
      } finally {
        temp.deleteSync(recursive: true);
      }
    });

    test('passes when adopters use shared factories', () {
      final temp = Directory.systemTemp.createTempSync('ai-mes-ok-');
      try {
        _writeSupport(temp);
        _writeAdopter(
          temp,
          'diplomacy_planner_mutual_exhausted_peace_wiring_cases.dart',
          "import '../support/mutual_exhausted_stalemate_test_support.dart';\n",
        );
        final code = runCheckAiMutualExhaustedStalemateTestSharedFixtures(
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
      final temp = Directory.systemTemp.createTempSync('ai-mes-miss-');
      try {
        final code = runCheckAiMutualExhaustedStalemateTestSharedFixtures(
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
    p.join(support.path, 'mutual_exhausted_stalemate_test_support.dart'),
  ).writeAsStringSync('// stub\n');
}

void _writeAdopter(Directory temp, String name, String body) {
  final planning = Directory(
    p.join(temp.path, 'packages', 'colonizethis_ai', 'test', 'planning'),
  )..createSync(recursive: true);
  File(p.join(planning.path, name)).writeAsStringSync(body);
}
