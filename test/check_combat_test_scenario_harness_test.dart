import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:test/test.dart';

import '../tool/check_combat_test_scenario_harness.dart';

void main() {
  group('runCheckCombatTestScenarioHarness', () {
    test('fails for a bare scenario for-loop in combat test', () {
      final temp = Directory.systemTemp.createTempSync('combat-harness-bare-');
      try {
        final testDir = Directory(
          p.join(
            temp.path,
            'packages',
            'colonizethis_combat',
            'test',
            'combat',
          ),
        )..createSync(recursive: true);
        File(p.join(testDir.path, 'demo_test.dart')).writeAsStringSync('''
void main() {
  group('demo', () {
    for (final scenario in demos()) {
      test(scenario.label, () => scenario.run());
    }
  });
}
''');

        final errors = <String>[];
        final exitCode = runCheckCombatTestScenarioHarness(
          temp.path,
          info: (_) {},
          err: errors.add,
        );
        expect(exitCode, 1);
        expect(errors.join('\n'), contains('demo_test.dart:3'));
      } finally {
        temp.deleteSync(recursive: true);
      }
    });

    test('passes when no bare scenario loops remain', () {
      final temp = Directory.systemTemp.createTempSync('combat-harness-ok-');
      try {
        final testDir = Directory(
          p.join(
            temp.path,
            'packages',
            'colonizethis_combat',
            'test',
            'combat',
          ),
        )..createSync(recursive: true);
        File(p.join(testDir.path, 'demo_test.dart')).writeAsStringSync('''
void main() {
  runLabeledScenarioGroup('demo', demos(), (s) => s.run());
}
''');

        final exitCode = runCheckCombatTestScenarioHarness(
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
