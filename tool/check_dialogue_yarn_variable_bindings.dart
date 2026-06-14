import 'dart:io';

import 'package:analyzer/dart/analysis/utilities.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:path/path.dart' as p;

/// Jenny stores Yarn variables under their `$`-prefixed name, so a Yarn asset
/// that interpolates `{$tribeName}` only resolves when the loading Dart overlay
/// binds `setVariable(r'$tribeName', …)`. Binding without the `$` prefix raised
/// `NameError: variable $tribeName is not defined` at runtime and blocked the
/// game (#3463); widget tests using hardcoded strings did not catch it.
///
/// This gate statically cross-references each dialogue overlay against the Yarn
/// assets it loads (via `kDialogue*Asset` constants) and fails when any
/// `{$var}` referenced by an asset is not bound with a matching `$`-prefixed
/// `setVariable` in the overlay that loads it.
///
/// SPEC: SPEC/program/repo-lint.md; SPEC/ui/tribe-first-contact-overlay.md.
const String _assetsDir = 'app/assets/dialogue';
const String _overlaysDir = 'app/lib/features/game/dialogue';
const String _constantsFile = 'app/lib/config/app_constants.dart';

/// `{$identifier}` interpolation tokens inside a Yarn line.
final RegExp _yarnVarPattern = RegExp(r'\{\$([A-Za-z_][A-Za-z0-9_]*)\}');

/// Used by `ct_repo_lint` / `dart run`; [info] / [err] default to std streams.
int runCheckDialogueYarnVariableBindings(
  String repoRoot, {
  void Function(String line)? info,
  void Function(String line)? err,
}) {
  final logI = info ?? stdout.writeln;
  final logE = err ?? stderr.writeln;
  final root = p.normalize(repoRoot);

  final assetsDir = Directory(p.join(root, _assetsDir));
  final overlaysDir = Directory(p.join(root, _overlaysDir));
  final constantsFile = File(p.join(root, _constantsFile));
  if (!assetsDir.existsSync()) {
    logE('check_dialogue_yarn_variable_bindings: missing $assetsDir');
    return 1;
  }
  if (!overlaysDir.existsSync()) {
    logE('check_dialogue_yarn_variable_bindings: missing $overlaysDir');
    return 1;
  }
  if (!constantsFile.existsSync()) {
    logE('check_dialogue_yarn_variable_bindings: missing $constantsFile');
    return 1;
  }

  // const name -> root-relative asset path (only `.yarn` assets).
  final constantToAssetPath = _readYarnAssetConstants(
    constantsFile.readAsStringSync(),
    relativePath: _constantsFile,
  );

  // root-relative asset path (e.g. assets/dialogue/intervention.yarn) -> vars.
  final assetVars = <String, Set<String>>{};
  for (final file in assetsDir.listSync(followLinks: false)) {
    if (file is! File || !file.path.endsWith('.yarn')) continue;
    final assetKey = p
        .relative(file.path, from: p.join(root, 'app'))
        .replaceAll(r'\', '/');
    assetVars[assetKey] = _yarnVarsIn(file.readAsStringSync());
  }

  final violations = <String>[];
  for (final file in overlaysDir.listSync(recursive: true, followLinks: false)) {
    if (file is! File || !file.path.endsWith('.dart')) continue;
    final relPath = p.normalize(p.relative(file.path, from: root));
    final overlay = _parseOverlay(file.readAsStringSync(), relPath);
    for (final constName in overlay.loadedAssetConstants) {
      final assetPath = constantToAssetPath[constName];
      if (assetPath == null) continue;
      final required = assetVars[assetPath];
      if (required == null) continue;
      for (final varName in required) {
        if (!overlay.boundVars.contains(varName)) {
          violations.add(
            '$relPath loads "$assetPath" but never binds Yarn variable '
            '\$$varName — add setVariable(r\'\$$varName\', …).',
          );
        }
      }
    }
  }

  if (violations.isEmpty) {
    logI('Dialogue Yarn variable binding check passed.');
    return 0;
  }

  logE(
    'ERROR: Yarn `{\$var}` interpolations must be bound via '
    'setVariable(r\'\$var\', …) in the overlay that loads the asset (#3463).',
  );
  for (final v in violations) {
    logE(v);
  }
  return 1;
}

/// Parses `const String kDialogue*Asset = '…';` declarations whose value points
/// at a `.yarn` asset and returns a `constName -> path` map.
Map<String, String> _readYarnAssetConstants(
  String source, {
  required String relativePath,
}) {
  final unit = parseString(
    content: source,
    path: relativePath,
    throwIfDiagnostics: false,
  ).unit;
  final result = <String, String>{};
  for (final decl in unit.declarations) {
    if (decl is! TopLevelVariableDeclaration) continue;
    for (final variable in decl.variables.variables) {
      final initializer = variable.initializer;
      if (initializer is! SimpleStringLiteral) continue;
      final value = initializer.value;
      if (!value.endsWith('.yarn')) continue;
      result[variable.name.lexeme] = value;
    }
  }
  return result;
}

/// All `{$identifier}` variable names referenced in a Yarn asset.
Set<String> _yarnVarsIn(String yarn) {
  return _yarnVarPattern
      .allMatches(yarn)
      .map((m) => m.group(1)!)
      .toSet();
}

class _OverlayBindings {
  _OverlayBindings({
    required this.loadedAssetConstants,
    required this.boundVars,
  });

  /// `kDialogue*Asset` constant names passed to `loadString(...)`.
  final Set<String> loadedAssetConstants;

  /// Variable names (without `$`) passed to `setVariable(r'$var', …)`.
  final Set<String> boundVars;
}

_OverlayBindings _parseOverlay(String source, String relativePath) {
  final unit = parseString(
    content: source,
    path: relativePath,
    throwIfDiagnostics: false,
  ).unit;
  final visitor = _OverlayVisitor();
  unit.accept(visitor);
  return _OverlayBindings(
    loadedAssetConstants: visitor.loadedAssetConstants,
    boundVars: visitor.boundVars,
  );
}

class _OverlayVisitor extends RecursiveAstVisitor<void> {
  final Set<String> loadedAssetConstants = {};
  final Set<String> boundVars = {};

  @override
  void visitMethodInvocation(MethodInvocation node) {
    final name = node.methodName.name;
    final args = node.argumentList.arguments;
    if (name == 'loadString' && args.isNotEmpty) {
      final first = args.first;
      if (first is SimpleIdentifier) {
        loadedAssetConstants.add(first.name);
      }
    } else if (name == 'setVariable' && args.isNotEmpty) {
      final first = args.first;
      if (first is SimpleStringLiteral && first.value.startsWith(r'$')) {
        boundVars.add(first.value.substring(1));
      }
    }
    super.visitMethodInvocation(node);
  }
}

void main() {
  exit(runCheckDialogueYarnVariableBindings(Directory.current.path));
}
