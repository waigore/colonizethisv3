
import 'package:colonizethis_models/colonizethis_models.dart' as ct_models;

import '../../../../core/services/game_service/game_service.dart'
    show GameMapData;
import 'package:colonizethis_economy/colonizethis_economy.dart' show ProvinceImprovableCommodityCount, projectProvinceExtraction, provinceImprovableResourceTileCounts;
import 'package:colonizethis_turn/colonizethis_turn.dart' show previewTownManufacturingBonusByProvince;
import 'package:colonizethis_world/colonizethis_world.dart' show WorldStateProvinceLookup;

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
