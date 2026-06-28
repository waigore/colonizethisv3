// 10-step gradient relation meter shared by the diplomacy panel row and the
// diplomacy detail screen.
// SPEC/ui/components/relation-meter.md, SPEC/game/diplomacy.md
// § Player-facing relation display — 10-step relation meter (Refs #3753 R13).

import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:flutter/material.dart';

import '../config/editorial_monocle_palette.dart';

/// Resolves the editorial-monocle gradient color for a 1-based relation-meter
/// [step] in `[1, relationMeterStepCount]`.
///
/// The ladder interpolates in OKLCH from the canonical `--danger` token
/// (warm red, hue 22°) at step 1 to the canonical `--success` token (cool
/// green, hue 150°) at step 10, holding lightness at the AA-tuned `L = 0.62`
/// shared by both endpoints so every step reads at a consistent brightness
/// against `--bg`. Chroma eases from the danger chroma (0.16) to the success
/// chroma (0.12). The two endpoints reproduce the existing relation-state
/// semantic exactly; intermediate steps pass through amber/yellow hues with no
/// new fixed palette tokens (Refs #3753 R13.3).
/// SPEC/ui/components/relation-meter.md § Gradient.
Color relationMeterStepColor(int step) {
  final int clamped = step.clamp(1, relationMeterStepCount);
  final double t = relationMeterStepCount > 1
      ? (clamped - 1) / (relationMeterStepCount - 1)
      : 0.0;
  const OklchToken danger = EditorialMonoclePalette.dangerToken;
  const OklchToken success = EditorialMonoclePalette.successToken;
  final double hue =
      danger.hueDegrees + t * (success.hueDegrees - danger.hueDegrees);
  final double chroma = danger.chroma + t * (success.chroma - danger.chroma);
  // Lightness held at the shared danger/success L so the ladder is iso-luminant.
  return oklchToColor(OklchToken(danger.lightness, chroma, hue));
}

/// Compact 10-step relation meter: a horizontal gradient bar of
/// [relationMeterStepCount] segments (red → green) with a raised indicator on
/// the step covering the hidden decimal relation [score]. The numeric score is
/// never shown (Refs #3753 R13.1, R13.2). The host renders the one-word ladder
/// label ([relationScoreToDisplayLabel]) beside the bar (R13.4).
///
/// SPEC/ui/components/relation-meter.md.
class RelationMeter extends StatelessWidget {
  const RelationMeter({super.key, required this.score});

  /// Hidden decimal relation score in `[0, 100]`. Maps to a 1-based step via
  /// [relationScoreToMeterStep] (half-open `[low, high)` bands; final band
  /// `[90, 100]` closed).
  final num score;

  /// Segment width (dp) of each of the [relationMeterStepCount] cells.
  static const double kSegmentWidth = 7.0;

  /// Height (dp) of an inactive meter segment.
  static const double kSegmentHeight = 6.0;

  /// Height (dp) of the active (indicated) meter segment — taller than the
  /// inactive cells so the indicated step reads at a glance.
  static const double kActiveSegmentHeight = 12.0;

  /// Gap (dp) between adjacent meter segments.
  static const double kSegmentGap = 1.0;

  /// Key prefix for the active-step indicator segment, so widget tests can pin
  /// which step the marker lands on without reading pixels. Each meter exposes
  /// `ValueKey('${kRelationMeterActiveStepKeyPrefix}<step>')`.
  static const String kRelationMeterActiveStepKeyPrefix = 'relationMeterStep:';

  @override
  Widget build(BuildContext context) {
    final int activeStep = relationScoreToMeterStep(score);
    final String label = relationScoreToDisplayLabel(score);

    final List<Widget> segments = <Widget>[];
    for (int step = 1; step <= relationMeterStepCount; step++) {
      final bool isActive = step == activeStep;
      if (step > 1) segments.add(const SizedBox(width: kSegmentGap));
      segments.add(
        Container(
          key: isActive
              ? ValueKey('$kRelationMeterActiveStepKeyPrefix$step')
              : null,
          width: kSegmentWidth,
          height: isActive ? kActiveSegmentHeight : kSegmentHeight,
          decoration: BoxDecoration(
            color: relationMeterStepColor(step),
            borderRadius: BorderRadius.circular(1),
            border: isActive
                ? Border.all(color: EditorialMonoclePalette.fg, width: 1)
                : null,
          ),
        ),
      );
    }

    return Semantics(
      label: 'Relation: $label',
      container: true,
      child: ExcludeSemantics(
        child: SizedBox(
          height: kActiveSegmentHeight,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: segments,
          ),
        ),
      ),
    );
  }
}
