import 'dart:io';

import 'package:analyzer/dart/analysis/utilities.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:path/path.dart' as p;

import 'ct_repo_lint_scan_contract.dart';

const _excludedPaths = <String>{};

/// [incrementalRelativeDartPaths]: when non-null and non-empty, only those
/// paths (repo-relative) are scanned; otherwise full scan.
///
/// Used by `ct_repo_lint` in-process; [info] / [err] default to stdout/stderr.
/// Returns 0 = pass, 1 = violations or missing catalog, 2 = bad CLI args (CLI only).
int runCheckTechIdConstants(
  String repoRoot, {
  List<String>? incrementalRelativeDartPaths,
  void Function(String line)? info,
  void Function(String line)? err,
}) {
  final logI = info ?? stdout.writeln;
  final logE = err ?? stderr.writeln;
  final root = p.normalize(repoRoot);
  final constantNameByTechId = _loadTechIdConstantNames(root);
  final techIds = constantNameByTechId.keys.toSet();
  if (techIds.isEmpty) {
    logE(
      'ERROR: Could not load canonical tech ID strings from '
      'packages/colonizethis_data/lib/src/tech_ids.dart.',
    );
    return 1;
  }
  final requested = incrementalRelativeDartPaths ?? const <String>[];
  final candidateFiles = _collectCandidateFiles(root, requested);

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
    logI('Tech ID constant usage check passed.');
    return 0;
  }

  logE(
    'ERROR: Found raw tech ID string literals in executable code. '
    'Use constants/declarations from colonizethis_data instead.',
  );
  for (final violation in violations) {
    logE(
      '${violation.path}:${violation.line}:${violation.column} '
      '${violation.message}',
    );
  }
  return 1;
}

void main(List<String> args) {
  final parsedArgs = _parseArgs(args);
  exit(
    runCheckTechIdConstants(
      Directory.current.path,
      incrementalRelativeDartPaths: parsedArgs.files.isEmpty
          ? null
          : parsedArgs.files,
    ),
  );
}

_ParsedArgs _parseArgs(List<String> args) {
  return _ParsedArgs(files: repoLintStrictIncrementalFilesArgListOrExit(args));
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
