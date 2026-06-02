import 'package:flutter/material.dart';

import '../../../../config/editorial_monocle_palette.dart';
import '../../../../widgets/ct_gradients.dart';
import '../../../../widgets/ct_spacing.dart';

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

class _CtNinePatchButtonState extends State<CtNinePatchButton> {
  bool _hovered = false;
  bool _pressed = false;

  bool get _isInteractive => widget.enabled && widget.onPressed != null;

  void _handleHover(bool entered) {
    if (!_isInteractive) return;
    if (_hovered == entered) return;
    setState(() => _hovered = entered);
  }

  void _setPressed(bool pressed) {
    if (!_isInteractive) return;
    if (_pressed == pressed) return;
    setState(() => _pressed = pressed);
  }

  LinearGradient get _surfaceGradient {
    final LinearGradient defaultGradient =
        widget.gradient ?? CtGradients.buttonGradient;
    if (_pressed && widget.pressedGradient != null) {
      return widget.pressedGradient!;
    }
    return defaultGradient;
  }

  /// `dangerVariant` and `mutedVariant` are mutually exclusive — when both
  /// are `true`, `dangerVariant` wins so destructive intent is never
  /// visually weakened (per the catalog spec § *CtNinePatchButton* Muted
  /// variant).
  bool get _isMutedOnly => widget.mutedVariant && !widget.dangerVariant;

  Color get _cornerColor {
    final Color base = _hovered
        ? EditorialMonoclePalette.accentBright
        : EditorialMonoclePalette.accent;
    final double rawAlpha = _hovered
        ? CtNinePatchButton.hoverCornerAlpha
        : CtNinePatchButton.defaultCornerAlpha;
    final double alpha = _isMutedOnly
        ? rawAlpha * CtNinePatchButton.mutedCornerAlphaScale
        : rawAlpha;
    return base.withValues(alpha: alpha);
  }

  Color get _borderColor {
    if (widget.dangerVariant) {
      return EditorialMonoclePalette.danger;
    }
    if (_isMutedOnly) {
      return _hovered
          ? EditorialMonoclePalette.accent
          : EditorialMonoclePalette.accentDim;
    }
    return _hovered
        ? EditorialMonoclePalette.accent
        : EditorialMonoclePalette.border;
  }

  Color get _textColor {
    if (widget.dangerVariant) {
      return EditorialMonoclePalette.danger;
    }
    if (_isMutedOnly) {
      return _hovered
          ? EditorialMonoclePalette.accent
          : EditorialMonoclePalette.muted;
    }
    return _hovered
        ? EditorialMonoclePalette.accentBright
        : EditorialMonoclePalette.accent;
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final EdgeInsetsGeometry padding =
        widget.padding ?? CtNinePatchButton.defaultPadding;

    final TextStyle baseTextStyle =
        theme.textTheme.titleSmall ??
        theme.textTheme.bodyLarge ??
        const TextStyle();
    final TextStyle engravedStyle = baseTextStyle.copyWith(
      color: _textColor,
      shadows: <Shadow>[
        Shadow(
          offset: CtNinePatchButton.engravedShadowOffset,
          blurRadius: 0,
          color: EditorialMonoclePalette.surface,
        ),
      ],
    );

    final Widget content = Padding(
      padding: padding,
      child: Center(
        child: DefaultTextStyle.merge(
          style: engravedStyle,
          child: IconTheme.merge(
            data: IconThemeData(color: _textColor, size: 20),
            child: widget.child,
          ),
        ),
      ),
    );

    final Widget surface = AnimatedContainer(
      duration: _isInteractive
          ? CtNinePatchButton.animationDuration
          : Duration.zero,
      curve: CtNinePatchButton.animationCurve,
      constraints: BoxConstraints(minHeight: widget.minHeight),
      decoration: BoxDecoration(
        gradient: _surfaceGradient,
        border: Border.all(
          color: _borderColor,
          width: CtNinePatchButton.borderWidth,
        ),
      ),
      child: content,
    );

    final Widget framed = Stack(
      children: <Widget>[
        surface,
        Positioned.fill(
          child: IgnorePointer(
            child: _BrassCornerBrackets(color: _cornerColor),
          ),
        ),
      ],
    );

    if (!widget.enabled) {
      final double resolvedDisabledOpacity =
          widget.disabledOpacityOverride ?? CtNinePatchButton.disabledOpacity;
      return Opacity(
        opacity: resolvedDisabledOpacity,
        child: IgnorePointer(
          ignoring: true,
          child: framed,
        ),
      );
    }

    return MouseRegion(
      onEnter: (_) => _handleHover(true),
      onExit: (_) => _handleHover(false),
      cursor: _isInteractive
          ? SystemMouseCursors.click
          : SystemMouseCursors.basic,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: _isInteractive ? widget.onPressed : null,
          onTapDown: _isInteractive ? (_) => _setPressed(true) : null,
          onTapUp: _isInteractive ? (_) => _setPressed(false) : null,
          onTapCancel: _isInteractive ? () => _setPressed(false) : null,
          onHighlightChanged: _isInteractive ? _setPressed : null,
          child: framed,
        ),
      ),
    );
  }
}

/// Four 10x10 L-shaped brass corner overlays positioned at each corner of
/// the parent button surface. Painted via [CustomPaint] so the brackets
/// stay crisp at any DPR (no rasterised asset).
class _BrassCornerBrackets extends StatelessWidget {
  const _BrassCornerBrackets({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _BrassCornerBracketsPainter(color: color),
      child: const SizedBox.expand(),
    );
  }
}

class _BrassCornerBracketsPainter extends CustomPainter {
  _BrassCornerBracketsPainter({required this.color});

  final Color color;

  static const double _bracketLength = CtNinePatchButton.cornerBracketSize;
  static const double _bracketThickness =
      CtNinePatchButton.cornerBracketThickness;

  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint()..color = color;
    final double w = size.width;
    final double h = size.height;
    _paintCorner(canvas, paint, Offset.zero, 1, 1);
    _paintCorner(canvas, paint, Offset(w, 0), -1, 1);
    _paintCorner(canvas, paint, Offset(0, h), 1, -1);
    _paintCorner(canvas, paint, Offset(w, h), -1, -1);
  }

  void _paintCorner(
    Canvas canvas,
    Paint paint,
    Offset anchor,
    double dx,
    double dy,
  ) {
    final Rect horizontal = Rect.fromLTWH(
      dx > 0 ? anchor.dx : anchor.dx - _bracketLength,
      dy > 0 ? anchor.dy : anchor.dy - _bracketThickness,
      _bracketLength,
      _bracketThickness,
    );
    final Rect vertical = Rect.fromLTWH(
      dx > 0 ? anchor.dx : anchor.dx - _bracketThickness,
      dy > 0 ? anchor.dy : anchor.dy - _bracketLength,
      _bracketThickness,
      _bracketLength,
    );
    canvas.drawRect(horizontal, paint);
    canvas.drawRect(vertical, paint);
  }

  @override
  bool shouldRepaint(covariant _BrassCornerBracketsPainter oldDelegate) {
    return oldDelegate.color != color;
  }
}
