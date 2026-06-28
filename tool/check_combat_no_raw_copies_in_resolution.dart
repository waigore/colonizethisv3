import 'dart:io';

import 'package:path/path.dart' as p;

/// SPEC: SPEC/program/repo-lint.md (Refs #3448, AC5).
///
/// Forbids re-introducing raw `List.from(...)` / `List<ShipInstance>.from(...)`
/// clones of naval ship lists in the combat resolution path. Ship-list copies
/// in `naval_combat_resolver.dart` must route through the canonical
/// `copyNavalShips(...)` helper so the defensive-copy pattern has one site.
///
/// `List<Fleet>.from(...)` and other non-ship collection clones are left alone:
/// they are not ship lists and are out of scope for this rule.
const _navalResolverRelative =
    'packages/colonizethis_combat/lib/src/combat/naval_combat_resolver.dart';

/// Matches a bare `List.from(` clone (untyped — every such site in the naval
/// resolver was a ship-list copy).
final RegExp _bareListFromPattern = RegExp(r'\bList\.from\(');

/// Matches a typed `List<ShipInstance>.from(` clone.
final RegExp _shipListFromPattern = RegExp(
  r'\bList<\s*ShipInstance\s*>\.from\(',
);

/// True when [line] is a pure comment line so a mention in prose is not flagged.
bool _isCommentLine(String line) {
  final trimmed = line.trimLeft();
  return trimmed.startsWith('//') || trimmed.startsWith('*');
}

void main() {
  exit(runCheckCombatNoRawCopiesInResolution(Directory.current.path));
}

/// Used by `ct_repo_lint` in-process; [info] / [err] default to stdout/stderr.
int runCheckCombatNoRawCopiesInResolution(
  String repoRoot, {
  void Function(String line)? info,
  void Function(String line)? err,
}) {
  final logI = info ?? stdout.writeln;
  final logE = err ?? stderr.writeln;
  final root = p.normalize(repoRoot);
  final file = File(p.join(root, _navalResolverRelative));
  if (!file.existsSync()) {
    logI('Combat no-raw-copies check skipped (naval resolver absent).');
    return 0;
  }

  final violations = findCombatRawCopyViolations(
    relativePath: _navalResolverRelative,
    source: file.readAsStringSync(),
  );

  if (violations.isEmpty) {
    logI('Combat no-raw-copies check passed.');
    return 0;
  }

  logE(
    'ERROR: Found raw ship-list clones in the naval combat resolver. Use the '
    'canonical copyNavalShips(...) helper instead of List.from(...) / '
    'List<ShipInstance>.from(...).',
  );
  for (final v in violations) {
    logE('${v.path}:${v.line} ${v.message}');
  }
  return 1;
}

List<CombatRawCopyViolation> findCombatRawCopyViolations({
  required String relativePath,
  required String source,
}) {
  final lines = source.split('\n');
  final violations = <CombatRawCopyViolation>[];
  for (var i = 0; i < lines.length; i++) {
    final line = lines[i];
    if (_isCommentLine(line)) continue;
    if (_bareListFromPattern.hasMatch(line) ||
        _shipListFromPattern.hasMatch(line)) {
      violations.add(
        CombatRawCopyViolation(
          path: relativePath,
          line: i + 1,
          message:
              'Raw ship-list clone detected; call copyNavalShips(...) instead.',
        ),
      );
    }
  }
  return violations;
}

class CombatRawCopyViolation {
  const CombatRawCopyViolation({
    required this.path,
    required this.line,
    required this.message,
  });

  final String path;
  final int line;
  final String message;
}
