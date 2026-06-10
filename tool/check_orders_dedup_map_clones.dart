import 'dart:io';

import 'package:path/path.dart' as p;

/// Orders module whose snapshot clones must delegate to canonical helpers
/// instead of inlining raw `Map<...>.from(...)` clones (Refs #3404):
/// - stockpile-quantities clones use `Stockpile.copyQuantities()` rather than
///   `Map<String, int>.from(<stockpile>.quantities)`.
/// - unit-by-id clones use `copyUnitsById(...)` rather than
///   `Map<String, Unit>.from(...)`.
const _ordersLibDir = 'packages/colonizethis_orders/lib/src/orders';

/// Matches a raw clone of a stockpile quantities map, e.g.
/// `Map<String, int>.from(snap.stockpile.quantities)`.
final RegExp _rawQuantitiesClonePattern = RegExp(
  r'Map<\s*String\s*,\s*int\s*>\.from\([^)]*\.quantities\)',
);

/// Matches a raw clone of a unit-by-id map, e.g.
/// `Map<String, Unit>.from(work.oldUnitsById)`. The canonical
/// `copyUnitsById(...)` helper uses a spread literal, so it does not match.
final RegExp _rawUnitsClonePattern = RegExp(
  r'Map<\s*String\s*,\s*Unit\s*>\.from\(',
);

/// True when [line] is a pure comment line (`//`, `///`, or a `*` doc/block
/// continuation), so a pattern mentioned in prose is not flagged.
bool _isCommentLine(String line) {
  final trimmed = line.trimLeft();
  return trimmed.startsWith('//') || trimmed.startsWith('*');
}

/// Used by `ct_repo_lint` in-process; [info] / [err] default to stdout/stderr.
int runCheckOrdersDedupMapClones(
  String repoRoot, {
  void Function(String line)? info,
  void Function(String line)? err,
}) {
  final logI = info ?? stdout.writeln;
  final logE = err ?? stderr.writeln;
  final root = p.normalize(repoRoot);
  final dir = Directory(p.join(root, _ordersLibDir));
  if (!dir.existsSync()) {
    logI('Orders dedup map-clone check skipped (orders lib dir absent).');
    return 0;
  }

  final violations = <OrdersDedupMapCloneViolation>[];
  for (final entity in dir.listSync(recursive: true)) {
    if (entity is! File) continue;
    if (!entity.path.endsWith('.dart')) continue;
    if (entity.path.endsWith('.g.dart')) continue;
    final relativePath = p.relative(entity.path, from: root);
    violations.addAll(
      findOrdersDedupMapCloneViolations(
        relativePath: relativePath,
        source: entity.readAsStringSync(),
      ),
    );
  }

  if (violations.isEmpty) {
    logI('Orders dedup map-clone check passed.');
    return 0;
  }

  logE(
    'ERROR: Found raw map clones in the orders module. Use '
    'Stockpile.copyQuantities() instead of '
    'Map<String, int>.from(<stockpile>.quantities), and copyUnitsById(...) '
    'instead of Map<String, Unit>.from(...).',
  );
  for (final v in violations) {
    logE('${v.path}:${v.line} ${v.message}');
  }
  return 1;
}

void main() {
  exit(runCheckOrdersDedupMapClones(Directory.current.path));
}

List<OrdersDedupMapCloneViolation> findOrdersDedupMapCloneViolations({
  required String relativePath,
  required String source,
}) {
  final lines = source.split('\n');
  final violations = <OrdersDedupMapCloneViolation>[];
  for (var i = 0; i < lines.length; i++) {
    final line = lines[i];
    if (_isCommentLine(line)) continue;
    if (_rawQuantitiesClonePattern.hasMatch(line)) {
      violations.add(
        OrdersDedupMapCloneViolation(
          path: relativePath,
          line: i + 1,
          message:
              'Raw stockpile quantities clone detected; call '
              'Stockpile.copyQuantities() instead.',
        ),
      );
    }
    if (_rawUnitsClonePattern.hasMatch(line)) {
      violations.add(
        OrdersDedupMapCloneViolation(
          path: relativePath,
          line: i + 1,
          message:
              'Raw unit-by-id map clone detected; call copyUnitsById(...) '
              'instead.',
        ),
      );
    }
  }
  return violations;
}

class OrdersDedupMapCloneViolation {
  const OrdersDedupMapCloneViolation({
    required this.path,
    required this.line,
    required this.message,
  });

  final String path;
  final int line;
  final String message;
}
