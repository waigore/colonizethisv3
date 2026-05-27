import 'package:flutter/material.dart';

import '../config/editorial_monocle_palette.dart';

/// Two-state pixel-art toggle for the dark editorial-monocle theme.
///
/// Implements `Refs #2859` R8 + § *CtToggleSwitch visual contract*. The
/// widget paints a 24x12 px track with a 10x10 px square knob that slides
/// 12 px horizontally between the off and on positions. Off and on states
/// resolve distinct palettes from [EditorialMonoclePalette] (no hard-coded
/// hex). When [onChanged] is `null` the widget is treated as disabled and
/// wraps itself in the shared 0.4-opacity convention from
/// `CtNinePatchButton` / `CtBackButton`; in that state pending slide /
/// glow animations are suppressed and taps are ignored.
///
/// SPEC: `SPEC/ui/pixel-art-ui-catalog.md` § Pixel-art component catalog
/// (`CtToggleSwitch` entry).
class CtToggleSwitch extends StatefulWidget {
  const CtToggleSwitch({
    super.key,
    required this.value,
    required this.onChanged,
  });

  /// Current on/off state. `true` renders the on-state palette, knob at the
  /// right inner edge, and the active glow.
  final bool value;

  /// Tap callback. Pass `null` to render the disabled treatment (see class
  /// dartdoc). Otherwise the widget invokes the callback with the negated
  /// value when the user taps.
  final ValueChanged<bool>? onChanged;

  /// Track width (R8 visual contract).
  static const double trackWidth = 24;

  /// Track height (R8 visual contract).
  static const double trackHeight = 12;

  /// Knob side length (square).
  static const double knobSize = 10;

  /// Knob inset from the track's left edge in the off state.
  static const double knobOffOffset = 1;

  /// Knob inset from the track's left edge in the on state. The slide
  /// distance is therefore [knobOnOffset] - [knobOffOffset] = 12 px.
  static const double knobOnOffset = 13;

  /// Total horizontal travel of the knob between the off and on states.
  static const double knobTravel = knobOnOffset - knobOffOffset;

  /// 1px border width used by both track and knob across all states.
  static const double borderWidth = 1;

  /// Active glow radius (1px outer halo).
  static const double glowSpread = 1;

  /// Active glow alpha at rest (on state, no hover).
  static const double glowRestAlpha = 0.6;

  /// Active glow alpha while hovered (on state).
  static const double glowHoverAlpha = 1.0;

  /// Disabled opacity, shared with `CtNinePatchButton` and `CtBackButton`.
  static const double disabledOpacity = 0.4;

  /// Slide + colour interpolation duration (R8 visual contract).
  static const Duration animationDuration = Duration(milliseconds: 120);

  /// Slide + colour interpolation curve.
  static const Curve animationCurve = Curves.easeOut;

  @override
  State<CtToggleSwitch> createState() => _CtToggleSwitchState();
}

class _CtToggleSwitchState extends State<CtToggleSwitch> {
  bool _hovered = false;

  bool get _enabled => widget.onChanged != null;

  void _handleHover(bool entered) {
    if (!_enabled) return;
    if (_hovered == entered) return;
    setState(() => _hovered = entered);
  }

  void _handleTap() {
    final ValueChanged<bool>? cb = widget.onChanged;
    if (cb == null) return;
    cb(!widget.value);
  }

  @override
  Widget build(BuildContext context) {
    if (!_enabled) {
      return Opacity(
        opacity: CtToggleSwitch.disabledOpacity,
        child: _CtToggleSwitchTrack(
          value: widget.value,
          hovered: false,
          animated: false,
        ),
      );
    }
    return MouseRegion(
      onEnter: (_) => _handleHover(true),
      onExit: (_) => _handleHover(false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: _handleTap,
        child: _CtToggleSwitchTrack(
          value: widget.value,
          hovered: _hovered,
          animated: true,
        ),
      ),
    );
  }
}

class _CtToggleSwitchTrack extends StatelessWidget {
  const _CtToggleSwitchTrack({
    required this.value,
    required this.hovered,
    required this.animated,
  });

  final bool value;
  final bool hovered;
  final bool animated;

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
            child: _CtToggleSwitchKnob(
              fill: _knobFill,
              border: _knobBorder,
              glowAlpha: _glowAlpha,
              duration: duration,
            ),
          ),
        ],
      ),
    );
  }
}

class _CtToggleSwitchKnob extends StatelessWidget {
  const _CtToggleSwitchKnob({
    required this.fill,
    required this.border,
    required this.glowAlpha,
    required this.duration,
  });

  final Color fill;
  final Color border;
  final double glowAlpha;
  final Duration duration;

  @override
  Widget build(BuildContext context) {
    final List<BoxShadow>? glow = glowAlpha > 0
        ? <BoxShadow>[
            BoxShadow(
              color: EditorialMonoclePalette.accent.withValues(
                alpha: glowAlpha,
              ),
              spreadRadius: CtToggleSwitch.glowSpread,
              blurRadius: 0,
            ),
          ]
        : null;
    return AnimatedContainer(
      key: const ValueKey<String>('ctToggleSwitchKnob'),
      duration: duration,
      curve: CtToggleSwitch.animationCurve,
      width: CtToggleSwitch.knobSize,
      height: CtToggleSwitch.knobSize,
      decoration: BoxDecoration(
        color: fill,
        border: Border.all(
          color: border,
          width: CtToggleSwitch.borderWidth,
        ),
        boxShadow: glow,
      ),
    );
  }
}
