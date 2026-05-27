import 'package:colonizethis_app/config/editorial_monocle_palette.dart';
import 'package:flutter/material.dart';

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

class _CtSliderState extends State<CtSlider> {
  static const double _trackHeight = 6;
  static const double _thumbDiameter = 14;
  static const double _hitTargetHeight = 24;

  @override
  void didUpdateWidget(CtSlider oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.value != widget.value) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    final range = widget.max - widget.min;
    final t = (range > 0 && range.isFinite)
        ? ((widget.value - widget.min) / range).clamp(0.0, 1.0)
        : 0.0;
    final Color comfortColor =
        widget.comfortHeadroomColor ?? EditorialMonoclePalette.bgDeep;

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final trackUsable = width.isFinite && width > _thumbDiameter
            ? width - _thumbDiameter
            : 0.0;
        final handleX =
            trackUsable > 0 && t.isFinite ? t * trackUsable : 0.0;
        final thumbCenterX = handleX + _thumbDiameter / 2;

        void handleTapOrDrag(Offset localPos) {
          if (range <= 0 || !range.isFinite) {
            widget.onChanged(widget.min);
            return;
          }
          if (!width.isFinite || width <= _thumbDiameter) {
            return;
          }
          final d = width - _thumbDiameter;
          final x = localPos.dx.clamp(0.0, d);
          final ratio = x / d;
          final raw = widget.min + ratio * range;
          if (widget.divisions > 0) {
            final step = range / widget.divisions;
            if (step <= 0 || !step.isFinite) {
              widget.onChanged(widget.min);
              return;
            }
            final snapped = (raw / step).round() * step + widget.min;
            widget.onChanged(snapped.clamp(widget.min, widget.max));
          } else {
            widget.onChanged(raw.clamp(widget.min, widget.max));
          }
        }

        return GestureDetector(
          behavior: HitTestBehavior.translucent,
          onTapDown: (d) => handleTapOrDrag(d.localPosition),
          onHorizontalDragStart: widget.onDragStart != null
              ? (_) => widget.onDragStart!()
              : null,
          onHorizontalDragUpdate: (d) => handleTapOrDrag(d.localPosition),
          onHorizontalDragEnd: widget.onDragEnd != null
              ? (_) => widget.onDragEnd!()
              : null,
          child: SizedBox(
            height: _hitTargetHeight,
            child: Stack(
              alignment: Alignment.centerLeft,
              children: [
                Positioned(
                  left: 0,
                  right: 0,
                  top: (_hitTargetHeight - _trackHeight) / 2,
                  child: Container(
                    height: _trackHeight,
                    decoration: BoxDecoration(
                      color: EditorialMonoclePalette.surface,
                      border: Border.all(
                        color: EditorialMonoclePalette.accentDim,
                        width: 1,
                      ),
                    ),
                  ),
                ),
                if (widget.comfortHeadroomActive &&
                    trackUsable > 0 &&
                    t < 1.0 - 1e-9) ...[
                  Positioned(
                    left: 1 + thumbCenterX,
                    right: 1,
                    top: (_hitTargetHeight - _trackHeight + 2) / 2,
                    child: Container(
                      height: _trackHeight - 2,
                      color: comfortColor,
                    ),
                  ),
                ],
                Positioned(
                  left: 1,
                  top: (_hitTargetHeight - _trackHeight + 2) / 2,
                  width: thumbCenterX,
                  child: Container(
                    height: _trackHeight - 2,
                    color: EditorialMonoclePalette.accent,
                  ),
                ),
                Positioned(
                  left: handleX,
                  top: (_hitTargetHeight - _thumbDiameter) / 2,
                  child: Container(
                    width: _thumbDiameter,
                    height: _thumbDiameter,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: EditorialMonoclePalette.accent,
                      border: Border.all(
                        color: EditorialMonoclePalette.accentBright,
                        width: 1,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
