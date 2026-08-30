import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_world/colonizethis_world.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/services/region_map/region_map_widget_bindings.dart';
import '../../../../providers/development_panel_projection_provider.dart';
import '../../../../widgets/ct_region_map.dart';

/// Pannable region map for the Development panel with multi-tile highlight.
class DevelopmentPanelMapPanel extends ConsumerStatefulWidget {
  const DevelopmentPanelMapPanel({
    super.key,
    required this.game,
    required this.humanPlayerId,
    required this.regionId,
    required this.playerView,
    this.highlightTileKeys,
    this.selectedTileKey,
  });

  final Game game;
  final String humanPlayerId;
  final String regionId;
  final PlayerView playerView;
  final Set<String>? highlightTileKeys;
  final String? selectedTileKey;

  @override
  ConsumerState<DevelopmentPanelMapPanel> createState() =>
      _DevelopmentPanelMapPanelState();
}

class _DevelopmentPanelMapPanelState
    extends ConsumerState<DevelopmentPanelMapPanel> {
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
  Widget build(BuildContext context) {
    if (!_mapReady) {
      return const SizedBox.shrink();
    }

    final snapshot = ref.watch(
      developmentPanelMapSnapshotProvider(widget.regionId),
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
      selectedTileKey: widget.selectedTileKey,
      secondaryHighlightTileKeys: widget.highlightTileKeys,
    );
  }
}
