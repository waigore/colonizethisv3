// Physical line ratchet for colonizethis_ai test support modules
// (`repo.ai_test_support_file_size`). Refs #4291.
import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;

import 'ct_repo_lint_scan_contract.dart';

const int aiTestSupportFileSizeCeiling = 300;

const String _aiSupportRelDir = 'packages/colonizethis_ai/test/support';

/// S7D support modules are gated separately by [repo.ai_s7d_support_suite_size].
const String _s7dSupportPathPrefix =
    'packages/colonizethis_ai/test/support/s7d/';

/// Empty allowlist: every in-scope support file must stay ≤300 physical lines.
/// Override in tests via [grandfatheredPaths].
const List<String> aiTestSupportFileSizeGrandfatheredForTests = <String>[];

bool aiTestSupportFileSizePathInScope(String slashPath) {
  final normalized = slashPath.replaceAll('\\', '/');
  if (!normalized.startsWith('$_aiSupportRelDir/')) {
    return false;
  }
  if (normalized.startsWith(_s7dSupportPathPrefix)) {
    return false;
  }
  return normalized.endsWith('.dart');
}

int runCheckAiTestSupportFileSize(
  String repoRoot, {
  Iterable<String>? targetFiles,
  Iterable<String>? grandfatheredPaths,
  void Function(String line)? info,
  void Function(String line)? err,
  int ceiling = aiTestSupportFileSizeCeiling,
}) {
  final logI = info ?? stdout.writeln;
  final logE = err ?? stderr.writeln;

  final supportDir = Directory(p.join(repoRoot, _aiSupportRelDir));
  if (!supportDir.existsSync()) {
    logE('check_ai_test_support_file_size: $_aiSupportRelDir not found.');
    return 1;
  }

  final grandfathered =
      (grandfatheredPaths ?? aiTestSupportFileSizeGrandfatheredForTests)
          .map((path) => path.replaceAll('\\', '/'))
          .toSet();

  final missingGrandfathered = <String>[];
  for (final relativePath in grandfathered) {
    if (!File(p.join(repoRoot, relativePath)).existsSync()) {
      missingGrandfathered.add(relativePath);
    }
  }
  if (missingGrandfathered.isNotEmpty) {
    logE(
      'check_ai_test_support_file_size: stale grandfather entries (file no '
      'longer exists; remove from allowlist):',
    );
    for (final relativePath in missingGrandfathered) {
      logE(' - $relativePath');
    }
    return 1;
  }

  final violations = <String>[];
  for (final filePath in _collectFilesToCheck(
    repoRoot,
    supportDir,
    targetFiles,
  )) {
    final file = File(filePath);
    final relativePath = p
        .relative(file.path, from: repoRoot)
        .replaceAll('\\', '/');
    if (!aiTestSupportFileSizePathInScope(relativePath)) {
      continue;
    }
    if (grandfathered.contains(relativePath)) {
      continue;
    }
    final physicalLines = const LineSplitter()
        .convert(file.readAsStringSync())
        .length;
    if (physicalLines <= ceiling) {
      continue;
    }
    violations.add('$relativePath ($physicalLines physical lines > $ceiling)');
  }

  if (violations.isEmpty) {
    logI(
      'check_ai_test_support_file_size: no violations found '
      '(ceiling $ceiling; Refs #4291).',
    );
    return 0;
  }

  violations.sort();
  logE(
    'check_ai_test_support_file_size: found ${violations.length} violation(s) '
    'under $_aiSupportRelDir (ceiling $ceiling; Refs #4291):',
  );
  for (final violation in violations) {
    logE(' - $violation');
  }
  return 1;
}

List<String> _collectFilesToCheck(
  String repoRoot,
  Directory supportDir,
  Iterable<String>? targetFiles,
) {
  if (targetFiles == null) {
    return supportDir
        .listSync(recursive: true, followLinks: false)
        .whereType<File>()
        .map((file) => file.path)
        .where((path) => path.endsWith('.dart'))
        .toList(growable: false);
  }

  const prefix = '$_aiSupportRelDir/';
  final results = <String>[];
  for (final relativePath in targetFiles) {
    final normalized = relativePath.replaceAll('\\', '/');
    if (!normalized.startsWith(prefix) || !normalized.endsWith('.dart')) {
      continue;
    }
    final file = File(p.join(repoRoot, normalized));
    if (!file.existsSync()) {
      continue;
    }
    results.add(file.path);
  }
  return results;
}

int maxAiTestSupportFilePhysicalLinesForTests() => aiTestSupportFileSizeCeiling;

void main(List<String> args) {
  final files = repoLintStrictIncrementalFilesArgListOrExit(args);
  exit(
    runCheckAiTestSupportFileSize(
      Directory.current.path,
      targetFiles: files.isEmpty ? null : files,
    ),
  );
}
