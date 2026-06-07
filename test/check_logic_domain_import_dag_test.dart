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
    expect(allowlist, contains('orders->turn:orders/order_projections.dart'));
  });

  test('economy->orders edge is enforced and fully eliminated (Refs #3290)', () {
    final forbidden = logicDomainImportForbiddenEdgesForTests();
    expect(forbidden, contains('economy->orders'));

    final allowlist = logicDomainImportDagGrandfatherAllowlistForTests();
    expect(allowlist.where((e) => e.startsWith('economy->orders:')), isEmpty);
  });

  test('orders->turn grandfather is trimmed to the single deferred projection '
      'file (orders_application* hoisted to lib/src/trace/)', () {
    final allowlist = logicDomainImportDagGrandfatherAllowlistForTests();
    final ordersToTurn =
        allowlist.where((e) => e.startsWith('orders->turn:')).toSet();
    expect(ordersToTurn, {'orders->turn:orders/order_projections.dart'});
  });

  test('fails when a new forbidden economy->orders import appears', () {
    final temp = Directory.systemTemp.createTempSync('logic_dag_econ_fail_');
    addTearDown(() => temp.deleteSync(recursive: true));

    File(
      '${temp.path}/packages/colonizethis_logic/lib/src/economy/bad_orders.dart',
    )
      ..createSync(recursive: true)
      ..writeAsStringSync("""
import '../orders/order_projections.dart';
void noop() {}
""");

    final code = runCheckLogicDomainImportDag(
      temp.path,
      info: (_) {},
      err: (_) {},
    );
    expect(code, 1);
  });

  test(
    'combat->diplomacy edge is fully eliminated (no grandfather entries)',
    () {
      final allowlist = logicDomainImportDagGrandfatherAllowlistForTests();
      expect(
        allowlist.where((e) => e.startsWith('combat->diplomacy:')),
        isEmpty,
      );
    },
  );

  test(
    'ai->diplomacy edge is enforced + fully eliminated (no grandfather entries)',
    () {
      final forbidden = logicDomainImportForbiddenEdgesForTests();
      expect(forbidden, contains('ai->diplomacy'));

      final allowlist = logicDomainImportDagGrandfatherAllowlistForTests();
      expect(allowlist.where((e) => e.startsWith('ai->diplomacy:')), isEmpty);
    },
  );

  test('fails when a new forbidden ai->diplomacy import appears', () {
    final temp = Directory.systemTemp.createTempSync('logic_dag_ai_dipl_fail_');
    addTearDown(() => temp.deleteSync(recursive: true));

    File('${temp.path}/packages/colonizethis_logic/lib/src/ai/bad_ai.dart')
      ..createSync(recursive: true)
      ..writeAsStringSync("""
import '../diplomacy/diplomacy_resolver.dart';
void noop() {}
""");

    final code = runCheckLogicDomainImportDag(
      temp.path,
      info: (_) {},
      err: (_) {},
    );
    expect(code, 1);
  });

  test(
    'world->combat and world->dossier leaf edges are enforced + eliminated',
    () {
      final forbidden = logicDomainImportForbiddenEdgesForTests();
      expect(forbidden, contains('world->combat'));
      expect(forbidden, contains('world->dossier'));

      final allowlist = logicDomainImportDagGrandfatherAllowlistForTests();
      expect(allowlist.where((e) => e.startsWith('world->combat:')), isEmpty);
      expect(allowlist.where((e) => e.startsWith('world->dossier:')), isEmpty);
    },
  );

  test('fails when a new forbidden world->combat import appears', () {
    final temp = Directory.systemTemp.createTempSync('logic_dag_combat_fail_');
    addTearDown(() => temp.deleteSync(recursive: true));

    File(
        '${temp.path}/packages/colonizethis_logic/lib/src/world/bad_combat.dart',
      )
      ..createSync(recursive: true)
      ..writeAsStringSync("""
import '../combat/naval_combat_resolver.dart';
void noop() {}
""");

    final code = runCheckLogicDomainImportDag(
      temp.path,
      info: (_) {},
      err: (_) {},
    );
    expect(code, 1);
  });
}
