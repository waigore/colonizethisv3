import 'dart:io';

import 'package:path/path.dart' as p;

import 'ct_repo_lint_scan_contract.dart';

const String growthStageIndustryCounselSharedFixturesSupportFile =
    'packages/colonizethis_ai/test/support/'
    'growth_stage_industry_counsel_test_support.dart';

const String _planningTestDir = 'packages/colonizethis_ai/test/planning/';

const Set<String> growthStageIndustryCounselSharedFixtureAdopterBasenames = {
  'growth_stage_industry_counsel_characterization_test.dart',
};

final RegExp _localFeedstockTileGameDecl =
    RegExp(r'Game\s+_feedstockTileGame\b');

bool _isAdopterPath(String normalized) {
  if (!normalized.startsWith(_planningTestDir)) {
    return false;
  }
  return growthStageIndustryCounselSharedFixtureAdopterBasenames
      .contains(p.basename(normalized));
}

String? aiGrowthStageIndustryCounselSharedFixturesViolationReason(
  String slashPath,
  String content,
) {
  final normalized = slashPath.replaceAll('\\', '/');
  if (!_isAdopterPath(normalized)) {
    return null;
  }
  if (_localFeedstockTileGameDecl.hasMatch(content)) {
    return 'redeclares local `_feedstockTileGame`; import '
        '`growthStageIndustryCounselFeedstockTileGame` from '
        '`$growthStageIndustryCounselSharedFixturesSupportFile` (Refs #4310)';
  }
  return null;
}

int runCheckAiGrowthStageIndustryCounselTestSharedFixtures(
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
    'growth_stage_industry_counsel_test_support.dart',
  );
  if (!File(supportPath).existsSync()) {
    logE(
      'check_ai_growth_stage_industry_counsel_test_shared_fixtures: missing '
      'shared support file '
      '`$growthStageIndustryCounselSharedFixturesSupportFile`.',
    );
    return 1;
  }

  final violations = <String>[];
  for (final file in collectRepoLintDomainDartFiles(repoRoot)) {
    final rel = p.relative(file.path, from: repoRoot).replaceAll('\\', '/');
    final reason = aiGrowthStageIndustryCounselSharedFixturesViolationReason(
      rel,
      file.readAsStringSync(),
    );
    if (reason != null) {
      violations.add('$rel: $reason');
    }
  }

  if (violations.isEmpty) {
    logI(
      'check_ai_growth_stage_industry_counsel_test_shared_fixtures: no local '
      'growth-stage industry counsel fixture redeclarations.',
    );
    return 0;
  }
  logE(
    'check_ai_growth_stage_industry_counsel_test_shared_fixtures: '
    '${violations.length} violation(s):',
  );
  for (final violation in violations) {
    logE(' - $violation');
  }
  return 1;
}

void main() {
  exit(
    runCheckAiGrowthStageIndustryCounselTestSharedFixtures(
      Directory.current.path,
    ),
  );
}
