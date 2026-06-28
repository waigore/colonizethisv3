import 'dart:io';

import 'package:analyzer/dart/analysis/utilities.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:path/path.dart' as p;

/// Setup grid breadth-first searches and 2D coordinate keys must route through
/// the canonical `grid_bfs.dart` helpers (`bfsGridParents`, `bfsGridDistances`,
/// `gridCoordKey`, `kGridNeighborsCardinal4`) rather than re-inlining a
/// standalone BFS with an ad-hoc cardinal-delta array literal and raw
/// `'$x|$y'` coordinate-key interpolation. The town-assignment site previously
/// carried such a clone (Refs #3740). This gate keeps it from returning,
/// mirroring `check_setup_lib_tile_key_interpolation.dart`.
const _setupLibRoot = 'packages/colonizethis_setup/lib';

/// `grid_bfs.dart` owns the canonical coord-key (`gridCoordKey`) and the grid
/// BFS skeletons, so it is the only file allowed to interpolate the raw `'$x|$y'`
/// shape and (in principle) reference the cardinal deltas inline.
const _gridBfsModuleRelativePath =
    'packages/colonizethis_setup/lib/src/setup/grid_bfs.dart';

/// Coordinate-like simple identifiers; a 2-segment `|` interpolation whose both
/// operands are coordinate-like is treated as a raw coord key (vs. id joins like
/// `'$provinceId|$seaZoneId'` whose operands are not coordinate-like).
const Set<String> _coordIdentifierNames = {
  'x',
  'y',
  'nx',
  'ny',
  'cx',
  'cy',
  'sx',
  'sy',
};

/// Coordinate-like property names (e.g. `coords.x`, `startCoords.y`, `item.y`).
const Set<String> _coordPropertyNames = {'x', 'y'};

/// Cardinal 4-neighbor deltas; an inline `[dx, dy]` integer-pair list literal
/// matching one of these signals a re-inlined BFS neighbor set.
const Set<(int, int)> _cardinalDeltas = {(1, 0), (-1, 0), (0, 1), (0, -1)};

/// Used by `ct_repo_lint` in-process; [info] / [err] default to stdout/stderr.
int runCheckSetupDedupGridBfsCoordKeys(
  String repoRoot, {
  void Function(String line)? info,
  void Function(String line)? err,
}) {
  final logI = info ?? stdout.writeln;
  final logE = err ?? stderr.writeln;
  final root = p.normalize(repoRoot);
  final libDir = Directory(p.join(root, _setupLibRoot));
  if (!libDir.existsSync()) {
    logI('Setup dedup grid-BFS/coord-key check skipped (lib dir absent).');
    return 0;
  }

  final violations = <SetupGridBfsCoordKeyViolation>[];
  for (final file in libDir.listSync(recursive: true, followLinks: false)) {
    if (file is! File || !file.path.endsWith('.dart')) continue;
    if (file.path.endsWith('.g.dart')) continue;
    final relPath = p.normalize(p.relative(file.path, from: root));
    if (relPath == p.normalize(_gridBfsModuleRelativePath)) continue;
    violations.addAll(
      findSetupGridBfsCoordKeyViolations(
        relativePath: relPath,
        source: file.readAsStringSync(),
      ),
    );
  }

  if (violations.isEmpty) {
    logI('Setup dedup grid-BFS/coord-key check passed.');
    return 0;
  }

  logE(
    'ERROR: Route setup grid BFS + 2D coord keys through grid_bfs.dart '
    '(bfsGridParents / bfsGridDistances / gridCoordKey / kGridNeighborsCardinal4) '
    'instead of inline cardinal-delta arrays and raw "\$x|\$y" interpolation.',
  );
  for (final v in violations) {
    logE('${v.path}:${v.line}:${v.column} ${v.message}');
  }
  return 1;
}

void main() {
  exit(runCheckSetupDedupGridBfsCoordKeys(Directory.current.path));
}

