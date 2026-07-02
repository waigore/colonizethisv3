import 'dart:io';

import 'package:path/path.dart' as p;

/// Capital-map collection over players, minors, and tribes must live in
/// `faction_setup_helpers.dart` (Refs #3840).
const _setupLibDir = 'packages/colonizethis_setup/lib/src/setup';

const _helperModuleRelativePath =
    'packages/colonizethis_setup/lib/src/setup/faction_setup_helpers.dart';

final RegExp _playersLoop = RegExp(r'for\s*\(\s*final\s+p\s+in\s+game\.players\s*\)');
final RegExp _minorsLoop = RegExp(
  r'for\s*\(\s*final\s+m\s+in\s+game\.minorNations\s*\)',
);
final RegExp _tribesLoop = RegExp(r'for\s*\(\s*final\s+t\s+in\s+game\.tribes\s*\)');
final RegExp _capitalCollectMarker = RegExp(
  r'capitalProvinceIdByOwner|capitalTileKeyByOwner|capitalProvinceId\s*!=\s*null\s*&&\s*\w+\.capitalTile',
);

/// Used by `ct_repo_lint` in-process; [info] / [err] default to stdout/stderr.
int runCheckSetupDedupFactionCapitalCollect(
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
      'Setup dedup faction-capital-collect check skipped (setup lib dir absent).',
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

  final violations = findSetupDedupFactionCapitalCollectViolations(
    sourcesByPath: sourcesByPath,
  );

  if (violations.isEmpty) {
    logI('Setup dedup faction-capital-collect check passed.');
    return 0;
  }

  logE(
    'ERROR: Capital-map triple-faction collection loops must delegate to '
    'faction_setup_helpers.dart (collectCapitalMapsByOwner / forEachSetupFaction).',
  );
  for (final v in violations) {
    logE('${v.path}:${v.line} ${v.message}');
  }
  return 1;
}

void main() {
  exit(runCheckSetupDedupFactionCapitalCollect(Directory.current.path));
}

List<SetupDedupFactionCapitalCollectViolation>
findSetupDedupFactionCapitalCollectViolations({
  required Map<String, String> sourcesByPath,
}) {
  final violations = <SetupDedupFactionCapitalCollectViolation>[];
  final paths = sourcesByPath.keys.toList()..sort();
  for (final path in paths) {
    final normalized = p.normalize(path);
    if (normalized == p.normalize(_helperModuleRelativePath)) continue;
    final content = sourcesByPath[path]!;
    if (!_hasTripleFactionCapitalCollectLoop(content)) continue;
    violations.add(
      SetupDedupFactionCapitalCollectViolation(
        path: path,
        line: 1,
        message:
            'Triple-faction capital-collection loop detected; use '
            'collectCapitalMapsByOwner or forEachSetupFaction in '
            'faction_setup_helpers.dart.',
      ),
    );
  }
  return violations;
}

bool _hasTripleFactionCapitalCollectLoop(String content) {
  if (!_playersLoop.hasMatch(content)) return false;
  if (!_minorsLoop.hasMatch(content)) return false;
  if (!_tribesLoop.hasMatch(content)) return false;
  return _capitalCollectMarker.hasMatch(content);
}

class SetupDedupFactionCapitalCollectViolation {
  const SetupDedupFactionCapitalCollectViolation({
    required this.path,
    required this.line,
    required this.message,
  });

  final String path;
  final int line;
  final String message;
}
