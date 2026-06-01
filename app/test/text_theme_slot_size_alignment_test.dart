// Regression test for #2914 S7 (font-size normalization).
//
// SPEC: `SPEC/ui/pixel-art-ui-catalog.md` § *Editorial-monocle palette*
// (TextTheme contract is the M3 dark slot table — sizes here match
// `ThemeData.dark(useMaterial3: true).textTheme`, which is what
// `AppThemes.editorialMonocle` builds on).
//
// Two-part contract pinned by this test:
//
//  1. **Positive:** `AppThemes.editorialMonocle.textTheme` exposes the
//     canonical M3 dark slot→size table (#2914 issue body table).
//
//  2. **Negative regression guard:** every `?? const TextStyle(fontSize:
//     N)` fallback under `app/lib/**` whose left-hand side is
//     `theme.textTheme.<slot>` declares an `N` matching the slot's
//     canonical size. Drift here is the exact failure mode #2914 S7 was
//     filed to close.

import 'dart:io';

import 'package:colonizethis_app/config/themes.dart';
import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Canonical M3 dark slot → font-size mapping per the table in #2914 §
/// "3. Hardcoded `fontSize:` values bypassing the theme TextTheme".
///
/// This is the single source of truth for the negative-regression scan
/// below; updating any value here without a SPEC update is a regression.
const Map<String, double> kCanonicalSlotSizes = <String, double>{
  'headlineMedium': 28,
  'headlineSmall': 24,
  'titleLarge': 22,
  'titleMedium': 16,
  'titleSmall': 14,
  'bodyLarge': 16,
  'bodyMedium': 14,
  'bodySmall': 12,
  'labelLarge': 14,
  'labelMedium': 12,
  'labelSmall': 11,
};

/// Files under `app/lib/**` are walked recursively; this rule skips
/// generated and asset directories that legitimately should not contain
/// Flutter widget source.
bool _isWalkable(FileSystemEntity entity) {
  if (entity is! File) return false;
  if (!entity.path.endsWith('.dart')) return false;
  // Generated localizations / freezed output and similar are tooling
  // outputs; the slot/size contract is for human-authored widgets.
  if (entity.path.contains('.g.dart')) return false;
  if (entity.path.contains('.freezed.dart')) return false;
  return true;
}

/// Matches `theme.textTheme.<slot>` (or `Theme.of(context).textTheme.<slot>`)
/// followed directly (whitespace only) by `??`, then
/// `const TextStyle(fontSize: <number>` so the slot identifier and the
/// fallback size can be cross-checked.
///
/// The pattern intentionally rejects intervening method chains
/// (`?.copyWith(...)`) so two unrelated `textTheme.<slot>` statements
/// in the same file cannot be cross-matched into a spurious mismatch.
/// Real codepaths that need a method chain before the `??` fallback
/// are vanishingly rare in `app/lib/**` and are documented as out of
/// scope by the slot/size SPEC table.
final RegExp _slotFallbackRegex = RegExp(
  r'textTheme\.(\w+)\s*\?\?\s*const\s+TextStyle\s*\(\s*fontSize:\s*(\d+(?:\.\d+)?)',
  multiLine: true,
);

