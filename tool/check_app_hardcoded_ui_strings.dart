import 'dart:convert';
import 'dart:io';

import 'package:analyzer/dart/analysis/utilities.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/source/line_info.dart';
import 'package:path/path.dart' as p;

/// PR-blocking hardcoded UI string check for `app/lib/**`.
///
/// Uses the Dart AST (not line regexes) so multiline `Text(\n  '…',\n)` and
/// adjacent string literals are detected. Supplements `hardcoded_strings_lint`.
void main() {
  final repoRoot = Directory.current.path;
  final appLib = Directory(p.join(repoRoot, 'app', 'lib'));
  if (!appLib.existsSync()) {
    stderr.writeln('check_app_hardcoded_ui_strings: app/lib not found.');
    exitCode = 1;
    return;
  }

  final violations = <HardcodedUiViolation>[];
  for (final file in _collectAppLibDartFiles(appLib)) {
    final relativePath = p.relative(file.path, from: repoRoot);
    final content = file.readAsStringSync();
    violations.addAll(findHardcodedUiViolations(relativePath, content));
  }

  if (violations.isEmpty) {
    stdout.writeln('check_app_hardcoded_ui_strings: no violations found.');
    return;
  }

  stderr.writeln('Hardcoded UI string violations found in app/lib:');
  for (final v in violations) {
    stderr.writeln(' - ${v.path}:${v.line}: ${v.snippet}');
  }
  stderr.writeln(
    '\nTotal violations: ${violations.length}. '
    'Move user-visible strings to AppLocalizations/ARB.',
  );
  exitCode = 1;
}

/// Exposed for unit tests (same behavior as production scan).
List<HardcodedUiViolation> findHardcodedUiViolations(
  String relativePath,
  String content,
) {
  final normalized = p.normalize(relativePath);
  if (!normalized.startsWith('app${p.separator}lib${p.separator}')) {
    return const [];
  }
  if (_fileHasIgnoreForRule(content)) {
    return const [];
  }
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
  final visitor = _HardcodedUiVisitor(relativePath, content, parsed.lineInfo);
  parsed.unit.accept(visitor);
  return visitor.violations;
}

List<File> _collectAppLibDartFiles(Directory appLib) {
  final files = <File>[];
  for (final entity in appLib.listSync(recursive: true, followLinks: false)) {
    if (entity is! File) {
      continue;
    }
    if (!entity.path.endsWith('.dart')) {
      continue;
    }
    files.add(entity);
  }
  files.sort((a, b) => a.path.compareTo(b.path));
  return files;
}

bool _fileHasIgnoreForRule(String source) {
  return source.contains('ignore_for_file: avoid_hardcoded_strings_in_widgets');
}

bool _lineSuppresses(String line) {
  return line.contains('ignore: avoid_hardcoded_strings_in_widgets');
}

bool _isSuppressedAtLine(String source, int lineNumber1Based) {
  final lines = const LineSplitter().convert(source);
  final idx = lineNumber1Based - 1;
  if (idx < 0 || idx >= lines.length) {
    return false;
  }
  if (_lineSuppresses(lines[idx])) {
    return true;
  }
  if (idx > 0 && _lineSuppresses(lines[idx - 1])) {
    return true;
  }
  return false;
}

bool _isAllowedLiteral(String value) {
  final v = value.trim();
  if (v.length <= 2) {
    return true;
  }
  if (RegExp(r'^\s*$').hasMatch(v)) {
    return true;
  }
  if (RegExp(r'^[\W_]{1,2}$').hasMatch(v)) {
    return true;
  }
  if (RegExp(r'^[a-z]+_[a-z0-9_]+$').hasMatch(v)) {
    return true;
  }
  if (RegExp(r'^[A-Z][A-Z0-9_]+$').hasMatch(v)) {
    return true;
  }
  if (RegExp(r'^/[\w/\-.]+$').hasMatch(v)) {
    return true;
  }
  return false;
}

bool _interpolationHasStaticText(StringInterpolation node) {
  for (final e in node.elements) {
    if (e is InterpolationString && e.value.isNotEmpty) {
      return true;
    }
  }
  return false;
}

