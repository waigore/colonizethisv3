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
