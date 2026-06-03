import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;

/// PR-blocking structural check: production UI surface under `app/lib/features/`
/// must not construct the Material `Scaffold` widget as visible chrome.
/// Screen-level chrome resolves through `CtGameFeatureScreenShell` (game-bound
/// feature screens, with the optional `backgroundColor` for per-screen
/// mockup backgrounds) or `CtScreenShell` (shell-bound utility screens).
/// Both Ct-* shells own the editorial-monocle background, `SafeArea`, and
/// top-bar / panel chrome so consumers do not hand-roll [Scaffold] in
/// feature code.
///
/// SPEC:
/// - `SPEC/ui/pixel-art-ui-catalog.md` § Material design ban (Ct-* counterparts)
/// - `SPEC/ui/pixel-art-ui-catalog.md` § Pixel-art component catalog —
///   CtGameFeatureScreenShell / CtScreenShell
/// - `SPEC/program/repo-lint.md`
///
/// Refs #2914 (Phase 2 §G2 — Material widget bans extended beyond
/// IconButton / AlertDialog / TextButton to cover Scaffold).
///
/// Scope (production UI surface, non-test, non-generated):
/// - `app/lib/features/**/*.dart`
///
/// Skipped (whole-file path exclusions per repo-lint scope-only policy in
/// `SPEC/program/repo-lint.md` § "Policy: no violation allowlists"):
///
/// 1. **Dev-tooling screens** — `SYS20001` Debug Console Overlay
///    (`app/lib/features/game/flame/debug_console_overlay_panel.dart`) are
///    operator-only surfaces; implementing Ct-* catalog widgets there is
///    low-value (see #2914 Risks / edge cases). The allowlist mirrors the
///    sibling `repo.app_no_material_iconbutton`,
///    `repo.app_no_material_alertdialog`, and
///    `repo.app_no_material_textbutton` rules so the Material-widget ban
///    family stays scope-uniform across rules.
/// 2. **`app/lib/features/game/widgets/chrome/**`** — Ct-* catalog widget
///    implementations. These widgets implement the design-system
///    primitives consumed by the rest of the feature tree and may
///    compose Material primitives internally. Consumer code in
///    `features/**` must still resolve screen chrome through the
///    catalog shell, not a raw `Scaffold`.
///
/// Per-line skips:
/// - Lines starting with `//` (line comments) and `///` (dartdoc) so this
///   document and similar narrative references in source can mention the
///   banned token by name without tripping the check.
///
/// Out-of-scope (intentionally not banned) sites the lint should never
/// flag, captured by the regex shape:
/// - `ScaffoldMessenger` and `ScaffoldState` are distinct identifiers
///   (different word boundaries) and remain available for snackbar /
///   imperative chrome interactions where required.
/// - `Scaffold.of(context)` and other static member accesses do not match
///   because the regex anchors on an opening parenthesis after the
///   `Scaffold` token.
int runCheckAppNoMaterialScaffold(
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
    logE('check_app_no_material_scaffold: app/lib/features not found.');
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
    if (_shouldSkipAppNoMaterialScaffoldFile(relativePath)) {
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
      final match = bannedScaffoldConstructionPattern.firstMatch(line);
      if (match == null) {
        continue;
      }
      violations.add(
        '$relativePath:${i + 1}: ${match.group(0)!} -> use '
        'CtGameFeatureScreenShell (game-bound feature screens) or '
        'CtScreenShell (shell-bound utility screens); see '
        'SPEC/ui/pixel-art-ui-catalog.md § Pixel-art component catalog',
      );
    }
  }

  if (violations.isEmpty) {
    logI('check_app_no_material_scaffold: no violations found.');
    return 0;
  }

  logE(
    'check_app_no_material_scaffold: found ${violations.length} '
    'violation(s) under app/lib/features/ (banned Material Scaffold '
    'construction; use CtGameFeatureScreenShell / CtScreenShell):',
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
/// Exposed for `test/check_app_no_material_scaffold_test.dart`.
bool shouldSkipAppNoMaterialScaffoldFile(String relativePath) {
  return _shouldSkipAppNoMaterialScaffoldFile(relativePath);
}

bool _shouldSkipAppNoMaterialScaffoldFile(String relativePath) {
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
  if (_appNoMaterialScaffoldAllowedFiles.contains(relativePath)) {
    return true;
  }
  for (final prefix in _appNoMaterialScaffoldAllowedDirPrefixes) {
    if (relativePath.startsWith(prefix)) {
      return true;
    }
  }
  return false;
}

/// Banned construction syntax: `Scaffold(`. Allows trailing whitespace
/// between the identifier and the opening parenthesis, as Dart's formatter
/// often inserts a space or newline before nested argument lists.
///
/// The leading `\b` word boundary keeps the pattern from matching
/// identifiers that contain `Scaffold` as a suffix (e.g. `MyScaffold`).
/// The trailing `(?![A-Za-z_])` zero-width negative lookahead keeps
/// `ScaffoldMessenger` and `ScaffoldState` out of scope because those
/// identifiers continue past the `Scaffold` token before any `(` appears.
/// Static member accesses (`Scaffold.of(`, `Scaffold.maybeOf(`) do not
/// match because the regex requires an opening parenthesis immediately
/// after the `Scaffold` token (optionally separated by whitespace), not
/// after a `.`-qualified member.
///
/// Exposed for unit tests.
final RegExp bannedScaffoldConstructionPattern = RegExp(
  r'\bScaffold(?![A-Za-z_])\s*\(',
);

const Set<String> _appNoMaterialScaffoldAllowedFiles = <String>{
  // Dev-tooling screens — SYS10001 (Debug Log Viewer) and SYS20001
  // (Debug Console Overlay). Relaxed per #2914 Risks / edge cases.
  // Mirrors the sibling repo.app_no_material_iconbutton,
  // repo.app_no_material_alertdialog, and repo.app_no_material_textbutton
  // allowlists so the Material-widget ban family stays scope-uniform
  // across rules.
  'app/lib/features/game/flame/debug_console_overlay_panel.dart',
};

const Set<String> _appNoMaterialScaffoldAllowedDirPrefixes = <String>{
  // Ct-* catalog widgets implementing design-system primitives. Consumers
  // in features/** still resolve screen chrome through these widgets,
  // not raw Material Scaffold.
  'app/lib/features/game/widgets/chrome/',
};

void main() {
  exit(runCheckAppNoMaterialScaffold(Directory.current.path));
}
