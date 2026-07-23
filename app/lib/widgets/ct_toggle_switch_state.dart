import 'package:flutter/material.dart';

import 'package:colonizethis_app_ui_chrome/config/editorial_monocle_palette.dart';
import 'ct_toggle_switch.dart';
import 'ct_toggle_switch_track.dart';

class CtToggleSwitchState extends State<CtToggleSwitch> {
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

  Color get _resolvedGlowColor =>
      widget.onGlowColor ?? EditorialMonoclePalette.accent;

  @override
  Widget build(BuildContext context) {
    if (!_enabled) {
      return Opacity(
        opacity: CtToggleSwitch.disabledOpacity,
        child: CtToggleSwitchTrack(
          value: widget.value,
          hovered: false,
          animated: false,
          glowColor: _resolvedGlowColor,
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
        child: CtToggleSwitchTrack(
          value: widget.value,
          hovered: _hovered,
          animated: true,
          glowColor: _resolvedGlowColor,
        ),
      ),
    );
  }
}
