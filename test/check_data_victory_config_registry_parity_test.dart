import 'dart:io';

import 'package:test/test.dart';

import '../tool/check_data_victory_config_registry_parity.dart';

const _srcRel = 'packages/colonizethis_data/lib/src';

void main() {
  group('victoryConfigRegistryParityViolations', () {
    test('empty when source consts and params match exactly', () {
      expect(
        victoryConfigRegistryParityViolations(
          sourceConsts: {'kA', 'kB'},
          registeredParams: {'kA', 'kB'},
        ),
        isEmpty,
      );
    });

    test('reports consts missing from registry (positive gap)', () {
      final violations = victoryConfigRegistryParityViolations(
        sourceConsts: {'kA', 'kMissing'},
        registeredParams: {'kA'},
      );
      expect(violations, hasLength(1));
      expect(violations.single, contains('kMissing'));
      expect(violations.single, contains('no victoryConfigParams entry'));
    });

    test('reports orphan params without matching consts (negative gap)', () {
      final violations = victoryConfigRegistryParityViolations(
        sourceConsts: {'kA'},
        registeredParams: {'kA', 'kOrphan'},
      );
      expect(violations, hasLength(1));
      expect(violations.single, contains('kOrphan'));
      expect(violations.single, contains('no matching'));
    });
  });

  group('source scanners', () {
    test('extracts const int/double k* and ignores Maps / strings', () {
      const source = '''
const int kFoo = 1;
const double kBar = 2.0;
const String kSkip = 'x';
const Map<String, int> kCivilianBuildMinCountByType = {};
  const int kIndented = 3;
''';
      expect(victoryConfigScalarConstNamesFromSources([source]), {
        'kFoo',
        'kBar',
        'kIndented',
      });
    });

    test('extracts victoryConfigInt/DoubleParam string names', () {
      const source = '''
victoryConfigIntParam(
  'kAlpha',
  kAlpha,
  'desc',
),
victoryConfigDoubleParam('kBeta', kBeta, 'desc'),
''';
      expect(victoryConfigParamNamesFromSources([source]), {'kAlpha', 'kBeta'});
    });
  });

  group('runCheckDataVictoryConfigRegistryParity', () {
    test('passes for the real colonizethis_data victory-config tree', () {
      final logs = <String>[];
      final code = runCheckDataVictoryConfigRegistryParity(
        Directory.current.path,
        info: logs.add,
        err: logs.add,
      );
      expect(
        code,
        0,
        reason:
            'victory-config scalars must match victoryConfigParams '
            '(Refs #4072).\n${logs.join('\n')}',
      );
      expect(logs.join('\n'), contains('scalars match'));
    });

    test('fails when a scalar const lacks a param entry', () {
      final temp = Directory.systemTemp.createTempSync(
        'check_vc_registry_fail_',
      );
      addTearDown(() => temp.deleteSync(recursive: true));

      Directory('${temp.path}/$_srcRel').createSync(recursive: true);
      File('${temp.path}/$_srcRel/ai_victory_config.dart')
        ..createSync()
        ..writeAsStringSync('const int kOnlyInSource = 1;\n');
      File('${temp.path}/$_srcRel/ai_parameter_victory_config_params.dart')
        ..createSync()
        ..writeAsStringSync('final list = <dynamic>[];\n');

      final logs = <String>[];
      final code = runCheckDataVictoryConfigRegistryParity(
        temp.path,
        info: logs.add,
        err: logs.add,
      );
      expect(code, 1);
      expect(logs.join('\n'), contains('kOnlyInSource'));
    });

    test('fails when a param entry lacks a matching const', () {
      final temp = Directory.systemTemp.createTempSync(
        'check_vc_registry_orphan_',
      );
      addTearDown(() => temp.deleteSync(recursive: true));

      Directory('${temp.path}/$_srcRel').createSync(recursive: true);
      File('${temp.path}/$_srcRel/ai_victory_config.dart')
        ..createSync()
        ..writeAsStringSync('const int kKept = 1;\n');
      File('${temp.path}/$_srcRel/ai_parameter_victory_config_params_work.dart')
        ..createSync()
        ..writeAsStringSync(
          "victoryConfigIntParam('kKept', kKept, 'ok'),\n"
          "victoryConfigIntParam('kOrphan', 0, 'orphan'),\n",
        );

      final logs = <String>[];
      final code = runCheckDataVictoryConfigRegistryParity(
        temp.path,
        info: logs.add,
        err: logs.add,
      );
      expect(code, 1);
      expect(logs.join('\n'), contains('kOrphan'));
    });
  });
}
