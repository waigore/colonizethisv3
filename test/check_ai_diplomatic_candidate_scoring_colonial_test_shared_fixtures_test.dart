import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:test/test.dart';

import '../tool/check_ai_diplomatic_candidate_scoring_colonial_test_shared_fixtures.dart';

void main() {
  group('runCheckAiDiplomaticCandidateScoringColonialTestSharedFixtures', () {
    test('fails when adopter redeclares _colonialScenarioGame', () {
      final temp = Directory.systemTemp.createTempSync('ai-dip-colonial-1-');
      try {
        _writeSupport(temp);
        _writeAdopter(
          temp,
          'diplomatic_candidate_scoring_personality_colonial_divergence_test.dart',
          'Game _colonialScenarioGame() {\n'
          '  throw UnimplementedError();\n'
          '}\n',
        );
        final errors = <String>[];
        final code =
            runCheckAiDiplomaticCandidateScoringColonialTestSharedFixtures(
          temp.path,
          info: (_) {},
          err: errors.add,
        );
        expect(code, 1);
        expect(errors.join('\n'), contains('_colonialScenarioGame'));
      } finally {
        temp.deleteSync(recursive: true);
      }
    });

    test('fails when adopter redeclares _colonialTribeScenarioGame', () {
      final temp = Directory.systemTemp.createTempSync('ai-dip-colonial-2-');
      try {
        _writeSupport(temp);
        _writeAdopter(
          temp,
          'diplomatic_candidate_scoring_intervention_tribe_tolerance_test.dart',
          'Game _colonialTribeScenarioGame({required List overtureStates}) {\n'
          '  throw UnimplementedError();\n'
          '}\n',
        );
        final errors = <String>[];
        final code =
            runCheckAiDiplomaticCandidateScoringColonialTestSharedFixtures(
          temp.path,
          info: (_) {},
          err: errors.add,
        );
        expect(code, 1);
        expect(errors.join('\n'), contains('_colonialTribeScenarioGame'));
      } finally {
        temp.deleteSync(recursive: true);
      }
    });

    test('passes when adopters use shared factories', () {
      final temp = Directory.systemTemp.createTempSync('ai-dip-colonial-ok-');
      try {
        _writeSupport(temp);
        _writeAdopter(
          temp,
          'diplomatic_candidate_scoring_personality_colonial_divergence_test.dart',
          "import '../support/diplomatic_candidate_scoring_colonial_test_support.dart';\n",
        );
        final code =
            runCheckAiDiplomaticCandidateScoringColonialTestSharedFixtures(
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
      final temp = Directory.systemTemp.createTempSync('ai-dip-colonial-miss-');
      try {
        final code =
            runCheckAiDiplomaticCandidateScoringColonialTestSharedFixtures(
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
      'diplomatic_candidate_scoring_colonial_test_support.dart',
    ),
  ).writeAsStringSync('// stub\n');
}

void _writeAdopter(Directory temp, String name, String body) {
  final planning = Directory(
    p.join(temp.path, 'packages', 'colonizethis_ai', 'test', 'planning'),
  )..createSync(recursive: true);
  File(p.join(planning.path, name)).writeAsStringSync(body);
}
