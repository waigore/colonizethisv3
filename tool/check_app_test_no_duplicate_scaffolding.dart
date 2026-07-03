import 'dart:io';

import 'package:analyzer/dart/analysis/utilities.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/source/line_info.dart';
import 'package:path/path.dart' as p;

/// PR-blocking dedup gate for the `app` min-viewport test scaffolding (#3730).
///
/// The 25 `app/test/*_320dp_min_viewport_test.dart` files previously each
/// re-declared an identical private `_pump<Thing>AtSize(...)` helper that
/// repeated the same `setSurfaceSize` + `MaterialApp(theme:
/// AppThemes.editorialMonocle, home: MediaQuery(...))` viewport shell. That
/// boilerplate now lives once in `app/test/support/min_viewport_harness.dart`
/// (`pumpAtMinViewport` / `buildMinViewportApp`). This gate keeps the
/// duplication from creeping back into that family.
///
/// **Scope (deliberately narrow).** Only the `*_320dp_min_viewport_test.dart`
/// family is governed, so the gate cannot fire on the many legitimately
/// distinct helpers elsewhere in `app/test/` (golden capture, mockup-fidelity,
/// widgetbook viewport stories, main-menu responsive `pumpAtSize`, etc.) that
/// also force a surface size and/or use the editorial theme for unrelated
/// reasons. The shared harness under `app/test/support/` is always exempt.
///
/// **Violations.** Inside a governed file, any of the following is flagged
/// because it indicates a re-introduced bespoke viewport shell instead of the
/// shared harness:
///   1. a function declaration whose name ends with `AtSize` (the
///      `_pump<Thing>AtSize` signature the harness replaced);
///   2. a `tester.binding.setSurfaceSize(...)` invocation;
///   3. a reference to `AppThemes.editorialMonocle`.
///
/// Detection is AST-based, so comments and string literals never trigger it.
int runCheckAppTestNoDuplicateScaffolding(
  String repoRoot, {
  void Function(String line)? info,
  void Function(String line)? err,
}) {
  final logI = info ?? stdout.writeln;
  final logE = err ?? stderr.writeln;

  final appTestDir = Directory(p.join(repoRoot, 'app', 'test'));
  if (!appTestDir.existsSync()) {
    logI(
      'check_app_test_no_duplicate_scaffolding: app/test not found; nothing to '
      'scan.',
    );
    return 0;
  }

  final violations = <String>[];

  for (final entity in appTestDir.listSync(recursive: true, followLinks: false)) {
    if (entity is! File || !entity.path.endsWith('.dart')) {
      continue;
    }
    final relativePath = p
        .relative(entity.path, from: repoRoot)
        .replaceAll('\\', '/');
    final content = entity.readAsStringSync();
    final parsed = parseString(content: content, path: relativePath);
    if (_isGovernedMinViewportFile(relativePath)) {
      final visitor = _ScaffoldingVisitor(
        relativePath: relativePath,
        lineInfo: parsed.unit.lineInfo,
        violations: violations,
      );
      parsed.unit.accept(visitor);
    }
    if (_isGovernedWidgetbookUseCaseFile(relativePath)) {
      final visitor = _WidgetbookUseCaseVisitor(
        relativePath: relativePath,
        lineInfo: parsed.unit.lineInfo,
        violations: violations,
      );
      parsed.unit.accept(visitor);
    }
  }

  if (violations.isEmpty) {
    logI(
      'check_app_test_no_duplicate_scaffolding: no duplicated min-viewport or '
      'widgetbook use-case scaffolding found.',
    );
    return 0;
  }

  violations.sort();
  logE(
    'check_app_test_no_duplicate_scaffolding: found ${violations.length} '
    'duplicated-scaffolding violation(s):',
  );
  for (final v in violations) {
    logE(' - $v');
  }
  logE(
    '   Min-viewport: use pumpAtMinViewport / buildMinViewportApp from '
    'app/test/support/min_viewport_harness.dart. '
    'Widgetbook: use findWidgetbookUseCase from '
    'app/test/support/widgetbook_test_harness.dart.',
  );
  return 1;
}

