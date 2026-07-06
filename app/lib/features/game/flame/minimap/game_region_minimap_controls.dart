part of 'game_region_minimap.dart';

/// Minimap zoom label + [CtSlider] (non-Material), with local value during drag so
/// the thumb and % label track the gesture before the viewport snapshot catches up.
class _MinimapZoomControls extends StatefulWidget {
  const _MinimapZoomControls({
    required this.regionId,
    required this.bus,
    required this.viewportMultiplier,
    required this.trackWidth,
    required this.theme,
    required this.trailing,
  });

  final String regionId;
  final AppEventBus bus;
  final double viewportMultiplier;
  final double trackWidth;
  final ThemeData theme;
  final Widget trailing;

  @override
  State<_MinimapZoomControls> createState() => _MinimapZoomControlsState();
}

class _MinimapZoomControlsState extends State<_MinimapZoomControls> {
  double? _dragMultiplier;
  bool _dragging = false;

  @override
  void didUpdateWidget(covariant _MinimapZoomControls oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.regionId != widget.regionId) {
      _dragMultiplier = null;
      _dragging = false;
    }
  }

  double get _displayMultiplier {
    final v = _dragMultiplier ?? widget.viewportMultiplier;
    return v.clamp(kRegionMapZoomMultiplierMin, kRegionMapZoomMultiplierMax);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = appL10n(context);
    final pct = (_displayMultiplier * 100).round();
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        SizedBox(
          width: widget.trackWidth,
          child: Text(
            l10n.common_percent(pct),
            textAlign: TextAlign.center,
            style: widget.theme.textTheme.labelSmall,
          ),
        ),
        const SizedBox(height: 2),
        SizedBox(
          width: widget.trackWidth,
          height: 48,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Semantics(
                  label: l10n.regionMinimap_mapZoom,
                  value: l10n.regionMinimap_zoomSemanticsValue(pct),
                  slider: true,
                  child: Tooltip(
                    message: l10n.regionMinimap_mapZoom,
                    child: Center(
                      child: CtSlider(
                        key: kRegionMinimapZoomSliderKey,
                        value: _displayMultiplier,
                        min: kRegionMapZoomMultiplierMin,
                        max: kRegionMapZoomMultiplierMax,
                        divisions: 0,
                        onDragStart: () {
                          setState(() => _dragging = true);
                        },
                        onChanged: (v) {
                          widget.bus.emit(
                            RequestRegionMapSetZoomMultiplierEvent(
                              regionId: widget.regionId,
                              zoomMultiplier: v,
                            ),
                          );
                          if (_dragging) {
                            setState(() => _dragMultiplier = v);
                          }
                        },
                        onDragEnd: () {
                          setState(() {
                            _dragging = false;
                            _dragMultiplier = null;
                          });
                        },
                      ),
                    ),
                  ),
                ),
              ),
              widget.trailing,
            ],
          ),
        ),
      ],
    );
  }
}

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
