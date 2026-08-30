/// Display-only Build improvement next-yield gist. Refs #4627.
library;

import 'package:colonizethis_app/core/services/game_service/game_service.dart'
    show GameMapData;
import 'package:colonizethis_app/features/game/flame/overlays/province_detail_overlay_host_support_tile_connectivity.dart'
    show humanConnectivityPreview;
import 'package:colonizethis_app/widgets/commodity_display_name.dart';
import 'package:colonizethis_app_l10n/l10n/l10n.dart';
import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_economy/colonizethis_economy.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_world/colonizethis_world.dart';

/// Localized gist for a [BuildImprovementYieldPreview].
String buildImprovementNextYieldGistLine({
  required AppLocalizations l10n,
  required BuildImprovementYieldPreview preview,
}) {
  final good = commodityDisplayName(l10n, preview.commodityId);
  switch (preview.kind) {
    case BuildImprovementYieldKind.raise:
      return l10n.provinceOverlay_tileBuildImprovementYieldRaise(
        preview.currentEffective,
        preview.nextEffective,
        good,
      );
    case BuildImprovementYieldKind.roadPathLimit:
      return l10n.provinceOverlay_tileBuildImprovementYieldRoadLimit(
        preview.nextEffective,
        good,
      );
    case BuildImprovementYieldKind.townDevelopmentLimit:
      return l10n.provinceOverlay_tileBuildImprovementYieldTownLimit(
        preview.nextEffective,
        good,
      );
    case BuildImprovementYieldKind.disconnected:
      return l10n.provinceOverlay_tileBuildImprovementYieldDisconnected;
  }
}

/// Resolves gist when Build improvement is enabled for a human-owned tile.
String? buildImprovementNextYieldGistForTile({
  required AppLocalizations l10n,
  required Game game,
  required String humanPlayerId,
  required String tileKey,
  required bool enabled,
  GameMapData? mapData,
  bool canMutateViaUi = true,
}) {
  if (!enabled || !canMutateViaUi) return null;
  final provinceId = Unit.provinceIdFromTileKey(tileKey);
  if (provinceId == null) return null;
  final province = game.worldState.tryGetProvince(provinceId);
  if (province?.ownerId != humanPlayerId) return null;
  final player = game.playerById(humanPlayerId);
  if (player == null) return null;
  final tileMapByRegion = mapData?.tileMapByRegion;
  if (tileMapByRegion == null || tileMapByRegion.isEmpty) return null;
  final cr = humanConnectivityPreview(
    game: game,
    humanPlayerId: humanPlayerId,
    mapData: mapData,
  );
  if (cr == null) return null;
  final prospected =
      game.worldState.playerProspectedTiles[humanPlayerId] ?? const <String>{};
  final preview = computeBuildImprovementYieldPreview(
    game: game,
    tileMapByRegion: tileMapByRegion,
    tileKey: tileKey,
    connectedTileKeys: cr.connected,
    pathTransportCap: cr.pathTransportCap,
    connectedByRoadRule: cr.connectedByRoadRule,
    portTileKeys: collectPortTileKeys(game),
    capitalProvinceId: player.capitalProvinceId,
    provincesByFullId: buildProvinceIndex(game),
    techCapForCommodity: (commodityId) =>
        extractionCapForResourceForUnlocked(player.techUnlocked, commodityId),
    isCommodityExtractable: (key, commodityId) =>
        !kProspectRequiredResourceIds.contains(commodityId) ||
        prospected.contains(key),
  );
  if (preview == null) return null;
  return buildImprovementNextYieldGistLine(l10n: l10n, preview: preview);
}
