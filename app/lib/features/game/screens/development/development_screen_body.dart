import 'package:colonizethis_app_fixtures/runtime/app_perf_trace.dart';
import 'package:colonizethis_app_l10n/l10n/l10n.dart';
import 'package:colonizethis_economy/colonizethis_economy.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_world/colonizethis_world.dart'
    show kRegionNewWorld, kRegionOldWorld;
import 'package:flutter/foundation.dart' show kProfileMode, kReleaseMode;
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../providers/app_event_bus_provider.dart';
import '../../../../providers/development_panel_projection_provider.dart';
import '../../../../providers/game_service_provider.dart';
import '../../../../providers/games_provider.dart';
import '../../../../widgets/commodity_display_name.dart';
import '../../../../widgets/ct_panel.dart';
import '../../../../widgets/ct_spacing.dart';
import '../../../../widgets/ct_tab_strip.dart';
import '../../widgets/shell/shell_player_context.dart';
import 'development_inbound_highlight.dart';
import 'development_panel_assign_handler.dart';
import 'development_panel_keys.dart';
import 'development_region_tab.dart';

/// Body for [DevelopmentScreen]: region tabs, overview, list + map.
class DevelopmentScreenBody extends ConsumerStatefulWidget {
  const DevelopmentScreenBody({
    super.key,
    required this.game,
    required this.humanPlayerId,
    this.highlightCommodityId,
    this.highlightTileKey,
  });

  final Game game;
  final String humanPlayerId;
  final String? highlightCommodityId;
  final String? highlightTileKey;

  @override
  ConsumerState<DevelopmentScreenBody> createState() =>
      _DevelopmentScreenBodyState();
}

class _DevelopmentScreenBodyState extends ConsumerState<DevelopmentScreenBody> {
  late final Set<String> _visitedRegionIds = _initialVisitedRegionIds();
  bool _readModelReady = false;
  bool _loggedInteractiveReady = false;
  int? _resolvedInitialTabIndex;

  Set<String> _initialVisitedRegionIds() {
    final visited = <String>{kRegionOldWorld};
    final tileKey = widget.highlightTileKey;
    if (tileKey != null) {
      final parsed = parseTileKeyCoordinates(tileKey);
      if (parsed?.regionId == kRegionNewWorld) {
        visited.add(kRegionNewWorld);
      }
    } else if (widget.highlightCommodityId != null) {
      // Search both regions for the first matching improvable row.
      visited.add(kRegionNewWorld);
    }
    return visited;
  }

