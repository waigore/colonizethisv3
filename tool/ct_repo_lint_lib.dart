import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:yaml/yaml.dart';

import 'check_app_editorial_monocle_colors.dart';
import 'check_app_event_bus_decoupling.dart';
import 'check_app_event_handler_scope_logic_boundary.dart';
import 'check_app_hardcoded_ui_strings.dart';
import 'check_app_no_duplicate_helpers.dart';
import 'check_app_no_material_alertdialog.dart';
import 'check_app_no_material_button.dart';
import 'check_app_no_material_chip.dart';
import 'check_app_no_material_filterchip.dart';
import 'check_app_no_material_iconbutton.dart';
import 'check_app_no_material_listtile.dart';
import 'check_app_no_material_scaffold.dart';
import 'check_app_no_material_switchlisttile.dart';
import 'check_app_no_material_textbutton.dart';
import 'check_app_shell_panel_dedup.dart';
import 'check_app_widgetbook_file_naming.dart';
import 'check_app_textstyle_fontsize_fallback.dart';
import 'check_app_widget_imports.dart';
import 'check_asset_path_constants.dart';
import 'check_canonical_province_tile_keys.dart';
import 'check_colonizethis_map_lib_pipe_split.dart';
import 'check_tile_map_inline_cardinal_directions.dart';
import 'check_civilian_unit_type_constants.dart';
import 'check_control_flow_nesting_depth.dart';
import 'check_custom_exceptions.dart';
import 'check_dart_file_non_comment_line_size.dart';
import 'check_diplomacy_no_part_of.dart';
import 'check_debug_handler_one_per_file.dart';
import 'check_debug_console_logic_contract_boundary.dart';
import 'check_debug_console_shared_helpers.dart';
import 'check_disallowed_ast_patterns.dart';
import 'check_long_string_switches.dart';
import 'check_map_gen_file_size.dart';
import 'check_map_gen_no_image_import.dart';
import 'check_map_gen_stage_protocol.dart';
import 'check_map_no_partfile_classes.dart';
import 'check_map_grid_cell_iteration_central.dart';
import 'check_map_grid_ops_central.dart';
import 'check_map_public_barrel_surface.dart';
import 'check_map_region_data_access_central.dart';
import 'check_map_region_dispatch_central.dart';
import 'check_flutter_action_pins.dart';
import 'check_function_size.dart';
import 'check_game_widgets_file_size.dart';
import 'check_economy_cost_check_shared_helper.dart';
import 'check_land_province_bucket_keys.dart';
import 'check_orders_dedup_diplomatic_helpers.dart';
import 'check_orders_dedup_map_clones.dart';
import 'check_setup_dedup_gp_ids_from_players.dart';
import 'check_setup_dedup_gp_ow_tile_scans.dart';
import 'check_setup_dedup_init_pipeline_retry.dart';
import 'check_logic_diplomatic_sub_validator_size.dart';
import 'check_logic_work_target_switch.dart';
import 'check_logic_test_file_size.dart';
import 'check_logic_domain_import_dag.dart';
import 'check_logic_source_file_size.dart';
import 'check_world_no_logic_deps.dart';
import 'check_logic_no_map_deps.dart';
import 'check_world_no_circular_imports.dart';
import 'check_logic_dead_files.dart';
import 'check_logic_dedup_logger.dart';
import 'check_domain_package_logger_dedup.dart';
import 'check_ai_api_narrow_surface.dart';
import 'check_ai_planner_context.dart';
import 'check_logic_all_provinces_sanctioned_calls.dart';
import 'check_logic_dual_region_province_field_access.dart';
import 'check_logic_units_by_id_rebuild.dart';
import 'check_logic_validator_units_params.dart';
import 'check_no_flame_in_widgets.dart';
import 'check_no_screen_in_game_widgets.dart';
import 'check_part_unit_size.dart';
import 'check_repeated_magic_numbers.dart';
import 'check_screen_registry_active_paths.dart';
import 'check_subscription_tracker.dart';
import 'check_tech_id_constants.dart';
import 'check_turn_no_part_directives.dart';
import 'check_turn_resume_param_budget.dart';
import 'check_work_target_constants.dart';
import 'check_workspace_outdated_latest_direct.dart';
import 'check_workspace_outdated_resolvable.dart';
import 'ct_repo_lint_scan_contract.dart';

/// One entry from [tool/ct_repo_lint_manifest.yaml].
final class RepoLintRule {
  const RepoLintRule({
    required this.ruleId,
    required this.group,
    required this.title,
    required this.spec,
    required this.runner,
    required this.argv,
    required this.script,
    required this.prIncremental,
    required this.includeOnlyWhenEnvName,
    required this.includeOnlyWhenEnvValue,
  });

