import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:test/test.dart';

import '../tool/check_ai_phase_priority_weights_test_shared_fixtures.dart';

void main() {
  group('runCheckAiPhasePriorityWeightsTestSharedFixtures', () {
    test('fails when adopter redeclares _gameWithRegiments', () {
      final temp = Directory.systemTemp.createTempSync('ai-ppw-reg-');
      try {
        _writeSupport(temp);
        _writeAdopter(
          temp,
          'phase_priority_weights_curve_cases.dart',
          'Game _gameWithRegiments(int c) {\n'
          '  throw UnimplementedError();\n'
          '}\n',
        );
        final errors = <String>[];
        final code = runCheckAiPhasePriorityWeightsTestSharedFixtures(
          temp.path,
          info: (_) {},
          err: errors.add,
        );
        expect(code, 1);
        expect(errors.join('\n'), contains('_gameWithRegiments'));
      } finally {
        temp.deleteSync(recursive: true);
      }
    });

    test('fails when adopter redeclares _snapshot', () {
      final temp = Directory.systemTemp.createTempSync('ai-ppw-snap-');
      try {
        _writeSupport(temp);
        _writeAdopter(
          temp,
          'phase_priority_weights_override_cases.dart',
          'AIWorldSnapshot _snapshot({required int oldWorldProvincesOwned}) {\n'
          '  throw UnimplementedError();\n'
          '}\n',
        );
        final errors = <String>[];
        final code = runCheckAiPhasePriorityWeightsTestSharedFixtures(
          temp.path,
          info: (_) {},
          err: errors.add,
        );
        expect(code, 1);
        expect(errors.join('\n'), contains('_snapshot'));
      } finally {
        temp.deleteSync(recursive: true);
      }
    });

    test('passes when adopters use shared factories', () {
      final temp = Directory.systemTemp.createTempSync('ai-ppw-ok-');
      try {
        _writeSupport(temp);
        _writeAdopter(
          temp,
          'phase_priority_weights_curve_cases.dart',
          "import '../support/phase_priority_weights_test_support.dart';\n",
        );
        _writeAdopter(
          temp,
          'phase_priority_weights_override_cases.dart',
          "import '../support/phase_priority_weights_test_support.dart';\n",
        );
        final code = runCheckAiPhasePriorityWeightsTestSharedFixtures(
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
      final temp = Directory.systemTemp.createTempSync('ai-ppw-miss-');
      try {
        final code = runCheckAiPhasePriorityWeightsTestSharedFixtures(
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
    p.join(support.path, 'phase_priority_weights_test_support.dart'),
  ).writeAsStringSync('// stub\n');
}

void _writeAdopter(Directory temp, String name, String body) {
  final planning = Directory(
    p.join(temp.path, 'packages', 'colonizethis_ai', 'test', 'planning'),
  )..createSync(recursive: true);
  File(p.join(planning.path, name)).writeAsStringSync(body);
}
