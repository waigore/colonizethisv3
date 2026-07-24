/// Layout constants for the military victory overlay panel.
///
/// Visual contract: SPEC/ui/victory-overlay.md and the OVL20001 mockup.
abstract final class VictoryPanelLayout {
  /// Outer max width for the ceremonial panel. Matches the mockup's
  /// `clamp(280px,88vw,460px)` ceiling so the panel does not stretch to the
  /// full overlay width on wide viewports.
  static const double maxWidth = 460;

  /// Border thickness for the surrounding `--accent` frame.
  static const double borderWidth = 2;

  /// Corner-bracket dimensions for the top-left / bottom-right ornaments.
  static const double cornerBracketWidth = 20;
  static const double cornerBracketHeight = 24;
  static const double cornerBracketInset = 4;
  static const double cornerBracketStroke = 1.5;
  static const double cornerBracketAlpha = 0.7;

  /// Laurel font size (logical px) at default and narrow viewport widths.
  /// Pinned to the lower bound of the mockup's `clamp(24px,5vw,36px)` so the
  /// narrow flip lands on the same value the mockup hits at small widths.
  /// SPEC/ui/victory-overlay.md § Narrow viewport.
  static const double laurelFontSizeWide = 28;
  static const double laurelFontSizeNarrow = 24;
}
