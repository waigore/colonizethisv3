part of 'ct_action_text_button.dart';

class _CtActionTextButtonState extends State<CtActionTextButton>
    with CtHoverButtonStateMixin<CtActionTextButton> {
  @override
  bool get hoverButtonEnabled => widget.enabled;

  @override
  VoidCallback? get hoverButtonOnPressed => widget.onPressed;

  Color get _resolvedForeground {
    if (widget.primary) {
      return hovered
          ? EditorialMonoclePalette.accentBright
          : EditorialMonoclePalette.accent;
    }
    return hovered
        ? EditorialMonoclePalette.accentBright
        : EditorialMonoclePalette.accentDim;
  }

  Color get _resolvedBorderColor {
    if (widget.primary) {
      return hovered
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
    if (widget.iconOnly) {
      return Icon(icon, size: widget.iconSize, color: _resolvedForeground);
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
          duration: isInteractive
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

    return buildHoverButton(
      surface: surface,
      semanticLabel: widget.semanticLabel ?? widget.label,
      tooltip: widget.tooltip,
      disabledOpacity: CtNinePatchButton.disabledOpacity,
    );
  }
}
