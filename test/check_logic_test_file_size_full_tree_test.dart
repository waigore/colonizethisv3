// Regression harness for the GitHub #2288 transition: `repo.logic_test_file_size`
// must run the full `packages/colonizethis_logic/test/**` tree from
// `ct_repo_lint`, not skip when the changed-file baseline is empty.
// See `SPEC/program/repo-lint.md` "Implementation status (GitHub #2288, logic
// test file size)".
import 'dart:io';

import 'package:test/test.dart';

import '../tool/check_logic_test_file_size.dart';

void main() {
  final repoRoot = Directory.current.path;

  test('current repo passes full-tree logic test file-size scan', () {
    final logs = <String>[];
    final code = runCheckLogicTestFileSize(
      repoRoot,
      info: logs.add,
      err: logs.add,
    );
    expect(
      code,
      0,
      reason:
          'Full-tree scan must stay green; new violations under '
          'packages/colonizethis_logic/test must be split before merging.\n'
          '${logs.join('\n')}',
    );
  });

  test(
    'ct_repo_lint runs repo.logic_test_file_size without skipping on full scan',
    () {
      final result = Process.runSync(
        Platform.resolvedExecutable,
        [
          'run',
          'tool/ct_repo_lint.dart',
          '--rule',
          'repo.logic_test_file_size',
          '--force-full-scan',
          '--verbose',
        ],
        workingDirectory: repoRoot,
      );
      final combined =
          '${result.stdout.toString()}\n${result.stderr.toString()}';
      expect(result.exitCode, 0, reason: combined);
      expect(
        combined,
        isNot(contains('skipped')),
        reason:
            'The PR-incremental skip path was removed for #2288; '
            '`ct_repo_lint --rule repo.logic_test_file_size --force-full-scan` '
            'must scan the whole `packages/colonizethis_logic/test/**` tree.',
      );
    },
    timeout: const Timeout(Duration(minutes: 2)),
  );
}
