// Refs #3661 — guards tool/check_economy_test_wall_clock.sh comparison/mode
// behaviour. Uses ECONOMY_TEST_TIMING_MEASURED_SECONDS to drive the
// deterministic comparison path without running the real economy suite.
// Spec: SPEC/program/economy-test-wall-clock.md.

import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:test/test.dart';

void main() {
  late String repoRoot;
  late String script;

  setUp(() {
    repoRoot = Directory.current.path;
    script = p.join(repoRoot, 'tool', 'check_economy_test_wall_clock.sh');
  });

  Future<ProcessResult> run(Map<String, String> env) => Process.run(
        'bash',
        [script],
        environment: env,
        runInShell: false,
      );

  test('skip path exits 0 without measuring', () async {
    final r = await run({
      'SKIP_ECONOMY_TEST_TIMING': '1',
      'ECONOMY_TEST_TIMING_MEASURED_SECONDS': '999',
    });
    expect(r.exitCode, 0, reason: '${r.stderr}\n${r.stdout}');
    expect(r.stdout as String, contains('skipping economy test timing'));
  });

  test('median under ceiling passes (advisory default)', () async {
    final r = await run({
      'ECONOMY_TEST_TIMING_MEASURED_SECONDS': '10',
      'ECONOMY_TEST_TIMING_CEILING_SECONDS': '25',
    });
    expect(r.exitCode, 0, reason: '${r.stderr}\n${r.stdout}');
    expect(r.stdout as String, contains('PASS: median 10'));
  });

  test('median equal to ceiling is within budget under enforce', () async {
    final r = await run({
      'ECONOMY_TEST_TIMING_MEASURED_SECONDS': '25',
      'ECONOMY_TEST_TIMING_CEILING_SECONDS': '25',
      'ECONOMY_TEST_TIMING_ENFORCE': '1',
    });
    expect(r.exitCode, 0, reason: '${r.stderr}\n${r.stdout}');
    expect(r.stdout as String, contains('PASS: median 25'));
  });

  test('median over ceiling warns but exits 0 in advisory mode', () async {
    final r = await run({
      'ECONOMY_TEST_TIMING_MEASURED_SECONDS': '40',
      'ECONOMY_TEST_TIMING_CEILING_SECONDS': '25',
    });
    expect(r.exitCode, 0, reason: '${r.stderr}\n${r.stdout}');
    expect(r.stdout as String, contains('WARN: median 40'));
  });

  test('median over ceiling fails (exit 1) in enforce mode', () async {
    final r = await run({
      'ECONOMY_TEST_TIMING_MEASURED_SECONDS': '40',
      'ECONOMY_TEST_TIMING_CEILING_SECONDS': '25',
      'ECONOMY_TEST_TIMING_ENFORCE': '1',
    });
    expect(r.exitCode, 1, reason: '${r.stderr}\n${r.stdout}');
    expect(
      '${r.stdout}${r.stderr}',
      contains('FAIL: median 40'),
    );
  });

  test('even ECONOMY_TEST_TIMING_RUNS is rejected with exit 2', () async {
    final r = await run({
      'ECONOMY_TEST_TIMING_MEASURED_SECONDS': '10',
      'ECONOMY_TEST_TIMING_RUNS': '2',
    });
    expect(r.exitCode, 2, reason: '${r.stderr}\n${r.stdout}');
    expect('${r.stdout}${r.stderr}', contains('must be an odd integer'));
  });
}
