import 'dart:io';

import 'package:test/test.dart';

import '../tool/check_turn_test_support_region_literals.dart';

void main() {
  group('runCheckTurnTestSupportRegionLiterals', () {
    test('passes when support files use kRegion* constants', () {
      final temp = Directory.systemTemp.createTempSync(
        'check_turn_support_region_literals_pass_',
      );
      addTearDown(() => temp.deleteSync(recursive: true));

      File(
        '${temp.path}/packages/colonizethis_turn/test/support/clean.dart',
      )
        ..createSync(recursive: true)
        ..writeAsStringSync('''
import 'package:colonizethis_logic/colonizethis_logic.dart'
    show kRegionNewWorld, kRegionOldWorld;

String regionIndex(String regionId) =>
    regionId == kRegionNewWorld ? 1 : (regionId == kRegionOldWorld ? 0 : -1);
''');

      final logs = <String>[];
      final code = runCheckTurnTestSupportRegionLiterals(
        temp.path,
        info: logs.add,
        err: logs.add,
      );

      expect(code, 0);
      expect(logs.join('\n'), contains('no violations found'));
    });

    test("fails when a support file hard-codes 'oldWorld' / 'newWorld'", () {
      final temp = Directory.systemTemp.createTempSync(
        'check_turn_support_region_literals_bad_',
      );
      addTearDown(() => temp.deleteSync(recursive: true));

      File(
        '${temp.path}/packages/colonizethis_turn/test/support/bad_region.dart',
      )
        ..createSync(recursive: true)
        ..writeAsStringSync('''
int regionIndex(String regionId) {
  if (regionId == 'newWorld') return 1;
  if (regionId == "oldWorld") return 0;
  return -1;
}
''');

      final logs = <String>[];
      final code = runCheckTurnTestSupportRegionLiterals(
        temp.path,
        info: logs.add,
        err: logs.add,
      );

      expect(code, 1);
      final out = logs.join('\n');
      expect(out, contains("bad_region.dart:2: 'newWorld'"));
      expect(out, contains('bad_region.dart:3: "oldWorld"'));
      expect(out, contains('kRegionOldWorld'));
    });

    test('passes on current repo turn test support tree', () {
      expect(runCheckTurnTestSupportRegionLiterals('.'), 0);
    });
  });
}
