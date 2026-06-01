import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;

/// PR-blocking structural check: production UI surface under `app/lib/features/`
/// must not construct the Material `AlertDialog` widget as visible chrome.
/// Dialog popups (confirm dialogs, alert popups, single-action prompts, and
/// destructive-confirmation sub-dialogs) resolve through `CtDialogShell`
/// (single dialog frame) or `CtFullScreenDialogueShell` (scrim + dialog
/// scaffold), with the `dialogScrim` token providing the barrier color so
/// dialog chrome stays inside the editorial-monocle token surface end-to-end.
///
/// SPEC:
/// - `SPEC/ui/pixel-art-ui-catalog.md` § Material design ban (Ct-* counterparts)
/// - `SPEC/ui/pixel-art-ui-catalog.md` § Pixel-art component catalog — CtDialogShell
/// - `SPEC/program/repo-lint.md`
///
/// Refs #2914 (Phase 2 §G2 — Material widget bans extended beyond IconButton).
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
///    low-value (see #2914 Risks / edge cases). Currently neither file
///    constructs `AlertDialog`, but the allowlist mirrors the sibling
///    `repo.app_no_material_iconbutton` rule so the scope contract stays
///    uniform across the Material-widget ban family.
/// 2. **`app/lib/features/game/widgets/chrome/**`** — Ct-* catalog widget
///    implementations. These widgets implement the design-system
///    primitives consumed by the rest of the feature tree and may
///    compose Material primitives internally. Consumer code in
///    `features/**` must still use the catalog widget, not a raw
///    `AlertDialog`.
///
/// Per-line skips:
/// - Lines starting with `//` (line comments) and `///` (dartdoc) so this
///   document and similar narrative references in source can mention the
///   banned token by name without tripping the check.
int runCheckAppNoMaterialAlertDialog(
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
    logE('check_app_no_material_alertdialog: app/lib/features not found.');
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
    if (_shouldSkipAppNoMaterialAlertDialogFile(relativePath)) {
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
      final match = bannedAlertDialogConstructionPattern.firstMatch(line);
      if (match == null) {
        continue;
      }
      violations.add(
        '$relativePath:${i + 1}: ${match.group(0)!} -> use CtDialogShell '
        '(see SPEC/ui/pixel-art-ui-catalog.md § Pixel-art component '
        'catalog — CtDialogShell) or CtFullScreenDialogueShell for '
        'scrim + dialog scaffolds',
      );
    }
  }

  if (violations.isEmpty) {
    logI('check_app_no_material_alertdialog: no violations found.');
    return 0;
  }

  logE(
    'check_app_no_material_alertdialog: found ${violations.length} '
    'violation(s) under app/lib/features/ (banned Material AlertDialog '
    'construction; use CtDialogShell / CtFullScreenDialogueShell):',
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
/// Exposed for `test/check_app_no_material_alertdialog_test.dart`.
bool shouldSkipAppNoMaterialAlertDialogFile(String relativePath) {
  return _shouldSkipAppNoMaterialAlertDialogFile(relativePath);
}

bool _shouldSkipAppNoMaterialAlertDialogFile(String relativePath) {
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
  if (_appNoMaterialAlertDialogAllowedFiles.contains(relativePath)) {
    return true;
  }
  for (final prefix in _appNoMaterialAlertDialogAllowedDirPrefixes) {
    if (relativePath.startsWith(prefix)) {
      return true;
    }
  }
  return false;
}

/// Banned construction syntax: `AlertDialog(` and `AlertDialog.adaptive(`.
/// Allows trailing whitespace between the identifier (or named constructor)
/// and the opening parenthesis, as Dart's formatter often inserts a space or
/// newline before nested argument lists.
///
/// Exposed for unit tests.
final RegExp bannedAlertDialogConstructionPattern = RegExp(
  r'\bAlertDialog(?:\.adaptive)?\s*\(',
);

const Set<String> _appNoMaterialAlertDialogAllowedFiles = <String>{
  // Dev-tooling screens — SYS10001 (Debug Log Viewer) and SYS20001
  // (Debug Console Overlay). Relaxed per #2914 Risks / edge cases.
  // Mirrors the sibling repo.app_no_material_iconbutton allowlist so the
  // Material-widget ban family stays scope-uniform across rules.
  'app/lib/features/debug_log/debug_log_viewer_screen.dart',
  'app/lib/features/game/flame/debug_console_overlay_panel.dart',
};

const Set<String> _appNoMaterialAlertDialogAllowedDirPrefixes = <String>{
  // Ct-* catalog widgets implementing design-system primitives. Consumers
  // in features/** still resolve dialog popups through these widgets, not
  // raw Material AlertDialog.
  'app/lib/features/game/widgets/chrome/',
};

void main() {
  exit(runCheckAppNoMaterialAlertDialog(Directory.current.path));
}
