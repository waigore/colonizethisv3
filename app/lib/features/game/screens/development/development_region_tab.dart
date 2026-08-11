import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_economy/colonizethis_economy.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_orders/colonizethis_orders.dart'
    show
        DevelopmentAssignRowState,
        DevelopmentImproveAssignCandidate,
        resolveDevelopmentAssignRowState;
import 'package:colonizethis_world/colonizethis_world.dart' show PlayerView;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

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

  DevelopmentAssignRowState _assignRowStateFor(
    String commodityId,
    Set<String> tileKeys,
  ) {
    if (!widget.canEdit) {
      return const DevelopmentAssignRowState(
        enabled: false,
        disabledReason: 'Orders are read-only',
      );
    }
    return resolveDevelopmentAssignRowState(
      game: widget.game,
      playerId: widget.humanPlayerId,
      currentOrders: widget.currentOrders,
      topology: widget.topology,
      tileMapByRegion: widget.tileMapByRegion,
      commodityTileKeys: tileKeys,
      connectedTileKeys: widget.connectedTileKeys,
    );
  }

  @override
  Widget build(BuildContext context) {
    final wide = MediaQuery.sizeOf(context).width >= kNarrowBreakpoint;
    final materialShortages = ref.watch(
      developmentPanelMaterialShortageProvider(widget.regionId),
    );
    final list = DevelopmentPanelScopeList(
      key: DevelopmentPanelKeys.scopeListKey,
      regionModel: widget.regionModel,
      onShowTiles: (keys) => setState(() {
        _highlightTileKeys = Set<String>.from(keys);
      }),
      assignRowStateFor: _assignRowStateFor,
      onAssign: widget.onAssign,
    );
    final mapPanel = DevelopmentPanelMapPanel(
      key: DevelopmentPanelKeys.panelMapKeyForRegion(widget.regionId),
      game: widget.game,
      humanPlayerId: widget.humanPlayerId,
      regionId: widget.regionId,
      playerView: widget.playerView,
      highlightTileKeys: _highlightTileKeys,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        DevelopmentPanelOverview(
          key: DevelopmentPanelKeys.overviewKey,
          regionModel: widget.regionModel,
          materialShortageCommodityIds: materialShortages,
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
