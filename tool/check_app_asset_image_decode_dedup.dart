import 'dart:io';

import 'package:analyzer/dart/analysis/utilities.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/source/line_info.dart';
import 'package:path/path.dart' as p;

import 'ct_repo_lint_scan_contract.dart';

/// PR-blocking structural gate for the shared Flame asset-image decode helper
/// and the `AssetImageCache` base (Refs #3699 target state #1 & #2).
///
/// Two invariants are enforced across `app/lib/**`:
///
/// 1. The `ui.decodeImageFromList(...)` PNG-decode idiom may appear **only** in
///    the canonical helper file [_decodeHelperRelative] (which exposes
///    `decodeImageAsset(...)`). Every icon cache and tileset must route decode
///    through that helper instead of re-inlining the
///    `rootBundle.load` -> `Completer` -> `decodeImageFromList` sequence.
/// 2. Every concrete icon cache (a public class declared in a
///    `*_icon_cache.dart` file whose name ends with `IconCache`) must declare
///    `extends $_cacheBaseName` so the load lifecycle / flags / logging / decode
///    fan-out stay single-sourced in [AssetImageCache].
///
/// SPEC: `SPEC/program/repo-lint.md`.
const _decodeHelperRelative =
    'app/lib/features/game/flame/asset_image_cache.dart';
const _decodeMethodName = 'decodeImageFromList';
const _cacheBaseName = 'AssetImageCache';
const _iconCacheFileSuffix = '_icon_cache.dart';
const _iconCacheClassSuffix = 'IconCache';

void main(List<String> args) {
  exit(runCheckAppAssetImageDecodeDedup(Directory.current.path));
}

int runCheckAppAssetImageDecodeDedup(
  String repoRoot, {
  void Function(String line)? info,
  void Function(String line)? err,
}) {
  final logI = info ?? stdout.writeln;
  final logE = err ?? stderr.writeln;

  final flameDir = Directory(
    p.join(repoRoot, 'app', 'lib', 'features', 'game', 'flame'),
  );
  if (!flameDir.existsSync()) {
    logE(
      'check_app_asset_image_decode_dedup: '
      'app/lib/features/game/flame not found.',
    );
    return 1;
  }

  final files = collectRepoLintAppLibDartFilesSorted(repoRoot);
  final violations = <String>[];

  for (final file in files) {
    final relativePath = p
        .relative(file.path, from: repoRoot)
        .replaceAll('\\', '/');
    if (_shouldSkipPath(relativePath)) {
      continue;
    }

    final content = file.readAsStringSync();
    final parsed = parseString(content: content, path: relativePath);
    final visitor = _AssetImageDecodeVisitor(
      relativePath: relativePath,
      lineInfo: parsed.unit.lineInfo,
    );
    parsed.unit.accept(visitor);

    for (final line in visitor.decodeInvocationLines) {
      if (relativePath != _decodeHelperRelative) {
        violations.add(
          '$relativePath:$line: inlines `$_decodeMethodName(...)`; route the '
          'decode through `decodeImageAsset(...)` in $_decodeHelperRelative '
          'instead.',
        );
      }
    }

    if (relativePath.endsWith(_iconCacheFileSuffix)) {
      for (final missing in visitor.iconCachesMissingBase) {
        violations.add(
          '$relativePath:${missing.line}: class "${missing.name}" does not '
          'adopt `extends $_cacheBaseName`.',
        );
      }
    }
  }

  if (violations.isEmpty) {
    logI(
      'check_app_asset_image_decode_dedup: `$_decodeMethodName` is confined to '
      '$_decodeHelperRelative and all `*IconCache` classes extend '
      '$_cacheBaseName.',
    );
    return 0;
  }

  violations.sort();
  logE(
    'check_app_asset_image_decode_dedup: found ${violations.length} '
    'violation(s):',
  );
  for (final v in violations) {
    logE(' - $v');
  }
  logE(
    'Fix: call `decodeImageAsset(assetPath)` from '
    '$_decodeHelperRelative instead of inlining `$_decodeMethodName`, and have '
    'each `*IconCache` cache `extends $_cacheBaseName` (supplying only '
    '`assetIds`, `assetPath(...)`, and `loadLogLabel`).',
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

class _IconCacheViolation {
  _IconCacheViolation(this.name, this.line);
  final String name;
  final int line;
}

class _AssetImageDecodeVisitor extends RecursiveAstVisitor<void> {
  _AssetImageDecodeVisitor({
    required this.relativePath,
    required this.lineInfo,
  });

  final String relativePath;
  final LineInfo lineInfo;
  final List<int> decodeInvocationLines = <int>[];
  final List<_IconCacheViolation> iconCachesMissingBase =
      <_IconCacheViolation>[];

  @override
  void visitMethodInvocation(MethodInvocation node) {
    if (node.methodName.name == _decodeMethodName) {
      decodeInvocationLines.add(
        lineInfo.getLocation(node.methodName.offset).lineNumber,
      );
    }
    super.visitMethodInvocation(node);
  }

  @override
  void visitClassDeclaration(ClassDeclaration node) {
    final name = node.name.lexeme;
    final isConcreteIconCache =
        !name.startsWith('_') &&
        name != _cacheBaseName &&
        name.endsWith(_iconCacheClassSuffix);
    if (isConcreteIconCache && !_extendsBase(node)) {
      iconCachesMissingBase.add(
        _IconCacheViolation(
          name,
          lineInfo.getLocation(node.name.offset).lineNumber,
        ),
      );
    }
    super.visitClassDeclaration(node);
  }

  bool _extendsBase(ClassDeclaration node) {
    final extendsClause = node.extendsClause;
    if (extendsClause == null) return false;
    return extendsClause.superclass.name.lexeme == _cacheBaseName;
  }
}
