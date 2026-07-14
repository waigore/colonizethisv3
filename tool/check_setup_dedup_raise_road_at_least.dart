import 'dart:io';

import 'package:path/path.dart' as p;

/// Raise-road-at-least must live in `setup_road_wiring.dart` (Refs #4020).
const _setupLibDir = 'packages/colonizethis_setup/lib/src/setup';

const _helperModuleRelativePath =
    'packages/colonizethis_setup/lib/src/setup/setup_road_wiring.dart';

/// Local clone names observed historically (plus the canonical public name).
final RegExp _raiseRoadDef = RegExp(
  r'(?:TileMapState\s+)?(?:_raiseRoadAtLeast|_setRoadLevelMax|raiseRoadAtLeast)\s*\(',
);

/// Used by `ct_repo_lint` in-process; [info] / [err] default to stdout/stderr.
int runCheckSetupDedupRaiseRoadAtLeast(
  String repoRoot, {
  void Function(String line)? info,
  void Function(String line)? err,
}) {
  final logI = info ?? stdout.writeln;
  final logE = err ?? stderr.writeln;
  final root = p.normalize(repoRoot);
  final dir = Directory(p.join(root, _setupLibDir));
  if (!dir.existsSync()) {
    logI(
      'Setup dedup raise-road-at-least check skipped (setup lib dir absent).',
    );
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

  final violations = findSetupDedupRaiseRoadAtLeastViolations(
    sourcesByPath: sourcesByPath,
  );

  if (violations.isEmpty) {
    logI('Setup dedup raise-road-at-least check passed.');
    return 0;
  }

  logE(
    'ERROR: raiseRoadAtLeast / _raiseRoadAtLeast / _setRoadLevelMax must be '
    'defined only in setup_road_wiring.dart; call sites must import it.',
  );
  for (final v in violations) {
    logE('${v.path}:${v.line} ${v.message}');
  }
  return 1;
}

void main() {
  exit(runCheckSetupDedupRaiseRoadAtLeast(Directory.current.path));
}

List<SetupDedupRaiseRoadAtLeastViolation>
findSetupDedupRaiseRoadAtLeastViolations({
  required Map<String, String> sourcesByPath,
}) {
  final violations = <SetupDedupRaiseRoadAtLeastViolation>[];
  final paths = sourcesByPath.keys.toList()..sort();
  for (final path in paths) {
    final normalized = p.normalize(path);
    if (normalized == p.normalize(_helperModuleRelativePath)) continue;
    final content = sourcesByPath[path]!;
    final withoutComments = _stripLineComments(content);
    if (!_raiseRoadDef.hasMatch(withoutComments)) continue;
    // Flag bodies that assign via setRoadLevel after a roadLevel compare —
    // definitions, not call sites.
    if (!withoutComments.contains('setRoadLevel') ||
        !withoutComments.contains('roadLevel(')) {
      continue;
    }
    // Require the early-return pattern of the raise helper body.
    if (!RegExp(
      r'if\s*\(\s*current\s*>=\s*\w+\s*\)\s*return\s+\w+',
    ).hasMatch(withoutComments)) {
      continue;
    }
    violations.add(
      SetupDedupRaiseRoadAtLeastViolation(
        path: path,
        line: 1,
        message:
            'Duplicate raise-road-at-least body; use raiseRoadAtLeast from '
            'setup_road_wiring.dart.',
      ),
    );
  }
  return violations;
}

String _stripLineComments(String source) {
  final buf = StringBuffer();
  for (final line in source.split('\n')) {
    final idx = line.indexOf('//');
    buf.writeln(idx < 0 ? line : line.substring(0, idx));
  }
  return buf.toString();
}

class SetupDedupRaiseRoadAtLeastViolation {
  const SetupDedupRaiseRoadAtLeastViolation({
    required this.path,
    required this.line,
    required this.message,
  });

  final String path;
  final int line;
  final String message;
}
