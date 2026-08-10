import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:test/test.dart';

import '../tool/check_ai_planning_peace_collectors_test_shared_fixtures.dart';

void main() {
  group('runCheckAiPlanningPeaceCollectorsTestSharedFixtures', () {
    test('fails when cases redeclare _gameWithGps', () {
      final temp = Directory.systemTemp.createTempSync('ai-peace-gps-');
      try {
        _writeSupport(temp);
        _writeAdopter(
          temp,
          'planning_peace_collectors_gp_cases.dart',
          'Game _gameWithGps() {\n'
          '  throw UnimplementedError();\n'
          '}\n',
        );
        final errors = <String>[];
        final code = runCheckAiPlanningPeaceCollectorsTestSharedFixtures(
          temp.path,
          info: (_) {},
          err: errors.add,
        );
        expect(code, 1);
        expect(errors.join('\n'), contains('_gameWithGps'));
      } finally {
        temp.deleteSync(recursive: true);
      }
    });

    test('fails when cases redeclare _snapshotWithAtWar', () {
      final temp = Directory.systemTemp.createTempSync('ai-peace-snap-');
      try {
        _writeSupport(temp);
        _writeAdopter(
          temp,
          'planning_peace_collectors_non_gp_cases.dart',
          'AIWorldSnapshot _snapshotWithAtWar(List<String> atWarWith) {\n'
          '  throw UnimplementedError();\n'
          '}\n',
        );
        final errors = <String>[];
        final code = runCheckAiPlanningPeaceCollectorsTestSharedFixtures(
          temp.path,
          info: (_) {},
          err: errors.add,
        );
        expect(code, 1);
        expect(errors.join('\n'), contains('_snapshotWithAtWar'));
      } finally {
        temp.deleteSync(recursive: true);
      }
    });

    test('passes when adopters use shared factories', () {
      final temp = Directory.systemTemp.createTempSync('ai-peace-ok-');
      try {
        _writeSupport(temp);
        _writeAdopter(
          temp,
          'planning_peace_collectors_gp_cases.dart',
          "import '../support/planning_peace_collectors_test_support.dart';\n",
        );
        final code = runCheckAiPlanningPeaceCollectorsTestSharedFixtures(
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
      final temp = Directory.systemTemp.createTempSync('ai-peace-miss-');
      try {
        final code = runCheckAiPlanningPeaceCollectorsTestSharedFixtures(
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
    p.join(support.path, 'planning_peace_collectors_test_support.dart'),
  ).writeAsStringSync('// stub\n');
}

void _writeAdopter(Directory temp, String name, String body) {
  final planning = Directory(
    p.join(temp.path, 'packages', 'colonizethis_ai', 'test', 'planning'),
  )..createSync(recursive: true);
  File(p.join(planning.path, name)).writeAsStringSync(body);
}
