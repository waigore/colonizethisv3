// AST gate: governed province shortcut-host tests must not re-declare
// MapTopology( / TileMapResult( as fields. Fixture SoT:
// app/test/province_shortcut_host_emit_test_support.dart and
// app/test/province_shortcut_host_emit_fixtures.dart (Refs #4450 AC8–AC9).
import 'dart:io';

import 'package:analyzer/dart/analysis/utilities.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:path/path.dart' as p;

const String kShortcutHostSupportTestBasename =
    'province_shortcut_host_emit_test_support_test.dart';

bool isGovernedProvinceShortcutHostTest(String relativePath) {
  final normalized = relativePath.replaceAll('\\', '/');
  if (!normalized.startsWith('app/test/')) return false;
  if (!normalized.endsWith('.dart')) return false;
  final name = p.basename(normalized);
  if (name == kShortcutHostSupportTestBasename) return false;
  return name.startsWith('province_') &&
      name.contains('shortcut_host_') &&
      name.endsWith('_test.dart');
}

int runCheckAppTestNoDuplicateShortcutFixtures(
  String repoRoot, {
  void Function(String line)? info,
  void Function(String line)? err,
}) {
  final logI = info ?? stdout.writeln;
  final logE = err ?? stderr.writeln;

  final appTestDir = Directory(p.join(repoRoot, 'app', 'test'));
  if (!appTestDir.existsSync()) {
    logI(
      'check_app_test_no_duplicate_shortcut_fixtures: app/test not found; '
      'nothing to scan.',
    );
    return 0;
  }

  final violations = <String>[];
  for (final entity in appTestDir.listSync(
    recursive: false,
    followLinks: false,
  )) {
    if (entity is! File || !entity.path.endsWith('.dart')) continue;
    final relativePath = p
        .relative(entity.path, from: repoRoot)
        .replaceAll('\\', '/');
    if (!isGovernedProvinceShortcutHostTest(relativePath)) continue;
    final parsed = parseString(
      content: entity.readAsStringSync(),
      path: relativePath,
    );
    final visitor = _ShortcutFixtureVisitor(
      relativePath: relativePath,
      violations: violations,
    );
    parsed.unit.accept(visitor);
  }

  if (violations.isEmpty) {
    logI(
      'check_app_test_no_duplicate_shortcut_fixtures: no governed shortcut-host '
      'file re-declares MapTopology( or TileMapResult( (Refs #4450).',
    );
    return 0;
  }

  logE(
    'check_app_test_no_duplicate_shortcut_fixtures: found '
    '${violations.length} violation(s):',
  );
  for (final violation in violations) {
    logE(' - $violation');
  }
  return 1;
}

class _ShortcutFixtureVisitor extends RecursiveAstVisitor<void> {
  _ShortcutFixtureVisitor({
    required this.relativePath,
    required this.violations,
  });

  final String relativePath;
  final List<String> violations;

  @override
  void visitTopLevelVariableDeclaration(TopLevelVariableDeclaration node) {
    _scanFields(node.variables);
    super.visitTopLevelVariableDeclaration(node);
  }

  @override
  void visitFieldDeclaration(FieldDeclaration node) {
    _scanFields(node.fields);
    super.visitFieldDeclaration(node);
  }

  void _scanFields(VariableDeclarationList fields) {
    for (final variable in fields.variables) {
      final initializer = variable.initializer;
      if (initializer == null) continue;
      initializer.accept(
        _ConstructorNameVisitor(
          relativePath: relativePath,
          fieldName: variable.name.lexeme,
          violations: violations,
        ),
      );
    }
  }
}

class _ConstructorNameVisitor extends RecursiveAstVisitor<void> {
  _ConstructorNameVisitor({
    required this.relativePath,
    required this.fieldName,
    required this.violations,
  });

  final String relativePath;
  final String fieldName;
  final List<String> violations;

  void _flag(String name) {
    if (name == 'MapTopology' || name == 'TileMapResult') {
      violations.add(
        '$relativePath field `$fieldName` re-declares $name( — use '
        'province_shortcut_host_emit_fixtures.dart (Refs #4450 AC8/AC9)',
      );
    }
  }

  @override
  void visitInstanceCreationExpression(InstanceCreationExpression node) {
    _flag(node.constructorName.type.name.lexeme);
    super.visitInstanceCreationExpression(node);
  }

  @override
  void visitMethodInvocation(MethodInvocation node) {
    _flag(node.methodName.name);
    super.visitMethodInvocation(node);
  }
}

void main() {
  exit(runCheckAppTestNoDuplicateShortcutFixtures(Directory.current.path));
}
