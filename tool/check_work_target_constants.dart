import 'dart:io';

import 'package:analyzer/dart/analysis/utilities.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:path/path.dart' as p;

import 'ct_repo_lint_scan_contract.dart';

const _workTargetConstantsRelPath =
    'packages/colonizethis_logic/lib/src/constants.dart';

const _excludedPaths = <String>{
  _workTargetConstantsRelPath,
  'app/lib/l10n/app_localizations_en.dart',
  'app/lib/widgetbook.dart',
  'app/lib/widgetbook/catalog.dart',
  'packages/colonizethis_data/lib/src/work_order_costs.dart',
};

/// Used by `ct_repo_lint` in-process; [info] / [err] default to stdout/stderr.
int runCheckWorkTargetConstants(
  String repoRoot, {
  List<String>? incrementalRelativeDartPaths,
  void Function(String line)? info,
  void Function(String line)? err,
}) {
  final logI = info ?? stdout.writeln;
  final logE = err ?? stderr.writeln;
  final root = p.normalize(repoRoot);
  final canonicalWorkTargets = _loadCanonicalWorkTargets(root);
  if (canonicalWorkTargets.isEmpty) {
    logE(
      'ERROR: Could not derive canonical work target IDs from '
      '$_workTargetConstantsRelPath.',
    );
    return 1;
  }
  final constantNameByWorkTarget = _loadWorkTargetConstantNames(root);
  final requested = incrementalRelativeDartPaths ?? const <String>[];
  final candidateFiles = _collectCandidateFiles(root, requested);

  final violations = <WorkTargetConstantViolation>[];
  for (final file in candidateFiles) {
    final relPath = p.normalize(p.relative(file.path, from: root));
    if (repoLintIdentifierLiteralShouldSkipFile(relPath, _excludedPaths)) {
      continue;
    }
    final source = file.readAsStringSync();
    violations.addAll(
      findWorkTargetConstantViolations(
        relativePath: relPath,
        source: source,
        canonicalWorkTargets: canonicalWorkTargets,
        constantNameByWorkTarget: constantNameByWorkTarget,
      ),
    );
  }

  if (violations.isEmpty) {
    logI('Work target constant usage check passed.');
    return 0;
  }

  logE(
    'ERROR: Found raw work target string literals in executable code. '
    'Use constants from colonizethis_logic.',
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
    runCheckWorkTargetConstants(
      Directory.current.path,
      incrementalRelativeDartPaths: parsedArgs.files.isEmpty
          ? null
          : parsedArgs.files,
    ),
  );
}

List<WorkTargetConstantViolation> findWorkTargetConstantViolations({
  required String relativePath,
  required String source,
  required Set<String> canonicalWorkTargets,
  required Map<String, String> constantNameByWorkTarget,
}) {
  if (!relativePath.endsWith('.dart')) {
    return const [];
  }
  if (repoLintIdentifierLiteralShouldSkipFile(relativePath, _excludedPaths)) {
    return const [];
  }
  final parsed = parseString(
    content: source,
    path: relativePath,
    throwIfDiagnostics: false,
  );
  final visitor = _WorkTargetLiteralVisitor(
    path: relativePath,
    unit: parsed.unit,
    canonicalWorkTargets: canonicalWorkTargets,
    constantNameByWorkTarget: constantNameByWorkTarget,
  );
  parsed.unit.visitChildren(visitor);
  return visitor.violations;
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

Set<String> _loadCanonicalWorkTargets(String root) {
  final constantsAbsPath = p.join(root, _workTargetConstantsRelPath);
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
  final collector = _WorkTargetConstantCollector();
  parsed.unit.visitChildren(collector);
  return collector.constantNameByWorkTarget.keys.toSet();
}

Map<String, String> _loadWorkTargetConstantNames(String root) {
  final constantsAbsPath = p.join(root, _workTargetConstantsRelPath);
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
  final collector = _WorkTargetConstantCollector();
  parsed.unit.visitChildren(collector);
  return collector.constantNameByWorkTarget;
}

class _WorkTargetConstantCollector extends RecursiveAstVisitor<void> {
  final Map<String, String> constantNameByWorkTarget = <String, String>{};

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
      if (!variableName.startsWith('kWorkTarget')) {
        continue;
      }
      constantNameByWorkTarget[initializer.value] = variableName;
    }
    super.visitTopLevelVariableDeclaration(node);
  }
}

class _WorkTargetLiteralVisitor extends RecursiveAstVisitor<void> {
  _WorkTargetLiteralVisitor({
    required this.path,
    required this.unit,
    required this.canonicalWorkTargets,
    required this.constantNameByWorkTarget,
  });

  final String path;
  final CompilationUnit unit;
  final Set<String> canonicalWorkTargets;
  final Map<String, String> constantNameByWorkTarget;
  final List<WorkTargetConstantViolation> violations =
      <WorkTargetConstantViolation>[];

  @override
  void visitSimpleStringLiteral(SimpleStringLiteral node) {
    if (!_isExecutableLiteral(node)) {
      return;
    }
    final value = node.value;
    if (!canonicalWorkTargets.contains(value)) {
      return;
    }
    final location = unit.lineInfo.getLocation(node.offset);
    final suggestedConstant = constantNameByWorkTarget[value];
    final suggestion = suggestedConstant == null
        ? 'Use a kWorkTarget* constant from colonizethis_logic.'
        : 'Use $suggestedConstant from colonizethis_logic.';
    violations.add(
      WorkTargetConstantViolation(
        path: path,
        line: location.lineNumber,
        column: location.columnNumber,
        message: 'raw work target literal "$value". $suggestion',
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

class WorkTargetConstantViolation {
  const WorkTargetConstantViolation({
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
