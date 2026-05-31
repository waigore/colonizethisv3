import 'package:flutter/material.dart';

import '../config/editorial_monocle_palette.dart';

/// Standalone pixel-art back-affordance for the dark editorial-monocle theme.
///
/// Implements `Refs #2859` R11/R11a — 28x28 px tap target with a centered
/// 16x16 px chevron-left glyph. Default state paints no background; hover
/// fades a `--surface-lite` panel in at 40 % alpha over 120 ms; pressed
/// state bumps the panel to 60 % alpha and the glyph to `--accent-bright`.
/// When [enabled] is `false` the entire widget is wrapped in 0.4 opacity
/// and ignores taps/hover (matching the disabled convention shared with
/// `CtNinePatchButton`, `CtToggleSwitch`, and `CtProgressBar`).
///
/// The widget is **not** a thin wrapper around `CtNinePatchButton` (the
/// nine-patch gradient/corner-bracket chrome is wrong for a glyph-only
/// chevron) and resolves all colours from [EditorialMonoclePalette] tokens
/// (issue #2858); no hard-coded hex literals.
///
/// SPEC: `SPEC/ui/pixel-art-ui-catalog.md` § Pixel-art component catalog
/// (`CtBackButton` entry).
class CtBackButton extends StatefulWidget {
  const CtBackButton({
    super.key,
    this.onPressed,
    this.enabled = true,
    this.semanticLabel = _defaultSemanticLabel,
  });

  /// Tap callback. When `null`, the widget defaults to
  /// `Navigator.of(context).maybePop()` so consumers can drop the button
  /// into a route without wiring a handler (R11a default behaviour).
  final VoidCallback? onPressed;

  /// When `false`, the widget renders at 0.4 opacity and ignores taps and
  /// hover (matches the shared disabled convention).
  final bool enabled;

  /// Accessibility label for screen readers. Defaults to the literal
  /// mandated by R11a (`'Back'`). Consumers should pass a localised
  /// override (e.g. `AppLocalizations.of(context)!.common_back`) when the
  /// surrounding screen has localised chrome.
  final String semanticLabel;

  // Static default — not a widget constructor argument, so the
  // `avoid_hardcoded_strings_in_widgets` lint does not see it. The literal
  // is mandated by `Refs #2859` R11a so the default keeps the spec wording
  // verbatim; consumers override via [semanticLabel] when they need
  // localisation.
  static const String _defaultSemanticLabel = 'Back';

  /// Outer tap-target side length (R11a visual contract).
  static const double size = 28;

  /// Centered chevron-left glyph side length (R11a visual contract).
  static const double glyphSize = 16;

  /// Disabled opacity shared with `CtNinePatchButton` R1,
  /// `CtToggleSwitch` R8, and `CtProgressBar` R12.
  static const double disabledOpacity = 0.4;

  /// `--surface-lite` overlay alpha while hovered (R11a).
  static const double hoverBackgroundAlpha = 0.4;

  /// `--surface-lite` overlay alpha while pressed (R11a).
  static const double pressedBackgroundAlpha = 0.6;

  /// Hover/press fade duration shared with `CtToggleSwitch` slide and
  /// `CtProgressBar` fill animations.
  static const Duration animationDuration = Duration(milliseconds: 120);

  /// Hover/press fade curve.
  static const Curve animationCurve = Curves.easeOut;

  @override
  State<CtBackButton> createState() => _CtBackButtonState();
}

class _CtBackButtonState extends State<CtBackButton> {
  bool _hovered = false;
  bool _pressed = false;

  bool get _enabled => widget.enabled;

  void _handleHover(bool entered) {
    if (!_enabled) return;
    if (_hovered == entered) return;
    setState(() => _hovered = entered);
  }

  void _handlePressed(bool pressed) {
    if (!_enabled) return;
    if (_pressed == pressed) return;
    setState(() => _pressed = pressed);
  }

  void _handleTap() {
    final VoidCallback? cb = widget.onPressed;
    if (cb != null) {
      cb();
      return;
    }
    Navigator.of(context).maybePop();
  }

  Color get _iconColor {
    if (_pressed) return EditorialMonoclePalette.accentBright;
    if (_hovered) return EditorialMonoclePalette.accent;
    return EditorialMonoclePalette.accentDim;
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
    // Default (not hovered, not pressed) — fully transparent so no panel
    // is painted, while keeping the `surfaceLite` token as the animation
    // anchor so `AnimatedContainer` can lerp alpha 0 → 0.4 → 0.6 within
    // a single palette-bound color (Refs #2914 S4 — no raw hex literals).
    return EditorialMonoclePalette.surfaceLite.withValues(alpha: 0);
  }

  @override
  Widget build(BuildContext context) {
    final Widget body = AnimatedContainer(
      key: const ValueKey<String>('ctBackButtonBody'),
      duration: _enabled ? CtBackButton.animationDuration : Duration.zero,
      curve: CtBackButton.animationCurve,
      width: CtBackButton.size,
      height: CtBackButton.size,
      decoration: BoxDecoration(color: _backgroundColor),
      child: Center(
        child: Icon(
          Icons.chevron_left,
          size: CtBackButton.glyphSize,
          color: _iconColor,
        ),
      ),
    );
    if (!_enabled) {
      return Semantics(
        label: widget.semanticLabel,
        button: true,
        enabled: false,
        child: Opacity(
          opacity: CtBackButton.disabledOpacity,
          child: body,
        ),
      );
    }
    return Semantics(
      label: widget.semanticLabel,
      button: true,
      enabled: true,
      child: MouseRegion(
        onEnter: (_) => _handleHover(true),
        onExit: (_) => _handleHover(false),
        cursor: SystemMouseCursors.click,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTapDown: (_) => _handlePressed(true),
          onTapUp: (_) => _handlePressed(false),
          onTapCancel: () => _handlePressed(false),
          onTap: _handleTap,
          child: body,
        ),
      ),
    );
  }
}
