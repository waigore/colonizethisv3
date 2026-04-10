import 'package:analyzer/dart/analysis/utilities.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/source/line_info.dart';

/// Whether [filePath] is runtime domain code covered by exception enforcement.
///
/// [filePath] may be absolute or repo-relative; path separators are normalized.
bool shouldEnforceDomainExceptions(String filePath) {
  final p = filePath.replaceAll(r'\', '/');
  if (!p.contains('/lib/')) {
    return false;
  }
  if (p.contains('/test/') || p.endsWith('_test.dart')) {
    return false;
  }
  if (p.endsWith('.g.dart') ||
      p.endsWith('.freezed.dart') ||
      p.endsWith('.mocks.dart')) {
    return false;
  }
  if (RegExp(r'(^|/)packages/').hasMatch(p)) {
    return true;
  }
  if (p.contains('/app/lib/') || p.startsWith('app/lib/')) {
    return true;
  }
  if (p.contains('/ctdev/lib/') || p.startsWith('ctdev/lib/')) {
    return true;
  }
  if (p.contains('/ctterm/lib/') || p.startsWith('ctterm/lib/')) {
    return true;
  }
  if (RegExp(r'(^|/)tool/').hasMatch(p)) {
    return true;
  }
  return false;
}

/// When non-null, [expression] is a forbidden generic throw operand.
String? forbiddenGenericThrowLabel(Expression expression) {
  if (expression is InstanceCreationExpression) {
    final rawTypeName = expression.constructorName.type.toSource();
    final typeName = rawTypeName.split('<').first;
    if (_forbiddenExceptionTypes.contains(typeName)) {
      return typeName;
    }
    return null;
  }
  if (expression is MethodInvocation) {
    if (_isArgumentErrorValueInvocation(expression)) {
      return 'ArgumentError.value';
    }
    if (expression.target == null &&
        _forbiddenExceptionTypes.contains(expression.methodName.name)) {
      return expression.methodName.name;
    }
  }
  return null;
}

const _forbiddenExceptionTypes = {'ArgumentError', 'Exception'};

/// `ArgumentError.value(...)` parses as a static method invocation, not a
/// constructor [InstanceCreationExpression].
bool _isArgumentErrorValueInvocation(MethodInvocation node) {
  if (node.methodName.name != 'value') {
    return false;
  }
  final target = node.target;
  if (target is SimpleIdentifier && target.name == 'ArgumentError') {
    return true;
  }
  return false;
}

/// One generic-throw violation in a scanned file.
class CustomExceptionViolation {
  const CustomExceptionViolation({
    required this.path,
    required this.line,
    required this.exceptionType,
  });

  final String path;
  final int line;
  final String exceptionType;
}

/// Parses [content] and returns violations for [relativePath] when enforcement
/// applies (same behavior as the repository CI script).
List<CustomExceptionViolation> findCustomExceptionViolations(
  String relativePath,
  String content,
) {
  if (!relativePath.endsWith('.dart')) {
    return const [];
  }
  if (!shouldEnforceDomainExceptions(relativePath)) {
    return const [];
  }

  final parsed = parseString(
    content: content,
    path: relativePath,
    throwIfDiagnostics: false,
  );
  final visitor = _ThrowVisitor(relativePath, parsed.lineInfo);
  parsed.unit.accept(visitor);
  return visitor.violations;
}

class _ThrowVisitor extends RecursiveAstVisitor<void> {
  _ThrowVisitor(this.path, this.lineInfo);

  final String path;
  final LineInfo lineInfo;
  final List<CustomExceptionViolation> violations = [];

  @override
  void visitThrowExpression(ThrowExpression node) {
    final label = forbiddenGenericThrowLabel(node.expression);
    if (label != null) {
      final line = lineInfo.getLocation(node.offset).lineNumber;
      violations.add(
        CustomExceptionViolation(path: path, line: line, exceptionType: label),
      );
    }
    super.visitThrowExpression(node);
  }
}
