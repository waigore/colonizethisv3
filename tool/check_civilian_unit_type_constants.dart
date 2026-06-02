import 'dart:io';

import 'package:analyzer/dart/analysis/utilities.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:path/path.dart' as p;

import 'ct_repo_lint_scan_contract.dart';

/// Declarations for [kUnitTypeExplorer], etc. SPEC/game/civilian-units.md.
const _civilianUnitTypeIdsRelPath =
    'packages/colonizethis_models/lib/src/civilian_unit_type_ids.dart';

const _excludedPaths = <String>{
  _civilianUnitTypeIdsRelPath,

  /// Archetype display names; values may match civilian spellings by coincidence.
  'packages/colonizethis_data/lib/src/ai_personality_config.dart',

  /// Hand-maintained app l10n part files (no `flutter gen-l10n` output here):
  /// English display strings such as the naval composition role label
  /// `naval_units_compositionRoleMerchant` are user-facing labels, not
  /// civilian unit-type ids; the same coincident-spelling carve-out as
  /// `ai_personality_config.dart` applies. App code reaches civilian unit
  /// types via `kUnitType*` constants from `colonizethis_models`; the l10n
  /// values here are independent translation strings.
  'app/lib/l10n/app_localizations_en_part1.dart',
  'app/lib/l10n/app_localizations_en_part2.dart',
  'app/lib/l10n/app_localizations_en_part3.dart',
  'app/lib/l10n/app_localizations_en_part4.dart',
  'app/lib/l10n/app_localizations_en_part5.dart',
};

/// Used by `ct_repo_lint` in-process; [info] / [err] default to stdout/stderr.
int runCheckCivilianUnitTypeConstants(
  String repoRoot, {
  List<String>? incrementalRelativeDartPaths,
  void Function(String line)? info,
  void Function(String line)? err,
}) {
  final logI = info ?? stdout.writeln;
  final logE = err ?? stderr.writeln;
  final root = p.normalize(repoRoot);
  final canonicalIds = _loadCanonicalCivilianUnitTypeIds(root);
  if (canonicalIds.isEmpty) {
    logE(
      'ERROR: Could not derive canonical civilian unit type ids from '
      '$_civilianUnitTypeIdsRelPath.',
    );
    return 1;
  }
  final constantNameById = _loadCivilianUnitTypeConstantNames(root);
  final requested = incrementalRelativeDartPaths ?? const <String>[];
  final candidateFiles = _collectCandidateFiles(root, requested);

  final violations = <CivilianUnitTypeConstantViolation>[];
  for (final file in candidateFiles) {
    final relPath = p.normalize(p.relative(file.path, from: root));
    if (repoLintIdentifierLiteralShouldSkipFile(relPath, _excludedPaths)) {
      continue;
    }
    final source = file.readAsStringSync();
    violations.addAll(
      findCivilianUnitTypeConstantViolations(
        relativePath: relPath,
        source: source,
        canonicalCivilianUnitTypeIds: canonicalIds,
        constantNameById: constantNameById,
      ),
    );
  }

  if (violations.isEmpty) {
    logI('Civilian unit type constant usage check passed.');
    return 0;
  }

  logE(
    'ERROR: Found raw civilian unit type string literals in executable code. '
    'Use kUnitType* constants from colonizethis_models.',
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
    runCheckCivilianUnitTypeConstants(
      Directory.current.path,
      incrementalRelativeDartPaths: parsedArgs.files.isEmpty
          ? null
          : parsedArgs.files,
    ),
  );
}

List<CivilianUnitTypeConstantViolation> findCivilianUnitTypeConstantViolations({
  required String relativePath,
  required String source,
  required Set<String> canonicalCivilianUnitTypeIds,
  required Map<String, String> constantNameById,
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
  final visitor = _CivilianUnitTypeLiteralVisitor(
    path: relativePath,
    unit: parsed.unit,
    canonicalCivilianUnitTypeIds: canonicalCivilianUnitTypeIds,
    constantNameById: constantNameById,
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

Set<String> _loadCanonicalCivilianUnitTypeIds(String root) {
  final absPath = p.join(root, _civilianUnitTypeIdsRelPath);
  final file = File(absPath);
  if (!file.existsSync()) {
    return const {};
  }
  final source = file.readAsStringSync();
  final parsed = parseString(
    content: source,
    path: absPath,
    throwIfDiagnostics: false,
  );
  final collector = _CivilianUnitTypeConstantCollector();
  parsed.unit.visitChildren(collector);
  return collector.constantNameById.keys.toSet();
}

Map<String, String> _loadCivilianUnitTypeConstantNames(String root) {
  final absPath = p.join(root, _civilianUnitTypeIdsRelPath);
  final file = File(absPath);
  if (!file.existsSync()) {
    return const {};
  }
  final source = file.readAsStringSync();
  final parsed = parseString(
    content: source,
    path: absPath,
    throwIfDiagnostics: false,
  );
  final collector = _CivilianUnitTypeConstantCollector();
  parsed.unit.visitChildren(collector);
  return collector.constantNameById;
}

class _CivilianUnitTypeConstantCollector extends RecursiveAstVisitor<void> {
  final Map<String, String> constantNameById = <String, String>{};

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
      if (!variableName.startsWith('kUnitType')) {
        continue;
      }
      constantNameById[initializer.value] = variableName;
    }
    super.visitTopLevelVariableDeclaration(node);
  }
}

class _CivilianUnitTypeLiteralVisitor extends RecursiveAstVisitor<void> {
  _CivilianUnitTypeLiteralVisitor({
    required this.path,
    required this.unit,
    required this.canonicalCivilianUnitTypeIds,
    required this.constantNameById,
  });

  final String path;
  final CompilationUnit unit;
  final Set<String> canonicalCivilianUnitTypeIds;
  final Map<String, String> constantNameById;
  final List<CivilianUnitTypeConstantViolation> violations =
      <CivilianUnitTypeConstantViolation>[];

  @override
  void visitSimpleStringLiteral(SimpleStringLiteral node) {
    if (!_isExecutableLiteral(node)) {
      return;
    }
    final value = node.value;
    if (!canonicalCivilianUnitTypeIds.contains(value)) {
      return;
    }
    final location = unit.lineInfo.getLocation(node.offset);
    final suggestedConstant = constantNameById[value];
    final suggestion = suggestedConstant == null
        ? 'Use a kUnitType* constant from colonizethis_models.'
        : 'Use $suggestedConstant from colonizethis_models.';
    violations.add(
      CivilianUnitTypeConstantViolation(
        path: path,
        line: location.lineNumber,
        column: location.columnNumber,
        message: 'raw civilian unit type literal "$value". $suggestion',
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

class CivilianUnitTypeConstantViolation {
  const CivilianUnitTypeConstantViolation({
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
