import 'dart:io';

import 'package:path/path.dart' as p;

import 'ct_repo_lint_scan_contract.dart';

/// Repo-relative path prefix for AI planning tests (Refs #3941).
const String _aiPlanningTestPathPrefix =
    'packages/colonizethis_ai/test/planning/';

/// Matches `*_part2_test.dart`, `*_part3_test.dart`, … under planning tests.
final RegExp _partShardTestName = RegExp(
  r'^(.+)_part(\d+)_test\.dart$',
);

/// True when [slashPath] is an AI planning `*_partN_test.dart` (N ≥ 2).
bool aiTestMatrixPartShardPathInScope(String slashPath) {
  final normalized = slashPath.replaceAll('\\', '/');
  if (!normalized.startsWith(_aiPlanningTestPathPrefix)) {
    return false;
  }
  final name = p.basename(normalized);
  final match = _partShardTestName.firstMatch(name);
  if (match == null) {
    return false;
  }
  final partNumber = int.tryParse(match.group(2) ?? '');
  return partNumber != null && partNumber >= 2;
}

/// Returns a violation reason when [slashPath] is a planning matrix part shard
/// whose sibling `*_support.dart` already exists (the consolidation landing
/// pad from Refs #3941), or `null` when compliant / out of scope.
String? aiTestMatrixPartShardViolationReason(
  String slashPath,
  String repoRoot,
) {
  final normalized = slashPath.replaceAll('\\', '/');
  if (!aiTestMatrixPartShardPathInScope(normalized)) {
    return null;
  }
  final name = p.basename(normalized);
  final match = _partShardTestName.firstMatch(name);
  if (match == null) {
    return null;
  }
  final stem = match.group(1)!;
  final supportRel =
      '$_aiPlanningTestPathPrefix${stem}_support.dart';
  final supportPath = p.join(repoRoot, supportRel);
  if (!File(supportPath).existsSync()) {
    // No sibling support library yet — part shards may still be mid-migration.
    return null;
  }
  return 'matrix part shard `$name` coexists with sibling support '
      '`$supportRel`; merge into one `*_test.dart` contract file plus the '
      'support library (Refs #3941)';
}

int runCheckAiTestNoMatrixPartShards(
  String repoRoot, {
  void Function(String line)? info,
  void Function(String line)? err,
}) {
  final logI = info ?? stdout.writeln;
  final logE = err ?? stderr.writeln;

  final violations = <String>[];
  for (final file in collectRepoLintDomainDartFiles(repoRoot)) {
    final rel = p.relative(file.path, from: repoRoot).replaceAll('\\', '/');
    final reason = aiTestMatrixPartShardViolationReason(rel, repoRoot);
    if (reason != null) {
      violations.add('$rel: $reason');
    }
  }

  if (violations.isEmpty) {
    logI(
      'check_ai_test_no_matrix_part_shards: no planning matrix part shards '
      'alongside sibling *_support.dart files.',
    );
    return 0;
  }
  logE(
    'check_ai_test_no_matrix_part_shards: ${violations.length} violation(s):',
  );
  for (final violation in violations) {
    logE(' - $violation');
  }
  return 1;
}

void main() {
  exit(runCheckAiTestNoMatrixPartShards(Directory.current.path));
}
