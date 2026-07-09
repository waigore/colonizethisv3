import 'dart:io';

import 'package:path/path.dart' as p;

import 'ct_repo_lint_scan_contract.dart';

/// SPEC: SPEC/program/repo-lint.md (Refs #3949).
///
/// Prefer-scenario-tables gate for colonizethis_orders tests. Flags long
/// imperative `test('…') { … }` bodies (heuristic: opening `{` on the same
/// line as `test(` and no surrounding `for (final scenario` within a small
/// look-behind window) outside [ordersPreferScenarioTablesAllowlist]. Wave-3
/// slice 13 turns baseline allow-all off so only listed documented-exception
/// suites may keep long-form bodies (Refs #3949).
///
/// Allowlist entries are repo-relative paths under
/// `packages/colonizethis_orders/test/` (forward slashes).

const _ordersTestPrefix = 'packages/colonizethis_orders/test/';

/// Heuristic: `test('…') {` or `testWidgets('…') {` on one line.
final RegExp _longFormTestOpen = RegExp(
  r"""(?:test|testWidgets)\(\s*(?:'[^']*'|"[^"]*")\s*,\s*\(\)\s*\{""",
);

/// Look-behind window (lines) when searching for a surrounding scenario loop.
const _lookBehindLines = 8;

/// Allowlist of remaining imperative suites after wave-3 family migrations
/// (Refs #3949 slice 13). New long bodies outside this set fail the gate.
/// Documented-exception suites stay listed; migrated family runners are
/// scenario-loop covered and must not reappear here.
final Set<String> ordersPreferScenarioTablesAllowlist = {
  'packages/colonizethis_orders/test/debug_console/debug_console_supported_ids_test.dart',
  'packages/colonizethis_orders/test/orders/append_military_regiment_armies_by_id_test.dart',
  'packages/colonizethis_orders/test/orders/build_rail_work_rules_test.dart',
  'packages/colonizethis_orders/test/orders/civilian_projected_tile_test.dart',
  'packages/colonizethis_orders/test/orders/debug_console_workers_test.dart',
  'packages/colonizethis_orders/test/orders/diplomatic_panel_actions_test.dart',
  'packages/colonizethis_orders/test/orders/draft_orders_mutations_test.dart',
  'packages/colonizethis_orders/test/orders/explorer_consulate_gate_predicate_test.dart',
  'packages/colonizethis_orders/test/orders/merchant_purchase_land_candidate_tile_keys_test.dart',
  'packages/colonizethis_orders/test/orders/order_effects_projector_seam_test.dart',
  'packages/colonizethis_orders/test/orders/order_resolution_context_test.dart',
  'packages/colonizethis_orders/test/orders/order_suggestion_api_impl_diplomatic_minor_test.dart',
  'packages/colonizethis_orders/test/orders/order_suggestion_api_impl_diplomatic_test.dart',
  'packages/colonizethis_orders/test/orders/order_suggestion_api_impl_test.dart',
  'packages/colonizethis_orders/test/orders/order_suggestion_api_impl_trade_test.dart',
  'packages/colonizethis_orders/test/orders/order_suggestion_army_move_heuristics_test.dart',
  'packages/colonizethis_orders/test/orders/order_suggestion_army_move_picker_test.dart',
  'packages/colonizethis_orders/test/orders/order_suggestion_army_move_test.dart',
  'packages/colonizethis_orders/test/orders/order_suggestion_build_civilian_suggestion_test.dart',
  'packages/colonizethis_orders/test/orders/order_suggestion_build_pending_riches_test.dart',
  'packages/colonizethis_orders/test/orders/order_suggestion_colonial_intel_explore_test.dart',
  'packages/colonizethis_orders/test/orders/order_suggestion_context_helpers_test.dart',
  'packages/colonizethis_orders/test/orders/order_suggestion_diplomacy_filter_test.dart',
  'packages/colonizethis_orders/test/orders/order_suggestion_diplomatic_boycott_test.dart',
  'packages/colonizethis_orders/test/orders/order_suggestion_diplomatic_pass_test.dart',
  'packages/colonizethis_orders/test/orders/order_suggestion_helpers_test.dart',
  'packages/colonizethis_orders/test/orders/order_suggestion_no_order_engine_full_pass_test.dart',
  'packages/colonizethis_orders/test/orders/order_suggestion_pass_context_test.dart',
  'packages/colonizethis_orders/test/orders/order_suggestion_prospect_own_province_budget_priority_test.dart',
  'packages/colonizethis_orders/test/orders/order_suggestion_research_diversify_test.dart',
  'packages/colonizethis_orders/test/orders/order_suggestion_research_multi_slot_test.dart',
  'packages/colonizethis_orders/test/orders/order_suggestion_shared_validator_equivalence_test.dart',
  'packages/colonizethis_orders/test/orders/order_suggestion_unit_availability_test.dart',
  'packages/colonizethis_orders/test/orders/order_suggestion_work_logging_test.dart',
  'packages/colonizethis_orders/test/orders/order_suggestion_work_tile_keys_shared_validator_test.dart',
  'packages/colonizethis_orders/test/orders/order_suggestion_work_tile_prefilter_purchase_land_test.dart',
  'packages/colonizethis_orders/test/orders/order_visibility_test.dart',
  'packages/colonizethis_orders/test/orders/orders_logging_test.dart',
  'packages/colonizethis_orders/test/orders/partial_province_reveal_test.dart',
  'packages/colonizethis_orders/test/orders/per_player_work_target_selection_cache_test.dart',
  'packages/colonizethis_orders/test/orders/propagate_road_to_adjacent_capital_test.dart',
  'packages/colonizethis_orders/test/orders/upgrade_town_minor_tribe_test.dart',
  'packages/colonizethis_orders/test/orders/validators/build_order_treasury_no_bypass_test.dart',
  'packages/colonizethis_orders/test/orders/validators/build_order_validator_test.dart',
  'packages/colonizethis_orders/test/orders/validators/diplomatic/boycott_validator_test.dart',
  'packages/colonizethis_orders/test/orders/validators/diplomatic/break_alliance_validator_test.dart',
  'packages/colonizethis_orders/test/orders/validators/diplomatic/diplomatic_sub_validators_aid_test.dart',
  'packages/colonizethis_orders/test/orders/validators/diplomatic/diplomatic_sub_validators_faction_membership_test.dart',
  'packages/colonizethis_orders/test/orders/validators/diplomatic/diplomatic_sub_validators_relations_test.dart',
  'packages/colonizethis_orders/test/orders/validators/diplomatic/establish_overture_sub_validator_test.dart',
  'packages/colonizethis_orders/test/orders/validators/recruit_worker_order_validator_test.dart',
  'packages/colonizethis_orders/test/orders/validators/work_order_cost_calculator_test.dart',
  'packages/colonizethis_orders/test/orders/validators/work_order_target_prechecks_test.dart',
  'packages/colonizethis_orders/test/orders/work_handlers/explore_work_handler_test.dart',
  'packages/colonizethis_orders/test/orders/work_handlers/purchase_land_work_handler_test.dart',
  'packages/colonizethis_orders/test/orders/work_handlers/remaining_work_handlers_test.dart',
  'packages/colonizethis_orders/test/orders/work_order_duration_preview_test.dart',
};

