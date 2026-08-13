// Process stdout/stderr forwarding for `ct_repo_lint` child runs.
// Extracted so `ct_repo_lint_lib.dart` stays under the
// `repo.dart_file_non_comment_line_size` 1000-NCL ceiling (Refs #4344).

import 'dart:io';

void forwardRepoLintProcessOutput(
  ProcessResult result, {
  required bool relayStdoutToStderr,
}) {
  final out = result.stdout.toString();
  final err = result.stderr.toString();
  if (out.isNotEmpty) {
    if (relayStdoutToStderr) {
      stderr.write(out);
    } else {
      stdout.write(out);
    }
  }
  if (err.isNotEmpty) {
    stderr.write(err);
  }
}
