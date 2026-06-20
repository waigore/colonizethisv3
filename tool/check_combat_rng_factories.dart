import 'dart:io';

import 'package:path/path.dart' as p;

/// SPEC: SPEC/program/repo-lint.md / SPEC/program/combat-resolution.md (Refs #3448).
///
/// Enforces the single combat-RNG seam (#3448, AC6): every random-number
/// generator used by combat resolution must be constructed through the named
/// factory functions in `combat_rng.dart`. Direct `Random(...)` /
/// `DeterministicRng(...)` construction anywhere else under
/// `packages/colonizethis_combat/lib/src` is a violation.
///
/// Two files are exempt because they *are* the seam / its implementation:
/// - `combat_rng.dart` — the factory module itself.
/// - `deterministic_rng.dart` — the LCG implementation `DeterministicRng`
///   constructor lives here and is wrapped by `navalCombatRng`.
const _combatLibSrcDir = 'packages/colonizethis_combat/lib/src';

const _combatRngRelative =
    'packages/colonizethis_combat/lib/src/combat/combat_rng.dart';
const _deterministicRngRelative =
    'packages/colonizethis_combat/lib/src/combat/deterministic_rng.dart';

/// Matches a direct construction of a combat RNG, e.g. `Random(seed)`,
/// `math.Random(...)`, or `DeterministicRng(seed)`. A type annotation such as
/// `Random rng` has no `(` and is not matched.
final RegExp _rngConstructionPattern = RegExp(
  r'\b(?:Random|DeterministicRng)\(',
);

/// True when [line] is a pure comment line so a mention in prose is not flagged.
bool _isCommentLine(String line) {
  final trimmed = line.trimLeft();
  return trimmed.startsWith('//') || trimmed.startsWith('*');
}

void main() {
  exit(runCheckCombatRngFactories(Directory.current.path));
}

/// Used by `ct_repo_lint` in-process; [info] / [err] default to stdout/stderr.
int runCheckCombatRngFactories(
  String repoRoot, {
  void Function(String line)? info,
  void Function(String line)? err,
}) {
  final logI = info ?? stdout.writeln;
  final logE = err ?? stderr.writeln;
  final root = p.normalize(repoRoot);
  final dir = Directory(p.join(root, _combatLibSrcDir));
  if (!dir.existsSync()) {
    logI('Combat RNG factory check skipped (combat lib dir absent).');
    return 0;
  }

  final violations = <CombatRngFactoryViolation>[];
  for (final entity in dir.listSync(recursive: true)) {
    if (entity is! File) continue;
    if (!entity.path.endsWith('.dart')) continue;
    if (entity.path.endsWith('.g.dart')) continue;
    final relativePath = p.relative(entity.path, from: root);
    violations.addAll(
      findCombatRngFactoryViolations(
        relativePath: relativePath,
        source: entity.readAsStringSync(),
      ),
    );
  }

  if (violations.isEmpty) {
    logI('Combat RNG factory check passed.');
    return 0;
  }

  logE(
    'ERROR: Found direct RNG construction in the combat package. Route every '
    'combat RNG through a factory in combat_rng.dart (preCombatBindingRng, '
    'battleAssignmentRng, quickBattleRng, probabilisticEngagementRng, '
    'navalCombatRng) instead of constructing Random(...) / '
    'DeterministicRng(...) inline.',
  );
  for (final v in violations) {
    logE('${v.path}:${v.line} ${v.message}');
  }
  return 1;
}

List<CombatRngFactoryViolation> findCombatRngFactoryViolations({
  required String relativePath,
  required String source,
}) {
  final normalized = relativePath.replaceAll('\\', '/');
  if (normalized == _combatRngRelative ||
      normalized == _deterministicRngRelative) {
    return const [];
  }
  final lines = source.split('\n');
  final violations = <CombatRngFactoryViolation>[];
  for (var i = 0; i < lines.length; i++) {
    final line = lines[i];
    if (_isCommentLine(line)) continue;
    if (_rngConstructionPattern.hasMatch(line)) {
      violations.add(
        CombatRngFactoryViolation(
          path: relativePath,
          line: i + 1,
          message:
              'Direct RNG construction detected; use a combat_rng.dart factory '
              'instead.',
        ),
      );
    }
  }
  return violations;
}

class CombatRngFactoryViolation {
  const CombatRngFactoryViolation({
    required this.path,
    required this.line,
    required this.message,
  });

  final String path;
  final int line;
  final String message;
}
