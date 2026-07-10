import 'dart:io';

import 'package:analyzer/dart/analysis/utilities.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/source/line_info.dart';
import 'package:path/path.dart' as p;

/// PR-blocking dedup gate for Yarn [AssetBundle] fakes in dialogue overlay
/// tests (Refs #3952).
///
/// Canonical fakes live in `app/test/support/yarn_test_fixtures.dart`
/// (`YarnStringAssetBundle`, `YarnInlineAssetBundle`,
/// `YarnThrowingAssetBundle`, `YarnMissingNodeAssetBundle`). Re-declaring
/// `class _*AssetBundle extends Fake implements AssetBundle` (or the same
/// shape without the leading underscore) outside `app/test/support/` in
/// dialogue / yarn / overlay test paths fails CI.
int runCheckAppTestNoDuplicateYarnBundle(
  String repoRoot, {
  void Function(String line)? info,
  void Function(String line)? err,
}) {
  final logI = info ?? stdout.writeln;
  final logE = err ?? stderr.writeln;

  final appTestDir = Directory(p.join(repoRoot, 'app', 'test'));
  if (!appTestDir.existsSync()) {
    logI(
      'check_app_test_no_duplicate_yarn_bundle: app/test not found; nothing to '
      'scan.',
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
    if (!_isGovernedDialogueOverlayTest(relativePath)) {
      continue;
    }
    final content = entity.readAsStringSync();
    final parsed = parseString(content: content, path: relativePath);
    final visitor = _YarnBundleVisitor(
      relativePath: relativePath,
      lineInfo: parsed.unit.lineInfo,
      violations: violations,
    );
    parsed.unit.accept(visitor);
  }

  if (violations.isEmpty) {
    logI(
      'check_app_test_no_duplicate_yarn_bundle: no duplicated Yarn AssetBundle '
      'fakes found.',
    );
    return 0;
  }

  violations.sort();
  logE(
    'check_app_test_no_duplicate_yarn_bundle: found ${violations.length} '
    'violation(s):',
  );
  for (final v in violations) {
    logE(' - $v');
  }
  logE(
    '   Use YarnStringAssetBundle / YarnInlineAssetBundle / '
    'YarnThrowingAssetBundle / YarnMissingNodeAssetBundle from '
    'app/test/support/yarn_test_fixtures.dart.',
  );
  return 1;
}

/// Dialogue / yarn / overlay widget tests outside `app/test/support/`.
bool _isGovernedDialogueOverlayTest(String relativePath) {
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
  final name = p.basename(relativePath).toLowerCase();
  final isDialogueFamily = name.contains('dialogue') ||
      name.contains('yarn') ||
      name.contains('overlay') ||
      name.contains('tribe_first_contact') ||
      name.contains('intervention') ||
      name.contains('game_start_intro');
  return isDialogueFamily && name.endsWith('_test.dart');
}

class _YarnBundleVisitor extends RecursiveAstVisitor<void> {
  _YarnBundleVisitor({
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
    final lower = name.toLowerCase();
    if (!lower.contains('assetbundle')) {
      super.visitClassDeclaration(node);
      return;
    }
    final extendsClause = node.extendsClause;
    final implementsClause = node.implementsClause;
    final extendsFake = extendsClause != null &&
        extendsClause.superclass.name2.lexeme == 'Fake';
    final implementsAssetBundle = implementsClause != null &&
        implementsClause.interfaces.any(
          (NamedType t) => t.name2.lexeme == 'AssetBundle',
        );
    if (extendsFake && implementsAssetBundle) {
      _report(
        node.name.offset,
        'class "$name" duplicates Yarn*AssetBundle fakes in '
        'yarn_test_fixtures.dart',
      );
    }
    super.visitClassDeclaration(node);
  }
}

void main(List<String> args) {
  final repoRoot = args.isNotEmpty ? args.first : Directory.current.path;
  exit(runCheckAppTestNoDuplicateYarnBundle(repoRoot));
}
