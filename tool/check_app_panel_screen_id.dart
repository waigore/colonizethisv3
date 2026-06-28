import 'dart:io';

import 'package:analyzer/dart/analysis/utilities.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/source/line_info.dart';
import 'package:path/path.dart' as p;

import 'ct_repo_lint_scan_contract.dart';

/// PR-blocking structural gate for the game-bearing panel `screenId` mandate
/// (Refs #3279).
///
/// Every **game-bearing panel** must expose a stable, grep-able screen ID so
/// it is traceable to `SPEC/ui/screen-registry.md` and `UiScreenIds`
/// (per `colonizethis-ui-documentation.mdc` § Code binding).
///
/// A class is a *game-bearing panel* when **all** of the following hold:
/// - It is declared under [_panelDirRelative]
///   (`app/lib/features/game/widgets/`), the canonical home of the player-app
///   game panels enumerated by issue #3279.
/// - Its name is public (does not start with `_`) and ends with `Panel`.
/// - Its primary (unnamed) constructor declares a `game` parameter (the
///   contract boundary in #3279: `PauseMenuPanel` and
///   `ObserveModeNotDefinedPanel` take no `game` and are therefore exempt).
///
/// Such a class must declare a `static const screenId` field initialized from a
/// `UiScreenIds.*` constant. Sub-panels living under `features/game/flame/` or
/// `features/game/screens/` (for example `VictoryPanel`, the
/// `GameMapProvinceDetailSidePanel` slot, private `_*Panel` helpers) are
/// intentionally out of scope: they are bodies/slots of a host surface that
/// already owns the registry ID, not standalone registered surfaces.
///
/// SPEC: `SPEC/program/repo-lint.md`.
const _panelDirRelative = 'app/lib/features/game/widgets';

void main(List<String> args) {
  exit(runCheckAppPanelScreenId(Directory.current.path));
}

int runCheckAppPanelScreenId(
  String repoRoot, {
  void Function(String line)? info,
  void Function(String line)? err,
}) {
  final logI = info ?? stdout.writeln;
  final logE = err ?? stderr.writeln;

  final panelDir = Directory(p.join(repoRoot, _panelDirRelative));
  if (!panelDir.existsSync()) {
    logE('check_app_panel_screen_id: $_panelDirRelative not found.');
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
    logI('check_app_panel_screen_id: all game-bearing panels declare screenId.');
    return 0;
  }

  violations.sort();
  logE(
    'check_app_panel_screen_id: found ${violations.length} game-bearing '
    'panel(s) under $_panelDirRelative without a `static const screenId`:',
  );
  for (final v in violations) {
    logE(' - $v');
  }
  logE(
    'Fix: add `static const screenId = UiScreenIds.<id>;` to each panel (per '
    'colonizethis-ui-documentation.mdc § Code binding), reusing the host '
    "surface's registry ID when the panel is the body of an existing screen.",
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
    final isGameBearingPanel =
        !name.startsWith('_') &&
        name.endsWith('Panel') &&
        _hasGameConstructorParam(node);
    if (isGameBearingPanel && !_hasStaticConstScreenId(node)) {
      final line = lineInfo.getLocation(node.name.offset).lineNumber;
      violations.add(
        '$relativePath:$line: class "$name" accepts a `game` parameter but '
        'does not declare `static const screenId = UiScreenIds.<id>;`.',
      );
    }
    super.visitClassDeclaration(node);
  }

  bool _hasGameConstructorParam(ClassDeclaration node) {
    for (final member in node.members) {
      if (member is! ConstructorDeclaration) continue;
      for (final param in member.parameters.parameters) {
        if (_parameterName(param) == 'game') {
          return true;
        }
      }
    }
    return false;
  }

  bool _hasStaticConstScreenId(ClassDeclaration node) {
    for (final member in node.members) {
      if (member is! FieldDeclaration) continue;
      if (!member.isStatic) continue;
      if (!member.fields.isConst) continue;
      for (final variable in member.fields.variables) {
        if (variable.name.lexeme == 'screenId') {
          return true;
        }
      }
    }
    return false;
  }

  String? _parameterName(FormalParameter param) {
    final inner = param is DefaultFormalParameter ? param.parameter : param;
    return inner.name?.lexeme;
  }
}
