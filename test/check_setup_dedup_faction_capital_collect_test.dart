import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:test/test.dart';

import '../tool/check_setup_dedup_faction_capital_collect.dart';
import '../tool/check_setup_test_default_init_options.dart';

void main() {
  group('findSetupTestDefaultInitOptionsViolations', () {
    const testPath =
        'packages/colonizethis_setup/test/setup/example_init_test.dart';
    const supportPath =
        'packages/colonizethis_setup/test/setup/init_game_orchestrator_test_support.dart';

    test('flags repeated default InitGameOptions literal', () {
      const src = r'''
runInitGame(
  config: config,
  options: const InitGameOptions(cellSize: 8, renderPng: false),
);
''';
      final violations = findSetupTestDefaultInitOptionsViolations(
        sourcesByPath: {testPath: src},
      );
      expect(violations, hasLength(1));
    });

    test('accepts defaultInitOptions and non-default overrides', () {
      const src = r'''
runInitGame(config: config, options: defaultInitOptions);
runInitGame(config: config, options: const InitGameOptions(renderPng: false));
runInitGame(config: config, options: const InitGameOptions(cellSize: 8, renderPng: true));
''';
      final violations = findSetupTestDefaultInitOptionsViolations(
        sourcesByPath: {testPath: src},
      );
      expect(violations, isEmpty);
    });

    test('exempts test support file that defines defaultInitOptions', () {
      const src = r'''
const defaultInitOptions = InitGameOptions(cellSize: 8, renderPng: false);
''';
      final violations = findSetupTestDefaultInitOptionsViolations(
        sourcesByPath: {supportPath: src},
      );
      expect(violations, isEmpty);
    });

    test('passes on the live setup test tree', () {
      final code = runCheckSetupTestDefaultInitOptions(
        _repoRoot(),
        info: (_) {},
        err: (_) {},
      );
      expect(code, 0);
    });
  });

  group('findSetupDedupFactionCapitalCollectViolations', () {
    const townsPath =
        'packages/colonizethis_setup/lib/src/setup/game_setup_helpers_towns.dart';
    const helperPath =
        'packages/colonizethis_setup/lib/src/setup/faction_setup_helpers.dart';

    test('flags triple-faction capital collection outside helper module', () {
      const src = r'''
for (final p in game.players) {
  if (p.capitalProvinceId != null && p.capitalTile != null) {
    capitalProvinceIdByOwner[p.id] = p.capitalProvinceId!;
  }
}
for (final m in game.minorNations) {}
for (final t in game.tribes) {}
''';
      final violations = findSetupDedupFactionCapitalCollectViolations(
        sourcesByPath: {townsPath: src},
      );
      expect(violations, hasLength(1));
    });

    test('accepts delegation to collectCapitalMapsByOwner', () {
      const src = r'''
final capitalData = collectCapitalMapsByOwner(game);
''';
      final violations = findSetupDedupFactionCapitalCollectViolations(
        sourcesByPath: {townsPath: src},
      );
      expect(violations, isEmpty);
    });

    test('exempts faction_setup_helpers.dart', () {
      const src = r'''
for (final p in game.players) {}
for (final m in game.minorNations) {}
for (final t in game.tribes) {}
capitalProvinceIdByOwner[id] = provinceId;
''';
      final violations = findSetupDedupFactionCapitalCollectViolations(
        sourcesByPath: {helperPath: src},
      );
      expect(violations, isEmpty);
    });

    test('passes on the live setup lib tree', () {
      final code = runCheckSetupDedupFactionCapitalCollect(
        _repoRoot(),
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
