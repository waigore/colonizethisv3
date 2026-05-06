import 'dart:io';

import 'package:analyzer/dart/analysis/utilities.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:path/path.dart' as p;

import 'ct_repo_lint_scan_contract.dart';

const _provinceLevelTargets = <String>{'explore', 'steal_tech', 'counter_spy'};

const _excludedPaths = <String>{'tool/check_canonical_province_tile_keys.dart'};

/// Used by `ct_repo_lint` in-process; [info] / [err] default to stdout/stderr.
int runCheckCanonicalProvinceTileKeys(
  String repoRoot, {
  void Function(String line)? info,
  void Function(String line)? err,
}) {
  final logI = info ?? stdout.writeln;
  final logE = err ?? stderr.writeln;
  final root = p.normalize(repoRoot);
  final files = collectRepoLintCanonicalProvinceTileKeyDartFiles(
    root,
    _excludedPaths,
  );
  final violations = <CanonicalProvinceTileKeyViolation>[];
  for (final file in files) {
    final relPath = p.normalize(p.relative(file.path, from: root));
    final source = file.readAsStringSync();
    violations.addAll(
      findCanonicalProvinceTileKeyViolations(
        relativePath: relPath,
        source: source,
      ),
    );
  }

  if (violations.isEmpty) {
    logI('Canonical province tile-key check passed.');
    return 0;
  }

  logE(
    'ERROR: Found invalid province-level WorkOrder targetTileKey literals. '
    'Use full tile keys (region|province|x|y) for explore/steal_tech/counter_spy.',
  );
  for (final v in violations) {
    logE('${v.path}:${v.line}:${v.column} ${v.message}');
  }
  return 1;
}

void main() {
  exit(runCheckCanonicalProvinceTileKeys(Directory.current.path));
}

List<CanonicalProvinceTileKeyViolation> findCanonicalProvinceTileKeyViolations({
  required String relativePath,
  required String source,
}) {
  final parsed = parseString(
    content: source,
    path: relativePath,
    throwIfDiagnostics: false,
  );
  final visitor = _CanonicalProvinceTileKeyVisitor(
    path: relativePath,
    unit: parsed.unit,
  );
  // Use accept() so the full subtree is walked (visitChildren on the unit alone
  // is insufficient for some call sites).
  parsed.unit.accept(visitor);
  return visitor.violations;
}

class _CanonicalProvinceTileKeyVisitor extends RecursiveAstVisitor<void> {
  _CanonicalProvinceTileKeyVisitor({required this.path, required this.unit});

  final String path;
  final CompilationUnit unit;
  final List<CanonicalProvinceTileKeyViolation> violations =
      <CanonicalProvinceTileKeyViolation>[];

  @override
  void visitInstanceCreationExpression(InstanceCreationExpression node) {
    if (_isWorkOrderConstructor(node)) {
      _checkWorkOrderArguments(node, node.argumentList);
    }
    super.visitInstanceCreationExpression(node);
  }

  @override
  void visitMethodInvocation(MethodInvocation node) {
    // Without resolution, bare `WorkOrder(...)` parses as an unresolved call, not
    // a constructor invocation (e.g. tests and snippets with no import).
    if (node.target == null && node.methodName.name == 'WorkOrder') {
      _checkWorkOrderArguments(node, node.argumentList);
    }
    super.visitMethodInvocation(node);
  }

  bool _isWorkOrderConstructor(InstanceCreationExpression node) {
    final typeName = node.constructorName.type;
    return typeName.name.lexeme == 'WorkOrder';
  }

  void _checkWorkOrderArguments(AstNode anchor, ArgumentList argumentList) {
    String? target;
    String? targetTileKey;
    var hasUnitIdArg = false;
    for (final arg in argumentList.arguments) {
      if (arg is! NamedExpression) continue;
      final name = arg.name.label.name;
      final expr = arg.expression;
      if (name == 'unitId') {
        hasUnitIdArg = true;
      }
      if (name == 'target' && expr is StringLiteral) {
        target = expr.stringValue;
      }
      if (name == 'targetTileKey' && expr is StringLiteral) {
        targetTileKey = expr.stringValue;
      }
    }
    if (!hasUnitIdArg || target == null || targetTileKey == null) {
      return;
    }
    if (!_provinceLevelTargets.contains(target)) {
      return;
    }

    final parts = targetTileKey.split('|');
    final hasValidShape = parts.length == 4;
    if (!hasValidShape) {
      final location = unit.lineInfo.getLocation(anchor.offset);
      violations.add(
        CanonicalProvinceTileKeyViolation(
          path: path,
          line: location.lineNumber,
          column: location.columnNumber,
          message:
              'Invalid targetTileKey "$targetTileKey" for province-level target "$target"; expected region|province|x|y.',
        ),
      );
    }
  }
}

class CanonicalProvinceTileKeyViolation {
  const CanonicalProvinceTileKeyViolation({
    required this.path,
    required this.line,
    required this.column,
    required this.message,
  });

  final String path;
  final int line;
  final int column;
  final String message;
}
