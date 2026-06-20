import 'dart:io';

import 'package:path/path.dart' as p;

/// SPEC: SPEC/program/repo-lint.md (Refs #3278).
///
/// Enforces the shared weight-scaling contract for `colonizethis_ai`:
/// `lib/**` filter/scoring code must call the shared
/// `scaleWeightedBonus(weight, baseConstant)` helper instead of re-inlining
/// the `<= 0.0 → return 0`, clamp-to-`1.0`, `(baseConstant * clamped).round()`
/// weight-scaling idiom.
///
/// The single canonical home (`lib/src/planning/planning_helpers.dart`) is the
/// only file allowed to contain the idiom.
///
/// Detection matches the full canonical body shape: a `<= 0.0) { return 0; }`
/// guard, a `final clamped = <id> > 1.0 ? 1.0 : <id>;` clamp, and a
/// `return (<factor> * clamped).round();` rounded scale. Sites with a
/// different guard return (for example `return null;` /
/// `return uncappedThreshold;`) or a different return shape (a non-rounded
/// `baseBonus * clamped`, or a `(threshold - span * clamped)` span formula)
/// are intentionally not flagged because they do not map onto
/// `scaleWeightedBonus`.

const _aiLibRelative = 'packages/colonizethis_ai/lib';

/// Canonical home of `scaleWeightedBonus` — the only allowed idiom site.
const _allowedRelative =
    'packages/colonizethis_ai/lib/src/planning/planning_helpers.dart';

/// `<= 0.0) { return 0; } final clamped = X > 1.0 ? 1.0 : X; return (Y *
/// clamped).round();` — the full body replaceable by `scaleWeightedBonus`.
final RegExp _inlineWeightScaleClamp = RegExp(
  r'<=\s*0\.0\s*\)\s*\{\s*return\s+0\s*;\s*\}\s*'
  r'final\s+clamped\s*=\s*\w+\s*>\s*1\.0\s*\?\s*1\.0\s*:\s*\w+\s*;\s*'
  r'return\s*\(\s*[^;()]*?\*\s*clamped\s*\)\s*\.round\(\)\s*;',
);

void main(List<String> args) {
  exit(runCheckAiDedupWeightScaleClamp(Directory.current.path));
}

int runCheckAiDedupWeightScaleClamp(
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
    final match = _inlineWeightScaleClamp.firstMatch(content);
    if (match == null) continue;
    final lineNumber =
        '\n'.allMatches(content.substring(0, match.start)).length + 1;
    violations.add('$relative:$lineNumber');
  }

  if (violations.isEmpty) {
    logI('check_ai_dedup_weight_scale_clamp: no violations found.');
    return 0;
  }

  logE(
    'check_ai_dedup_weight_scale_clamp: found ${violations.length} inline '
    'weight-scale clamp idiom(s) in $_aiLibRelative. Use the shared '
    '`scaleWeightedBonus(weight, baseConstant)` helper from '
    'src/planning/planning_helpers.dart instead.',
  );
  for (final v in violations) {
    logE(' - $v');
  }
  return 1;
}
