import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:test/test.dart';

import '../tool/check_ai_treasury_satellite_test_shared_fixtures.dart';

void main() {
  group('runCheckAiTreasurySatelliteTestSharedFixtures', () {
    test('fails when forecasting redeclares _gameWithStockpile', () {
      final temp = Directory.systemTemp.createTempSync('ai-treasury-fc-');
      try {
        _writeSupports(temp);
        _writeAdopter(
          temp,
          'treasury_planner_forecasting_test.dart',
          "Game _gameWithStockpile({required int treasury}) {\n"
          '  throw UnimplementedError();\n'
          '}\n',
        );
        final errors = <String>[];
        final code = runCheckAiTreasurySatelliteTestSharedFixtures(
          temp.path,
          info: (_) {},
          err: errors.add,
        );
        expect(code, 1);
        expect(errors.join('\n'), contains('_gameWithStockpile'));
      } finally {
        temp.deleteSync(recursive: true);
      }
    });

    test('fails when boycott pin redeclares _game', () {
      final temp = Directory.systemTemp.createTempSync('ai-treasury-by-');
      try {
        _writeSupports(temp);
        _writeAdopter(
          temp,
          'treasury_planner_boycott_suppression_test.dart',
          'Game _game({required int treasury}) {\n'
          '  throw UnimplementedError();\n'
          '}\n',
        );
        final errors = <String>[];
        final code = runCheckAiTreasurySatelliteTestSharedFixtures(
          temp.path,
          info: (_) {},
          err: errors.add,
        );
        expect(code, 1);
        expect(errors.join('\n'), contains('_game'));
      } finally {
        temp.deleteSync(recursive: true);
      }
    });

    test('passes when pins use shared factories', () {
      final temp = Directory.systemTemp.createTempSync('ai-treasury-ok-');
      try {
        _writeSupports(temp);
        _writeAdopter(
          temp,
          'treasury_planner_forecasting_test.dart',
          "import 'treasury_planner_main_support.dart';\n",
        );
        _writeAdopter(
          temp,
          'treasury_planner_boycott_suppression_test.dart',
          "import 'treasury_planner_satellite_support.dart';\n",
        );
        final code = runCheckAiTreasurySatelliteTestSharedFixtures(
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
      final temp = Directory.systemTemp.createTempSync('ai-treasury-miss-');
      try {
        final code = runCheckAiTreasurySatelliteTestSharedFixtures(
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

void _writeSupports(Directory temp) {
  final planning = Directory(
    p.join(temp.path, 'packages', 'colonizethis_ai', 'test', 'planning'),
  )..createSync(recursive: true);
  File(
    p.join(planning.path, 'treasury_planner_satellite_support.dart'),
  ).writeAsStringSync('// stub\n');
  File(
    p.join(planning.path, 'treasury_planner_main_support.dart'),
  ).writeAsStringSync('// stub\n');
}

void _writeAdopter(Directory temp, String name, String body) {
  final planning = Directory(
    p.join(temp.path, 'packages', 'colonizethis_ai', 'test', 'planning'),
  )..createSync(recursive: true);
  File(p.join(planning.path, name)).writeAsStringSync(body);
}
