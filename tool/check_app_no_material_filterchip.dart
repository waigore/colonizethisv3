import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;

/// PR-blocking structural check: production UI surface under `app/lib/features/`
/// must not construct the Material `FilterChip` widget (or its `.elevated`
/// named constructor) as visible chrome. Single-select toggle chips and
/// multi-select pickers must compose `CtChoiceChip` rows so chip chrome
/// stays inside the editorial-monocle token surface end-to-end.
///
/// SPEC:
/// - `SPEC/ui/pixel-art-ui-catalog.md` § Material design ban (Ct-* counterparts)
/// - `SPEC/ui/pixel-art-ui-catalog.md` § Pixel-art component catalog — CtChoiceChip
/// - `SPEC/program/repo-lint.md`
///
/// Refs #2914 (Phase 2 §G2 — Material widget bans extended beyond IconButton /
/// AlertDialog / TextButton / Scaffold).
///
/// Scope (production UI surface, non-test, non-generated):
/// - `app/lib/features/**/*.dart`
///
/// Skipped (whole-file path exclusions per repo-lint scope-only policy in
/// `SPEC/program/repo-lint.md` § "Policy: no violation allowlists"):
///
/// 1. **Dev-tooling screens** — `SYS10001` Debug Log Viewer
///    (`app/lib/features/debug_log/debug_log_viewer_screen.dart`) and
///    `SYS20001` Debug Console Overlay
///    (`app/lib/features/game/flame/debug_console_overlay_panel.dart`) are
///    operator-only surfaces; implementing Ct-* catalog widgets there is
///    low-value (see #2914 Risks / edge cases). The allowlist mirrors the
///    sibling `repo.app_no_material_iconbutton`,
///    `repo.app_no_material_alertdialog`,
///    `repo.app_no_material_textbutton`, and
///    `repo.app_no_material_scaffold` rules so the Material-widget ban
///    family stays scope-uniform across rules.
/// 2. **`app/lib/features/game/widgets/chrome/**`** — Ct-* catalog widget
///    implementations. These widgets implement the design-system
///    primitives consumed by the rest of the feature tree and may
///    compose Material primitives internally. Consumer code in
///    `features/**` must still resolve chip chrome through the catalog
///    widget, not a raw `FilterChip`.
///
/// Per-line skips:
/// - Lines starting with `//` (line comments) and `///` (dartdoc) so this
///   document and similar narrative references in source can mention the
///   banned token by name without tripping the check.
int runCheckAppNoMaterialFilterChip(
  String repoRoot, {
  void Function(String line)? info,
  void Function(String line)? err,
}) {
  final logI = info ?? stdout.writeln;
  final logE = err ?? stderr.writeln;

  final featuresDir = Directory(p.join(repoRoot, 'app', 'lib', 'features'));
  if (!featuresDir.existsSync()) {
    logE('check_app_no_material_filterchip: app/lib/features not found.');
    return 1;
  }

  final violations = <String>[];
  for (final entity in featuresDir.listSync(
    recursive: true,
    followLinks: false,
  )) {
    if (entity is! File || !entity.path.endsWith('.dart')) {
      continue;
    }
    final relativePath = p
        .relative(entity.path, from: repoRoot)
        .replaceAll('\\', '/');
    if (_shouldSkipAppNoMaterialFilterChipFile(relativePath)) {
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
      final match = bannedFilterChipConstructionPattern.firstMatch(line);
      if (match == null) {
        continue;
      }
      violations.add(
        '$relativePath:${i + 1}: ${match.group(0)!} -> use CtChoiceChip '
        '(see SPEC/ui/pixel-art-ui-catalog.md § Pixel-art component '
        'catalog — CtChoiceChip); compose multi-select pickers as a row '
        'of CtChoiceChip widgets, no Material FilterChip on visible chrome',
      );
    }
  }

  if (violations.isEmpty) {
    logI('check_app_no_material_filterchip: no violations found.');
    return 0;
  }

  logE(
    'check_app_no_material_filterchip: found ${violations.length} '
    'violation(s) under app/lib/features/ (banned Material FilterChip '
    'construction; use CtChoiceChip):',
  );
  for (final violation in violations) {
    logE(' - $violation');
  }
  return 1;
}

/// True when [relativePath] (POSIX, repo-rooted) is in scope for the checker
/// but allowlisted as a whole-file scope exclusion (dev tooling screen or
/// Ct-* catalog widget under `features/game/widgets/chrome/`).
///
/// Exposed for `test/check_app_no_material_filterchip_test.dart`.
bool shouldSkipAppNoMaterialFilterChipFile(String relativePath) {
  return _shouldSkipAppNoMaterialFilterChipFile(relativePath);
}

bool _shouldSkipAppNoMaterialFilterChipFile(String relativePath) {
  // Generated suffixes — never scan.
  if (relativePath.endsWith('.g.dart') ||
      relativePath.endsWith('.freezed.dart') ||
      relativePath.endsWith('.mocks.dart') ||
      relativePath.endsWith('.gen.dart')) {
    return true;
  }
  // Test files — production UI surface only.
  if (relativePath.endsWith('_test.dart') || relativePath.contains('/test/')) {
    return true;
  }
  if (_appNoMaterialFilterChipAllowedFiles.contains(relativePath)) {
    return true;
  }
  for (final prefix in _appNoMaterialFilterChipAllowedDirPrefixes) {
    if (relativePath.startsWith(prefix)) {
      return true;
    }
  }
  return false;
}

/// Banned construction syntax: `FilterChip(` and `FilterChip.elevated(`.
/// Allows trailing whitespace between the identifier (or named constructor)
/// and the opening parenthesis, as Dart's formatter often inserts a space or
/// newline before nested argument lists.
///
/// The leading `\b` word boundary keeps the pattern from matching
/// identifiers that contain `FilterChip` as a suffix (e.g. `MyFilterChip`).
///
/// Exposed for unit tests.
final RegExp bannedFilterChipConstructionPattern = RegExp(
  r'\bFilterChip(?:\.elevated)?\s*\(',
);

const Set<String> _appNoMaterialFilterChipAllowedFiles = <String>{
  // Dev-tooling screens — SYS10001 (Debug Log Viewer) and SYS20001
  // (Debug Console Overlay). Relaxed per #2914 Risks / edge cases.
  // Mirrors the sibling repo.app_no_material_iconbutton,
  // repo.app_no_material_alertdialog, repo.app_no_material_textbutton,
  // and repo.app_no_material_scaffold allowlists so the Material-widget
  // ban family stays scope-uniform across rules.
  'app/lib/features/debug_log/debug_log_viewer_screen.dart',
  'app/lib/features/game/flame/debug_console_overlay_panel.dart',
};

const Set<String> _appNoMaterialFilterChipAllowedDirPrefixes = <String>{
  // Ct-* catalog widgets implementing design-system primitives. Consumers
  // in features/** still resolve chip chrome through these widgets, not
  // raw Material FilterChip.
  'app/lib/features/game/widgets/chrome/',
};

void main() {
  exit(runCheckAppNoMaterialFilterChip(Directory.current.path));
}
