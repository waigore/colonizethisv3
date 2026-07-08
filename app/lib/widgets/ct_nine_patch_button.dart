import 'package:flutter/material.dart';

import 'package:colonizethis_app_ui_chrome/config/editorial_monocle_palette.dart';
import 'ct_gradients.dart';
import 'ct_spacing.dart';

part 'ct_nine_patch_button_state.dart';
part 'ct_nine_patch_button_brackets.dart';

/// Dark editorial-monocle primary/secondary/action button.
///
/// Implements `Refs #2859` S2 / R1 by painting a token-resolved
/// [CtGradients.buttonGradient] surface, four 10x10 px brass corner brackets,
/// and engraved label text (single 1 px downward drop-shadow coloured from
/// [EditorialMonoclePalette.surface]). The chrome no longer depends on the
/// legacy `ui_button_nine_patch.png` parchment asset; the widget is renamed
/// in intent only (the public class name `CtNinePatchButton` is preserved so
/// existing call sites and tests do not churn).
///
/// **Visual contract (per #2859 R1):**
/// - **Default surface:** [CtGradients.buttonGradient] (top→bottom
///   `--surface-lite` → `--surface`) with a 1 px [EditorialMonoclePalette.border]
///   border on every side.
/// - **Brass corner brackets:** Four [cornerBracketSize] × [cornerBracketSize]
///   L-shaped overlays painted in [EditorialMonoclePalette.accent]. Default
///   alpha is [defaultCornerAlpha]; hover lifts alpha to [hoverCornerAlpha]
///   and recolours to [EditorialMonoclePalette.accentBright]. Hover also
///   shifts the border to [EditorialMonoclePalette.accent].
/// - **Engraved label text:** [DefaultTextStyle] sets the body colour from
///   the dark-theme `titleSmall` slot (default
///   [EditorialMonoclePalette.accent]; hover
///   [EditorialMonoclePalette.accentBright]) and adds a single 1 px downward
///   drop-shadow (`Offset(0, 1)`, `blurRadius: 0`,
///   colour [EditorialMonoclePalette.surface]) so the label reads as
///   recessed brass.
/// - **Disabled:** Entire widget renders at [disabledOpacity] (0.4) and
///   suppresses pointer events / hover.
/// - **Touch target:** Minimum [minHeight] (default 48 dp); inner padding is
///   `CtSpacing.l` (16 px) horizontal / `CtSpacing.ml` (12 px) vertical
///   unless [padding] overrides. Tokens resolve through
///   `SPEC/ui/pixel-art-ui-catalog.md` § *Spacing tokens*.
///
/// All colours resolve from [EditorialMonoclePalette] tokens (`--surface`,
/// `--surface-lite`, `--accent`, `--accent-bright`, `--border`); no
/// hard-coded hex literals are used. SPEC:
/// `SPEC/ui/pixel-art-ui-catalog.md` § *CtNinePatchButton* (R1 visual
/// contract) and `SPEC/ui/buttons-nine-patch.md`.
class CtNinePatchButton extends StatefulWidget {
  const CtNinePatchButton({
    super.key,
    required this.onPressed,
    required this.child,
    this.enabled = true,
    this.padding,
    this.destTileSize = 16,
    this.minHeight = 48,
    this.shrinkWrap = false,
    this.dangerVariant = false,
    this.mutedVariant = false,
    this.disabledOpacityOverride,
    this.gradient,
    this.pressedGradient,
  });

  /// Callback fired on tap when [enabled] is `true` and [onPressed] is
  /// non-null.
  final VoidCallback? onPressed;

  /// Button content (label, icon, or a row combining both).
  final Widget child;

  /// When `false`, the widget renders at [disabledOpacity] and ignores
  /// pointer events.
  final bool enabled;

  /// Override for inner padding. Defaults to [defaultPadding]
  /// (`CtSpacing.l` horizontal / `CtSpacing.ml` vertical) per
  /// `SPEC/ui/pixel-art-ui-catalog.md` § *Spacing tokens*, matching the
  /// legacy nine-patch button's content inset.
  final EdgeInsetsGeometry? padding;

