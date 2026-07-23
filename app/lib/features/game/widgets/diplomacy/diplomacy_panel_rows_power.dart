/// Great Power relative-strength helpers for diplomacy panel rows.

part of 'diplomacy_panel_rows.dart';

/// Computes the relative Great Power power-comparison percentage used by
/// `SPEC/ui/diplomacy-panel.md` § Power comparison percentage.
///
/// Formula: `round(((gpPowerScore - playerPowerScore) / max(playerPowerScore,
/// 1)) * 100)`. The `max(.., 1)` guard prevents division-by-zero when the
/// human player's score is `0`, yielding a finite percentage.
///
/// Returns the integer percentage (positive when the GP is stronger, negative
/// when weaker, zero when equal).
int powerComparisonPercent(int gpPowerScore, int playerPowerScore) {
  final int denom = math.max(playerPowerScore, 1);
  final double ratio = (gpPowerScore - playerPowerScore) / denom;
  return (ratio * 100).round();
}

/// Formats a `powerComparisonPercent` integer for display per
/// `SPEC/ui/diplomacy-panel.md` § Power comparison percentage:
/// `+N%` when positive, `−N%` (U+2212 minus) when negative, `0%` when zero.
///
/// The minus sign is the unicode `MINUS SIGN` (U+2212) to match the mockup,
/// not the ASCII hyphen-minus (U+002D).
String formatPowerComparisonPercent(int pct) {
  if (pct > 0) return '+$pct%';
  if (pct < 0) return '\u2212${-pct}%';
  return '0%';
}

/// Display-only strength tier derived from a `powerComparisonPercent` value
/// per `SPEC/ui/diplomacy-panel.md` § Relative power line. The tier is a
/// UI-only label and never feeds AI war-desire or any logic-package model.
enum PowerComparisonTier {
  vastlyInferior,
  inferior,
  roughlyEqual,
  superior,
  vastlySuperior,
}

/// Maps a `powerComparisonPercent` integer to its [PowerComparisonTier] per
/// the boundary table in `SPEC/ui/diplomacy-panel.md` § Relative power line:
///
/// | `pct` range | Tier |
/// |-------------|------|
/// | `pct >= +31` | vastlySuperior |
/// | `+11 .. +30` | superior |
/// | `−10 .. +10` | roughlyEqual |
/// | `−30 .. −11` | inferior |
/// | `pct <= −31` | vastlyInferior |
///
/// Boundaries are inclusive on the side shown (e.g. `+10` is roughlyEqual,
/// `+11` is superior). Extreme values (e.g. `+4900` when the player score is
/// near zero) clamp into [PowerComparisonTier.vastlySuperior] without a cap.
PowerComparisonTier powerComparisonTier(int pct) {
  if (pct <= -31) return PowerComparisonTier.vastlyInferior;
  if (pct <= -11) return PowerComparisonTier.inferior;
  if (pct <= 10) return PowerComparisonTier.roughlyEqual;
  if (pct <= 30) return PowerComparisonTier.superior;
  return PowerComparisonTier.vastlySuperior;
}
