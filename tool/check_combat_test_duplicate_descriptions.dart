import 'dart:io';

import 'package:path/path.dart' as p;

/// SPEC: SPEC/program/repo-lint.md (Refs #3865).
///
/// Guards against re-introduced duplicate test scenarios in the combat
/// package after the #3865 table-merge pass.
const _combatTestDir = 'packages/colonizethis_combat/test';

/// Captures the literal description of a single-line `test('...')` or
/// `testWidgets('...')` declaration.
final RegExp _testDescription = RegExp(
  r"""(?:test|testWidgets)\(\s*(?:'((?:[^'\\]|\\.)*)'|"((?:[^"\\]|\\.)*)")\s*[,)]""",
);

bool _isCommentLine(String line) {
  final trimmed = line.trimLeft();
  return trimmed.startsWith('//') || trimmed.startsWith('*');
}

void main() {
  exit(runCheckCombatTestDuplicateDescriptions(Directory.current.path));
}

int runCheckCombatTestDuplicateDescriptions(
  String repoRoot, {
  void Function(String line)? info,
  void Function(String line)? err,
}) {
  final logI = info ?? stdout.writeln;
  final logE = err ?? stderr.writeln;
  final root = p.normalize(repoRoot);
  final dir = Directory(p.join(root, _combatTestDir));
  if (!dir.existsSync()) {
    logI('Combat test duplicate-description check skipped (test dir absent).');
    return 0;
  }

  final sourcesByPath = <String, String>{};
  for (final entity in dir.listSync(recursive: true)) {
    if (entity is! File) continue;
    if (!entity.path.endsWith('_test.dart')) continue;
    final relativePath = p.relative(entity.path, from: root);
    sourcesByPath[relativePath] = entity.readAsStringSync();
  }

  final violations = findCombatTestDuplicateDescriptions(
    sourcesByPath: sourcesByPath,
  );

  if (violations.isEmpty) {
    logI('Combat test duplicate-description check passed.');
    return 0;
  }

  logE(
    'ERROR: Found identical test descriptions across multiple '
    'packages/colonizethis_combat/test files. Consolidate duplicate '
    'scenarios into one file or give genuinely distinct tests distinct '
    'descriptions (Refs #3865).',
  );
  for (final v in violations) {
    logE("  '${v.description}' appears in: ${v.paths.join(', ')}");
  }
  return 1;
}

List<CombatTestDuplicateDescriptionViolation> findCombatTestDuplicateDescriptions({
  required Map<String, String> sourcesByPath,
}) {
  final filesByDescription = <String, Set<String>>{};
  final paths = sourcesByPath.keys.toList()..sort();
  for (final path in paths) {
    final lines = sourcesByPath[path]!.split('\n');
    for (final line in lines) {
      if (_isCommentLine(line)) continue;
      for (final match in _testDescription.allMatches(line)) {
        final description = match.group(1) ?? match.group(2);
        if (description == null || description.isEmpty) continue;
        filesByDescription.putIfAbsent(description, () => <String>{}).add(path);
      }
    }
  }

  final violations = <CombatTestDuplicateDescriptionViolation>[];
  final descriptions = filesByDescription.keys.toList()..sort();
  for (final description in descriptions) {
    final files = filesByDescription[description]!;
    if (files.length < 2) continue;
    violations.add(
      CombatTestDuplicateDescriptionViolation(
        description: description,
        paths: files.toList()..sort(),
      ),
    );
  }
  return violations;
}

class CombatTestDuplicateDescriptionViolation {
  const CombatTestDuplicateDescriptionViolation({
    required this.description,
    required this.paths,
  });

  final String description;
  final List<String> paths;
}