  final String ruleId;
  final String group;
  final String title;
  final String spec;
  final String runner;
  final List<String> argv;
  final String? script;
  final bool prIncremental;
  final String? includeOnlyWhenEnvName;
  final String? includeOnlyWhenEnvValue;
}

/// Parsed CLI options for [runRepoLint].
final class RepoLintOptions {
  const RepoLintOptions({
    required this.manifestPath,
    required this.listOnly,
    required this.verbose,
    required this.onlyRuleId,
    required this.onlyGroup,
    required this.forceFullScan,
    required this.sarifOutputPath,
  });

  final String manifestPath;
  final bool listOnly;
  final bool verbose;
  final String? onlyRuleId;
  final String? onlyGroup;
  final bool forceFullScan;

  /// When set, run every selected rule (do not stop at the first failure) and
  /// write SARIF 2.1.0 to this path, or `-` for stdout.
  final String? sarifOutputPath;
}

RepoLintOptions parseRepoLintArgs(List<String> args) {
  var manifestPath = 'tool/ct_repo_lint_manifest.yaml';
  var listOnly = false;
  var verbose = false;
  var onlyRuleId = '';
  var onlyGroup = '';
  var forceFullScan = false;
  String? sarifOutputPath;

  for (var i = 0; i < args.length; i++) {
    final a = args[i];
    if (a == '--help' || a == '-h') {
      stdout.writeln(_usage);
      exit(0);
    }
    if (a == '--list') {
      listOnly = true;
      continue;
    }
    if (a == '--verbose' || a == '-v') {
      verbose = true;
      continue;
    }
    if (a == '--force-full-scan') {
      forceFullScan = true;
      continue;
    }
    if (a.startsWith('--manifest=')) {
      manifestPath = a.substring('--manifest='.length);
      continue;
    }
    if (a == '--manifest') {
      i++;
      if (i >= args.length) {
        stderr.writeln('ct_repo_lint: --manifest requires a path');
        exit(2);
      }
      manifestPath = args[i];
      continue;
    }
    if (a.startsWith('--rule=')) {
      onlyRuleId = a.substring('--rule='.length);
      continue;
    }
    if (a == '--rule') {
      i++;
      if (i >= args.length) {
        stderr.writeln('ct_repo_lint: --rule requires an id');
        exit(2);
      }
      onlyRuleId = args[i];
      continue;
    }
    if (a.startsWith('--group=')) {
      onlyGroup = a.substring('--group='.length);
      continue;
    }
    if (a == '--group') {
      i++;
      if (i >= args.length) {
        stderr.writeln('ct_repo_lint: --group requires a name');
        exit(2);
      }
      onlyGroup = args[i];
      continue;
    }
    if (a.startsWith('--sarif=')) {
      sarifOutputPath = a.substring('--sarif='.length);
      continue;
    }
    if (a == '--sarif') {
      i++;
      if (i >= args.length) {
        stderr.writeln('ct_repo_lint: --sarif requires a path or -');
        exit(2);
      }
      sarifOutputPath = args[i];
      continue;
    }
    stderr.writeln('ct_repo_lint: unknown argument: $a');
    stderr.writeln(_usage);
    exit(2);
  }

  if (listOnly && sarifOutputPath != null) {
    stderr.writeln('ct_repo_lint: --sarif cannot be used with --list');
    exit(2);
  }

  return RepoLintOptions(
    manifestPath: manifestPath,
    listOnly: listOnly,
    verbose: verbose,
    onlyRuleId: onlyRuleId.isEmpty ? null : onlyRuleId,
    onlyGroup: onlyGroup.isEmpty ? null : onlyGroup,
    forceFullScan: forceFullScan,
    sarifOutputPath: sarifOutputPath,
  );
}

const _usage = '''
ct_repo_lint — unified repo convention checks (manifest-driven).

Usage:
  dart run tool/ct_repo_lint.dart [options]

Options:
  --manifest <path>     Manifest YAML (default: tool/ct_repo_lint_manifest.yaml)
  --list                Print rule_id, group, and title; exit 0
  --rule <rule_id>      Run only this rule
  --group <name>        Run only rules in this group
  --force-full-scan     Do not pass PR incremental --files to supported rules
  --verbose, -v         Log each rule as it starts
  --sarif <path>        After running, write SARIF 2.1.0 (run all rules; use - for stdout)
  --help, -h            Show this message

Environment:
  CT_REPO_LINT_INCLUDE_APP=true   Include repo.app_hardcoded_ui_strings (Quality workflow sets this when app/package paths changed)
  GITHUB_BASE_REF                 When set (not force-full-scan), incremental rules receive --files for changed *.dart on the PR branch
''';