  /// Default inner padding applied when [padding] is `null`.
  /// `CtSpacing.l` (16 px) horizontal / `CtSpacing.ml` (12 px) vertical
  /// per `SPEC/ui/pixel-art-ui-catalog.md` § *Spacing tokens*. Exposed so
  /// widget tests and Widgetbook stories can pin the canonical default
  /// without re-deriving the literal.
  static const EdgeInsetsGeometry defaultPadding = EdgeInsets.symmetric(
    horizontal: CtSpacing.l,
    vertical: CtSpacing.ml,
  );

  /// Retained for backward compatibility with the legacy nine-patch
  /// rendering. The dark editorial-monocle visual contract no longer
  /// rasterises a nine-patch image, so this argument has **no effect** on
  /// rendering; it remains in the constructor signature so existing call
  /// sites continue to compile without churn. Removal is deferred to a
  /// follow-up cleanup slice once all `destTileSize:` arguments are
  /// dropped.
  final double destTileSize;

  /// Minimum tap-target height. The 48 dp default keeps the button above
  /// the 44 dp accessibility threshold called out in
  /// `SPEC/ui/buttons-nine-patch.md`.
  final double minHeight;

  /// When `false` (default), the button content is centered and the surface
  /// **expands to fill** the available cross-axis width handed down by the
  /// parent (the legacy behaviour: a `Center` inside loose constraints grows
  /// to the maximum width, so buttons in a `Column`/`Wrap` fill the run).
  ///
  /// When `true`, the surface **shrink-wraps to its content width** (label +
  /// [padding]) instead of expanding. This lets several compact buttons share
  /// a single `Wrap` run and flow left-to-right rather than each occupying the
  /// full run width as a vertical column. Used by the diplomacy panel action
  /// cluster per `SPEC/ui/diplomacy-panel.md` § Action button styling
  /// (Refs #3621). The [minHeight] tap target is unchanged. Defaults to
  /// `false` so every existing call site keeps its expanding layout.
  final bool shrinkWrap;

  /// When `true`, the resolved border and engraved label foreground swap
  /// from the brass `--border` / `--accent` family to the `--danger` token
  /// (border, label, and hover all stay on `--danger`). The gradient
  /// surface and brass corner brackets are unchanged. Used by destructive
  /// action buttons such as the diplomacy panel `Declare War` button per
  /// `SPEC/ui/diplomacy-panel.md` § Action button styling, the move-army
  /// war confirmation `Declare war and move` button per
  /// `SPEC/ui/move-army-dialog.md` § Invade-confirm sub-dialog, and
  /// `SPEC/ui/pixel-art-ui-catalog.md` § Pixel-art component catalog
  /// (CtNinePatchButton). Defaults to `false`.
  final bool dangerVariant;

  /// When `true`, the button renders with a secondary / "muted" emphasis:
  /// idle border `--accent-dim` (lifts to `--accent` on hover); idle label
  /// `--muted` (lifts to `--accent` on hover); brass corner brackets at
  /// [mutedCornerAlphaScale] of their default alpha so the affordance reads
  /// as visually de-emphasised against a sibling primary `CtNinePatchButton`
  /// in the same row/column. The gradient surface, padding, drop-shadow,
  /// and minimum tap target are unchanged so muted buttons remain
  /// accessible and aligned with their primary siblings. Used by
  /// **Diplomatic protest** and **Do naught** in the intervention overlay
  /// per `SPEC/ui/screens/pending-intervention-overlay.md` § Choice-button
  /// styling and `SPEC/ui/pixel-art-ui-catalog.md` § *CtNinePatchButton*
  /// (Muted variant; #2867 R26b). Mutually exclusive with [dangerVariant];
  /// when both are `true`, [dangerVariant] wins so destructive intent is
  /// never visually weakened. Defaults to `false`.
  final bool mutedVariant;

