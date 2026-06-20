// Enforces the SPEC/program/orders.md § Work-order handler registry contract:
// work-target dispatch in `lib/src/orders/work_handlers/` and
// `lib/src/orders/order_visibility.dart` must go through a registry map lookup
// (`workOrderHandlersByTarget`, `_workOrderVisibilityByTarget`) instead of
// switching across the enumerated `kWorkTarget*` constants. Any switch
// statement or switch expression in the scoped paths whose cases enumerate
// [_minWorkTargetCases] or more `kWorkTarget*` constants is rejected so the
// canonical registry shape does not silently regress (Refs #2560).
import 'dart:io';

import 'package:analyzer/dart/analysis/utilities.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/source/line_info.dart';
import 'package:path/path.dart' as p;

/// Threshold: a switch on the enumerated work-target constants only earns a
/// registry lookup when it dispatches 3 or more distinct targets. Single- or
/// two-case branching (e.g. a hot-path special case) stays acceptable because
/// it does not represent an enumeration.
const int _minWorkTargetCases = 3;

/// Identifier prefix for the canonical work-target constants in
/// `packages/colonizethis_logic/lib/src/constants.dart` (`kWorkTargetExplore`,
/// `kWorkTargetBuildImprovement`, etc.).
const String _workTargetConstantPrefix = 'kWorkTarget';

int runCheckLogicWorkTargetSwitch(
  String repoRoot, {
  void Function(String line)? info,
  void Function(String line)? err,
}) {
  final logI = info ?? stdout.writeln;
  final logE = err ?? stderr.writeln;

  final scanFiles = _collectScanFiles(repoRoot);
  if (scanFiles == null) {
    logE(
      'check_logic_work_target_switch: scoped paths not found '
      '(expected `packages/colonizethis_orders/lib/src/orders/work_handlers/` '
      'and `packages/colonizethis_orders/lib/src/orders/order_visibility.dart`).',
    );
    return 1;
  }

  final violations = <String>[];
  for (final file in scanFiles) {
    final source = file.readAsStringSync();
    final relativePath = p.relative(file.path, from: repoRoot);
    violations.addAll(scanWorkTargetSwitchViolations(relativePath, source));
  }

  if (violations.isEmpty) {
    logI('check_logic_work_target_switch: no violations found.');
    return 0;
  }

  logE(
    'check_logic_work_target_switch: found ${violations.length} violation(s):',
  );
  for (final violation in violations) {
    logE(' - $violation');
  }
  return 1;
}

/// Scans [source] for switch statements/expressions whose cases enumerate
/// [_minWorkTargetCases] or more `kWorkTarget*` constants. Returns one message
/// per violating switch with `path:line` and a registry-lookup hint.
List<String> scanWorkTargetSwitchViolations(
  String relativePath,
  String source,
) {
  final parsed = parseString(
    content: source,
    path: relativePath,
    throwIfDiagnostics: false,
  );
  if (parsed.errors.isNotEmpty) {
    return <String>[
      '$relativePath — skipping AST switch scan '
      '(${parsed.errors.length} parse errors)',
    ];
  }
  final violations = <String>[];
  parsed.unit.accept(
    _WorkTargetSwitchVisitor(relativePath, parsed.lineInfo, violations),
  );
  return violations;
}

List<File>? _collectScanFiles(String repoRoot) {
  final orderHandlersDir = Directory(
    p.join(
      repoRoot,
      'packages',
      'colonizethis_orders',
      'lib',
      'src',
      'orders',
      'work_handlers',
    ),
  );
  final orderVisibilityFile = File(
    p.join(
      repoRoot,
      'packages',
      'colonizethis_orders',
      'lib',
      'src',
      'orders',
      'order_visibility.dart',
    ),
  );
  if (!orderHandlersDir.existsSync() || !orderVisibilityFile.existsSync()) {
    return null;
  }
  final files = <File>[
    for (final entity in orderHandlersDir.listSync(recursive: false))
      if (entity is File && entity.path.endsWith('.dart')) entity,
    orderVisibilityFile,
  ];
  files.sort((a, b) => a.path.compareTo(b.path));
  return files;
}

class _WorkTargetSwitchVisitor extends RecursiveAstVisitor<void> {
  _WorkTargetSwitchVisitor(this.filePath, this.lineInfo, this.violations);

  final String filePath;
  final LineInfo lineInfo;
  final List<String> violations;

  @override
  void visitSwitchStatement(SwitchStatement node) {
    final cases = _collectWorkTargetCaseConstants(node.members);
    _report(cases, node.switchKeyword.offset);
    super.visitSwitchStatement(node);
  }

  @override
  void visitSwitchExpression(SwitchExpression node) {
    final cases = _collectWorkTargetExpressionCaseConstants(node.cases);
    _report(cases, node.switchKeyword.offset);
    super.visitSwitchExpression(node);
  }

  void _report(Set<String> cases, int offset) {
    if (cases.length < _minWorkTargetCases) return;
    final line = lineInfo.getLocation(offset).lineNumber;
    final sorted = cases.toList()..sort();
    violations.add(
      '$filePath:$line — switch enumerates ${cases.length} work-target '
      "constants (${sorted.join(', ')}); use a registry lookup "
      '(`workOrderHandlersByTarget` for `orders/work_handlers/`, '
      '`_workOrderVisibilityByTarget` for `order_visibility.dart`) instead '
      '(SPEC/program/orders.md § Work-order handler registry).',
    );
  }
}

Set<String> _collectWorkTargetCaseConstants(List<SwitchMember> members) {
  final found = <String>{};
  for (final member in members) {
    if (member is! SwitchPatternCase) continue;
    final name = _workTargetIdentifierName(member.guardedPattern.pattern);
    if (name != null) found.add(name);
  }
  return found;
}

Set<String> _collectWorkTargetExpressionCaseConstants(
  List<SwitchExpressionCase> cases,
) {
  final found = <String>{};
  for (final c in cases) {
    final name = _workTargetIdentifierName(c.guardedPattern.pattern);
    if (name != null) found.add(name);
  }
  return found;
}

String? _workTargetIdentifierName(AstNode? pattern) {
  if (pattern is! ConstantPattern) return null;
  final expr = pattern.expression;
  if (expr is SimpleIdentifier && expr.name.startsWith(_workTargetConstantPrefix)) {
    return expr.name;
  }
  if (expr is PrefixedIdentifier &&
      expr.identifier.name.startsWith(_workTargetConstantPrefix)) {
    return expr.identifier.name;
  }
  return null;
}

void main() {
  exit(runCheckLogicWorkTargetSwitch(Directory.current.path));
}
