import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:test/test.dart';

import '../tool/check_domain_package_barrel_import.dart';

void _writeFile(String path, String contents) {
  File(path)
    ..createSync(recursive: true)
    ..writeAsStringSync(contents);
}

/// Ensures every enforced consumer package has a `lib/` tree in [root] so the
/// rule does not abort on a missing consumer unrelated to the scenario under
/// test. Keeps fixtures forward-compatible as new consumer boundaries are
/// enforced (e.g. `orders`).
void _ensureEnforcedConsumerDirs(String root) {
  for (final consumer in enforcedConsumerTargetsForTests().keys) {
    Directory(
      p.join(root, 'packages', 'colonizethis_$consumer', 'lib'),
    ).createSync(recursive: true);
  }
}

/// Creates a minimal target domain package whose barrel publishes
/// `src/<published>` (directly and via a nested sub-barrel) but not
/// `src/<hidden>`.
void _writeTargetPackage(
  String root,
  String target, {
  required String published,
  required String subBarrelPublished,
  required String hidden,
}) {
  final lib = p.join(root, 'packages', 'colonizethis_$target', 'lib');

  _writeFile(
    p.join(lib, 'colonizethis_$target.dart'),
    "library colonizethis_$target;\n"
    "export 'src/$published';\n"
    "export 'src/sub_barrel.dart';\n",
  );
  _writeFile(
    p.join(lib, 'src', 'sub_barrel.dart'),
    "export '$subBarrelPublished';\n",
  );
  _writeFile(p.join(lib, 'src', published), '// published\n');
  _writeFile(p.join(lib, 'src', subBarrelPublished), '// nested published\n');
  _writeFile(p.join(lib, 'src', hidden), '// not published\n');
}

