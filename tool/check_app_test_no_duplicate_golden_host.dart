import 'dart:io';

import 'package:analyzer/dart/analysis/utilities.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/source/line_info.dart';
import 'package:path/path.dart' as p;

/// PR-blocking dedup gate for golden-capture hosts in `app/test/**` (Refs #3952).
///
/// Surface sizing (`tester.view.physicalSize = …`) and private `_pumpBuilt`
/// bounded-flush helpers previously reappeared in every `*golden*_test.dart` /
/// `*_goldens_test.dart` file. Canonical helpers live in
/// `app/test/golden_capture_harness.dart` (`configureGoldenView`,
/// `pumpForGolden`, `pumpGoldenHost`) and
/// `app/test/diplomacy_panel_test_support.dart`
/// (`pumpDiplomacyPanelBuilt`).
int runCheckAppTestNoDuplicateGoldenHost(
  String repoRoot, {
  void Function(String line)? info,
  void Function(String line)? err,
}) {
  final logI = info ?? stdout.writeln;
  final logE = err ?? stderr.writeln;

  final appTestDir = Directory(p.join(repoRoot, 'app', 'test'));
  if (!appTestDir.existsSync()) {
    logI(
      'check_app_test_no_duplicate_golden_host: app/test not found; nothing to '
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
    if (!_isGovernedGoldenFile(relativePath)) {
      continue;
    }
    final content = entity.readAsStringSync();
    final parsed = parseString(content: content, path: relativePath);
    final visitor = _GoldenHostVisitor(
      relativePath: relativePath,
      lineInfo: parsed.unit.lineInfo,
      violations: violations,
    );
    parsed.unit.accept(visitor);
  }

  if (violations.isEmpty) {
    logI(
      'check_app_test_no_duplicate_golden_host: no duplicated golden-host '
      'scaffolding found.',
    );
    return 0;
  }

  violations.sort();
  logE(
    'check_app_test_no_duplicate_golden_host: found ${violations.length} '
    'violation(s):',
  );
  for (final v in violations) {
    logE(' - $v');
  }
  logE(
    '   Use configureGoldenView / pumpGoldenHost / pumpForGolden from '
    'app/test/golden_capture_harness.dart (or '
    'pumpDiplomacyPanelBuilt for diplomacy bounded flushes).',
  );
  return 1;
}

/// True for `app/test/**/*golden*_test.dart` and `*_goldens_test.dart`,
/// excluding the shared harness tree under `app/test/support/`.
bool _isGovernedGoldenFile(String relativePath) {
  if (!relativePath.startsWith('app/test/')) {
    return false;
  }
  if (relativePath.startsWith('app/test/support/')) {
    return false;
  }
  final name = p.basename(relativePath);
  final isGoldenFamily =
      name.contains('golden') && name.endsWith('_test.dart');
  if (!isGoldenFamily) {
    return false;
  }
  if (relativePath.endsWith('.g.dart') ||
      relativePath.endsWith('.mocks.dart')) {
    return false;
  }
  return true;
}

class _GoldenHostVisitor extends RecursiveAstVisitor<void> {
  _GoldenHostVisitor({
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
    if (name == '_pumpBuilt') {
      _report(
        node.name.offset,
        'function "_pumpBuilt" duplicates pumpForGolden / '
        'pumpDiplomacyPanelBuilt',
      );
    }
    super.visitFunctionDeclaration(node);
  }

  @override
  void visitAssignmentExpression(AssignmentExpression node) {
    final left = node.leftHandSide;
    if (left is PropertyAccess && left.propertyName.name == 'physicalSize') {
      _report(
        left.propertyName.offset,
        'direct "physicalSize" assignment duplicates configureGoldenView',
      );
    }
    super.visitAssignmentExpression(node);
  }
}

void main(List<String> args) {
  final repoRoot = args.isNotEmpty ? args.first : Directory.current.path;
  exit(runCheckAppTestNoDuplicateGoldenHost(repoRoot));
}
