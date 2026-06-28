import 'dart:io';

import 'package:analyzer/dart/analysis/utilities.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/source/line_info.dart';
import 'package:path/path.dart' as p;

/// PR-blocking structural gate for the shared **commodity-cost** train-dialog
/// base (Refs #3686).
///
/// `TrainMilitaryDialog` and `TrainNavalDialog` share an identical cost model
/// (treasury + 1 peasant + commodity inputs), deficit hint, resource bar, and
/// unit-row presentation — differing only in the economy catalog and id
/// accessor. That shared machinery is centralized in [_canonicalBase]
/// (`CommodityCostTrainDialogState`, declared in
/// `app/lib/features/game/widgets/train_commodity_cost_dialog_base.dart`).
///
/// This check prevents a regression where either commodity-cost dialog
/// re-implements the cost math or private resource-bar / unit-row widgets
/// instead of extending the shared base: each target file
/// ([_targetFilesRelative]) must declare a state class
/// `extends $_canonicalBase` and must not re-declare any of the
/// [_forbiddenMemberNames] members or a private `_*ResourceBar` / `_*Row`
/// widget.
///
/// Scoped to the two commodity-cost dialogs only — `TrainCiviliansDialog` keeps
/// its own (treasury + paper) cost model and entry-style resource bar.
///
/// SPEC: `SPEC/program/repo-lint.md`.
const _canonicalBase = 'CommodityCostTrainDialogState';

const _targetFilesRelative = <String>[
  'app/lib/features/game/widgets/train_military_dialog.dart',
  'app/lib/features/game/widgets/train_naval_dialog.dart',
];

const _forbiddenMemberNames = <String>{
  '_totalTreasuryCost',
  '_totalPeasantCost',
  '_totalCommodityCosts',
  '_remainingTreasury',
  '_remainingPeasants',
  '_remainingCommodity',
  '_deficitHint',
  'canAffordIncrement',
};

void main(List<String> args) {
  exit(runCheckAppTrainDialogCommodityCostDedup(Directory.current.path));
}

int runCheckAppTrainDialogCommodityCostDedup(
  String repoRoot, {
  void Function(String line)? info,
  void Function(String line)? err,
}) {
  final logI = info ?? stdout.writeln;
  final logE = err ?? stderr.writeln;

  final violations = <String>[];
  var scanned = 0;

  for (final relativePath in _targetFilesRelative) {
    final file = File(p.join(repoRoot, relativePath));
    if (!file.existsSync()) continue;
    scanned++;

    final content = file.readAsStringSync();
    final parsed = parseString(content: content, path: relativePath);
    final visitor = _CommodityCostDialogVisitor(
      relativePath: relativePath,
      lineInfo: parsed.unit.lineInfo,
    );
    parsed.unit.accept(visitor);

    if (!visitor.extendsCanonical) {
      violations.add(
        '$relativePath: no class declares `extends $_canonicalBase`.',
      );
    }
    violations.addAll(visitor.violations);
  }

  if (scanned == 0) {
    logE(
      'check_app_train_dialog_commodity_cost_dedup: no target train-dialog '
      'files found under $repoRoot.',
    );
    return 1;
  }

  if (violations.isEmpty) {
    logI(
      'check_app_train_dialog_commodity_cost_dedup: the commodity-cost train '
      'dialogs extend $_canonicalBase and declare no duplicated cost machinery.',
    );
    return 0;
  }

  violations.sort();
  logE(
    'check_app_train_dialog_commodity_cost_dedup: found ${violations.length} '
    'commodity-cost dedup violation(s):',
  );
  for (final v in violations) {
    logE(' - $v');
  }
  logE(
    'Fix: have TrainMilitaryDialog / TrainNavalDialog `extends $_canonicalBase` '
    '(app/lib/features/game/widgets/train_commodity_cost_dialog_base.dart) and '
    'supply only commodityCostEntries / resourceBarCommodityIds / the tech map '
    '/ title / committed-orders event, instead of re-declaring the cost math '
    '(${_forbiddenMemberNames.join(', ')}) or private '
    '`_*ResourceBar` / `_*Row` widgets.',
  );
  return 1;
}

class _CommodityCostDialogVisitor extends RecursiveAstVisitor<void> {
  _CommodityCostDialogVisitor({
    required this.relativePath,
    required this.lineInfo,
  });

  final String relativePath;
  final LineInfo lineInfo;
  final List<String> violations = <String>[];
  bool extendsCanonical = false;

  @override
  void visitClassDeclaration(ClassDeclaration node) {
    final extendsClause = node.extendsClause;
    if (extendsClause != null &&
        extendsClause.superclass.name.lexeme == _canonicalBase) {
      extendsCanonical = true;
    }

    final name = node.name.lexeme;
    if (name.startsWith('_') &&
        (name.endsWith('ResourceBar') || name.endsWith('Row'))) {
      final line = lineInfo.getLocation(node.name.offset).lineNumber;
      violations.add(
        '$relativePath:$line: private widget "$name" re-declares the '
        'commodity-cost resource-bar / unit-row chrome owned by '
        '$_canonicalBase.',
      );
    }
    super.visitClassDeclaration(node);
  }

  @override
  void visitMethodDeclaration(MethodDeclaration node) {
    final name = node.name.lexeme;
    if (_forbiddenMemberNames.contains(name)) {
      final line = lineInfo.getLocation(node.name.offset).lineNumber;
      violations.add(
        '$relativePath:$line: member "$name" re-declares commodity-cost '
        'machinery owned by $_canonicalBase.',
      );
    }
    super.visitMethodDeclaration(node);
  }
}
