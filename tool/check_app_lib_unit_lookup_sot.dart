import 'dart:io';

import 'package:analyzer/dart/analysis/utilities.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/source/line_info.dart';
import 'package:path/path.dart' as p;

/// SPEC: SPEC/program/repo-lint.md (Refs #4534).
///
/// Forbid dual-region unit-list concatenation and dual-region unit-id walks
/// under `app/lib/**`. Use `WorldState.tryGetUnitById` / `allUnitsById`.
/// Single-region arguments to named functions (civilian panel) are allowed.
const _appLibPrefix = 'app/lib/';

class AppLibUnitLookupSotViolation {
  const AppLibUnitLookupSotViolation({
    required this.path,
    required this.line,
    required this.reason,
  });

  final String path;
  final int line;
  final String reason;
}

bool appLibUnitLookupSotPathInScope(String slashPath) {
  final normalized = slashPath.replaceAll('\\', '/');
  return normalized.startsWith(_appLibPrefix) && normalized.endsWith('.dart');
}

List<AppLibUnitLookupSotViolation> findAppLibUnitLookupSotViolations({
  required String relativePath,
  required String source,
}) {
  final parsed = parseString(
    content: source,
    path: relativePath,
    throwIfDiagnostics: false,
  );
  final out = <AppLibUnitLookupSotViolation>[];
  parsed.unit.accept(
    _UnitLookupSotVisitor(
      relativePath: relativePath,
      lineInfo: parsed.unit.lineInfo,
      out: out,
    ),
  );
  return out;
}

class _UnitLookupSotVisitor extends RecursiveAstVisitor<void> {
  _UnitLookupSotVisitor({
    required this.relativePath,
    required this.lineInfo,
    required this.out,
  });

  final String relativePath;
  final LineInfo lineInfo;
  final List<AppLibUnitLookupSotViolation> out;

  @override
  void visitListLiteral(ListLiteral node) {
    _flagIfBothRegions(node.elements, node.offset);
    super.visitListLiteral(node);
  }

  @override
  void visitSetOrMapLiteral(SetOrMapLiteral node) {
    _flagIfBothRegions(node.elements, node.offset);
    super.visitSetOrMapLiteral(node);
  }

  @override
  void visitBlockFunctionBody(BlockFunctionBody node) {
    _flagDualForIdWalks(node.block.statements, node.offset);
    super.visitBlockFunctionBody(node);
  }

  void _flagIfBothRegions(NodeList<CollectionElement> elements, int offset) {
    final regions = <String>{};
    for (final el in elements) {
      if (el is SpreadElement) {
        final region = regionOfUnitsExpression(el.expression);
        if (region != null) {
          regions.add(region);
        }
      }
      if (el is ForElement) {
        final iterable = _forElementIterable(el);
        final region = regionOfUnitsExpression(iterable);
        if (region != null) {
          regions.add(region);
        }
      }
    }
    if (regions.contains('oldWorld') && regions.contains('newWorld')) {
      out.add(
        AppLibUnitLookupSotViolation(
          path: relativePath,
          line: _lineOf(offset),
          reason: 'concatenates oldWorld.units and newWorld.units',
        ),
      );
    }
  }

  void _flagDualForIdWalks(NodeList<Statement> statements, int offset) {
    final regions = <String>{};
    for (final stmt in statements) {
      if (stmt is ForStatement) {
        final parts = stmt.forLoopParts;
        if (parts is ForEachPartsWithDeclaration) {
          final region = regionOfUnitsExpression(parts.iterable);
          if (region == null) {
            continue;
          }
          final loopVar = parts.loopVariable.name.lexeme;
          if (_nodeLooksUpId(stmt.body, loopVar)) {
            regions.add(region);
          }
        }
      }
    }
    if (regions.contains('oldWorld') && regions.contains('newWorld')) {
      out.add(
        AppLibUnitLookupSotViolation(
          path: relativePath,
          line: _lineOf(offset),
          reason: 'walks both region unit lists for unit.id',
        ),
      );
    }
  }

  int _lineOf(int offset) => lineInfo.getLocation(offset).lineNumber;
}

Expression? _forElementIterable(ForElement el) {
  final parts = el.forLoopParts;
  if (parts is ForEachPartsWithDeclaration) {
    return parts.iterable;
  }
  return null;
}

String? regionOfUnitsExpression(Expression? expr) {
  if (expr is PropertyAccess && expr.propertyName.name == 'units') {
    final target = expr.target;
    if (target is PropertyAccess) {
      final name = target.propertyName.name;
      if (name == 'oldWorld' || name == 'newWorld') {
        return name;
      }
    }
    if (target is PrefixedIdentifier) {
      final name = target.identifier.name;
      if (name == 'oldWorld' || name == 'newWorld') {
        return name;
      }
    }
  }
  return null;
}

bool _nodeLooksUpId(AstNode node, String loopVar) {
  var found = false;
  node.accept(
    _UnitIdEqualityVisitor(loopVar: loopVar, onMatch: () => found = true),
  );
  return found;
}

class _UnitIdEqualityVisitor extends RecursiveAstVisitor<void> {
  _UnitIdEqualityVisitor({required this.loopVar, required this.onMatch});

  final String loopVar;
  final void Function() onMatch;

  @override
  void visitBinaryExpression(BinaryExpression node) {
    if (node.operator.lexeme == '==' || node.operator.lexeme == '!=') {
      if (_isIdAccess(node.leftOperand) || _isIdAccess(node.rightOperand)) {
        onMatch();
      }
    }
    super.visitBinaryExpression(node);
  }

  bool _isIdAccess(Expression expr) {
    if (expr is PropertyAccess) {
      return expr.propertyName.name == 'id' &&
          expr.target is SimpleIdentifier &&
          (expr.target as SimpleIdentifier).name == loopVar;
    }
    if (expr is PrefixedIdentifier) {
      return expr.identifier.name == 'id' && expr.prefix.name == loopVar;
    }
    return false;
  }
}

int runCheckAppLibUnitLookupSot(
  String repoRoot, {
  void Function(String line)? info,
  void Function(String line)? err,
}) {
  final logI = info ?? stdout.writeln;
  final logE = err ?? stderr.writeln;
  final violations = <AppLibUnitLookupSotViolation>[];
  final appLibDir = Directory(p.join(repoRoot, 'app', 'lib'));
  if (!appLibDir.existsSync()) {
    logE('check_app_lib_unit_lookup_sot: app/lib not found');
    return 1;
  }

  for (final entity in appLibDir.listSync(recursive: true)) {
    if (entity is! File || !entity.path.endsWith('.dart')) {
      continue;
    }
    final rel = p.relative(entity.path, from: repoRoot).replaceAll('\\', '/');
    if (!appLibUnitLookupSotPathInScope(rel)) {
      continue;
    }
    violations.addAll(
      findAppLibUnitLookupSotViolations(
        relativePath: rel,
        source: entity.readAsStringSync(),
      ),
    );
  }

  if (violations.isEmpty) {
    logI(
      'check_app_lib_unit_lookup_sot: no dual-region unit concatenations or '
      'id walks.',
    );
    return 0;
  }

  logE('check_app_lib_unit_lookup_sot: ${violations.length} violation(s):');
  for (final v in violations) {
    logE(
      ' - ${v.path}:${v.line} ${v.reason}; use WorldState.tryGetUnitById / '
      'allUnitsById (Refs #4534).',
    );
  }
  return 1;
}

void main() {
  exit(runCheckAppLibUnitLookupSot(Directory.current.path));
}
