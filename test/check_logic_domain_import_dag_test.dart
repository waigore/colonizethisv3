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

  test(
    'Phase 0 C0 grandfather allowlist is empty (all deferred edges eliminated)',
    () {
      final allowlist = logicDomainImportDagGrandfatherAllowlistForTests();
      expect(allowlist, isEmpty);
    },
  );

  test(
    'economy->orders edge is enforced and fully eliminated (Refs #3290)',
    () {
      final forbidden = logicDomainImportForbiddenEdgesForTests();
      expect(forbidden, contains('economy->orders'));

      final allowlist = logicDomainImportDagGrandfatherAllowlistForTests();
      expect(allowlist.where((e) => e.startsWith('economy->orders:')), isEmpty);
    },
  );

  test('orders->turn edge is enforced and fully eliminated (Refs #3290)', () {
    final forbidden = logicDomainImportForbiddenEdgesForTests();
    expect(forbidden, contains('orders->turn'));

    final allowlist = logicDomainImportDagGrandfatherAllowlistForTests();
    expect(allowlist.where((e) => e.startsWith('orders->turn:')), isEmpty);
  });

  test('fails when a new forbidden orders->turn import appears', () {
    final temp = Directory.systemTemp.createTempSync('logic_dag_orders_turn_');
    addTearDown(() => temp.deleteSync(recursive: true));

    File(
        '${temp.path}/packages/colonizethis_logic/lib/src/orders/bad_turn.dart',
      )
      ..createSync(recursive: true)
      ..writeAsStringSync("""
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

  test('fails when a new forbidden economy->orders import appears', () {
    final temp = Directory.systemTemp.createTempSync('logic_dag_econ_fail_');
    addTearDown(() => temp.deleteSync(recursive: true));

    File(
        '${temp.path}/packages/colonizethis_logic/lib/src/economy/bad_orders.dart',
      )
      ..createSync(recursive: true)
      ..writeAsStringSync("""
import '../orders/order_engine.dart';
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
    'diplomacy->turn edge is enforced and fully eliminated (Refs #3290)',
    () {
      final forbidden = logicDomainImportForbiddenEdgesForTests();
      expect(forbidden, contains('diplomacy->turn'));

      final allowlist = logicDomainImportDagGrandfatherAllowlistForTests();
      expect(allowlist.where((e) => e.startsWith('diplomacy->turn:')), isEmpty);
    },
  );

  test('fails when a new forbidden diplomacy->turn import appears', () {
    final temp = Directory.systemTemp.createTempSync('logic_dag_dipl_turn_');
    addTearDown(() => temp.deleteSync(recursive: true));

    File(
        '${temp.path}/packages/colonizethis_logic/lib/src/diplomacy/bad_turn.dart',
      )
      ..createSync(recursive: true)
      ..writeAsStringSync("""
import '../turn/turn_resolution_result.dart';
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

  test(
    'economy->diplomacy edge is enforced and fully eliminated (Refs #3290)',
    () {
      final forbidden = logicDomainImportForbiddenEdgesForTests();
      expect(forbidden, contains('economy->diplomacy'));

      final allowlist = logicDomainImportDagGrandfatherAllowlistForTests();
      expect(
        allowlist.where((e) => e.startsWith('economy->diplomacy:')),
        isEmpty,
      );
    },
  );

  test('fails when a new forbidden economy->diplomacy import appears', () {
    final temp = Directory.systemTemp.createTempSync('logic_dag_econ_dipl_');
    addTearDown(() => temp.deleteSync(recursive: true));

    File(
        '${temp.path}/packages/colonizethis_logic/lib/src/economy/bad_diplomacy.dart',
      )
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

  test('diplomacy->ai edge is enforced and fully eliminated (Refs #3290)', () {
    final forbidden = logicDomainImportForbiddenEdgesForTests();
    expect(forbidden, contains('diplomacy->ai'));

    final allowlist = logicDomainImportDagGrandfatherAllowlistForTests();
    expect(allowlist.where((e) => e.startsWith('diplomacy->ai:')), isEmpty);
  });

  test(
    'diplomacy->orders edge is enforced and fully eliminated (Refs #3290)',
    () {
      final forbidden = logicDomainImportForbiddenEdgesForTests();
      expect(forbidden, contains('diplomacy->orders'));

      final allowlist = logicDomainImportDagGrandfatherAllowlistForTests();
      expect(
        allowlist.where((e) => e.startsWith('diplomacy->orders:')),
        isEmpty,
      );
    },
  );

  test('fails when a new forbidden diplomacy->orders import appears', () {
    final temp = Directory.systemTemp.createTempSync('logic_dag_dipl_orders_');
    addTearDown(() => temp.deleteSync(recursive: true));

    File(
        '${temp.path}/packages/colonizethis_logic/lib/src/diplomacy/bad_orders.dart',
      )
      ..createSync(recursive: true)
      ..writeAsStringSync("""
import '../orders/order_suggestion_helpers.dart';
void noop() {}
""");

    final code = runCheckLogicDomainImportDag(
      temp.path,
      info: (_) {},
      err: (_) {},
    );
    expect(code, 1);
  });

  test('fails when a new forbidden diplomacy->ai import appears', () {
    final temp = Directory.systemTemp.createTempSync('logic_dag_dipl_ai_');
    addTearDown(() => temp.deleteSync(recursive: true));

    File(
        '${temp.path}/packages/colonizethis_logic/lib/src/diplomacy/bad_ai.dart',
      )
      ..createSync(recursive: true)
      ..writeAsStringSync("""
import '../ai/ai_planner.dart';
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
    'diplomacy and dossier do not import logic constants barrel (Refs #3290 Phase 2)',
    () {
      final violations = <String>[];
      for (final domain in ['diplomacy', 'dossier']) {
        final domainDir = Directory(
          'packages/colonizethis_logic/lib/src/$domain',
        );
        if (!domainDir.existsSync()) continue;
        for (final entity in domainDir.listSync(recursive: true)) {
          if (entity is! File || !entity.path.endsWith('.dart')) continue;
          final content = entity.readAsStringSync();
          if (content.contains("import '../constants.dart';")) {
            violations.add(entity.path);
          }
        }
      }
      expect(
        violations,
        isEmpty,
        reason:
            'diplomacy/dossier must import world symbols directly, not '
            'lib/src/constants.dart',
      );
    },
  );

  test(
    'orders does not import the neutral logic constants core (Refs #3290 Phase 2)',
    () {
      // The orders tree extracts into colonizethis_orders, which must depend on
      // colonizethis_world / colonizethis_economy / colonizethis_diplomacy /
      // colonizethis_models / colonizethis_data — not on the thin
      // colonizethis_logic core. Order/work constants come from the
      // orders-domain order_work_constants.dart; world/models convenience
      // symbols come from colonizethis_world / colonizethis_models directly.
      const forbiddenConstantsImports = <String>[
        "import '../constants.dart';",
        "import '../../constants.dart';",
        "import '../../../constants.dart';",
        "import '../constants.dart' show",
        "import '../../constants.dart' show",
        "import '../../../constants.dart' show",
        "import 'package:colonizethis_logic/src/constants.dart';",
      ];
      final ordersDir = Directory('packages/colonizethis_logic/lib/src/orders');
      final violations = <String>[];
      if (ordersDir.existsSync()) {
        for (final entity in ordersDir.listSync(recursive: true)) {
          if (entity is! File || !entity.path.endsWith('.dart')) continue;
          final content = entity.readAsStringSync();
          for (final bad in forbiddenConstantsImports) {
            if (content.contains(bad)) {
              violations.add('${entity.path}: $bad');
            }
          }
        }
      }
      expect(
        violations,
        isEmpty,
        reason:
            'orders/ must import order constants from '
            'orders/order_work_constants.dart and world/models symbols from '
            'colonizethis_world / colonizethis_models directly, not the neutral '
            'lib/src/constants.dart core',
      );
    },
  );

  test('orders does not import the neutral projections core (Refs #3290 C2)', () {
    // The orders tree extracts into colonizethis_orders. The dry-run
    // projector (projectOrderEffects) runs the turn resolver and lives in the
    // neutral lib/src/projections/ core module, which sits above the orders
    // domain. order_engine.dart therefore consumes it via an injected
    // OrderEffectsProjector and the ProjectedEffects type from
    // orders/projected_effects.dart, never importing the core module.
    const forbiddenProjectionImports = <String>[
      "import '../projections/order_projections.dart';",
      "import '../projections/projected_effects.dart';",
      "import '../../projections/order_projections.dart';",
      "import '../../projections/projected_effects.dart';",
      "import 'package:colonizethis_logic/src/projections/order_projections.dart';",
      "import 'package:colonizethis_logic/src/projections/projected_effects.dart';",
    ];
    final ordersDir = Directory('packages/colonizethis_logic/lib/src/orders');
    final violations = <String>[];
    if (ordersDir.existsSync()) {
      for (final entity in ordersDir.listSync(recursive: true)) {
        if (entity is! File || !entity.path.endsWith('.dart')) continue;
        final content = entity.readAsStringSync();
        for (final bad in forbiddenProjectionImports) {
          if (content.contains(bad)) {
            violations.add('${entity.path}: $bad');
          }
        }
      }
    }
    expect(
      violations,
      isEmpty,
      reason:
          'orders/ must consume the dry-run via an injected '
          'OrderEffectsProjector and ProjectedEffects from '
          'orders/projected_effects.dart, not the neutral '
          'lib/src/projections/ core module',
    );
  });

  test(
    'turn_resolution_seeds is turn-owned, not a neutral core file (Refs #3290 C3)',
    () {
      final neutralFiles = logicDomainImportNeutralTopLevelFilesForTests();
      expect(neutralFiles, isNot(contains('turn_resolution_seeds.dart')));

      final relocated = File(
        'packages/colonizethis_logic/lib/src/turn/turn_resolution_seeds.dart',
      );
      expect(
        relocated.existsSync(),
        isTrue,
        reason: 'turn_resolution_seeds.dart must live in the turn/ domain',
      );

      final oldNeutral = File(
        'packages/colonizethis_logic/lib/src/turn_resolution_seeds.dart',
      );
      expect(
        oldNeutral.existsSync(),
        isFalse,
        reason:
            'turn_resolution_seeds.dart must no longer live in the neutral '
            'lib/src/ core root',
      );
    },
  );

  test('fails when world imports the now turn-owned seeds (Refs #3290 C3)', () {
    final temp = Directory.systemTemp.createTempSync('logic_dag_world_seeds_');
    addTearDown(() => temp.deleteSync(recursive: true));

    File(
        '${temp.path}/packages/colonizethis_logic/lib/src/world/bad_seeds.dart',
      )
      ..createSync(recursive: true)
      ..writeAsStringSync("""
import '../turn/turn_resolution_seeds.dart';
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
    'diplomacy and dossier do not import logic core logging (Refs #3290 Phase 2)',
    () {
      // The diplomacy/dossier trees fold into colonizethis_diplomacy, which must
      // depend only on world/combat/models/data/logger — not on the thin
      // colonizethis_logic core. Logging therefore goes through the
      // diplomacy-domain logger (diploLog), not the logic-core logicLog.
      const forbiddenLoggingImports = <String>[
        "import 'package:colonizethis_logic/src/logging.dart';",
        "import 'package:colonizethis_logic/package_logger.dart';",
        "import '../logging.dart';",
        "import '../package_logger.dart';",
        "import 'package:colonizethis_logic/colonizethis_logic.dart';",
      ];
      final violations = <String>[];
      for (final domain in ['diplomacy', 'dossier']) {
        final domainDir = Directory(
          'packages/colonizethis_logic/lib/src/$domain',
        );
        if (!domainDir.existsSync()) continue;
        for (final entity in domainDir.listSync(recursive: true)) {
          if (entity is! File || !entity.path.endsWith('.dart')) continue;
          final content = entity.readAsStringSync();
          for (final bad in forbiddenLoggingImports) {
            if (content.contains(bad)) {
              violations.add('${entity.path}: $bad');
            }
          }
        }
      }
      expect(
        violations,
        isEmpty,
        reason:
            'diplomacy/dossier must log via the diplomacy-domain logger '
            '(diploLog in diplomacy/diplomacy_logging.dart), not the '
            'colonizethis_logic core logicLog',
      );
    },
  );

  test('turn does not import the logic core logging (Refs #3290 C3)', () {
    // The turn/ tree extracts into colonizethis_turn, which must depend only on
    // world/combat/economy/diplomacy/orders/models/data/logger — not on the
    // thin colonizethis_logic core. Logging therefore goes through the
    // turn-domain logger (turnLog in turn/turn_logging.dart), not the
    // logic-core logicLog.
    const forbiddenLoggingImports = <String>[
      "import 'package:colonizethis_logic/src/logging.dart';",
      "import 'package:colonizethis_logic/package_logger.dart';",
      "import '../logging.dart';",
      "import '../../logging.dart';",
      "import '../package_logger.dart';",
      "import '../../package_logger.dart';",
      "import 'package:colonizethis_logic/colonizethis_logic.dart';",
    ];
    final turnDir = Directory('packages/colonizethis_logic/lib/src/turn');
    final violations = <String>[];
    if (turnDir.existsSync()) {
      for (final entity in turnDir.listSync(recursive: true)) {
        if (entity is! File || !entity.path.endsWith('.dart')) continue;
        if (entity.path.endsWith('turn_logging.dart')) continue;
        final content = entity.readAsStringSync();
        for (final bad in forbiddenLoggingImports) {
          if (content.contains(bad)) {
            violations.add('${entity.path}: $bad');
          }
        }
        if (content.contains('logicLog')) {
          violations.add('${entity.path}: references logicLog');
        }
      }
    }
    expect(
      violations,
      isEmpty,
      reason:
          'turn/ must log via the turn-domain logger (turnLog in '
          'turn/turn_logging.dart), not the colonizethis_logic core logicLog',
    );
  });
}
