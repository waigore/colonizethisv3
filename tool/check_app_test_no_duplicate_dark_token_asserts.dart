// Forbid private dark-token / editorial-monocle chrome expect helpers outside
// `app/test/support/` (Refs #4013).
import 'dart:io';

import 'package:analyzer/dart/analysis/utilities.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/source/line_info.dart';
import 'package:path/path.dart' as p;

final RegExp _forbiddenHelperName = RegExp(
  r'^_expect(Muted|EditorialMonocle)',
);

bool _isForbiddenHelperName(String name) =>
    _forbiddenHelperName.hasMatch(name);

/// Scans `app/test/**/*.dart` (excluding `app/test/support/`) and fails when
/// any top-level function is named `_expectMuted*` or `_expectEditorialMonocle*`.
int runCheckAppTestNoDuplicateDarkTokenAsserts(
  String repoRoot, {
  void Function(String line)? info,
  void Function(String line)? err,
}) {
  final logI = info ?? stdout.writeln;
  final logE = err ?? stderr.writeln;

  final appTestDir = Directory(p.join(repoRoot, 'app', 'test'));
  if (!appTestDir.existsSync()) {
    logI(
      'check_app_test_no_duplicate_dark_token_asserts: app/test not found; '
      'nothing to scan.',
    );
    return 0;
  }

  final violations = <String>[];
  for (final entity in appTestDir.listSync(
    recursive: true,
    followLinks: false,
  )) {
    if (entity is! File || !entity.path.endsWith('.dart')) {
      continue;
    }
    final relativePath = p
        .relative(entity.path, from: repoRoot)
        .replaceAll('\\', '/');
    if (relativePath.startsWith('app/test/support/')) {
      continue;
    }
    final content = entity.readAsStringSync();
    if (!content.contains('_expectMuted') &&
        !content.contains('_expectEditorialMonocle')) {
      continue;
    }
    final parsed = parseString(content: content, path: relativePath);
    parsed.unit.accept(
      _DarkTokenAssertVisitor(
        relativePath: relativePath,
        lineInfo: parsed.unit.lineInfo,
        violations: violations,
      ),
    );
  }

  if (violations.isEmpty) {
    logI(
      'check_app_test_no_duplicate_dark_token_asserts: no private '
      '_expectMuted* / _expectEditorialMonocle* helpers outside support/.',
    );
    return 0;
  }

  violations.sort();
  logE(
    'check_app_test_no_duplicate_dark_token_asserts: found '
    '${violations.length} violation(s):',
  );
  for (final violation in violations) {
    logE(' - $violation');
  }
  return 1;
}

class _DarkTokenAssertVisitor extends RecursiveAstVisitor<void> {
  _DarkTokenAssertVisitor({
    required this.relativePath,
    required this.lineInfo,
    required this.violations,
  });

  final String relativePath;
  final LineInfo lineInfo;
  final List<String> violations;

  @override
  void visitFunctionDeclaration(FunctionDeclaration node) {
    final name = node.name.lexeme;
    if (_isForbiddenHelperName(name)) {
      final line = lineInfo.getLocation(node.offset).lineNumber;
      violations.add(
        '$relativePath:$line declares $name — use shared helpers in '
        'app/test/support/editorial_monocle_dark_token_assertions.dart',
      );
    }
    super.visitFunctionDeclaration(node);
  }
}

void main() {
  exit(runCheckAppTestNoDuplicateDarkTokenAsserts(Directory.current.path));
}
