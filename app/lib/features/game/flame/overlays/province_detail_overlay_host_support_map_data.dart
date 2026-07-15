part of 'province_detail_overlay_host_support.dart';

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
