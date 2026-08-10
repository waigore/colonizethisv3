import 'package:colonizethis_map/colonizethis_map.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_world/colonizethis_world.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/services/region_map/region_map_widget_bindings.dart';
import '../../../../providers/game_service_provider.dart';
import '../../../../widgets/ct_region_map.dart';
import 'development_panel_map_visibility.dart';

/// Pannable region map for the Development panel with multi-tile highlight.
class DevelopmentPanelMapPanel extends ConsumerWidget {
  const DevelopmentPanelMapPanel({
    super.key,
    required this.game,
    required this.humanPlayerId,
    required this.regionId,
    required this.playerView,
    this.highlightTileKeys,
  });

  final Game game;
  final String humanPlayerId;
  final String regionId;
  final PlayerView playerView;
  final Set<String>? highlightTileKeys;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mapData = ref.read(gameServiceProvider).getMapData(game.id);
    if (mapData == null) {
      return const SizedBox.shrink();
    }

    final visibilityByTile = developmentPanelVisibilityByTile(
      game: game,
      playerView: playerView,
    );
    final region = buildInitGameMapRegionViewData(
      regionId: regionId,
      game: game,
      tileMapByRegion: mapData.tileMapByRegion,
      topologyByRegion: mapData.topologyByRegion,
      cellSize: 12,
      visibilityByTile: visibilityByTile,
    );
    final playerTerritoryTileKeys = developmentPanelPlayerTerritoryTileKeys(
      game: game,
      playerId: humanPlayerId,
      regionId: regionId,
      tileMapByRegion: mapData.tileMapByRegion,
    );

    return CtRegionMap(
      region: region,
      showPoliticalOverlay: false,
      showProvinceOverlay: true,
      showProvinceNamesLayer: false,
      cellSizePx: 12,
      visibilityMode: CtMapVisibilityMode.playerConstrained,
      playerViewForResources: playerView,
      showPlayerTerritoryOutline: true,
      playerTerritoryTileKeys: playerTerritoryTileKeys,
      secondaryHighlightTileKeys: highlightTileKeys,
    );
  }
}
