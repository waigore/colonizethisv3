part of 'province_detail_overlay_host_support.dart';

/// Best-effort [GameService.getMapData] for province-detail overlay hosts.
///
/// Widget tests that mount the hosts without initializing Hive-backed
/// persistence previously each swallowed the same throw; one helper keeps that
/// contract behavior-preserving. Refs #4035 AC3.
GameMapData? tryGetGameMapData(GameMapData? Function() load) {
  try {
    return load();
  } catch (_) {
    return null;
  }
}

/// Shared map-data load + highlight/close/bus args for both province-detail
/// hosts (wide side panel and narrow bottom sheet).
///
/// Callers pass narrow deps (service, notifier, bus) from their own `build`
/// — do not thread [WidgetRef] into this helper (`repo.app_widget_ref_parameter_smell`).
/// Refs #4035 AC3.
ProvinceDetailHostOverlayArgs resolveProvinceDetailHostOverlayArgs({
  required GameService gameService,
  required String gameId,
  required MapProvincePanelNotifier panelNotifier,
  required ct_models.AppEventBus bus,
}) {
  return (
    mapData: tryGetGameMapData(() => gameService.getMapData(gameId)),
    onHighlightTile: panelNotifier.setSecondaryHighlight,
    onHighlightTiles: panelNotifier.setSecondaryHighlights,
    onClose: panelNotifier.closeOverlay,
    bus: bus,
  );
}
