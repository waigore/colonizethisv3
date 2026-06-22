import 'dart:io';

import 'package:analyzer/dart/analysis/utilities.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/source/line_info.dart';
import 'package:path/path.dart' as p;

import 'ct_repo_lint_scan_contract.dart';

/// PR-blocking structural gate for the shared train-at-capital dialog base
/// (Refs #3594 target state #3).
///
/// The in-game train dialogs (`TrainCiviliansDialog`, `TrainMilitaryDialog`,
/// `TrainNavalDialog`, …) all repeat the same `PopScope` + `CtDialogShell`
/// wrapper, no-capital message, header/body composition, stepper count state,
/// tech-lock resolution, and order materialization on close. That shared
/// scaffolding lives in [_canonicalBase] ([TrainDialogBase] / its
/// `TrainDialogBaseState`, declared in
/// `app/lib/features/game/widgets/train_dialog_base.dart`).
///
/// This check prevents regression where a new `Train*Dialog` re-implements the
/// scaffold and stepper state instead of extending the canonical base: any
/// public class declared under [_widgetsDirRelative] whose name starts with
/// `Train` and ends with `Dialog` (other than the base itself) must declare
/// `extends $_canonicalBase`.
///
/// SPEC: `SPEC/program/repo-lint.md`.
const _widgetsDirRelative = 'app/lib/features/game/widgets';
const _canonicalBase = 'TrainDialogBase';
const _dialogPrefix = 'Train';
const _dialogSuffix = 'Dialog';

void main(List<String> args) {
  exit(runCheckAppTrainDialogBase(Directory.current.path));
}

int runCheckAppTrainDialogBase(
  String repoRoot, {
  void Function(String line)? info,
  void Function(String line)? err,
}) {
  final logI = info ?? stdout.writeln;
  final logE = err ?? stderr.writeln;

  final widgetsDir = Directory(p.join(repoRoot, _widgetsDirRelative));
  if (!widgetsDir.existsSync()) {
    logE('check_app_train_dialog_base: $_widgetsDirRelative not found.');
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
    final visitor = _TrainDialogVisitor(
      relativePath: relativePath,
      lineInfo: parsed.unit.lineInfo,
    );
    parsed.unit.accept(visitor);
    violations.addAll(visitor.violations);
  }

  if (violations.isEmpty) {
    logI(
      'check_app_train_dialog_base: all `$_dialogPrefix*$_dialogSuffix` widgets '
      'extend $_canonicalBase.',
    );
    return 0;
  }

  violations.sort();
  logE(
    'check_app_train_dialog_base: found ${violations.length} '
    '`$_dialogPrefix*$_dialogSuffix` widget(s) under $_widgetsDirRelative not '
    'adopting `extends $_canonicalBase`:',
  );
  for (final v in violations) {
    logE(' - $v');
  }
  logE(
    'Fix: have each `$_dialogPrefix*$_dialogSuffix` widget '
    '`extends $_canonicalBase` (see '
    'app/lib/features/game/widgets/train_dialog_base.dart) and back it with a '
    '`TrainDialogBaseState` subclass that supplies the unit-type cost model via '
    '`buildBody(...)` instead of re-implementing the dialog scaffold and '
    'stepper state.',
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

class _TrainDialogVisitor extends RecursiveAstVisitor<void> {
  _TrainDialogVisitor({required this.relativePath, required this.lineInfo});

  final String relativePath;
  final LineInfo lineInfo;
  final List<String> violations = <String>[];

  @override
  void visitClassDeclaration(ClassDeclaration node) {
    final name = node.name.lexeme;
    final isTrainDialog =
        !name.startsWith('_') &&
        name != _canonicalBase &&
        name.startsWith(_dialogPrefix) &&
        name.endsWith(_dialogSuffix);
    if (isTrainDialog && !_extendsCanonical(node)) {
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
