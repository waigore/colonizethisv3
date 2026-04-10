import 'dart:io';

import 'package:analyzer/dart/analysis/utilities.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:path/path.dart' as p;

const _scanRoots = <String>['app', 'ctterm', 'packages', 'tool'];
const _argFiles = '--files';

/// Declarations for [kUnitTypeExplorer], etc. SPEC/game/civilian-units.md.
const _civilianUnitTypeIdsRelPath =
    'packages/colonizethis_models/lib/src/civilian_unit_type_ids.dart';

const _excludedPaths = <String>{
  _civilianUnitTypeIdsRelPath,
  /// Naval ship category label; same spelling as civilian [kUnitTypeMerchant].
  'ctterm/lib/screens/shipyard_screen.dart',
  /// Archetype display names; values may match civilian spellings by coincidence.
  'packages/colonizethis_data/lib/src/ai_personality_config.dart',
};

const _excludedDirMarkers = <String>[
  '/test_data/',
  '/testdata/',
  '/fixtures/',
  '/fixture/',
  '/golden/',
  '/goldens/',
];

void main(List<String> args) {
  final parsedArgs = _parseArgs(args);
  final root = p.normalize(Directory.current.path);
  final canonicalIds = _loadCanonicalCivilianUnitTypeIds(root);
  if (canonicalIds.isEmpty) {
    stderr.writeln(
      'ERROR: Could not derive canonical civilian unit type ids from '
      '$_civilianUnitTypeIdsRelPath.',
    );
    exit(1);
  }
  final constantNameById = _loadCivilianUnitTypeConstantNames(root);
  final candidateFiles = _collectCandidateFiles(root, parsedArgs.files);

  final violations = <CivilianUnitTypeConstantViolation>[];
  for (final file in candidateFiles) {
    final relPath = p.normalize(p.relative(file.path, from: root));
    if (_shouldSkipFile(relPath)) {
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
    stdout.writeln('Civilian unit type constant usage check passed.');
    exit(0);
  }

  stderr.writeln(
    'ERROR: Found raw civilian unit type string literals in executable code. '
    'Use kUnitType* constants from colonizethis_models.',
  );
  for (final violation in violations) {
    stderr.writeln(
      '${violation.path}:${violation.line}:${violation.column} '
      '${violation.message}',
    );
  }
  exit(1);
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
  if (_shouldSkipFile(relativePath)) {
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
    final files = <File>[];
    for (final relRoot in _scanRoots) {
      final absRoot = p.join(root, relRoot);
      final dir = Directory(absRoot);
      if (!dir.existsSync()) {
        continue;
      }
      for (final entity in dir.listSync(recursive: true, followLinks: false)) {
        if (entity is File && entity.path.endsWith('.dart')) {
          files.add(entity);
        }
      }
    }
    return files;
  }

  final files = <File>[];
  for (final relPath in requestedPaths) {
    if (!relPath.endsWith('.dart')) {
      continue;
    }
    final normalizedRelPath = p.normalize(relPath);
    if (!_isInScanRoots(normalizedRelPath)) {
      continue;
    }
    final file = File(p.join(root, normalizedRelPath));
    if (file.existsSync()) {
      files.add(file);
    }
  }
  return files;
}

bool _isInScanRoots(String relPath) {
  final normalized = relPath.replaceAll('\\', '/');
  for (final root in _scanRoots) {
    if (normalized == root || normalized.startsWith('$root/')) {
      return true;
    }
  }
  return false;
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
