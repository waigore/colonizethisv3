import 'dart:io';

import 'package:path/path.dart' as p;

/// SPEC: SPEC/program/repo-lint.md (Refs #4028).
///
/// Forbid raw `diplomacyRelations: relationsIndex.toList()` outside the
/// canonical commit helpers in `diplomacy_relation_upsert.dart`.
const _diplomacyLibRelative = 'packages/colonizethis_diplomacy/lib';

const _helperRelative =
    'packages/colonizethis_diplomacy/lib/src/diplomacy/diplomacy_relation_upsert.dart';

/// Matches `diplomacyRelations: relationsIndex.toList()` with optional spacing
/// / line breaks between tokens.
final RegExp _rawCommitPattern = RegExp(
  r'diplomacyRelations\s*:\s*relationsIndex\s*\.\s*toList\s*\(\s*\)',
  multiLine: true,
);

List<String> findDiplomacyRelationUpsertCommitViolations({
  required String relativePath,
  required String source,
}) {
  if (relativePath == _helperRelative) return const [];
  if (!relativePath.startsWith('$_diplomacyLibRelative/')) return const [];
  if (!relativePath.endsWith('.dart')) return const [];
  if (!_rawCommitPattern.hasMatch(source)) return const [];
  return [
    '$relativePath: use committedRelations(...) / withCommittedRelations(...) '
        'instead of diplomacyRelations: relationsIndex.toList() (Refs #4028)',
  ];
}

int runCheckDiplomacyRelationUpsertCommit(
  String repoRoot, {
  void Function(String line)? info,
  void Function(String line)? err,
}) {
  final logI = info ?? stdout.writeln;
  final logE = err ?? stderr.writeln;

  final libDir = Directory(p.join(repoRoot, _diplomacyLibRelative));
  if (!libDir.existsSync()) {
    logE('check_diplomacy_relation_upsert_commit: missing $_diplomacyLibRelative');
    return 1;
  }

  final violations = <String>[];
  for (final entity in libDir.listSync(recursive: true)) {
    if (entity is! File || !entity.path.endsWith('.dart')) continue;
    final rel = p.relative(entity.path, from: repoRoot).replaceAll('\\', '/');
    violations.addAll(
      findDiplomacyRelationUpsertCommitViolations(
        relativePath: rel,
        source: entity.readAsStringSync(),
      ),
    );
  }

  if (violations.isEmpty) {
    logI(
      'check_diplomacy_relation_upsert_commit: no raw relationsIndex.toList() '
      'commit sites outside the helper.',
    );
    return 0;
  }
  logE(
    'check_diplomacy_relation_upsert_commit: ${violations.length} violation(s):',
  );
  for (final v in violations) {
    logE('  $v');
  }
  return 1;
}

void main() {
  exit(runCheckDiplomacyRelationUpsertCommit(Directory.current.path));
}
