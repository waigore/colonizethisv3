import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:test/test.dart';

import '../tool/check_combat_test_support_no_logic_barrel.dart';

void _writeFile(Directory root, String relative, String source) {
  final file = File(p.join(root.path, relative));
  file.parent.createSync(recursive: true);
  file.writeAsStringSync(source);
}

void main() {
  group('runCheckCombatTestSupportNoLogicBarrel', () {
    test('passes on current repo tree', () {
      expect(runCheckCombatTestSupportNoLogicBarrel('.'), 0);
    });

    test('fails when a support lib file imports colonizethis_logic', () {
      final root = Directory.systemTemp.createTempSync('cts_no_logic_bad');
      addTearDown(() => root.deleteSync(recursive: true));
      _writeFile(
        root,
        '$combatTestSupportLibRelative/src/bad.dart',
        "import 'package:colonizethis_logic/colonizethis_logic.dart';\n",
      );

      final errors = <String>[];
      final code = runCheckCombatTestSupportNoLogicBarrel(
        root.path,
        err: errors.add,
      );
      expect(code, 1);
      expect(errors.join('\n'), contains('bad.dart'));
    });

    test('passes when support lib uses combat/models barrels only', () {
      final root = Directory.systemTemp.createTempSync('cts_no_logic_ok');
      addTearDown(() => root.deleteSync(recursive: true));
      _writeFile(
        root,
        '$combatTestSupportLibRelative/src/ok.dart',
        "import 'package:colonizethis_combat/colonizethis_combat.dart';\n",
      );

      expect(runCheckCombatTestSupportNoLogicBarrel(root.path), 0);
    });
  });
}
