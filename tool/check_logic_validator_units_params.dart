import 'dart:io';

import 'package:path/path.dart' as p;

/// Canonical [OrderResolutionContext] typedef lives here; all other logic
/// `lib/src/orders/` code should accept the threaded context record instead of
/// taking `Map<String, Unit> unitsById` as a function parameter (Refs #2836
/// AC 3; SPEC/program/logic-validator-units-params.md).
const _canonicalOrderResolutionContextRelativePath =
    'packages/colonizethis_logic/lib/src/orders/order_resolution_context.dart';

const _scanDirRelative = 'packages/colonizethis_logic/lib/src/orders';

/// Smallest value the current audit confirms is achievable — captures the
/// remaining `Map<String, Unit> unitsById` function-parameter declarations
/// under [_scanDirRelative] outside the canonical typedef file. Lowering this
/// budget tracks further [OrderResolutionContext] threading; raising it
/// requires a SPEC update in
/// SPEC/program/logic-validator-units-params.md and a maintainer-reviewed PR.
const _maxMatchingParamSitesOutsideCanonical = 10;

final RegExp _generatedSuffix = RegExp(r'\.(g|freezed|mocks|gen)\.dart$');

/// Matches a function-parameter declaration `Map<String, Unit> unitsById` that
/// is terminated by either `,` (more parameters) or `)` (last parameter).
///
/// Intentionally **does not** match class field declarations like
/// `final Map<String, Unit> unitsById;` (terminated by `;`) — those are
/// constructor-bound state, not parameter threading, and migrating them is
/// orthogonal to threading [OrderResolutionContext]. Comment lines starting
/// with `//` or `///` are also excluded so backwards-compat narrative does
/// not bump the budget.
final RegExp _paramPattern = RegExp(r'Map<String,\s*Unit>\s+unitsById\s*[,)]');

bool logicValidatorUnitsParamLineMatches(String line) {
  final trimmed = line.trimLeft();
  if (trimmed.startsWith('//') || trimmed.startsWith('///')) {
    return false;
  }
  if (trimmed.startsWith('final ')) {
    return false;
  }
  return _paramPattern.hasMatch(line);
}

/// Used by `ct_repo_lint` in-process; [info] / [err] default to stdout/stderr.
int runCheckLogicValidatorUnitsParams(
  String repoRoot, {
  void Function(String line)? info,
  void Function(String line)? err,
}) {
  final logI = info ?? stdout.writeln;
  final logE = err ?? stderr.writeln;
  final root = p.normalize(repoRoot);
  final scanRoot = Directory(p.join(root, _scanDirRelative));
  if (!scanRoot.existsSync()) {
    logE('ERROR: Expected logic orders tree missing: $_scanDirRelative');
    return 1;
  }

  final hits = <LogicValidatorUnitsParamHit>[];
  for (final entity in scanRoot.listSync(recursive: true, followLinks: false)) {
    if (entity is! File) continue;
    final fullPath = p.normalize(entity.path);
    if (!fullPath.endsWith('.dart')) continue;
    if (_generatedSuffix.hasMatch(fullPath)) continue;
    final relative = p.normalize(p.relative(fullPath, from: root));
    if (relative == _canonicalOrderResolutionContextRelativePath) {
      continue;
    }

    final lines = entity.readAsLinesSync();
    for (var i = 0; i < lines.length; i++) {
      final line = lines[i];
      if (logicValidatorUnitsParamLineMatches(line)) {
        hits.add(LogicValidatorUnitsParamHit(path: relative, line: i + 1));
      }
    }
  }

  if (hits.length <= _maxMatchingParamSitesOutsideCanonical) {
    logI(
      'Logic validator units-params check passed '
      '(${hits.length}/$_maxMatchingParamSitesOutsideCanonical '
      '`Map<String, Unit> unitsById` parameter sites under '
      '$_scanDirRelative outside '
      '$_canonicalOrderResolutionContextRelativePath).',
    );
    return 0;
  }

  logE(
    'ERROR: Too many `Map<String, Unit> unitsById` function-parameter '
    'declarations under $_scanDirRelative outside '
    '$_canonicalOrderResolutionContextRelativePath '
    '(${hits.length} > $_maxMatchingParamSitesOutsideCanonical). '
    'Thread the canonical [OrderResolutionContext] record '
    '(view + unitsById + provinceById) into helpers and validators '
    'instead so per-pass snapshots are reused (Refs #2836 AC 3; '
    'SPEC/program/logic-validator-units-params.md).',
  );
  for (final h in hits) {
    logE('${h.path}:${h.line}');
  }
  return 1;
}

void main() {
  exit(runCheckLogicValidatorUnitsParams(Directory.current.path));
}

final class LogicValidatorUnitsParamHit {
  const LogicValidatorUnitsParamHit({required this.path, required this.line});

  final String path;
  final int line;
}
