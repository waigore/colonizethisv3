import 'dart:io';

import 'package:path/path.dart' as p;

/// SPEC: SPEC/program/repo-lint.md (Refs #3822).
///
/// Forbids the inline colonial-pressure scale ternary
/// (`colonialPressureWeight != null ? … clamp(0.0, 1.0) … : … ? 1.0 : 0.0`)
/// and the phase-plan null fallback (`phasePlan != null ? … : … ? 1.0 : 0.0`)
/// under `packages/colonizethis_ai/lib/**` outside the canonical helper file.
/// Planner code MUST call `colonialPressureScaleFromWeight` from
/// `planning_helpers.dart` instead.

const _aiLibRelative = 'packages/colonizethis_ai/lib';

const _allowedRelative =
    'packages/colonizethis_ai/lib/src/planning/planning_helpers.dart';

final RegExp _inlineColonialPressureFallback = RegExp(
  r'\?\s*\([^)]+\?\s*1\.0\s*:\s*0\.0\s*\)',
);

void main(List<String> args) {
  exit(runCheckAiDedupColonialPressureScale(Directory.current.path));
}

int runCheckAiDedupColonialPressureScale(
  String repoRoot, {
  void Function(String line)? info,
  void Function(String line)? err,
}) {
  final logI = info ?? stdout.writeln;
  final logE = err ?? stderr.writeln;

  final root = p.normalize(repoRoot);
  final libDir = Directory(p.join(root, _aiLibRelative));
  if (!libDir.existsSync()) {
    logE('ERROR: Missing colonizethis_ai lib directory: $_aiLibRelative');
    return 1;
  }

  final allowedPath = p.normalize(p.join(root, _allowedRelative));
  final violations = <String>[];
  for (final entity in libDir.listSync(recursive: true, followLinks: false)) {
    if (entity is! File || !entity.path.endsWith('.dart')) continue;
    if (p.normalize(entity.path) == allowedPath) continue;
    final relative = p.relative(entity.path, from: root);
    final content = entity.readAsStringSync();
    final match = _inlineColonialPressureFallback.firstMatch(content);
    if (match == null) continue;
    final lineNumber =
        '\n'.allMatches(content.substring(0, match.start)).length + 1;
    violations.add('$relative:$lineNumber');
  }

  if (violations.isEmpty) {
    logI('check_ai_dedup_colonial_pressure_scale: no violations found.');
    return 0;
  }

  logE(
    'check_ai_dedup_colonial_pressure_scale: found ${violations.length} '
    'inline colonial-pressure fallback(s) in $_aiLibRelative. Use '
    '`colonialPressureScaleFromWeight` from planning_helpers.dart instead.',
  );
  for (final v in violations) {
    logE(' - $v');
  }
  return 1;
}
