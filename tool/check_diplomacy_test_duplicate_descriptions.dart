import 'dart:io';

import 'package:path/path.dart' as p;

/// SPEC: SPEC/program/repo-lint.md (Refs #3825).
///
/// Guards against re-introduced duplicate test scenarios in the diplomacy
/// package after the #3825 dedup pass.
const _diplomacyTestDir = 'packages/colonizethis_diplomacy/test';

final RegExp _testDescription = RegExp(
  r"""(?:test|testWidgets)\(\s*(?:'((?:[^'\\]|\\.)*)'|"((?:[^"\\]|\\.)*)")\s*[,)]""",
);

bool _isCommentLine(String line) {
  final trimmed = line.trimLeft();
  return trimmed.startsWith('//') || trimmed.startsWith('*');
}

void main() {
  exit(runCheckDiplomacyTestDuplicateDescriptions(Directory.current.path));
}

int runCheckDiplomacyTestDuplicateDescriptions(
  String repoRoot, {
  void Function(String line)? info,
  void Function(String line)? err,
}) {
  final logI = info ?? stdout.writeln;
  final logE = err ?? stderr.writeln;
  final root = p.normalize(repoRoot);
  final dir = Directory(p.join(root, _diplomacyTestDir));
  if (!dir.existsSync()) {
    logI(
      'Diplomacy test duplicate-description check skipped (test dir absent).',
    );
    return 0;
  }

  final sourcesByPath = <String, String>{};
  for (final entity in dir.listSync(recursive: true)) {
    if (entity is! File) continue;
    if (!entity.path.endsWith('_test.dart')) continue;
    final relativePath = p.relative(entity.path, from: root);
    sourcesByPath[relativePath] = entity.readAsStringSync();
  }

  final violations = findDiplomacyTestDuplicateDescriptions(
    sourcesByPath: sourcesByPath,
  );

  if (violations.isEmpty) {
    logI('Diplomacy test duplicate-description check passed.');
    return 0;
  }

  logE(
    'ERROR: Found identical test descriptions across multiple '
    'packages/colonizethis_diplomacy/test files. Consolidate duplicate '
    'scenarios or give genuinely distinct tests distinct descriptions.',
  );
  for (final v in violations) {
    logE("  '${v.description}' appears in: ${v.paths.join(', ')}");
  }
  return 1;
}

List<DiplomacyTestDuplicateDescriptionViolation>
findDiplomacyTestDuplicateDescriptions({
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

  final violations = <DiplomacyTestDuplicateDescriptionViolation>[];
  final descriptions = filesByDescription.keys.toList()..sort();
  for (final description in descriptions) {
    final files = filesByDescription[description]!;
    if (files.length < 2) continue;
    violations.add(
      DiplomacyTestDuplicateDescriptionViolation(
        description: description,
        paths: files.toList()..sort(),
      ),
    );
  }
  return violations;
}

class DiplomacyTestDuplicateDescriptionViolation {
  const DiplomacyTestDuplicateDescriptionViolation({
    required this.description,
    required this.paths,
  });

  final String description;
  final List<String> paths;
}
