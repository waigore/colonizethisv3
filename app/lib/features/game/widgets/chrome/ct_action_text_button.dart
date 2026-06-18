// Dark editorial-monocle reusable neutral action text button.
// SPEC/ui/production-panel.md § Layout — Available subpanel header.
// Mockup `.action-btn` in SPEC/ui/mockups/GAME20001-production-panel.html.

import 'package:flutter/material.dart';

import '../../../../config/editorial_monocle_palette.dart';
import '../../../../config/themes.dart';
import '../../../../widgets/ct_gradients.dart';
import 'ct_nine_patch_button.dart';

/// Reusable small **neutral** text button used for secondary panel-header
/// actions (e.g. the Available subpanel **Breakdown** affordance) that do not
/// warrant the heavier [CtNinePatchButton] nine-patch chrome.
///
/// The visual contract follows the canonical mockup `.action-btn` rule from
/// `SPEC/ui/mockups/GAME20001-production-panel.html` lines 39–40 and the
/// issue #2862 owner decision **C11**:
///
/// - **Surface:** [CtGradients.actionButtonGradient]
///   (`--surface-lite` → `--bg-deep`).
/// - **Border:** 1 px [EditorialMonoclePalette.border].
/// - **Foreground:** [EditorialMonoclePalette.accentDim] (idle) lifting to
///   [EditorialMonoclePalette.accentBright] on pointer hover (desktop / mouse).
/// - **Font:** Cinzel display family ([editorialMonocleDisplayFontFamily])
///   at [_fontSize] (10 logical px) with [_letterSpacing] (`0.04em`).
/// - **Padding:** [_horizontalPadding] × [_verticalPadding] inset
///   (10 × 3 logical px, matching the mockup `padding: 3px 10px`).
/// - **Disabled:** entire control wraps in an [Opacity] of
///   [CtNinePatchButton.disabledOpacity] (`0.4`) and ignores pointer events
///   via [IgnorePointer], mirroring the shared dark-theme disabled
///   convention used by [CtNinePatchButton] and other Ct-* controls.
///
/// This is the neutral counterpart to `CtDangerTextButton` (mockup
/// `.reset-btn` / `.disband-btn`); use that widget for destructive actions.
///
/// **Primary variant ([primary] == `true`):** Compact *primary* header pill
/// used by the unit panels' header actions (Train / Tile / Combine) per
/// `SPEC/ui/civilian-units-panel.md` § Header actions and issue #3514 owner
/// decision **#5** (mockup `.train-btn` / `.hdr-btn` primary family —
/// gradient surface, 1 px border, **no nine-patch corner brackets**). The
/// primary variant is visually distinct from the neutral secondary pill so
/// the player can tell a primary header action apart from a neutral one:
///
/// - **Surface:** [CtGradients.buttonGradient] (`--surface-lite` →
///   `--surface`) instead of the secondary `actionButtonGradient`.
/// - **Border:** [EditorialMonoclePalette.accentDim] (idle) lifting to
///   [EditorialMonoclePalette.accent] on hover (the secondary variant keeps a
///   static `--border`).
/// - **Foreground:** [EditorialMonoclePalette.accent] (idle) lifting to
///   [EditorialMonoclePalette.accentBright] on hover (brighter than the
///   secondary's `--accent-dim` idle).
/// - **Font weight:** [FontWeight.w700] (the secondary keeps `w600`).
///
/// No hard-coded colour literals are used — every visible colour resolves
/// through [EditorialMonoclePalette] tokens so the widget stays compliant
/// with the editorial-monocle theme contract.
class CtActionTextButton extends StatefulWidget {
  const CtActionTextButton({
    super.key,
    required this.onPressed,
    required this.label,
    this.enabled = true,
    this.semanticLabel,
    this.tooltip,
    this.primary = false,
    this.icon,
    this.iconSize = 14,
  });

  /// Tap callback. Ignored when [enabled] is `false`.
  final VoidCallback? onPressed;

  /// Single-line label text rendered inside the button.
  final String label;

  /// Optional leading icon rendered before [label] (mockup row-action pills
  /// such as the civilian units panel `.u-actions button` keep an icon + label
  /// per `SPEC/ui/civilian-units-panel.md` § Row actions and issue #3514 owner
  /// decision #7 — Assign stays icon + label). When `null` (default) the
  /// button keeps the original text-only chrome so existing header / secondary
  /// call sites are unchanged.
  final IconData? icon;

  /// Rendered size of [icon] when present. Defaults to the compact row-action
  /// footprint (14 logical px) used by the unit-panel mockups.
  final double iconSize;

  /// When `false`, the entire control fades to the shared
  /// [CtNinePatchButton.disabledOpacity] and ignores pointer events.
  final bool enabled;

