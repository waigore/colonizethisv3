import 'dart:io';

import 'package:path/path.dart' as p;

import 'ct_repo_lint_scan_contract.dart';

const String expandFeedstockSellerSharedFixturesSupportFile =
    'packages/colonizethis_ai/test/support/'
    'expand_feedstock_seller_test_support.dart';

const String _planningTestDir = 'packages/colonizethis_ai/test/planning/';

const Set<String> expandFeedstockSellerSharedFixtureAdopterBasenames = {
  'expand_phase_planner_feedstock_acquisition_target_test.dart',
  'expand_phase_planner_declare_war_feedstock_bias_test.dart',
};

final RegExp _localFlaggedSellerGameDecl =
    RegExp(r'Game\s+_flaggedSellerGame\b');
final RegExp _localFeedstockBiasGameDecl = RegExp(r'Game\s+_game\b');

bool _isAdopterPath(String normalized) {
  if (!normalized.startsWith(_planningTestDir)) {
    return false;
  }
  return expandFeedstockSellerSharedFixtureAdopterBasenames
      .contains(p.basename(normalized));
}

String? aiExpandFeedstockSellerSharedFixturesViolationReason(
  String slashPath,
  String content,
) {
  final normalized = slashPath.replaceAll('\\', '/');
  if (!_isAdopterPath(normalized)) {
    return null;
  }
  if (p.basename(normalized) ==
      'expand_phase_planner_feedstock_acquisition_target_test.dart') {
    if (_localFlaggedSellerGameDecl.hasMatch(content)) {
      return 'redeclares local `_flaggedSellerGame`; import '
          '`buildExpandFeedstockAcquisitionTargetGame` from '
          '`$expandFeedstockSellerSharedFixturesSupportFile` (Refs #4310)';
    }
    return null;
  }
  if (_localFeedstockBiasGameDecl.hasMatch(content)) {
    return 'redeclares local feedstock declare-war `_game`; import '
        '`buildExpandFeedstockDeclareWarBiasGame` from '
        '`$expandFeedstockSellerSharedFixturesSupportFile` (Refs #4310)';
  }
  return null;
}

int runCheckAiExpandFeedstockSellerTestSharedFixtures(
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
    'expand_feedstock_seller_test_support.dart',
  );
  if (!File(supportPath).existsSync()) {
    logE(
      'check_ai_expand_feedstock_seller_test_shared_fixtures: missing shared '
      'support file `$expandFeedstockSellerSharedFixturesSupportFile`.',
    );
    return 1;
  }

  final violations = <String>[];
  for (final file in collectRepoLintDomainDartFiles(repoRoot)) {
    final rel = p.relative(file.path, from: repoRoot).replaceAll('\\', '/');
    final reason = aiExpandFeedstockSellerSharedFixturesViolationReason(
      rel,
      file.readAsStringSync(),
    );
    if (reason != null) {
      violations.add('$rel: $reason');
    }
  }

  if (violations.isEmpty) {
    logI(
      'check_ai_expand_feedstock_seller_test_shared_fixtures: no local '
      'expand-feedstock seller fixture redeclarations.',
    );
    return 0;
  }
  logE(
    'check_ai_expand_feedstock_seller_test_shared_fixtures: '
    '${violations.length} violation(s):',
  );
  for (final violation in violations) {
    logE(' - $violation');
  }
  return 1;
}

void main() {
  exit(
    runCheckAiExpandFeedstockSellerTestSharedFixtures(
      Directory.current.path,
    ),
  );
}
