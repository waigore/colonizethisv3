import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:test/test.dart';

import '../tool/check_economy_test_no_local_run_scenarios.dart';

void main() {
  group('runCheckEconomyTestNoLocalRunScenarios', () {
    test('passes on current repo tree', () {
      expect(runCheckEconomyTestNoLocalRunScenarios('.'), 0);
    });

    test('fails when a local void Function() run shell appears', () {
      final temp = Directory.systemTemp.createTempSync('economy-no-local-run-');
      try {
        final testDir = Directory(
          p.join(temp.path, 'packages', 'colonizethis_economy', 'test'),
        )..createSync(recursive: true);
        File(p.join(testDir.path, 'bad_local_run_test.dart')).writeAsStringSync(
          "typedef _S = ({String label, void Function() run});\n"
          "void main() {}\n",
        );

        final errors = <String>[];
        final code = runCheckEconomyTestNoLocalRunScenarios(
          temp.path,
          info: (_) {},
          err: errors.add,
        );
        expect(code, 1);
        expect(errors.join('\n'), contains('local void Function() run'));
      } finally {
        temp.deleteSync(recursive: true);
      }
    });
  });
}
