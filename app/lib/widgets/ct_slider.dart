import 'package:flutter/material.dart';

/// Pixel-art friendly slider for integer or continuous values (`divisions: 0`).
/// Replaces Material [Slider] in production allocation and region minimap zoom.
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

  /// Deeper purple than the filled track; defaults to a fixed deep purple.
  final Color? comfortHeadroomColor;

  @override
  State<CtSlider> createState() => _CtSliderState();
}

class _CtSliderState extends State<CtSlider> {
  @override
  void didUpdateWidget(CtSlider oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.value != widget.value) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final range = widget.max - widget.min;
    final t = (range > 0 && range.isFinite)
        ? ((widget.value - widget.min) / range).clamp(0.0, 1.0)
        : 0.0;

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final trackHeight = 6.0;
        final handleSize = 14.0;
        final trackUsable = width.isFinite && width > handleSize
            ? width - handleSize
            : 0.0;
        final handleX =
            trackUsable > 0 && t.isFinite ? t * trackUsable : 0.0;
        final thumbCenterX = handleX + handleSize / 2;
        final comfortColor = widget.comfortHeadroomColor ??
            const Color(0xFF4527A0); // Deep purple 800 — darker than primary @0.5

        void handleTapOrDrag(Offset localPos) {
          if (range <= 0 || !range.isFinite) {
            widget.onChanged(widget.min);
            return;
          }
          if (!width.isFinite || width <= handleSize) {
            return;
          }
          final d = width - handleSize;
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
            height: 24,
            child: Stack(
              alignment: Alignment.centerLeft,
              children: [
                // Track
                Positioned(
                  left: 0,
                  right: 0,
                  top: (24 - trackHeight) / 2,
                  child: Container(
                    height: trackHeight,
                    decoration: BoxDecoration(
                      color: colorScheme.surface.withValues(alpha: 0.7),
                      border: Border.all(color: colorScheme.outline, width: 1),
                    ),
                  ),
                ),
                if (widget.comfortHeadroomActive &&
                    trackUsable > 0 &&
                    t < 1.0 - 1e-9) ...[
                  Positioned(
                    left: 1 + thumbCenterX,
                    right: 1,
                    top: (24 - trackHeight + 2) / 2,
                    child: Container(
                      height: trackHeight - 2,
                      color: comfortColor,
                    ),
                  ),
                ],
                // Filled portion
                Positioned(
                  left: 1,
                  top: (24 - trackHeight + 2) / 2,
                  width: thumbCenterX,
                  child: Container(
                    height: trackHeight - 2,
                    color: colorScheme.primary.withValues(alpha: 0.5),
                  ),
                ),
                // Handle (square, pixel-ish)
                Positioned(
                  left: handleX,
                  top: (24 - handleSize) / 2,
                  child: Container(
                    width: handleSize,
                    height: handleSize,
                    decoration: BoxDecoration(
                      color: colorScheme.primary,
                      border: Border.all(
                        color: colorScheme.onPrimary,
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