  /// Optional semantic label override. When `null` the button uses
  /// [label] verbatim for accessibility.
  final String? semanticLabel;

  /// Optional pointer tooltip; not rendered when `null`.
  final String? tooltip;

  /// When `true`, the button renders the **primary** header-pill variant
  /// (accent-dim border lifting to accent on hover, accent foreground, the
  /// `--surface-lite` → `--surface` [CtGradients.buttonGradient] surface, and
  /// a heavier label weight) per `SPEC/ui/civilian-units-panel.md`
  /// § Header actions (issue #3514 owner decision #5). When `false`
  /// (default), the button keeps the original neutral secondary `.action-btn`
  /// chrome so existing call sites do not change.
  final bool primary;

  static const double _fontSize = 10;
  static const double _letterSpacing = 10 * 0.04; // .04em = 0.4 logical px
  static const double _horizontalPadding = 10;
  static const double _verticalPadding = 3;
  static const double _borderWidth = 1;

  /// Hover animation duration (shared with [CtNinePatchButton]).
  static const Duration animationDuration = CtNinePatchButton.animationDuration;

  @override
  State<CtActionTextButton> createState() => _CtActionTextButtonState();
}

class _CtActionTextButtonState extends State<CtActionTextButton> {
  bool _hovered = false;

  bool get _isInteractive => widget.enabled && widget.onPressed != null;

  void _setHover(bool hovered) {
    if (!_isInteractive) return;
    if (_hovered == hovered) return;
    setState(() => _hovered = hovered);
  }

  Color get _resolvedForeground {
    if (widget.primary) {
      return _hovered
          ? EditorialMonoclePalette.accentBright
          : EditorialMonoclePalette.accent;
    }
    return _hovered
        ? EditorialMonoclePalette.accentBright
        : EditorialMonoclePalette.accentDim;
  }

  Color get _resolvedBorderColor {
    if (widget.primary) {
      return _hovered
          ? EditorialMonoclePalette.accent
          : EditorialMonoclePalette.accentDim;
    }
    return EditorialMonoclePalette.border;
  }

  LinearGradient get _resolvedGradient => widget.primary
      ? CtGradients.buttonGradient
      : CtGradients.actionButtonGradient;

  FontWeight get _resolvedFontWeight =>
      widget.primary ? FontWeight.w700 : FontWeight.w600;

  /// Builds the button content: the bare [Text] label (default) or a compact
  /// `Icon + label` row when [CtActionTextButton.icon] is set. The icon colour
  /// tracks the resolved foreground so it shares the idle/hover treatment.
  Widget _buildLabel() {
    final IconData? icon = widget.icon;
    if (icon == null) {
      return Text(widget.label);
    }
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: widget.iconSize, color: _resolvedForeground),
        const SizedBox(width: 4),
        Text(widget.label),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final Widget surface = DecoratedBox(
      decoration: BoxDecoration(
        gradient: _resolvedGradient,
        border: Border.all(
          color: _resolvedBorderColor,
          width: CtActionTextButton._borderWidth,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: CtActionTextButton._horizontalPadding,
          vertical: CtActionTextButton._verticalPadding,
        ),
        child: AnimatedDefaultTextStyle(
          duration: _isInteractive
              ? CtActionTextButton.animationDuration
              : Duration.zero,
          curve: CtNinePatchButton.animationCurve,
          style: TextStyle(
            color: _resolvedForeground,
            fontFamily: editorialMonocleDisplayFontFamily,
            fontSize: CtActionTextButton._fontSize,
            letterSpacing: CtActionTextButton._letterSpacing,
            fontWeight: _resolvedFontWeight,
          ),
          child: _buildLabel(),
        ),
      ),
    );

    if (!widget.enabled) {
      return Semantics(
        button: true,
        enabled: false,
        label: widget.semanticLabel ?? widget.label,
        child: IgnorePointer(
          child: Opacity(
            opacity: CtNinePatchButton.disabledOpacity,
            child: surface,
          ),
        ),
      );
    }

    final Widget interactive = MouseRegion(
      onEnter: (_) => _setHover(true),
      onExit: (_) => _setHover(false),
      cursor: SystemMouseCursors.click,
      child: Material(
        color: Colors.transparent,
        child: InkWell(onTap: widget.onPressed, child: surface),
      ),
    );

    Widget wrapped = Semantics(
      button: true,
      enabled: true,
      label: widget.semanticLabel ?? widget.label,
      child: interactive,
    );

    final String? tooltip = widget.tooltip;
    if (tooltip != null) {
      wrapped = Tooltip(message: tooltip, child: wrapped);
    }
    return wrapped;
  }
}
