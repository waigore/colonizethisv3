import 'package:colonizethis_app_ui_chrome/config/editorial_monocle_palette.dart';
import 'package:flutter/material.dart';

import 'ct_back_button.dart';
import 'ct_icon_action.dart';

/// Stateful implementation for [CtIconAction] (Refs #4117 de-part).
class CtIconActionState extends State<CtIconAction> {
  bool _hovered = false;
  bool _pressed = false;

  bool get _isInteractive => widget.enabled && widget.onPressed != null;

  void _setHover(bool hovered) {
    if (!_isInteractive) return;
    if (_hovered == hovered) return;
    setState(() => _hovered = hovered);
  }

  void _setPressed(bool pressed) {
    if (!_isInteractive) return;
    if (_pressed == pressed) return;
    setState(() => _pressed = pressed);
  }

  Color get _resolvedIconColor {
    if (!widget.enabled) {
      return widget.disabledIconColor ??
          widget.iconColor ??
          EditorialMonoclePalette.accentDim;
    }
    if (_pressed) {
      return widget.pressedIconColor ?? EditorialMonoclePalette.accentBright;
    }
    if (_hovered) {
      return widget.hoverIconColor ?? EditorialMonoclePalette.accent;
    }
    return widget.iconColor ?? EditorialMonoclePalette.accentDim;
  }

  Color get _backgroundColor {
    if (_pressed) {
      return EditorialMonoclePalette.surfaceLite.withValues(
        alpha: CtBackButton.pressedBackgroundAlpha,
      );
    }
    if (_hovered) {
      return EditorialMonoclePalette.surfaceLite.withValues(
        alpha: CtBackButton.hoverBackgroundAlpha,
      );
    }
    // Default — fully transparent panel. Keep `surfaceLite` as the
    // animation anchor so `AnimatedContainer` can lerp alpha cleanly
    // without introducing a hard-coded literal (Refs #2914 S4).
    return EditorialMonoclePalette.surfaceLite.withValues(alpha: 0);
  }

  @override
  Widget build(BuildContext context) {
    final double side = widget.iconSize + widget.hitPadding * 2;
    final Widget body = AnimatedContainer(
      duration: _isInteractive
          ? CtBackButton.animationDuration
          : Duration.zero,
      curve: CtBackButton.animationCurve,
      width: side,
      height: side,
      decoration: BoxDecoration(color: _backgroundColor),
      child: Center(
        child: Icon(
          widget.icon,
          size: widget.iconSize,
          color: _resolvedIconColor,
        ),
      ),
    );

    Widget chrome;
    if (!_isInteractive) {
      final Widget faded = Opacity(
        opacity: widget.enabled
            ? 1.0
            : CtBackButton.disabledOpacity,
        child: body,
      );
      chrome = Semantics(
        button: true,
        enabled: false,
        label: widget.semanticLabel ?? widget.tooltip,
        child: IgnorePointer(child: faded),
      );
    } else {
      chrome = Semantics(
        button: true,
        enabled: true,
        label: widget.semanticLabel ?? widget.tooltip,
        child: MouseRegion(
          onEnter: (_) => _setHover(true),
          onExit: (_) => _setHover(false),
          cursor: SystemMouseCursors.click,
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTapDown: (_) => _setPressed(true),
            onTapUp: (_) => _setPressed(false),
            onTapCancel: () => _setPressed(false),
            onTap: widget.onPressed,
            child: body,
          ),
        ),
      );
    }

    final String? tooltip = widget.tooltip;
    if (tooltip != null && tooltip.isNotEmpty) {
      chrome = Tooltip(message: tooltip, child: chrome);
    }
    return chrome;
  }
}