List<RepoLintRule> loadRepoLintManifest(
  String repoRoot,
  String manifestRelativePath,
) {
  final manifestFile = File(p.join(repoRoot, manifestRelativePath));
  if (!manifestFile.existsSync()) {
    stderr.writeln('ct_repo_lint: manifest not found: ${manifestFile.path}');
    exit(2);
  }
  final yaml = loadYaml(manifestFile.readAsStringSync());
  if (yaml is! YamlMap) {
    stderr.writeln('ct_repo_lint: manifest root must be a map');
    exit(2);
  }
  final rulesYaml = yaml['rules'];
  if (rulesYaml is! YamlList) {
    stderr.writeln('ct_repo_lint: manifest missing rules: list');
    exit(2);
  }

  final out = <RepoLintRule>[];
  for (final entry in rulesYaml) {
    if (entry is! YamlMap) {
      continue;
    }
    final ruleId = entry['rule_id']?.toString();
    final group = entry['group']?.toString() ?? 'default';
    final title = entry['title']?.toString() ?? ruleId ?? '(untitled)';
    final spec = entry['spec']?.toString() ?? '';
    final runner = entry['runner']?.toString() ?? '';
    if (ruleId == null || ruleId.isEmpty) {
      stderr.writeln('ct_repo_lint: rule missing rule_id');
      exit(2);
    }
    if (runner != 'shell' && runner != 'dart') {
      stderr.writeln(
        'ct_repo_lint: rule $ruleId: runner must be shell or dart',
      );
      exit(2);
    }

    String? script;
    var argv = <String>[];
    if (runner == 'shell') {
      final a = entry['argv'];
      if (a is! YamlList || a.isEmpty) {
        stderr.writeln(
          'ct_repo_lint: rule $ruleId: shell runner requires argv',
        );
        exit(2);
      }
      argv = a.map((e) => e.toString()).toList();
    } else {
      script = entry['script']?.toString();
      if (script == null || script.isEmpty) {
        stderr.writeln(
          'ct_repo_lint: rule $ruleId: dart runner requires script',
        );
        exit(2);
      }
    }

    final prInc = entry['pr_incremental'] == true;
    final envGate = entry['include_only_when_env'];
    String? envName;
    String? envValue;
    if (envGate is YamlMap) {
      envName = envGate['name']?.toString();
      envValue = envGate['value']?.toString();
      if (envName == null || envName.isEmpty || envValue == null) {
        stderr.writeln(
          'ct_repo_lint: rule $ruleId: include_only_when_env needs name and value',
        );
        exit(2);
      }
    }

    out.add(
      RepoLintRule(
        ruleId: ruleId,
        group: group,
        title: title,
        spec: spec,
        runner: runner,
        argv: argv,
        script: script,
        prIncremental: prInc,
        includeOnlyWhenEnvName: envName,
        includeOnlyWhenEnvValue: envValue,
      ),
    );
  }
  return out;
}

/// Resolves a comma-separated list of changed `*.dart` paths for PR workflows,
/// matching `.github/workflows/quality.yml` (three-dot diff vs `origin/$GITHUB_BASE_REF`).
String? resolvePrChangedDartFilesCsv() {
  final explicitBaseSha = Platform.environment['CT_REPO_LINT_BASE_SHA'];
  if (explicitBaseSha != null && explicitBaseSha.trim().isNotEmpty) {
    final normalizedBaseSha = explicitBaseSha.trim();
    final fetchExplicit = Process.runSync(
      'git',
      ['fetch', '--no-tags', '--depth=1', 'origin', normalizedBaseSha],
      workingDirectory: Directory.current.path,
      runInShell: false,
    );
    if (fetchExplicit.exitCode == 0) {
      final csv = _resolveChangedDartFilesCsvForBaseSha(normalizedBaseSha);
      if (csv != null) {
        return csv;
      }
    }
    final csv = _resolveChangedDartFilesCsvForLeft(normalizedBaseSha);
    if (csv != null) {
      return csv;
    }
  }

  final baseRef = Platform.environment['GITHUB_BASE_REF'];
  if (baseRef == null || baseRef.isEmpty) {
    return null;
  }

  final fetch = Process.runSync(
    'git',
    ['fetch', '--no-tags', '--depth=1', 'origin', baseRef],
    workingDirectory: Directory.current.path,
    runInShell: false,
  );
  final primaryLeft = 'origin/$baseRef';
  if (fetch.exitCode == 0) {
    final csv = _resolveChangedDartFilesCsvForLeft(primaryLeft);
    if (csv != null) {
      return csv;
    }
  }

  // CI may check out a merge commit and/or omit remote refs in shallow clones.
  // Fall back to the first parent when origin/<base> cannot be resolved.
  return _resolveChangedDartFilesCsvForLeft('HEAD^');
}

