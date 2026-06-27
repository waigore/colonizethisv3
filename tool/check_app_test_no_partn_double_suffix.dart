// Pins the documented split-test-family naming convention for the `app`
// package (Refs #3730 AC3). Several large widget/screen suites are split into
// numbered fragments to stay under the `repo.dart_file_non_comment_line_size`
// cap. Before this gate they used an awkward double `_test` suffix
// (`military_units_panel_test_part1_test.dart`), which reads as "a test of a
// test part" and obscures the family. The single documented convention is
// `<family>_part<N>_test.dart` (matching the already-clean
// `province_panel_draft_orders_part2_test.dart` and the repo-lint
// `order_merge_part1_test.dart` precedent).
//
// This gate forbids any `app/test/**` Dart file whose basename matches the
// `<name>_test_part<N>_test.dart` double-suffix pattern. New split families
// must drop the inner `_test`, naming fragments `<family>_part<N>_test.dart`.
//
// SPEC: SPEC/program/repo-lint.md
import 'dart:io';

import 'package:path/path.dart' as p;

/// Directory tree holding the `app` package widget/screen tests.
const String appTestDirPath = 'app/test';

/// Matches the disallowed double `_test` split-family fragment basenames such
/// as `military_units_panel_test_part1_test.dart` or
/// `naval_units_panel_test_part12_test.dart`. Case-insensitive on the `part`
/// token for safety; the leading `<name>` group requires at least one char so
/// a bare `_test_part1_test.dart` would also be flagged.
final RegExp _doubleSuffixPartFileName = RegExp(
  r'^.+_test_part\d+_test\.dart$',
  caseSensitive: false,
);

/// True when [fileName] (basename only) is a forbidden double-suffix split
/// fragment.
bool isDoubleSuffixPartFileName(String fileName) =>
    _doubleSuffixPartFileName.hasMatch(fileName);

int runCheckAppTestNoPartNDoubleSuffix(
  String repoRoot, {
  void Function(String line)? info,
  void Function(String line)? err,
}) {
  final logI = info ?? stdout.writeln;
  final logE = err ?? stderr.writeln;

  final testDir = Directory(p.join(repoRoot, appTestDirPath));
  if (!testDir.existsSync()) {
    // No app/test directory in this checkout (e.g. partial tree): nothing to
    // enforce, treat as a pass.
    logI(
      'check_app_test_no_partn_double_suffix: $appTestDirPath not found; '
      'nothing to check.',
    );
    return 0;
  }

  final violations = <String>[];
  final dartFiles = testDir
      .listSync(recursive: true, followLinks: false)
      .whereType<File>()
      .where((f) => f.path.endsWith('.dart'))
      .toList()
    ..sort((a, b) => a.path.compareTo(b.path));

  for (final file in dartFiles) {
    final fileName = p.basename(file.path);
    if (!isDoubleSuffixPartFileName(fileName)) {
      continue;
    }
    final rel = p.relative(file.path, from: repoRoot).replaceAll('\\', '/');
    violations.add(
      '$rel: double `_test` split-family fragment is disallowed — rename it to '
      'the documented convention <family>_part<N>_test.dart (drop the inner '
      '`_test`) so split suites read cleanly (Refs #3730)',
    );
  }

  if (violations.isEmpty) {
    logI(
      'check_app_test_no_partn_double_suffix: app/test split families use the '
      '<family>_part<N>_test.dart convention (no _test_partN_test.dart '
      'double suffix).',
    );
    return 0;
  }
  logE(
    'check_app_test_no_partn_double_suffix: ${violations.length} violation(s):',
  );
  for (final violation in violations) {
    logE(' - $violation');
  }
  return 1;
}

void main() {
  exit(runCheckAppTestNoPartNDoubleSuffix(Directory.current.path));
}
