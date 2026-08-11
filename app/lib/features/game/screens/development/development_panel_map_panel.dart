import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_world/colonizethis_world.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/services/region_map/region_map_widget_bindings.dart';
import '../../../../providers/game_service_provider.dart';
import '../../../../widgets/ct_region_map.dart';
import 'development_panel_map_snapshot.dart';

/// Pannable region map for the Development panel with multi-tile highlight.
class DevelopmentPanelMapPanel extends ConsumerStatefulWidget {
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
  ConsumerState<DevelopmentPanelMapPanel> createState() =>
      _DevelopmentPanelMapPanelState();
}

class _DevelopmentPanelMapPanelState
    extends ConsumerState<DevelopmentPanelMapPanel> {
  Object? _snapshotCacheKey;
  DevelopmentPanelMapSnapshot? _snapshot;
  bool _mapReady = false;

  @override
  void initState() {
    super.initState();
    SchedulerBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      setState(() => _mapReady = true);
    });
  }

  @override
  void didUpdateWidget(covariant DevelopmentPanelMapPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    final cacheKey = developmentPanelMapSnapshotCacheKey(
      game: widget.game,
      humanPlayerId: widget.humanPlayerId,
      regionId: widget.regionId,
      playerView: widget.playerView,
    );
    if (cacheKey != _snapshotCacheKey) {
      _snapshotCacheKey = null;
      _snapshot = null;
    }
  }

  DevelopmentPanelMapSnapshot? _resolveSnapshot(
    Map<String, TileMapResult> tileMapByRegion,
    Map<String, MapTopology> topologyByRegion,
  ) {
    final cacheKey = developmentPanelMapSnapshotCacheKey(
      game: widget.game,
      humanPlayerId: widget.humanPlayerId,
      regionId: widget.regionId,
      playerView: widget.playerView,
    );
    if (_snapshotCacheKey == cacheKey && _snapshot != null) {
      return _snapshot;
    }
    _snapshotCacheKey = cacheKey;
    _snapshot = buildDevelopmentPanelMapSnapshot(
      game: widget.game,
      humanPlayerId: widget.humanPlayerId,
      regionId: widget.regionId,
      playerView: widget.playerView,
      tileMapByRegion: tileMapByRegion,
      topologyByRegion: topologyByRegion,
    );
    return _snapshot;
  }

  @override
  Widget build(BuildContext context) {
    if (!_mapReady) {
      return const SizedBox.shrink();
    }

    final mapData = ref.read(gameServiceProvider).getMapData(widget.game.id);
    if (mapData == null) {
      return const SizedBox.shrink();
    }

    final snapshot = _resolveSnapshot(
      mapData.tileMapByRegion,
      mapData.topologyByRegion,
    );
    if (snapshot == null) {
      return const SizedBox.shrink();
    }

    return CtRegionMap(
      region: snapshot.region,
      showPoliticalOverlay: false,
      showProvinceOverlay: true,
      showProvinceNamesLayer: false,
      cellSizePx: 12,
      visibilityMode: CtMapVisibilityMode.playerConstrained,
      playerViewForResources: widget.playerView,
      showPlayerTerritoryOutline: true,
      playerTerritoryTileKeys: snapshot.playerTerritoryTileKeys,
      secondaryHighlightTileKeys: widget.highlightTileKeys,
    );
  }
}
