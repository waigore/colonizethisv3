import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:test/test.dart';

import '../tool/check_economy_dedup_port_tile_keys.dart';

void main() {
  group('findEconomyDedupPortTileKeysViolations', () {
    const sharedHelperPath =
        'packages/colonizethis_economy/lib/src/economy/game_lookup_helpers.dart';
    const consumerPath =
        'packages/colonizethis_economy/lib/src/economy/world_market/purchased_tile_riches.dart';

    test('flags a re-inlined portsByProvinceSeaboard.values.toSet()', () {
      const src = r'''
final portTileKeys = game.worldState.portsByProvinceSeaboard.values.toSet();
''';
      final violations = findEconomyDedupPortTileKeysViolations(
        sourcesByPath: const {consumerPath: src},
      );
      expect(violations, hasLength(1));
      expect(violations.single.message, contains('collectPortTileKeys'));
    });

    test('tolerates whitespace between member accesses', () {
      const src = r'''
final keys = game.worldState.portsByProvinceSeaboard . values . toSet ();
''';
      final violations = findEconomyDedupPortTileKeysViolations(
        sourcesByPath: const {consumerPath: src},
      );
      expect(violations, hasLength(1));
    });

    test('accepts delegation to collectPortTileKeys', () {
      const src = r'''
final portTileKeys = collectPortTileKeys(game);
''';
      final violations = findEconomyDedupPortTileKeysViolations(
        sourcesByPath: const {consumerPath: src},
      );
      expect(violations, isEmpty);
    });

    test('exempts the shared helper module that owns the comprehension', () {
      const src = r'''
Set<String> collectPortTileKeys(Game game) =>
    game.worldState.portsByProvinceSeaboard.values.toSet();
''';
      final violations = findEconomyDedupPortTileKeysViolations(
        sourcesByPath: const {sharedHelperPath: src},
      );
      expect(violations, isEmpty);
    });

    test('ignores the pattern in comment lines', () {
      const src = r'''
// Mirrors the inline portsByProvinceSeaboard.values.toSet() used previously.
/// portsByProvinceSeaboard.values.toSet() was inlined before #3615.
''';
      final violations = findEconomyDedupPortTileKeysViolations(
        sourcesByPath: const {consumerPath: src},
      );
      expect(violations, isEmpty);
    });

    test('passes on the live economy source tree', () {
      final repoRoot = _repoRoot();
      final code = runCheckEconomyDedupPortTileKeys(
        repoRoot,
        info: (_) {},
        err: (_) {},
      );
      expect(code, 0);
    });
  });
}

String _repoRoot() {
  var dir = Directory.current;
  while (true) {
    final manifest = File(
      p.join(dir.path, 'tool', 'ct_repo_lint_manifest.yaml'),
    );
    if (manifest.existsSync()) return dir.path;
    final parent = dir.parent;
    if (parent.path == dir.path) {
      return Directory.current.path;
    }
    dir = parent;
  }
}
