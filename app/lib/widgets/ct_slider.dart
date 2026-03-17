import 'package:flutter/material.dart';

/// Pixel-art friendly slider for integer values.
/// Replaces Material [Slider] in production allocation.
class CtSlider extends StatefulWidget {
  const CtSlider({
    super.key,
    required this.value,
    required this.min,
    required this.max,
    required this.divisions,
    required this.onChanged,
  });

  final double value;
  final double min;
  final double max;
  final int divisions;
  final ValueChanged<double> onChanged;

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
    final t = ((widget.value - widget.min) / (widget.max - widget.min)).clamp(
      0,
      1,
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final trackHeight = 6.0;
        final handleSize = 14.0;
        final handleX = t * (width - handleSize);

        void handleTapOrDrag(Offset localPos) {
          final x = localPos.dx.clamp(0, width - handleSize);
          final ratio = x / (width - handleSize);
          final raw = widget.min + ratio * (widget.max - widget.min);
          if (widget.divisions > 0) {
            final step = (widget.max - widget.min) / widget.divisions;
            final snapped = (raw / step).round() * step + widget.min;
            widget.onChanged(snapped.clamp(widget.min, widget.max));
          } else {
            widget.onChanged(raw.clamp(widget.min, widget.max));
          }
        }

        return GestureDetector(
          behavior: HitTestBehavior.translucent,
          onTapDown: (d) => handleTapOrDrag(d.localPosition),
          onHorizontalDragUpdate: (d) => handleTapOrDrag(d.localPosition),
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
                // Filled portion
                Positioned(
                  left: 1,
                  top: (24 - trackHeight + 2) / 2,
                  width: handleX + handleSize / 2,
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
