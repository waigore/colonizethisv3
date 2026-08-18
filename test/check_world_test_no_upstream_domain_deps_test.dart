import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:test/test.dart';

import '../tool/check_world_test_no_upstream_domain_deps.dart';

void _write(Directory root, String relative, String source) {
  final file = File(p.join(root.path, relative));
  file.parent.createSync(recursive: true);
  file.writeAsStringSync(source);
}

void main() {
  group('runCheckWorldTestNoUpstreamDomainDeps', () {
    test('passes on the current repo tree', () {
      expect(runCheckWorldTestNoUpstreamDomainDeps('.', err: (_) {}), 0);
    });

    test('fails when a world test imports colonizethis_logic', () {
      final root = Directory.systemTemp.createTempSync('world_no_up_logic_');
      addTearDown(() => root.deleteSync(recursive: true));
      _write(
        root,
        'packages/colonizethis_world/pubspec.yaml',
        'name: colonizethis_world\n',
      );
      _write(
        root,
        'packages/colonizethis_world/test/world/bad_test.dart',
        "import 'package:colonizethis_logic/colonizethis_logic.dart';\n",
      );

      final errors = <String>[];
      final code = runCheckWorldTestNoUpstreamDomainDeps(
        root.path,
        err: errors.add,
      );
      expect(code, 1);
      expect(errors.join('\n'), contains('bad_test.dart'));
    });

    test('fails when a world support file imports colonizethis_turn', () {
      final root = Directory.systemTemp.createTempSync('world_no_up_turn_');
      addTearDown(() => root.deleteSync(recursive: true));
      _write(
        root,
        'packages/colonizethis_world/pubspec.yaml',
        'name: colonizethis_world\n',
      );
      _write(
        root,
        'packages/colonizethis_world/test/world_test_support/bad_support.dart',
        "import 'package:colonizethis_turn/src/turn/end_of_turn_resolver.dart';\n",
      );

      final errors = <String>[];
      final code = runCheckWorldTestNoUpstreamDomainDeps(
        root.path,
        err: errors.add,
      );
      expect(code, 1);
      expect(
        errors.join('\n'),
        contains('world_test_support/bad_support.dart'),
      );
    });

    test('fails when world pubspec lists colonizethis_logic', () {
      final root = Directory.systemTemp.createTempSync('world_no_up_pub_');
      addTearDown(() => root.deleteSync(recursive: true));
      _write(
        root,
        'packages/colonizethis_world/pubspec.yaml',
        'name: colonizethis_world\ndev_dependencies:\n  colonizethis_logic:\n',
      );
      _write(
        root,
        'packages/colonizethis_world/test/world/ok_test.dart',
        "import 'package:colonizethis_world/colonizethis_world.dart';\n",
      );

      final errors = <String>[];
      final code = runCheckWorldTestNoUpstreamDomainDeps(
        root.path,
        err: errors.add,
      );
      expect(code, 1);
      expect(errors.join('\n'), contains('pubspec.yaml'));
    });

    test('passes when tests and pubspec are clean', () {
      final root = Directory.systemTemp.createTempSync('world_no_up_ok_');
      addTearDown(() => root.deleteSync(recursive: true));
      _write(
        root,
        'packages/colonizethis_world/pubspec.yaml',
        'name: colonizethis_world\ndev_dependencies:\n  colonizethis_test:\n',
      );
      _write(
        root,
        'packages/colonizethis_world/test/world/ok_test.dart',
        "import 'package:colonizethis_world/colonizethis_world.dart';\n",
      );

      expect(runCheckWorldTestNoUpstreamDomainDeps(root.path, err: (_) {}), 0);
    });
  });
}
