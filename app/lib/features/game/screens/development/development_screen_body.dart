import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../config/constants.dart';
import '../../../../providers/game_service_provider.dart';
import '../../../../providers/games_provider.dart';
import '../../../../widgets/ct_panel.dart';
import '../../../../widgets/ct_spacing.dart';
import '../../../../widgets/ct_tab_strip.dart';
import 'development_panel_keys.dart';
import 'development_panel_map_panel.dart';
import 'development_panel_overview.dart';
import 'development_panel_scope_list.dart';

/// Body for [DevelopmentScreen]: region tabs, overview, list + map.
class DevelopmentScreenBody extends ConsumerWidget {
  const DevelopmentScreenBody({
    super.key,
    required this.game,
    required this.humanPlayerId,
  });

  final Game game;
  final String humanPlayerId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mapData = ref.read(gameServiceProvider).getMapData(game.id);
    if (mapData == null) {
      return const Center(child: Text('Map data unavailable'));
    }

    final orders = ref.watch(currentOrdersProvider);
    final provinceNames = <String, String>{};
    for (final province in game.worldState.allProvinces()) {
      provinceNames[province.id] = province.displayName ?? province.id;
    }
    final playerNames = {for (final p in game.players) p.id: p.displayName};
    final model = buildDevelopmentPanelModel(
      game: game,
      playerId: humanPlayerId,
      tileMapByRegion: mapData.tileMapByRegion,
      topology: mapData.combinedTopology,
      currentOrders: orders,
      provinceDisplayNamesById: provinceNames,
      playerDisplayNamesById: playerNames,
    );

    return Padding(
      padding: const EdgeInsets.all(CtSpacing.l),
      child: CtPanel(
        padding: const EdgeInsets.all(CtSpacing.l),
        child: CtTabStrip(
          key: DevelopmentPanelKeys.tabsBodyKey,
          tabLabels: const ['Old World', 'New World'],
          tabViews: [
            _DevelopmentRegionTab(
              game: game,
              regionId: kRegionOldWorld,
              regionModel: model.oldWorld,
            ),
            _DevelopmentRegionTab(
              game: game,
              regionId: kRegionNewWorld,
              regionModel: model.newWorld,
            ),
          ],
        ),
      ),
    );
  }
}

class _DevelopmentRegionTab extends StatefulWidget {
  const _DevelopmentRegionTab({
    required this.game,
    required this.regionId,
    required this.regionModel,
  });

  final Game game;
  final String regionId;
  final DevelopmentPanelRegionModel regionModel;

  @override
  State<_DevelopmentRegionTab> createState() => _DevelopmentRegionTabState();
}

class _DevelopmentRegionTabState extends State<_DevelopmentRegionTab> {
  Set<String>? _highlightTileKeys;

  @override
  Widget build(BuildContext context) {
    final wide = MediaQuery.sizeOf(context).width >= kNarrowBreakpoint;
    final list = DevelopmentPanelScopeList(
      key: DevelopmentPanelKeys.scopeListKey,
      regionModel: widget.regionModel,
      onShowTiles: (keys) => setState(() {
        _highlightTileKeys = Set<String>.from(keys);
      }),
    );
    final mapPanel = DevelopmentPanelMapPanel(
      key: DevelopmentPanelKeys.panelMapKey,
      game: widget.game,
      regionId: widget.regionId,
      highlightTileKeys: _highlightTileKeys,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        DevelopmentPanelOverview(
          key: DevelopmentPanelKeys.overviewKey,
          regionModel: widget.regionModel,
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
