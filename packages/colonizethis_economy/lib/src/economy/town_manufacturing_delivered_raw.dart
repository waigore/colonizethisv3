import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_world/colonizethis_world.dart';

import 'game_lookup_helpers.dart';
import 'town_connected_province_extraction.dart';

/// Town-connected **delivered** raw extraction walk for the town
/// manufacturing bonus (Refs #3872; phase-7 split Refs #4049).
/// SPEC/game/extraction-and-improvements.md § Town manufacturing bonus.
///
/// Sibling libraries own the rest of the surface:
/// `town_manufacturing_bonus_math.dart` (recipe eligibility and per-province
/// bonus math) and `town_manufacturing_bonus.dart` (game rollup, overlay
/// preview, and auto-offers bridge; also the re-export barrel).

/// Per-province town-connected **delivered** raw extraction keyed by province id.
typedef ProvinceDeliveredRawExtraction = Map<String, Map<CommodityId, int>>;

ProvinceDeliveredRawExtraction computeTownConnectedDeliveredRawByProvince({
  required Game game,
  required Map<String, TileMapResult> tileMapByRegion,
  required Map<String, ConnectivityResult> gpConnectivityByPlayerId,
  required Map<String, ConnectivityResult> nonGpConnectivityByFactionId,
  required Map<String, Set<String>> townConnectedByProvinceId,
}) {
  final provincesByFullId = buildProvinceIndex(game);
  final portTileKeys = collectPortTileKeys(game);
  final landByProvince = <String, Map<CommodityId, int>>{};
  final overseasByPlayerProvince =
      <String, Map<String, Map<CommodityId, int>>>{};
  final ctx = TownConnectedProvinceExtractionContext(
    game: game,
    tileMapByRegion: tileMapByRegion,
    provincesByFullId: provincesByFullId,
    portTileKeys: portTileKeys,
    landByProvince: landByProvince,
    overseasByPlayerProvince: overseasByPlayerProvince,
  );

  for (final province in allProvinces(game.worldState)) {
    final ownerId = province.ownerId;
    if (ownerId == null || ownerId.isEmpty) continue;
    final townConnected = townConnectedByProvinceId[province.id];
    if (townConnected == null || townConnected.isEmpty) continue;

    final player = game.playerById(ownerId);
    if (player != null) {
      accumulateGpProvinceExtraction(
        ctx: ctx,
        player: player,
        province: province,
        townConnected: townConnected,
        connectivity: gpConnectivityByPlayerId[player.id],
      );
      continue;
    }

    final connectivity = nonGpConnectivityByFactionId[ownerId];
    if (connectivity == null) continue;
    accumulateNonGpProvinceExtraction(
      ctx: ctx,
      province: province,
      townConnected: townConnected,
      connectivity: connectivity,
      ownerId: ownerId,
    );
  }

  applyOverseasCargoDeliveryToProvinces(
    game: game,
    overseasByPlayerProvince: overseasByPlayerProvince,
    landByProvince: landByProvince,
  );

  return landByProvince;
}
