import 'package:colonizethis_app_ui_chrome/config/editorial_monocle_palette.dart';
import 'package:flutter/material.dart';

import 'ct_gradients.dart';
import 'ct_nine_patch_button.dart';
import 'ct_nine_patch_button_brackets.dart';

/// Stateful implementation for [CtNinePatchButton] (Refs #4117 de-part).
class CtNinePatchButtonState extends State<CtNinePatchButton> {
  bool _hovered = false;
  bool _pressed = false;

  bool get isInteractive => widget.enabled && widget.onPressed != null;

  void handleHover(bool entered) {
    if (!isInteractive) return;
    if (_hovered == entered) return;
    setState(() => _hovered = entered);
  }

  void setPressed(bool pressed) {
    if (!isInteractive) return;
    if (_pressed == pressed) return;
    setState(() => _pressed = pressed);
  }

  LinearGradient get surfaceGradient {
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
  bool get isMutedOnly => widget.mutedVariant && !widget.dangerVariant;

  Color get cornerColor {
    final Color base = _hovered
        ? EditorialMonoclePalette.accentBright
        : EditorialMonoclePalette.accent;
    final double rawAlpha = _hovered
        ? CtNinePatchButton.hoverCornerAlpha
        : CtNinePatchButton.defaultCornerAlpha;
    final double alpha = isMutedOnly
        ? rawAlpha * CtNinePatchButton.mutedCornerAlphaScale
        : rawAlpha;
    return base.withValues(alpha: alpha);
  }

  Color get borderColor {
    if (widget.dangerVariant) {
      return EditorialMonoclePalette.danger;
    }
    if (isMutedOnly) {
      return _hovered
          ? EditorialMonoclePalette.accent
          : EditorialMonoclePalette.accentDim;
    }
    return _hovered
        ? EditorialMonoclePalette.accent
        : EditorialMonoclePalette.border;
  }

  Color get textColor {
    if (widget.dangerVariant) {
      return EditorialMonoclePalette.danger;
    }
    if (isMutedOnly) {
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
      color: textColor,
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
        data: IconThemeData(color: textColor, size: 20),
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
      duration: isInteractive
          ? CtNinePatchButton.animationDuration
          : Duration.zero,
      curve: CtNinePatchButton.animationCurve,
      constraints: BoxConstraints(minHeight: widget.minHeight),
      decoration: BoxDecoration(
        gradient: surfaceGradient,
        border: Border.all(
          color: borderColor,
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
            child: CtNinePatchButtonBrackets(color: cornerColor),
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
      onEnter: (_) => handleHover(true),
      onExit: (_) => handleHover(false),
      cursor: isInteractive
          ? SystemMouseCursors.click
          : SystemMouseCursors.basic,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: isInteractive ? widget.onPressed : null,
          onTapDown: isInteractive ? (_) => setPressed(true) : null,
          onTapUp: isInteractive ? (_) => setPressed(false) : null,
          onTapCancel: isInteractive ? () => setPressed(false) : null,
          onHighlightChanged: isInteractive ? setPressed : null,
          child: framed,
        ),
      ),
    );
  }
}
