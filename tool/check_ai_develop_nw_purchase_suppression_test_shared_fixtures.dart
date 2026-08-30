import 'dart:io';

import 'package:path/path.dart' as p;

import 'ct_repo_lint_scan_contract.dart';

const String developNwPurchaseSuppressionSharedFixturesSupportFile =
    'packages/colonizethis_ai/test/support/'
    'domain_planner_develop_nw_purchase_suppression_test_support.dart';

const String _planningTestDir = 'packages/colonizethis_ai/test/planning/';

const Set<String> developNwPurchaseSuppressionSharedFixtureAdopterBasenames = {
  'domain_planner_orchestrator_develop_nw_purchase_suppression_test.dart',
};

final RegExp _localDevelopScenarioGameDecl =
    RegExp(r'Game\s+_developScenarioGame\b');

bool _isAdopterPath(String normalized) {
  if (!normalized.startsWith(_planningTestDir)) {
    return false;
  }
  return developNwPurchaseSuppressionSharedFixtureAdopterBasenames
      .contains(p.basename(normalized));
}

String? aiDevelopNwPurchaseSuppressionSharedFixturesViolationReason(
  String slashPath,
  String content,
) {
  final normalized = slashPath.replaceAll('\\', '/');
  if (!_isAdopterPath(normalized)) {
    return null;
  }
  if (_localDevelopScenarioGameDecl.hasMatch(content)) {
    return 'redeclares local `_developScenarioGame`; import '
        '`developNwPurchaseSuppressionScenarioGame` from '
        '`$developNwPurchaseSuppressionSharedFixturesSupportFile` (Refs #4310)';
  }
  return null;
}

int runCheckAiDevelopNwPurchaseSuppressionTestSharedFixtures(
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
    'domain_planner_develop_nw_purchase_suppression_test_support.dart',
  );
  if (!File(supportPath).existsSync()) {
    logE(
      'check_ai_develop_nw_purchase_suppression_test_shared_fixtures: missing '
      'shared support file '
      '`$developNwPurchaseSuppressionSharedFixturesSupportFile`.',
    );
    return 1;
  }

  final violations = <String>[];
  for (final file in collectRepoLintDomainDartFiles(repoRoot)) {
    final rel = p.relative(file.path, from: repoRoot).replaceAll('\\', '/');
    final reason = aiDevelopNwPurchaseSuppressionSharedFixturesViolationReason(
      rel,
      file.readAsStringSync(),
    );
    if (reason != null) {
      violations.add('$rel: $reason');
    }
  }

  if (violations.isEmpty) {
    logI(
      'check_ai_develop_nw_purchase_suppression_test_shared_fixtures: no local '
      'develop NW purchase-suppression fixture redeclarations.',
    );
    return 0;
  }
  logE(
    'check_ai_develop_nw_purchase_suppression_test_shared_fixtures: '
    '${violations.length} violation(s):',
  );
  for (final violation in violations) {
    logE(' - $violation');
  }
  return 1;
}

void main() {
  exit(
    runCheckAiDevelopNwPurchaseSuppressionTestSharedFixtures(
      Directory.current.path,
    ),
  );
}
