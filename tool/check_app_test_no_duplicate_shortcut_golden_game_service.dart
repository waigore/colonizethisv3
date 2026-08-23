// AST gate: the six MAP20001 shortcut-host golden suites must not declare a
// local `extends GameService` stub. SoT:
// app/test/province_shortcut_host_golden_game_service.dart (Refs #4606 AC3).
// Consulate goldens are excluded.
import 'dart:io';

import 'package:analyzer/dart/analysis/utilities.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:path/path.dart' as p;

const Set<String> kShortcutHostGoldenGameServiceGovernedBasenames = {
  'province_purchase_land_shortcut_host_goldens_test.dart',
  'province_build_railroad_shortcut_host_goldens_test.dart',
  'province_build_road_shortcut_host_goldens_test.dart',
  'province_build_fort_shortcut_host_goldens_test.dart',
  'province_build_port_shortcut_host_goldens_test.dart',
  'province_build_improvement_shortcut_host_goldens_test.dart',
};

bool isGovernedShortcutHostGoldenGameServiceTest(String relativePath) {
  final normalized = relativePath.replaceAll('\\', '/');
  if (!normalized.startsWith('app/test/')) return false;
  return kShortcutHostGoldenGameServiceGovernedBasenames.contains(
    p.basename(normalized),
  );
}

int runCheckAppTestNoDuplicateShortcutGoldenGameService(
  String repoRoot, {
  void Function(String line)? info,
  void Function(String line)? err,
}) {
  final logI = info ?? stdout.writeln;
  final logE = err ?? stderr.writeln;

  final appTestDir = Directory(p.join(repoRoot, 'app', 'test'));
  if (!appTestDir.existsSync()) {
    logI(
      'check_app_test_no_duplicate_shortcut_golden_game_service: app/test '
      'not found; nothing to scan.',
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
    if (!isGovernedShortcutHostGoldenGameServiceTest(relativePath)) continue;
    final parsed = parseString(
      content: entity.readAsStringSync(),
      path: relativePath,
    );
    parsed.unit.accept(
      _GameServiceExtendsVisitor(
        relativePath: relativePath,
        violations: violations,
      ),
    );
  }

  if (violations.isEmpty) {
    logI(
      'check_app_test_no_duplicate_shortcut_golden_game_service: no governed '
      'golden file declares class extends GameService (Refs #4606).',
    );
    return 0;
  }

  logE(
    'check_app_test_no_duplicate_shortcut_golden_game_service: found '
    '${violations.length} violation(s):',
  );
  for (final violation in violations) {
    logE(' - $violation');
  }
  return 1;
}

class _GameServiceExtendsVisitor extends RecursiveAstVisitor<void> {
  _GameServiceExtendsVisitor({
    required this.relativePath,
    required this.violations,
  });

  final String relativePath;
  final List<String> violations;

  @override
  void visitClassDeclaration(ClassDeclaration node) {
    final extendsClause = node.extendsClause;
    if (extendsClause != null &&
        extendsClause.superclass.name2.lexeme == 'GameService') {
      violations.add(
        '$relativePath class `${node.name.lexeme}` extends GameService — use '
        'province_shortcut_host_golden_game_service.dart (Refs #4606 AC1/AC3)',
      );
    }
    super.visitClassDeclaration(node);
  }
}

void main() {
  exit(
    runCheckAppTestNoDuplicateShortcutGoldenGameService(Directory.current.path),
  );
}
