// Forbid duplicated legend-height arithmetic outside the shared layout helper.
// SPEC/program/repo-lint.md (`repo.map_render_legend_layout_dedup`, Refs #4112).
import 'dart:io';

import 'package:path/path.dart' as p;

import 'ct_repo_lint_scan_contract.dart';

const String _inlineLegendHeightPattern =
    'legendPadding * 2 + legendLines * legendLineHeight';

/// Canonical owner for [legendHeightForLineCount].
const String mapRenderLegendLayoutOwnerRelativePath =
    'packages/colonizethis_map/lib/src/render/tile_map_visualization_legend_layout.dart';

/// Files permitted to contain the inline arithmetic (tests documenting the helper).
const Set<String> mapRenderLegendLayoutDedupExemptFiles = {
  'packages/colonizethis_map/test/tile_map_visualization_legend_layout_test.dart',
};

final RegExp _inlineLegendHeightExpr = RegExp(
  r'legendPadding\s*\*\s*2\s*\+\s*legendLines\s*\*\s*legendLineHeight',
);

bool mapRenderLegendLayoutDedupPathInScope(String slashPath) {
  final normalized = slashPath.replaceAll('\\', '/');
  if (normalized == mapRenderLegendLayoutOwnerRelativePath) {
    return false;
  }
  if (mapRenderLegendLayoutDedupExemptFiles.contains(normalized)) {
    return false;
  }
  if (!normalized.startsWith('packages/colonizethis_map/')) {
    return false;
  }
  return normalized.endsWith('.dart');
}

String? mapRenderLegendLayoutDedupViolationReason(String content) {
  final withoutFullLineComments = content
      .split('\n')
      .where((line) {
        final trimmed = line.trimLeft();
        return !trimmed.startsWith('//') && !trimmed.startsWith('*');
      })
      .join('\n');
  if (_inlineLegendHeightExpr.hasMatch(withoutFullLineComments)) {
    return 'use legendHeightForLineCount(legendLines) from '
        'tile_map_visualization_legend_layout.dart instead of inline '
        '$_inlineLegendHeightPattern (Refs #4112)';
  }
  return null;
}

int runCheckMapRenderLegendLayoutDedup(
  String repoRoot, {
  void Function(String line)? info,
  void Function(String line)? err,
}) {
  final logI = info ?? stdout.writeln;
  final logE = err ?? stderr.writeln;

  final violations = <String>[];
  for (final file in collectRepoLintDomainDartFiles(repoRoot)) {
    final rel = p.relative(file.path, from: repoRoot).replaceAll('\\', '/');
    if (!mapRenderLegendLayoutDedupPathInScope(rel)) {
      continue;
    }
    final reason = mapRenderLegendLayoutDedupViolationReason(
      file.readAsStringSync(),
    );
    if (reason != null) {
      violations.add('$rel: $reason');
    }
  }

  if (violations.isEmpty) {
    logI('check_map_render_legend_layout_dedup: no inline legend-height violations.');
    return 0;
  }

  logE(
    'check_map_render_legend_layout_dedup: ${violations.length} violation(s):',
  );
  for (final violation in violations) {
    logE(' - $violation');
  }
  return 1;
}

void main() {
  exit(runCheckMapRenderLegendLayoutDedup(Directory.current.path));
}
