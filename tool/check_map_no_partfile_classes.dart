import 'dart:io';

import 'package:analyzer/dart/analysis/utilities.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:path/path.dart' as p;

const _mapSrcRoot = 'packages/colonizethis_map/lib/src';
const _allowedPartClassPaths = <String>{
  'packages/colonizethis_map/lib/src/gen/tile_map_generator_types.dart',
};

int runCheckMapNoPartfileClasses(
  String repoRoot, {
  void Function(String line)? info,
  void Function(String line)? err,
}) {
  final logI = info ?? stdout.writeln;
  final logE = err ?? stderr.writeln;
  final root = p.normalize(repoRoot);
  final srcDir = Directory(p.join(root, _mapSrcRoot));
  if (!srcDir.existsSync()) {
    logE('check_map_no_partfile_classes: missing ${srcDir.path}');
    return 1;
  }

  final violations = <_Violation>[];
  for (final entity in srcDir.listSync(recursive: true, followLinks: false)) {
    if (entity is! File || !entity.path.endsWith('.dart')) continue;
    final relPath = p.normalize(p.relative(entity.path, from: root));
    final source = entity.readAsStringSync();
    violations.addAll(_findViolations(relativePath: relPath, source: source));
  }

  if (violations.isEmpty) {
    logI('map part-file class check passed.');
    return 0;
  }

  logE('ERROR: map part files must not declare top-level non-private classes.');
  for (final violation in violations) {
    logE(
      '${violation.path}:${violation.line}:${violation.column} '
      '${violation.message}',
    );
  }
  return 1;
}

void main() {
  exit(runCheckMapNoPartfileClasses(Directory.current.path));
}

List<_Violation> _findViolations({
  required String relativePath,
  required String source,
}) {
  if (_allowedPartClassPaths.contains(relativePath)) {
    return const [];
  }
  final parsed = parseString(
    content: source,
    path: relativePath,
    throwIfDiagnostics: false,
  );
  final hasPartOfDirective = parsed.unit.directives.any((directive) {
    return directive is PartOfDirective;
  });
  if (!hasPartOfDirective) return const [];

  final violations = <_Violation>[];
  for (final declaration in parsed.unit.declarations) {
    if (declaration is! ClassDeclaration) continue;
    final className = declaration.name.lexeme;
    if (className.startsWith('_')) continue;
    final location = parsed.unit.lineInfo.getLocation(declaration.offset);
    violations.add(
      _Violation(
        path: relativePath,
        line: location.lineNumber,
        column: location.columnNumber,
        message:
            'Top-level class `$className` is declared in a part file; move it to a standalone library file.',
      ),
    );
  }
  return violations;
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