/// Scans [source] for inline cardinal-delta list literals and raw coordinate-key
/// string interpolations.
List<SetupGridBfsCoordKeyViolation> findSetupGridBfsCoordKeyViolations({
  required String relativePath,
  required String source,
}) {
  final parsed = parseString(
    content: source,
    path: relativePath,
    throwIfDiagnostics: false,
  );
  final visitor = _GridBfsCoordKeyVisitor(
    path: relativePath,
    unit: parsed.unit,
  );
  parsed.unit.accept(visitor);
  return visitor.violations;
}

class _GridBfsCoordKeyVisitor extends RecursiveAstVisitor<void> {
  _GridBfsCoordKeyVisitor({required this.path, required this.unit});

  final String path;
  final CompilationUnit unit;
  final List<SetupGridBfsCoordKeyViolation> violations =
      <SetupGridBfsCoordKeyViolation>[];

  @override
  void visitStringInterpolation(StringInterpolation node) {
    if (_isRawCoordKeyShape(node)) {
      final loc = unit.lineInfo.getLocation(node.offset);
      violations.add(
        SetupGridBfsCoordKeyViolation(
          path: path,
          line: loc.lineNumber,
          column: loc.columnNumber,
          message: 'Raw 2D coord-key interpolation; use gridCoordKey(x, y).',
        ),
      );
    }
    super.visitStringInterpolation(node);
  }

  @override
  void visitListLiteral(ListLiteral node) {
    final delta = _cardinalDeltaPair(node);
    if (delta != null) {
      final loc = unit.lineInfo.getLocation(node.offset);
      violations.add(
        SetupGridBfsCoordKeyViolation(
          path: path,
          line: loc.lineNumber,
          column: loc.columnNumber,
          message:
              'Inline cardinal-delta literal $delta; iterate '
              'kGridNeighborsCardinal4 and use the grid_bfs.dart skeletons.',
        ),
      );
    }
    super.visitListLiteral(node);
  }

  /// True when [node] is a pure `'$a|$b'` interpolation whose both operands are
  /// coordinate-like (so id joins such as `'$provinceId|$seaZoneId'` are not
  /// flagged).
  bool _isRawCoordKeyShape(StringInterpolation node) {
    final elements = node.elements;
    if (elements.length != 5) return false;
    final e0 = elements[0];
    final e2 = elements[2];
    final e4 = elements[4];
    if (e0 is! InterpolationString || e0.value.isNotEmpty) return false;
    if (e2 is! InterpolationString || e2.value != '|') return false;
    if (e4 is! InterpolationString || e4.value.isNotEmpty) return false;
    final e1 = elements[1];
    final e3 = elements[3];
    if (e1 is! InterpolationExpression || e3 is! InterpolationExpression) {
      return false;
    }
    return _isCoordLike(e1.expression) && _isCoordLike(e3.expression);
  }

  bool _isCoordLike(Expression e) {
    if (e is SimpleIdentifier) return _coordIdentifierNames.contains(e.name);
    if (e is PrefixedIdentifier) {
      return _coordPropertyNames.contains(e.identifier.name);
    }
    if (e is PropertyAccess) {
      return _coordPropertyNames.contains(e.propertyName.name);
    }
    return false;
  }

  /// Returns the `(dx, dy)` pair when [node] is a 2-element integer list literal
  /// matching a cardinal delta, else `null`.
  (int, int)? _cardinalDeltaPair(ListLiteral node) {
    final elements = node.elements;
    if (elements.length != 2) return null;
    final first = elements[0];
    final second = elements[1];
    if (first is! Expression || second is! Expression) return null;
    final dx = _intValue(first);
    final dy = _intValue(second);
    if (dx == null || dy == null) return null;
    final pair = (dx, dy);
    return _cardinalDeltas.contains(pair) ? pair : null;
  }

  int? _intValue(Expression e) {
    if (e is IntegerLiteral) return e.value;
    if (e is PrefixExpression && e.operator.lexeme == '-') {
      final operand = e.operand;
      if (operand is IntegerLiteral) {
        final v = operand.value;
        return v == null ? null : -v;
      }
    }
    return null;
  }
}

class SetupGridBfsCoordKeyViolation {
  const SetupGridBfsCoordKeyViolation({
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
