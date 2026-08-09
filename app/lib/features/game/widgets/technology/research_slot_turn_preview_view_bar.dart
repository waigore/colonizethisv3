import 'package:colonizethis_app_ui_chrome/config/editorial_monocle_palette.dart';
import 'package:flutter/material.dart';

/// Dual-segment research progress bar (Refs #4117 de-part).
class ResearchDualSegmentBar extends StatelessWidget {
  const ResearchDualSegmentBar({
    super.key,
    required this.committedFraction,
    required this.anticipatedFraction,
    required this.anticipatedSegmentKey,
  });

  final double committedFraction;
  final double anticipatedFraction;
  final Key anticipatedSegmentKey;

  static const double height = 12;
  static const double borderWidth = 1;
  static const Duration animationDuration = Duration(milliseconds: 120);

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final double trackWidth =
            constraints.maxWidth.isFinite ? constraints.maxWidth : 0.0;
        final double innerWidth =
            (trackWidth - 2 * borderWidth).clamp(0.0, trackWidth);
        final double committedWidth =
            (innerWidth * committedFraction.clamp(0.0, 1.0)).clamp(
          0.0,
          innerWidth,
        );
        final double anticipatedWidth =
            (innerWidth * anticipatedFraction.clamp(0.0, 1.0)).clamp(
          0.0,
          innerWidth - committedWidth,
        );
        return SizedBox(
          height: height,
          width: trackWidth,
          child: Stack(
            alignment: Alignment.centerLeft,
            children: <Widget>[
              const _DualSegmentTrack(),
              _DualSegmentFill(
                committedWidth: committedWidth,
                anticipatedWidth: anticipatedWidth,
                anticipatedSegmentKey: anticipatedSegmentKey,
              ),
            ],
          ),
        );
      },
    );
  }
}

class _DualSegmentTrack extends StatelessWidget {
  const _DualSegmentTrack();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: EditorialMonoclePalette.surface,
        border: Border.all(
          color: EditorialMonoclePalette.accentDim,
          width: ResearchDualSegmentBar.borderWidth,
        ),
      ),
      child: const SizedBox.expand(),
    );
  }
}

class _DualSegmentFill extends StatelessWidget {
  const _DualSegmentFill({
    required this.committedWidth,
    required this.anticipatedWidth,
    required this.anticipatedSegmentKey,
  });

  final double committedWidth;
  final double anticipatedWidth;
  final Key anticipatedSegmentKey;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(ResearchDualSegmentBar.borderWidth),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            if (committedWidth > 0)
              SizedBox(
                width: committedWidth,
                height: double.infinity,
                child: ColoredBox(color: EditorialMonoclePalette.accent),
              ),
            if (anticipatedWidth > 0)
              AnimatedContainer(
                key: anticipatedSegmentKey,
                duration: ResearchDualSegmentBar.animationDuration,
                curve: Curves.easeOut,
                width: anticipatedWidth,
                height: double.infinity,
                color:
                    EditorialMonoclePalette.accent.withValues(alpha: 0.4),
              ),
          ],
        ),
      ),
    );
  }
}
