import 'dart:io';

import 'package:path/path.dart' as p;

/// SPEC: SPEC/program/repo-lint.md (Refs #3562 AC7).
///
/// Enforces that overture-clearing pair filters in `colonizethis_diplomacy`
/// route through the canonical `clearOverturesBetweenGpAndFaction` helper in
/// `diplomacy_shared_helpers.dart` instead of re-inlining a negated GP/target
/// pair filter (for example
/// `overtures.where((o) => !(o.gpId == x && o.targetId == y))`).
///
/// The forbidden shape is a `.where(...)` predicate that **negates** a
/// GP/target pair match — `!(` together with both `.gpId` and `.targetId`
/// inside the same closure body. Positive lookups (`firstWhere` / `indexWhere`
/// style equality), single-faction teardown filters (`!=` on one id), and
/// pair-key set membership diffs do not match this signature.
const _diplomacyLibRelative = 'packages/colonizethis_diplomacy/lib';

/// The canonical helper lives here; it is exempt from the rule.
const _canonicalHelperRelative =
    'packages/colonizethis_diplomacy/lib/src/diplomacy/diplomacy_shared_helpers.dart';

class OvertureClearViolation {
  const OvertureClearViolation(this.path, this.line, this.message);
  final String path;
  final int line;
  final String message;
}

/// Returns the body text (between the outer parentheses) of every `.where(`
/// call in [source], paired with the source offset where the body begins.
List<({String body, int offset})> _whereCallBodies(String source) {
  const marker = '.where(';
  final results = <({String body, int offset})>[];
  var searchFrom = 0;
  while (true) {
    final start = source.indexOf(marker, searchFrom);
    if (start < 0) break;
    final bodyStart = start + marker.length;
    var depth = 1;
    var i = bodyStart;
    for (; i < source.length && depth > 0; i++) {
      final c = source[i];
      if (c == '(') depth++;
      if (c == ')') depth--;
    }
    final bodyEnd = depth == 0 ? i - 1 : source.length;
    results.add((
      body: source.substring(bodyStart, bodyEnd),
      offset: bodyStart,
    ));
    searchFrom = bodyEnd + 1;
  }
  return results;
}

int _lineForOffset(String source, int offset) =>
    '\n'.allMatches(source.substring(0, offset)).length + 1;

/// Flags inline overture pair-clearing `.where(` predicates in [source].
List<OvertureClearViolation> findOvertureClearViolations({
  required String relativePath,
  required String source,
}) {
  final violations = <OvertureClearViolation>[];
  for (final call in _whereCallBodies(source)) {
    final body = call.body;
    final negates = body.contains('!(');
    final touchesGp = body.contains('.gpId');
    final touchesTarget = body.contains('.targetId');
    if (negates && touchesGp && touchesTarget) {
      violations.add(
        OvertureClearViolation(
          relativePath,
          _lineForOffset(source, call.offset),
          'inline overture pair-clear filter; use '
          'clearOverturesBetweenGpAndFaction() from '
          'diplomacy_shared_helpers.dart instead.',
        ),
      );
    }
  }
  return violations;
}

int runCheckDiplomacyNoDuplicateOvertureClear(
  String repoRoot, {
  void Function(String line)? info,
  void Function(String line)? err,
}) {
  final logI = info ?? stdout.writeln;
  final logE = err ?? stderr.writeln;
  final root = p.normalize(repoRoot);
  final libDir = Directory(p.join(root, _diplomacyLibRelative));
  if (!libDir.existsSync()) {
    logI('Diplomacy overture-clear dedup check skipped (lib dir absent).');
    return 0;
  }

  final violations = <OvertureClearViolation>[];
  for (final entity in libDir.listSync(recursive: true)) {
    if (entity is! File || !entity.path.endsWith('.dart')) continue;
    final relativePath = p.relative(entity.path, from: root);
    if (relativePath == _canonicalHelperRelative) continue;
    violations.addAll(
      findOvertureClearViolations(
        relativePath: relativePath,
        source: entity.readAsStringSync(),
      ),
    );
  }

  if (violations.isEmpty) {
    logI('Diplomacy overture-clear dedup check passed.');
    return 0;
  }

  logE(
    'ERROR: Found inline overture-clearing filters outside the canonical helper.',
  );
  for (final v in violations) {
    logE('${v.path}:${v.line} ${v.message}');
  }
  return 1;
}

void main() {
  exit(runCheckDiplomacyNoDuplicateOvertureClear(Directory.current.path));
}
