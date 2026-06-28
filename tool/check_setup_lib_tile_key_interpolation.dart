import 'dart:io';

import 'package:analyzer/dart/analysis/utilities.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:path/path.dart' as p;

/// Setup-package tile keys must be built through the canonical helpers
/// (`CapitalTile.tileKey`, `gpOwTileKey`) rather than raw
/// `'$regionId|$localId|$x|$y'` string interpolation. This mirrors the
/// `colonizethis_map` gates (`repo.colonizethis_map_lib_pipe_split` /
/// `repo.canonical_province_tile_keys`, GitHub #2087) for
/// `packages/colonizethis_setup/lib/` so setup stays decoupled from the raw
/// pipe-string tile-key shape (Refs #3712).
const _setupLibRoot = 'packages/colonizethis_setup/lib';

/// The canonical tile-key shape `region|province|x|y` is a pure-interpolation
/// join with this many `|` separators. Two-segment coord keys (`'$x|$y'`) and
/// port keys (`'$provinceId|$seaZoneId'`) carry fewer separators and are not
/// flagged; descriptive log strings (`'i=$i|sz=$s|sea=$x'`) carry non-pipe
/// literal text between segments and are likewise not flagged.
const _tileKeySeparatorThreshold = 3;

/// Canonical tile-key builders are allowed to construct the raw shape. The
/// setup package routes all keys through `CapitalTile.tileKey` (in
/// `colonizethis_models`) and the shared `gp_old_world_tile_scan.dart` /
/// `province_tile_ranking.dart` helpers, none of which interpolate the raw
/// string, so no setup source is exempt today; the allow-list documents intent
/// and keeps a single editable place should a canonical builder ever move here.
const _allowedRawTileKeyPaths = <String>{};

/// Used by `ct_repo_lint` in-process; [info] / [err] default to stdout/stderr.
int runCheckSetupLibTileKeyInterpolation(
  String repoRoot, {
  void Function(String line)? info,
  void Function(String line)? err,
}) {
  final logI = info ?? stdout.writeln;
  final logE = err ?? stderr.writeln;
  final root = p.normalize(repoRoot);
  final libDir = Directory(p.join(root, _setupLibRoot));
  if (!libDir.existsSync()) {
    logI('Setup lib tile-key interpolation check skipped (lib dir absent).');
    return 0;
  }

  final violations = <SetupLibTileKeyInterpolationViolation>[];
  for (final file in libDir.listSync(recursive: true, followLinks: false)) {
    if (file is! File || !file.path.endsWith('.dart')) continue;
    if (file.path.endsWith('.g.dart')) continue;
    final relPath = p.normalize(p.relative(file.path, from: root));
    if (_allowedRawTileKeyPaths.contains(relPath)) continue;
    violations.addAll(
      findSetupLibTileKeyInterpolationViolations(
        relativePath: relPath,
        source: file.readAsStringSync(),
      ),
    );
  }

  if (violations.isEmpty) {
    logI('Setup lib tile-key interpolation check passed.');
    return 0;
  }

  logE(
    'ERROR: Build setup tile keys via CapitalTile.tileKey / gpOwTileKey '
    'instead of raw "\$regionId|\$localId|\$x|\$y" interpolation.',
  );
  for (final v in violations) {
    logE('${v.path}:${v.line}:${v.column} ${v.message}');
  }
  return 1;
}

void main() {
  exit(runCheckSetupLibTileKeyInterpolation(Directory.current.path));
}

/// Scans [source] for raw canonical-shape tile-key string interpolations.
List<SetupLibTileKeyInterpolationViolation>
findSetupLibTileKeyInterpolationViolations({
  required String relativePath,
  required String source,
}) {
  final parsed = parseString(
    content: source,
    path: relativePath,
    throwIfDiagnostics: false,
  );
  final visitor = _RawTileKeyInterpolationVisitor(
    path: relativePath,
    unit: parsed.unit,
  );
  parsed.unit.accept(visitor);
  return visitor.violations;
}

class _RawTileKeyInterpolationVisitor extends RecursiveAstVisitor<void> {
  _RawTileKeyInterpolationVisitor({required this.path, required this.unit});

  final String path;
  final CompilationUnit unit;
  final List<SetupLibTileKeyInterpolationViolation> violations =
      <SetupLibTileKeyInterpolationViolation>[];

  @override
  void visitStringInterpolation(StringInterpolation node) {
    if (_isRawTileKeyShape(node)) {
      final loc = unit.lineInfo.getLocation(node.offset);
      violations.add(
        SetupLibTileKeyInterpolationViolation(
          path: path,
          line: loc.lineNumber,
          column: loc.columnNumber,
          message:
              'Raw tile-key interpolation; use CapitalTile.tileKey / gpOwTileKey.',
        ),
      );
    }
    super.visitStringInterpolation(node);
  }

  /// True when [node] is a pure-interpolation join of 4+ segments separated by
  /// lone `|` literals — i.e. the canonical `region|province|x|y` tile-key
  /// shape. The analyzer always emits leading/trailing [InterpolationString]
  /// elements (possibly empty); a pure pipe-join has empty endpoints, `|`
  /// separators, and [InterpolationExpression] segments in between.
  bool _isRawTileKeyShape(StringInterpolation node) {
    final elements = node.elements;
    if (elements.length < 2) return false;
    var separators = 0;
    for (var i = 0; i < elements.length; i++) {
      final element = elements[i];
      if (i.isEven) {
        if (element is! InterpolationString) return false;
        final value = element.value;
        final isEndpoint = i == 0 || i == elements.length - 1;
        if (isEndpoint) {
          if (value.isNotEmpty) return false;
        } else {
          if (value != '|') return false;
          separators++;
        }
      } else {
        if (element is! InterpolationExpression) return false;
      }
    }
    return separators >= _tileKeySeparatorThreshold;
  }
}

class SetupLibTileKeyInterpolationViolation {
  const SetupLibTileKeyInterpolationViolation({
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
