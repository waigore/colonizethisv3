import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;

/// PR-blocking structural check: turn test support under
/// `packages/colonizethis_turn/test/support/` must not hard-code canonical
/// world region ids as bare string literals (`'oldWorld'` / `'newWorld'`).
/// Use `kRegionOldWorld` / `kRegionNewWorld` from
/// `package:colonizethis_logic/colonizethis_logic.dart`.
///
/// SPEC:
/// - `SPEC/program/logic-dual-region-province-access.md`
/// - `SPEC/program/repo-lint.md`
///
/// Refs #4168 (turn test support region-id SoT).
///
/// Scope: `packages/colonizethis_turn/test/support/**/*.dart`
///
/// Skipped:
/// - Generated suffixes (`*.g.dart`, `*.freezed.dart`, `*.mocks.dart`, `*.gen.dart`)
///
/// Per-line skips:
/// - Lines starting with `//` or `///` (comments / dartdoc).
int runCheckTurnTestSupportRegionLiterals(
  String repoRoot, {
  void Function(String line)? info,
  void Function(String line)? err,
}) {
  final logI = info ?? stdout.writeln;
  final logE = err ?? stderr.writeln;

  final supportDir = Directory(
    p.join(repoRoot, 'packages', 'colonizethis_turn', 'test', 'support'),
  );
  if (!supportDir.existsSync()) {
    logE('check_turn_test_support_region_literals: support dir not found.');
    return 1;
  }

  final violations = <String>[];
  for (final entity in supportDir.listSync(recursive: true, followLinks: false)) {
    if (entity is! File || !entity.path.endsWith('.dart')) {
      continue;
    }
    final relativePath = p
        .relative(entity.path, from: repoRoot)
        .replaceAll('\\', '/');
    if (_shouldSkipTurnTestSupportRegionLiteralsFile(relativePath)) {
      continue;
    }

    final lines = const LineSplitter().convert(entity.readAsStringSync());
    for (var i = 0; i < lines.length; i++) {
      final line = lines[i];
      final trimmed = line.trimLeft();
      if (trimmed.startsWith('//')) {
        continue;
      }
      final match = bannedRegionStringLiteralPattern.firstMatch(line);
      if (match == null) {
        continue;
      }
      violations.add(
        '$relativePath:${i + 1}: ${match.group(0)!} -> use kRegionOldWorld / '
        'kRegionNewWorld (package:colonizethis_logic/colonizethis_logic.dart; '
        'see SPEC/program/logic-dual-region-province-access.md)',
      );
    }
  }

  if (violations.isEmpty) {
    logI('check_turn_test_support_region_literals: no violations found.');
    return 0;
  }

  logE(
    'check_turn_test_support_region_literals: found ${violations.length} '
    "violation(s) under packages/colonizethis_turn/test/support/ (bare "
    "'oldWorld' / 'newWorld' string literal; use kRegionOldWorld / "
    'kRegionNewWorld):',
  );
  for (final violation in violations) {
    logE(' - $violation');
  }
  return 1;
}

/// Exposed for `test/check_turn_test_support_region_literals_test.dart`.
bool shouldSkipTurnTestSupportRegionLiteralsFile(String relativePath) {
  return _shouldSkipTurnTestSupportRegionLiteralsFile(relativePath);
}

bool _shouldSkipTurnTestSupportRegionLiteralsFile(String relativePath) {
  if (relativePath.endsWith('.g.dart') ||
      relativePath.endsWith('.freezed.dart') ||
      relativePath.endsWith('.mocks.dart') ||
      relativePath.endsWith('.gen.dart')) {
    return true;
  }
  return false;
}

/// Banned literal syntax — same contract as [check_app_region_string_literals].
final RegExp bannedRegionStringLiteralPattern = RegExp(
  r'''(['"])(oldWorld|newWorld)\1''',
);

void main() {
  exit(runCheckTurnTestSupportRegionLiterals(Directory.current.path));
}