String? _resolveChangedDartFilesCsvForBaseSha(String baseSha) {
  final diff = Process.runSync(
    'git',
    ['diff', '--name-only', '$baseSha..HEAD', '--', '*.dart'],
    workingDirectory: Directory.current.path,
    runInShell: false,
  );
  if (diff.exitCode != 0) {
    return null;
  }
  final lines = diff.stdout
      .toString()
      .split('\n')
      .map((l) => l.trim())
      .where((l) => l.isNotEmpty)
      .toList();
  if (lines.isEmpty) {
    // Distinguish "no Dart files changed" from "could not resolve baseline".
    // PR-incremental rules should scan zero files, not fall back to full scan.
    return '';
  }
  return lines.join(',');
}

String? _resolveChangedDartFilesCsvForLeft(String leftRef) {
  final mergeBase = Process.runSync(
    'git',
    ['merge-base', leftRef, 'HEAD'],
    workingDirectory: Directory.current.path,
    runInShell: false,
  );
  if (mergeBase.exitCode != 0) {
    return null;
  }
  final mergeBaseSha = mergeBase.stdout.toString().trim();
  if (mergeBaseSha.isEmpty) {
    return null;
  }

  final diff = Process.runSync(
    'git',
    ['diff', '--name-only', '$mergeBaseSha..HEAD', '--', '*.dart'],
    workingDirectory: Directory.current.path,
    runInShell: false,
  );
  if (diff.exitCode != 0) {
    return null;
  }

  final lines = diff.stdout
      .toString()
      .split('\n')
      .map((l) => l.trim())
      .where((l) => l.isNotEmpty)
      .toList();

  if (lines.isEmpty) {
    // Keep PR-incremental behavior explicit when there are no changed Dart files.
    return '';
  }
  return lines.join(',');
}

bool ruleIsIncluded(RepoLintRule rule) {
  final gateName = rule.includeOnlyWhenEnvName;
  final gateValue = rule.includeOnlyWhenEnvValue;
  if (gateName == null || gateValue == null) {
    return true;
  }
  final actual = Platform.environment[gateName];
  return actual == gateValue;
}

/// Runs selected rules; returns exit code (0 = success).
int runRepoLint({
  required String repoRoot,
  required List<RepoLintRule> allRules,
  required RepoLintOptions options,
}) {
  final incrementalCsv = options.forceFullScan
      ? null
      : resolvePrChangedDartFilesCsv();

  var rules = List<RepoLintRule>.from(allRules);

  if (options.onlyRuleId != null) {
    rules = rules.where((r) => r.ruleId == options.onlyRuleId).toList();
    if (rules.isEmpty) {
      stderr.writeln(
        'ct_repo_lint: no rule with rule_id "${options.onlyRuleId}"',
      );
      return 2;
    }
  } else if (options.onlyGroup != null) {
    rules = rules.where((r) => r.group == options.onlyGroup).toList();
    if (rules.isEmpty) {
      stderr.writeln('ct_repo_lint: no rules in group "${options.onlyGroup}"');
      return 2;
    }
  }

  if (options.listOnly) {
    for (final r in rules) {
      stdout.writeln('${r.ruleId}\t${r.group}\t${r.title}');
    }
    return 0;
  }

  rules = rules.where(ruleIsIncluded).toList();
  if (rules.isEmpty) {
    stderr.writeln(
      'ct_repo_lint: no rules to run after env gates '
      '(e.g. set CT_REPO_LINT_INCLUDE_APP=true for repo.app_hardcoded_ui_strings).',
    );
    return 2;
  }

  if (options.sarifOutputPath != null) {
    return _runRepoLintWithSarif(
      repoRoot: repoRoot,
      rules: rules,
      options: options,
      incrementalCsv: incrementalCsv,
    );
  }

  for (final rule in rules) {
    if (options.verbose) {
      stderr.writeln('ct_repo_lint: [${rule.ruleId}] ${rule.title}');
    }

    final code = _runOneRule(
      repoRoot: repoRoot,
      rule: rule,
      incrementalCsv: incrementalCsv,
      relayChildStdoutToStderr: false,
    );
    if (code != 0) {
      return code;
    }
  }

  stdout.writeln('ct_repo_lint: all ${rules.length} rule(s) passed.');
  return 0;
}

