import 'dart:io';

import 'package:test/test.dart';

import '../tool/check_map_no_partfile_classes.dart';

const _genRoot = 'packages/colonizethis_map/lib/src/gen';
const _viewRoot = 'packages/colonizethis_map/lib/src/view';
const _allowedPartOf =
    'packages/colonizethis_map/lib/src/gen/tile_map_generator_types.dart';

void main() {
  group('findMapGenPartDirectiveViolations', () {
    test('flags a `part of` directive in a non-whitelisted gen file', () {
      const src = "part of 'tile_map_generator.dart';\n";
      final violations = findMapGenPartDirectiveViolations(
        relativePath: '$_genRoot/some_pass.dart',
        source: src,
      );
      expect(violations, hasLength(1));
      expect(violations.single.message, contains('part of'));
    });

    test('allows the whitelisted shared-types part file', () {
      const src = "part of 'tile_map_generator.dart';\n";
      final violations = findMapGenPartDirectiveViolations(
        relativePath: _allowedPartOf,
        source: src,
      );
      expect(violations, isEmpty);
    });

    test('allows a `part` directive referencing the whitelisted types file', () {
      const src = "library;\npart 'tile_map_generator_types.dart';\n";
      final violations = findMapGenPartDirectiveViolations(
        relativePath: '$_genRoot/tile_map_generator.dart',
        source: src,
      );
      expect(violations, isEmpty);
    });

    test('flags a `part` directive referencing a non-whitelisted file', () {
      const src = "library;\npart 'some_other_part.dart';\n";
      final violations = findMapGenPartDirectiveViolations(
        relativePath: '$_genRoot/tile_map_generator.dart',
        source: src,
      );
      expect(violations, hasLength(1));
      expect(violations.single.message, contains('some_other_part.dart'));
    });

    test('ignores a standalone library file with no part directives', () {
      const src = 'class ContinentJoinPass {}\n';
      final violations = findMapGenPartDirectiveViolations(
        relativePath: '$_genRoot/tile_map_gen_continent_join_pass.dart',
        source: src,
      );
      expect(violations, isEmpty);
    });
  });

  group('runCheckMapGenNoNewPartfiles', () {
    test('passes on the live repository tree', () {
      final logs = <String>[];
      final code = runCheckMapGenNoNewPartfiles(
        Directory.current.path,
        info: logs.add,
        err: logs.add,
      );
      expect(code, 0, reason: logs.join('\n'));
    });

    test('fails when a gen file reintroduces part-of coupling', () {
      final temp = Directory.systemTemp.createTempSync('check_map_partfile_');
      addTearDown(() => temp.deleteSync(recursive: true));

      File('${temp.path}/$_genRoot/regressed_pass.dart')
        ..createSync(recursive: true)
        ..writeAsStringSync("part of 'tile_map_generator.dart';\n");
      Directory('${temp.path}/$_viewRoot').createSync(recursive: true);

      final logs = <String>[];
      final code = runCheckMapGenNoNewPartfiles(
        temp.path,
        scanRoots: const [_genRoot, _viewRoot],
        info: logs.add,
        err: logs.add,
      );

      expect(code, 1);
      expect(logs.join('\n'), contains('regressed_pass.dart'));
    });

    test('fails when a scanned root is missing (anti-rot existence check)', () {
      final temp = Directory.systemTemp.createTempSync('check_map_partfile_gone_');
      addTearDown(() => temp.deleteSync(recursive: true));

      final logs = <String>[];
      final code = runCheckMapGenNoNewPartfiles(
        temp.path,
        scanRoots: const [_genRoot, _viewRoot],
        info: logs.add,
        err: logs.add,
      );

      expect(code, 1);
      expect(logs.join('\n'), contains('not found'));
    });
  });
}
