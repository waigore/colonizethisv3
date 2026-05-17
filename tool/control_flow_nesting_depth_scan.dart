import 'package:analyzer/dart/analysis/utilities.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/source/line_info.dart';

/// Walks [unit] and appends control-flow nesting depth warnings (depth ≥3)
/// and errors (depth ≥4) to [warnings] and [errors].
///
/// SPEC: SPEC/program/control-flow-nesting-depth.md
void collectControlFlowNestingDepthViolationsFromUnit(
  CompilationUnit unit,
  String relativePath,
  LineInfo lineInfo,
  List<String> warnings,
  List<String> errors,
) {
  for (final decl in unit.declarations) {
    if (decl is FunctionDeclaration) {
      _scanDeclarationSubtree(decl, relativePath, lineInfo, warnings, errors);
    } else if (decl is ClassDeclaration) {
      for (final member in decl.members) {
        if (member is MethodDeclaration) {
          final body = member.body;
          if (body is! EmptyFunctionBody) {
            _scanBody(
              '${decl.name.lexeme}.${member.name.lexeme}',
              body,
              relativePath,
              lineInfo,
              warnings,
              errors,
            );
          }
        } else if (member is ConstructorDeclaration) {
          final body = member.body;
          if (body is! EmptyFunctionBody) {
            _scanBody(
              '${decl.name.lexeme}.<ctor>',
              body,
              relativePath,
              lineInfo,
              warnings,
              errors,
            );
          }
        }
      }
    }
  }
}

void _scanDeclarationSubtree(
  FunctionDeclaration decl,
  String relativePath,
  LineInfo lineInfo,
  List<String> warnings,
  List<String> errors,
) {
  _scanBody(
    decl.name.lexeme,
    decl.functionExpression.body,
    relativePath,
    lineInfo,
    warnings,
    errors,
  );
}

void _scanBody(
  String qualifiedName,
  FunctionBody body,
  String relativePath,
  LineInfo lineInfo,
  List<String> warnings,
  List<String> errors,
) {
  final visitor = _ControlFlowNestingVisitor();
  body.accept(visitor);
  final maxDepth = visitor.maxDepth;

  body.accept(
    _NestedExecutableCollector(
      onLocalFunction: (nested) {
        _scanDeclarationSubtree(
          nested,
          relativePath,
          lineInfo,
          warnings,
          errors,
        );
      },
    ),
  );
  if (maxDepth >= 4) {
    final line = lineInfo.getLocation(body.offset).lineNumber;
    errors.add(
      '$relativePath:$line: `$qualifiedName` max control-flow nesting depth is $maxDepth (fail at >=4)',
    );
  } else if (maxDepth >= 3) {
    final line = lineInfo.getLocation(body.offset).lineNumber;
    warnings.add(
      '$relativePath:$line: `$qualifiedName` max control-flow nesting depth is $maxDepth (warn at >=3)',
    );
  }
}

/// Finds [FunctionDeclaration] nodes nested under [decl] (excluding [decl]
/// itself).
final class _NestedExecutableCollector extends RecursiveAstVisitor<void> {
  _NestedExecutableCollector({required this.onLocalFunction});

  final void Function(FunctionDeclaration node) onLocalFunction;

  @override
  void visitFunctionDeclaration(FunctionDeclaration node) {
    onLocalFunction(node);
    super.visitFunctionDeclaration(node);
  }
}

/// Counts `if` / `for` / `while` / `doWhile` / `switch` nesting; skips closure
/// and local function bodies.
final class _ControlFlowNestingVisitor extends RecursiveAstVisitor<void> {
  int _depth = 0;
  int maxDepth = 0;

  void _enter() {
    _depth++;
    if (_depth > maxDepth) {
      maxDepth = _depth;
    }
  }

  void _exit() {
    _depth--;
  }

  @override
  void visitFunctionExpression(FunctionExpression node) {}

  @override
  void visitFunctionDeclaration(FunctionDeclaration node) {}

  bool _isGuardIf(IfStatement node) {
    final then = node.thenStatement;
    final Statement? core;
    if (then is Block) {
      core = then.statements.length == 1 ? then.statements.first : null;
    } else {
      core = then;
    }
    if (core == null) {
      return false;
    }
    if (core is ReturnStatement ||
        core is ContinueStatement ||
        core is BreakStatement ||
        _isThrowLikeStatement(core)) {
      return node.elseStatement == null;
    }
    if (core is IfStatement && node.elseStatement == null) {
      return _isGuardIf(core);
    }
    return false;
  }

  bool _isThrowLikeStatement(Statement s) {
    return s is ExpressionStatement && s.expression is ThrowExpression;
  }

  @override
  void visitIfStatement(IfStatement node) {
    node.expression.accept(this);
    if (_isGuardIf(node)) {
      node.thenStatement.accept(this);
      node.elseStatement?.accept(this);
      return;
    }
    _enter();
    node.thenStatement.accept(this);
    _exit();
    if (node.elseStatement != null) {
      _enter();
      node.elseStatement!.accept(this);
      _exit();
    }
  }

  @override
  void visitForStatement(ForStatement node) {
    node.forLoopParts.accept(this);
    _enter();
    node.body.accept(this);
    _exit();
  }

  @override
  void visitForElement(ForElement node) {
    node.forLoopParts.accept(this);
    _enter();
    node.body.accept(this);
    _exit();
  }

  @override
  void visitWhileStatement(WhileStatement node) {
    node.condition.accept(this);
    _enter();
    node.body.accept(this);
    _exit();
  }

  @override
  void visitDoStatement(DoStatement node) {
    _enter();
    node.body.accept(this);
    _exit();
    node.condition.accept(this);
  }

  @override
  void visitSwitchStatement(SwitchStatement node) {
    node.expression.accept(this);
    _enter();
    for (final m in node.members) {
      m.accept(this);
    }
    _exit();
  }
}

/// Synthetic `void __t() { ... }` wrapper — for unit tests only.
int maxControlFlowNestingDepthForTestBody(String bracedBodySource) {
  final parsed = parseString(content: 'void __t() $bracedBodySource');
  final unit = parsed.unit;
  final decl = unit.declarations.whereType<FunctionDeclaration>().first;
  final visitor = _ControlFlowNestingVisitor();
  decl.functionExpression.body.accept(visitor);
  return visitor.maxDepth;
}
