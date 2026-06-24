import 'dart:io';

import 'package:analyzer/dart/analysis/utilities.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:path/path.dart' as p;

const _mapSrcRoot = 'packages/colonizethis_map/lib/src';
const _allowedPartClassPaths = <String>{
  'packages/colonizethis_map/lib/src/gen/tile_map_generator_types.dart',
};

/// Generation-layer and view-layer roots that must remain free of `part` /
/// `part of` coupling after the #3588 decomposition. The sole permitted part
/// file is [_allowedPartOfPath] (shared parameter types).
const _mapGenViewRoots = <String>[
  'packages/colonizethis_map/lib/src/gen',
  'packages/colonizethis_map/lib/src/view',
];

/// The only file allowed to participate in a `part` / `part of` relationship
/// under the generation/view layers (shared parameter types — Refs #3588).
const _allowedPartOfPath =
    'packages/colonizethis_map/lib/src/gen/tile_map_generator_types.dart';

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

/// Entry point for `repo.map_gen_no_new_partfiles`: forbids any new `part` /
/// `part of` coupling under the generation/view layers. The sole permitted
/// part file is [_allowedPartOfPath] (shared parameter types — Refs #3588).
int runCheckMapGenNoNewPartfiles(
  String repoRoot, {
  Iterable<String>? scanRoots,
  void Function(String line)? info,
  void Function(String line)? err,
}) {
  final logI = info ?? stdout.writeln;
  final logE = err ?? stderr.writeln;
  final root = p.normalize(repoRoot);
  final roots = (scanRoots ?? _mapGenViewRoots)
      .map((path) => path.replaceAll('\\', '/'))
      .toList(growable: false);

  final missing = <String>[];
  final violations = <MapGenPartDirectiveViolation>[];
  for (final relativeRoot in roots) {
    final dir = Directory(p.join(root, relativeRoot));
    if (!dir.existsSync()) {
      missing.add(relativeRoot);
      continue;
    }
    for (final entity in dir.listSync(recursive: true, followLinks: false)) {
      if (entity is! File || !entity.path.endsWith('.dart')) continue;
      final relPath = p.normalize(p.relative(entity.path, from: root));
      violations.addAll(
        findMapGenPartDirectiveViolations(
          relativePath: relPath.replaceAll('\\', '/'),
          source: entity.readAsStringSync(),
        ),
      );
    }
  }

  if (missing.isNotEmpty) {
    logE(
      'check_map_gen_no_new_partfiles: scanned root(s) not found (map gen/view '
      'layer moved or renamed? update _mapGenViewRoots):',
    );
    for (final relativeRoot in missing) {
      logE(' - $relativeRoot');
    }
    return 1;
  }

  if (violations.isEmpty) {
    logI('map gen/view no-new-partfiles check passed.');
    return 0;
  }

  logE(
    'ERROR: colonizethis_map generation/view layers must not use part/part-of '
    'coupling (only $_allowedPartOfPath is permitted). Move shared code into '
    'standalone library files.',
  );
  for (final violation in violations) {
    logE(
      '${violation.path}:${violation.line}:${violation.column} '
      '${violation.message}',
    );
  }
  return 1;
}

/// A `part` / `part of` coupling violation found by
/// [findMapGenPartDirectiveViolations].
class MapGenPartDirectiveViolation {
  const MapGenPartDirectiveViolation({
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

/// Flags any `part` / `part of` directive in [source] (at [relativePath]) that
/// participates in coupling other than the permitted [_allowedPartOfPath].
List<MapGenPartDirectiveViolation> findMapGenPartDirectiveViolations({
  required String relativePath,
  required String source,
}) {
  final parsed = parseString(
    content: source,
    path: relativePath,
    throwIfDiagnostics: false,
  );
  final violations = <MapGenPartDirectiveViolation>[];
  for (final directive in parsed.unit.directives) {
    if (directive is PartOfDirective) {
      if (relativePath == _allowedPartOfPath) continue;
      final location = parsed.unit.lineInfo.getLocation(directive.offset);
      violations.add(
        MapGenPartDirectiveViolation(
          path: relativePath,
          line: location.lineNumber,
          column: location.columnNumber,
          message:
              '`part of` directive is not allowed here; convert this file to a '
              'standalone library.',
        ),
      );
      continue;
    }
    if (directive is PartDirective) {
      final uri = directive.uri.stringValue;
      if (uri != null && p.basename(uri) == p.basename(_allowedPartOfPath)) {
        continue;
      }
      final location = parsed.unit.lineInfo.getLocation(directive.offset);
      violations.add(
        MapGenPartDirectiveViolation(
          path: relativePath,
          line: location.lineNumber,
          column: location.columnNumber,
          message:
              '`part \'${uri ?? '?'}\'` directive is not allowed; import a '
              'standalone library instead.',
        ),
      );
    }
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
