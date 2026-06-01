import 'package:flutter/material.dart';

import '../config/editorial_monocle_palette.dart';
import 'ct_back_button.dart';

/// Standalone pixel-art glyph-only **action affordance** for the dark
/// editorial-monocle theme.
///
/// Implements `Refs #2914` Phase 1 §S8 — replacement for the generic Material
/// `IconButton` chrome banned by `SPEC/ui/pixel-art-ui-catalog.md`
/// § Material design ban. `CtIconAction` is the catalog primitive for tap
/// targets that surface a single glyph (e.g. *locate*, *explore*,
/// *prospect*, *build improvement*, *menu*) with an optional tooltip, an
/// optional disabled state, and no heavier nine-patch / back-affordance
/// chrome around the glyph.
///
/// Visual contract (per `SPEC/ui/pixel-art-ui-catalog.md` § Pixel-art
/// component catalog — `CtIconAction`):
///
/// - **Tap target:** square box sized [iconSize] + [hitPadding] × 2 on
///   each axis (default 18 + 2×3 = 24 logical px). Centred glyph.
/// - **Idle glyph colour:** [iconColor] when supplied, otherwise
///   [EditorialMonoclePalette.accentDim] — matching the `CtBackButton`
///   idle convention.
/// - **Hover:** glyph brightens to [EditorialMonoclePalette.accent] (or
///   [hoverIconColor] override). A `--surface-lite` panel fades in over
///   [CtBackButton.animationDuration] (120 ms) at
///   [CtBackButton.hoverBackgroundAlpha] (`0.4`).
/// - **Pressed:** glyph brightens to [EditorialMonoclePalette.accentBright]
///   (or [pressedIconColor] override). Background panel bumps to
///   [CtBackButton.pressedBackgroundAlpha] (`0.6`).
/// - **Disabled:** the entire widget wraps in
///   [CtBackButton.disabledOpacity] (`0.4`) and ignores pointer events
///   (matches the shared disabled convention used by `CtBackButton`,
///   `CtNinePatchButton`, `CtToggleSwitch`, and `CtProgressBar`).
///
/// When [tooltip] is non-null the widget wraps itself in a Material
/// [Tooltip] so consumers retain the same pointer-hover affordance the
/// banned `IconButton` provided. The tooltip wrap is preserved even when
/// the widget is disabled, matching the banned `IconButton.tooltip`
/// behaviour and the disabled-state regression tests in
/// `province_overlay_tile_section_dark_tokens_test.dart` that probe the
/// disabled glyph through `find.byTooltip(...)`.
///
/// All colours resolve through [EditorialMonoclePalette] tokens — no
/// hard-coded `Colors.*` or hex literals.
class CtIconAction extends StatefulWidget {
  const CtIconAction({
    super.key,
    required this.icon,
    required this.onPressed,
    this.tooltip,
    this.semanticLabel,
    this.iconSize = defaultIconSize,
    this.iconColor,
    this.hoverIconColor,
    this.pressedIconColor,
    this.disabledIconColor,
    this.hitPadding = defaultHitPadding,
    this.enabled = true,
  });

  /// Glyph data rendered inside the tap target.
  final IconData icon;

  /// Tap callback. When `null` the widget renders as disabled regardless
  /// of [enabled].
  final VoidCallback? onPressed;

  /// Optional Material [Tooltip] message shown on pointer hover and long
  /// press. Mirrors the banned `IconButton.tooltip` parameter.
  final String? tooltip;

  /// Accessibility label for screen readers. When `null` the widget falls
  /// back to [tooltip] (when set) and finally to `null` so the underlying
  /// [Icon] semantics apply.
  final String? semanticLabel;

  /// Glyph side length in logical pixels. Defaults to [defaultIconSize]
  /// (18 dp) — matching the dominant `IconButton(iconSize: 18)` use
  /// across the existing feature tree (`SPEC/ui/pixel-art-ui-catalog.md`
  /// § `CtIconAction`).
  final double iconSize;

  /// Optional override for the idle glyph colour. Defaults to
  /// [EditorialMonoclePalette.accentDim] (matches `CtBackButton`).
  final Color? iconColor;

  /// Optional override for the hover glyph colour. Defaults to
  /// [EditorialMonoclePalette.accent].
  final Color? hoverIconColor;

  /// Optional override for the pressed glyph colour. Defaults to
  /// [EditorialMonoclePalette.accentBright].
  final Color? pressedIconColor;

  /// Optional override for the disabled glyph colour. When `null` the
  /// idle colour is used and the entire widget is wrapped in
  /// [CtBackButton.disabledOpacity] (0.4) to fade it uniformly — matching
  /// the shared disabled convention.
  final Color? disabledIconColor;

  /// Symmetric padding added around the glyph to build the tap target.
  /// Default [defaultHitPadding] (3 dp) yields a 24 dp tap target at the
  /// default 18 dp glyph size — the same nominal touch surface the
  /// banned `IconButton(visualDensity: VisualDensity.compact)` produced
  /// for the existing call sites.
  final double hitPadding;

  /// When `false`, the widget renders at [CtBackButton.disabledOpacity]
  /// and ignores taps / hover.
  final bool enabled;

  /// Default glyph side length. Mirrors the dominant per-call `iconSize`
  /// for the IconButton sites being migrated by `Refs #2914` Phase 1 §S8.
  static const double defaultIconSize = 18;

  /// Default per-side hit padding around the glyph.
  static const double defaultHitPadding = 3;

  @override
  State<CtIconAction> createState() => _CtIconActionState();
}

class _CtIconActionState extends State<CtIconAction> {
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
