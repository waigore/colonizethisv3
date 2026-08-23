import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;

import 'ct_repo_lint_scan_contract.dart';

/// Physical-line ceiling for ungated AI planning / support_test Dart
/// (Refs #4602 Slice D). Complements `*_cases.dart` and support/s7d/observer
/// suite gates so `_test.dart` hosts cannot silently re-grow past 300.
const int aiTestFileSizeCeiling = 300;

const List<String> _aiTestFileSizePathPrefixes = <String>[
  'packages/colonizethis_ai/test/planning/',
  'packages/colonizethis_ai/test/support_test/',
];

bool aiTestFileSizePathInScope(String slashPath) {
  final normalized = slashPath.replaceAll('\\', '/');
  if (!normalized.endsWith('.dart')) {
    return false;
  }
  for (final prefix in _aiTestFileSizePathPrefixes) {
    if (normalized.startsWith(prefix)) {
      return true;
    }
  }
  return false;
}

String? aiTestFileSizeViolationReason(String slashPath, String content) {
  final normalized = slashPath.replaceAll('\\', '/');
  if (!aiTestFileSizePathInScope(normalized)) {
    return null;
  }
  final lineCount = const LineSplitter().convert(content).length;
  if (lineCount <= aiTestFileSizeCeiling) {
    return null;
  }
  return 'has $lineCount physical lines (ceiling $aiTestFileSizeCeiling); '
      'topic-split into a sibling `*_cases.dart` / named host (Refs #4602)';
}

int runCheckAiTestFileSize(
  String repoRoot, {
  void Function(String line)? info,
  void Function(String line)? err,
}) {
  final logI = info ?? stdout.writeln;
  final logE = err ?? stderr.writeln;

  final violations = <String>[];
  for (final file in collectRepoLintDomainDartFiles(repoRoot)) {
    final rel = p.relative(file.path, from: repoRoot).replaceAll('\\', '/');
    final reason = aiTestFileSizeViolationReason(rel, file.readAsStringSync());
    if (reason != null) {
      violations.add('$rel: $reason');
    }
  }

  if (violations.isEmpty) {
    logI(
      'check_ai_test_file_size: no oversize planning/support_test files '
      '(ceiling $aiTestFileSizeCeiling; Refs #4602).',
    );
    return 0;
  }
  logE('check_ai_test_file_size: ${violations.length} violation(s):');
  for (final violation in violations) {
    logE(' - $violation');
  }
  return 1;
}

void main() {
  exit(runCheckAiTestFileSize(Directory.current.path));
}
