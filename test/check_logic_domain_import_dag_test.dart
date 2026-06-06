import 'dart:io';

import 'package:test/test.dart';

import '../tool/check_logic_domain_import_dag.dart';

void main() {
  test('passes on current dev tree outside documented grandfather set', () {
    final code = runCheckLogicDomainImportDag(
      Directory.current.path,
      info: (_) {},
      err: (_) {},
    );
    expect(code, 0);
  });

  test('fails when a new forbidden world->turn import appears', () {
    final temp = Directory.systemTemp.createTempSync('logic_dag_fail_');
    addTearDown(() => temp.deleteSync(recursive: true));

    final violating = File(
      '${temp.path}/packages/colonizethis_logic/lib/src/world/bad.dart',
    )..createSync(recursive: true);
    violating.writeAsStringSync("""
import '../turn/turn_resolver.dart';
void noop() {}
""");

    final code = runCheckLogicDomainImportDag(
      temp.path,
      info: (_) {},
      err: (_) {},
    );
    expect(code, 1);
  });

  test('documents grandfather allowlist entries for deferred C0 edges', () {
    final allowlist = logicDomainImportDagGrandfatherAllowlistForTests();
    expect(allowlist, contains('combat->diplomacy:combat/naval_combat_resolver.dart'));
    expect(allowlist, contains('ai->diplomacy:ai/simple_ai_heuristics.dart'));
  });
}
