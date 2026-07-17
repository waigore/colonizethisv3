import 'dart:io';

import 'package:path/path.dart' as p;

/// SPEC: SPEC/program/repo-lint.md (Refs #4037).
///
/// Forbid deleted list-returning relation wrappers under diplomacy lib.
/// Production and tests must use updater factories + [RelationUpsertIndex].
const _diplomacyLibRelative = 'packages/colonizethis_diplomacy/lib';

const _forbiddenTokens = <String>[
  'setWarStateForPair(',
  'applyPeaceForPair(',
  'applyGrantAidModifier(',
  'applySubsidyBoost(',
];

List<String> findDiplomacyListRelationWrapperViolations({
  required String relativePath,
  required String source,
}) {
  if (!relativePath.startsWith('$_diplomacyLibRelative/')) return const [];
  if (!relativePath.endsWith('.dart')) return const [];

  final violations = <String>[];
  final lines = source.split('\n');
  for (var i = 0; i < lines.length; i++) {
    final line = lines[i];
    final trimmed = line.trimLeft();
    if (trimmed.startsWith('//')) continue;
    for (final token in _forbiddenTokens) {
      if (line.contains(token)) {
        violations.add(
          '$relativePath:${i + 1}: forbidden list-wrapper call `$token` '
          '(use updater + RelationUpsertIndex; Refs #4037)',
        );
        break;
      }
    }
  }
  return violations;
}

int runCheckDiplomacyNoListRelationWrappers(
  String repoRoot, {
  void Function(String line)? info,
  void Function(String line)? err,
}) {
  final logI = info ?? stdout.writeln;
  final logE = err ?? stderr.writeln;

  final libDir = Directory(p.join(repoRoot, _diplomacyLibRelative));
  if (!libDir.existsSync()) {
    logE(
      'check_diplomacy_no_list_relation_wrappers: missing $_diplomacyLibRelative',
    );
    return 1;
  }

  final violations = <String>[];
  for (final entity in libDir.listSync(recursive: true)) {
    if (entity is! File || !entity.path.endsWith('.dart')) continue;
    final rel = p.relative(entity.path, from: repoRoot).replaceAll('\\', '/');
    violations.addAll(
      findDiplomacyListRelationWrapperViolations(
        relativePath: rel,
        source: entity.readAsStringSync(),
      ),
    );
  }

  if (violations.isEmpty) {
    logI(
      'check_diplomacy_no_list_relation_wrappers: no deleted list-wrapper '
      'tokens under diplomacy lib.',
    );
    return 0;
  }

  logE(
    'check_diplomacy_no_list_relation_wrappers: ${violations.length} '
    'violation(s):',
  );
  for (final v in violations) {
    logE('  $v');
  }
  return 1;
}

void main() {
  exit(runCheckDiplomacyNoListRelationWrappers(Directory.current.path));
}
