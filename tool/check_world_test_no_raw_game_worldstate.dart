import 'dart:io';

import 'package:path/path.dart' as p;

import 'ct_repo_lint_scan_contract.dart';

/// Repo-relative path prefix for world package tests (Refs #3978).
const String _worldTestPathPrefix = 'packages/colonizethis_world/test/';

/// Shared builders may construct [Game] / [WorldState]; other fog/capital/
/// connectivity tests must call those builders (or TestFixtures) instead.
const String _worldTestSupportPathInfix = '/world_test_support/';

/// Files still inlining constructors before migration completes.
const Set<String> _grandfatheredRawGameWorldStateTestPaths = {};

final RegExp _inlineGameConstructor = RegExp(r'\bGame\s*\(');
final RegExp _inlineWorldStateConstructor = RegExp(r'\bWorldState\s*\(');

/// True when [slashPath] is a fog/capital/connectivity world test outside
/// `world_test_support/`.
bool worldTestNoRawGameWorldStatePathInScope(String slashPath) {
  final normalized = slashPath.replaceAll('\\', '/');
  if (!normalized.startsWith(_worldTestPathPrefix)) {
    return false;
  }
  if (normalized.contains(_worldTestSupportPathInfix)) {
    return false;
  }
  final base = p.basename(normalized).toLowerCase();
  return base.contains('fog') ||
      base.contains('capital') ||
      base.contains('connectivity');
}

/// Violation reason when [content] inlines `Game(` / `WorldState(` outside the
/// allowlist, or `null` when compliant.
String? worldTestRawGameWorldStateViolationReason(
  String slashPath,
  String content,
) {
  if (!worldTestNoRawGameWorldStatePathInScope(slashPath)) {
    return null;
  }
  if (_grandfatheredRawGameWorldStateTestPaths.contains(slashPath)) {
    return null;
  }
  final code = _stripLineComments(content);
  final inlineGame = _inlineGameConstructor.hasMatch(code);
  final inlineWorldState = _inlineWorldStateConstructor.hasMatch(code);
  if (!inlineGame && !inlineWorldState) {
    return null;
  }
  final parts = <String>[
    if (inlineGame) 'Game(...)',
    if (inlineWorldState) 'WorldState(...)',
  ];
  return 're-inlines ${parts.join(' + ')}; use world_test_support builders '
      'or TestFixtures instead (Refs #3978)';
}

String _stripLineComments(String content) {
  final out = StringBuffer();
  for (final line in content.split('\n')) {
    final trimmed = line.trimLeft();
    if (trimmed.startsWith('//') || trimmed.startsWith('*')) {
      continue;
    }
    out.writeln(line);
  }
  return out.toString();
}

int runCheckWorldTestNoRawGameWorldState(
  String repoRoot, {
  void Function(String line)? info,
  void Function(String line)? err,
}) {
  final logI = info ?? stdout.writeln;
  final logE = err ?? stderr.writeln;

  final violations = <String>[];
  for (final file in collectRepoLintDomainDartFiles(repoRoot)) {
    final rel = p.relative(file.path, from: repoRoot).replaceAll('\\', '/');
    final reason = worldTestRawGameWorldStateViolationReason(
      rel,
      file.readAsStringSync(),
    );
    if (reason != null) {
      violations.add('$rel: $reason');
    }
  }

  if (violations.isEmpty) {
    logI(
      'check_world_test_no_raw_game_worldstate: no raw Game/WorldState '
      'constructors in fog/capital/connectivity tests.',
    );
    return 0;
  }
  logE(
    'check_world_test_no_raw_game_worldstate: ${violations.length} '
    'violation(s):',
  );
  for (final violation in violations) {
    logE(' - $violation');
  }
  return 1;
}

void main() {
  exit(runCheckWorldTestNoRawGameWorldState(Directory.current.path));
}
