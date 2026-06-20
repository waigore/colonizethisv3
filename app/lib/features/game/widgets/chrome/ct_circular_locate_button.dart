// Dark editorial-monocle reusable circular icon-only "locate" pill.
// SPEC/ui/civilian-units-panel.md § Row actions.
// Mockup `.u-actions .locate-btn` in
// SPEC/ui/mockups/UNIT10001-civilian-units-panel.html.

import 'package:flutter/material.dart';

import '../../../../config/editorial_monocle_palette.dart';
import '../../../../widgets/ct_gradients.dart';
import 'ct_nine_patch_button.dart';

/// Compact **circular** icon-only action used for the right-most "Locate"
/// affordance on unit-panel rows (issue #3514 owner decision #6 / mockup
/// `.u-actions .locate-btn`: `width:22px; height:22px; border-radius:50%`).
///
/// Visual contract (mirrors the neutral [CtActionTextButton] row-action pill
/// chrome but in a circular footprint):
///
/// - **Shape:** circle of [diameter] (22 logical px) via a [BoxShape.circle]
///   [BoxDecoration].
/// - **Surface:** [CtGradients.actionButtonGradient]
///   (`--surface-lite` → `--bg-deep`).
/// - **Border:** 1 px [EditorialMonoclePalette.border] (idle) lifting to
///   [EditorialMonoclePalette.accentDim] on pointer hover (desktop / mouse).
/// - **Foreground:** [EditorialMonoclePalette.accentDim] (idle) lifting to
///   [EditorialMonoclePalette.accentBright] on hover.
/// - **Disabled:** entire control wraps in an [Opacity] of
///   [CtNinePatchButton.disabledOpacity] (`0.4`) and ignores pointer events
///   via [IgnorePointer], mirroring the shared dark-theme disabled convention.
///
/// No hard-coded colour literals are used — every visible colour resolves
/// through [EditorialMonoclePalette] tokens so the widget stays compliant with
/// the editorial-monocle theme contract.
class CtCircularLocateButton extends StatefulWidget {
  const CtCircularLocateButton({
    super.key,
    required this.onPressed,
    required this.icon,
    this.tooltip,
    this.semanticLabel,
    this.enabled = true,
    this.diameter = 22,
    this.iconSize = 13,
  });

  /// Tap callback. Ignored when [enabled] is `false`.
  final VoidCallback? onPressed;

  /// Icon rendered centred inside the circular button.
  final IconData icon;

  /// Optional pointer tooltip; not rendered when `null`.
  final String? tooltip;

  /// Optional accessibility label override. When `null` the button falls back
  /// to [tooltip].
  final String? semanticLabel;

  /// When `false`, the control fades to [CtNinePatchButton.disabledOpacity]
  /// and ignores pointer events.
  final bool enabled;

  /// Diameter of the circular hit/paint area (mockup `.locate-btn` = 22 px).
  final double diameter;

  /// Rendered size of [icon].
  final double iconSize;

  static const double _borderWidth = 1;

  /// Hover animation duration (shared with [CtNinePatchButton]).
  static const Duration animationDuration = CtNinePatchButton.animationDuration;

  @override
  State<CtCircularLocateButton> createState() => _CtCircularLocateButtonState();
}

class _CtCircularLocateButtonState extends State<CtCircularLocateButton> {
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

  Color get _resolvedBorderColor => _hovered
      ? EditorialMonoclePalette.accentDim
      : EditorialMonoclePalette.border;

  @override
  Widget build(BuildContext context) {
    final Widget surface = AnimatedContainer(
      duration: _isInteractive
          ? CtCircularLocateButton.animationDuration
          : Duration.zero,
      curve: CtNinePatchButton.animationCurve,
      width: widget.diameter,
      height: widget.diameter,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: CtGradients.actionButtonGradient,
        border: Border.all(
          color: _resolvedBorderColor,
          width: CtCircularLocateButton._borderWidth,
        ),
      ),
      child: Icon(
        widget.icon,
        size: widget.iconSize,
        color: _resolvedForeground,
      ),
    );

    if (!widget.enabled) {
      return Semantics(
        button: true,
        enabled: false,
        label: widget.semanticLabel ?? widget.tooltip,
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
        shape: const CircleBorder(),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: widget.onPressed,
          customBorder: const CircleBorder(),
          child: surface,
        ),
      ),
    );

    Widget wrapped = Semantics(
      button: true,
      enabled: true,
      label: widget.semanticLabel ?? widget.tooltip,
      child: interactive,
    );

    final String? tooltip = widget.tooltip;
    if (tooltip != null) {
      wrapped = Tooltip(message: tooltip, child: wrapped);
    }
    return wrapped;
  }
}
