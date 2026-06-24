import 'dart:io';

import 'package:path/path.dart' as p;

/// SPEC: SPEC/program/repo-lint.md (Refs #3661).
///
/// Guards against re-introduced duplicate test scenarios in the economy
/// package after the #3661 dedup pass. The dedup effort removed overlapping
/// First-Right-of-Refusal, treasury/validator and consumption scenarios so
/// each numeric contract has a single source of truth. This rule fails when
/// the **same** `test('...')` / `testWidgets('...')` description string appears
/// in **more than one** file under `packages/colonizethis_economy/test/`,
/// which is the signature of a copy-pasted scenario re-spreading across slice
/// files. Within-file repetition (across groups) and comment prose are not
/// flagged.
const _economyTestDir = 'packages/colonizethis_economy/test';

/// Captures the literal description of a single-line `test('...')` or
/// `testWidgets('...')` declaration. The trailing `[,)]` requires the string
/// to be the complete first argument (followed by the test body comma or a
/// closing paren), so Dart adjacent-string concatenations spanning lines are
/// intentionally ignored rather than partially matched.
final RegExp _testDescription = RegExp(
  r"""(?:test|testWidgets)\(\s*(?:'((?:[^'\\]|\\.)*)'|"((?:[^"\\]|\\.)*)")\s*[,)]""",
);

/// True when [line] is a pure comment line (`//`, `///`, or a `*` doc/block
/// continuation), so a description mentioned in prose is not flagged.
bool _isCommentLine(String line) {
  final trimmed = line.trimLeft();
  return trimmed.startsWith('//') || trimmed.startsWith('*');
}

void main() {
  exit(runCheckEconomyTestDuplicateDescriptions(Directory.current.path));
}

/// Used by `ct_repo_lint` (via the manifest `dart` runner) and standalone;
/// [info] / [err] default to stdout/stderr.
int runCheckEconomyTestDuplicateDescriptions(
  String repoRoot, {
  void Function(String line)? info,
  void Function(String line)? err,
}) {
  final logI = info ?? stdout.writeln;
  final logE = err ?? stderr.writeln;
  final root = p.normalize(repoRoot);
  final dir = Directory(p.join(root, _economyTestDir));
  if (!dir.existsSync()) {
    logI('Economy test duplicate-description check skipped (test dir absent).');
    return 0;
  }

  final sourcesByPath = <String, String>{};
  for (final entity in dir.listSync(recursive: true)) {
    if (entity is! File) continue;
    if (!entity.path.endsWith('_test.dart')) continue;
    final relativePath = p.relative(entity.path, from: root);
    sourcesByPath[relativePath] = entity.readAsStringSync();
  }

  final violations = findEconomyTestDuplicateDescriptions(
    sourcesByPath: sourcesByPath,
  );

  if (violations.isEmpty) {
    logI('Economy test duplicate-description check passed.');
    return 0;
  }

  logE(
    'ERROR: Found identical test descriptions across multiple '
    'packages/colonizethis_economy/test files. Each numeric contract should '
    'have a single source of truth after the #3661 dedup pass: consolidate '
    'the duplicate scenario into one file (prefer the issue-AC audit file '
    'where one exists) or give genuinely distinct tests distinct descriptions.',
  );
  for (final v in violations) {
    logE("  '${v.description}' appears in: ${v.paths.join(', ')}");
  }
  return 1;
}

/// Scans [sourcesByPath] (relative path -> source) and returns one violation
/// per description string that appears as a single-line `test`/`testWidgets`
/// declaration in two or more distinct files. Comment lines are ignored.
List<EconomyTestDuplicateDescriptionViolation>
findEconomyTestDuplicateDescriptions({
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

  final violations = <EconomyTestDuplicateDescriptionViolation>[];
  final descriptions = filesByDescription.keys.toList()..sort();
  for (final description in descriptions) {
    final files = filesByDescription[description]!;
    if (files.length < 2) continue;
    violations.add(
      EconomyTestDuplicateDescriptionViolation(
        description: description,
        paths: files.toList()..sort(),
      ),
    );
  }
  return violations;
}

class EconomyTestDuplicateDescriptionViolation {
  const EconomyTestDuplicateDescriptionViolation({
    required this.description,
    required this.paths,
  });

  final String description;
  final List<String> paths;
}
