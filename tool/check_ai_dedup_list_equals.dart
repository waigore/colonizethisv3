import 'dart:io';

import 'package:path/path.dart' as p;

/// SPEC: SPEC/program/repo-lint.md (Refs #3822).
///
/// Forbids local `_listEquals` / `_colonialListEquals` definitions under
/// `packages/colonizethis_ai/lib/**` outside the canonical helper file.
/// Phase planner value types MUST call `planningListEquals` from
/// `planning_helpers.dart` instead.

const _aiLibRelative = 'packages/colonizethis_ai/lib';

const _allowedRelative =
    'packages/colonizethis_ai/lib/src/planning/planning_helpers.dart';

final RegExp _localListEqualsDefinition = RegExp(
  r'bool\s+_(?:colonial)?[Ll]istEquals\s*\(',
);

void main(List<String> args) {
  exit(runCheckAiDedupListEquals(Directory.current.path));
}

int runCheckAiDedupListEquals(
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
    final match = _localListEqualsDefinition.firstMatch(content);
    if (match == null) continue;
    final lineNumber =
        '\n'.allMatches(content.substring(0, match.start)).length + 1;
    violations.add('$relative:$lineNumber');
  }

  if (violations.isEmpty) {
    logI('check_ai_dedup_list_equals: no violations found.');
    return 0;
  }

  logE(
    'check_ai_dedup_list_equals: found ${violations.length} local list-equals '
    'definition(s) in $_aiLibRelative. Use `planningListEquals` from '
    'planning_helpers.dart instead.',
  );
  for (final v in violations) {
    logE(' - $v');
  }
  return 1;
}
