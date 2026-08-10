import 'dart:io';

import 'package:path/path.dart' as p;

import 'ct_repo_lint_scan_contract.dart';

const String civilianBuildLiveWiringSharedFixturesSupportFile =
    'packages/colonizethis_ai/test/support/'
    'civilian_build_live_wiring_test_support.dart';

const String _planningTestDir = 'packages/colonizethis_ai/test/planning/';

const Set<String> civilianBuildLiveWiringSharedFixtureAdopterBasenames = {
  'civilian_build_live_wiring_test.dart',
};

final RegExp _localGameWithLeaderDecl = RegExp(r'Game\s+_gameWithLeader\b');

bool _isAdopterPath(String normalized) {
  if (!normalized.startsWith(_planningTestDir)) {
    return false;
  }
  return civilianBuildLiveWiringSharedFixtureAdopterBasenames
      .contains(p.basename(normalized));
}

String? aiCivilianBuildLiveWiringSharedFixturesViolationReason(
  String slashPath,
  String content,
) {
  final normalized = slashPath.replaceAll('\\', '/');
  if (!_isAdopterPath(normalized)) {
    return null;
  }
  if (_localGameWithLeaderDecl.hasMatch(content)) {
    return 'redeclares local `_gameWithLeader`; import '
        '`civilianBuildLiveWiringGameWithLeader` from '
        '`$civilianBuildLiveWiringSharedFixturesSupportFile` (Refs #4310)';
  }
  return null;
}

int runCheckAiCivilianBuildLiveWiringTestSharedFixtures(
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
    'civilian_build_live_wiring_test_support.dart',
  );
  if (!File(supportPath).existsSync()) {
    logE(
      'check_ai_civilian_build_live_wiring_test_shared_fixtures: missing '
      'shared support file '
      '`$civilianBuildLiveWiringSharedFixturesSupportFile`.',
    );
    return 1;
  }

  final violations = <String>[];
  for (final file in collectRepoLintDomainDartFiles(repoRoot)) {
    final rel = p.relative(file.path, from: repoRoot).replaceAll('\\', '/');
    final reason = aiCivilianBuildLiveWiringSharedFixturesViolationReason(
      rel,
      file.readAsStringSync(),
    );
    if (reason != null) {
      violations.add('$rel: $reason');
    }
  }

  if (violations.isEmpty) {
    logI(
      'check_ai_civilian_build_live_wiring_test_shared_fixtures: no local '
      'civilian-build live-wiring fixture redeclarations.',
    );
    return 0;
  }
  logE(
    'check_ai_civilian_build_live_wiring_test_shared_fixtures: '
    '${violations.length} violation(s):',
  );
  for (final violation in violations) {
    logE(' - $violation');
  }
  return 1;
}

void main() {
  exit(
    runCheckAiCivilianBuildLiveWiringTestSharedFixtures(
      Directory.current.path,
    ),
  );
}
