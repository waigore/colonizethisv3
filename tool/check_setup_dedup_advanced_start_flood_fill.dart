import 'dart:io';

import 'package:path/path.dart' as p;

/// Advanced-start province flood-fill BFS must live in
/// `advanced_start_nw_topology.dart` (Refs #4029). Bootstrap modules must call
/// `advancedStartFloodFillProvinces` rather than re-rolling visited/queue/head.
const _setupLibDir = 'packages/colonizethis_setup/lib/src/setup';

const _canonicalRelativePath =
    'packages/colonizethis_setup/lib/src/setup/advanced_start_nw_topology.dart';

final RegExp _bootstrapFile = RegExp(
  r'advanced_start_bootstrap_[^/]+\.dart$',
);

final RegExp _bannedEnqueue = RegExp(r'\b_enqueueUnvisitedNeighbors\b');

final RegExp _handRolledHead = RegExp(r'\bvar\s+head\s*=\s*0\s*;');

final RegExp _visitedMarker = RegExp(r'\bvisited\b');

final RegExp _queueMarker = RegExp(r'\bqueue\b');

bool _isCommentLine(String line) {
  final trimmed = line.trimLeft();
  return trimmed.startsWith('//') || trimmed.startsWith('*');
}

/// Used by `ct_repo_lint` in-process; [info] / [err] default to stdout/stderr.
int runCheckSetupDedupAdvancedStartFloodFill(
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
      'Setup dedup advanced-start flood-fill check skipped '
      '(setup lib dir absent).',
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

  final violations = findSetupDedupAdvancedStartFloodFillViolations(
    sourcesByPath: sourcesByPath,
  );

  if (violations.isEmpty) {
    logI('Setup dedup advanced-start flood-fill check passed.');
    return 0;
  }

  logE(
    'ERROR: Found a hand-rolled province flood-fill BFS in an advanced-start '
    'bootstrap module. Use advancedStartFloodFillProvinces from '
    'advanced_start_nw_topology.dart (Refs #4029).',
  );
  for (final v in violations) {
    logE('${v.path}:${v.line} ${v.message}');
  }
  return 1;
}

void main() {
  exit(runCheckSetupDedupAdvancedStartFloodFill(Directory.current.path));
}

List<SetupDedupAdvancedStartFloodFillViolation>
findSetupDedupAdvancedStartFloodFillViolations({
  required Map<String, String> sourcesByPath,
}) {
  final violations = <SetupDedupAdvancedStartFloodFillViolation>[];
  final paths = sourcesByPath.keys.toList()..sort();
  for (final path in paths) {
    final normalized = p.normalize(path);
    if (normalized == p.normalize(_canonicalRelativePath)) continue;
    if (!_bootstrapFile.hasMatch(path)) continue;
    final lines = sourcesByPath[path]!.split('\n');
    final content = sourcesByPath[path]!;
    for (var i = 0; i < lines.length; i++) {
      final line = lines[i];
      if (_isCommentLine(line)) continue;
      if (_bannedEnqueue.hasMatch(line)) {
        violations.add(
          SetupDedupAdvancedStartFloodFillViolation(
            path: path,
            line: i + 1,
            message:
                'Private enqueue clone; expand via '
                'advancedStartFloodFillProvinces accept/expand contract.',
          ),
        );
      }
    }
    // Hand-rolled BFS: `var head = 0` plus visited+queue markers in the file.
    if (_handRolledHead.hasMatch(content) &&
        _visitedMarker.hasMatch(content) &&
        _queueMarker.hasMatch(content)) {
      final headLine = lines.indexWhere(
        (l) => !_isCommentLine(l) && _handRolledHead.hasMatch(l),
      );
      violations.add(
        SetupDedupAdvancedStartFloodFillViolation(
          path: path,
          line: headLine < 0 ? 1 : headLine + 1,
          message:
              'Hand-rolled visited/queue/head province BFS; use '
              'advancedStartFloodFillProvinces.',
        ),
      );
    }
  }
  return violations;
}

class SetupDedupAdvancedStartFloodFillViolation {
  const SetupDedupAdvancedStartFloodFillViolation({
    required this.path,
    required this.line,
    required this.message,
  });

  final String path;
  final int line;
  final String message;
}
