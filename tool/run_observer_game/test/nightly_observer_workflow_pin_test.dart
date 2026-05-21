// Pins the nightly CI workflow contract for the observer colonial expansion
// gates (Refs #2509). These tests cover the two CI acceptance criteria from
// issue #2509:
//
//   * Given the nightly workflow triggers at 15:00 UTC (23:00 HKT), when it
//     runs successfully, then it executes run_observer_game with seed 42,
//     --max-turns 150, --verify-conquest, and --verify-colonial-expansion.
//   * Given the default quality workflow, when unit tests run, then no full
//     150-turn observer integration test is included.
//
// SPEC: SPEC/program/run_observer_game-tool.md § Nightly observer job.

import 'dart:io';

import 'package:colonizethis_test/test.dart';
import 'package:path/path.dart' as p;

/// Walk up from [start] to find the repo root (directory containing
/// `.github/workflows/`). Returns the resolved path or `null` if not found.
String? _findRepoRoot(String start) {
  var dir = Directory(start).absolute;
  for (var i = 0; i < 8; i++) {
    final workflows = Directory(p.join(dir.path, '.github', 'workflows'));
    if (workflows.existsSync()) {
      return dir.path;
    }
    final parent = dir.parent;
    if (parent.path == dir.path) {
      return null;
    }
    dir = parent;
  }
  return null;
}

String _readWorkflow(String repoRoot, String name) {
  final file = File(p.join(repoRoot, '.github', 'workflows', name));
  expect(
    file.existsSync(),
    isTrue,
    reason: '.github/workflows/$name must exist on dev (Refs #2509)',
  );
  return file.readAsStringSync();
}

void main() {
  final repoRoot = _findRepoRoot(Directory.current.path);

  group('nightly.yml observer_conquest_verify job', () {
    late String yaml;

    setUpAll(() {
      expect(
        repoRoot,
        isNotNull,
        reason:
            'could not locate repo root (no .github/workflows ancestor) from '
            'cwd=${Directory.current.path}',
      );
      yaml = _readWorkflow(repoRoot!, 'nightly.yml');
    });

    test('schedules at 15:00 UTC (23:00 Asia/Hong_Kong)', () {
      expect(
        yaml,
        contains("cron: '0 15 * * *'"),
        reason:
            'Nightly observer job must run daily at 23:00 HKT per #2509 CI '
            'acceptance criteria.',
      );
    });

    test('declares observer_conquest_verify job targeting 150 turns', () {
      expect(yaml, contains('observer_conquest_verify:'));
      expect(
        yaml,
        contains('Full-AI observer verify (seed 42, turns 150)'),
        reason:
            'Job name pin keeps the seed-42 / 150-turn campaign visible in '
            'GitHub Actions UI and matches #2509 must-have #13.',
      );
    });

    test('invokes run_observer_game with both verify flags and seed 42', () {
      expect(
        yaml,
        contains('dart run tool/run_observer_game/bin/run_observer_game.dart'),
        reason: 'Nightly job must execute the workspace observer entrypoint.',
      );
      expect(yaml, contains('--seed 42'));
      expect(yaml, contains('--max-turns 150'));
      expect(yaml, contains('--verify-conquest'));
      expect(yaml, contains('--verify-colonial-expansion'));
    });

    test('allows enough wall-clock budget for the 150-turn campaign', () {
      final timeoutMatch = RegExp(
        r'observer_conquest_verify:[\s\S]*?timeout-minutes:\s*(\d+)',
      ).firstMatch(yaml);
      expect(
        timeoutMatch,
        isNotNull,
        reason: 'observer_conquest_verify must declare timeout-minutes.',
      );
      final minutes = int.parse(timeoutMatch!.group(1)!);
      expect(
        minutes,
        greaterThanOrEqualTo(180),
        reason:
            'Issue #2509 requires nightly observer timeout >= 180 minutes for '
            'the seed-42 150-turn campaign.',
      );
    });
  });

  group('quality.yml PR gate', () {
    late String yaml;

    setUpAll(() {
      expect(repoRoot, isNotNull);
      yaml = _readWorkflow(repoRoot!, 'quality.yml');
    });

    test('does not run the full 150-turn observer campaign', () {
      // The PR quality lane must stay under PR-budget wall-clock and only
      // execute unit/coverage tests for run_observer_game. The expensive
      // 150-turn observer run lives in nightly.yml (Refs #2509 CI AC and
      // SPEC/program/run_observer_game-tool.md § Nightly observer job).
      expect(
        yaml.contains('--max-turns 150'),
        isFalse,
        reason:
            'quality.yml must not invoke a 150-turn observer campaign; this '
            'belongs in nightly.yml only.',
      );
      expect(
        yaml.contains('--verify-colonial-expansion'),
        isFalse,
        reason:
            'quality.yml must not run --verify-colonial-expansion; that gate '
            'is reserved for the nightly job (Refs #2509).',
      );
      // The CLI binary path must not appear as a "run:" step. Allow path
      // references that gate test scope ("tool/run_observer_game/**") but
      // disallow a workflow step that executes the CLI directly.
      final binPath = 'bin/run_observer_game.dart';
      expect(
        yaml.contains(binPath),
        isFalse,
        reason:
            'quality.yml must not execute run_observer_game CLI; only unit '
            'tests for the package are run on PRs.',
      );
    });
  });
}
