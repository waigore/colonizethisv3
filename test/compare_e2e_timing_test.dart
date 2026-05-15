// Refs #2336 — guards tool/compare_e2e_timing.sh AC8/AC9 table output.

import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:test/test.dart';

void main() {
  late String repoRoot;
  late String compareScript;

  setUp(() {
    repoRoot = Directory.current.path;
    compareScript = p.join(repoRoot, 'tool', 'compare_e2e_timing.sh');
  });

  test('compare_e2e_timing.sh reports AC9 PASS when reduction meets threshold',
      () async {
    final baseline = p.join(
      repoRoot,
      'test',
      'fixtures',
      'e2e_timing',
      'baseline_summary.md',
    );
    final after = p.join(
      repoRoot,
      'test',
      'fixtures',
      'e2e_timing',
      'after_summary.md',
    );
    final result = await Process.run(
      'bash',
      [compareScript, baseline, after, '--min-reduction-pct', '25'],
      runInShell: false,
    );
    expect(result.exitCode, 0, reason: '${result.stderr}\n${result.stdout}');
    final out = result.stdout as String;
    expect(out, contains('## Aggregate (sum of per-test medians)'));
    expect(out, contains('| Suite total | 270.00s | 175.00s |'));
    expect(out, contains('**AC9 (25% aggregate reduction):** PASS'));
  });

  test('compare_e2e_timing.sh reports AC9 FAIL when reduction is below threshold',
      () async {
    final baseline = p.join(
      repoRoot,
      'test',
      'fixtures',
      'e2e_timing',
      'baseline_summary.md',
    );
    final after = p.join(
      repoRoot,
      'test',
      'fixtures',
      'e2e_timing',
      'after_summary.md',
    );
    final result = await Process.run(
      'bash',
      [compareScript, baseline, after, '--min-reduction-pct', '50'],
      runInShell: false,
    );
    expect(result.exitCode, 0, reason: '${result.stderr}\n${result.stdout}');
    expect(
      result.stdout as String,
      contains('**AC9 (50% aggregate reduction):** FAIL'),
    );
  });
}
