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

/// Post-resolution Extraction projection for [provinceId] (Refs #4064).
ct_models.ProvinceExtractionSnapshot? provinceExtractionSnapshotPreview({
  required ct_models.Game game,
  required String provinceId,
  required GameMapData? mapData,
}) {
  final tileMapByRegion = mapData?.tileMapByRegion;
  if (tileMapByRegion == null || tileMapByRegion.isEmpty) {
    return null;
  }
  return projectProvinceExtraction(
    game: game,
    tileMapByRegion: tileMapByRegion,
    topology: mapData!.combinedTopology,
    provinceId: provinceId,
  );
}

/// Available improvable resource tile counts for [provinceId].
Map<String, ProvinceImprovableCommodityCount>
provinceAvailableResourceCountsPreview({
  required ct_models.Game game,
  required String provinceId,
  required GameMapData? mapData,
}) {
  final tileMapByRegion = mapData?.tileMapByRegion;
  if (tileMapByRegion == null || tileMapByRegion.isEmpty) {
    return const {};
  }
  final province = game.worldState.tryGetProvince(provinceId);
  final ownerId = province?.ownerId;
  if (ownerId == null || ownerId.isEmpty) {
    return const {};
  }
  return provinceImprovableResourceTileCounts(
    game: game,
    provinceId: provinceId,
    ownerId: ownerId,
    tileMapByRegion: tileMapByRegion,
  );
}
