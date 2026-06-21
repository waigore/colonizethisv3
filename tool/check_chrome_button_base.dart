import 'dart:io';

import 'package:analyzer/dart/analysis/utilities.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/source/line_info.dart';
import 'package:path/path.dart' as p;

import 'ct_repo_lint_scan_contract.dart';

/// PR-blocking structural gate for the shared chrome text-button base
/// (Refs #3594 target state #1).
///
/// The editorial-monocle chrome text buttons
/// (`CtActionTextButton`, `CtDangerTextButton`, …) all repeat the same hover
/// state machine and disabled / interactive / semantics / tooltip wrapping.
/// That shared chrome lives in [_canonicalMixin]
/// ([CtHoverButtonStateMixin], declared in
/// `app/lib/features/game/widgets/chrome/ct_hover_button.dart`).
///
/// This check prevents regression where a new `*TextButton` re-implements the
/// hover/disabled chrome instead of adopting the canonical base. A
/// `StatefulWidget` whose name ends in `TextButton` is backed by a
/// `State<...>` subclass; the Dart analyzer guarantees that pairing, so the
/// gate is enforced on the backing **state** class: any `State<X>` where `X`
/// is a public class name ending in `TextButton` (declared under
/// [_chromeDirRelative]) must declare `with $_canonicalMixin`.
///
/// SPEC: `SPEC/program/repo-lint.md`.
const _chromeDirRelative = 'app/lib/features/game/widgets/chrome';
const _canonicalMixin = 'CtHoverButtonStateMixin';
const _buttonStateSuffix = 'TextButton';

void main(List<String> args) {
  exit(runCheckChromeButtonBase(Directory.current.path));
}

int runCheckChromeButtonBase(
  String repoRoot, {
  void Function(String line)? info,
  void Function(String line)? err,
}) {
  final logI = info ?? stdout.writeln;
  final logE = err ?? stderr.writeln;

  final chromeDir = Directory(p.join(repoRoot, _chromeDirRelative));
  if (!chromeDir.existsSync()) {
    logE('check_chrome_button_base: $_chromeDirRelative not found.');
    return 1;
  }

  final files = collectRepoLintAppLibDartFilesSorted(repoRoot);
  final violations = <String>[];

  for (final file in files) {
    final relativePath = p
        .relative(file.path, from: repoRoot)
        .replaceAll('\\', '/');
    if (!relativePath.startsWith('$_chromeDirRelative/')) {
      continue;
    }
    if (_shouldSkipPath(relativePath)) {
      continue;
    }

    final content = file.readAsStringSync();
    final parsed = parseString(content: content, path: relativePath);
    final visitor = _ChromeButtonVisitor(
      relativePath: relativePath,
      lineInfo: parsed.unit.lineInfo,
    );
    parsed.unit.accept(visitor);
    violations.addAll(visitor.violations);
  }

  if (violations.isEmpty) {
    logI(
      'check_chrome_button_base: all chrome `*$_buttonStateSuffix` states mix '
      'in $_canonicalMixin.',
    );
    return 0;
  }

  violations.sort();
  logE(
    'check_chrome_button_base: found ${violations.length} chrome '
    '`*$_buttonStateSuffix` state(s) under $_chromeDirRelative not adopting '
    '`with $_canonicalMixin`:',
  );
  for (final v in violations) {
    logE(' - $v');
  }
  logE(
    'Fix: have each `*$_buttonStateSuffix` widget\'s State adopt '
    '`with $_canonicalMixin` (see '
    'app/lib/features/game/widgets/chrome/ct_hover_button.dart) and reuse '
    '`buildHoverButton(...)` instead of re-implementing the hover/disabled '
    'chrome.',
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

class _ChromeButtonVisitor extends RecursiveAstVisitor<void> {
  _ChromeButtonVisitor({required this.relativePath, required this.lineInfo});

  final String relativePath;
  final LineInfo lineInfo;
  final List<String> violations = <String>[];

  @override
  void visitClassDeclaration(ClassDeclaration node) {
    final backedButton = _stateBackedButtonName(node);
    if (backedButton != null && !_mixesInCanonical(node)) {
      final line = lineInfo.getLocation(node.name.offset).lineNumber;
      violations.add(
        '$relativePath:$line: state "${node.name.lexeme}" backs '
        '"$backedButton" but does not adopt `with $_canonicalMixin`.',
      );
    }
    super.visitClassDeclaration(node);
  }

  /// Returns the public `*TextButton` widget name that [node] is the `State`
  /// for, or null when [node] is not such a state class.
  String? _stateBackedButtonName(ClassDeclaration node) {
    final extendsClause = node.extendsClause;
    if (extendsClause == null) return null;
    final superType = extendsClause.superclass;
    if (superType.name.lexeme != 'State') return null;
    final typeArgs = superType.typeArguments?.arguments;
    if (typeArgs == null || typeArgs.length != 1) return null;
    final arg = typeArgs.first;
    if (arg is! NamedType) return null;
    final widgetName = arg.name.lexeme;
    if (widgetName.startsWith('_')) return null;
    if (!widgetName.endsWith(_buttonStateSuffix)) return null;
    return widgetName;
  }

  bool _mixesInCanonical(ClassDeclaration node) {
    final withClause = node.withClause;
    if (withClause == null) return false;
    for (final mixinType in withClause.mixinTypes) {
      if (mixinType.name.lexeme == _canonicalMixin) {
        return true;
      }
    }
    return false;
  }
}
