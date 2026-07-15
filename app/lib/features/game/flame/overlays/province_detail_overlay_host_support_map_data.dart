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
/// hosts (wide side panel and narrow bottom sheet). Refs #4035 AC3.
ProvinceDetailHostOverlayArgs resolveProvinceDetailHostOverlayArgs({
  required WidgetRef ref,
  required String gameId,
}) {
  final notifier = ref.read(mapProvincePanelProvider.notifier);
  return (
    mapData: tryGetGameMapData(
      () => ref.watch(gameServiceProvider).getMapData(gameId),
    ),
    onHighlightTile: notifier.setSecondaryHighlight,
    onHighlightTiles: notifier.setSecondaryHighlights,
    onClose: notifier.closeOverlay,
    bus: ref.read(appEventBusProvider),
  );
}