int _runRepoLintWithSarif({
  required String repoRoot,
  required List<RepoLintRule> rules,
  required RepoLintOptions options,
  required String? incrementalCsv,
}) {
  final failures = <({RepoLintRule rule, int exitCode})>[];
  for (final rule in rules) {
    if (options.verbose) {
      stderr.writeln('ct_repo_lint: [${rule.ruleId}] ${rule.title}');
    }

    final code = _runOneRule(
      repoRoot: repoRoot,
      rule: rule,
      incrementalCsv: incrementalCsv,
      relayChildStdoutToStderr: true,
    );
    if (code != 0) {
      failures.add((rule: rule, exitCode: code));
    }
  }

  final sarifText = encodeCtRepoLintSarif(
    executedRules: rules,
    failures: failures,
  );
  _writeSarifOutput(options.sarifOutputPath!, sarifText);

  if (failures.isEmpty) {
    stderr.writeln('ct_repo_lint: all ${rules.length} rule(s) passed.');
    return 0;
  }
  stderr.writeln(
    'ct_repo_lint: ${failures.length} rule(s) failed (SARIF written).',
  );
  return 1;
}

void _writeSarifOutput(String path, String json) {
  final text = json.endsWith('\n') ? json : '$json\n';
  if (path == '-') {
    stdout.write(text);
    return;
  }
  File(path).writeAsStringSync(text);
}

/// Builds SARIF 2.1.0 JSON for [executedRules] and failed runs in [failures].
/// Exposed for tests.
String encodeCtRepoLintSarif({
  required List<RepoLintRule> executedRules,
  required List<({RepoLintRule rule, int exitCode})> failures,
}) {
  return JsonEncoder.withIndent('  ').convert(
    buildCtRepoLintSarifObject(
      executedRules: executedRules,
      failures: failures,
    ),
  );
}

/// SARIF object before JSON encoding. Exposed for tests.
Map<String, Object?> buildCtRepoLintSarifObject({
  required List<RepoLintRule> executedRules,
  required List<({RepoLintRule rule, int exitCode})> failures,
}) {
  final driverRules = <Map<String, Object?>>[];
  final ruleIndexById = <String, int>{};
  for (var i = 0; i < executedRules.length; i++) {
    final r = executedRules[i];
    ruleIndexById[r.ruleId] = i;
    driverRules.add({
      'id': r.ruleId,
      'name': r.title,
      if (r.spec.isNotEmpty) 'shortDescription': {'text': 'SPEC: ${r.spec}'},
    });
  }

  final results = <Map<String, Object?>>[];
  for (final f in failures) {
    final uri = f.rule.runner == 'dart'
        ? (f.rule.script ?? 'unknown.dart')
        : (f.rule.argv.isNotEmpty ? f.rule.argv.first : 'unknown');
    results.add({
      'ruleId': f.rule.ruleId,
      'ruleIndex': ruleIndexById[f.rule.ruleId]!,
      'level': 'error',
      'message': {
        'text':
            'Convention check failed (exit ${f.exitCode}). See log output for file and line details.',
      },
      'locations': [
        {
          'physicalLocation': {
            'artifactLocation': {'uri': uri},
          },
        },
      ],
    });
  }

  return {
    r'$schema':
        'https://raw.githubusercontent.com/oasis-tcs/sarif-spec/master/Schemata/sarif-schema-2.1.0.json',
    'version': '2.1.0',
    'runs': [
      {
        'tool': {
          'driver': {
            'name': 'ct_repo_lint',
            'informationUri': 'https://github.com/waigore/colonizethisv3',
            'rules': driverRules,
          },
        },
        'results': results,
      },
    ],
  };
}

int _runOneRule({
  required String repoRoot,
  required RepoLintRule rule,
  required String? incrementalCsv,
  required bool relayChildStdoutToStderr,
}) {
  stderr.writeln('ct_repo_lint: --- [${rule.ruleId}] ${rule.title} ---');

  if (rule.runner == 'shell') {
    final rel = rule.argv.first;
    final scriptPath = p.join(repoRoot, rel);
    final result = Process.runSync(
      'bash',
      [scriptPath, ...rule.argv.skip(1)],
      workingDirectory: repoRoot,
      environment: Platform.environment,
      runInShell: false,
    );
    _forwardProcessOutput(
      result,
      relayStdoutToStderr: relayChildStdoutToStderr,
    );
    if (result.exitCode != 0) {
      stderr.writeln(
        'ct_repo_lint: FAILED [${rule.ruleId}] exit ${result.exitCode} (see output above)',
      );
    }
    return result.exitCode;
  }

  final inProcess = _tryRunDartRuleInProcess(
    rule: rule,
    repoRoot: repoRoot,
    incrementalCsv: incrementalCsv,
  );
  if (inProcess != null) {
    if (inProcess != 0) {
      stderr.writeln(
        'ct_repo_lint: FAILED [${rule.ruleId}] exit $inProcess (see output above)',
      );
    }
    return inProcess;
  }

  final script = rule.script!;
  final args = <String>['run', script];
  if (rule.prIncremental && incrementalCsv != null) {
    args.addAll(['--files', incrementalCsv]);
  }

  final result = Process.runSync(
    Platform.resolvedExecutable,
    args,
    workingDirectory: repoRoot,
    environment: Platform.environment,
    runInShell: false,
  );
  _forwardProcessOutput(result, relayStdoutToStderr: relayChildStdoutToStderr);
  if (result.exitCode != 0) {
    stderr.writeln(
      'ct_repo_lint: FAILED [${rule.ruleId}] exit ${result.exitCode} (see output above)',
    );
  }
  return result.exitCode;
}

