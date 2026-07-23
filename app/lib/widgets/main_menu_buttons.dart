// Main-menu button widgets (Refs #4117 de-part).
//
// SPEC/program/dart-file-non-comment-line-size.md.

import 'package:flutter/material.dart';
import 'package:colonizethis_app_l10n/l10n/l10n.dart';

import 'ct_gradients.dart';
import 'ct_nine_patch_button.dart';
import 'main_menu_constants.dart';
import 'main_menu_variant.dart';

class MainMenuButton extends StatelessWidget {
  const MainMenuButton({
    required this.label,
    required this.variant,
    required this.narrow,
    required this.onPressed,
  });

  final String label;
  final MainMenuVariant variant;
  final bool narrow;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    if (variant == MainMenuVariant.pixelArt) {
      return MainMenuPixelArtButton(
        label: label,
        narrow: narrow,
        onPressed: onPressed,
      );
    }
    return SizedBox(
      width: double.infinity,
      child: CtNinePatchButton(onPressed: onPressed, child: Text(label)),
    );
  }
}

class MainMenuPixelArtButton extends StatefulWidget {
  const MainMenuPixelArtButton({
    required this.label,
    required this.onPressed,
    required this.narrow,
    this.enabled = true,
  });

  final String label;
  final VoidCallback onPressed;
  final bool narrow;
  final bool enabled;

  @override
  State<MainMenuPixelArtButton> createState() => _MainMenuPixelArtButtonState();
}

class _MainMenuPixelArtButtonState extends State<MainMenuPixelArtButton>
    with SingleTickerProviderStateMixin {
  bool _hovered = false;
  static const double _bobAmount = 2.5;
  static const Duration _bobDuration = Duration(milliseconds: 800);

  late final AnimationController _bobController;
  late final Animation<double> _bobAnimation;

  @override
  void initState() {
    super.initState();
    _bobController = AnimationController(vsync: this, duration: _bobDuration);
    _bobAnimation = Tween<double>(
      begin: 0,
      end: 1,
    ).animate(CurvedAnimation(parent: _bobController, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _bobController.dispose();
    super.dispose();
  }

  void _onHoverEnter(PointerEvent _) {
    if (!widget.enabled) return;
    setState(() => _hovered = true);
    _bobController.repeat(reverse: true);
  }

  void _onHoverExit(PointerEvent _) {
    setState(() => _hovered = false);
    _bobController.stop();
    _bobController.reset();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 48,
      child: MouseRegion(
        onEnter: _onHoverEnter,
        onExit: _onHoverExit,
        cursor: widget.enabled
            ? SystemMouseCursors.click
            : SystemMouseCursors.basic,
        child: AnimatedBuilder(
          animation: _bobAnimation,
          builder: (context, child) {
            final double dy = _hovered
                ? (_bobAnimation.value * 2 * _bobAmount - _bobAmount)
                : 0;
            return Transform.translate(offset: Offset(0, dy), child: child);
          },
          child: ColorFiltered(
            colorFilter: _hovered && widget.enabled
                ? ColorFilter.mode(
                    Colors.black.withValues(alpha: 0.15),
                    BlendMode.darken,
                  )
                : const ColorFilter.mode(Colors.transparent, BlendMode.dst),
            child: CtNinePatchButton(
              onPressed: widget.enabled ? widget.onPressed : null,
              enabled: widget.enabled,
              minHeight: 48,
              gradient: CtGradients.woodPanelButtonGradient,
              pressedGradient: CtGradients.woodPanelButtonGradientPressed,
              child: Text(
                widget.label,
                style: TextStyle(
                  letterSpacing: widget.narrow
                      ? kMainMenuButtonLetterSpacingNarrow
                      : kMainMenuButtonLetterSpacingDefault,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class MainMenuLoadGameButton extends StatelessWidget {
  const MainMenuLoadGameButton({
    required this.enabled,
    required this.variant,
    required this.narrow,
    required this.onPressed,
  });

  final bool enabled;
  final MainMenuVariant variant;
  final bool narrow;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final l10n = appL10n(context);
    if (variant == MainMenuVariant.pixelArt) {
      return Tooltip(
        message: enabled ? '' : l10n.mainMenu_noSavesTooltip,
        child: MainMenuPixelArtButton(
          label: l10n.mainMenu_loadGame,
          enabled: enabled,
          narrow: narrow,
          onPressed: onPressed,
        ),
      );
    }
    return Tooltip(
      message: enabled ? '' : l10n.mainMenu_noSavesTooltip,
      child: SizedBox(
        width: double.infinity,
        child: CtNinePatchButton(
          onPressed: enabled ? onPressed : null,
          enabled: enabled,
          child: Text(l10n.mainMenu_loadGame),
        ),
      ),
    );
  }
}
