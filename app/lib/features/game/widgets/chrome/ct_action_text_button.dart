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
  });

  /// Tap callback. Ignored when [enabled] is `false`.
  final VoidCallback? onPressed;

  /// Single-line label text rendered inside the button.
  final String label;

  /// When `false`, the entire control fades to the shared
  /// [CtNinePatchButton.disabledOpacity] and ignores pointer events.
  final bool enabled;

  /// Optional semantic label override. When `null` the button uses
  /// [label] verbatim for accessibility.
  final String? semanticLabel;

  /// Optional pointer tooltip; not rendered when `null`.
  final String? tooltip;

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

  Color get _resolvedForeground => _hovered
      ? EditorialMonoclePalette.accentBright
      : EditorialMonoclePalette.accentDim;

  @override
  Widget build(BuildContext context) {
    final Widget surface = DecoratedBox(
      decoration: BoxDecoration(
        gradient: CtGradients.actionButtonGradient,
        border: Border.all(
          color: EditorialMonoclePalette.border,
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
            fontWeight: FontWeight.w600,
          ),
          child: Text(widget.label),
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
        child: InkWell(
          onTap: widget.onPressed,
          child: surface,
        ),
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
