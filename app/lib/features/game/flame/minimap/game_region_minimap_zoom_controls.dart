import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:flutter/material.dart';

import 'package:colonizethis_app_l10n/l10n/l10n.dart';
import '../../../../config/app_assets.dart';
import 'package:colonizethis_app_ui_chrome/config/editorial_monocle_palette.dart';
import '../../../../widgets/ct_slider.dart';
import '../../../../widgets/strict_asset_icon.dart';
import '../region_map/region_map_viewport_snapshot.dart'
    show kRegionMapZoomMultiplierMax, kRegionMapZoomMultiplierMin;
import '../../screens/game/game_screen_shared.dart';

/// Minimap zoom label + [CtSlider] and dark editorial-monocle toggle chrome.
class GameRegionMinimapZoomControls extends StatefulWidget {
  const GameRegionMinimapZoomControls({
    required this.regionId,
    required this.bus,
    required this.viewportMultiplier,
    required this.trackWidth,
    required this.theme,
    required this.visible,
    required this.onToggle,
  });

  final String regionId;
  final AppEventBus bus;
  final double viewportMultiplier;
  final double trackWidth;
  final ThemeData theme;
  final bool visible;
  final VoidCallback onToggle;

  @override
  State<GameRegionMinimapZoomControls> createState() =>
      _GameRegionMinimapZoomControlsState();
}

class _GameRegionMinimapZoomControlsState
    extends State<GameRegionMinimapZoomControls> {
  double? _dragMultiplier;
  bool _dragging = false;

  @override
  void didUpdateWidget(covariant GameRegionMinimapZoomControls oldWidget) {
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
              _MinimapToggleButton(
                visible: widget.visible,
                onTap: widget.onToggle,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _MinimapToggleButton extends StatefulWidget {
  const _MinimapToggleButton({required this.visible, required this.onTap});

  final bool visible;
  final VoidCallback onTap;

  static const double buttonSize = 32;
  static const double iconSize = 20;
  static const Duration animationDuration = Duration(milliseconds: 120);
  static const Curve animationCurve = Curves.easeOut;

  @override
  State<_MinimapToggleButton> createState() => _MinimapToggleButtonState();
}

class _MinimapToggleButtonState extends State<_MinimapToggleButton> {
  bool _hovered = false;
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final tooltip = widget.visible
        ? 'Hide region minimap'
        : 'Show region minimap';
    final borderColor = (_hovered || _pressed)
        ? EditorialMonoclePalette.accentDim
        : EditorialMonoclePalette.border;
    final iconColor = (_hovered || _pressed)
        ? EditorialMonoclePalette.accentBright
        : EditorialMonoclePalette.accentDim;
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
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
                onHighlightChanged: (v) => setState(() => _pressed = v),
                child: AnimatedContainer(
                  duration: _MinimapToggleButton.animationDuration,
                  curve: _MinimapToggleButton.animationCurve,
                  decoration: BoxDecoration(
                    color: EditorialMonoclePalette.bgDeep,
                    border: Border.all(color: borderColor, width: 1),
                  ),
                  child: Center(
                    child: ColorFiltered(
                      colorFilter: ColorFilter.mode(
                        iconColor,
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
