import 'dart:io';

import 'package:path/path.dart' as p;

import 'ct_repo_lint_scan_contract.dart';

/// Hard cap on `init_game_map_view_builder_*_test.dart` files under the map
/// package `test/` after the #3846 view-builder consolidation (Refs #3846).
const int mapTestViewBuilderFileCountMax = 4;

const String _mapViewBuilderTestGlobPrefix =
    'packages/colonizethis_map/test/init_game_map_view_builder_';

/// True when [slashPath] is a view-builder test file counted by the gate.
bool mapTestViewBuilderFileCountPathInScope(String slashPath) {
  final normalized = slashPath.replaceAll('\\', '/');
  if (!normalized.startsWith(_mapViewBuilderTestGlobPrefix)) {
    return false;
  }
  return normalized.endsWith('_test.dart');
}

int runCheckMapTestViewBuilderFileCount(
  String repoRoot, {
  void Function(String line)? info,
  void Function(String line)? err,
}) {
  final logI = info ?? stdout.writeln;
  final logE = err ?? stderr.writeln;

  final matches = <String>[];
  for (final file in collectRepoLintDomainDartFiles(repoRoot)) {
    final rel = p.relative(file.path, from: repoRoot).replaceAll('\\', '/');
    if (mapTestViewBuilderFileCountPathInScope(rel)) {
      matches.add(rel);
    }
  }
  matches.sort();

  if (matches.length <= mapTestViewBuilderFileCountMax) {
    logI(
      'check_map_test_view_builder_file_count: ${matches.length} file(s) '
      '(cap $mapTestViewBuilderFileCountMax).',
    );
    return 0;
  }

  logE(
    'check_map_test_view_builder_file_count: found ${matches.length} '
    'init_game_map_view_builder_*_test.dart files (hard cap '
    '$mapTestViewBuilderFileCountMax; consolidate per #3846):',
  );
  for (final match in matches) {
    logE(' - $match');
  }
  return 1;
}

void main() {
  exit(runCheckMapTestViewBuilderFileCount(Directory.current.path));
}