void main() {
  test('enforced boundaries only reference known migrated targets', () {
    final pairs = enforcedConsumerTargetsForTests();
    expect(
      pairs['turn'],
      containsAll(<String>{
        'combat',
        'diplomacy',
        'economy',
        'orders',
        'world',
      }),
    );
    expect(
      pairs['orders'],
      containsAll(<String>{'diplomacy', 'economy', 'world'}),
    );
    // Promoted by the combat/economy/logic -> sibling slice (Refs #3393 Phase 1).
    expect(pairs['combat'], containsAll(<String>{'world'}));
    expect(pairs['economy'], containsAll(<String>{'world'}));
    expect(pairs['logic'], containsAll(<String>{'orders', 'world'}));
    // Promoted by the diplomacy/setup -> sibling slice (Refs #3393 Phase 1).
    expect(pairs['diplomacy'], containsAll(<String>{'world'}));
    expect(pairs['setup'], containsAll(<String>{'diplomacy', 'world'}));
  });

  test('passes for the real post-migration domain packages', () {
    final code = runCheckDomainPackageBarrelImport(
      Directory.current.path,
      info: (_) {},
      err: (_) {},
    );
    expect(code, 0);
  });

  test('world barrel publishes the orders-consumed follow-up files', () {
    // Promoted by the `orders -> world` follow-up slice (Refs #3393 Phase 1):
    // these world files are now consumed through the barrel by orders.
    final closure = barrelPublishedSrcFiles(Directory.current.path, 'world');
    expect(closure, contains('src/world/civilian_tile_occupancy.dart'));
    expect(closure, contains('src/world/ship_instance_allocate.dart'));
    // `sea_reachable_provinces.dart` was promoted into the world barrel by the
    // #3543 slice; the `ai_api.dart` deep export was re-routed through the world
    // barrel `show` list in the same slice so it is not a barrel bypass.
    expect(closure, contains('src/world/sea_reachable_provinces.dart'));
  });

  test('no orders lib file deep-imports the promoted world files', () {
    final ordersLib = Directory(
      p.join(Directory.current.path, 'packages', 'colonizethis_orders', 'lib'),
    );
    final offenders = <String>[];
    for (final entity in ordersLib.listSync(recursive: true)) {
      if (entity is! File || !entity.path.endsWith('.dart')) continue;
      final content = entity.readAsStringSync();
      if (content.contains(
            "package:colonizethis_world/src/world/civilian_tile_occupancy.dart",
          ) ||
          content.contains(
            "package:colonizethis_world/src/world/ship_instance_allocate.dart",
          ) ||
          content.contains(
            "package:colonizethis_world/src/world/sea_reachable_provinces.dart",
          )) {
        offenders.add(p.relative(entity.path, from: Directory.current.path));
      }
    }
    expect(offenders, isEmpty);
  });

  test('combat barrel publishes the turn-consumed combat files', () {
    // Promoted by the `turn -> combat` slice (Refs #3393 Phase 1): these combat
    // files are now consumed through the barrel by turn.
    final closure = barrelPublishedSrcFiles(Directory.current.path, 'combat');
    expect(closure, contains('src/combat/military_attack_economy.dart'));
    expect(closure, contains('src/combat/unopposed_province_capture.dart'));
  });

  test('orders barrel publishes the turn-consumed orders files', () {
    // Promoted by the `turn -> orders` slice (Refs #3393 Phase 1): these orders
    // files are now consumed through the barrel by turn.
    final closure = barrelPublishedSrcFiles(Directory.current.path, 'orders');
    expect(closure, contains('src/orders/bundled_civilian_work_order.dart'));
    expect(
      closure,
      contains('src/orders/validators/work_order_cost_calculator.dart'),
    );
  });

  test('no turn lib file deep-imports the promoted combat/orders files', () {
    final turnLib = Directory(
      p.join(Directory.current.path, 'packages', 'colonizethis_turn', 'lib'),
    );
    const promoted = <String>[
      'package:colonizethis_combat/src/combat/military_attack_economy.dart',
      'package:colonizethis_combat/src/combat/unopposed_province_capture.dart',
      'package:colonizethis_orders/src/orders/bundled_civilian_work_order.dart',
      'package:colonizethis_orders/src/orders/validators/work_order_cost_calculator.dart',
    ];
    final offenders = <String>[];
    for (final entity in turnLib.listSync(recursive: true)) {
      if (entity is! File || !entity.path.endsWith('.dart')) continue;
      final content = entity.readAsStringSync();
      if (promoted.any((deep) => content.contains("import '$deep'"))) {
        offenders.add(p.relative(entity.path, from: Directory.current.path));
      }
    }
    expect(offenders, isEmpty);
  });

  test('world barrel publishes the combat/economy/logic-consumed files', () {
    // Promoted by the combat/economy/logic -> world slice (Refs #3393 Phase 1):
    // these world files are now consumed through the barrel by combat, economy,
    // and logic.
    final closure = barrelPublishedSrcFiles(Directory.current.path, 'world');
    expect(closure, contains('src/game_player_lookup.dart'));
    expect(closure, contains('src/world/province_lookup.dart'));
    expect(closure, contains('src/world/unit_lookup.dart'));
    expect(closure, contains('src/world/connectivity_resolver.dart'));
    expect(closure, contains('src/world/player_state_pipeline.dart'));
    expect(closure, contains('src/event_bus/game_event_bus.dart'));
  });

  test('orders barrel publishes the logic-consumed order-suggestion files', () {
    // Promoted by the logic -> orders slice (Refs #3393 Phase 1).
    final closure = barrelPublishedSrcFiles(Directory.current.path, 'orders');
    expect(closure, contains('src/orders/order_suggestion_api.dart'));
    expect(closure, contains('src/orders/order_suggestion_api_impl.dart'));
  });

  test(
    'no combat/economy/logic lib file deep-imports the promoted sibling files',
    () {
      const promotedByConsumer = <String, List<String>>{
        'combat': [
          'package:colonizethis_world/src/game_player_lookup.dart',
          'package:colonizethis_world/src/world/province_lookup.dart',
          'package:colonizethis_world/src/world/unit_lookup.dart',
          'package:colonizethis_world/src/world/army_migration.dart',
          'package:colonizethis_world/src/world/province_ownership_transfer.dart',
          'package:colonizethis_world/src/world/faction_membership.dart',
          'package:colonizethis_world/src/world/game_world_mutations.dart',
        ],
        'economy': [
          'package:colonizethis_world/src/world/player_state_pipeline.dart',
          'package:colonizethis_world/src/world/connectivity_resolver.dart',
          'package:colonizethis_world/src/world/province_lookup.dart',
          'package:colonizethis_world/src/world/faction_membership.dart',
          'package:colonizethis_world/src/world/naval.dart',
        ],
        'logic': [
          'package:colonizethis_world/src/event_bus/game_event_bus.dart',
          'package:colonizethis_orders/src/orders/order_suggestion_api.dart',
          'package:colonizethis_orders/src/orders/order_suggestion_api_impl.dart',
        ],
      };
      final offenders = <String>[];
      for (final entry in promotedByConsumer.entries) {
        final libDir = Directory(
          p.join(
            Directory.current.path,
            'packages',
            'colonizethis_${entry.key}',
            'lib',
          ),
        );
        for (final entity in libDir.listSync(recursive: true)) {
          if (entity is! File || !entity.path.endsWith('.dart')) continue;
          final content = entity.readAsStringSync();
          if (entry.value.any((deep) => content.contains("import '$deep'"))) {
            offenders.add(
              p.relative(entity.path, from: Directory.current.path),
            );
          }
        }
      }
      expect(offenders, isEmpty);
    },
  );

  test(
    'world/diplomacy barrels publish the diplomacy/setup-consumed files',
    () {
      // Promoted by the diplomacy -> world and setup -> {world, diplomacy}
      // slice (Refs #3393 Phase 1): these files are now consumed through the
      // owning domain barrel by diplomacy and setup.
      final worldClosure = barrelPublishedSrcFiles(
        Directory.current.path,
        'world',
      );
      expect(worldClosure, contains('src/game_player_lookup.dart'));
      expect(worldClosure, contains('src/world_constants.dart'));
      expect(worldClosure, contains('src/world/province_lookup.dart'));
      expect(worldClosure, contains('src/world/unit_lookup.dart'));
      expect(worldClosure, contains('src/world/game_world_mutations.dart'));
      expect(worldClosure, contains('src/world/army_migration.dart'));
      expect(worldClosure, contains('src/world/player_view.dart'));
      expect(worldClosure, contains('src/world/province_owner_cache.dart'));
      expect(worldClosure, contains('src/world/player_state_pipeline.dart'));

      final diplomacyClosure = barrelPublishedSrcFiles(
        Directory.current.path,
        'diplomacy',
      );
      expect(
        diplomacyClosure,
        contains('src/diplomacy/diplomacy_relation_lookup.dart'),
      );
    },
  );

  test('no diplomacy/setup lib file deep-imports the promoted sibling files', () {
    const promotedByConsumer = <String, List<String>>{
      'diplomacy': [
        'package:colonizethis_world/src/game_player_lookup.dart',
        'package:colonizethis_world/src/world/province_lookup.dart',
        'package:colonizethis_world/src/world/faction_membership.dart',
        'package:colonizethis_world/src/world/army_migration.dart',
        'package:colonizethis_world/src/world/game_world_mutations.dart',
        'package:colonizethis_world/src/world/province_owner_cache.dart',
        'package:colonizethis_world/src/world/province_ownership_transfer.dart',
        'package:colonizethis_world/src/world/player_view.dart',
        'package:colonizethis_world/src/world/movement.dart',
        'package:colonizethis_world/src/world/ai_control.dart',
        'package:colonizethis_world/src/world_constants.dart',
      ],
      'setup': [
        'package:colonizethis_world/src/world_constants.dart',
        'package:colonizethis_world/src/world/province_lookup.dart',
        'package:colonizethis_world/src/world/unit_lookup.dart',
        'package:colonizethis_world/src/world/game_world_mutations.dart',
        'package:colonizethis_world/src/world/player_state_pipeline.dart',
        'package:colonizethis_world/src/world/player_view.dart',
        'package:colonizethis_world/src/world/naval.dart',
        'package:colonizethis_world/src/world/ship_instance_allocate.dart',
        'package:colonizethis_world/src/world/army_migration.dart',
        'package:colonizethis_diplomacy/src/diplomacy/diplomacy_relation_lookup.dart',
      ],
    };
    final offenders = <String>[];
    for (final entry in promotedByConsumer.entries) {
      final libDir = Directory(
        p.join(
          Directory.current.path,
          'packages',
          'colonizethis_${entry.key}',
          'lib',
        ),
      );
      for (final entity in libDir.listSync(recursive: true)) {
        if (entity is! File || !entity.path.endsWith('.dart')) continue;
        final content = entity.readAsStringSync();
        if (entry.value.any((deep) => content.contains("import '$deep'"))) {
          offenders.add(p.relative(entity.path, from: Directory.current.path));
        }
      }
    }
    expect(offenders, isEmpty);
  });

  test('barrelPublishedSrcFiles resolves direct and nested re-exports', () {
    final temp = Directory.systemTemp.createTempSync('barrel_closure_');
    addTearDown(() => temp.deleteSync(recursive: true));
    _writeTargetPackage(
      temp.path,
      'economy',
      published: 'economy/economy_production.dart',
      subBarrelPublished: 'economy/world_market/deal_matcher.dart',
      hidden: 'economy/secret_internal.dart',
    );

    final closure = barrelPublishedSrcFiles(temp.path, 'economy');
    expect(closure, contains('src/economy/economy_production.dart'));
    expect(closure, contains('src/economy/world_market/deal_matcher.dart'));
    expect(closure, isNot(contains('src/economy/secret_internal.dart')));
  });

  test('show/hide re-exports are not treated as fully published', () {
    final temp = Directory.systemTemp.createTempSync('barrel_combinator_');
    addTearDown(() => temp.deleteSync(recursive: true));
    final lib = p.join(temp.path, 'packages', 'colonizethis_world', 'lib');
    // The barrel re-exports `fog_resolution.dart` with a `show` combinator
    // (multi-line, mirroring the real world barrel), so only a subset of its
    // symbols is published and the file must not count as fully published.
    _writeFile(
      p.join(lib, 'colonizethis_world.dart'),
      "library colonizethis_world;\n"
      "export 'src/world/movement.dart';\n"
      "export 'src/world/fog_resolution.dart'\n"
      "    show\n"
      "        applyCoastalSeaZoneFullVisibility;\n",
    );
    _writeFile(p.join(lib, 'src', 'world', 'movement.dart'), '// published\n');
    _writeFile(
      p.join(lib, 'src', 'world', 'fog_resolution.dart'),
      '// partially published\n',
    );

    final closure = barrelPublishedSrcFiles(temp.path, 'world');
    expect(closure, contains('src/world/movement.dart'));
    expect(closure, isNot(contains('src/world/fog_resolution.dart')));
  });

  test('allows a deep import of a show-restricted re-exported file', () {
    final temp = Directory.systemTemp.createTempSync('barrel_combinator_ok_');
    addTearDown(() => temp.deleteSync(recursive: true));
    final worldLib = p.join(temp.path, 'packages', 'colonizethis_world', 'lib');
    _writeFile(
      p.join(worldLib, 'colonizethis_world.dart'),
      "library colonizethis_world;\n"
      "export 'src/world/fog_resolution.dart' show applyCoastalSeaZoneFullVisibility;\n",
    );
    _writeFile(
      p.join(worldLib, 'src', 'world', 'fog_resolution.dart'),
      '// partially published\n',
    );
    for (final sibling in const ['economy', 'diplomacy']) {
      Directory(
        p.join(temp.path, 'packages', 'colonizethis_$sibling', 'lib'),
      ).createSync(recursive: true);
    }
    final turnLib = Directory(
      p.join(temp.path, 'packages', 'colonizethis_turn', 'lib'),
    )..createSync(recursive: true);
    // Deep import of the only-partially-published file is allowed.
    File(p.join(turnLib.path, 'end_of_turn.dart')).writeAsStringSync(
      "import 'package:colonizethis_world/src/world/fog_resolution.dart';\n",
    );
    _ensureEnforcedConsumerDirs(temp.path);

    final code = runCheckDomainPackageBarrelImport(
      temp.path,
      info: (_) {},
      err: (_) {},
    );
    expect(code, 0);
  });

  test('fails on a deep import that bypasses an existing barrel export', () {
    final temp = Directory.systemTemp.createTempSync('barrel_bypass_bad_');
    addTearDown(() => temp.deleteSync(recursive: true));
    _writeTargetPackage(
      temp.path,
      'economy',
      published: 'economy/economy_production.dart',
      subBarrelPublished: 'economy/world_market/deal_matcher.dart',
      hidden: 'economy/secret_internal.dart',
    );
    Directory(
      p.join(temp.path, 'packages', 'colonizethis_diplomacy', 'lib'),
    ).createSync(recursive: true);
    final turnLib = Directory(
      p.join(temp.path, 'packages', 'colonizethis_turn', 'lib'),
    )..createSync(recursive: true);
    File(p.join(turnLib.path, 'phase.dart')).writeAsStringSync(
      "import 'package:colonizethis_economy/src/economy/economy_production.dart';\n",
    );
    _ensureEnforcedConsumerDirs(temp.path);

    final code = runCheckDomainPackageBarrelImport(
      temp.path,
      info: (_) {},
      err: (_) {},
    );
    expect(code, 1);
  });

  test(
    'fails on an orders -> diplomacy deep import that bypasses the barrel',
    () {
      final temp = Directory.systemTemp.createTempSync('barrel_orders_diplo_');
      addTearDown(() => temp.deleteSync(recursive: true));
      _writeTargetPackage(
        temp.path,
        'diplomacy',
        published: 'diplomacy/diplomacy_resolver.dart',
        subBarrelPublished: 'dossier/event_dialogue.dart',
        hidden: 'diplomacy/internal_only.dart',
      );
      final ordersLib = Directory(
        p.join(temp.path, 'packages', 'colonizethis_orders', 'lib'),
      )..createSync(recursive: true);
      File(p.join(ordersLib.path, 'validator.dart')).writeAsStringSync(
        "import 'package:colonizethis_diplomacy/src/diplomacy/diplomacy_resolver.dart';\n",
      );
      _ensureEnforcedConsumerDirs(temp.path);

      final code = runCheckDomainPackageBarrelImport(
        temp.path,
        info: (_) {},
        err: (_) {},
      );
      expect(code, 1);
    },
  );

  test('allows a deep import of a file the barrel does not publish', () {
    final temp = Directory.systemTemp.createTempSync('barrel_bypass_ok_');
    addTearDown(() => temp.deleteSync(recursive: true));
    _writeTargetPackage(
      temp.path,
      'economy',
      published: 'economy/economy_production.dart',
      subBarrelPublished: 'economy/world_market/deal_matcher.dart',
      hidden: 'economy/secret_internal.dart',
    );
    Directory(
      p.join(temp.path, 'packages', 'colonizethis_diplomacy', 'lib'),
    ).createSync(recursive: true);
    final turnLib = Directory(
      p.join(temp.path, 'packages', 'colonizethis_turn', 'lib'),
    )..createSync(recursive: true);
    // Importing the unpublished file deeply is allowed; importing the barrel is
    // also allowed.
    File(p.join(turnLib.path, 'phase.dart')).writeAsStringSync(
      "import 'package:colonizethis_economy/src/economy/secret_internal.dart';\n"
      "import 'package:colonizethis_economy/colonizethis_economy.dart';\n",
    );
    _ensureEnforcedConsumerDirs(temp.path);

    final code = runCheckDomainPackageBarrelImport(
      temp.path,
      info: (_) {},
      err: (_) {},
    );
    expect(code, 0);
  });

  test('ignores generated files and deep export re-exports', () {
    final temp = Directory.systemTemp.createTempSync('barrel_bypass_gen_');
    addTearDown(() => temp.deleteSync(recursive: true));
    _writeTargetPackage(
      temp.path,
      'diplomacy',
      published: 'diplomacy/diplomacy_phase_result.dart',
      subBarrelPublished: 'dossier/event_dialogue.dart',
      hidden: 'diplomacy/internal_only.dart',
    );
    Directory(
      p.join(temp.path, 'packages', 'colonizethis_economy', 'lib'),
    ).createSync(recursive: true);
    final turnLib = Directory(
      p.join(temp.path, 'packages', 'colonizethis_turn', 'lib'),
    )..createSync(recursive: true);
    // A generated file with a bypassing import must be ignored.
    File(p.join(turnLib.path, 'thing.g.dart')).writeAsStringSync(
      "import 'package:colonizethis_diplomacy/src/diplomacy/diplomacy_phase_result.dart';\n",
    );
    // A deliberate narrow deep export re-exporting a single file is out of scope.
    File(p.join(turnLib.path, 'reexport.dart')).writeAsStringSync(
      "export 'package:colonizethis_diplomacy/src/diplomacy/diplomacy_phase_result.dart';\n",
    );
    _ensureEnforcedConsumerDirs(temp.path);

    final code = runCheckDomainPackageBarrelImport(
      temp.path,
      info: (_) {},
      err: (_) {},
    );
    expect(code, 0);
  });

  test('fails when an enforced consumer lib tree is missing', () {
    final temp = Directory.systemTemp.createTempSync('barrel_bypass_missing_');
    addTearDown(() => temp.deleteSync(recursive: true));

    final code = runCheckDomainPackageBarrelImport(
      temp.path,
      info: (_) {},
      err: (_) {},
    );
    expect(code, 1);
  });
}
