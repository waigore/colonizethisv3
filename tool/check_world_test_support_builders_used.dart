import 'dart:io';

import 'package:path/path.dart' as p;

import 'ct_repo_lint_scan_contract.dart';

/// World test-support builders that must have ≥1 call site outside
/// `world_test_support/` so they cannot rot unused (Refs #3968).
const List<String> worldRequiredSupportBuilderNames = [
  'spyRevealFogGame',
  'ownershipTransferVisibilityGame',
  'coastalSeaVisibilityGame',
  'capitalLossGame',
  'gpCapitalReassignmentGame',
  'factionCapitalReassignmentGame',
  'ordersPhaseGame',
  'topologyGraph',
];

const String _worldTestPrefix = 'packages/colonizethis_world/test/';
const String _supportInfix = '/world_test_support/';

/// True when [slashPath] is a world test file outside support builders.
bool worldTestSupportOrphanCallSitePathInScope(String slashPath) {
  final normalized = slashPath.replaceAll('\\', '/');
  if (!normalized.startsWith(_worldTestPrefix)) {
    return false;
  }
  if (normalized.contains(_supportInfix)) {
    return false;
  }
  return true;
}

/// Counts call-site occurrences of [builderName]( in [content] (not definitions).
int worldSupportBuilderCallCount(String content, String builderName) {
  final code = _stripLineComments(content);
  return RegExp(r'\b' + RegExp.escape(builderName) + r'\s*\(').allMatches(code).length;
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

int runCheckWorldTestSupportBuildersUsed(
  String repoRoot, {
  void Function(String line)? info,
  void Function(String line)? err,
}) {
  final logI = info ?? stdout.writeln;
  final logE = err ?? stderr.writeln;

  final callCounts = <String, int>{
    for (final name in worldRequiredSupportBuilderNames) name: 0,
  };

  for (final file in collectRepoLintDomainDartFiles(repoRoot)) {
    final rel = p.relative(file.path, from: repoRoot).replaceAll('\\', '/');
    if (!worldTestSupportOrphanCallSitePathInScope(rel)) {
      continue;
    }
    final content = file.readAsStringSync();
    for (final name in worldRequiredSupportBuilderNames) {
      callCounts[name] = callCounts[name]! +
          worldSupportBuilderCallCount(content, name);
    }
  }

  final violations = <String>[];
  for (final name in worldRequiredSupportBuilderNames) {
    if (callCounts[name]! < 1) {
      violations.add(
        'support builder `$name` has no call site outside '
        'packages/colonizethis_world/test/world_test_support/ (Refs #3968)',
      );
    }
  }

  if (violations.isEmpty) {
    logI(
      'check_world_test_support_builders_used: all required builders have '
      'external call sites.',
    );
    return 0;
  }
  logE(
    'check_world_test_support_builders_used: ${violations.length} '
    'violation(s):',
  );
  for (final violation in violations) {
    logE(' - $violation');
  }
  return 1;
}

void main() {
  exit(runCheckWorldTestSupportBuildersUsed(Directory.current.path));
}
