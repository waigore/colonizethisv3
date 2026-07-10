part of 'game_region_minimap.dart';

/// Dark editorial-monocle 32 × 32 dp show/hide toggle for the region minimap.
///
/// Mirrors mockup `.minimap-toggle`
/// (`SPEC/ui/mockups/GAME10001-game-screen.html`) and the
/// [GameMapCornerControls](../controls/game_map_corner_controls.dart) chrome family
/// per `SPEC/ui/empire-overview.md` § Region minimap chrome
/// (dark editorial-monocle): a flat `--bg-deep` surface with a 1 px
/// `--border` outline, centered glyph tinted via `ColorFiltered(srcIn)`
/// to `--accent-dim` (default) → `--accent-bright` (hover / pressed),
/// outline shifting to `--accent-dim` on the same hover / pressed
/// transition over `120 ms` (`Curves.easeOut`).
class _MinimapToggleButton extends StatefulWidget {
  const _MinimapToggleButton({required this.visible, required this.onTap});

  final bool visible;
  final VoidCallback onTap;

  /// Side length of the toggle tap target. Matches the corner-controls
  /// 32 dp tap target convention referenced by SPEC `Region minimap`:
  /// "same padding/hit target pattern as corner controls".
  static const double buttonSize = 32;

  /// Side length of the centered glyph. Preserves the existing 20 dp
  /// minimap icon so the visible silhouette inside the dark surface is
  /// unchanged from the legacy white-Material chrome.
  static const double iconSize = 20;

  /// Hover/press transition duration. Matches
  /// [GameMapCornerControls](../controls/game_map_corner_controls.dart) so the row
  /// of map chrome reads as one editorial-monocle family.
  static const Duration animationDuration = Duration(milliseconds: 120);
  static const Curve animationCurve = Curves.easeOut;

  @override
  State<_MinimapToggleButton> createState() => _MinimapToggleButtonState();
}

class _MinimapToggleButtonState extends State<_MinimapToggleButton> {
  bool _hovered = false;
  bool _pressed = false;

  void _setHovered(bool value) {
    if (_hovered == value) return;
    setState(() => _hovered = value);
  }

  void _setPressed(bool value) {
    if (_pressed == value) return;
    setState(() => _pressed = value);
  }

  Color get _borderColor => (_hovered || _pressed)
      ? EditorialMonoclePalette.accentDim
      : EditorialMonoclePalette.border;

  Color get _iconColor => (_hovered || _pressed)
      ? EditorialMonoclePalette.accentBright
      : EditorialMonoclePalette.accentDim;

  @override
  Widget build(BuildContext context) {
    final tooltip = widget.visible
        ? 'Hide region minimap'
        : 'Show region minimap';
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => _setHovered(true),
      onExit: (_) => _setHovered(false),
      child: Tooltip(
        message: tooltip,
        child: Semantics(
          button: true,
          label: tooltip,
          child: SizedBox(
            key: kRegionMinimapToggleKey,
            width: _MinimapToggleButton.buttonSize,
            height: _MinimapToggleButton.buttonSize,
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: widget.onTap,
                onHighlightChanged: _setPressed,
                child: AnimatedContainer(
                  duration: _MinimapToggleButton.animationDuration,
                  curve: _MinimapToggleButton.animationCurve,
                  decoration: BoxDecoration(
                    color: EditorialMonoclePalette.bgDeep,
                    border: Border.all(color: _borderColor, width: 1),
                  ),
                  child: Center(
                    child: ColorFiltered(
                      colorFilter: ColorFilter.mode(
                        _iconColor,
                        BlendMode.srcIn,
                      ),
                      child: StrictAssetIcon(
                        assetPath:
                            '${kAppIconAssetPrefix}ui_icon_region_minimap.png',
                        width: _MinimapToggleButton.iconSize,
                        height: _MinimapToggleButton.iconSize,
                      ),
                    ),
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
