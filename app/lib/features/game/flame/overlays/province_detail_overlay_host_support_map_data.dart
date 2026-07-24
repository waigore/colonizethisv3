import 'package:colonizethis_models/colonizethis_models.dart' as ct_models;
import 'package:flutter/widgets.dart';

import '../../../../core/services/game_service/game_service.dart'
    show GameMapData;
import '../../../../core/services/game_service/try_get_game_map_data.dart'
    show tryGetGameMapData;
import '../../../../providers/map_province_panel_provider.dart'
    show MapProvincePanelNotifier;

/// Shared map-data + secondary-highlight / close wiring for wide and narrow
/// province-detail overlay hosts (Refs #4035 AC3).
typedef ProvinceDetailHostOverlayArgs = ({
  GameMapData? mapData,
  void Function(String?) onHighlightTile,
  void Function(Iterable<String>?) onHighlightTiles,
  VoidCallback onClose,
  ct_models.AppEventBus bus,
});

/// Shared map-data load + highlight/close/bus args for both province-detail
/// hosts (wide side panel and narrow bottom sheet).
///
/// [loadMapData] is invoked inside [tryGetGameMapData] so Hive-backed
/// `gameServiceProvider` / `getMapData` failures stay swallowed for widget
/// hosts that mount without persistence (behavior-preserving vs pre-AC3).
/// Callers pass narrow deps (notifier, bus) from their own `build` — do not
/// thread [WidgetRef] into this helper (`repo.app_widget_ref_parameter_smell`).
/// Refs #4035 AC3.
ProvinceDetailHostOverlayArgs resolveProvinceDetailHostOverlayArgs({
  required GameMapData? Function() loadMapData,
  required MapProvincePanelNotifier panelNotifier,
  required ct_models.AppEventBus bus,
}) {
  return (
    mapData: tryGetGameMapData(loadMapData),
    onHighlightTile: panelNotifier.setSecondaryHighlight,
    onHighlightTiles: panelNotifier.setSecondaryHighlights,
    onClose: panelNotifier.closeOverlay,
    bus: bus,
  );
}
