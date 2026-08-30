import 'dart:io';

import 'package:path/path.dart' as p;

/// SPEC: SPEC/program/repo-lint.md (Refs #4559).
///
/// Forbid isomorphic civilian inline-action record field names under
/// `app/lib/features/game/**`. Upgrade-town keeps a 4-field record with
/// `hasBuilderUnits`; 3-bool civilian remaps must use `hasMatchingUnits`.
const _scopePrefix = 'app/lib/features/game/';
const _forbiddenFieldNames = [
  'hasEngineerUnits',
  'hasExplorerUnits',
  'hasRailBuilderUnits',
  'hasMerchantUnits',
];

const _overlayHostPaths = {
  'app/lib/features/game/widgets/province_overlay/province_sea_zone_detail_overlay_widget.dart':
      280,
  'app/lib/features/game/widgets/province_overlay/province_sea_zone_detail_overlay_province_content.dart':
      280,
};

final _forbiddenFieldPattern = RegExp(
  r'\b(?:hasEngineerUnits|hasExplorerUnits|hasRailBuilderUnits|hasMerchantUnits)\b',
);

/// Matches 3-bool civilian remaps using `hasBuilderUnits` (upgrade-town uses 4).
final _threeFieldBuilderRemapPattern = RegExp(
  r'\(\{[^}]*\bbool\s+show(?:Icon|Control)[^}]*\bbool\s+enabled[^}]*\bbool\s+hasBuilderUnits\b[^}]*\}\)',
);

class AppProvinceInlineActionStateViolation {
  const AppProvinceInlineActionStateViolation({
    required this.path,
    required this.line,
    required this.reason,
  });

  final String path;
  final int line;
  final String reason;
}

bool appProvinceInlineActionStatePathInScope(String slashPath) {
  final normalized = slashPath.replaceAll('\\', '/');
  return normalized.startsWith(_scopePrefix) && normalized.endsWith('.dart');
}

List<AppProvinceInlineActionStateViolation> findAppProvinceInlineActionStateViolations({
  required String relativePath,
  required String source,
}) {
  final out = <AppProvinceInlineActionStateViolation>[];
  final lines = source.split('\n');
  for (var i = 0; i < lines.length; i++) {
    final line = lines[i];
    if (_forbiddenFieldPattern.hasMatch(line)) {
      out.add(
        AppProvinceInlineActionStateViolation(
          path: relativePath,
          line: i + 1,
          reason: 'forbidden civilian inline-action field name on line',
        ),
      );
    }
    final remap = _threeFieldBuilderRemapPattern.firstMatch(line);
    if (remap != null) {
      final snippet = remap.group(0)!;
      if (!snippet.contains('townTileKey') && !snippet.contains('showControl')) {
        out.add(
          AppProvinceInlineActionStateViolation(
            path: relativePath,
            line: i + 1,
            reason:
                '3-field record uses hasBuilderUnits; use ProvinceInlineActionState / hasMatchingUnits',
          ),
        );
      }
    }
  }
  return out;
}

List<AppProvinceInlineActionStateViolation> findOverlayHostLineViolations(
  String repoRoot,
) {
  final out = <AppProvinceInlineActionStateViolation>[];
  for (final entry in _overlayHostPaths.entries) {
    final file = File(p.join(repoRoot, entry.key));
    if (!file.existsSync()) {
      out.add(
        AppProvinceInlineActionStateViolation(
          path: entry.key,
          line: 1,
          reason: 'overlay host file missing',
        ),
      );
      continue;
    }
    final lineCount = file.readAsLinesSync().length;
    if (lineCount > entry.value) {
      out.add(
        AppProvinceInlineActionStateViolation(
          path: entry.key,
          line: lineCount,
          reason:
              'overlay host has $lineCount physical lines (max ${entry.value})',
        ),
      );
    }
  }
  return out;
}

int runCheckAppProvinceInlineActionState(
  String repoRoot, {
  void Function(String line)? info,
  void Function(String line)? err,
}) {
  final logI = info ?? stdout.writeln;
  final logE = err ?? stderr.writeln;
  final violations = <AppProvinceInlineActionStateViolation>[];
  final scopeDir = Directory(p.join(repoRoot, 'app', 'lib', 'features', 'game'));
  if (!scopeDir.existsSync()) {
    logE('check_app_province_inline_action_state: scope dir not found');
    return 1;
  }

  for (final entity in scopeDir.listSync(recursive: true)) {
    if (entity is! File || !entity.path.endsWith('.dart')) {
      continue;
    }
    final rel = p.relative(entity.path, from: repoRoot).replaceAll('\\', '/');
    if (!appProvinceInlineActionStatePathInScope(rel)) {
      continue;
    }
    violations.addAll(
      findAppProvinceInlineActionStateViolations(
        relativePath: rel,
        source: entity.readAsStringSync(),
      ),
    );
  }

  violations.addAll(findOverlayHostLineViolations(repoRoot));

  if (violations.isEmpty) {
    logI(
      'check_app_province_inline_action_state: no forbidden inline-action '
      'field names; overlay hosts within line budget.',
    );
    return 0;
  }

  logE(
    'check_app_province_inline_action_state: ${violations.length} violation(s):',
  );
  for (final v in violations) {
    logE(' - ${v.path}:${v.line} ${v.reason} (Refs #4559).');
  }
  return 1;
}

void main() {
  exit(runCheckAppProvinceInlineActionState(Directory.current.path));
}
