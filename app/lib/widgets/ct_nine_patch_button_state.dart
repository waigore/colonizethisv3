part of 'ct_nine_patch_button.dart';

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

    final Widget label = DefaultTextStyle.merge(
      style: engravedStyle,
      child: IconTheme.merge(
        data: IconThemeData(color: _textColor, size: 20),
        child: widget.child,
      ),
    );
    final Widget content = Padding(
      padding: padding,
      // `widthFactor: 1.0` sizes the Align to its child's width so the surface
      // shrink-wraps to its label (compact cluster flow); the default `Center`
      // (no width factor) expands to fill the available width.
      child: widget.shrinkWrap
          ? Align(widthFactor: 1.0, child: label)
          : Center(child: label),
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
