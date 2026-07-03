import 'dart:io';

import 'package:analyzer/dart/analysis/utilities.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/source/line_info.dart';
import 'package:path/path.dart' as p;

/// PR-blocking dedup gate for duplicated diplomacy/civilian bus-dialog test
/// hosts in `app/test/**` (Refs #3847).
///
/// `_EventHandlingWrapper` previously appeared in diplomacy and civilian panel
/// test files. The canonical hosts now live in
/// `app/test/support/diplomacy_panel_test_support.dart`
/// (`DiplomacyPanelBusDialogHost`, `CivilianPanelBusDialogHost`).
int runCheckAppTestNoDuplicateDiplomacyHost(
  String repoRoot, {
  void Function(String line)? info,
  void Function(String line)? err,
}) {
  final logI = info ?? stdout.writeln;
  final logE = err ?? stderr.writeln;

  final appTestDir = Directory(p.join(repoRoot, 'app', 'test'));
  if (!appTestDir.existsSync()) {
    logI(
      'check_app_test_no_duplicate_diplomacy_host: app/test not found; nothing '
      'to scan.',
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
    if (!_isGovernedDiplomacyHostFile(relativePath)) {
      continue;
    }
    final content = entity.readAsStringSync();
    final parsed = parseString(content: content, path: relativePath);
    final visitor = _DiplomacyHostVisitor(
      relativePath: relativePath,
      lineInfo: parsed.unit.lineInfo,
      violations: violations,
    );
    parsed.unit.accept(visitor);
  }

  if (violations.isEmpty) {
    logI(
      'check_app_test_no_duplicate_diplomacy_host: no duplicated bus-dialog '
      'hosts found.',
    );
    return 0;
  }

  violations.sort();
  logE(
    'check_app_test_no_duplicate_diplomacy_host: found ${violations.length} '
    'violation(s):',
  );
  for (final v in violations) {
    logE(' - $v');
  }
  logE(
    '   Use DiplomacyPanelBusDialogHost / CivilianPanelBusDialogHost from '
    'app/test/support/diplomacy_panel_test_support.dart.',
  );
  return 1;
}

bool _isGovernedDiplomacyHostFile(String relativePath) {
  if (!relativePath.startsWith('app/test/')) {
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

class _DiplomacyHostVisitor extends RecursiveAstVisitor<void> {
  _DiplomacyHostVisitor({
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
  void visitClassDeclaration(ClassDeclaration node) {
    final name = node.name.lexeme;
    if (name == '_EventHandlingWrapper') {
      _report(
        node.name.offset,
        'private class "_EventHandlingWrapper" duplicates the shared '
        'bus-dialog host',
      );
    }
    super.visitClassDeclaration(node);
  }
}

void main() {
  exit(runCheckAppTestNoDuplicateDiplomacyHost(Directory.current.path));
}
