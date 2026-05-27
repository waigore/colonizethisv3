import 'package:flutter/material.dart';

import '../config/editorial_monocle_palette.dart';

/// Small-caps section label with a brass-tinted bottom border for the dark
/// editorial-monocle theme.
///
/// Implements `Refs #2859` R9 + § *CtSectionLabel visual contract*. The label
/// transforms its text to upper-case (canonical small-caps approximation) and
/// renders in [EditorialMonoclePalette.muted]. A 1px bottom border colored
/// [EditorialMonoclePalette.accentDim] spans the full label container width,
/// separated from the text baseline by [_textBorderGap] of vertical padding.
/// All colors resolve from issue #2858 tokens — no hard-coded hex literals.
class CtSectionLabel extends StatelessWidget {
  const CtSectionLabel(this.text, {super.key, this.padding});

  /// Label text. Rendered as-is with `TextStyle(fontFeatures:[ smcp ])` plus
  /// a [String.toUpperCase] fallback so platforms without small-caps glyphs
  /// still get the canonical visual.
  final String text;

  /// Outer padding around the label container. Defaults to a small
  /// horizontal pad so the section label hugs the leading edge of its parent.
  final EdgeInsetsGeometry? padding;

  /// Vertical pad between the text baseline and the bottom border. Documented
  /// in `SPEC/ui/pixel-art-ui-catalog.md` § Editorial-monocle palette / R9.
  static const double _textBorderGap = 2;

  /// Border thickness. Per R9 the bottom border is `1px`.
  static const double _borderWidth = 1;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final TextStyle baseStyle =
        theme.textTheme.labelSmall ?? const TextStyle(fontSize: 11);
    final TextStyle effectiveStyle = baseStyle.copyWith(
      color: EditorialMonoclePalette.muted,
      fontWeight: FontWeight.w500,
      letterSpacing: 1.0,
      fontFeatures: const <FontFeature>[FontFeature.enable('smcp')],
    );

    return Padding(
      padding: padding ?? EdgeInsets.zero,
      child: DecoratedBox(
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: EditorialMonoclePalette.accentDim,
              width: _borderWidth,
            ),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.only(bottom: _textBorderGap),
          child: Text(text.toUpperCase(), style: effectiveStyle),
        ),
      ),
    );
  }
}
