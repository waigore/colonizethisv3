import 'dart:io';

import 'package:path/path.dart' as p;

/// Ownership paint scaffolding must go through `_paintLandmass` in
/// `game_setup_ownership_paint.dart` (Refs #4029). Call sites must not re-inline
/// growth-order + assigner wiring.
const _setupLibDir = 'packages/colonizethis_setup/lib/src/setup';

const _paintRelativePath =
    'packages/colonizethis_setup/lib/src/setup/game_setup_ownership_paint.dart';

const _lockedAssignerRelativePath =
    'packages/colonizethis_setup/lib/src/setup/locked_province_assigner.dart';

const _bfsAssignerRelativePath =
    'packages/colonizethis_setup/lib/src/setup/province_assignment.dart';

final RegExp _ownershipOrchestration = RegExp(
  r'game_setup_ownership[^/]*\.dart$',
);

final RegExp _lockedAssignerCall = RegExp(
  r'\bassignTerritoriesLockedOnLandmass\s*\(',
);

final RegExp _bfsAssignerCall = RegExp(r'\bassignTerritoriesByBfsGrowth\s*\(');

final RegExp _growthOrderSymbol = RegExp(r'\b_lockedGrowthOrder\b');

final RegExp _paintFacadeSymbol = RegExp(r'\b_paintLandmass\b');

bool _isCommentLine(String line) {
  final trimmed = line.trimLeft();
  return trimmed.startsWith('//') || trimmed.startsWith('*');
}

/// Used by `ct_repo_lint` in-process; [info] / [err] default to stdout/stderr.
int runCheckSetupDedupOwnershipPaint(
  String repoRoot, {
  void Function(String line)? info,
  void Function(String line)? err,
}) {
  final logI = info ?? stdout.writeln;
  final logE = err ?? stderr.writeln;
  final root = p.normalize(repoRoot);
  final dir = Directory(p.join(root, _setupLibDir));
  if (!dir.existsSync()) {
    logI('Setup dedup ownership-paint check skipped (setup lib dir absent).');
    return 0;
  }

  final sourcesByPath = <String, String>{};
  for (final entity in dir.listSync(recursive: true)) {
    if (entity is! File) continue;
    if (!entity.path.endsWith('.dart')) continue;
    if (entity.path.endsWith('.g.dart')) continue;
    final relativePath = p.relative(entity.path, from: root);
    sourcesByPath[relativePath] = entity.readAsStringSync();
  }

  final violations = findSetupDedupOwnershipPaintViolations(
    sourcesByPath: sourcesByPath,
  );

  if (violations.isEmpty) {
    logI('Setup dedup ownership-paint check passed.');
    return 0;
  }

  logE(
    'ERROR: Found re-inlined ownership paint scaffolding outside '
    'game_setup_ownership_paint.dart. Use _paintLandmass (locked|bfs) for '
    'growth-order/target/seed wiring (Refs #4029).',
  );
  for (final v in violations) {
    logE('${v.path}:${v.line} ${v.message}');
  }
  return 1;
}

void main() {
  exit(runCheckSetupDedupOwnershipPaint(Directory.current.path));
}

List<SetupDedupOwnershipPaintViolation> findSetupDedupOwnershipPaintViolations({
  required Map<String, String> sourcesByPath,
}) {
  final violations = <SetupDedupOwnershipPaintViolation>[];
  final paths = sourcesByPath.keys.toList()..sort();
  final normalizedPaint = p.normalize(_paintRelativePath);
  final normalizedLocked = p.normalize(_lockedAssignerRelativePath);
  final normalizedBfs = p.normalize(_bfsAssignerRelativePath);

  var paintDefinesFacade = false;
  for (final path in paths) {
    final normalized = p.normalize(path);
    final lines = sourcesByPath[path]!.split('\n');

    if (normalized == normalizedPaint) {
      for (var i = 0; i < lines.length; i++) {
        final line = lines[i];
        if (_isCommentLine(line)) continue;
        if (_paintFacadeSymbol.hasMatch(line) && line.contains('(')) {
          paintDefinesFacade = true;
        }
      }
      continue;
    }

    // Assigner definitions may name themselves; ignore their bodies.
    if (normalized == normalizedLocked || normalized == normalizedBfs) {
      continue;
    }
    if (normalized.contains('locked_province_assigner_')) {
      continue;
    }

    // Growth-order symbol anywhere outside the paint module; assigner calls
    // only under ownership orchestration parts/main.
    final scanAssignerCalls = _ownershipOrchestration.hasMatch(path);

    for (var i = 0; i < lines.length; i++) {
      final line = lines[i];
      if (_isCommentLine(line)) continue;

      if (_growthOrderSymbol.hasMatch(line)) {
        violations.add(
          SetupDedupOwnershipPaintViolation(
            path: path,
            line: i + 1,
            message:
                '_lockedGrowthOrder must live only in '
                'game_setup_ownership_paint.dart.',
          ),
        );
      }

      if (!scanAssignerCalls) continue;

      if (_lockedAssignerCall.hasMatch(line)) {
        violations.add(
          SetupDedupOwnershipPaintViolation(
            path: path,
            line: i + 1,
            message:
                'Direct assignTerritoriesLockedOnLandmass scaffolding; use '
                '_paintLandmass(mode: locked).',
          ),
        );
      }
      if (_bfsAssignerCall.hasMatch(line)) {
        violations.add(
          SetupDedupOwnershipPaintViolation(
            path: path,
            line: i + 1,
            message:
                'Direct assignTerritoriesByBfsGrowth scaffolding; use '
                '_paintLandmass(mode: bfs).',
          ),
        );
      }
    }
  }

  if (!paintDefinesFacade) {
    violations.add(
      const SetupDedupOwnershipPaintViolation(
        path: _paintRelativePath,
        line: 1,
        message: 'Missing _paintLandmass facade definition.',
      ),
    );
  }

  return violations;
}

class SetupDedupOwnershipPaintViolation {
  const SetupDedupOwnershipPaintViolation({
    required this.path,
    required this.line,
    required this.message,
  });

  final String path;
  final int line;
  final String message;
}
