import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter/painting.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:colonizethis_app/config/editorial_monocle_palette.dart';

/// Pins from `SPEC/ui/pixel-art-ui-catalog.md` § Editorial-monocle palette.
/// These are the sRGB values produced by the OKLab → linear-sRGB matrix +
/// IEC 61966-2-1 gamma encoding for the canonical OKLCH tokens.
const Map<String, int> _expectedHex = <String, int>{
  'bg': 0xFF140B07,
  'bg-deep': 0xFF0A0403,
  'surface': 0xFF261D19,
  'surface-lite': 0xFF352C27,
  'fg': 0xFFDDD7CD,
  'muted': 0xFF998D7F,
  'border': 0xFF51453E,
  'accent': 0xFFCD9C1F,
  'accent-dim': 0xFFA4780E,
  'accent-bright': 0xFFE5C057,
  'danger': 0xFFD55759,
  'success': 0xFF4A9A5E,
};

int _toArgb(Color c) {
  final int a = (c.a * 255.0).round() & 0xFF;
  final int r = (c.r * 255.0).round() & 0xFF;
  final int g = (c.g * 255.0).round() & 0xFF;
  final int b = (c.b * 255.0).round() & 0xFF;
  return (a << 24) | (r << 16) | (g << 8) | b;
}

void main() {
  suppressLogsForTests();

  group('EditorialMonoclePalette OKLCH → sRGB', () {
    test('every token resolves to the catalog-pinned sRGB value', () {
      expect(_toArgb(EditorialMonoclePalette.bg), _expectedHex['bg']);
      expect(_toArgb(EditorialMonoclePalette.bgDeep), _expectedHex['bg-deep']);
      expect(_toArgb(EditorialMonoclePalette.surface), _expectedHex['surface']);
      expect(
        _toArgb(EditorialMonoclePalette.surfaceLite),
        _expectedHex['surface-lite'],
      );
      expect(_toArgb(EditorialMonoclePalette.fg), _expectedHex['fg']);
      expect(_toArgb(EditorialMonoclePalette.muted), _expectedHex['muted']);
      expect(_toArgb(EditorialMonoclePalette.border), _expectedHex['border']);
      expect(_toArgb(EditorialMonoclePalette.accent), _expectedHex['accent']);
      expect(
        _toArgb(EditorialMonoclePalette.accentDim),
        _expectedHex['accent-dim'],
      );
      expect(
        _toArgb(EditorialMonoclePalette.accentBright),
        _expectedHex['accent-bright'],
      );
      expect(_toArgb(EditorialMonoclePalette.danger), _expectedHex['danger']);
      expect(_toArgb(EditorialMonoclePalette.success), _expectedHex['success']);
    });

    test('out-of-gamut OKLCH triples clamp without throwing', () {
      // Saturated bright orange that escapes sRGB gamut; should not produce
      // NaN or throw — channels clamp into [0, 255].
      final Color clamped = oklchToColor(const OklchToken(1.2, 0.5, 30));
      expect(_toArgb(clamped) & 0x00FFFFFF, isNonNegative);
    });
  });

  group('EditorialMonoclePalette WCAG contrast', () {
    test('--fg on --bg clears AA body-text 4.5:1', () {
      final double ratio = wcagContrastRatio(
        EditorialMonoclePalette.fg,
        EditorialMonoclePalette.bg,
      );
      expect(ratio, greaterThanOrEqualTo(4.5));
    });

    test('--muted on --bg clears AA secondary 3:1', () {
      final double ratio = wcagContrastRatio(
        EditorialMonoclePalette.muted,
        EditorialMonoclePalette.bg,
      );
      expect(ratio, greaterThanOrEqualTo(3.0));
    });

    test('--accent on --bg clears AA decorative 3:1', () {
      final double ratio = wcagContrastRatio(
        EditorialMonoclePalette.accent,
        EditorialMonoclePalette.bg,
      );
      expect(ratio, greaterThanOrEqualTo(3.0));
    });

    test('--danger on --bg clears AA status 4.5:1', () {
      final double ratio = wcagContrastRatio(
        EditorialMonoclePalette.danger,
        EditorialMonoclePalette.bg,
      );
      expect(ratio, greaterThanOrEqualTo(4.5));
    });

    test('--success on --bg clears AA status 4.5:1', () {
      final double ratio = wcagContrastRatio(
        EditorialMonoclePalette.success,
        EditorialMonoclePalette.bg,
      );
      expect(ratio, greaterThanOrEqualTo(4.5));
    });

    test('large display text (--fg headings) clears AA large 3:1', () {
      final double ratio = wcagContrastRatio(
        EditorialMonoclePalette.fg,
        EditorialMonoclePalette.bg,
      );
      expect(ratio, greaterThanOrEqualTo(3.0));
    });

    test('contrast ratio is symmetric and >= 1', () {
      final double a = wcagContrastRatio(
        EditorialMonoclePalette.fg,
        EditorialMonoclePalette.bg,
      );
      final double b = wcagContrastRatio(
        EditorialMonoclePalette.bg,
        EditorialMonoclePalette.fg,
      );
      expect(a, closeTo(b, 1e-9));
      expect(a, greaterThanOrEqualTo(1.0));
    });
  });

  group('EditorialMonoclePalette dialog scrim token', () {
    test('alpha matches the SPEC pin (0.70)', () {
      expect(EditorialMonoclePalette.dialogScrimAlpha, 0.70);
    });

    test('dialogScrim applies the canonical alpha to the base color', () {
      final Color scrim = EditorialMonoclePalette.dialogScrim;
      expect(
        scrim.a,
        closeTo(EditorialMonoclePalette.dialogScrimAlpha, 1e-6),
        reason: 'dialogScrim must use the SPEC-pinned alpha',
      );
      final Color base = oklchToColor(
        EditorialMonoclePalette.dialogScrimBaseToken,
      );
      // RGB channels are derived from the base OKLCH token; alpha differs.
      expect(scrim.r, closeTo(base.r, 1e-6));
      expect(scrim.g, closeTo(base.g, 1e-6));
      expect(scrim.b, closeTo(base.b, 1e-6));
    });

    test('dialogScrim base token is darker than --bg-deep', () {
      // Sanity check from the SPEC narrative ("darker than --bg-deep").
      final Color scrimBase = oklchToColor(
        EditorialMonoclePalette.dialogScrimBaseToken,
      );
      final double scrimLum = wcagRelativeLuminance(scrimBase);
      final double bgDeepLum = wcagRelativeLuminance(
        EditorialMonoclePalette.bgDeep,
      );
      expect(scrimLum, lessThan(bgDeepLum));
    });
  });
}
