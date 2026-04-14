import 'dart:io';

import 'package:analyzer/dart/analysis/utilities.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:path/path.dart' as p;

const _scannedRoots = <String>['app/lib'];

const _excludedPaths = <String>{
  'app/lib/config/app_assets.dart',
  'app/lib/config/app_constants.dart',
};

/// One direct `assets/...` or `packages/.../assets/...` string literal violation.
final class AssetPathConstantViolation {
  const AssetPathConstantViolation({
    required this.path,
    required this.line,
    required this.column,
    required this.message,
  });

  final String path;
  final int line;
  final int column;
  final String message;
}

/// Parses [source] as a compilation unit and returns violations for [relativePath].
///
/// Used by unit tests; [relativePath] is repo-relative (POSIX-style). The constants
/// file `app/lib/config/app_assets.dart` is never flagged.
List<AssetPathConstantViolation> findAssetPathConstantViolationsInSource({
  required String relativePath,
  required String source,
}) {
  if (_excludedPaths.contains(relativePath)) {
    return const [];
  }
  final parsed = parseString(
    content: source,
    path: relativePath,
    throwIfDiagnostics: false,
  );
  final visitor = _AssetLiteralVisitor(path: relativePath, unit: parsed.unit);
  parsed.unit.visitChildren(visitor);
  return visitor.violations;
}

/// Used by `ct_repo_lint` in-process; [info] / [err] default to stdout/stderr.
int runCheckAssetPathConstants(
  String repoRoot, {
  void Function(String line)? info,
  void Function(String line)? err,
}) {
  final logI = info ?? stdout.writeln;
  final logE = err ?? stderr.writeln;
  final root = p.normalize(repoRoot);
  final violations = <AssetPathConstantViolation>[];

  for (final relRoot in _scannedRoots) {
    final absRoot = p.join(root, relRoot);
    final dir = Directory(absRoot);
    if (!dir.existsSync()) {
      continue;
    }
    for (final entity in dir.listSync(recursive: true, followLinks: false)) {
      if (entity is! File || !entity.path.endsWith('.dart')) {
        continue;
      }
      final relPath = p.normalize(p.relative(entity.path, from: root));
      if (_excludedPaths.contains(relPath)) {
        continue;
      }
      final src = entity.readAsStringSync();
      violations.addAll(
        findAssetPathConstantViolationsInSource(
          relativePath: relPath,
          source: src,
        ),
      );
    }
  }

  if (violations.isEmpty) {
    logI('Asset path constant check passed.');
    return 0;
  }

  logE(
    'ERROR: Found direct asset path literals. Use constants from '
    'app/lib/config/app_assets.dart or app/lib/config/app_constants.dart instead.',
  );
  for (final v in violations) {
    logE('${v.path}:${v.line}:${v.column} ${v.message}');
  }
  return 1;
}

void main() {
  exit(runCheckAssetPathConstants(Directory.current.path));
}

class _AssetLiteralVisitor extends RecursiveAstVisitor<void> {
  _AssetLiteralVisitor({required this.path, required this.unit});

  final String path;
  final CompilationUnit unit;
  final List<AssetPathConstantViolation> violations = [];

  @override
  void visitSimpleStringLiteral(SimpleStringLiteral node) {
    _checkLiteral(
      node.value,
      node,
      isPackageAsset: _isPackageAsset(node.value),
    );
  }

  @override
  void visitStringInterpolation(StringInterpolation node) {
    if (node.elements.isEmpty) {
      return;
    }
    final firstElement = node.elements.first;
    if (firstElement is! InterpolationString) {
      return;
    }
    final first = firstElement;
    final prefix = first.value;
    _checkLiteral(prefix, first, isPackageAsset: _isPackageAsset(prefix));
  }

  bool _isPackageAsset(String value) {
    if (!value.startsWith('packages/')) {
      return false;
    }
    final parts = value.split('/');
    return parts.length >= 3 && parts[2] == 'assets';
  }

  void _checkLiteral(
    String value,
    AstNode node, {
    required bool isPackageAsset,
  }) {
    final isDirectAsset = value.startsWith('assets/');
    final isCandidate = isDirectAsset || isPackageAsset;
    if (!isCandidate) {
      return;
    }
    final location = unit.lineInfo.getLocation(node.offset);
    violations.add(
      AssetPathConstantViolation(
        path: path,
        line: location.lineNumber,
        column: location.columnNumber,
        message: 'direct asset path literal "$value"',
      ),
    );
  }
}
