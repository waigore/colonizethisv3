import 'dart:io';

import 'check_disallowed_ast_patterns.dart';
import 'ct_repo_lint_scan_contract.dart';

const _ruleId = 'debug_console_logic_contract_boundary';

int runCheckDebugConsoleLogicContractBoundary(
  String repoRoot, {
  List<String>? incrementalRelativeDartPaths,
}) {
  return runCheckDisallowedAstPatterns(
    repoRoot,
    incrementalRelativeDartPaths: incrementalRelativeDartPaths,
    enabledRuleIds: {_ruleId},
  );
}

void main(List<String> args) {
  final parsed = repoLintParseIncrementalRelativeDartPathsFromArgs(args);
  if (parsed.missingValueError) {
    stderr.writeln(
      'check_debug_console_logic_contract_boundary: --files requires a comma-separated list',
    );
    exit(2);
  }

  exit(
    runCheckDebugConsoleLogicContractBoundary(
      Directory.current.path,
      incrementalRelativeDartPaths: parsed.paths,
    ),
  );
}
