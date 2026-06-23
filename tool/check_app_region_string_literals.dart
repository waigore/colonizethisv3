import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;

/// PR-blocking structural check: production app code under `app/lib/` must not
/// hard-code the canonical world region ids as bare string literals
/// (`'oldWorld'` / `'newWorld'`). The constants `kRegionOldWorld` /
/// `kRegionNewWorld` (defined in `colonizethis_world`, re-exported via
/// `package:colonizethis_logic/colonizethis_logic.dart`) are the single source
/// of truth and decouple the app from the magic strings.
///
/// SPEC:
/// - `SPEC/program/logic-dual-region-province-access.md` (canonical dual-region
///   access policy and `kRegion*` constants)
/// - `SPEC/program/repo-lint.md`
///
/// Refs #3658 (app dual-region helper + `kRegion` constant dedup).
///
/// Scope (production app surface, non-test, non-generated):
/// - `app/lib/**/*.dart`
///
/// Skipped (whole-file / whole-dir scope exclusions per repo-lint scope-only
/// policy in `SPEC/program/repo-lint.md`):
///
/// 1. **Generated files** — `*.g.dart`, `*.freezed.dart`, `*.mocks.dart`,
///    `*.gen.dart`.
/// 2. **Test files** — `*_test.dart` and anything under a `/test/` segment
///    (production surface only).
/// 3. **`app/lib/l10n/**`** — generated/authored localization carries region
///    ids as ARB keys / identifiers, not as the magic data-derivation literals
///    this rule targets.
/// 4. **`app/lib/test_support/**`** and **`app/lib/widgetbook/**`** — demo and
///    expected-line fixtures. The #3658 migration deferred these; they are
///    sanctioned directory-scoped exceptions.
///
/// Per-line skips:
/// - Lines starting with `//` (line comments) and `///` (dartdoc) so narrative
///   references can mention the banned token by name without tripping the
///   check.
int runCheckAppRegionStringLiterals(
  String repoRoot, {
  void Function(String line)? info,
  void Function(String line)? err,
}) {
  final logI = info ?? stdout.writeln;
  final logE = err ?? stderr.writeln;

  final libDir = Directory(p.join(repoRoot, 'app', 'lib'));
  if (!libDir.existsSync()) {
    logE('check_app_region_string_literals: app/lib not found.');
    return 1;
  }

  final violations = <String>[];
  for (final entity in libDir.listSync(recursive: true, followLinks: false)) {
    if (entity is! File || !entity.path.endsWith('.dart')) {
      continue;
    }
    final relativePath = p
        .relative(entity.path, from: repoRoot)
        .replaceAll('\\', '/');
    if (_shouldSkipAppRegionStringLiteralsFile(relativePath)) {
      continue;
    }

    final lines = const LineSplitter().convert(entity.readAsStringSync());
    for (var i = 0; i < lines.length; i++) {
      final line = lines[i];
      final trimmed = line.trimLeft();
      if (trimmed.startsWith('//')) {
        // Covers '///' dartdoc as well — see header note.
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
    logI('check_app_region_string_literals: no violations found.');
    return 0;
  }

  logE(
    'check_app_region_string_literals: found ${violations.length} '
    "violation(s) under app/lib/ (bare 'oldWorld' / 'newWorld' string "
    'literal; use kRegionOldWorld / kRegionNewWorld):',
  );
  for (final violation in violations) {
    logE(' - $violation');
  }
  return 1;
}

/// True when [relativePath] (POSIX, repo-rooted) is out of scope for the
/// checker (generated, test, l10n, or a sanctioned fixture directory).
///
/// Exposed for `test/check_app_region_string_literals_test.dart`.
bool shouldSkipAppRegionStringLiteralsFile(String relativePath) {
  return _shouldSkipAppRegionStringLiteralsFile(relativePath);
}

bool _shouldSkipAppRegionStringLiteralsFile(String relativePath) {
  // Generated suffixes — never scan.
  if (relativePath.endsWith('.g.dart') ||
      relativePath.endsWith('.freezed.dart') ||
      relativePath.endsWith('.mocks.dart') ||
      relativePath.endsWith('.gen.dart')) {
    return true;
  }
  // Test files — production surface only.
  if (relativePath.endsWith('_test.dart') || relativePath.contains('/test/')) {
    return true;
  }
  if (_appRegionStringLiteralsAllowedFiles.contains(relativePath)) {
    return true;
  }
  for (final prefix in _appRegionStringLiteralsAllowedDirPrefixes) {
    if (relativePath.startsWith(prefix)) {
      return true;
    }
  }
  return false;
}

/// Banned literal syntax: a string literal whose entire content is exactly
/// `oldWorld` or `newWorld`, single- or double-quoted. The backreference (`\1`)
/// requires the closing quote to match the opening quote, and anchoring the
/// content prevents matching prefixed/composite ids (e.g. `'oldWorld|p1'`) or
/// identifiers (e.g. `l10n.region_oldWorld`, `'$kRegionOldWorld|'`).
///
/// Exposed for unit tests.
final RegExp bannedRegionStringLiteralPattern = RegExp(
  r'''(['"])(oldWorld|newWorld)\1''',
);

/// Whole-file scope exclusions (POSIX, repo-rooted). Empty by default; add a
/// justified entry here for any genuinely sanctioned remaining literal.
const Set<String> _appRegionStringLiteralsAllowedFiles = <String>{};

const Set<String> _appRegionStringLiteralsAllowedDirPrefixes = <String>{
  // Generated/authored localization — region ids appear as ARB keys /
  // identifiers, not data-derivation literals.
  'app/lib/l10n/',
  // Demo and expected-line fixtures. The #3658 migration deferred these to a
  // follow-up; sanctioned directory-scoped exceptions.
  'app/lib/test_support/',
  'app/lib/widgetbook/',
};

void main() {
  exit(runCheckAppRegionStringLiterals(Directory.current.path));
}
