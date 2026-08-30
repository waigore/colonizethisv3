import 'dart:io';

import 'package:path/path.dart' as p;

import 'ct_repo_lint_scan_contract.dart';

const String factionQuerySharedFixturesSupportFile =
    'packages/colonizethis_ai/test/support/faction_query_test_support.dart';

const String _utilTestDir = 'packages/colonizethis_ai/test/util/';

const Set<String> factionQuerySharedFixtureAdopterBasenames = {
  'faction_query_test.dart',
};

final RegExp _localGameDecl = RegExp(r'Game\s+_game\b');

bool _isAdopterPath(String normalized) {
  if (!normalized.startsWith(_utilTestDir)) {
    return false;
  }
  return factionQuerySharedFixtureAdopterBasenames
      .contains(p.basename(normalized));
}

String? aiFactionQuerySharedFixturesViolationReason(
  String slashPath,
  String content,
) {
  final normalized = slashPath.replaceAll('\\', '/');
  if (!_isAdopterPath(normalized)) {
    return null;
  }
  if (_localGameDecl.hasMatch(content)) {
    return 'redeclares local `_game`; import `factionQueryGame` from '
        '`$factionQuerySharedFixturesSupportFile` (Refs #4310)';
  }
  return null;
}

int runCheckAiFactionQueryTestSharedFixtures(
  String repoRoot, {
  void Function(String line)? info,
  void Function(String line)? err,
}) {
  final logI = info ?? stdout.writeln;
  final logE = err ?? stderr.writeln;

  final supportPath = p.join(
    repoRoot,
    'packages',
    'colonizethis_ai',
    'test',
    'support',
    'faction_query_test_support.dart',
  );
  if (!File(supportPath).existsSync()) {
    logE(
      'check_ai_faction_query_test_shared_fixtures: missing shared support '
      'file `$factionQuerySharedFixturesSupportFile`.',
    );
    return 1;
  }

  final violations = <String>[];
  for (final file in collectRepoLintDomainDartFiles(repoRoot)) {
    final rel = p.relative(file.path, from: repoRoot).replaceAll('\\', '/');
    final reason = aiFactionQuerySharedFixturesViolationReason(
      rel,
      file.readAsStringSync(),
    );
    if (reason != null) {
      violations.add('$rel: $reason');
    }
  }

  if (violations.isEmpty) {
    logI(
      'check_ai_faction_query_test_shared_fixtures: no local faction-query '
      'fixture redeclarations.',
    );
    return 0;
  }
  logE(
    'check_ai_faction_query_test_shared_fixtures: '
    '${violations.length} violation(s):',
  );
  for (final violation in violations) {
    logE(' - $violation');
  }
  return 1;
}

void main() {
  exit(runCheckAiFactionQueryTestSharedFixtures(Directory.current.path));
}
