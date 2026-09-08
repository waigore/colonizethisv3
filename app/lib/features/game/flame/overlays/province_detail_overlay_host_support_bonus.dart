import 'package:colonizethis_models/colonizethis_models.dart' as ct_models;

import '../../../../core/services/game_service/game_service.dart'
    show GameMapData;
import 'package:colonizethis_economy/colonizethis_economy.dart'
    show
        ProvinceImprovableCommodityCount,
        previewTownManufacturingBonusCurrentAndNextByProvince,
        projectProvinceExtraction,
        provinceImprovableResourceTileCounts;
import 'package:colonizethis_world/colonizethis_world.dart'
    show WorldStateProvinceLookup;

/// Current and next-level town-workshop bonus for one overlay rebuild.
({Map<String, int> current, Map<String, int> next})
provinceTownProductionBonusCurrentAndNext({
  required ct_models.Game game,
  required String provinceId,
  required GameMapData? mapData,
}) {
  final tileMapByRegion = mapData?.tileMapByRegion;
  if (tileMapByRegion == null || tileMapByRegion.isEmpty) {
    return (current: const <String, int>{}, next: const <String, int>{});
  }
  final pair = previewTownManufacturingBonusCurrentAndNextByProvince(
    game: game,
    topology: mapData!.combinedTopology,
    tileMapByRegion: tileMapByRegion,
  );
  return (
    current: pair.currentByProvinceId[provinceId] ?? const {},
    next: pair.nextByProvinceId[provinceId] ?? const {},
  );
}

/// Town manufacturing bonus preview for the province overlay Economic section.
Map<String, int> provinceTownProductionBonusPreview({
  required ct_models.Game game,
  required String provinceId,
  required GameMapData? mapData,
}) {
  return provinceTownProductionBonusCurrentAndNext(
    game: game,
    provinceId: provinceId,
    mapData: mapData,
  ).current;
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
