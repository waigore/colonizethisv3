part of 'game_top_bar.dart';

/// 28 x 28 bordered pause tap target per mockup `.pause-btn-sm`.
class _GameTopBarPauseButton extends StatefulWidget {
  const _GameTopBarPauseButton({required this.onPressed, required this.tooltip});

  final VoidCallback onPressed;
  final String tooltip;

  static const double _hoverBackgroundAlpha = 0.4;
  static const double _pressedBackgroundAlpha = 0.6;
  static const Duration _animationDuration = Duration(milliseconds: 120);
  static const Curve _animationCurve = Curves.easeOut;

  @override
  State<_GameTopBarPauseButton> createState() => _GameTopBarPauseButtonState();
}

class _GameTopBarPauseButtonState extends State<_GameTopBarPauseButton> {
  bool _hovered = false;
  bool _pressed = false;

  void _handleHover(bool entered) {
    if (_hovered == entered) return;
    setState(() => _hovered = entered);
  }

  void _handlePressed(bool pressed) {
    if (_pressed == pressed) return;
    setState(() => _pressed = pressed);
  }

  Color get _borderColor {
    if (_hovered || _pressed) return EditorialMonoclePalette.accentDim;
    return EditorialMonoclePalette.border;
  }

  Color get _glyphColor {
    if (_hovered || _pressed) return EditorialMonoclePalette.accentBright;
    return EditorialMonoclePalette.accentDim;
  }

  Color get _backgroundColor {
    if (_pressed) {
      return EditorialMonoclePalette.surfaceLite.withValues(
        alpha: _GameTopBarPauseButton._pressedBackgroundAlpha,
      );
    }
    if (_hovered) {
      return EditorialMonoclePalette.surfaceLite.withValues(
        alpha: _GameTopBarPauseButton._hoverBackgroundAlpha,
      );
    }
    return Colors.transparent;
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => _handleHover(true),
      onExit: (_) => _handleHover(false),
      child: SizedBox(
        key: GameTopBar.pauseButtonKey,
        width: GameTopBar.hamburgerSize,
        height: GameTopBar.hamburgerSize,
        child: Tooltip(
          message: widget.tooltip,
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: widget.onPressed,
              onHighlightChanged: _handlePressed,
              child: AnimatedContainer(
                duration: _GameTopBarPauseButton._animationDuration,
                curve: _GameTopBarPauseButton._animationCurve,
                decoration: BoxDecoration(
                  color: _backgroundColor,
                  border: Border.all(color: _borderColor, width: 1),
                ),
                child: Center(
                  child: Icon(
                    Icons.play_arrow,
                    size: 14,
                    color: _glyphColor,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