String? _concatStringLiteralValue(Expression expr) {
  if (expr is SimpleStringLiteral) {
    return expr.value;
  }
  if (expr is AdjacentStrings) {
    final b = StringBuffer();
    for (final s in expr.strings) {
      final part = _concatStringLiteralValue(s);
      if (part == null) {
        return null;
      }
      b.write(part);
    }
    return b.toString();
  }
  return null;
}

bool _isDisallowedStringExpression(Expression expr) {
  final literal = _concatStringLiteralValue(expr);
  if (literal != null) {
    return !_isAllowedLiteral(literal);
  }
  if (expr is StringInterpolation) {
    return _interpolationHasStaticText(expr);
  }
  return false;
}

Expression? _firstPositionalArgument(ArgumentList args) {
  for (final arg in args.arguments) {
    if (arg is NamedExpression) {
      continue;
    }
    return arg;
  }
  return null;
}

Expression? _namedArgumentExpression(ArgumentList args, String name) {
  for (final arg in args.arguments) {
    if (arg is! NamedExpression) {
      continue;
    }
    if (arg.name.label.name == name) {
      return arg.expression;
    }
  }
  return null;
}

class _HardcodedUiVisitor extends RecursiveAstVisitor<void> {
  _HardcodedUiVisitor(this.path, this.source, this.lineInfo);

  final String path;
  final String source;
  final LineInfo lineInfo;
  final List<HardcodedUiViolation> violations = [];

  void _reportIfBad(Expression? expr) {
    if (expr == null || !_isDisallowedStringExpression(expr)) {
      return;
    }
    final line = lineInfo.getLocation(expr.offset).lineNumber;
    if (_isSuppressedAtLine(source, line)) {
      return;
    }
    final endLine = lineInfo.getLocation(expr.end).lineNumber;
    final snippet = _snippetForLines(source, line, endLine);
    violations.add(
      HardcodedUiViolation(path: path, line: line, snippet: snippet),
    );
  }

  /// `parseString` (no resolution) represents most `Widget(` calls as
  /// [MethodInvocation]; `const Widget(` is [InstanceCreationExpression].
  /// Matches the historical Python gate surface (`tool/check_app_hardcoded_ui_strings.py`)
  /// plus multiline arguments; keep this list aligned with `SPEC/ui/localization.md`.
  void _checkWidgetConstructor(String typeName, ArgumentList args) {
    switch (typeName) {
      case 'Text':
      case 'SelectableText':
        _reportIfBad(_firstPositionalArgument(args));
        break;
      case 'Tooltip':
        _reportIfBad(_namedArgumentExpression(args, 'message'));
        break;
      case 'InputDecoration':
        _reportIfBad(_namedArgumentExpression(args, 'labelText'));
        _reportIfBad(_namedArgumentExpression(args, 'hintText'));
        break;
      default:
        break;
    }
  }

  bool _isUnqualifiedOrPrefixedCall(MethodInvocation node) {
    final target = node.target;
    if (target == null) {
      return true;
    }
    // `importPrefix.Text(...)` (e.g. `material.Text(...)`).
    return target is SimpleIdentifier;
  }

  @override
  void visitMethodInvocation(MethodInvocation node) {
    if (_isUnqualifiedOrPrefixedCall(node)) {
      _checkWidgetConstructor(node.methodName.name, node.argumentList);
    }
    super.visitMethodInvocation(node);
  }

  @override
  void visitInstanceCreationExpression(InstanceCreationExpression node) {
    final typeName = node.constructorName.type.name.lexeme;
    _checkWidgetConstructor(typeName, node.argumentList);
    super.visitInstanceCreationExpression(node);
  }
}

String _snippetForLines(String source, int startLine, int endLine) {
  final lines = const LineSplitter().convert(source);
  if (startLine < 1 || startLine > lines.length) {
    return '';
  }
  final last = endLine.clamp(startLine, lines.length);
  return lines.sublist(startLine - 1, last).join(' ').trim();
}

class HardcodedUiViolation {
  const HardcodedUiViolation({
    required this.path,
    required this.line,
    required this.snippet,
  });

  final String path;
  final int line;
  final String snippet;
}