/// True for `app/test/widgetbook_*_test.dart`, excluding support fixtures.
bool _isGovernedWidgetbookUseCaseFile(String relativePath) {
  final name = p.basename(relativePath);
  if (!name.startsWith('widgetbook_') || !name.endsWith('_test.dart')) {
    return false;
  }
  if (relativePath.startsWith('app/test/support/')) {
    return false;
  }
  return true;
}

/// True for `app/test/**/*_320dp_min_viewport_test.dart`, excluding the shared
/// harness tree under `app/test/support/` and generated Dart.
bool _isGovernedMinViewportFile(String relativePath) {
  if (!relativePath.endsWith('_320dp_min_viewport_test.dart')) {
    return false;
  }
  if (relativePath.startsWith('app/test/support/')) {
    return false;
  }
  if (relativePath.endsWith('.g.dart') ||
      relativePath.endsWith('.mocks.dart')) {
    return false;
  }
  return true;
}

class _ScaffoldingVisitor extends RecursiveAstVisitor<void> {
  _ScaffoldingVisitor({
    required this.relativePath,
    required this.lineInfo,
    required this.violations,
  });

  final String relativePath;
  final LineInfo lineInfo;
  final List<String> violations;

  void _report(int offset, String detail) {
    final line = lineInfo.getLocation(offset).lineNumber;
    violations.add('$relativePath:$line: $detail');
  }

  @override
  void visitFunctionDeclaration(FunctionDeclaration node) {
    final name = node.name.lexeme;
    if (name.endsWith('AtSize')) {
      _report(
        node.name.offset,
        'function "$name" re-declares a per-file min-viewport pump helper',
      );
    }
    super.visitFunctionDeclaration(node);
  }

  @override
  void visitMethodInvocation(MethodInvocation node) {
    if (node.methodName.name == 'setSurfaceSize') {
      _report(
        node.methodName.offset,
        'direct "setSurfaceSize" call duplicates the harness viewport setup',
      );
    }
    super.visitMethodInvocation(node);
  }

  @override
  void visitPrefixedIdentifier(PrefixedIdentifier node) {
    if (node.identifier.name == 'editorialMonocle') {
      _report(
        node.offset,
        'reference to "AppThemes.editorialMonocle" duplicates the harness shell',
      );
    }
    super.visitPrefixedIdentifier(node);
  }

  @override
  void visitPropertyAccess(PropertyAccess node) {
    if (node.propertyName.name == 'editorialMonocle') {
      _report(
        node.offset,
        'reference to "AppThemes.editorialMonocle" duplicates the harness shell',
      );
    }
    super.visitPropertyAccess(node);
  }
}

class _WidgetbookUseCaseVisitor extends RecursiveAstVisitor<void> {
  _WidgetbookUseCaseVisitor({
    required this.relativePath,
    required this.lineInfo,
    required this.violations,
  });

  final String relativePath;
  final LineInfo lineInfo;
  final List<String> violations;

  void _report(int offset, String detail) {
    final line = lineInfo.getLocation(offset).lineNumber;
    violations.add('$relativePath:$line: $detail');
  }

  @override
  void visitFunctionDeclaration(FunctionDeclaration node) {
    final name = node.name.lexeme;
    if (name != '_useCase') {
      super.visitFunctionDeclaration(node);
      return;
    }
    final returnType = node.returnType;
    if (returnType != null &&
        returnType.toString().contains('WidgetbookUseCase')) {
      _report(
        node.name.offset,
        'function "_useCase" duplicates widgetbook_test_harness.dart',
      );
    }
    super.visitFunctionDeclaration(node);
  }
}

void main() {
  exit(runCheckAppTestNoDuplicateScaffolding(Directory.current.path));
}
