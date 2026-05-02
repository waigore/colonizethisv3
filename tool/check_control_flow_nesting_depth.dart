import 'dart:io';

import 'package:analyzer/dart/analysis/utilities.dart';
import 'package:path/path.dart' as p;

import 'control_flow_nesting_depth_scan.dart';
import 'ct_repo_lint_scan_contract.dart';

export 'control_flow_nesting_depth_scan.dart';

/// AST-based control-flow nesting depth for domain Dart sources.
///
/// SPEC: SPEC/program/control-flow-nesting-depth.md
///
/// Warn (stderr) when max depth in a function/method is **3**; exit **1** when
/// any function reaches depth **4+**. Guard `if`s whose then-branch only exits
/// the current scope (`return` / `continue` / `break` / `throw`, including
/// short chains without `else`) do **not** increase nesting depth.
int runCheckControlFlowNestingDepth(
  String repoRoot, {
  void Function(String line)? info,
  void Function(String line)? err,
}) {
  final logI = info ?? stdout.writeln;
  final logE = err ?? stderr.writeln;
  final verbose = Platform.environment['CT_NESTING_DEPTH_VERBOSE'] == '1';
  final files = collectRepoLintDomainDartFiles(repoRoot);
  final warnings = <String>[];
  final errors = <String>[];

  for (final file in files) {
    final relativePath = p.relative(file.path, from: repoRoot);
    final content = file.readAsStringSync();
    final parsed = parseString(content: content, path: file.path);
    final unit = parsed.unit;
    final lineInfo = unit.lineInfo;
    collectControlFlowNestingDepthViolationsFromUnit(
      unit,
      relativePath,
      lineInfo,
      warnings,
      errors,
    );
  }

  if (warnings.isNotEmpty) {
    logE(
      'check_control_flow_nesting_depth: ${warnings.length} depth>=3 warning(s) '
      '(set CT_NESTING_DEPTH_VERBOSE=1 for details)',
    );
    if (verbose) {
      for (final w in warnings) {
        logE('check_control_flow_nesting_depth: WARNING $w');
      }
    }
  }
  if (errors.isEmpty) {
    logI('check_control_flow_nesting_depth: no depth>=4 violations.');
    return 0;
  }
  logE(
    'check_control_flow_nesting_depth: ${errors.length} depth>=4 violation(s):',
  );
  for (final e in errors) {
    logE(' - $e');
  }
  return 1;
}

void main() {
  exit(runCheckControlFlowNestingDepth(Directory.current.path));
}
