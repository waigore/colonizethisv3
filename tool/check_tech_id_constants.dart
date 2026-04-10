import 'dart:io';

import 'package:analyzer/dart/analysis/utilities.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:path/path.dart' as p;

import 'ct_repo_lint_scan_contract.dart';

const _argFiles = '--files';

const _excludedPaths = <String>{
  'packages/colonizethis_data/lib/src/tech_catalog.dart',
  'packages/colonizethis_data/lib/src/tech_extraction.dart',
  'packages/colonizethis_data/lib/src/combat_config.dart',
  'app/lib/features/game/widgets/tech_tree_widget.dart',
  'app/lib/features/game/widgets/province_panel_labels.dart',
  'tool/sim_scenarios/lib/scenario_runner.dart',
};

void main(List<String> args) {
  final parsedArgs = _parseArgs(args);
  final root = p.normalize(Directory.current.path);
  final techIds = _loadCanonicalTechIds(root);
  if (techIds.isEmpty) {
    stderr.writeln(
      'ERROR: Could not derive canonical tech IDs from '
      'packages/colonizethis_data/lib/src/tech_catalog.dart.',
    );
    exit(1);
  }
  final constantNameByTechId = _loadTechIdConstantNames(root);
  final candidateFiles = _collectCandidateFiles(root, parsedArgs.files);

  final violations = <_Violation>[];
  for (final file in candidateFiles) {
    final relPath = p.normalize(p.relative(file.path, from: root));
    if (repoLintIdentifierLiteralShouldSkipFile(relPath, _excludedPaths)) {
      continue;
    }
    final source = file.readAsStringSync();
    final parsed = parseString(
      content: source,
      path: file.path,
      throwIfDiagnostics: false,
    );
    final visitor = _TechIdLiteralVisitor(
      path: relPath,
      unit: parsed.unit,
      techIds: techIds,
      constantNameByTechId: constantNameByTechId,
    );
    parsed.unit.visitChildren(visitor);
    violations.addAll(visitor.violations);
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

_ParsedArgs _parseArgs(List<String> args) {
  String? filesArgValue;
  for (var i = 0; i < args.length; i++) {
    final arg = args[i];
    if (arg == _argFiles) {
      if (i + 1 >= args.length) {
        stderr.writeln('ERROR: Missing value for $_argFiles.');
        exit(2);
      }
      filesArgValue = args[i + 1];
      i++;
      continue;
    }
    if (arg.startsWith('$_argFiles=')) {
      filesArgValue = arg.substring('$_argFiles='.length);
      continue;
    }
    stderr.writeln(
      'ERROR: Unsupported argument "$arg". Supported: $_argFiles '
      '(comma-separated or newline-separated relative paths).',
    );
    exit(2);
  }
  return _ParsedArgs(
    files: filesArgValue == null ? const [] : _splitFileArg(filesArgValue),
  );
}

List<String> _splitFileArg(String value) {
  if (value.trim().isEmpty) {
    return const [];
  }
  final normalized = value.replaceAll('\r\n', '\n').replaceAll('\r', '\n');
  return normalized
      .split(RegExp('[,\n]'))
      .map((entry) => entry.trim())
      .where((entry) => entry.isNotEmpty)
      .toList(growable: false);
}

List<File> _collectCandidateFiles(String root, List<String> requestedPaths) {
  if (requestedPaths.isEmpty) {
    return collectRepoLintDartFilesUnderRelativeRoots(
      root,
      repoLintIdentifierLiteralScanRoots,
    );
  }

  final files = <File>[];
  for (final relPath in requestedPaths) {
    if (!relPath.endsWith('.dart')) {
      continue;
    }
    final normalizedRelPath = p.normalize(relPath);
    if (!repoLintPathIsUnderLiteralScanRoots(
      normalizedRelPath,
      repoLintIdentifierLiteralScanRoots,
    )) {
      continue;
    }
    final file = File(p.join(root, normalizedRelPath));
    if (file.existsSync()) {
      files.add(file);
    }
  }
  return files;
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

Map<String, String> _loadTechIdConstantNames(String root) {
  final constantsRelPath = 'packages/colonizethis_data/lib/src/tech_ids.dart';
  final constantsAbsPath = p.join(root, constantsRelPath);
  final file = File(constantsAbsPath);
  if (!file.existsSync()) {
    return const {};
  }
  final source = file.readAsStringSync();
  final parsed = parseString(
    content: source,
    path: constantsAbsPath,
    throwIfDiagnostics: false,
  );
  final collector = _TechIdConstantCollector();
  parsed.unit.visitChildren(collector);
  return collector.constantNameByTechId;
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

class _TechIdConstantCollector extends RecursiveAstVisitor<void> {
  final Map<String, String> constantNameByTechId = <String, String>{};

  @override
  void visitTopLevelVariableDeclaration(TopLevelVariableDeclaration node) {
    for (final variable in node.variables.variables) {
      final initializer = variable.initializer;
      if (initializer is! SimpleStringLiteral) {
        continue;
      }
      if (initializer.value.isEmpty) {
        continue;
      }
      final variableName = variable.name.lexeme;
      if (!variableName.startsWith('kTechId')) {
        continue;
      }
      constantNameByTechId[initializer.value] = variableName;
    }
    super.visitTopLevelVariableDeclaration(node);
  }
}

class _TechIdLiteralVisitor extends RecursiveAstVisitor<void> {
  _TechIdLiteralVisitor({
    required this.path,
    required this.unit,
    required this.techIds,
    required this.constantNameByTechId,
  });

  final String path;
  final CompilationUnit unit;
  final Set<String> techIds;
  final Map<String, String> constantNameByTechId;
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
    final suggestedConstant = constantNameByTechId[value];
    final suggestion = suggestedConstant == null
        ? 'Use a kTechId* constant from colonizethis_data.'
        : 'Use $suggestedConstant from colonizethis_data.';
    violations.add(
      _Violation(
        path: path,
        line: location.lineNumber,
        column: location.columnNumber,
        message: 'raw tech ID literal "$value". $suggestion',
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

class _ParsedArgs {
  const _ParsedArgs({required this.files});

  final List<String> files;
}
