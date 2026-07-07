import 'package:colonizethis_app/config/editorial_monocle_palette.dart';
import 'package:flutter/material.dart';

part 'ct_slider_state.dart';

/// Pixel-art friendly slider for integer or continuous values (`divisions: 0`).
/// Replaces Material [Slider] in production allocation and region minimap zoom.
///
/// Dark editorial-monocle chrome per `SPEC/ui/pixel-art-ui-catalog.md`
/// § CtSlider and issue #2859 S7: `--surface` track with `--accent-dim`
/// border, `--accent` fill, round `--accent` thumb with `--accent-bright`
/// border. All colors resolve from [EditorialMonoclePalette].
class CtSlider extends StatefulWidget {
  const CtSlider({
    super.key,
    required this.value,
    required this.min,
    required this.max,
    required this.divisions,
    required this.onChanged,
    this.comfortHeadroomActive = false,
    this.comfortHeadroomColor,
    this.onDragStart,
    this.onDragEnd,
  });

  final double value;
  final double min;
  final double max;
  final int divisions;
  final ValueChanged<double> onChanged;

  /// Optional hook when a horizontal drag begins (not fired for tap-only changes).
  final VoidCallback? onDragStart;

  /// Optional hook when a horizontal drag ends.
  final VoidCallback? onDragEnd;

  /// When true, draws the track segment from thumb to max in [comfortHeadroomColor].
  /// SPEC/ui/production-panel.md
  final bool comfortHeadroomActive;

  /// Deeper segment to the right of the thumb when [comfortHeadroomActive] is true.
  /// Defaults to `--bg-deep` from the editorial-monocle palette.
  final Color? comfortHeadroomColor;

  @override
  State<CtSlider> createState() => _CtSliderState();
}
