/// Display-only transport-step payoff gist. Refs #4663.
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

/// Localized gist for a [TransportStepYieldPreview].
String transportStepYieldGistLine({
  required AppLocalizations l10n,
  required TransportStepYieldPreview preview,
}) {
  switch (preview.kind) {
    case TransportStepYieldKind.raise:
      final good = commodityDisplayName(l10n, preview.commodityId!);
      return l10n.provinceOverlay_tileTransportStepYieldRaise(
        preview.currentEffective,
        preview.nextEffective,
        good,
      );
    case TransportStepYieldKind.roadPathLimit:
      final good = commodityDisplayName(l10n, preview.commodityId!);
      return l10n.provinceOverlay_tileTransportStepYieldRoadLimit(
        preview.nextEffective,
        good,
      );
    case TransportStepYieldKind.townDevelopmentLimit:
      final good = commodityDisplayName(l10n, preview.commodityId!);
      return l10n.provinceOverlay_tileTransportStepYieldTownLimit(
        preview.nextEffective,
        good,
      );
    case TransportStepYieldKind.disconnected:
      return l10n.provinceOverlay_tileTransportStepYieldDisconnected;
    case TransportStepYieldKind.bindsToCapital:
      return l10n.provinceOverlay_tileTransportStepYieldBindsCapital;
    case TransportStepYieldKind.portOnCoast:
      return l10n.provinceOverlay_tileTransportStepPortOnCoast;
  }
}

bool _playerHasRoadConstruction(Player player) {
  return player.techUnlocked?[kTechIdRoadConstruction] == true;
}

TransportStepYieldPreview? _transportStepPreviewForTile({
  required Game game,
  required String humanPlayerId,
  required String tileKey,
  required String workTarget,
  GameMapData? mapData,
}) {
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
  return computeTransportStepYieldPreview(
    game: game,
    tileMapByRegion: tileMapByRegion,
    tileKey: tileKey,
    workTarget: workTarget,
    connectedTileKeys: cr.connected,
    pathTransportCap: cr.pathTransportCap,
    connectedByRoadRule: cr.connectedByRoadRule,
    portTileKeys: collectPortTileKeys(game),
    capitalProvinceId: player.capitalProvinceId,
    provincesByFullId: buildProvinceIndex(game),
    hasRoadConstructionTech: _playerHasRoadConstruction(player),
    techCapForCommodity: (commodityId) =>
        extractionCapForResourceForUnlocked(player.techUnlocked, commodityId),
    isCommodityExtractable: (key, commodityId) =>
        !kProspectRequiredResourceIds.contains(commodityId) ||
        prospected.contains(key),
  );
}

/// Resolves gist when a transport work step is enabled for a human-owned tile.
String? transportStepYieldGistForTile({
  required AppLocalizations l10n,
  required Game game,
  required String humanPlayerId,
  required String tileKey,
  required String workTarget,
  required bool enabled,
  GameMapData? mapData,
  bool canMutateViaUi = true,
}) {
  if (!enabled || !canMutateViaUi) return null;
  final preview = _transportStepPreviewForTile(
    game: game,
    humanPlayerId: humanPlayerId,
    tileKey: tileKey,
    workTarget: workTarget,
    mapData: mapData,
  );
  if (preview == null) return null;
  return transportStepYieldGistLine(l10n: l10n, preview: preview);
}