/// When true, every existing `*_test.dart` under the orders test tree is
/// treated as allowlisted (wave-3 kickoff). Set false once migration coverage
/// is sufficient to tighten to [ordersPreferScenarioTablesAllowlist] only.
const bool ordersPreferScenarioTablesBaselineAllowAll = false;

bool ordersScenarioTableRunnerPathInScope(String slashPath) {
  final normalized = slashPath.replaceAll('\\', '/');
  return normalized.startsWith(_ordersTestPrefix) &&
      normalized.endsWith('_test.dart');
}

String? ordersScenarioTableRunnerViolationReason(
  String slashPath,
  String content, {
  bool baselineAllowAll = ordersPreferScenarioTablesBaselineAllowAll,
  Set<String> allowlist = const {},
}) {
  final normalized = slashPath.replaceAll('\\', '/');
  if (!ordersScenarioTableRunnerPathInScope(normalized)) {
    return null;
  }
  if (baselineAllowAll) {
    return null;
  }
  final effectiveAllowlist = allowlist.isEmpty
      ? ordersPreferScenarioTablesAllowlist
      : allowlist;
  if (effectiveAllowlist.contains(normalized)) {
    return null;
  }

  final lines = content.split('\n');
  for (var i = 0; i < lines.length; i++) {
    final line = lines[i];
    final trimmed = line.trimLeft();
    if (trimmed.startsWith('//') || trimmed.startsWith('*')) {
      continue;
    }
    if (!_longFormTestOpen.hasMatch(line)) {
      continue;
    }
    final start = i > _lookBehindLines ? i - _lookBehindLines : 0;
    final window = lines.sublist(start, i + 1).join('\n');
    if (window.contains('for (final scenario')) {
      continue;
    }
    return 'long imperative test() body without surrounding '
        '`for (final scenario` loop; migrate to support scenario tables or '
        'add to REFACTOR_TRACE.md / allowlist (Refs #3949)';
  }
  return null;
}

int runCheckOrdersScenarioTableRunner(
  String repoRoot, {
  void Function(String line)? info,
  void Function(String line)? err,
}) {
  final logI = info ?? stdout.writeln;
  final logE = err ?? stderr.writeln;

  final violations = <String>[];
  for (final file in collectRepoLintDomainDartFiles(repoRoot)) {
    final rel = p.relative(file.path, from: repoRoot).replaceAll('\\', '/');
    if (!ordersScenarioTableRunnerPathInScope(rel)) {
      continue;
    }
    final reason = ordersScenarioTableRunnerViolationReason(
      rel,
      file.readAsStringSync(),
    );
    if (reason != null) {
      violations.add('$rel: $reason');
    }
  }

  if (violations.isEmpty) {
    logI(
      'check_orders_scenario_table_runner: no disallowed long imperative '
      'test bodies (baseline allow-all=$ordersPreferScenarioTablesBaselineAllowAll).',
    );
    return 0;
  }
  logE(
    'check_orders_scenario_table_runner: ${violations.length} violation(s):',
  );
  for (final violation in violations) {
    logE(' - $violation');
  }
  return 1;
}

void main() {
  exit(runCheckOrdersScenarioTableRunner(Directory.current.path));
}
