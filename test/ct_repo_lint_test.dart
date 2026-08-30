import 'dart:io';

import 'package:test/test.dart';
import 'package:yaml/yaml.dart';

import '../tool/ct_repo_lint_lib.dart';

void main() {
  final repoRoot = Directory.current.path;

  group('loadRepoLintManifest', () {
    test('loads rules with stable rule_id and group', () {
      final rules = loadRepoLintManifest(
        repoRoot,
        'tool/ct_repo_lint_manifest.yaml',
      );
      final ids = rules.map((r) => r.ruleId).toList();
      expect(ids, contains('repo.custom_exceptions'));
      expect(ids, contains('repo.disallowed_ast_patterns'));
      expect(ids, contains('repo.debug_console_logic_contract_boundary'));
      expect(ids, contains('repo.debug_console_shared_helpers'));
      expect(ids, contains('repo.debug_console_lib_file_size'));
      expect(ids, contains('repo.debug_console_test_file_size'));
      expect(ids, contains('repo.app_debug_lib_file_size'));
      expect(ids, contains('repo.app_debug_test_file_size'));
      expect(ids, contains('repo.app_event_handler_scope_logic_boundary'));
      expect(ids, contains('repo.control_flow_nesting_depth'));
      expect(ids, contains('repo.repeated_magic_numbers'));
      expect(ids, contains('repo.dart_long_string_switches'));
      expect(ids, contains('repo.workspace_outdated_resolvable'));
      expect(ids, contains('repo.workspace_outdated_latest_direct'));
      expect(ids, contains('repo.function_size'));
      expect(ids, contains('repo.part_unit_size'));
      expect(ids, contains('repo.turn_no_part_directives'));
      expect(ids, contains('repo.map_gen_no_new_partfiles'));
      expect(ids, contains('repo.map_lib_file_size'));
      expect(ids, contains('repo.map_lib_file_size_headroom'));
      expect(ids, contains('repo.data_lib_file_size'));
      expect(ids, contains('repo.data_victory_config_registry_parity'));
      expect(ids, contains('repo.map_test_run_generation_harness'));
      expect(ids, contains('repo.map_test_minimal_game_shared'));
      expect(
        rules.firstWhere((r) => r.ruleId == 'repo.map_lib_file_size').script,
        'tool/check_map_lib_file_size.dart',
      );
      expect(
        rules
            .firstWhere((r) => r.ruleId == 'repo.map_lib_file_size_headroom')
            .script,
        'tool/check_map_lib_file_size_headroom.dart',
      );
      expect(
        rules
            .firstWhere((r) => r.ruleId == 'repo.turn_no_part_directives')
            .spec,
        'SPEC/program/turn-no-part-directives.md',
      );
      expect(ids, contains('repo.diplomacy_no_part_of'));
      expect(
        rules.firstWhere((r) => r.ruleId == 'repo.diplomacy_no_part_of').spec,
        'SPEC/program/diplomacy-no-part-of.md',
      );
      expect(ids, contains('repo.no_flame_in_widgets'));
      expect(ids, contains('repo.game_widgets_file_size'));
      expect(ids, contains('repo.app_core_services_file_size'));
      expect(ids, contains('repo.app_turn_resolution_file_size'));
      expect(ids, contains('repo.app_test_no_duplicate_shortcut_fixtures'));
      expect(
        ids,
        contains('repo.app_test_no_duplicate_shortcut_golden_game_service'),
      );
      expect(ids, contains('repo.logic_test_file_size'));
      expect(ids, contains('repo.logic_domain_import_dag'));
      expect(ids, contains('repo.logic_source_file_size'));
      expect(ids, contains('repo.dart_file_non_comment_line_size'));
      expect(ids, contains('repo.land_province_bucket_keys'));
      expect(ids, contains('repo.logic_dual_region_province_field_access'));
      expect(ids, contains('repo.world_lib_unit_lookup_sot'));
      expect(ids, contains('repo.logic_work_target_switch'));
      expect(ids, contains('repo.app_lib_no_broad_suggest_work_orders'));
      expect(ids, contains('repo.app_lib_player_by_id_lookup'));
      expect(ids, contains('repo.app_lib_unit_lookup_sot'));
      expect(ids, contains('repo.app_province_inline_action_state'));
      expect(ids, contains('repo.app_hardcoded_ui_strings'));
      expect(
        rules
            .firstWhere((r) => r.ruleId == 'repo.tech_id_constants')
            .prIncremental,
        isTrue,
      );
      expect(
        rules
            .firstWhere(
              (r) => r.ruleId == 'repo.dart_file_non_comment_line_size',
            )
            .prIncremental,
        isTrue,
      );
      expect(
        rules
            .firstWhere(
              (r) => r.ruleId == 'repo.dart_file_non_comment_line_size',
            )
            .spec,
        'SPEC/program/dart-file-non-comment-line-size.md',
      );
      expect(
        rules.firstWhere((r) => r.ruleId == 'repo.game_widgets_file_size').spec,
        'SPEC/program/game-widgets-file-size.md',
      );
      expect(
        rules
            .firstWhere((r) => r.ruleId == 'repo.app_core_services_file_size')
            .spec,
        'SPEC/program/app-core-services-file-size.md',
      );
      expect(
        rules
            .firstWhere((r) => r.ruleId == 'repo.app_turn_resolution_file_size')
            .spec,
        'SPEC/program/app-turn-resolution-file-size.md',
      );
      expect(
        rules.firstWhere((r) => r.ruleId == 'repo.logic_test_file_size').spec,
        'SPEC/program/repo-lint.md',
      );
      expect(
        rules
            .firstWhere((r) => r.ruleId == 'repo.logic_test_file_size')
            .prIncremental,
        isTrue,
      );
      expect(
        rules.firstWhere((r) => r.ruleId == 'repo.logic_test_file_size').title,
        isNot(contains('PR-incremental')),
        reason:
            'GitHub #2288 transitioned this rule to full-tree enforcement; '
            'manifest title must no longer advertise PR-incremental only.',
      );
      expect(
        rules
            .firstWhere((r) => r.ruleId == 'repo.app_hardcoded_ui_strings')
            .includeOnlyWhenEnvName,
        'CT_REPO_LINT_INCLUDE_APP',
      );
      final assetRule = rules.firstWhere(
        (r) => r.ruleId == 'repo.asset_path_constants',
      );
      expect(assetRule.runner, 'dart');
      expect(assetRule.script, 'tool/check_asset_path_constants.dart');
    });
  });

  group('manifest file', () {
    test('AI suite-size titles advertise 250 after #4669 Slice E', () {
      final rules = loadRepoLintManifest(
        repoRoot,
        'tool/ct_repo_lint_manifest.yaml',
      );
      const ids = <String>[
        'repo.ai_planning_cases_suite_size',
        'repo.ai_expand_peace_pin_cases_required',
        'repo.ai_residual_fat_pin_cases_required',
      ];
      for (final id in ids) {
        final title = rules.firstWhere((r) => r.ruleId == id).title;
        expect(title, contains('250 physical lines'), reason: id);
        expect(title, isNot(contains('300 physical lines')), reason: id);
        expect(title, contains('#4669 Slice E'), reason: id);
      }
    });

    test('AI s7d suite-size title advertises 250 after #4669 Slice E', () {
      final rules = loadRepoLintManifest(
        repoRoot,
        'tool/ct_repo_lint_manifest.yaml',
      );
      const id = 'repo.ai_s7d_support_suite_size';
      final title = rules.firstWhere((r) => r.ruleId == id).title;
      expect(title, contains('250 physical lines'), reason: id);
      expect(title, isNot(contains('400 physical lines')), reason: id);
      expect(title, contains('#4669 Slice E'), reason: id);
    });

    test('version and rules list are present', () {
      final f = File('$repoRoot/tool/ct_repo_lint_manifest.yaml');
      final doc = loadYaml(f.readAsStringSync()) as YamlMap;
      expect(doc['version'], 1);
      expect(doc['rules'], isA<YamlList>());
      expect((doc['rules'] as YamlList).length, greaterThanOrEqualTo(8));
    });
  });

  test('CLI --list exits 0 and prints rule ids', () {
    final r = Process.runSync(Platform.resolvedExecutable, [
      'run',
      'tool/ct_repo_lint.dart',
      '--list',
    ], workingDirectory: repoRoot);
    expect(r.exitCode, 0, reason: r.stderr.toString());
    final out = r.stdout.toString();
    expect(out, contains('repo.custom_exceptions'));
    expect(out, contains('repo.test_imports'));
  });

  test('CLI rejects --list with --sarif', () {
    final r = Process.runSync(Platform.resolvedExecutable, [
      'run',
      'tool/ct_repo_lint.dart',
      '--list',
      '--sarif=-',
    ], workingDirectory: repoRoot);
    expect(r.exitCode, 2);
    expect(r.stderr.toString(), contains('--sarif'));
  });
}