/// Runs manifest Dart rules in-process when wired; returns `null` to fall back
/// to `dart run` (unknown [RepoLintRule.ruleId] or future scripts).
///
/// The dispatch is split into category-scoped helpers so each individual
/// `switch` stays below the `repo.dart_long_string_switches` 49-case ceiling
/// even as new manifest rules are added. The split is purely structural —
/// dispatch order (app-specific first, then generic repo-wide) is preserved
/// because `_tryRunAppRuleInProcess` returns `null` for non-app ids and the
/// caller falls back to the generic dispatch unchanged.
int? _tryRunDartRuleInProcess({
  required RepoLintRule rule,
  required String repoRoot,
  required String? incrementalCsv,
}) {
  List<String>? incrementalPaths;
  if (rule.prIncremental && incrementalCsv != null) {
    incrementalPaths = repoLintSplitRelativeDartPathsArg(incrementalCsv);
  }

  final int? appResult = _tryRunAppRuleInProcess(
    ruleId: rule.ruleId,
    repoRoot: repoRoot,
    incrementalPaths: incrementalPaths,
  );
  if (appResult != null) {
    return appResult;
  }

  final int? logicResult = _tryRunLogicRuleInProcess(
    ruleId: rule.ruleId,
    repoRoot: repoRoot,
    incrementalPaths: incrementalPaths,
  );
  if (logicResult != null) {
    return logicResult;
  }

  final int? mapResult = _tryRunMapRuleInProcess(
    ruleId: rule.ruleId,
    repoRoot: repoRoot,
  );
  if (mapResult != null) {
    return mapResult;
  }

  switch (rule.ruleId) {
    case 'repo.custom_exceptions':
      return runCheckCustomExceptions(repoRoot);
    case 'repo.asset_path_constants':
      return runCheckAssetPathConstants(repoRoot);
    case 'repo.disallowed_ast_patterns':
      return runCheckDisallowedAstPatterns(
        repoRoot,
        incrementalRelativeDartPaths: incrementalPaths,
      );
    case 'repo.flutter_action_pins':
      return runCheckFlutterActionPins(repoRoot);
    case 'repo.workspace_outdated_resolvable':
      return runCheckWorkspaceOutdatedResolvable(repoRoot);
    case 'repo.workspace_outdated_latest_direct':
      return runCheckWorkspaceOutdatedLatestDirect(repoRoot);
    case 'repo.debug_console_logic_contract_boundary':
      return runCheckDebugConsoleLogicContractBoundary(
        repoRoot,
        incrementalRelativeDartPaths: incrementalPaths,
      );
    case 'repo.debug_console_shared_helpers':
      return runCheckDebugConsoleSharedHelpers(repoRoot);
    case 'repo.app_event_handler_scope_logic_boundary':
      return runCheckAppEventHandlerScopeLogicBoundary(repoRoot);
    case 'repo.app_event_bus_decoupling':
      return runCheckAppEventBusDecoupling(repoRoot);
    case 'repo.app_no_shell_panel_duplication':
      return runCheckAppShellPanelDedup(repoRoot);
    case 'repo.control_flow_nesting_depth':
      return runCheckControlFlowNestingDepth(repoRoot);
    case 'repo.repeated_magic_numbers':
      return runCheckRepeatedMagicNumbers(repoRoot);
    case 'repo.dart_long_string_switches':
      return runCheckLongStringSwitches(repoRoot);
    case 'repo.function_size':
      return runCheckFunctionSize(repoRoot);
    case 'repo.debug_handler_one_per_file':
      return runCheckDebugHandlerOnePerFile(repoRoot);
    case 'repo.game_widgets_file_size':
      return runCheckGameWidgetsFileSize(repoRoot);
    case 'repo.world_no_logic_deps':
      return runCheckWorldNoLogicDeps(repoRoot);
    case 'repo.logic_no_map_deps':
      return runCheckLogicNoMapDeps(repoRoot);
    case 'repo.world_no_circular_imports':
      return runCheckWorldNoCircularImports(repoRoot);
    case 'repo.dart_file_non_comment_line_size':
      return runCheckDartFileNonCommentLineSize(
        repoRoot,
        incrementalRelativeDartPaths: incrementalPaths,
      );
    case 'repo.part_unit_size':
      return runCheckPartUnitSize(repoRoot);
    case 'repo.turn_no_part_directives':
      return runCheckTurnNoPartDirectives(repoRoot);
    case 'repo.turn_resume_param_budget':
      return runCheckTurnResumeParamBudget(repoRoot);
    case 'repo.diplomacy_no_part_of':
      return runCheckDiplomacyNoPartOf(repoRoot);
    case 'repo.no_flame_in_widgets':
      return runCheckNoFlameInWidgets(repoRoot);
    case 'repo.no_screen_in_game_widgets':
      return runCheckNoScreenInGameWidgets(repoRoot);
    case 'repo.subscription_tracker':
      return runCheckSubscriptionTracker(repoRoot);
    case 'repo.tech_id_constants':
      return runCheckTechIdConstants(
        repoRoot,
        incrementalRelativeDartPaths: incrementalPaths,
      );
    case 'repo.work_target_constants':
      return runCheckWorkTargetConstants(
        repoRoot,
        incrementalRelativeDartPaths: incrementalPaths,
      );
    case 'repo.civilian_unit_type_constants':
      return runCheckCivilianUnitTypeConstants(
        repoRoot,
        incrementalRelativeDartPaths: incrementalPaths,
      );
    case 'repo.canonical_province_tile_keys':
      return runCheckCanonicalProvinceTileKeys(repoRoot);
    case 'repo.land_province_bucket_keys':
      return runCheckLandProvinceBucketKeys(repoRoot);
    case 'repo.orders_dedup_map_clones':
      return runCheckOrdersDedupMapClones(repoRoot);
    case 'repo.orders_dedup_diplomatic_helpers':
      return runCheckOrdersDedupDiplomaticHelpers(repoRoot);
    case 'repo.setup_dedup_init_pipeline_retry':
      return runCheckSetupDedupInitPipelineRetry(repoRoot);
    case 'repo.setup_dedup_gp_ow_tile_scans':
      return runCheckSetupDedupGpOwTileScans(repoRoot);
    case 'repo.setup_dedup_gp_ids_from_players':
      return runCheckSetupDedupGpIdsFromPlayers(repoRoot);
    case 'repo.domain_package_logger_dedup':
      return runCheckDomainPackageLoggerDedup(repoRoot);
    case 'repo.ai_api_narrow_surface':
      return runCheckAiApiNarrowSurface(repoRoot);
    case 'repo.ai_planner_context':
      return runCheckAiPlannerContext(repoRoot);
    case 'repo.screen_registry_active_paths':
      return runCheckScreenRegistryActivePaths(repoRoot);
    default:
      return null;
  }
}

