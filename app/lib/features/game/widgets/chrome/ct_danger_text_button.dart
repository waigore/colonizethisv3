// Dark editorial-monocle reusable danger text button.
// SPEC/ui/production-panel.md § Labour Controls (12-A) — Per-tier row layout.
// Mockup `.disband-btn` in SPEC/ui/mockups/GAME20001-production-panel.html.

import 'package:flutter/material.dart';

import '../../../../config/editorial_monocle_palette.dart';
import '../../../../config/themes.dart';
import 'ct_nine_patch_button.dart';

/// Reusable small text button used for destructive **danger** actions that
/// do not warrant the heavier [CtNinePatchButton] chrome.
///
/// The visual contract follows the canonical mockup `.disband-btn` rule
/// from `SPEC/ui/mockups/GAME20001-production-panel.html` lines 91–92 and
/// the issue #2862 owner decision **C2** (Option A — mockup-styled danger
/// text button, reusable):
///
/// - **Surface:** transparent (no gradient, no nine-patch).
/// - **Border:** 1 px [EditorialMonoclePalette.danger].
/// - **Foreground:** [EditorialMonoclePalette.danger] (label colour).
/// - **Font:** Cinzel display family ([editorialMonocleDisplayFontFamily])
///   at [_fontSize] (≈ 8 logical px) with [_letterSpacing] (`0.04em`).
/// - **Padding:** [_horizontalPadding] × [_verticalPadding] inset.
/// - **Idle opacity:** [idleOpacity] (`0.7`) so the control reads as a
///   secondary affordance against the surrounding row chrome.
/// - **Hover opacity:** [hoverOpacity] (`1.0`) once a pointer enters the
///   button bounds (desktop / mouse).
/// - **Disabled:** entire control wraps in an [Opacity] of
///   [CtNinePatchButton.disabledOpacity] (`0.4`) and ignores pointer events
///   via [IgnorePointer], mirroring the shared dark-theme disabled
///   convention used by [CtNinePatchButton] and other Ct-* controls.
///
/// No hard-coded colour literals are used — every visible colour resolves
/// through [EditorialMonoclePalette] tokens so the widget stays compliant
/// with the editorial-monocle theme contract.
class CtDangerTextButton extends StatefulWidget {
  const CtDangerTextButton({
    super.key,
    required this.onPressed,
    required this.label,
    this.enabled = true,
    this.semanticLabel,
    this.tooltip,
    this.icon,
    this.iconSize = 14,
  });

  /// Tap callback. Ignored when [enabled] is `false`.
  final VoidCallback? onPressed;

  /// Single-line label text rendered inside the button.
  final String label;

  /// Optional leading icon rendered before [label] (mockup destructive
  /// row-action pills such as the civilian units panel `.u-actions .cancel-btn`
  /// keep an icon + label per `SPEC/ui/civilian-units-panel.md` § Row actions,
  /// issue #3514). When `null` (default) the button keeps the original
  /// text-only chrome so existing call sites are unchanged.
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

  /// Idle opacity when [enabled] is `true` and pointer is not hovering.
  static const double idleOpacity = 0.7;

  /// Hover opacity when [enabled] is `true` and pointer is inside the
  /// button bounds.
  static const double hoverOpacity = 1.0;

  static const double _fontSize = 8;
  static const double _letterSpacing = 8 * 0.04; // .04em ≈ 0.32 logical px
  static const double _horizontalPadding = 6;
  static const double _verticalPadding = 2;
  static const double _borderWidth = 1;

  /// Hover animation duration (shared with [CtNinePatchButton]).
  static const Duration animationDuration = CtNinePatchButton.animationDuration;

  @override
  State<CtDangerTextButton> createState() => _CtDangerTextButtonState();
}

class _CtDangerTextButtonState extends State<CtDangerTextButton> {
  bool _hovered = false;

  bool get _isInteractive => widget.enabled && widget.onPressed != null;

  void _setHover(bool hovered) {
    if (!_isInteractive) return;
    if (_hovered == hovered) return;
    setState(() => _hovered = hovered);
  }

  double get _resolvedOpacity {
    if (!widget.enabled) {
      return CtNinePatchButton.disabledOpacity;
    }
    return _hovered
        ? CtDangerTextButton.hoverOpacity
        : CtDangerTextButton.idleOpacity;
  }

  @override
  Widget build(BuildContext context) {
    final Color dangerColor = EditorialMonoclePalette.danger;
    final TextStyle labelStyle = TextStyle(
      color: dangerColor,
      fontFamily: editorialMonocleDisplayFontFamily,
      fontSize: CtDangerTextButton._fontSize,
      letterSpacing: CtDangerTextButton._letterSpacing,
      fontWeight: FontWeight.w600,
    );

    final Widget surface = AnimatedContainer(
      duration: _isInteractive
          ? CtDangerTextButton.animationDuration
          : Duration.zero,
      curve: CtNinePatchButton.animationCurve,
      decoration: BoxDecoration(
        color: Colors.transparent,
        border: Border.all(
          color: dangerColor,
          width: CtDangerTextButton._borderWidth,
        ),
      ),
      padding: const EdgeInsets.symmetric(
        horizontal: CtDangerTextButton._horizontalPadding,
        vertical: CtDangerTextButton._verticalPadding,
      ),
      child: widget.icon == null
          ? Text(widget.label, style: labelStyle)
          : Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(widget.icon, size: widget.iconSize, color: dangerColor),
                const SizedBox(width: 4),
                Text(widget.label, style: labelStyle),
              ],
            ),
    );

    final Widget faded = Opacity(opacity: _resolvedOpacity, child: surface);

    if (!widget.enabled) {
      return Semantics(
        button: true,
        enabled: false,
        label: widget.semanticLabel ?? widget.label,
        child: IgnorePointer(child: faded),
      );
    }

    final Widget interactive = MouseRegion(
      onEnter: (_) => _setHover(true),
      onExit: (_) => _setHover(false),
      cursor: SystemMouseCursors.click,
      child: Material(
        color: Colors.transparent,
        child: InkWell(onTap: widget.onPressed, child: faded),
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
