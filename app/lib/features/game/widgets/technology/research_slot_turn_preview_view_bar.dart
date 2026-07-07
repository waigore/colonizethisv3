part of 'research_slot_turn_preview_view.dart';

/// Dual-segment research progress bar: committed RP (segment A, `--accent`)
/// followed by anticipated RP this turn (segment B, a subtler `--accent` tint
/// animated on width). Mirrors the single-segment `CtProgressBar` geometry
/// (12 dp tall, 1 px `--accent-dim` border, `--surface` track).
class _ResearchDualSegmentBar extends StatelessWidget {
  const _ResearchDualSegmentBar({
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

/// Static track (surface fill + `--accent-dim` border) behind both segments.
class _DualSegmentTrack extends StatelessWidget {
  const _DualSegmentTrack();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: EditorialMonoclePalette.surface,
        border: Border.all(
          color: EditorialMonoclePalette.accentDim,
          width: _ResearchDualSegmentBar.borderWidth,
        ),
      ),
      child: const SizedBox.expand(),
    );
  }
}

/// Committed (segment A) + anticipated (segment B, animated) fill row, inset by
/// the track border so the segments sit inside the 1 px frame.
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
      padding: const EdgeInsets.all(_ResearchDualSegmentBar.borderWidth),
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
                duration: _ResearchDualSegmentBar.animationDuration,
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
