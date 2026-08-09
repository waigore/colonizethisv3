import 'package:flutter/material.dart';

import 'package:colonizethis_app_ui_chrome/config/editorial_monocle_palette.dart';
import 'ct_back_button.dart';

import 'ct_icon_action_state.dart';

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
  State<CtIconAction> createState() => CtIconActionState();
}
