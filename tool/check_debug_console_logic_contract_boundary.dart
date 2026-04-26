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
  List<String>? incrementalRelativeDartPaths;
  for (var i = 0; i < args.length; i++) {
    final arg = args[i];
    if (arg.startsWith('--files=')) {
      incrementalRelativeDartPaths = repoLintSplitRelativeDartPathsArg(
        arg.substring('--files='.length),
      );
      continue;
    }
    if (arg == '--files') {
      if (i + 1 >= args.length) {
        stderr.writeln(
          'check_debug_console_logic_contract_boundary: --files requires a comma-separated list',
        );
        exit(2);
      }
      incrementalRelativeDartPaths = repoLintSplitRelativeDartPathsArg(
        args[++i],
      );
      continue;
    }
  }

  exit(
    runCheckDebugConsoleLogicContractBoundary(
      Directory.current.path,
      incrementalRelativeDartPaths: incrementalRelativeDartPaths,
    ),
  );
}
