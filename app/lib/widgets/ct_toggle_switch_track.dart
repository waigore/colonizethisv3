import 'package:colonizethis_app_ui_chrome/config/editorial_monocle_palette.dart';
import 'package:flutter/material.dart';

import 'ct_toggle_switch.dart';
import 'ct_toggle_switch_knob.dart';

/// Animated track + knob stack for [CtToggleSwitch] (Refs #4117 de-part).
class CtToggleSwitchTrack extends StatelessWidget {
  const CtToggleSwitchTrack({
    super.key,
    required this.value,
    required this.hovered,
    required this.animated,
    required this.glowColor,
  });

  final bool value;
  final bool hovered;
  final bool animated;
  final Color glowColor;

  Color get _trackFill => value
      ? EditorialMonoclePalette.surfaceLite
      : EditorialMonoclePalette.surface;

  Color get _trackBorder => value
      ? EditorialMonoclePalette.accent
      : EditorialMonoclePalette.accentDim;

  Color get _knobFill {
    if (value) {
      return hovered
          ? EditorialMonoclePalette.accentBright
          : EditorialMonoclePalette.accent;
    }
    return hovered
        ? EditorialMonoclePalette.accentDim
        : EditorialMonoclePalette.muted;
  }

  Color get _knobBorder => value
      ? EditorialMonoclePalette.accentBright
      : EditorialMonoclePalette.accentDim;

  double get _knobLeft =>
      value ? CtToggleSwitch.knobOnOffset : CtToggleSwitch.knobOffOffset;

  double get _glowAlpha {
    if (!value) return 0;
    return hovered
        ? CtToggleSwitch.glowHoverAlpha
        : CtToggleSwitch.glowRestAlpha;
  }

  @override
  Widget build(BuildContext context) {
    final Duration duration = animated
        ? CtToggleSwitch.animationDuration
        : Duration.zero;
    final double knobTopInset =
        (CtToggleSwitch.trackHeight - CtToggleSwitch.knobSize) / 2;
    return SizedBox(
      width: CtToggleSwitch.trackWidth,
      height: CtToggleSwitch.trackHeight,
      child: Stack(
        clipBehavior: Clip.none,
        children: <Widget>[
          AnimatedContainer(
            key: const ValueKey<String>('ctToggleSwitchTrack'),
            duration: duration,
            curve: CtToggleSwitch.animationCurve,
            width: CtToggleSwitch.trackWidth,
            height: CtToggleSwitch.trackHeight,
            decoration: BoxDecoration(
              color: _trackFill,
              border: Border.all(
                color: _trackBorder,
                width: CtToggleSwitch.borderWidth,
              ),
            ),
          ),
          AnimatedPositioned(
            duration: duration,
            curve: CtToggleSwitch.animationCurve,
            left: _knobLeft,
            top: knobTopInset,
            child: CtToggleSwitchKnob(
              fill: _knobFill,
              border: _knobBorder,
              glowColor: glowColor,
              glowAlpha: _glowAlpha,
              duration: duration,
            ),
          ),
        ],
      ),
    );
  }
}
