import 'dart:io';

import 'package:analyzer/dart/analysis/utilities.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/source/line_info.dart';
import 'package:path/path.dart' as p;

import 'ct_repo_lint_scan_contract.dart';

/// PR-blocking structural gate for the shared split-dialog base
/// (Refs #3594 target state #2).
///
/// The in-game split dialogs (`SplitArmyDialog`, `SplitFleetDialog`, …) all
/// repeat the same `CtDialogShell(520 x 500)` + padded title + `CtTransferList`
/// scaffold and the same "keep one on the source side / new side non-empty"
/// Confirm rule. That shared chrome lives in [_canonicalBase]
/// ([SplitEntityDialog], declared in
/// `app/lib/features/game/widgets/split_entity_dialog.dart`).
///
/// This check prevents regression where a new `Split*Dialog` re-implements the
/// scaffold and confirm rule instead of extending the canonical base: any
/// public class declared under [_widgetsDirRelative] whose name starts with
/// `Split` and ends with `Dialog` (other than the base itself) must declare
/// `extends $_canonicalBase`.
///
/// SPEC: `SPEC/program/repo-lint.md`.
const _widgetsDirRelative = 'app/lib/features/game/widgets';
const _canonicalBase = 'SplitEntityDialog';
const _dialogPrefix = 'Split';
const _dialogSuffix = 'Dialog';

void main(List<String> args) {
  exit(runCheckAppSplitDialogBase(Directory.current.path));
}

int runCheckAppSplitDialogBase(
  String repoRoot, {
  void Function(String line)? info,
  void Function(String line)? err,
}) {
  final logI = info ?? stdout.writeln;
  final logE = err ?? stderr.writeln;

  final widgetsDir = Directory(p.join(repoRoot, _widgetsDirRelative));
  if (!widgetsDir.existsSync()) {
    logE('check_app_split_dialog_base: $_widgetsDirRelative not found.');
    return 1;
  }

  final files = collectRepoLintAppLibDartFilesSorted(repoRoot);
  final violations = <String>[];

  for (final file in files) {
    final relativePath = p
        .relative(file.path, from: repoRoot)
        .replaceAll('\\', '/');
    if (!relativePath.startsWith('$_widgetsDirRelative/')) {
      continue;
    }
    if (_shouldSkipPath(relativePath)) {
      continue;
    }

    final content = file.readAsStringSync();
    final parsed = parseString(content: content, path: relativePath);
    final visitor = _SplitDialogVisitor(
      relativePath: relativePath,
      lineInfo: parsed.unit.lineInfo,
    );
    parsed.unit.accept(visitor);
    violations.addAll(visitor.violations);
  }

  if (violations.isEmpty) {
    logI(
      'check_app_split_dialog_base: all `$_dialogPrefix*$_dialogSuffix` widgets '
      'extend $_canonicalBase.',
    );
    return 0;
  }

  violations.sort();
  logE(
    'check_app_split_dialog_base: found ${violations.length} '
    '`$_dialogPrefix*$_dialogSuffix` widget(s) under $_widgetsDirRelative not '
    'adopting `extends $_canonicalBase`:',
  );
  for (final v in violations) {
    logE(' - $v');
  }
  logE(
    'Fix: have each `$_dialogPrefix*$_dialogSuffix` widget '
    '`extends $_canonicalBase` (see '
    'app/lib/features/game/widgets/split_entity_dialog.dart) and return '
    '`buildSplitDialogScaffold(...)` from `build` instead of re-implementing '
    'the dialog scaffold and confirm rule.',
  );
  return 1;
}

bool _shouldSkipPath(String relativePath) {
  if (!relativePath.endsWith('.dart')) {
    return true;
  }
  if (relativePath.endsWith('.g.dart') ||
      relativePath.endsWith('.freezed.dart') ||
      relativePath.endsWith('.mocks.dart') ||
      relativePath.endsWith('.gen.dart')) {
    return true;
  }
  if (relativePath.contains('/test/') || relativePath.endsWith('_test.dart')) {
    return true;
  }
  for (final marker in repoLintFixtureDirPathMarkers) {
    if (('/$relativePath').contains(marker)) {
      return true;
    }
  }
  return false;
}

class _SplitDialogVisitor extends RecursiveAstVisitor<void> {
  _SplitDialogVisitor({required this.relativePath, required this.lineInfo});

  final String relativePath;
  final LineInfo lineInfo;
  final List<String> violations = <String>[];

  @override
  void visitClassDeclaration(ClassDeclaration node) {
    final name = node.name.lexeme;
    final isSplitDialog =
        !name.startsWith('_') &&
        name != _canonicalBase &&
        name.startsWith(_dialogPrefix) &&
        name.endsWith(_dialogSuffix);
    if (isSplitDialog && !_extendsCanonical(node)) {
      final line = lineInfo.getLocation(node.name.offset).lineNumber;
      violations.add(
        '$relativePath:$line: class "$name" does not adopt '
        '`extends $_canonicalBase`.',
      );
    }
    super.visitClassDeclaration(node);
  }

  bool _extendsCanonical(ClassDeclaration node) {
    final extendsClause = node.extendsClause;
    if (extendsClause == null) return false;
    return extendsClause.superclass.name.lexeme == _canonicalBase;
  }
}
