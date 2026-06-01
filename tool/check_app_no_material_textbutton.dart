import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;

/// PR-blocking structural check: production UI surface under `app/lib/features/`
/// must not construct the Material `TextButton` widget as visible chrome.
/// Click affordances resolve through `CtNinePatchButton` (primary / secondary /
/// inline catalog button) for canonical brass-bracket chrome, or through
/// `CtDangerTextButton` for the small destructive text-styled affordance used
/// by `SPEC/ui/production-panel.md` § Labour Controls. Tap-only icon buttons
/// resolve through `CtIconAction` / `CtBackButton` (see the sibling
/// `repo.app_no_material_iconbutton` rule).
///
/// SPEC:
/// - `SPEC/ui/pixel-art-ui-catalog.md` § Material design ban (Ct-* counterparts)
/// - `SPEC/ui/pixel-art-ui-catalog.md` § Pixel-art component catalog — CtNinePatchButton
/// - `SPEC/program/repo-lint.md`
///
/// Refs #2914 (Phase 2 §G2 — Material widget bans extended beyond IconButton /
/// AlertDialog to cover TextButton).
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
///    sibling `repo.app_no_material_iconbutton` and
///    `repo.app_no_material_alertdialog` rules so the Material-widget ban
///    family stays scope-uniform across rules.
/// 2. **`app/lib/features/game/widgets/chrome/**`** — Ct-* catalog widget
///    implementations. These widgets implement the design-system
///    primitives consumed by the rest of the feature tree and may
///    compose Material primitives internally (for example
///    `CtDangerTextButton` historically borrowed text-button surface
///    semantics). Consumer code in `features/**` must still use the
///    catalog widget, not a raw `TextButton`.
///
/// Per-line skips:
/// - Lines starting with `//` (line comments) and `///` (dartdoc) so this
///   document and similar narrative references in source can mention the
///   banned token by name without tripping the check.
int runCheckAppNoMaterialTextButton(
  String repoRoot, {
  void Function(String line)? info,
  void Function(String line)? err,
}) {
  final logI = info ?? stdout.writeln;
  final logE = err ?? stderr.writeln;

  final featuresDir = Directory(
    p.join(repoRoot, 'app', 'lib', 'features'),
  );
  if (!featuresDir.existsSync()) {
    logE('check_app_no_material_textbutton: app/lib/features not found.');
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
    if (_shouldSkipAppNoMaterialTextButtonFile(relativePath)) {
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
      final match = bannedTextButtonConstructionPattern.firstMatch(line);
      if (match == null) {
        continue;
      }
      violations.add(
        '$relativePath:${i + 1}: ${match.group(0)!} -> use CtNinePatchButton '
        '(see SPEC/ui/pixel-art-ui-catalog.md § Pixel-art component '
        'catalog — CtNinePatchButton) or CtDangerTextButton for the '
        'small destructive text-styled affordance',
      );
    }
  }

  if (violations.isEmpty) {
    logI('check_app_no_material_textbutton: no violations found.');
    return 0;
  }

  logE(
    'check_app_no_material_textbutton: found ${violations.length} '
    'violation(s) under app/lib/features/ (banned Material TextButton '
    'construction; use CtNinePatchButton / CtDangerTextButton):',
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
/// Exposed for `test/check_app_no_material_textbutton_test.dart`.
bool shouldSkipAppNoMaterialTextButtonFile(String relativePath) {
  return _shouldSkipAppNoMaterialTextButtonFile(relativePath);
}

bool _shouldSkipAppNoMaterialTextButtonFile(String relativePath) {
  // Generated suffixes — never scan.
  if (relativePath.endsWith('.g.dart') ||
      relativePath.endsWith('.freezed.dart') ||
      relativePath.endsWith('.mocks.dart') ||
      relativePath.endsWith('.gen.dart')) {
    return true;
  }
  // Test files — production UI surface only.
  if (relativePath.endsWith('_test.dart') ||
      relativePath.contains('/test/')) {
    return true;
  }
  if (_appNoMaterialTextButtonAllowedFiles.contains(relativePath)) {
    return true;
  }
  for (final prefix in _appNoMaterialTextButtonAllowedDirPrefixes) {
    if (relativePath.startsWith(prefix)) {
      return true;
    }
  }
  return false;
}

/// Banned construction syntax: `TextButton(`, `TextButton.icon(`,
/// `TextButton.tonalIcon(`. Allows trailing whitespace between the
/// identifier (or named constructor) and the opening parenthesis, as
/// Dart's formatter often inserts a space or newline before nested
/// argument lists.
///
/// The leading `\b` word boundary keeps the pattern from matching
/// catalog widgets that contain `TextButton` as a suffix (notably
/// `CtDangerTextButton`), and the explicit named-constructor enumeration
/// keeps `TextButton.styleFrom(` (the static `ButtonStyle` factory used
/// when styling other widgets) out of scope so legitimate theme work is
/// not blocked.
///
/// Exposed for unit tests.
final RegExp bannedTextButtonConstructionPattern = RegExp(
  r'\bTextButton(?:\.(?:icon|tonalIcon))?\s*\(',
);

const Set<String> _appNoMaterialTextButtonAllowedFiles = <String>{
  // Dev-tooling screens — SYS10001 (Debug Log Viewer) and SYS20001
  // (Debug Console Overlay). Relaxed per #2914 Risks / edge cases.
  // Mirrors the sibling repo.app_no_material_iconbutton and
  // repo.app_no_material_alertdialog allowlists so the Material-widget
  // ban family stays scope-uniform across rules.
  'app/lib/features/debug_log/debug_log_viewer_screen.dart',
  'app/lib/features/game/flame/debug_console_overlay_panel.dart',
};

const Set<String> _appNoMaterialTextButtonAllowedDirPrefixes = <String>{
  // Ct-* catalog widgets implementing design-system primitives. Consumers
  // in features/** still resolve click affordances through these widgets,
  // not raw Material TextButton.
  'app/lib/features/game/widgets/chrome/',
};

void main() {
  exit(runCheckAppNoMaterialTextButton(Directory.current.path));
}
