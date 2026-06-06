import 'dart:io';

import 'package:analyzer/dart/analysis/utilities.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/source/line_info.dart';
import 'package:path/path.dart' as p;

import 'ct_repo_lint_scan_contract.dart';

/// PR-blocking structural gate for the shared game-panel contract
/// (Refs #3279 target state #2).
///
/// The fully-shaped game-bearing panels all carry the same four inputs
/// (`game`, `humanPlayerId`, `bus`, `readOnly`). They must adopt the shared
/// [GamePanelMixin] contract (declared in
/// `app/lib/features/game/widgets/game_panel_contract.dart`) so generic
/// helpers and tests can refer to "a game-bearing panel" by one type.
///
/// A class is a *fully-shaped game panel* when **all** of the following hold:
/// - It is declared under [_panelDirRelative]
///   (`app/lib/features/game/widgets/`).
/// - Its name is public (does not start with `_`) and ends with `Panel`.
/// - Its primary (unnamed) constructor declares **all three** of the
///   `game`, `bus`, and `readOnly` parameters. `ProductionPanel` /
///   `TechnologyPanel` (a `Player` but no `bus`/`readOnly`) and
///   `PauseMenuPanel` / `ObserveModeNotDefinedPanel` (no `game`) are therefore
///   exempt — they do not carry the full contract.
///
/// Such a class must declare `with GamePanelMixin` so the four getters and the
/// `gamePanelConfig` bundle are part of its type.
///
/// SPEC: `SPEC/program/repo-lint.md`.
const _panelDirRelative = 'app/lib/features/game/widgets';
const _requiredMixin = 'GamePanelMixin';
const _requiredParams = <String>{'game', 'bus', 'readOnly'};

void main(List<String> args) {
  exit(runCheckAppGamePanelMixin(Directory.current.path));
}

int runCheckAppGamePanelMixin(
  String repoRoot, {
  void Function(String line)? info,
  void Function(String line)? err,
}) {
  final logI = info ?? stdout.writeln;
  final logE = err ?? stderr.writeln;

  final panelDir = Directory(p.join(repoRoot, _panelDirRelative));
  if (!panelDir.existsSync()) {
    logE('check_app_game_panel_mixin: $_panelDirRelative not found.');
    return 1;
  }

  final files = collectRepoLintAppLibDartFilesSorted(repoRoot);
  final violations = <String>[];

  for (final file in files) {
    final relativePath = p
        .relative(file.path, from: repoRoot)
        .replaceAll('\\', '/');
    if (!relativePath.startsWith('$_panelDirRelative/')) {
      continue;
    }
    if (_shouldSkipPath(relativePath)) {
      continue;
    }

    final content = file.readAsStringSync();
    final parsed = parseString(content: content, path: relativePath);
    final visitor = _PanelVisitor(
      relativePath: relativePath,
      lineInfo: parsed.unit.lineInfo,
    );
    parsed.unit.accept(visitor);
    violations.addAll(visitor.violations);
  }

  if (violations.isEmpty) {
    logI(
      'check_app_game_panel_mixin: all fully-shaped game panels mix in '
      '$_requiredMixin.',
    );
    return 0;
  }

  violations.sort();
  logE(
    'check_app_game_panel_mixin: found ${violations.length} fully-shaped game '
    'panel(s) under $_panelDirRelative not adopting `with $_requiredMixin`:',
  );
  for (final v in violations) {
    logE(' - $v');
  }
  logE(
    'Fix: add `with $_requiredMixin` to each panel that declares `game`, '
    '`bus`, and `readOnly` (see '
    'app/lib/features/game/widgets/game_panel_contract.dart). The existing '
    '`final` fields satisfy the mixin getters.',
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

class _PanelVisitor extends RecursiveAstVisitor<void> {
  _PanelVisitor({required this.relativePath, required this.lineInfo});

  final String relativePath;
  final LineInfo lineInfo;
  final List<String> violations = <String>[];

  @override
  void visitClassDeclaration(ClassDeclaration node) {
    final name = node.name.lexeme;
    final isFullyShapedPanel =
        !name.startsWith('_') &&
        name.endsWith('Panel') &&
        _hasAllRequiredConstructorParams(node);
    if (isFullyShapedPanel && !_mixesInRequired(node)) {
      final line = lineInfo.getLocation(node.name.offset).lineNumber;
      violations.add(
        '$relativePath:$line: class "$name" declares game/bus/readOnly but '
        'does not adopt `with $_requiredMixin`.',
      );
    }
    super.visitClassDeclaration(node);
  }

  bool _hasAllRequiredConstructorParams(ClassDeclaration node) {
    final found = <String>{};
    for (final member in node.members) {
      if (member is! ConstructorDeclaration) continue;
      if (member.name != null) continue; // primary (unnamed) constructor only
      for (final param in member.parameters.parameters) {
        final paramName = _parameterName(param);
        if (paramName != null && _requiredParams.contains(paramName)) {
          found.add(paramName);
        }
      }
    }
    return found.containsAll(_requiredParams);
  }

  bool _mixesInRequired(ClassDeclaration node) {
    final withClause = node.withClause;
    if (withClause == null) return false;
    for (final mixinType in withClause.mixinTypes) {
      if (mixinType.name.lexeme == _requiredMixin) {
        return true;
      }
    }
    return false;
  }

  String? _parameterName(FormalParameter param) {
    final inner = param is DefaultFormalParameter ? param.parameter : param;
    return inner.name?.lexeme;
  }
}
