import 'package:flutter/material.dart';

import 'package:colonizethis_app_ui_chrome/config/editorial_monocle_palette.dart';
import 'ct_toggle_switch_state.dart';

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
    this.onGlowColor,
  });

  /// Current on/off state. `true` renders the on-state palette, knob at the
  /// right inner edge, and the active glow.
  final bool value;

  /// Tap callback. Pass `null` to render the disabled treatment (see class
  /// dartdoc). Otherwise the widget invokes the callback with the negated
  /// value when the user taps.
  final ValueChanged<bool>? onChanged;

  /// Optional override for the active (on-state) knob glow color.
  ///
  /// Defaults to `EditorialMonoclePalette.accent` (the canonical brass glow
  /// from the base R8 visual contract). Pass a different palette token
  /// (e.g. `EditorialMonoclePalette.success` or `EditorialMonoclePalette.danger`)
  /// to render the toggle with a semantic glow without re-skinning the
  /// track/knob foreground (Refs #2867 R22 / R24 — accept/reject and
  /// join/refuse toggles in the overture and call-to-arms overlays).
  ///
  /// SPEC: `SPEC/ui/pixel-art-ui-catalog.md` § Pixel-art component catalog
  /// (`CtToggleSwitch` entry — glow color override).
  final Color? onGlowColor;

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
  State<CtToggleSwitch> createState() => CtToggleSwitchState();
}
