import 'dart:io';

import 'package:path/path.dart' as p;

import 'ct_repo_lint_scan_contract.dart';

/// SPEC: SPEC/program/repo-lint.md (Refs #4022).
///
/// Forbid inline `TileMapGenerator(` under generator integration tests.
/// Prefer shared [runTileMapGeneration] from
/// `test/support/tile_map_gen_fixtures.dart`. Constructor/DI probes may keep
/// a preceding `// map-generation-harness-exempt: <reason>` marker.
const String mapGenerationHarnessExemptMarkerPrefix =
    '// map-generation-harness-exempt:';

final RegExp _inlineTileMapGenerator = RegExp(r'\bTileMapGenerator\s*\(');

/// Fully exempt paths (support harness defines the generator).
const Set<String> mapTestRunGenerationHarnessExemptFiles = {
  'packages/colonizethis_map/test/support/tile_map_gen_fixtures.dart',
};

bool mapTestRunGenerationHarnessPathInScope(String slashPath) {
  final normalized = slashPath.replaceAll('\\', '/');
  if (!normalized.startsWith('packages/colonizethis_map/test/')) {
    return false;
  }
  if (mapTestRunGenerationHarnessExemptFiles.contains(normalized)) {
    return false;
  }
  if (normalized.startsWith('packages/colonizethis_map/test/support/')) {
    return false;
  }
  final base = p.basename(normalized);
  if (base.startsWith('tile_map_generator_') && base.endsWith('_test.dart')) {
    return true;
  }
  if (base.startsWith('tile_map_generation_') && base.endsWith('_test.dart')) {
    return true;
  }
  if (base.startsWith('tile_map_pass4_') && base.endsWith('_test.dart')) {
    return true;
  }
  if (base.startsWith('tile_map_forest_') && base.endsWith('_test.dart')) {
    return true;
  }
  if (base.startsWith('tile_map_terrain_') && base.endsWith('_test.dart')) {
    return true;
  }
  return false;
}

String? mapTestRunGenerationHarnessViolationReason(
  String slashPath,
  String content,
) {
  if (!mapTestRunGenerationHarnessPathInScope(slashPath)) {
    return null;
  }
  final lines = content.split('\n');
  for (var i = 0; i < lines.length; i++) {
    final line = lines[i];
    if (!_inlineTileMapGenerator.hasMatch(line)) {
      continue;
    }
    if (i > 0 &&
        lines[i - 1].trim().startsWith(
          mapGenerationHarnessExemptMarkerPrefix,
        )) {
      continue;
    }
    return 'inline TileMapGenerator( at line ${i + 1}; use '
        'runTileMapGeneration from test/support/tile_map_gen_fixtures.dart or '
        "add '$mapGenerationHarnessExemptMarkerPrefix <reason>' on the "
        'preceding line for constructor/DI probes (Refs #4022)';
  }
  return null;
}

int runCheckMapTestRunGenerationHarness(
  String repoRoot, {
  void Function(String line)? info,
  void Function(String line)? err,
}) {
  final logI = info ?? stdout.writeln;
  final logE = err ?? stderr.writeln;

  final violations = <String>[];
  for (final file in collectRepoLintDomainDartFiles(repoRoot)) {
    final rel = p.relative(file.path, from: repoRoot).replaceAll('\\', '/');
    final reason = mapTestRunGenerationHarnessViolationReason(
      rel,
      file.readAsStringSync(),
    );
    if (reason != null) {
      violations.add('$rel: $reason');
    }
  }

  if (violations.isEmpty) {
    logI(
      'check_map_test_run_generation_harness: no inline TileMapGenerator( '
      'violations.',
    );
    return 0;
  }

  logE(
    'check_map_test_run_generation_harness: ${violations.length} '
    'violation(s):',
  );
  for (final violation in violations) {
    logE(' - $violation');
  }
  return 1;
}

void main() {
  exit(runCheckMapTestRunGenerationHarness(Directory.current.path));
}
