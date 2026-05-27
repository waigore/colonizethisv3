import 'dart:math' as math;
import 'dart:ui';

/// Canonical OKLCH color tokens and derived sRGB [Color]s for the
/// `editorialMonocle` dark theme.
///
/// Source of truth for the token table is
/// `SPEC/ui/pixel-art-ui-catalog.md` (§ Editorial-monocle palette). Each
/// public field returns a deterministic sRGB approximation of the
/// corresponding OKLCH triple via [oklchToColor] (Björn Ottosson's
/// OKLab → linear-sRGB matrix + IEC 61966-2-1 gamma), so the SPEC
/// values remain the editable single source.
class EditorialMonoclePalette {
  EditorialMonoclePalette._();

  // OKLCH triples (lightness 0..1, chroma, hue degrees). Mirrors the
  // SPEC token table — change values here only when the SPEC changes.
  static const OklchToken bgToken = OklchToken(0.16, 0.018, 50);
  static const OklchToken bgDeepToken = OklchToken(0.12, 0.015, 45);
  static const OklchToken surfaceToken = OklchToken(0.24, 0.015, 45);
  static const OklchToken surfaceLiteToken = OklchToken(0.30, 0.016, 52);
  static const OklchToken fgToken = OklchToken(0.88, 0.015, 80);
  static const OklchToken mutedToken = OklchToken(0.65, 0.025, 70);
  static const OklchToken borderToken = OklchToken(0.40, 0.020, 55);
  static const OklchToken accentToken = OklchToken(0.72, 0.14, 85);
  static const OklchToken accentDimToken = OklchToken(0.60, 0.12, 82);
  static const OklchToken accentBrightToken = OklchToken(0.82, 0.13, 90);
  // Danger / success were bumped from L=0.55 (issue #2858 Design proposal) to
  // L=0.62 so that contrast against `--bg` clears the issue's own AA AC
  // (>= 4.5:1) — see SPEC/ui/pixel-art-ui-catalog.md § Editorial-monocle
  // palette and the linked WCAG note for the conflict resolution. Chroma and
  // hue are preserved so the warm-red / cool-green perceptual identity stays.
  static const OklchToken dangerToken = OklchToken(0.62, 0.16, 22);
  static const OklchToken successToken = OklchToken(0.62, 0.12, 150);

  static Color get bg => oklchToColor(bgToken);
  static Color get bgDeep => oklchToColor(bgDeepToken);
  static Color get surface => oklchToColor(surfaceToken);
  static Color get surfaceLite => oklchToColor(surfaceLiteToken);
  static Color get fg => oklchToColor(fgToken);
  static Color get muted => oklchToColor(mutedToken);
  static Color get border => oklchToColor(borderToken);
  static Color get accent => oklchToColor(accentToken);
  static Color get accentDim => oklchToColor(accentDimToken);
  static Color get accentBright => oklchToColor(accentBrightToken);
  static Color get danger => oklchToColor(dangerToken);
  static Color get success => oklchToColor(successToken);
}

/// Immutable OKLCH triple. Lightness is the OKLab L (0..1), chroma is
/// unbounded, hue is degrees in `[0, 360)`.
class OklchToken {
  const OklchToken(this.lightness, this.chroma, this.hueDegrees);
  final double lightness;
  final double chroma;
  final double hueDegrees;
}

/// Convert OKLCH (lightness 0..1, chroma, hue degrees) to an sRGB [Color]
/// using the OKLab forward conversion + IEC 61966-2-1 gamma encoding.
///
/// Out-of-gamut components are clamped to `[0, 1]` before encoding so the
/// palette degrades gracefully rather than producing NaN sRGB output.
Color oklchToColor(OklchToken token) {
  final double hueRad = token.hueDegrees * math.pi / 180.0;
  final double a = token.chroma * math.cos(hueRad);
  final double b = token.chroma * math.sin(hueRad);

  final double lPrime = token.lightness + 0.3963377774 * a + 0.2158037573 * b;
  final double mPrime = token.lightness - 0.1055613458 * a - 0.0638541728 * b;
  final double sPrime = token.lightness - 0.0894841775 * a - 1.2914855480 * b;

  final double l = lPrime * lPrime * lPrime;
  final double m = mPrime * mPrime * mPrime;
  final double s = sPrime * sPrime * sPrime;

  final double rLinear = 4.0767416621 * l - 3.3077115913 * m + 0.2309699292 * s;
  final double gLinear = -1.2684380046 * l + 2.6097574011 * m - 0.3413193965 * s;
  final double bLinear = -0.0041960863 * l - 0.7034186147 * m + 1.7076147010 * s;

  final int r = _encodeChannel(rLinear);
  final int g = _encodeChannel(gLinear);
  final int bChannel = _encodeChannel(bLinear);
  return Color.fromARGB(0xFF, r, g, bChannel);
}

/// Apply the IEC 61966-2-1 gamma curve and clamp to an sRGB byte.
int _encodeChannel(double linear) {
  final double clamped = linear.clamp(0.0, 1.0);
  final double encoded = clamped <= 0.0031308
      ? 12.92 * clamped
      : 1.055 * math.pow(clamped, 1.0 / 2.4) - 0.055;
  return (encoded * 255.0).round().clamp(0, 255);
}

/// Relative luminance per WCAG 2.x for an sRGB [Color] using its 0..255
/// channels. Returned value is in `[0, 1]` and is used by
/// [wcagContrastRatio].
double wcagRelativeLuminance(Color color) {
  double channel(int byte) {
    final double srgb = byte / 255.0;
    return srgb <= 0.03928
        ? srgb / 12.92
        : math.pow((srgb + 0.055) / 1.055, 2.4) as double;
  }

  final int r = ((color.r * 255.0).round() & 0xFF);
  final int g = ((color.g * 255.0).round() & 0xFF);
  final int b = ((color.b * 255.0).round() & 0xFF);
  return 0.2126 * channel(r) + 0.7152 * channel(g) + 0.0722 * channel(b);
}

/// WCAG 2.x contrast ratio for two sRGB colors. Always returns a value
/// >= 1.0 (text vs background symmetric).
double wcagContrastRatio(Color a, Color b) {
  final double la = wcagRelativeLuminance(a);
  final double lb = wcagRelativeLuminance(b);
  final double lighter = math.max(la, lb);
  final double darker = math.min(la, lb);
  return (lighter + 0.05) / (darker + 0.05);
}
