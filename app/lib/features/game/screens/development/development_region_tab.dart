import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_economy/colonizethis_economy.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_orders/colonizethis_orders.dart'
    show
        DevelopmentAssignRowState,
        DevelopmentImproveAssignCandidate,
        developmentPanelMaterialShortageCommodityIds;
import 'package:colonizethis_world/colonizethis_world.dart' show PlayerView;
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:colonizethis_app/features/game/widgets/units/civilian/build_improvement_next_yield_copy.dart';
import 'package:colonizethis_app_l10n/l10n/l10n.dart';
import '../../../../config/constants.dart';
import '../../../../providers/development_panel_projection_provider.dart';
import '../../../../widgets/ct_spacing.dart';
import 'development_panel_keys.dart';
import 'development_panel_map_panel.dart';
import 'development_panel_overview.dart';
import 'development_panel_scope_list.dart';

/// One region tab: overview, scope list, and panel map.
class DevelopmentRegionTab extends ConsumerStatefulWidget {
  const DevelopmentRegionTab({
    super.key,
    required this.game,
    required this.humanPlayerId,
    required this.regionId,
    required this.regionModel,
    required this.playerView,
    required this.topology,
    required this.tileMapByRegion,
    required this.currentOrders,
    required this.connectedTileKeys,
    required this.provinceDisplayNamesById,
    required this.canEdit,
    required this.onAssign,
  });

  final Game game;
  final String humanPlayerId;
  final String regionId;
  final DevelopmentPanelRegionModel regionModel;
  final PlayerView playerView;
  final MapTopology topology;
  final Map<String, TileMapResult> tileMapByRegion;
  final Orders currentOrders;
  final Set<String> connectedTileKeys;
  final Map<String, String> provinceDisplayNamesById;
  final bool canEdit;
  final void Function(DevelopmentImproveAssignCandidate candidate) onAssign;

  @override
  ConsumerState<DevelopmentRegionTab> createState() =>
      _DevelopmentRegionTabState();
}

class _DevelopmentRegionTabState extends ConsumerState<DevelopmentRegionTab> {
  Set<String>? _highlightTileKeys;
  String? _selectedHighlightTileKey;
  Set<String> _materialShortageCommodityIds = const {};
  Object? _shortageScanKey;

  @override
  void initState() {
    super.initState();
    _scheduleMaterialShortageScan();
  }

  @override
  void didUpdateWidget(covariant DevelopmentRegionTab oldWidget) {
    super.didUpdateWidget(oldWidget);
    final scanKey = (
      widget.regionId,
      widget.game,
      widget.currentOrders,
      widget.regionModel,
      widget.connectedTileKeys,
    );
    if (_shortageScanKey != scanKey) {
      _scheduleMaterialShortageScan();
    }
  }

  void _scheduleMaterialShortageScan() {
    _shortageScanKey = (
      widget.regionId,
      widget.game,
      widget.currentOrders,
      widget.regionModel,
      widget.connectedTileKeys,
    );
    SchedulerBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final shortages = developmentPanelMaterialShortageCommodityIds(
        game: widget.game,
        playerId: widget.humanPlayerId,
        currentOrders: widget.currentOrders,
        topology: widget.topology,
        tileMapByRegion: widget.tileMapByRegion,
        improvableRows: _improvableRowsForShortageScan(),
        connectedTileKeys: widget.connectedTileKeys,
      );
      if (!mounted) return;
      setState(() => _materialShortageCommodityIds = shortages);
    });
  }

  Iterable<({String commodityId, Set<String> tileKeys})>
  _improvableRowsForShortageScan() sync* {
    for (final scope in [
      ...widget.regionModel.ownedScopes,
      ...widget.regionModel.purchasedScopes,
    ]) {
      for (final row in scope.improvableCommodities) {
        yield (commodityId: row.commodityId, tileKeys: row.tileKeys.toSet());
      }
    }
  }

  DevelopmentAssignRowState _assignRowStateFor(
    String scopeKey,
    String commodityId,
  ) {
    if (!widget.canEdit) {
      return const DevelopmentAssignRowState(
        enabled: false,
        disabledReason: 'Orders are read-only',
      );
    }
    final cache = ref.read(
      developmentPanelAssignRowStateCacheProvider(widget.regionId),
    );
    return cache.rowStateFor(scopeKey, commodityId);
  }

  @override
  Widget build(BuildContext context) {
    final wide = MediaQuery.sizeOf(context).width >= kNarrowBreakpoint;
    ref.watch(developmentPanelAssignRowStateCacheProvider(widget.regionId));
    final list = DevelopmentPanelScopeList(
      key: DevelopmentPanelKeys.scopeListKey,
      regionModel: widget.regionModel,
      onShowTiles: (keys, {selectedTileKey}) => setState(() {
        _highlightTileKeys = Set<String>.from(keys);
        _selectedHighlightTileKey = selectedTileKey;
      }),
      assignRowStateFor: _assignRowStateFor,
      onAssign: widget.onAssign,
      provinceDisplayNamesById: widget.provinceDisplayNamesById,
      nextYieldGistForTile: (tileKey) => buildImprovementNextYieldGistForTile(
        l10n: appL10n(context),
        game: widget.game,
        humanPlayerId: widget.humanPlayerId,
        tileKey: tileKey,
        enabled: widget.canEdit,
        mapData: (
          combinedTopology: widget.topology,
          tileMapByRegion: widget.tileMapByRegion,
          topologyByRegion: const {},
          warpLinks: null,
        ),
      ),
    );
    final mapPanel = DevelopmentPanelMapPanel(
      key: DevelopmentPanelKeys.panelMapKeyForRegion(widget.regionId),
      game: widget.game,
      humanPlayerId: widget.humanPlayerId,
      regionId: widget.regionId,
      playerView: widget.playerView,
      highlightTileKeys: _highlightTileKeys,
      selectedTileKey: _selectedHighlightTileKey,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        DevelopmentPanelOverview(
          key: DevelopmentPanelKeys.overviewKey,
          regionModel: widget.regionModel,
          materialShortageCommodityIds: _materialShortageCommodityIds,
          provinceDisplayNamesById: widget.provinceDisplayNamesById,
          game: widget.game,
          humanPlayerId: widget.humanPlayerId,
          currentOrders: widget.currentOrders,
        ),
        const SizedBox(height: CtSpacing.m),
        Expanded(
          child: wide
              ? Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(child: list),
                    const SizedBox(width: CtSpacing.m),
                    Expanded(child: mapPanel),
                  ],
                )
              : Column(
                  children: [
                    Expanded(child: list),
                    const SizedBox(height: CtSpacing.m),
                    SizedBox(height: 240, child: mapPanel),
                  ],
                ),
        ),
      ],
    );
  }
}
