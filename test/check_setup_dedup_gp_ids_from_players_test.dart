import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:test/test.dart';

import '../tool/check_setup_dedup_gp_ids_from_players.dart';

void main() {
  group('findSetupDedupGpIdsFromPlayersViolations', () {
    const sharedModulePath =
        'packages/colonizethis_setup/lib/src/setup/gp_old_world_tile_scan.dart';
    const resourcePath =
        'packages/colonizethis_setup/lib/src/setup/gp_old_world_resource_redistribution.dart';
    const terrainPath =
        'packages/colonizethis_setup/lib/src/setup/gp_old_world_terrain_redistribution.dart';

    test('flags a re-inlined toList() GP-id projection', () {
      const src = r'''
final gpIdsSorted = game.players.map((p) => p.id).toList();
final gpIds = gpIdsSorted.toSet();
''';
      final violations = findSetupDedupGpIdsFromPlayersViolations(
        sourcesByPath: const {terrainPath: src},
      );
      expect(violations, hasLength(1));
      expect(violations.single.line, 1);
      expect(violations.single.message, contains('gpIdsSortedFromPlayers'));
    });

    test('flags a re-inlined toSet() projection with any variable name', () {
      const src = r'''
final gpIds = game.players.map((x) => x.id).toSet();
''';
      final violations = findSetupDedupGpIdsFromPlayersViolations(
        sourcesByPath: const {resourcePath: src},
      );
      expect(violations, hasLength(1));
    });

    test('accepts delegation to gpIdsSortedFromPlayers', () {
      const src = r'''
final gpIdsSorted = gpIdsSortedFromPlayers(game);
final gpIds = gpIdsSorted.toSet();
''';
      final violations = findSetupDedupGpIdsFromPlayersViolations(
        sourcesByPath: const {resourcePath: src},
      );
      expect(violations, isEmpty);
    });

    test('exempts the shared module that owns the canonical helper', () {
      const src = r'''
List<String> gpIdsSortedFromPlayers(Game game) => [
  for (final p in game.players) p.id,
];
// even an inline players.map((p) => p.id) here is allowed for the canonical source.
''';
      final violations = findSetupDedupGpIdsFromPlayersViolations(
        sourcesByPath: const {sharedModulePath: src},
      );
      expect(violations, isEmpty);
    });

    test('ignores the pattern when it only appears in comment lines', () {
      const src = r'''
// previously: game.players.map((p) => p.id).toList()
/// gpIdsSortedFromPlayers replaces players.map((p) => p.id) per #3449.
''';
      final violations = findSetupDedupGpIdsFromPlayersViolations(
        sourcesByPath: const {terrainPath: src},
      );
      expect(violations, isEmpty);
    });

    test('passes on the live setup source tree', () {
      final repoRoot = _repoRoot();
      final code = runCheckSetupDedupGpIdsFromPlayers(
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
