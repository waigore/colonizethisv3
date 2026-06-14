import 'dart:io';

import 'package:path/path.dart' as p;

/// Setup package whose init map+setup retry control flow must delegate to the
/// shared `runInitPipelineWithRetries` runner (Refs #3449) instead of inlining
/// the per-attempt seed bump and the retriable-topology-code predicate in each
/// pipeline. Two duplicated copies of this loop existed in
/// `init_game_orchestrator.dart` before dedup.
const _setupLibDir = 'packages/colonizethis_setup/lib/src/setup';

/// Matches an inline per-attempt seed bump such as `attempt * 100003`. The
/// canonical runner exposes the bump as `kInitPipelineSeedBump`, so any inline
/// `* 100003` re-introduces a duplicated pipeline loop. The constant
/// definition (`= 100003`) does not match.
final RegExp _inlineSeedBumpPattern = RegExp(r'\*\s*100003\b');

/// Matches the retriable-topology classification predicate, e.g.
/// `e.code == 'faction_component_bin_pack_failed'`. The canonical runner has a
/// single `isRetriableInitTopologyCode` source of truth; a second occurrence
/// signals a re-inlined retry classifier. Throw sites (`code: '...'`) use a
/// colon and do not match.
final RegExp _retriablePredicatePattern = RegExp(
  r"code\s*==\s*'faction_component_bin_pack_failed'",
);

/// True when [line] is a pure comment line (`//`, `///`, or a `*` doc/block
/// continuation), so a pattern mentioned in prose is not flagged.
bool _isCommentLine(String line) {
  final trimmed = line.trimLeft();
  return trimmed.startsWith('//') || trimmed.startsWith('*');
}

/// Used by `ct_repo_lint` in-process; [info] / [err] default to stdout/stderr.
int runCheckSetupDedupInitPipelineRetry(
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
      'Setup dedup init-pipeline-retry check skipped (setup lib dir absent).',
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

  final violations = findSetupDedupInitPipelineRetryViolations(
    sourcesByPath: sourcesByPath,
  );

  if (violations.isEmpty) {
    logI('Setup dedup init-pipeline-retry check passed.');
    return 0;
  }

  logE(
    'ERROR: Found duplicated init map+setup retry control flow in the setup '
    'package. Delegate to runInitPipelineWithRetries (kInitPipelineSeedBump, '
    'isRetriableInitTopologyCode) in init_pipeline_retry.dart instead of '
    'inlining the per-attempt seed bump or the retriable-code predicate.',
  );
  for (final v in violations) {
    logE('${v.path}:${v.line} ${v.message}');
  }
  return 1;
}

void main() {
  exit(runCheckSetupDedupInitPipelineRetry(Directory.current.path));
}

/// Scans [sourcesByPath] (relative path -> source) for duplicated init-pipeline
/// retry control flow. Any inline `* 100003` seed bump is flagged. The
/// retriable-code predicate is flagged only when it appears in more than one
/// place (the canonical helper keeps exactly one occurrence).
List<SetupDedupInitPipelineRetryViolation>
findSetupDedupInitPipelineRetryViolations({
  required Map<String, String> sourcesByPath,
}) {
  final violations = <SetupDedupInitPipelineRetryViolation>[];
  final predicateSites = <SetupDedupInitPipelineRetryViolation>[];

  final paths = sourcesByPath.keys.toList()..sort();
  for (final path in paths) {
    final lines = sourcesByPath[path]!.split('\n');
    for (var i = 0; i < lines.length; i++) {
      final line = lines[i];
      if (_isCommentLine(line)) continue;
      if (_inlineSeedBumpPattern.hasMatch(line)) {
        violations.add(
          SetupDedupInitPipelineRetryViolation(
            path: path,
            line: i + 1,
            message:
                'Inline init-pipeline seed bump (* 100003) detected; use '
                'kInitPipelineSeedBump via runInitPipelineWithRetries.',
          ),
        );
      }
      if (_retriablePredicatePattern.hasMatch(line)) {
        predicateSites.add(
          SetupDedupInitPipelineRetryViolation(
            path: path,
            line: i + 1,
            message:
                'Duplicated retriable init-topology code predicate; delegate '
                'to isRetriableInitTopologyCode().',
          ),
        );
      }
    }
  }

  if (predicateSites.length >= 2) {
    violations.addAll(predicateSites);
  }
  return violations;
}

class SetupDedupInitPipelineRetryViolation {
  const SetupDedupInitPipelineRetryViolation({
    required this.path,
    required this.line,
    required this.message,
  });

  final String path;
  final int line;
  final String message;
}
