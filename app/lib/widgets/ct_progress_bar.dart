import 'package:flutter/material.dart';

import '../config/editorial_monocle_palette.dart';

/// Pixel-art horizontal progress bar for the dark editorial-monocle theme.
///
/// Implements `Refs #2859` R12 + § *CtProgressBar visual contract*. The bar is
/// 12px tall, spans the full parent-provided horizontal width, paints a
/// `--surface` track with a 1px `--accent-dim` border, fills `--accent` from
/// the inner-left edge growing to the inner-right edge, and animates fill
/// width changes over 120ms with `Curves.easeOut`. An optional monospace
/// `--muted` label sits 4px to the right of the bar. The widget respects an
/// [enabled] flag matching the 0.4-opacity disabled convention shared with
/// `CtNinePatchButton`, `CtToggleSwitch`, and `CtBackButton`. All colors
/// resolve from [EditorialMonoclePalette] tokens (issue #2858); no hard-coded
/// hex literals.
class CtProgressBar extends StatelessWidget {
  const CtProgressBar({
    super.key,
    required this.value,
    this.label,
    this.enabled = true,
  });

  /// Progress value. `null` is treated as `0.0`. Values `<= 0.0` clamp to
  /// `0.0`; values `>= 1.0` clamp to `1.0`.
  final double? value;

  /// Optional consumer-supplied label rendered outside the bar (4px to the
  /// right). When `null`, no label region is laid out and the bar consumes
  /// only the 12px height.
  final String? label;

  /// When false, the entire widget renders at 0.4 opacity.
  final bool enabled;

  /// Overall bar height (R12 visual contract).
  static const double height = 12;

  /// 1px track border on all sides (R12 visual contract).
  static const double borderWidth = 1;

  /// Fill-grow animation duration shared with `CtToggleSwitch` slide and
  /// `CtDropdown` chevron rotation per R12 / R8.
  static const Duration animationDuration = Duration(milliseconds: 120);

  /// Animation curve for the fill grow.
  static const Curve animationCurve = Curves.easeOut;

  /// Horizontal gap between the bar and its optional label.
  static const double labelGap = 4;

  @visibleForTesting
  static double clampValueForTesting(double? raw) => _clamp(raw);

  static double _clamp(double? raw) {
    if (raw == null) return 0.0;
    if (raw.isNaN) return 0.0;
    if (raw <= 0.0) return 0.0;
    if (raw >= 1.0) return 1.0;
    return raw;
  }

  @override
  Widget build(BuildContext context) {
    final double clamped = _clamp(value);
    final Widget bar = _CtProgressBarTrack(clamped: clamped);
    final Widget contents = label == null
        ? bar
        : Row(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: <Widget>[
              Expanded(child: bar),
              const SizedBox(width: labelGap),
              _CtProgressBarLabel(text: label!),
            ],
          );
    if (!enabled) {
      return Opacity(opacity: 0.4, child: contents);
    }
    return contents;
  }
}

class _CtProgressBarTrack extends StatelessWidget {
  const _CtProgressBarTrack({required this.clamped});

  final double clamped;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final double availableWidth = constraints.maxWidth.isFinite
            ? constraints.maxWidth
            : 0.0;
        final double trackWidth = availableWidth > 0 ? availableWidth : 0.0;
        final double innerWidth =
            (trackWidth - 2 * CtProgressBar.borderWidth).clamp(0.0, trackWidth);
        final double fillWidth = (innerWidth * clamped).clamp(0.0, innerWidth);
        return SizedBox(
          height: CtProgressBar.height,
          width: trackWidth,
          child: Stack(
            alignment: Alignment.centerLeft,
            children: <Widget>[
              DecoratedBox(
                decoration: BoxDecoration(
                  color: EditorialMonoclePalette.surface,
                  border: Border.all(
                    color: EditorialMonoclePalette.accentDim,
                    width: CtProgressBar.borderWidth,
                  ),
                ),
                child: const SizedBox.expand(),
              ),
              if (fillWidth > 0)
                Padding(
                  padding: const EdgeInsets.all(CtProgressBar.borderWidth),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: AnimatedContainer(
                      duration: CtProgressBar.animationDuration,
                      curve: CtProgressBar.animationCurve,
                      width: fillWidth,
                      color: EditorialMonoclePalette.accent,
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

class _CtProgressBarLabel extends StatelessWidget {
  const _CtProgressBarLabel({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final TextStyle baseStyle =
        theme.textTheme.labelMedium ?? const TextStyle(fontSize: 12);
    return Text(
      text,
      style: baseStyle.copyWith(
        color: EditorialMonoclePalette.muted,
        fontFamilyFallback: const <String>[
          'SF Mono',
          'Menlo',
          'monospace',
        ],
        fontFeatures: const <FontFeature>[FontFeature.tabularFigures()],
      ),
    );
  }
}
