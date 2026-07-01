import 'dart:io';

import 'package:path/path.dart' as p;

import 'ct_repo_lint_scan_contract.dart';

/// Repo-relative paths that must not construct `Game(` inline (Refs #3825).
const _mandatedFixtureTestPaths = <String>{
  'packages/colonizethis_diplomacy/test/diplomacy/gp_tribe_first_contact_test.dart',
  'packages/colonizethis_diplomacy/test/diplomacy/ai_gp_tribe_first_contact_test.dart',
  'packages/colonizethis_diplomacy/test/diplomacy/diplomacy_ftp_resolver_test.dart',
  'packages/colonizethis_diplomacy/test/diplomacy/diplomacy_faction_membership_test.dart',
  'packages/colonizethis_diplomacy/test/diplomacy/known_diplomatic_targets_test.dart',
  'packages/colonizethis_diplomacy/test/diplomacy/diplomacy_intra_turn_event_tally_test.dart',
  'packages/colonizethis_diplomacy/test/diplomacy/diplomacy_resolver_dialogue_test.dart',
  'packages/colonizethis_diplomacy/test/diplomacy/diplomacy_resolver_history_test.dart',
  'packages/colonizethis_diplomacy/test/diplomacy/diplomacy_resolver_dossier_test.dart',
  'packages/colonizethis_diplomacy/test/diplomacy/diplomacy_resolver_phase_test_part1_test.dart',
  'packages/colonizethis_diplomacy/test/diplomacy/diplomacy_phase_types_split_test.dart',
  'packages/colonizethis_diplomacy/test/diplomacy/diplomacy_phase_result_value_types_test.dart',
  'packages/colonizethis_diplomacy/test/diplomacy/diplomacy_resolver_trade_and_labels_test.dart',
  'packages/colonizethis_diplomacy/test/diplomacy/diplomacy_resolver_survival_peace_test.dart',
  'packages/colonizethis_diplomacy/test/diplomacy/diplomacy_resolver_intervention_test.dart',
  'packages/colonizethis_diplomacy/test/diplomacy/diplomacy_call_to_arms_test.dart',
  'packages/colonizethis_diplomacy/test/diplomacy/diplomacy_resolver_phase_test_part2_test.dart',
  'packages/colonizethis_diplomacy/test/diplomacy/diplomacy_subsidies_relations_resolver_test.dart',
  'packages/colonizethis_diplomacy/test/diplomacy/alliance_break_cooldown_test.dart',
  'packages/colonizethis_diplomacy/test/diplomacy/boycott_resolver_test.dart',
  'packages/colonizethis_diplomacy/test/diplomacy/boycott_blocked_trade_pair_keys_test.dart',
};

/// Matches an inline `Game(` constructor call (standalone identifier, not
/// `gpGpEmbassyGame(` etc.).
final RegExp _inlineGameConstructor = RegExp(r'(?<![A-Za-z0-9_])Game\(');

/// True when [slashPath] is a mandated no-inline-`Game(` test file.
bool diplomacyTestInlineGameCtorPathInScope(String slashPath) {
  final normalized = slashPath.replaceAll('\\', '/');
  return _mandatedFixtureTestPaths.contains(normalized);
}

/// Returns a violation reason when [content] constructs `Game(` inline instead
/// of importing shared fixtures from `test/support/diplomacy_game_fixtures.dart`.
String? diplomacyTestInlineGameCtorViolationReason(String slashPath, String content) {
  if (!diplomacyTestInlineGameCtorPathInScope(slashPath)) {
    return null;
  }
  final code = _stripLineComments(content);
  if (!_inlineGameConstructor.hasMatch(code)) {
    return null;
  }
  return "constructs Game(...) inline; import shared builders from "
      "'support/diplomacy_game_fixtures.dart' (Refs #3825)";
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

int runCheckDiplomacyTestInlineGameCtor(
  String repoRoot, {
  void Function(String line)? info,
  void Function(String line)? err,
}) {
  final logI = info ?? stdout.writeln;
  final logE = err ?? stderr.writeln;

  final violations = <String>[];
  for (final file in collectRepoLintDomainDartFiles(repoRoot)) {
    final rel = p.relative(file.path, from: repoRoot).replaceAll('\\', '/');
    final reason = diplomacyTestInlineGameCtorViolationReason(
      rel,
      file.readAsStringSync(),
    );
    if (reason != null) {
      violations.add('$rel: $reason');
    }
  }

  if (violations.isEmpty) {
    logI(
      'check_diplomacy_test_inline_game_ctor: no inline Game(...) violations.',
    );
    return 0;
  }
  logE(
    'check_diplomacy_test_inline_game_ctor: ${violations.length} violation(s):',
  );
  for (final violation in violations) {
    logE(' - $violation');
  }
  return 1;
}

void main() {
  exit(runCheckDiplomacyTestInlineGameCtor(Directory.current.path));
}
