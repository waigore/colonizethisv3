import 'dart:io';

import 'package:analyzer/dart/analysis/utilities.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/source/line_info.dart';
import 'package:path/path.dart' as p;

final _domainRoots = <String>[
  'packages',
  'app/lib',
  'ctdev/lib',
  'ctterm/lib',
  'tool',
];

final _forbiddenExceptionTypes = <String>{'ArgumentError', 'Exception'};

/// PR-blocking check for generic exception throws in runtime domain code.
///
/// SPEC: SPEC/program/exception-enforcement.md
void main() {
  final repoRoot = Directory.current.path;
  final dartFiles = _collectDomainDartFiles(repoRoot);
  final violations = <CustomExceptionViolation>[];

  for (final file in dartFiles) {
    final relativePath = p.relative(file.path, from: repoRoot);
    final content = file.readAsStringSync();
    violations.addAll(findCustomExceptionViolations(relativePath, content));
  }

  if (violations.isEmpty) {
    stdout.writeln('check_custom_exceptions: no violations found.');
    return;
  }

  stderr.writeln(
    'check_custom_exceptions: found ${violations.length} violation(s):',
  );
  for (final violation in violations) {
    stderr.writeln(
      ' - ${violation.path}:${violation.line}: '
      'throwing ${violation.exceptionType} is forbidden; use a domain-specific exception type',
    );
  }
  exitCode = 1;
}

/// Exposed for unit tests (same behavior as production scan for a single file).
List<CustomExceptionViolation> findCustomExceptionViolations(
  String relativePath,
  String content,
) {
  if (!relativePath.endsWith('.dart')) {
    return const [];
  }
  if (relativePath.contains('/test/') || relativePath.endsWith('_test.dart')) {
    return const [];
  }
  if (relativePath.endsWith('.g.dart') ||
      relativePath.endsWith('.freezed.dart') ||
      relativePath.endsWith('.mocks.dart')) {
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

List<File> _collectDomainDartFiles(String repoRoot) {
  final files = <File>[];
  for (final domainRoot in _domainRoots) {
    final base = Directory(p.join(repoRoot, domainRoot));
    if (!base.existsSync()) {
      continue;
    }
    for (final entity in base.listSync(recursive: true, followLinks: false)) {
      if (entity is! File) {
        continue;
      }
      if (!entity.path.endsWith('.dart')) {
        continue;
      }
      final rel = p.relative(entity.path, from: repoRoot);
      if (rel.contains('/test/') || rel.endsWith('_test.dart')) {
        continue;
      }
      if (!rel.contains('/lib/')) {
        continue;
      }
      if (rel.endsWith('.g.dart') ||
          rel.endsWith('.freezed.dart') ||
          rel.endsWith('.mocks.dart')) {
        continue;
      }
      files.add(entity);
    }
  }
  return files;
}

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

class _ThrowVisitor extends RecursiveAstVisitor<void> {
  _ThrowVisitor(this.path, this.lineInfo);

  final String path;
  final LineInfo lineInfo;
  final List<CustomExceptionViolation> violations = [];

  @override
  void visitThrowExpression(ThrowExpression node) {
    final expression = node.expression;
    if (expression is InstanceCreationExpression) {
      final rawTypeName = expression.constructorName.type.toSource();
      final typeName = rawTypeName.split('<').first;
      if (_forbiddenExceptionTypes.contains(typeName)) {
        _addViolation(node, typeName);
      }
    } else if (expression is MethodInvocation) {
      if (_isArgumentErrorValueInvocation(expression)) {
        _addViolation(node, 'ArgumentError.value');
      } else if (expression.target == null &&
          _forbiddenExceptionTypes.contains(expression.methodName.name)) {
        _addViolation(node, expression.methodName.name);
      }
    }
    super.visitThrowExpression(node);
  }

  void _addViolation(ThrowExpression node, String exceptionType) {
    final line = lineInfo.getLocation(node.offset).lineNumber;
    violations.add(
      CustomExceptionViolation(
        path: path,
        line: line,
        exceptionType: exceptionType,
      ),
    );
  }
}

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
