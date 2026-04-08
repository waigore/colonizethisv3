import 'dart:io';

import 'package:analyzer/dart/analysis/utilities.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:path/path.dart' as p;

const _scannedRoots = <String>['app/lib'];

const _excludedPaths = <String>{'app/lib/config/app_assets.dart'};

void main() {
  final cwd = Directory.current.path;
  final root = p.normalize(cwd);
  final violations = <_Violation>[];

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
      final parsed = parseString(
        content: src,
        path: entity.path,
        throwIfDiagnostics: false,
      );
      final visitor = _AssetLiteralVisitor(path: relPath, unit: parsed.unit);
      parsed.unit.visitChildren(visitor);
      violations.addAll(visitor.violations);
    }
  }

  if (violations.isEmpty) {
    stdout.writeln('Asset path constant check passed.');
    exit(0);
  }

  stderr.writeln(
    'ERROR: Found direct asset path literals. Use constants from '
    'app/lib/config/app_assets.dart instead.',
  );
  for (final v in violations) {
    stderr.writeln('${v.path}:${v.line}:${v.column} ${v.message}');
  }
  exit(1);
}

class _AssetLiteralVisitor extends RecursiveAstVisitor<void> {
  _AssetLiteralVisitor({required this.path, required this.unit});

  final String path;
  final CompilationUnit unit;
  final List<_Violation> violations = [];

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
      _Violation(
        path: path,
        line: location.lineNumber,
        column: location.columnNumber,
        message: 'direct asset path literal "$value"',
      ),
    );
  }
}

class _Violation {
  const _Violation({
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
