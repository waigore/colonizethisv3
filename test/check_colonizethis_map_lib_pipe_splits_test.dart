import 'dart:io';

import 'package:test/test.dart';

import '../tool/check_colonizethis_map_lib_pipe_splits.dart';

void main() {
  group('findColonizethisMapLibPipeSplitViolations', () {
    test('allows .split only in tile_key_util.dart', () {
      const src = "final parts = tileKey.split('|');\n";
      expect(
        findColonizethisMapLibPipeSplitViolations(
          relativePath: 'packages/colonizethis_map/lib/src/tile_key_util.dart',
          source: src,
        ),
        isEmpty,
      );
    });

    test('flags .split in other map lib files', () {
      const src = "void f(String k) {\n  final p = k.split('|');\n}\n";
      final v = findColonizethisMapLibPipeSplitViolations(
        relativePath: 'packages/colonizethis_map/lib/src/other.dart',
        source: src,
      );
      expect(v, isNotEmpty);
      expect(v.first.line, 2);
    });

    test('ignores paths outside colonizethis_map lib', () {
      const src = "void f(String k) {\n  final p = k.split('|');\n}\n";
      expect(
        findColonizethisMapLibPipeSplitViolations(
          relativePath: 'packages/colonizethis_logic/lib/x.dart',
          source: src,
        ),
        isEmpty,
      );
    });

    test('repo map package lib passes gate', () {
      expect(runCheckColonizethisMapLibPipeSplits(Directory.current.path), 0);
    });
  });
}
