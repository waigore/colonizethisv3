import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:test/test.dart';

import '../tool/check_world_no_circular_imports.dart';

String _worldLib(String root) =>
    p.join(root, 'packages', 'colonizethis_world', 'lib');

void main() {
  test('passes for the real colonizethis_world lib tree', () {
    final code = runCheckWorldNoCircularImports(
      Directory.current.path,
      info: (_) {},
      err: (_) {},
    );
    expect(code, 0);
  });

  test('fails on a two-node relative-import cycle', () {
    final temp = Directory.systemTemp.createTempSync('world_cycle_');
    addTearDown(() => temp.deleteSync(recursive: true));
    final libDir = Directory(p.join(_worldLib(temp.path), 'src', 'world'))
      ..createSync(recursive: true);

    File(p.join(libDir.path, 'a.dart')).writeAsStringSync(
      "import 'b.dart';\n",
    );
    File(p.join(libDir.path, 'b.dart')).writeAsStringSync(
      "import 'a.dart';\n",
    );

    final errors = <String>[];
    final code = runCheckWorldNoCircularImports(
      temp.path,
      info: (_) {},
      err: errors.add,
    );
    expect(code, 1);
    expect(errors.join('\n'), contains('a.dart'));
    expect(errors.join('\n'), contains('b.dart'));
  });

  test('fails on a cycle expressed via package:colonizethis_world self-import',
      () {
    final temp = Directory.systemTemp.createTempSync('world_cycle_pkg_');
    addTearDown(() => temp.deleteSync(recursive: true));
    final libDir = Directory(p.join(_worldLib(temp.path), 'src', 'world'))
      ..createSync(recursive: true);

    File(p.join(libDir.path, 'a.dart')).writeAsStringSync(
      "import 'package:colonizethis_world/src/world/b.dart';\n",
    );
    File(p.join(libDir.path, 'b.dart')).writeAsStringSync(
      "import 'a.dart';\n",
    );

    final code = runCheckWorldNoCircularImports(
      temp.path,
      info: (_) {},
      err: (_) {},
    );
    expect(code, 1);
  });

  test('passes on an acyclic tree and ignores generated-file cycles', () {
    final temp = Directory.systemTemp.createTempSync('world_acyclic_');
    addTearDown(() => temp.deleteSync(recursive: true));
    final libDir = Directory(p.join(_worldLib(temp.path), 'src', 'world'))
      ..createSync(recursive: true);

    // a -> b -> c (acyclic chain), plus an external + dart: import skipped.
    File(p.join(libDir.path, 'a.dart')).writeAsStringSync(
      "import 'dart:collection';\n"
      "import 'package:colonizethis_models/colonizethis_models.dart';\n"
      "import 'b.dart';\n",
    );
    File(p.join(libDir.path, 'b.dart')).writeAsStringSync(
      "import 'c.dart';\n",
    );
    File(p.join(libDir.path, 'c.dart')).writeAsStringSync('// leaf\n');
    // A generated file with a back-edge must be ignored.
    File(p.join(libDir.path, 'a.g.dart')).writeAsStringSync(
      "import 'a.dart';\nexport 'b.dart';\n",
    );

    final code = runCheckWorldNoCircularImports(
      temp.path,
      info: (_) {},
      err: (_) {},
    );
    expect(code, 0);
  });

  test('fails when the world lib tree is missing', () {
    final temp = Directory.systemTemp.createTempSync('world_missing_');
    addTearDown(() => temp.deleteSync(recursive: true));
    final code = runCheckWorldNoCircularImports(
      temp.path,
      info: (_) {},
      err: (_) {},
    );
    expect(code, 1);
  });
}
