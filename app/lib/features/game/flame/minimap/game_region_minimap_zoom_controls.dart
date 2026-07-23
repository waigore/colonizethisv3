// Region minimap zoom label + [CtSlider] row.
// SPEC/ui/empire-overview.md § Region minimap.
//
// De-parted wave-9 cluster (Refs #4117).

import 'package:colonizethis_app_l10n/l10n/l10n.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:flutter/material.dart';

import '../../../../widgets/ct_slider.dart';
import '../../screens/game/game_screen_shared.dart' show kRegionMinimapZoomSliderKey;
import '../region_map/region_map_viewport_snapshot.dart'
    show kRegionMapZoomMultiplierMax, kRegionMapZoomMultiplierMin;

/// Minimap zoom label + [CtSlider] (non-Material), with local value during drag so
/// the thumb and % label track the gesture before the viewport snapshot catches up.
class MinimapZoomControls extends StatefulWidget {
  const MinimapZoomControls({
    super.key,
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
  State<MinimapZoomControls> createState() => MinimapZoomControlsState();
}

class MinimapZoomControlsState extends State<MinimapZoomControls> {
  double? _dragMultiplier;
  bool _dragging = false;

  @override
  void didUpdateWidget(covariant MinimapZoomControls oldWidget) {
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