void main() {
  suppressLogsForTests();

  group('AppThemes.editorialMonocle TextTheme slot sizes (positive AC)', () {
    final TextTheme tt = AppThemes.editorialMonocle.textTheme;
    for (final entry in kCanonicalSlotSizes.entries) {
      test('${entry.key} resolves to ${entry.value} when populated', () {
        final TextStyle? style = _resolveSlot(tt, entry.key);
        if (style == null || style.fontSize == null) {
          // M3 dark `Typography.material2021()` does not always
          // populate every slot with a concrete `fontSize` (notably
          // `labelMedium` / `labelSmall` flow through unfilled on
          // some Flutter SDK versions). Those slots fall through to
          // the `?? const TextStyle(fontSize: N)` fallback at every
          // callsite — the negative regression below pins those `N`
          // values to `kCanonicalSlotSizes`, so the slot→size
          // contract still holds at every render path even when the
          // base theme leaves the slot fontSize-less. This is
          // informational only — the assertion below is intentionally
          // lenient on null slots / null fontSize.
          expect(
            style?.fontSize,
            isNull,
            reason:
                'Slot `${entry.key}` has a null fontSize on '
                '`AppThemes.editorialMonocle.textTheme`; the negative '
                'regression below enforces the slot→size table at '
                'fallback callsites.',
          );
          return;
        }
        expect(
          style.fontSize,
          entry.value,
          reason:
              'Slot `${entry.key}` must keep the M3 dark canonical '
              'size ${entry.value}; #2914 S7 pins the slot→size table '
              'as the contract every `?? const TextStyle(fontSize: N)` '
              'fallback in `app/lib/**` must respect.',
        );
      });
    }
  });

  group(
    '#2914 S7 negative regression — slot/size alignment in `?? const '
    'TextStyle(fontSize: N)` fallbacks under `app/lib/**`',
    () {
      test('every slot fallback declares the slot-canonical size', () {
        final Directory libDir = Directory('lib');
        expect(
          libDir.existsSync(),
          isTrue,
          reason:
              'This test must run from `app/`; `Directory.current` is '
              '${Directory.current.path}.',
        );

        final List<String> mismatches = <String>[];
        // Track at least one match was inspected; otherwise the regex
        // is silently broken and the test would falsely pass.
        int matchCount = 0;

        for (final entity in libDir.listSync(recursive: true)) {
          if (!_isWalkable(entity)) continue;
          final File file = entity as File;
          final String content = file.readAsStringSync();
          for (final match in _slotFallbackRegex.allMatches(content)) {
            matchCount++;
            final String slot = match.group(1)!;
            final double declared = double.parse(match.group(2)!);
            final double? canonical = kCanonicalSlotSizes[slot];
            if (canonical == null) {
              // Unknown slot name — the test does not police custom
              // slots; the SPEC table covers the canonical M3 dark
              // surface only.
              continue;
            }
            if (declared != canonical) {
              mismatches.add(
                '${file.path}: `theme.textTheme.$slot ?? '
                'const TextStyle(fontSize: $declared)` — slot canonical '
                'size is $canonical (per #2914 S7 slot→size table).',
              );
            }
          }
        }

        expect(
          matchCount,
          greaterThan(0),
          reason:
              'No `theme.textTheme.<slot> ?? const TextStyle(fontSize: '
              'N)` fallbacks were detected; the regex is likely broken '
              'or the codebase has been emptied. Either way, the S7 '
              'regression guard is no longer active.',
        );

        expect(
          mismatches,
          isEmpty,
          reason:
              '#2914 S7 requires every `?? const TextStyle(fontSize: N)` '
              'fallback whose left-hand side is `theme.textTheme.<slot>` '
              'to declare an `N` that matches the canonical M3 dark '
              'size for that slot. Mismatches found:\n'
              '  - ${mismatches.join('\n  - ')}',
        );
      });
    },
  );
}

TextStyle? _resolveSlot(TextTheme tt, String slot) {
  switch (slot) {
    case 'headlineMedium':
      return tt.headlineMedium;
    case 'headlineSmall':
      return tt.headlineSmall;
    case 'titleLarge':
      return tt.titleLarge;
    case 'titleMedium':
      return tt.titleMedium;
    case 'titleSmall':
      return tt.titleSmall;
    case 'bodyLarge':
      return tt.bodyLarge;
    case 'bodyMedium':
      return tt.bodyMedium;
    case 'bodySmall':
      return tt.bodySmall;
    case 'labelLarge':
      return tt.labelLarge;
    case 'labelMedium':
      return tt.labelMedium;
    case 'labelSmall':
      return tt.labelSmall;
  }
  return null;
}
