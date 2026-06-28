import 'dart:io';

import 'package:path/path.dart' as p;

/// SPEC: SPEC/program/repo-lint.md (Refs #3448, AC5).
///
/// Companion to `repo.combat_no_raw_copies_in_resolution`. That rule eliminates
/// raw ship-list clones in the naval resolver; the copy-disposition table in
/// #3448 also marks several combat-resolution copies as **keep** because they
/// isolate working state the resolver mutates during simulation (they are not
/// defensive ship/unit clones that `copyNavalShips(...)` should absorb).
///
/// This rule keeps those decisions honest: every documented keep-copy site must
/// carry an inline `copy-disposition` rationale marker so the choice stays
/// reviewable and is not silently flipped into an undocumented clone or an
/// accidental `copyNavalShips(...)` candidate. The check is presence-based per
/// file (robust to line movement): if the keep-copy expression is present on a
/// non-comment line, the file must contain a `copy-disposition` rationale
/// comment.
const _keepCopyMarker = 'copy-disposition';

/// Keep-copy sites from the #3448 copy-disposition table, keyed by a distinctive
/// expression so the rule binds to the actual copy rather than any `.toList()`.
const List<_KeepCopySite> _keepCopySites = [
  _KeepCopySite(
    relativePath:
        'packages/colonizethis_combat/lib/src/combat/military_attack_economy.dart',
    expressionLabel: 'List<Player>.from(...)',
    expressionPattern: r'\bList<\s*Player\s*>\.from\(',
  ),
  _KeepCopySite(
    relativePath:
        'packages/colonizethis_combat/lib/src/combat/quick_battle_resolver_engine.dart',
    expressionLabel: 'copyGroups List<String>.from(...)',
    expressionPattern: r'\bList<\s*String\s*>\.from\(',
  ),
  _KeepCopySite(
    relativePath:
        'packages/colonizethis_combat/lib/src/combat/combat_resolver_probabilistic.dart',
    expressionLabel: 'copyWith()).toList()',
    expressionPattern: r'\.copyWith\(\)\)\.toList\(',
  ),
  _KeepCopySite(
    relativePath:
        'packages/colonizethis_combat/lib/src/combat/combat_resolver.dart',
    expressionLabel: 'defenderUnitIds.toList()',
    expressionPattern: r'\bdefenderUnitIds\.toList\(',
  ),
];

/// True when [line] is a pure comment line.
bool _isCommentLine(String line) {
  final trimmed = line.trimLeft();
  return trimmed.startsWith('//') || trimmed.startsWith('*');
}

void main() {
  exit(runCheckCombatDocumentedKeepCopies(Directory.current.path));
}

/// Used by `ct_repo_lint`; [info] / [err] default to stdout/stderr.
int runCheckCombatDocumentedKeepCopies(
  String repoRoot, {
  void Function(String line)? info,
  void Function(String line)? err,
}) {
  final logI = info ?? stdout.writeln;
  final logE = err ?? stderr.writeln;
  final root = p.normalize(repoRoot);

  final violations = <CombatKeepCopyViolation>[];
  var scanned = 0;
  for (final site in _keepCopySites) {
    final file = File(p.join(root, site.relativePath));
    if (!file.existsSync()) continue;
    scanned++;
    violations.addAll(
      findCombatUndocumentedKeepCopies(
        relativePath: site.relativePath,
        expressionLabel: site.expressionLabel,
        expressionPattern: site.expressionPattern,
        source: file.readAsStringSync(),
      ),
    );
  }

  if (scanned == 0) {
    logI('Combat documented keep-copies check skipped (combat files absent).');
    return 0;
  }

  if (violations.isEmpty) {
    logI('Combat documented keep-copies check passed.');
    return 0;
  }

  logE(
    'ERROR: Found a combat keep-copy site without a "$_keepCopyMarker" '
    'rationale marker. Semantically required copies (per #3448 AC5) must be '
    'documented inline so they are not mistaken for raw clones; add a '
    'rationale comment or eliminate the copy.',
  );
  for (final v in violations) {
    logE('${v.path}: ${v.message}');
  }
  return 1;
}

/// Returns a single violation for [relativePath] when its keep-copy expression
/// appears on a non-comment line but the file lacks the `copy-disposition`
/// rationale marker.
List<CombatKeepCopyViolation> findCombatUndocumentedKeepCopies({
  required String relativePath,
  required String expressionLabel,
  required String expressionPattern,
  required String source,
}) {
  final expression = RegExp(expressionPattern);
  final lines = source.split('\n');
  final hasExpression = lines.any(
    (line) => !_isCommentLine(line) && expression.hasMatch(line),
  );
  if (!hasExpression) return const [];

  if (source.contains(_keepCopyMarker)) return const [];

  return [
    CombatKeepCopyViolation(
      path: relativePath,
      message:
          'keep-copy "$expressionLabel" present but no "$_keepCopyMarker" '
          'rationale marker found.',
    ),
  ];
}

class _KeepCopySite {
  const _KeepCopySite({
    required this.relativePath,
    required this.expressionLabel,
    required this.expressionPattern,
  });

  final String relativePath;
  final String expressionLabel;
  final String expressionPattern;
}

class CombatKeepCopyViolation {
  const CombatKeepCopyViolation({required this.path, required this.message});

  final String path;
  final String message;
}
