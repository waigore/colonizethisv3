import 'dart:io';

import 'package:analyzer/dart/analysis/utilities.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/source/line_info.dart';
import 'package:path/path.dart' as p;

/// Flags [WidgetRef] / [Ref] formal parameters on helpers under the app refactor
/// scope (Refs #3483).
///
/// SPEC: `SPEC/program/app-ui-wiring.md`, `SPEC/program/app-event-bus.md`,
/// `.cursor/rules/colonizethis-core-principles.mdc` § UI coupling.
const _ignoreToken = 'app_widget_ref_parameter_smell';

const _scanPaths = <String>[
  'app/lib/features',
  'app/lib/core/services',
  'app/lib/providers',
  'app/lib/config/ct_e2e_turn_snapshot_refresh.dart',
];

const _providerFactoryNames = <String>{
  'Provider',
  'FutureProvider',
  'StreamProvider',
  'NotifierProvider',
  'AsyncNotifierProvider',
  'StateNotifierProvider',
  'StateProvider',
  'ChangeNotifierProvider',
};

const _allowedLifecycleMethods = <String>{'initState', 'dispose'};

int runCheckAppWidgetRefParameterSmell(
  String repoRoot, {
  void Function(String line)? info,
  void Function(String line)? err,
}) {
  final logI = info ?? stdout.writeln;
  final logE = err ?? stderr.writeln;
  final root = p.normalize(repoRoot);
  final violations = <String>[];

  for (final scanPath in _scanPaths) {
    final absolute = p.join(root, scanPath);
    if (p.extension(scanPath) == '.dart') {
      final file = File(absolute);
      if (!file.existsSync()) {
        continue;
      }
      _scanFile(
        root: root,
        file: file,
        violations: violations,
      );
      continue;
    }
    final dir = Directory(absolute);
    if (!dir.existsSync()) {
      continue;
    }
    for (final entity in dir.listSync(recursive: true, followLinks: false)) {
      if (entity is! File || !entity.path.endsWith('.dart')) {
        continue;
      }
      _scanFile(
        root: root,
        file: entity,
        violations: violations,
      );
    }
  }

  if (violations.isEmpty) {
    logI('check_app_widget_ref_parameter_smell: no violations found.');
    return 0;
  }

  logE(
    'check_app_widget_ref_parameter_smell: found ${violations.length} violation(s):',
  );
  for (final violation in violations) {
    logE(' - $violation');
  }
  return 1;
}

void _scanFile({
  required String root,
  required File file,
  required List<String> violations,
}) {
  final relativePath = p.posix.joinAll(
    p.split(p.relative(file.path, from: root)),
  );
  final content = file.readAsStringSync();
  if (content.contains('ignore_for_file: $_ignoreToken')) {
    return;
  }
  final parsed = parseString(content: content, path: relativePath);
  final visitor = _WidgetRefParameterVisitor(
    relativePath: relativePath,
    lineInfo: parsed.lineInfo,
    sourceLines: content.split('\n'),
  );
  parsed.unit.accept(visitor);
  violations.addAll(visitor.violations);
}

class _WidgetRefParameterVisitor extends RecursiveAstVisitor<void> {
  _WidgetRefParameterVisitor({
    required this.relativePath,
    required this.lineInfo,
    required this.sourceLines,
  });

  final String relativePath;
  final LineInfo lineInfo;
  final List<String> sourceLines;
  final List<String> violations = <String>[];

  @override
  void visitFunctionDeclaration(FunctionDeclaration node) {
    _checkParameters(node.functionExpression.parameters, node);
    super.visitFunctionDeclaration(node);
  }

  @override
  void visitMethodDeclaration(MethodDeclaration node) {
    _checkParameters(node.parameters, node);
    super.visitMethodDeclaration(node);
  }

  void _checkParameters(FormalParameterList? parameters, AstNode owner) {
    if (parameters == null) {
      return;
    }
    for (final param in parameters.parameters) {
      if (!_isWidgetRefOrRefType(param)) {
        continue;
      }
      if (_isIgnored(param)) {
        continue;
      }
      if (_isAllowedContext(param, owner)) {
        continue;
      }
      final location = lineInfo.getLocation(param.offset);
      violations.add(
        '$relativePath:${location.lineNumber}: '
        'WidgetRef/Ref must not appear as a helper parameter '
        '(use narrow notifiers, services, or explicit data instead)',
      );
    }
  }

  bool _isWidgetRefOrRefType(FormalParameter param) {
    final inner = param is DefaultFormalParameter ? param.parameter : param;
    if (inner is! SimpleFormalParameter) {
      return false;
    }
    final type = inner.type;
    if (type == null) {
      return false;
    }
    final name = type.toSource();
    return name == 'WidgetRef' || name == 'Ref';
  }

  bool _isIgnored(FormalParameter node) {
    final location = lineInfo.getLocation(node.offset);
    final lineIndex = location.lineNumber - 1;
    for (final index in <int>[lineIndex, lineIndex - 1]) {
      if (index < 0 || index >= sourceLines.length) {
        continue;
      }
      if (sourceLines[index].contains('ignore: $_ignoreToken')) {
        return true;
      }
    }
    return false;
  }

  bool _isAllowedContext(FormalParameter node, AstNode owner) {
    if (owner is MethodDeclaration) {
      final name = owner.name.lexeme;
      if (name == 'build') {
        return true;
      }
      if (_allowedLifecycleMethods.contains(name)) {
        return true;
      }
    }
    if (node.thisOrAncestorOfType<GenericTypeAlias>() != null ||
        node.thisOrAncestorOfType<FunctionTypeAlias>() != null) {
      return true;
    }
    if (_isProviderFactoryParameter(node)) {
      return true;
    }
    if (relativePath == 'app/lib/widgets/ct_game_feature_screen_shell.dart' &&
        node.thisOrAncestorOfType<GenericTypeAlias>() != null) {
      return true;
    }
    return false;
  }

  bool _isProviderFactoryParameter(FormalParameter node) {
    final functionExpr = node.thisOrAncestorOfType<FunctionExpression>();
    if (functionExpr == null) {
      return false;
    }
    final creation = functionExpr.thisOrAncestorOfType<InstanceCreationExpression>();
    if (creation != null) {
      final typeName = creation.constructorName.type.name2.lexeme;
      if (_providerFactoryNames.contains(typeName)) {
        return true;
      }
    }
    final invocation = functionExpr.thisOrAncestorOfType<MethodInvocation>();
    if (invocation != null) {
      final target = invocation.methodName.name;
      if (_providerFactoryNames.contains(target)) {
        return true;
      }
    }
    return false;
  }
}

void main() {
  exit(runCheckAppWidgetRefParameterSmell(Directory.current.path));
}
