import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:test/test.dart';

import '../tool/check_ai_economy_satellite_test_shared_fixtures.dart';

void main() {
  group('runCheckAiEconomySatelliteTestSharedFixtures', () {
    test('fails when castiron pin redeclares _sellerGame', () {
      final temp = Directory.systemTemp.createTempSync('ai-econ-seller-');
      try {
        _writeSupport(temp);
        _writeAdopter(
          temp,
          'domain_planner_orchestrator_castiron_peasant_recruit_test.dart',
          'Game _sellerGame() {\n'
          '  throw UnimplementedError();\n'
          '}\n',
        );
        final errors = <String>[];
        final code = runCheckAiEconomySatelliteTestSharedFixtures(
          temp.path,
          info: (_) {},
          err: errors.add,
        );
        expect(code, 1);
        expect(errors.join('\n'), contains('_sellerGame'));
      } finally {
        temp.deleteSync(recursive: true);
      }
    });

    test('fails when cotton gate pin redeclares _cottonOnlyGame', () {
      final temp = Directory.systemTemp.createTempSync('ai-econ-cotton-');
      try {
        _writeSupport(temp);
        _writeAdopter(
          temp,
          'economy_planner_cotton_weaving_gate_test.dart',
          'Game _cottonOnlyGame({required int cotton}) {\n'
          '  throw UnimplementedError();\n'
          '}\n',
        );
        final errors = <String>[];
        final code = runCheckAiEconomySatelliteTestSharedFixtures(
          temp.path,
          info: (_) {},
          err: errors.add,
        );
        expect(code, 1);
        expect(errors.join('\n'), contains('_cottonOnlyGame'));
      } finally {
        temp.deleteSync(recursive: true);
      }
    });

    test('passes when adopters use shared factories', () {
      final temp = Directory.systemTemp.createTempSync('ai-econ-ok-');
      try {
        _writeSupport(temp);
        for (final name in economySatelliteSharedFixtureAdopterBasenames) {
          _writeAdopter(
            temp,
            name,
            "import '../support/economy_satellite_test_support.dart';\n",
          );
        }
        final code = runCheckAiEconomySatelliteTestSharedFixtures(
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
      final temp = Directory.systemTemp.createTempSync('ai-econ-miss-');
      try {
        final code = runCheckAiEconomySatelliteTestSharedFixtures(
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
    p.join(support.path, 'economy_satellite_test_support.dart'),
  ).writeAsStringSync('// stub\n');
}

void _writeAdopter(Directory temp, String name, String body) {
  final planning = Directory(
    p.join(temp.path, 'packages', 'colonizethis_ai', 'test', 'planning'),
  )..createSync(recursive: true);
  File(p.join(planning.path, name)).writeAsStringSync(body);
}
