import 'dart:io';

import 'package:analyzer/dart/analysis/utilities.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:path/path.dart' as p;

const _packageLib = 'packages/colonizethis_debug_console/lib/src';

int runCheckDebugConsoleSharedHelpers(
  String repoRoot, {
  void Function(String line)? info,
  void Function(String line)? err,
}) {
  final logI = info ?? stdout.writeln;
  final logE = err ?? stderr.writeln;
  final violations = <String>[];

  final parserPath = p.join(
    repoRoot,
    _packageLib,
    'debug_console_command_parser.dart',
  );
  final executorPath = p.join(
    repoRoot,
    _packageLib,
    'debug_console_command_executor.dart',
  );
  final parserHelpersPath = p.join(
    repoRoot,
    _packageLib,
    'debug_console_parser_helpers.dart',
  );
  final executorHelpersPath = p.join(
    repoRoot,
    _packageLib,
    'debug_console_executor_helpers.dart',
  );

  for (final path in [
    parserPath,
    executorPath,
    parserHelpersPath,
    executorHelpersPath,
  ]) {
    if (!File(path).existsSync()) {
      logE('check_debug_console_shared_helpers: missing $path');
      return 1;
    }
  }

  final parserUnit = _parseUnit(parserPath, repoRoot);
  final executorUnit = _parseUnit(executorPath, repoRoot);
  final parserHelpersUnit = _parseUnit(parserHelpersPath, repoRoot);

  if (!_definesTopLevelFunction(parserHelpersUnit, 'parseOptionalCount')) {
    violations.add(
      '${p.relative(parserHelpersPath, from: repoRoot)} must define parseOptionalCount',
    );
  }
  if (!_definesTopLevelFunction(parserHelpersUnit, 'parseAmountWithClamp')) {
    violations.add(
      '${p.relative(parserHelpersPath, from: repoRoot)} must define parseAmountWithClamp',
    );
  }
  if (!_definesTopLevelFunction(parserHelpersUnit, 'canonicalIdForInput')) {
    violations.add(
      '${p.relative(parserHelpersPath, from: repoRoot)} must define canonicalIdForInput',
    );
  }

  for (final methodName in [
    '_parseSpawnCivilian',
    '_parseSpawnRegiment',
    '_parseSpawnShip',
  ]) {
    if (!_methodInvokesFunction(
      parserUnit,
      methodName: methodName,
      invokedName: 'parseOptionalCount',
    )) {
      violations.add(
        'debug_console_command_parser.dart:$methodName must call parseOptionalCount',
      );
    }
  }

  for (final methodName in [
    '_parseAddMoney',
    '_parseAddWorker',
    '_parseAddResource',
  ]) {
    if (!_methodInvokesFunction(
      parserUnit,
      methodName: methodName,
      invokedName: 'parseAmountWithClamp',
    )) {
      violations.add(
        'debug_console_command_parser.dart:$methodName must call parseAmountWithClamp',
      );
    }
  }

  for (final legacyName in [
    '_treasuryCreditExecutorMessage',
    '_workerPoolCreditExecutorMessage',
    '_stockpileCreditExecutorMessage',
  ]) {
    if (_definesTopLevelFunction(executorUnit, legacyName) ||
        _classDefinesMethod(executorUnit, 'DebugConsoleCommandExecutor', legacyName)) {
      violations.add(
        'debug_console_command_executor.dart must not define $legacyName; '
        'use creditExecutorMessage in debug_console_executor_helpers.dart',
      );
    }
  }

  if (!_methodInvokesFunction(
    executorUnit,
    methodName: '_executeInvocation',
    invokedName: 'dispatchDebugConsoleSessionEvents',
  )) {
    violations.add(
      'debug_console_command_executor.dart:_executeInvocation must call '
      'dispatchDebugConsoleSessionEvents',
    );
  }

  if (violations.isEmpty) {
    logI('check_debug_console_shared_helpers: no violations found.');
    return 0;
  }
  logE('check_debug_console_shared_helpers: ${violations.length} violation(s):');
  for (final violation in violations) {
    logE(' - $violation');
  }
  return 1;
}

CompilationUnit _parseUnit(String absolutePath, String repoRoot) {
  return parseString(
    content: File(absolutePath).readAsStringSync(),
    path: p.relative(absolutePath, from: repoRoot),
  ).unit;
}

bool _definesTopLevelFunction(CompilationUnit unit, String name) {
  return unit.declarations
      .whereType<FunctionDeclaration>()
      .any((decl) => decl.name.lexeme == name);
}

bool _classDefinesMethod(
  CompilationUnit unit,
  String className,
  String methodName,
) {
  return unit.declarations
      .whereType<ClassDeclaration>()
      .where((decl) => decl.name.lexeme == className)
      .any(
        (decl) => decl.members
            .whereType<MethodDeclaration>()
            .any((member) => member.name.lexeme == methodName),
      );
}

bool _methodInvokesFunction(
  CompilationUnit unit, {
  required String methodName,
  required String invokedName,
}) {
  final method = _findMethod(unit, methodName);
  if (method == null) {
    return false;
  }
  var found = false;
  method.body?.visitChildren(_InvocationCollector(invokedName, (value) {
    found = value;
  }));
  return found;
}

MethodDeclaration? _findMethod(CompilationUnit unit, String methodName) {
  for (final decl in unit.declarations.whereType<ClassDeclaration>()) {
    for (final member in decl.members.whereType<MethodDeclaration>()) {
      if (member.name.lexeme == methodName) {
        return member;
      }
    }
  }
  return null;
}

class _InvocationCollector extends RecursiveAstVisitor<void> {
  _InvocationCollector(this.invokedName, this.onFound);

  final String invokedName;
  final void Function(bool found) onFound;
  var _found = false;

  @override
  void visitMethodInvocation(MethodInvocation node) {
    final name = node.methodName.name;
    if (name == invokedName) {
      _found = true;
      onFound(true);
    }
    super.visitMethodInvocation(node);
  }

  @override
  void visitFunctionExpressionInvocation(FunctionExpressionInvocation node) {
    super.visitFunctionExpressionInvocation(node);
  }
}

void main() {
  exit(runCheckDebugConsoleSharedHelpers(Directory.current.path));
}
