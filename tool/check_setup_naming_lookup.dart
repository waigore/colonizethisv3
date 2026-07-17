import 'dart:io';

import 'package:path/path.dart' as p;

/// Minor/tribe resolved-naming lookups must use `setup_naming_lookup.dart`
/// (Refs #4054).
const _setupLibDir = 'packages/colonizethis_setup/lib/src/setup';

const _canonicalRelativePath =
    'packages/colonizethis_setup/lib/src/setup/setup_naming_lookup.dart';

final RegExp _emptyMinorSentinel = RegExp(
  r"MinorNationNaming\s*\(\s*id:\s*''\s*,\s*displayName:\s*''\s*\)",
);

final RegExp _emptyTribeSentinel = RegExp(
  r"TribeNaming\s*\(\s*id:\s*''\s*,\s*displayName:\s*''\s*,\s*"
  r"provinceNamePool:\s*\[\s*\]\s*\)",
);

bool _isCommentLine(String line) {
  final trimmed = line.trimLeft();
  return trimmed.startsWith('//') || trimmed.startsWith('*');
}

int runCheckSetupNamingLookup(
  String repoRoot, {
  void Function(String line)? info,
  void Function(String line)? err,
}) {
  final logI = info ?? stdout.writeln;
  final logE = err ?? stderr.writeln;
  final root = p.normalize(repoRoot);
  final dir = Directory(p.join(root, _setupLibDir));
  if (!dir.existsSync()) {
    logI('Setup naming-lookup check skipped (setup lib dir absent).');
    return 0;
  }

  final sourcesByPath = <String, String>{};
  for (final entity in dir.listSync(recursive: true)) {
    if (entity is! File) continue;
    if (!entity.path.endsWith('.dart')) continue;
    if (entity.path.endsWith('.g.dart')) continue;
    final relativePath = p.relative(entity.path, from: root);
    sourcesByPath[relativePath] = entity.readAsStringSync();
  }

  final violations = findSetupNamingLookupViolations(
    sourcesByPath: sourcesByPath,
  );

  if (violations.isEmpty) {
    logI('Setup naming-lookup check passed.');
    return 0;
  }

  logE(
    'ERROR: Found re-inlined empty minor/tribe naming sentinel. Call '
    'resolvedMinorNaming / resolvedTribeNaming from setup_naming_lookup.dart '
    '(Refs #4054).',
  );
  for (final v in violations) {
    logE('${v.path}:${v.line} ${v.message}');
  }
  return 1;
}

void main() {
  exit(runCheckSetupNamingLookup(Directory.current.path));
}

List<SetupNamingLookupViolation> findSetupNamingLookupViolations({
  required Map<String, String> sourcesByPath,
}) {
  final violations = <SetupNamingLookupViolation>[];
  final paths = sourcesByPath.keys.toList()..sort();
  for (final path in paths) {
    final normalized = p.normalize(path);
    if (normalized == p.normalize(_canonicalRelativePath)) continue;
    final lines = sourcesByPath[path]!.split('\n');
    for (var i = 0; i < lines.length; i++) {
      final line = lines[i];
      if (_isCommentLine(line)) continue;
      if (_emptyMinorSentinel.hasMatch(line)) {
        violations.add(
          SetupNamingLookupViolation(
            path: path,
            line: i + 1,
            message: 'Empty MinorNationNaming sentinel; call resolvedMinorNaming.',
          ),
        );
      }
      if (_emptyTribeSentinel.hasMatch(line)) {
        violations.add(
          SetupNamingLookupViolation(
            path: path,
            line: i + 1,
            message: 'Empty TribeNaming sentinel; call resolvedTribeNaming.',
          ),
        );
      }
    }
  }
  return violations;
}

class SetupNamingLookupViolation {
  const SetupNamingLookupViolation({
    required this.path,
    required this.line,
    required this.message,
  });

  final String path;
  final int line;
  final String message;
}
