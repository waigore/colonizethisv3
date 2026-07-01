import 'dart:io';

import 'package:path/path.dart' as p;

/// SPEC: SPEC/program/repo-lint.md (Refs #3825).
///
/// Flags resolver functions that call standalone [upsertRelation] more than once
/// in the same body — prefer [RelationUpsertIndex] for batched mutations.
const _diplomacyLibRelative = 'packages/colonizethis_diplomacy/lib';

const _definitionRelative =
    'packages/colonizethis_diplomacy/lib/src/diplomacy/diplomacy_relation_upsert.dart';

const _upsertToken = 'upsertRelation(';

class DiplomacyLoopUpsertViolation {
  const DiplomacyLoopUpsertViolation(this.path, this.line, this.count);
  final String path;
  final int line;
  final int count;
}

List<DiplomacyLoopUpsertViolation> findDiplomacyLoopUpsertViolations({
  required String relativePath,
  required String source,
}) {
  if (relativePath == _definitionRelative) return const [];

  final violations = <DiplomacyLoopUpsertViolation>[];
  final lines = source.split('\n');
  var inFn = false;
  var fnStartLine = 0;
  var braceDepth = 0;
  var upsertCount = 0;

  for (var i = 0; i < lines.length; i++) {
    final line = lines[i];
    final trimmed = line.trimLeft();
    if (!inFn &&
        (trimmed.startsWith('Game ') ||
            trimmed.startsWith('List<DiplomacyRelation> ') ||
            trimmed.startsWith('void ') ||
            trimmed.startsWith('bool ') ||
            trimmed.startsWith('int ') ||
            trimmed.startsWith('String? '))) {
      inFn = true;
      fnStartLine = i + 1;
      braceDepth = 0;
      upsertCount = 0;
    }
    if (!inFn) continue;

    if (!line.trimLeft().startsWith('//') && line.contains(_upsertToken)) {
      upsertCount++;
    }

    braceDepth += '{'.allMatches(line).length;
    braceDepth -= '}'.allMatches(line).length;
    if (braceDepth <= 0 && inFn) {
      if (upsertCount > 1) {
        violations.add(
          DiplomacyLoopUpsertViolation(relativePath, fnStartLine, upsertCount),
        );
      }
      inFn = false;
    }
  }
  return violations;
}

int runCheckDiplomacyNoLoopUpsertRelation(
  String repoRoot, {
  void Function(String line)? info,
  void Function(String line)? err,
}) {
  final logI = info ?? stdout.writeln;
  final logE = err ?? stderr.writeln;
  final root = p.normalize(repoRoot);
  final libDir = Directory(p.join(root, _diplomacyLibRelative));
  if (!libDir.existsSync()) {
    logI('Diplomacy loop-upsert check skipped (lib dir absent).');
    return 0;
  }

  final violations = <DiplomacyLoopUpsertViolation>[];
  for (final entity in libDir.listSync(recursive: true)) {
    if (entity is! File || !entity.path.endsWith('.dart')) continue;
    final relativePath = p.relative(entity.path, from: root);
    violations.addAll(
      findDiplomacyLoopUpsertViolations(
        relativePath: relativePath,
        source: entity.readAsStringSync(),
      ),
    );
  }

  if (violations.isEmpty) {
    logI('Diplomacy loop-upsert check passed.');
    return 0;
  }

  logE(
    'ERROR: Found functions with multiple standalone upsertRelation calls. '
    'Use RelationUpsertIndex for batched relation mutations (Refs #3825).',
  );
  for (final v in violations) {
    logE('${v.path}:${v.line} ($v.count upsertRelation calls)');
  }
  return 1;
}

void main() {
  exit(runCheckDiplomacyNoLoopUpsertRelation(Directory.current.path));
}
