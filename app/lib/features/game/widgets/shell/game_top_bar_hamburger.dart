part of 'game_top_bar.dart';

/// 28 x 28 hamburger tap target painted in the dark editorial-monocle
/// theme. Mirrors the hover / pressed pattern used by [CtBackButton]:
///
/// - default: no background, glyph tinted `--accent-dim`,
/// - hover:   `--surface-lite` panel at 40 % alpha, glyph `--accent`,
/// - pressed: `--surface-lite` panel at 60 % alpha, glyph `--accent-bright`.
///
/// Wrapped in [MouseRegion] for cursor feedback and a [Material] / [InkWell]
/// for accurate hit-testing inside the top bar.
class _GameTopBarHamburger extends StatefulWidget {
  const _GameTopBarHamburger({required this.onPressed, required this.tooltip});

  final VoidCallback onPressed;
  final String tooltip;

  static const double _hoverBackgroundAlpha = 0.4;
  static const double _pressedBackgroundAlpha = 0.6;
  static const Duration _animationDuration = Duration(milliseconds: 120);
  static const Curve _animationCurve = Curves.easeOut;

  @override
  State<_GameTopBarHamburger> createState() => _GameTopBarHamburgerState();
}

class _GameTopBarHamburgerState extends State<_GameTopBarHamburger> {
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

  Color get _backgroundColor {
    if (_pressed) {
      return EditorialMonoclePalette.surfaceLite.withValues(
        alpha: _GameTopBarHamburger._pressedBackgroundAlpha,
      );
    }
    if (_hovered) {
      return EditorialMonoclePalette.surfaceLite.withValues(
        alpha: _GameTopBarHamburger._hoverBackgroundAlpha,
      );
    }
    return EditorialMonoclePalette.surfaceLite.withValues(alpha: 0);
  }

  Color get _glyphColor {
    if (_pressed) return EditorialMonoclePalette.accentBright;
    if (_hovered) return EditorialMonoclePalette.accent;
    return EditorialMonoclePalette.accentDim;
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => _handleHover(true),
      onExit: (_) => _handleHover(false),
      child: SizedBox(
        key: GameTopBar.hamburgerKey,
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
                duration: _GameTopBarHamburger._animationDuration,
                curve: _GameTopBarHamburger._animationCurve,
                color: _backgroundColor,
                child: Center(
                  child: Icon(
                    Icons.menu,
                    size: GameTopBar.hamburgerGlyphSize,
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
