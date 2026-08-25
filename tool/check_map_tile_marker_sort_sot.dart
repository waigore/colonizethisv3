// Forbid inlined y/x/tileKey sorts under map view (Refs #4654).
// SPEC/program/repo-lint.md (`repo.map_tile_marker_sort_sot`).
import 'dart:io';

import 'package:path/path.dart' as p;

import 'ct_repo_lint_scan_contract.dart';

const String mapTileMarkerSortOwnerRelativePath =
    'packages/colonizethis_map/lib/src/view/init_game_map_view_tile_marker_sort.dart';

final RegExp _inlineTileMarkerSort = RegExp(
  r'\.y\.compareTo\([\s\S]{0,120}\.x\.compareTo[\s\S]{0,120}tileKey\.compareTo',
);

bool mapTileMarkerSortSotPathInScope(String slashPath) {
  final normalized = slashPath.replaceAll('\\', '/');
  if (normalized == mapTileMarkerSortOwnerRelativePath) {
    return false;
  }
  if (!normalized.startsWith('packages/colonizethis_map/lib/src/view/')) {
    return false;
  }
  return normalized.endsWith('.dart');
}

String? mapTileMarkerSortSotViolationReason(String content) {
  final withoutFullLineComments = content
      .split('\n')
      .where((line) {
        final trimmed = line.trimLeft();
        return !trimmed.startsWith('//') && !trimmed.startsWith('*');
      })
      .join('\n');
  if (_inlineTileMarkerSort.hasMatch(withoutFullLineComments)) {
    return 'use sortTileAnchoredMarkers / compareTileAnchoredMarkerOrder '
        'from init_game_map_view_tile_marker_sort.dart instead of inlining '
        'y/x/tileKey sorts (Refs #4654)';
  }
  return null;
}

int runCheckMapTileMarkerSortSot(
  String repoRoot, {
  void Function(String line)? info,
  void Function(String line)? err,
}) {
  final logI = info ?? stdout.writeln;
  final logE = err ?? stderr.writeln;

  final violations = <String>[];
  for (final file in collectRepoLintDomainDartFiles(repoRoot)) {
    final rel = p.relative(file.path, from: repoRoot).replaceAll('\\', '/');
    if (!mapTileMarkerSortSotPathInScope(rel)) {
      continue;
    }
    final reason = mapTileMarkerSortSotViolationReason(file.readAsStringSync());
    if (reason != null) {
      violations.add('$rel: $reason');
    }
  }

  if (violations.isEmpty) {
    logI(
      'check_map_tile_marker_sort_sot: no inline tile-marker sort violations.',
    );
    return 0;
  }

  logE('check_map_tile_marker_sort_sot: ${violations.length} violation(s):');
  for (final violation in violations) {
    logE(' - $violation');
  }
  return 1;
}

void main() {
  exit(runCheckMapTileMarkerSortSot(Directory.current.path));
}
