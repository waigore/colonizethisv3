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
    // `sea_reachable_provinces.dart` stays internal so the `ai_api.dart`
    // narrow-contract deep export of it does not become a barrel bypass.
    expect(closure, isNot(contains('src/world/sea_reachable_provinces.dart')));
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
          )) {
        offenders.add(p.relative(entity.path, from: Directory.current.path));
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
