// In-process dispatch for `repo.world_*` manifest rules.
// Extracted from `ct_repo_lint_lib.dart` so that library stays under the
// `repo.dart_file_non_comment_line_size` 1000-NCL ceiling (Refs #4515).

import 'check_world_lib_unit_lookup_sot.dart';
import 'check_world_no_circular_imports.dart';
import 'check_world_no_duplicate_extension_helper.dart';
import 'check_world_no_logic_deps.dart';
import 'check_world_test_no_upstream_domain_deps.dart';

/// Dispatch helper for `colonizethis_world` package manifest rules. Keeps the
/// main `_tryRunDartRuleInProcess` switch under the
/// `repo.dart_long_string_switches` 49-case ceiling as new world-scoped rules
/// are added (Refs #4515). Returns `null` for non-world rule ids so the caller
/// falls back to the generic dispatch.
int? tryRunWorldRuleInProcess({
  required String ruleId,
  required String repoRoot,
}) {
  switch (ruleId) {
    case 'repo.world_no_logic_deps':
      return runCheckWorldNoLogicDeps(repoRoot);
    case 'repo.world_test_no_upstream_domain_deps':
      return runCheckWorldTestNoUpstreamDomainDeps(repoRoot);
    case 'repo.world_no_circular_imports':
      return runCheckWorldNoCircularImports(repoRoot);
    case 'repo.world_no_duplicate_extension_helper':
      return runCheckWorldNoDuplicateExtensionHelper(repoRoot);
    case 'repo.world_lib_unit_lookup_sot':
      return runCheckWorldLibUnitLookupSot(repoRoot);
    default:
      return null;
  }
}
