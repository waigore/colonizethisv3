part of 'province_detail_overlay_host_support.dart';

/// Town manufacturing bonus preview for the province overlay Economic section.
///
/// Returns an empty map when map data is unavailable or tile maps are empty.
Map<String, int> provinceTownProductionBonusPreview({
  required ct_models.Game game,
  required String provinceId,
  required GameMapData? mapData,
}) {
  final tileMapByRegion = mapData?.tileMapByRegion;
  if (tileMapByRegion == null || tileMapByRegion.isEmpty) {
    return const {};
  }
  final byProvince = previewTownManufacturingBonusByProvince(
    game: game,
    topology: mapData!.combinedTopology,
    tileMapByRegion: tileMapByRegion,
  );
  return byProvince[provinceId] ?? const {};
}
