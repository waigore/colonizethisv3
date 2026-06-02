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
      expect(ids, contains('repo.app_event_handler_scope_logic_boundary'));
      expect(ids, contains('repo.control_flow_nesting_depth'));
      expect(ids, contains('repo.repeated_magic_numbers'));
      expect(ids, contains('repo.dart_long_string_switches'));
      expect(ids, contains('repo.workspace_outdated_resolvable'));
      expect(ids, contains('repo.workspace_outdated_latest_direct'));
      expect(ids, contains('repo.function_size'));
      expect(ids, contains('repo.part_unit_size'));
      expect(ids, contains('repo.no_flame_in_widgets'));
      expect(ids, contains('repo.game_widgets_file_size'));
      expect(ids, contains('repo.logic_test_file_size'));
      expect(ids, contains('repo.dart_file_non_comment_line_size'));
      expect(ids, contains('repo.land_province_bucket_keys'));
      expect(ids, contains('repo.logic_dual_region_province_field_access'));
      expect(ids, contains('repo.logic_work_target_switch'));
      expect(ids, contains('repo.app_lib_no_broad_suggest_work_orders'));
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
