import 'dart:io';

import 'package:analyzer/dart/analysis/utilities.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:path/path.dart' as p;

/// SPEC: SPEC/program/repo-lint.md (Refs #4534).
///
/// Forbid linear `game.players` id lookups under `app/lib/**`. Use
/// `Game.playerById`. Capital-predicate walks and full-list map/list
/// transforms are allowed.
const _appLibPrefix = 'app/lib/';

class AppLibPlayerByIdViolation {
  const AppLibPlayerByIdViolation({required this.path, required this.line});

  final String path;
  final int line;
}

bool appLibPlayerByIdLookupPathInScope(String slashPath) {
  final normalized = slashPath.replaceAll('\\', '/');
  return normalized.startsWith(_appLibPrefix) && normalized.endsWith('.dart');
}

List<AppLibPlayerByIdViolation> findAppLibPlayerByIdLookupViolations({
  required String relativePath,
  required String source,
}) {
  final parsed = parseString(
    content: source,
    path: relativePath,
    throwIfDiagnostics: false,
  );
  final out = <AppLibPlayerByIdViolation>[];
  parsed.unit.accept(
    _PlayerByIdLookupVisitor(relativePath: relativePath, out: out),
  );
  return out;
}

class _PlayerByIdLookupVisitor extends RecursiveAstVisitor<void> {
  _PlayerByIdLookupVisitor({required this.relativePath, required this.out});

  final String relativePath;
  final List<AppLibPlayerByIdViolation> out;

  @override
  void visitMethodInvocation(MethodInvocation node) {
    final name = node.methodName.name;
    if ((name == 'where' || name == 'firstWhere') &&
        _isPlayersIterable(node.target) &&
        _functionLooksUpId(node.argumentList)) {
      out.add(
        AppLibPlayerByIdViolation(path: relativePath, line: node.offsetLine),
      );
    }
    super.visitMethodInvocation(node);
  }

  @override
  void visitForStatement(ForStatement node) {
    final parts = node.forLoopParts;
    if (parts is ForEachPartsWithDeclaration &&
        _isPlayersIterable(parts.iterable)) {
      final loopVar = parts.loopVariable.name.lexeme;
      if (_nodeLooksUpId(node.body, loopVar)) {
        out.add(
          AppLibPlayerByIdViolation(path: relativePath, line: node.offsetLine),
        );
      }
    }
    super.visitForStatement(node);
  }
}

extension on AstNode {
  int get offsetLine {
    final info = root is CompilationUnit
        ? (root as CompilationUnit).lineInfo
        : null;
    if (info == null) {
      return 1;
    }
    return info.getLocation(offset).lineNumber;
  }
}

bool _isPlayersIterable(Expression? expr) {
  if (expr == null) {
    return false;
  }
  if (expr is PropertyAccess) {
    return expr.propertyName.name == 'players';
  }
  if (expr is PrefixedIdentifier) {
    return expr.identifier.name == 'players';
  }
  return false;
}

bool _functionLooksUpId(ArgumentList args) {
  if (args.arguments.isEmpty) {
    return false;
  }
  final first = args.arguments.first;
  if (first is FunctionExpression) {
    final params = first.parameters?.parameters;
    if (params == null || params.isEmpty) {
      return false;
    }
    final nameNode = params.first.name;
    final name = nameNode?.lexeme;
    if (name == null || name.isEmpty) {
      return false;
    }
    return _expressionHasIdEquality(first.body, name);
  }
  return false;
}

bool _expressionHasIdEquality(AstNode node, String loopVar) {
  var found = false;
  node.accept(_IdBinaryVisitor(loopVar: loopVar, onMatch: () => found = true));
  return found;
}

bool _nodeLooksUpId(AstNode node, String loopVar) {
  var found = false;
  node.accept(
    _IdEqualityVisitor(loopVar: loopVar, onMatch: () => found = true),
  );
  return found;
}

class _IdEqualityVisitor extends RecursiveAstVisitor<void> {
  _IdEqualityVisitor({required this.loopVar, required this.onMatch});

  final String loopVar;
  final void Function() onMatch;

  @override
  void visitIfStatement(IfStatement node) {
    if (_conditionHasIdEquality(node.expression) &&
        !_isContinueOnly(node.thenStatement)) {
      onMatch();
    }
    super.visitIfStatement(node);
  }

  bool _conditionHasIdEquality(Expression expr) {
    var found = false;
    expr.accept(
      _IdBinaryVisitor(loopVar: loopVar, onMatch: () => found = true),
    );
    return found;
  }

  bool _isContinueOnly(Statement stmt) {
    if (stmt is ContinueStatement) {
      return true;
    }
    if (stmt is Block &&
        stmt.statements.length == 1 &&
        stmt.statements.first is ContinueStatement) {
      return true;
    }
    return false;
  }
}

class _IdBinaryVisitor extends RecursiveAstVisitor<void> {
  _IdBinaryVisitor({required this.loopVar, required this.onMatch});

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
      return expr.propertyName.name == 'id' && _isLoopVar(expr.target);
    }
    if (expr is PrefixedIdentifier) {
      return expr.identifier.name == 'id' && expr.prefix.name == loopVar;
    }
    return false;
  }

  bool _isLoopVar(Expression? target) {
    return target is SimpleIdentifier && target.name == loopVar;
  }
}

int runCheckAppLibPlayerByIdLookup(
  String repoRoot, {
  void Function(String line)? info,
  void Function(String line)? err,
}) {
  final logI = info ?? stdout.writeln;
  final logE = err ?? stderr.writeln;
  final violations = <AppLibPlayerByIdViolation>[];
  final appLibDir = Directory(p.join(repoRoot, 'app', 'lib'));
  if (!appLibDir.existsSync()) {
    logE('check_app_lib_player_by_id_lookup: app/lib not found');
    return 1;
  }

  for (final entity in appLibDir.listSync(recursive: true)) {
    if (entity is! File || !entity.path.endsWith('.dart')) {
      continue;
    }
    final rel = p.relative(entity.path, from: repoRoot).replaceAll('\\', '/');
    if (!appLibPlayerByIdLookupPathInScope(rel)) {
      continue;
    }
    violations.addAll(
      findAppLibPlayerByIdLookupViolations(
        relativePath: rel,
        source: entity.readAsStringSync(),
      ),
    );
  }

  if (violations.isEmpty) {
    logI(
      'check_app_lib_player_by_id_lookup: no linear game.players id lookups.',
    );
    return 0;
  }

  logE('check_app_lib_player_by_id_lookup: ${violations.length} violation(s):');
  for (final v in violations) {
    logE(
      ' - ${v.path}:${v.line} use game.playerById(id) instead of a linear '
      'players id lookup (Refs #4534).',
    );
  }
  return 1;
}

void main() {
  exit(runCheckAppLibPlayerByIdLookup(Directory.current.path));
}
