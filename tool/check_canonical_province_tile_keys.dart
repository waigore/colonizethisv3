import 'dart:io';

import 'package:analyzer/dart/analysis/utilities.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:path/path.dart' as p;

import 'ct_repo_lint_scan_contract.dart';

const _provinceLevelTargets = <String>{'explore', 'steal_tech', 'counter_spy'};

const _excludedPaths = <String>{'tool/check_canonical_province_tile_keys.dart'};

void main() {
  final root = p.normalize(Directory.current.path);
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
    stdout.writeln('Canonical province tile-key check passed.');
    exit(0);
  }

  stderr.writeln(
    'ERROR: Found non-canonical province-level WorkOrder targetTileKey values. '
    'Use region|province|0|0 for explore/steal_tech/counter_spy.',
  );
  for (final v in violations) {
    stderr.writeln('${v.path}:${v.line}:${v.column} ${v.message}');
  }
  exit(1);
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
    final isCanonical = parts.length == 4 && parts[2] == '0' && parts[3] == '0';
    if (!isCanonical) {
      final location = unit.lineInfo.getLocation(anchor.offset);
      violations.add(
        CanonicalProvinceTileKeyViolation(
          path: path,
          line: location.lineNumber,
          column: location.columnNumber,
          message:
              'Non-canonical targetTileKey "$targetTileKey" for province-level target "$target".',
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
