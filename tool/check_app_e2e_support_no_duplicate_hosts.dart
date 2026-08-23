import 'dart:io';

import 'package:analyzer/dart/analysis/utilities.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:path/path.dart' as p;

/// AST gate: pin suites under `packages/colonizethis_app_e2e_support/test/*.dart`
/// must not re-declare private wrap/pump hosts (Refs #4598 AC5).
///
/// `test/support/` is exempt — that is the shared host SoT
/// (`e2e_widget_pump_harness.dart`, `e2e_alert_dialog_pump_harness.dart`, …).
const String _pinTestsRelativePath =
    'packages/colonizethis_app_e2e_support/test';

const Set<String> _forbiddenFunctionNames = {
  '_wrap',
  '_pumpScaffold',
  '_pumpDialog',
  '_pumpEmpty',
};

int runCheckAppE2eSupportNoDuplicateHosts(
  String repoRoot, {
  void Function(String line)? info,
  void Function(String line)? err,
}) {
  final logI = info ?? stdout.writeln;
  final logE = err ?? stderr.writeln;
  final pinDir = Directory(p.join(repoRoot, _pinTestsRelativePath));
  if (!pinDir.existsSync()) {
    logE(
      'check_app_e2e_support_no_duplicate_hosts: $_pinTestsRelativePath '
      'not found.',
    );
    return 1;
  }

  final violations = <String>[];
  for (final entity in pinDir.listSync(followLinks: false)) {
    if (entity is! File || !entity.path.endsWith('.dart')) {
      continue;
    }
    final relativePath = p
        .relative(entity.path, from: repoRoot)
        .replaceAll('\\', '/');
    final parsed = parseString(
      content: entity.readAsStringSync(),
      path: relativePath,
    );
    final visitor = _HostCloneVisitor(
      relativePath: relativePath,
      violations: violations,
    );
    parsed.unit.accept(visitor);
  }

  if (violations.isEmpty) {
    logI('check_app_e2e_support_no_duplicate_hosts: no violations found.');
    return 0;
  }
  logE(
    'check_app_e2e_support_no_duplicate_hosts: found ${violations.length} '
    'violation(s). Declare wrap/pump hosts under test/support/ '
    '(Refs #4598):',
  );
  for (final v in violations) {
    logE(' - $v');
  }
  return 1;
}

class _HostCloneVisitor extends RecursiveAstVisitor<void> {
  _HostCloneVisitor({required this.relativePath, required this.violations});

  final String relativePath;
  final List<String> violations;

  @override
  void visitFunctionDeclaration(FunctionDeclaration node) {
    final name = node.name.lexeme;
    if (_forbiddenFunctionNames.contains(name)) {
      violations.add(
        '$relativePath: private host function `$name` — import '
        'test/support/e2e_widget_pump_harness.dart or '
        'e2e_alert_dialog_pump_harness.dart',
      );
    }
    super.visitFunctionDeclaration(node);
  }
}

void main() {
  exit(runCheckAppE2eSupportNoDuplicateHosts(Directory.current.path));
}