/// Dispatch helper for `repo.app_*` manifest rules. Keeps the main
/// `_tryRunDartRuleInProcess` switch under the `repo.dart_long_string_switches`
/// 49-case ceiling as new app-scoped rules are added (e.g. the Material widget
/// ban family per #2914). Returns `null` for non-app rule ids so the caller
/// falls back to the generic dispatch.
int? _tryRunAppRuleInProcess({
  required String ruleId,
  required String repoRoot,
  required List<String>? incrementalPaths,
}) {
  switch (ruleId) {
    case 'repo.app_hardcoded_ui_strings':
      return runCheckAppHardcodedUiStrings(repoRoot);
    case 'repo.app_no_duplicate_helpers':
      return runCheckAppNoDuplicateHelpers(repoRoot);
    case 'repo.app_widget_imports':
      return runCheckAppWidgetImports(repoRoot);
    case 'repo.app_editorial_monocle_colors':
      return runCheckAppEditorialMonocleColors(repoRoot);
    case 'repo.app_textstyle_fontsize_fallback':
      return runCheckAppTextStyleFontSizeFallback(repoRoot);
    case 'repo.app_no_material_alertdialog':
      return runCheckAppNoMaterialAlertDialog(repoRoot);
    case 'repo.app_no_material_button':
      return runCheckAppNoMaterialButton(repoRoot);
    case 'repo.app_no_material_chip':
      return runCheckAppNoMaterialChip(repoRoot);
    case 'repo.app_no_material_filterchip':
      return runCheckAppNoMaterialFilterChip(repoRoot);
    case 'repo.app_no_material_iconbutton':
      return runCheckAppNoMaterialIconButton(repoRoot);
    case 'repo.app_no_material_listtile':
      return runCheckAppNoMaterialListTile(repoRoot);
    case 'repo.app_no_material_switchlisttile':
      return runCheckAppNoMaterialSwitchListTile(repoRoot);
    case 'repo.app_no_material_textbutton':
      return runCheckAppNoMaterialTextButton(repoRoot);
    case 'repo.app_no_material_scaffold':
      return runCheckAppNoMaterialScaffold(repoRoot);
    case 'repo.app_widgetbook_file_naming':
      return runCheckAppWidgetbookFileNaming(repoRoot);
    default:
      return null;
  }
}

