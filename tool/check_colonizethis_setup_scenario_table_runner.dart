import 'dart:io';

import 'package:path/path.dart' as p;

import 'ct_repo_lint_scan_contract.dart';

/// SPEC: SPEC/program/repo-lint.md (Refs #4273).
///
/// Prefer-scenario-tables gate for colonizethis_setup tests. Flags long
/// imperative `test('…') { … }` bodies outside
/// [setupPreferScenarioTablesAllowlist]. Wave-6 slice D migrates the fat
/// creation/redistribution/naming suites; baseline allow-all stays on until
/// remaining imperative suites are table-driven.
///
/// Allowlist entries are repo-relative paths under
/// `packages/colonizethis_setup/test/` (forward slashes).

const _setupTestPrefix = 'packages/colonizethis_setup/test/';

/// Heuristic: `test('…') {` or `testWidgets('…') {` on one line.
final RegExp _longFormTestOpen = RegExp(
  r"""(?:test|testWidgets)\(\s*(?:'[^']*'|"[^"]*")\s*,\s*\(\)\s*\{""",
);

/// Look-behind window (lines) when searching for a surrounding scenario loop.
const _lookBehindLines = 8;

/// Documented-exception imperative suites after wave-7 slice C densify
/// (Refs #4349). Fat ≥300-line suites migrated to `support/*_scenarios.dart`;
/// remaining legitimately imperative suites stay allowlisted until a later
/// table-driven pass.
final Set<String> setupPreferScenarioTablesAllowlist = {
  'packages/colonizethis_setup/test/setup/advanced_start_bootstrap_colonization_test.dart',
  'packages/colonizethis_setup/test/setup/advanced_start_bootstrap_development_test.dart',
  'packages/colonizethis_setup/test/setup/advanced_start_bootstrap_prospecting_test.dart',
  'packages/colonizethis_setup/test/setup/advanced_start_bootstrap_test.dart',
  'packages/colonizethis_setup/test/setup/advanced_start_bootstrap_world_test.dart',
  'packages/colonizethis_setup/test/setup/advanced_start_init_game_test.dart',
  'packages/colonizethis_setup/test/setup/capital_choice_classification_test.dart',
  'packages/colonizethis_setup/test/setup/capital_choice_reassignment_test.dart',
  'packages/colonizethis_setup/test/setup/faction_setup_helpers_test.dart',
  'packages/colonizethis_setup/test/setup/full_assignment_verification_test.dart',
  'packages/colonizethis_setup/test/setup/game_setup_snapshot_test.dart',
  'packages/colonizethis_setup/test/setup/game_setup_town_tile_ranking_test.dart',
  'packages/colonizethis_setup/test/setup/gp_gp_auto_embassy_test.dart',
  'packages/colonizethis_setup/test/setup/gp_land_connectivity_repair_test.dart',
  'packages/colonizethis_setup/test/setup/gp_starting_grain_integration_test.dart',
  'packages/colonizethis_setup/test/setup/grid_bfs_test.dart',
  'packages/colonizethis_setup/test/setup/hidden_agenda_assignment_test.dart',
  'packages/colonizethis_setup/test/setup/init_game_human_ai_slots_test.dart',
  'packages/colonizethis_setup/test/setup/init_game_orchestrator_part1_test.dart',
  'packages/colonizethis_setup/test/setup/init_game_tribe_sea_bound_test.dart',
  'packages/colonizethis_setup/test/setup/init_game_world_market_seed_test.dart',
  'packages/colonizethis_setup/test/setup/init_pipeline_retry_test.dart',
  'packages/colonizethis_setup/test/setup/locked_assigner/locked_assigner_mechanics_test.dart',
  'packages/colonizethis_setup/test/setup/minor_tribe_starting_development_select_test.dart',
  'packages/colonizethis_setup/test/setup/minor_tribe_starting_development_test.dart',
  'packages/colonizethis_setup/test/setup/plains/game_setup_plains_conversion_test.dart',
  'packages/colonizethis_setup/test/setup/plains/game_setup_plains_terrain_restore_test.dart',
  'packages/colonizethis_setup/test/setup/plains/game_setup_plains_town_assignment_test.dart',
  'packages/colonizethis_setup/test/setup/province_tile_ranking_test.dart',
  'packages/colonizethis_setup/test/setup/seed_perturbation_test.dart',
  'packages/colonizethis_setup/test/setup/setup_exception_and_seed_coverage_test.dart',
  'packages/colonizethis_setup/test/setup/setup_logging_test.dart',
  'packages/colonizethis_setup/test/setup/setup_wave7_slice_a_api_surface_test.dart',
  'packages/colonizethis_setup/test/setup/tile_cell_scan_test.dart',
  'packages/colonizethis_setup/test/setup/validation_exceptions_test.dart',
  'packages/colonizethis_setup/test/setup/warp_zone_generator_test.dart',
};

/// When true, every existing `*_test.dart` under the setup test tree is
/// treated as allowlisted (wave-6 kickoff). Wave-7 slice C (#4349) tightens
/// to [setupPreferScenarioTablesAllowlist] only.
const bool setupPreferScenarioTablesBaselineAllowAll = false;

bool setupScenarioTableRunnerPathInScope(String slashPath) {
  final normalized = slashPath.replaceAll('\\', '/');
  return normalized.startsWith(_setupTestPrefix) &&
      normalized.endsWith('_test.dart');
}

String? setupScenarioTableRunnerViolationReason(
  String slashPath,
  String content, {
  bool baselineAllowAll = setupPreferScenarioTablesBaselineAllowAll,
  Set<String> allowlist = const {},
}) {
  final normalized = slashPath.replaceAll('\\', '/');
  if (!setupScenarioTableRunnerPathInScope(normalized)) {
    return null;
  }
  if (baselineAllowAll) {
    return null;
  }
  final effectiveAllowlist = allowlist.isEmpty
      ? setupPreferScenarioTablesAllowlist
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
        'add to allowlist (Refs #4273)';
  }
  return null;
}

int runCheckColonizethisSetupScenarioTableRunner(
  String repoRoot, {
  void Function(String line)? info,
  void Function(String line)? err,
}) {
  final logI = info ?? stdout.writeln;
  final logE = err ?? stderr.writeln;

  final violations = <String>[];
  for (final file in collectRepoLintDomainDartFiles(repoRoot)) {
    final rel = p.relative(file.path, from: repoRoot).replaceAll('\\', '/');
    if (!setupScenarioTableRunnerPathInScope(rel)) {
      continue;
    }
    final reason = setupScenarioTableRunnerViolationReason(
      rel,
      file.readAsStringSync(),
    );
    if (reason != null) {
      violations.add('$rel: $reason');
    }
  }

  if (violations.isEmpty) {
    logI(
      'check_colonizethis_setup_scenario_table_runner: no disallowed long '
      'imperative test bodies (baseline allow-all='
      '$setupPreferScenarioTablesBaselineAllowAll).',
    );
    return 0;
  }
  logE(
    'check_colonizethis_setup_scenario_table_runner: '
    '${violations.length} violation(s):',
  );
  for (final violation in violations) {
    logE(' - $violation');
  }
  return 1;
}

void main() {
  exit(runCheckColonizethisSetupScenarioTableRunner(Directory.current.path));
}
