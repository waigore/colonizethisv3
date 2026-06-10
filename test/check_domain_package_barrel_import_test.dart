import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:test/test.dart';

import '../tool/check_domain_package_barrel_import.dart';

void _writeFile(String path, String contents) {
  File(path)
    ..createSync(recursive: true)
    ..writeAsStringSync(contents);
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
    expect(pairs['turn'], containsAll(<String>{'economy', 'diplomacy'}));
  });

  test('passes for the real post-migration domain packages', () {
    final code = runCheckDomainPackageBarrelImport(
      Directory.current.path,
      info: (_) {},
      err: (_) {},
    );
    expect(code, 0);
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

    final code = runCheckDomainPackageBarrelImport(
      temp.path,
      info: (_) {},
      err: (_) {},
    );
    expect(code, 1);
  });

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