  @override
  void initState() {
    super.initState();
    ctAppPerfSurfaceOpenBegin('development');
    SchedulerBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      ctAppPerfInstant('development.readModelReady');
      setState(() => _readModelReady = true);
    });
  }

  void _onRegionTabSelected(int index) {
    final regionId = index == 0 ? kRegionOldWorld : kRegionNewWorld;
    if (_visitedRegionIds.contains(regionId)) return;
    setState(() => _visitedRegionIds.add(regionId));
  }

  @override
  Widget build(BuildContext context) {
    final game = widget.game;
    final mapData = ref.read(gameServiceProvider).getMapData(game.id);
    if (mapData == null) {
      return Center(child: Text(appL10n(context).development_mapDataUnavailable));
    }

    final l10n = appL10n(context);
    if (!_readModelReady) {
      return Padding(
        padding: const EdgeInsets.all(CtSpacing.l),
        child: CtPanel(
          padding: const EdgeInsets.all(CtSpacing.l),
          child: CtTabStrip(
            key: const ValueKey<String>('development_tabs_loading'),
            lazyTabBodies: true,
            onTabIndexChanged: _onRegionTabSelected,
            tabLabels: [l10n.region_oldWorld, l10n.region_newWorld],
            tabViews: const [
              SizedBox.shrink(),
              SizedBox.shrink(),
            ],
          ),
        ),
      );
    }

    final projection = ref.watch(developmentPanelProjectionProvider);
    if (projection == null) {
      return Center(child: Text(l10n.development_mapDataUnavailable));
    }

    if (!_loggedInteractiveReady) {
      _loggedInteractiveReady = true;
      final elapsedMs = ctAppPerfSurfaceOpenInteractiveReady('development');
      if ((kProfileMode || kReleaseMode) && elapsedMs != null) {
        ctAppPerfLogUiSurfaceOpen('development', elapsedMs);
      }
    }

    final orders = ref.watch(currentOrdersProvider);
    final shell = ref.watch(shellPlayerContextProvider);
    final canEdit = shell.canMutateViaUi;
    final connectedTileKeys = projection.shared.connectedTileKeys;

    DevelopmentPanelRegionModel regionModelFor(String regionId) {
      if (!_visitedRegionIds.contains(regionId)) {
        return emptyDevelopmentPanelRegionModel(regionId);
      }
      return ref.watch(developmentPanelRegionModelProvider(regionId)) ??
          emptyDevelopmentPanelRegionModel(regionId);
    }

    final owModel = regionModelFor(kRegionOldWorld);
    final nwModel = regionModelFor(kRegionNewWorld);
    final inboundCommodityId = widget.highlightCommodityId;
    final inboundTileKey = widget.highlightTileKey;
    final initialTabIndex = _resolvedInitialTabIndex ??=
        resolveDevelopmentInboundTabIndex(
          highlightCommodityId: inboundCommodityId,
          highlightTileKey: inboundTileKey,
          oldWorld: owModel,
          newWorld: nwModel,
        );
    final activeRegionId =
        initialTabIndex == 0 ? kRegionOldWorld : kRegionNewWorld;
    final inboundMiss =
        inboundCommodityId != null &&
        !developmentRegionHasImprovableCommodity(owModel, inboundCommodityId) &&
        !developmentRegionHasImprovableCommodity(nwModel, inboundCommodityId);

    final bus = ref.read(appEventBusProvider);

    Widget regionTab({
      required String regionId,
      required DevelopmentPanelRegionModel regionModel,
    }) {
      final applyInbound =
          inboundCommodityId != null && regionId == activeRegionId;
      return DevelopmentRegionTab(
        game: projection.game,
        humanPlayerId: projection.humanPlayerId,
        regionId: regionId,
        regionModel: regionModel,
        playerView: projection.playerView,
        topology: projection.topology,
        tileMapByRegion: projection.tileMapByRegion,
        currentOrders: orders,
        connectedTileKeys: connectedTileKeys,
        provinceDisplayNamesById: projection.provinceDisplayNamesById,
        canEdit: canEdit,
        inboundHighlightCommodityId:
            applyInbound ? inboundCommodityId : null,
        inboundHighlightTileKey: applyInbound ? inboundTileKey : null,
        onAssign: (candidate) => handleDevelopmentAssign(
          context: context,
          bus: bus,
          game: projection.game,
          humanPlayerId: projection.humanPlayerId,
          canEdit: canEdit,
          topology: projection.topology,
          tileMapByRegion: projection.tileMapByRegion,
          orders: orders,
          connectedTileKeys: connectedTileKeys,
          candidate: candidate,
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.all(CtSpacing.l),
      child: CtPanel(
        padding: const EdgeInsets.all(CtSpacing.l),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (inboundMiss)
              Padding(
                padding: const EdgeInsets.only(bottom: CtSpacing.m),
                child: Text(
                  key: const ValueKey<String>(
                    'development_inbound_no_match_banner',
                  ),
                  l10n.development_noMatchForInboundCommodity(
                    commodityDisplayName(l10n, inboundCommodityId!),
                  ),
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ),
            Expanded(
              child: CtTabStrip(
                key: DevelopmentPanelKeys.tabsBodyKey,
                lazyTabBodies: true,
                initialTabIndex: initialTabIndex,
                onTabIndexChanged: _onRegionTabSelected,
                tabLabels: [l10n.region_oldWorld, l10n.region_newWorld],
                tabViews: [
                  regionTab(regionId: kRegionOldWorld, regionModel: owModel),
                  regionTab(regionId: kRegionNewWorld, regionModel: nwModel),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
