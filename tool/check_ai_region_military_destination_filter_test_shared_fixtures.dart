import 'dart:io';

import 'package:path/path.dart' as p;

import 'ct_repo_lint_scan_contract.dart';

const String regionMilitaryDestinationFilterSharedFixturesSupportFile =
    'packages/colonizethis_ai/test/support/'
    'region_military_destination_filter_test_support.dart';

const String _planningTestDir = 'packages/colonizethis_ai/test/planning/';

const Set<String> regionMilitaryDestinationFilterSharedFixtureAdopterBasenames =
    {
  'region_military_destination_filter_test.dart',
};

final RegExp _localGameDecl = RegExp(r'Game\s+_game\b');

bool _isAdopterPath(String normalized) {
  if (!normalized.startsWith(_planningTestDir)) {
    return false;
  }
  return regionMilitaryDestinationFilterSharedFixtureAdopterBasenames
      .contains(p.basename(normalized));
}

String? aiRegionMilitaryDestinationFilterSharedFixturesViolationReason(
  String slashPath,
  String content,
) {
  final normalized = slashPath.replaceAll('\\', '/');
  if (!_isAdopterPath(normalized)) {
    return null;
  }
  if (_localGameDecl.hasMatch(content)) {
    return 'redeclares local `_game`; import '
        '`regionMilitaryDestinationFilterGame` from '
        '`$regionMilitaryDestinationFilterSharedFixturesSupportFile` '
        '(Refs #4310)';
  }
  return null;
}

int runCheckAiRegionMilitaryDestinationFilterTestSharedFixtures(
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
    'region_military_destination_filter_test_support.dart',
  );
  if (!File(supportPath).existsSync()) {
    logE(
      'check_ai_region_military_destination_filter_test_shared_fixtures: '
      'missing shared support file '
      '`$regionMilitaryDestinationFilterSharedFixturesSupportFile`.',
    );
    return 1;
  }

  final violations = <String>[];
  for (final file in collectRepoLintDomainDartFiles(repoRoot)) {
    final rel = p.relative(file.path, from: repoRoot).replaceAll('\\', '/');
    final reason =
        aiRegionMilitaryDestinationFilterSharedFixturesViolationReason(
      rel,
      file.readAsStringSync(),
    );
    if (reason != null) {
      violations.add('$rel: $reason');
    }
  }

  if (violations.isEmpty) {
    logI(
      'check_ai_region_military_destination_filter_test_shared_fixtures: no '
      'local region-military destination-filter fixture redeclarations.',
    );
    return 0;
  }
  logE(
    'check_ai_region_military_destination_filter_test_shared_fixtures: '
    '${violations.length} violation(s):',
  );
  for (final violation in violations) {
    logE(' - $violation');
  }
  return 1;
}

void main() {
  exit(
    runCheckAiRegionMilitaryDestinationFilterTestSharedFixtures(
      Directory.current.path,
    ),
  );
}
