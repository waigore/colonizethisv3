import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;

/// PR-blocking structural check: production UI surface under `app/lib/features/`
/// must resolve colors through `EditorialMonoclePalette` tokens (and
/// `CtGradients`) rather than hard-coded Material color literals or raw
/// `const Color(0x...)` hex values.
///
/// SPEC:
/// - `SPEC/ui/pixel-art-ui-catalog.md` § Editorial-monocle palette / Dialog scrim
/// - `SPEC/ui/pixel-art-ui-catalog.md` § Hard-coded color ban (this rule)
/// - `SPEC/program/repo-lint.md`
///
/// Refs #2914 (target state §1, Phase 2 §G1).
///
/// Scope (production UI surface, non-test, non-generated):
/// - `app/lib/features/**/*.dart`
///
/// Skipped (whole-file path exclusions per repo-lint scope-only policy in
/// `SPEC/program/repo-lint.md` § "Policy: no violation allowlists"):
///
/// 1. **Flame canvas renderers** — these files paint to `Canvas` via `Paint`
///    objects (no `Color` extension through the Flutter theme) and may
///    legitimately use raw `Colors.black` / `Colors.white` for stroke/fill
///    where palette tokens are non-`const`. See `SPEC/ui/map-widget.md`.
/// 2. **Pixel-art palette data files** — generated lookup tables of named
///    colors (per-resource hue references) keyed by id; the table values are
///    the palette source for those resources rather than a bypass of the
///    editorial-monocle theme.
/// 3. **Dev-tooling screens** — `SYS10001` Debug Log Viewer and `SYS20001`
///    Debug Console Overlay are operator-only surfaces; implementing Ct-*
///    catalog widgets there is low-value (see #2914 Risks / edge cases).
/// 4. **`app/lib/features/game/widgets/chrome/**`** — Ct-* catalog widget
///    implementations. These widgets implement the design-system primitives
///    consumed by the rest of the feature tree and may declare `const`
///    fallbacks where palette tokens are non-`const`. Consumer code in
///    `features/**` must still use the catalog widget, not raw Material
///    colors.
///
/// Per-line skips:
/// - Lines starting with `//` (line comments) and `///` (dartdoc) so this
///   document and similar narrative references in source can mention the
///   banned tokens by name without tripping the check.
int runCheckAppEditorialMonocleColors(
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
    logE(
      'check_app_editorial_monocle_colors: app/lib/features not found.',
    );
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
    if (_shouldSkipAppEditorialMonocleColorsFile(relativePath)) {
      continue;
    }

    final lines = const LineSplitter().convert(entity.readAsStringSync());
    for (var i = 0; i < lines.length; i++) {
      final line = lines[i];
      final trimmed = line.trimLeft();
      if (trimmed.startsWith('//')) {
        // Also covers '///' dartdoc — see header note.
        continue;
      }
      final match = bannedColorLiteralPattern.firstMatch(line);
      if (match == null) {
        continue;
      }
      violations.add(
        '$relativePath:${i + 1}: ${match.group(0)!} -> use '
        'EditorialMonoclePalette token (see SPEC/ui/pixel-art-ui-catalog.md '
        '§ Editorial-monocle palette)',
      );
    }
  }

  if (violations.isEmpty) {
    logI(
      'check_app_editorial_monocle_colors: no violations found.',
    );
    return 0;
  }

  logE(
    'check_app_editorial_monocle_colors: found ${violations.length} '
    'violation(s) under app/lib/features/ (banned hard-coded color literal; '
    'use EditorialMonoclePalette token or a Ct-* catalog widget):',
  );
  for (final violation in violations) {
    logE(' - $violation');
  }
  return 1;
}

/// True when [relativePath] (POSIX, repo-rooted) is in scope for the checker
/// but allowlisted as a whole-file scope exclusion (Flame renderer, palette
/// data, dev tooling screen, or Ct-* catalog widget under
/// `features/game/widgets/chrome/`).
///
/// Exposed for `test/check_app_editorial_monocle_colors_test.dart`.
bool shouldSkipAppEditorialMonocleColorsFile(String relativePath) {
  return _shouldSkipAppEditorialMonocleColorsFile(relativePath);
}

bool _shouldSkipAppEditorialMonocleColorsFile(String relativePath) {
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
  if (_appEditorialMonocleColorsAllowedFiles.contains(relativePath)) {
    return true;
  }
  for (final prefix in _appEditorialMonocleColorsAllowedDirPrefixes) {
    if (relativePath.startsWith(prefix)) {
      return true;
    }
  }
  return false;
}

/// Banned Material color literals (with common opacity / grade variants such
/// as `Colors.black54`, `Colors.white70`, `Colors.redAccent100`) plus raw
/// `const Color(0x...)` hex literals. Pattern is intentionally narrow to the
/// `#2914` § Hardcoded color bypasses list and does not include
/// `Colors.transparent` (legitimate for hit-testing / non-rendering surfaces).
///
/// Exposed for unit tests.
final RegExp bannedColorLiteralPattern = RegExp(
  // Named Material colors from #2914 § Hardcoded color bypasses, with
  // optional Material opacity / grade suffix (digits after the base name)
  // and optional `Accent` variant for red/green.
  r'\bColors\.(?:'
  r'black\w*'
  r'|white\w*'
  r'|red(?:Accent)?\w*'
  r'|green(?:Accent)?\w*'
  r'|grey\w*|gray\w*'
  r')\b'
  r'|'
  // Raw `const Color(0x...)` hex literal — bypasses the palette entirely.
  r'\bconst\s+Color\s*\(\s*0x',
);

const Set<String> _appEditorialMonocleColorsAllowedFiles = <String>{
  // Flame canvas renderers — `Paint().color` / `TextPaint(...)`-style draws.
  'app/lib/features/game/flame/region_map_component_render_core.dart',
  'app/lib/features/game/flame/region_map_component_render_political.dart',
  'app/lib/features/game/flame/region_map_component_render_markers.dart',
  'app/lib/features/game/flame/game_region_minimap.dart',
  // Pixel-art palette data (per-resource hue lookup table).
  'app/lib/features/game/flame/resource_icon_disc_palette.dart',
  // Dev-tooling screens — SYS10001 (Debug Log Viewer) and SYS20001
  // (Debug Console Overlay). Relaxed per #2914 Risks / edge cases.
  'app/lib/features/debug_log/debug_log_viewer_screen.dart',
  'app/lib/features/game/flame/debug_console_overlay_panel.dart',
};

const Set<String> _appEditorialMonocleColorsAllowedDirPrefixes = <String>{
  // Ct-* catalog widgets implementing design-system primitives. Consumers
  // in features/** still resolve colors through these widgets, not raw
  // Material colors.
  'app/lib/features/game/widgets/chrome/',
};

void main() {
  exit(runCheckAppEditorialMonocleColors(Directory.current.path));
}