  /// Optional per-instance override for the disabled-state [Opacity] used
  /// when [enabled] is `false` (or [onPressed] is `null`). When `null`
  /// (default), the widget falls back to the shared catalog convention
  /// [CtNinePatchButton.disabledOpacity] (`0.4`) used by `CtBackButton`,
  /// `CtToggleSwitch`, `CtProgressBar`, and every other dark-theme
  /// disabled control. Specific call sites whose SPEC mockups require a
  /// different value (e.g. the in-game Next-turn button — `0.35` per
  /// `SPEC/ui/game-screen.md` ACs and `.next-turn.disabled` in
  /// `SPEC/ui/mockups/GAME10001-game-screen.html`, issue #2861 R1) pass
  /// the desired value here. Must be in the closed range `[0.0, 1.0]`.
  final double? disabledOpacityOverride;

  /// Optional surface gradient override. When `null` (default), the button
  /// paints [CtGradients.buttonGradient] so existing call sites continue to
  /// render the canonical 2-stop `--surface-lite` → `--surface` surface.
  /// Bespoke variants — notably the `pixelArt` main-menu wood-panel button
  /// per `SPEC/ui/main-menu.md` § Buttons region — pass a 3-stop gradient
  /// (`CtGradients.woodPanelButtonGradient`).
  final LinearGradient? gradient;

  /// Optional pressed-state gradient. When non-`null`, replaces the surface
  /// gradient while the button is actively held (between `onTapDown` and
  /// `onTap` / `onTapCancel`). Mirrors the mockup `.menu-btn:active` rule
  /// in `SPEC/ui/mockups/SHEL10002-main-menu.html` and AC
  /// `Wood-panel button pressed gradient inversion` in
  /// `SPEC/ui/main-menu.md`. When `null` the button keeps painting
  /// [gradient] (or [CtGradients.buttonGradient] when `gradient` is also
  /// `null`) regardless of press state, preserving the prior visual contract
  /// for every existing call site.
  final LinearGradient? pressedGradient;

  /// Side length of each brass corner-bracket overlay (R1).
  static const double cornerBracketSize = 10;

  /// Stroke thickness used to draw each L-shaped corner bracket (R1).
  static const double cornerBracketThickness = 2;

  /// Border width painted around the gradient surface (R1).
  static const double borderWidth = 1;

  /// Shared disabled opacity convention with `CtBackButton`,
  /// `CtToggleSwitch`, `CtProgressBar`, etc.
  static const double disabledOpacity = 0.4;

  /// Default corner-bracket alpha (R1: "opacity 0.75").
  static const double defaultCornerAlpha = 0.75;

  /// Hover corner-bracket alpha (R1: "opacity 0.75→1.0").
  static const double hoverCornerAlpha = 1.0;

  /// Multiplier applied to [defaultCornerAlpha] / [hoverCornerAlpha] when
  /// [mutedVariant] is `true` so the brass brackets read as half-strength
  /// against a sibling primary button (per `SPEC/ui/pixel-art-ui-catalog.md`
  /// § *CtNinePatchButton* (Muted variant)). With the canonical `0.75 → 1.0`
  /// alpha cycle this resolves to `0.375 → 0.5` — bright enough that the
  /// brackets remain visible at narrow viewports, dim enough that the
  /// muted button does not read as a co-equal primary action.
  static const double mutedCornerAlphaScale = 0.5;

  /// Engraved-text shadow offset (R1: 1 px downward).
  static const Offset engravedShadowOffset = Offset(0, 1);

  /// Hover animation duration (shared with `CtBackButton`,
  /// `CtToggleSwitch`).
  static const Duration animationDuration = Duration(milliseconds: 120);

  /// Hover animation curve.
  static const Curve animationCurve = Curves.easeOut;

  @override
  State<CtNinePatchButton> createState() => _CtNinePatchButtonState();
}
