import 'dart:io';

import 'package:analyzer/dart/analysis/utilities.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:path/path.dart' as p;

const _scanRoots = <String>['app', 'ctterm', 'packages', 'tool'];

const _excludedPaths = <String>{
  'packages/colonizethis_data/lib/src/tech_catalog.dart',
  'packages/colonizethis_data/lib/src/tech_extraction.dart',
  'packages/colonizethis_data/lib/src/combat_config.dart',
  'app/lib/features/game/widgets/tech_tree_widget.dart',
  'app/lib/features/game/widgets/province_panel_labels.dart',
  'tool/sim_scenarios/lib/scenario_runner.dart',
};

const _excludedDirMarkers = <String>[
  '/test_data/',
  '/testdata/',
  '/fixtures/',
  '/fixture/',
  '/golden/',
  '/goldens/',
];

void main() {
  final root = p.normalize(Directory.current.path);
  final techIds = _loadCanonicalTechIds(root);
  if (techIds.isEmpty) {
    stderr.writeln(
      'ERROR: Could not derive canonical tech IDs from '
      'packages/colonizethis_data/lib/src/tech_catalog.dart.',
    );
    exit(1);
  }

  final violations = <_Violation>[];
  for (final relRoot in _scanRoots) {
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
      if (_shouldSkipFile(relPath)) {
        continue;
      }
      final source = entity.readAsStringSync();
      final parsed = parseString(
        content: source,
        path: entity.path,
        throwIfDiagnostics: false,
      );
      final visitor = _TechIdLiteralVisitor(
        path: relPath,
        unit: parsed.unit,
        techIds: techIds,
      );
      parsed.unit.visitChildren(visitor);
      violations.addAll(visitor.violations);
    }
  }

  if (violations.isEmpty) {
    stdout.writeln('Tech ID constant usage check passed.');
    exit(0);
  }

  stderr.writeln(
    'ERROR: Found raw tech ID string literals in executable code. '
    'Use constants/declarations from colonizethis_data instead.',
  );
  for (final violation in violations) {
    stderr.writeln(
      '${violation.path}:${violation.line}:${violation.column} '
      '${violation.message}',
    );
  }
  exit(1);
}

bool _shouldSkipFile(String relPath) {
  final normalized = '/${relPath.replaceAll('\\', '/')}';
  if (!normalized.contains('/lib/')) {
    return true;
  }
  if (_excludedPaths.contains(relPath)) {
    return true;
  }
  if (relPath.endsWith('.g.dart') ||
      relPath.endsWith('.freezed.dart') ||
      relPath.endsWith('.mocks.dart') ||
      relPath.endsWith('.gen.dart')) {
    return true;
  }
  for (final marker in _excludedDirMarkers) {
    if (normalized.contains(marker)) {
      return true;
    }
  }
  return false;
}

Set<String> _loadCanonicalTechIds(String root) {
  final catalogRelPath = 'packages/colonizethis_data/lib/src/tech_catalog.dart';
  final catalogAbsPath = p.join(root, catalogRelPath);
  final file = File(catalogAbsPath);
  if (!file.existsSync()) {
    return const {};
  }
  final source = file.readAsStringSync();
  final parsed = parseString(
    content: source,
    path: catalogAbsPath,
    throwIfDiagnostics: false,
  );
  final collector = _TechCatalogIdCollector();
  parsed.unit.visitChildren(collector);
  return collector.ids;
}

class _TechCatalogIdCollector extends RecursiveAstVisitor<void> {
  final Set<String> ids = <String>{};

  @override
  void visitAssignmentExpression(AssignmentExpression node) {
    final left = node.leftHandSide;
    if (left is IndexExpression &&
        _isIdentifierNamed(left.target, 'm') &&
        left.index is SimpleStringLiteral) {
      final index = left.index as SimpleStringLiteral;
      if (index.value.isNotEmpty) {
        ids.add(index.value);
      }
    }
    super.visitAssignmentExpression(node);
  }

  bool _isIdentifierNamed(Expression? expression, String name) {
    return expression is SimpleIdentifier && expression.name == name;
  }
}

class _TechIdLiteralVisitor extends RecursiveAstVisitor<void> {
  _TechIdLiteralVisitor({
    required this.path,
    required this.unit,
    required this.techIds,
  });

  final String path;
  final CompilationUnit unit;
  final Set<String> techIds;
  final List<_Violation> violations = <_Violation>[];

  @override
  void visitSimpleStringLiteral(SimpleStringLiteral node) {
    if (!_isExecutableLiteral(node)) {
      return;
    }
    final value = node.value;
    if (!techIds.contains(value)) {
      return;
    }
    final location = unit.lineInfo.getLocation(node.offset);
    violations.add(
      _Violation(
        path: path,
        line: location.lineNumber,
        column: location.columnNumber,
        message: 'raw tech ID literal "$value"',
      ),
    );
  }

  bool _isExecutableLiteral(AstNode node) {
    AstNode? cursor = node.parent;
    while (cursor != null) {
      if (cursor is Annotation || cursor is Comment) {
        return false;
      }
      if (cursor is FunctionBody) {
        return true;
      }
      if (cursor is ConstructorInitializer) {
        return true;
      }
      if (cursor is TopLevelVariableDeclaration || cursor is FieldDeclaration) {
        return false;
      }
      cursor = cursor.parent;
    }
    return false;
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