/// Dispatch helper for `repo.logic_*` manifest rules. Keeps the main
/// `_tryRunDartRuleInProcess` switch under the `repo.dart_long_string_switches`
/// 49-case ceiling as new logic-scoped rules are added. Returns `null` for
/// non-logic rule ids so the caller falls back to the generic dispatch.
int? _tryRunLogicRuleInProcess({
  required String ruleId,
  required String repoRoot,
  required List<String>? incrementalPaths,
}) {
  switch (ruleId) {
    case 'repo.logic_diplomatic_sub_validator_size':
      return runCheckLogicDiplomaticSubValidatorSize(repoRoot);
    case 'repo.logic_work_target_switch':
      return runCheckLogicWorkTargetSwitch(repoRoot);
    case 'repo.logic_test_file_size':
      // Full-tree enforcement (GitHub #2288): the #2216 file-size debt is now
      // cleared across `packages/colonizethis_logic/test/**`, so the rule
      // scans the entire tree when no changed-file baseline is provided and
      // narrows to changed files when CI supplies an incremental baseline.
      return runCheckLogicTestFileSize(repoRoot, targetFiles: incrementalPaths);
    case 'repo.logic_domain_import_dag':
      return runCheckLogicDomainImportDag(repoRoot);
    case 'repo.logic_source_file_size':
      return runCheckLogicSourceFileSize(repoRoot);
    case 'repo.logic_dual_region_province_field_access':
      return runCheckLogicDualRegionProvinceFieldAccess(repoRoot);
    case 'repo.logic_all_provinces_sanctioned_calls':
      return runCheckLogicAllProvincesSanctionedCalls(repoRoot);
    case 'repo.logic_units_by_id_rebuild':
      return runCheckLogicUnitsByIdRebuild(repoRoot);
    case 'repo.logic_validator_units_params':
      return runCheckLogicValidatorUnitsParams(repoRoot);
    case 'repo.logic_dead_files':
      return runCheckLogicDeadFiles(repoRoot);
    case 'repo.logic_dedup_logger':
      return runCheckLogicDedupLogger(repoRoot);
    case 'repo.economy_cost_check_shared_helper':
      return runCheckEconomyCostCheckSharedHelper(repoRoot);
    default:
      return null;
  }
}

/// Dispatch helper for `colonizethis_map` package manifest rules. Keeps the
/// main `_tryRunDartRuleInProcess` switch under the
/// `repo.dart_long_string_switches` 49-case ceiling as new map-scoped rules are
/// added (Refs #3574). Returns `null` for non-map rule ids so the caller falls
/// back to the generic dispatch.
int? _tryRunMapRuleInProcess({
  required String ruleId,
  required String repoRoot,
}) {
  switch (ruleId) {
    case 'repo.colonizethis_map_lib_pipe_split':
      return runCheckColonizethisMapLibPipeSplit(repoRoot);
    case 'repo.tile_map_inline_cardinal_directions':
      return runCheckTileMapInlineCardinalDirections(repoRoot);
    case 'repo.map_gen_no_image_import':
      return runCheckMapGenNoImageImport(repoRoot);
    case 'repo.map_grid_ops_central':
      return runCheckMapGridOpsCentral(repoRoot);
    case 'repo.map_grid_cell_iteration_central':
      return runCheckMapGridCellIterationCentral(repoRoot);
    case 'repo.map_gen_stage_protocol':
      return runCheckMapGenStageProtocol(repoRoot);
    case 'repo.map_gen_no_new_partfiles':
      return runCheckMapGenNoNewPartfiles(repoRoot);
    case 'repo.map_gen_file_size':
      return runCheckMapGenFileSize(repoRoot);
    case 'repo.map_public_barrel_surface':
      return runCheckMapPublicBarrelSurface(repoRoot);
    case 'repo.map_region_data_access_central':
      return runCheckMapRegionDataAccessCentral(repoRoot);
    case 'repo.map_region_dispatch_central':
      return runCheckMapRegionDispatchCentral(repoRoot);
    default:
      return null;
  }
}

void _forwardProcessOutput(
  ProcessResult result, {
  required bool relayStdoutToStderr,
}) {
  final out = result.stdout.toString();
  final err = result.stderr.toString();
  if (out.isNotEmpty) {
    if (relayStdoutToStderr) {
      stderr.write(out);
    } else {
      stdout.write(out);
    }
  }
  if (err.isNotEmpty) {
    stderr.write(err);
  }
}
