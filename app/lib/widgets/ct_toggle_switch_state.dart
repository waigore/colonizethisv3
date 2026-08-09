import 'package:colonizethis_app_ui_chrome/config/editorial_monocle_palette.dart';
import 'package:flutter/material.dart';

import 'ct_toggle_switch.dart';
import 'ct_toggle_switch_track.dart';

/// Stateful implementation for [CtToggleSwitch] (Refs #4117 de-part).
class CtToggleSwitchState extends State<CtToggleSwitch> {
  bool _hovered = false;

  bool get enabled => widget.onChanged != null;

  void handleHover(bool entered) {
    if (!enabled) return;
    if (_hovered == entered) return;
    setState(() => _hovered = entered);
  }

  void handleTap() {
    final ValueChanged<bool>? cb = widget.onChanged;
    if (cb == null) return;
    cb(!widget.value);
  }

  Color get resolvedGlowColor =>
      widget.onGlowColor ?? EditorialMonoclePalette.accent;

  @override
  Widget build(BuildContext context) {
    if (!enabled) {
      return Opacity(
        opacity: CtToggleSwitch.disabledOpacity,
        child: CtToggleSwitchTrack(
          value: widget.value,
          hovered: false,
          animated: false,
          glowColor: resolvedGlowColor,
        ),
      );
    }
    return MouseRegion(
      onEnter: (_) => handleHover(true),
      onExit: (_) => handleHover(false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: handleTap,
        child: CtToggleSwitchTrack(
          value: widget.value,
          hovered: _hovered,
          animated: true,
          glowColor: resolvedGlowColor,
        ),
      ),
    );
  }
}
