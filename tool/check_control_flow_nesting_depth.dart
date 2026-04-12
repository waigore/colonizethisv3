import 'dart:io';

import 'package:analyzer/dart/analysis/utilities.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/source/line_info.dart';
import 'package:path/path.dart' as p;
import 'package:yaml/yaml.dart';

import 'ct_repo_lint_scan_contract.dart';

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
  final allowlisted = _loadNestingAllowlist(repoRoot);
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
    _collectAndScanExecutableBodies(
      unit,
      relativePath,
      lineInfo,
      warnings,
      errors,
      allowlisted,
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

Set<String> _loadNestingAllowlist(String repoRoot) {
  final f = File(
    p.join(repoRoot, 'tool', 'control_flow_nesting_depth_allowlist.yaml'),
  );
  if (!f.existsSync()) {
    return {};
  }
  final dynamic doc = loadYaml(f.readAsStringSync());
  if (doc is! YamlMap) {
    return {};
  }
  final list = doc['allowed_depth_ge4'];
  if (list is! YamlList) {
    return {};
  }
  final out = <String>{};
  for (final dynamic e in list) {
    if (e is YamlMap) {
      final file = e['file']?.toString();
      final sym = e['symbol']?.toString();
      if (file != null && sym != null) {
        out.add('$file|$sym');
      }
    }
  }
  return out;
}

void _collectAndScanExecutableBodies(
  CompilationUnit unit,
  String relativePath,
  LineInfo lineInfo,
  List<String> warnings,
  List<String> errors,
  Set<String> allowlisted,
) {
  for (final decl in unit.declarations) {
    if (decl is FunctionDeclaration) {
      _scanDeclarationSubtree(
        decl,
        relativePath,
        lineInfo,
        warnings,
        errors,
        allowlisted,
      );
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
              allowlisted,
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
              allowlisted,
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
  Set<String> allowlisted,
) {
  _scanBody(
    decl.name.lexeme,
    decl.functionExpression.body,
    relativePath,
    lineInfo,
    warnings,
    errors,
    allowlisted,
  );
}

void _scanBody(
  String qualifiedName,
  FunctionBody body,
  String relativePath,
  LineInfo lineInfo,
  List<String> warnings,
  List<String> errors,
  Set<String> allowlisted,
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
          allowlisted,
        );
      },
    ),
  );
  if (maxDepth >= 4) {
    if (allowlisted.contains('$relativePath|$qualifiedName')) {
      return;
    }
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

void main() {
  exit(runCheckControlFlowNestingDepth(Directory.current.path));
}
