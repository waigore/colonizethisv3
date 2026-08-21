/// Flutter host for MAP30001 / MAP30002. SPEC/ui/tile-context-radial.md.
library;

import 'package:colonizethis_app/features/game/flame/caches/per_player_work_target_selection_cache.dart';
import 'package:colonizethis_app/features/game/flame/controls/map_tile_hover_readout_copy.dart';
import 'package:colonizethis_app/features/game/flame/map_state/game_map_area_state_logic.dart';
import 'package:colonizethis_app/features/game/flame/map_state/province_action_state_calculator.dart';
import 'package:colonizethis_app/features/game/flame/overlays/province_detail_overlay_host_support.dart';
import 'package:colonizethis_app/providers/game_service_provider.dart';
import 'package:colonizethis_app/providers/games_provider.dart';
import 'package:colonizethis_app/providers/map_province_panel_provider.dart';
import 'package:colonizethis_app_l10n/l10n/l10n.dart';
import 'package:colonizethis_map/colonizethis_map.dart';
import 'package:colonizethis_models/colonizethis_models.dart' as ct_models;
import 'package:colonizethis_world/colonizethis_world.dart' show PlayerView;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'tile_context_radial.dart';
import 'tile_more_actions_dialog.dart';
import 'tile_radial_catalog.dart';
import 'tile_radial_emit.dart';
import 'tile_radial_keys.dart';
import 'tile_radial_layout.dart';
import 'tile_radial_spoke_view.dart';
import 'tile_radial_tooltips.dart';

/// Overlay host: secondary map gesture → radial or More dialog.
class GameMapTileRadialHost extends ConsumerStatefulWidget {
  const GameMapTileRadialHost({
    required this.game,
    required this.region,
    required this.humanPlayerId,
    required this.playerView,
    required this.workTargetSelectionCache,
    required this.canMutateViaUi,
    required this.bus,
    required this.mapBuilder,
    super.key,
  });

  final ct_models.Game game;
  final RegionMapViewData region;
  final String humanPlayerId;
  final PlayerView playerView;
  final PerPlayerWorkTargetSelectionCache workTargetSelectionCache;
  final bool canMutateViaUi;
  final ct_models.AppEventBus? bus;
  final Widget Function(
    void Function(String tileKey, Offset local)? onSecondary,
  )
  mapBuilder;

  @override
  ConsumerState<GameMapTileRadialHost> createState() =>
      GameMapTileRadialHostState();
}

class GameMapTileRadialHostState extends ConsumerState<GameMapTileRadialHost> {
  String? _tileKey;
  Offset _anchor = Offset.zero;
  bool _radialOpen = false;

  bool get isRadialOpen => _radialOpen;

  void openFromSecondary(String tileKey, Offset local) {
    if (!widget.canMutateViaUi || widget.bus == null) {
      return;
    }
    final viewport = MediaQuery.sizeOf(context);
    final fits = tileRadialFitsAfterClamp(viewport: viewport, anchor: local);
    setState(() {
      _tileKey = tileKey;
      _anchor = local;
      _radialOpen = fits;
    });
    if (!fits) {
      _openMoreDialog(includeAllCatalog: true);
    }
  }

  void _dismiss() {
    if (!_radialOpen && _tileKey == null) return;
    setState(() {
      _radialOpen = false;
      _tileKey = null;
    });
  }

  TileRadialCatalogLayout _layoutFor(String tileKey) {
    final draftOrders = ref.read(currentOrdersProvider);
    final mapData = tryGetGameMapData(
      () => ref.read(gameServiceProvider).getMapData(widget.game.id),
    );
    final states = ProvinceActionStateCalculator.compute(
      game: widget.game,
      humanPlayerId: widget.humanPlayerId,
      selectedTileKey: tileKey,
      region: widget.region,
      playerView: widget.playerView,
      currentOrders: draftOrders,
      workTargetSelectionCache: widget.workTargetSelectionCache,
      mapData: mapData,
    );
    final parsed = tileKey.split('|');
    final provinceId = parsed.length >= 2
        ? '${parsed[0]}|${parsed[1]}'
        : tileKey;
    final upgradeTown =
        GameMapAreaStateLogicProvinceActions.provinceUpgradeTownActionState(
          game: widget.game,
          humanPlayerId: widget.humanPlayerId,
          provinceId: provinceId,
          playerView: widget.playerView,
          workTargetSelectionCache: widget.workTargetSelectionCache,
          topology: mapData?.combinedTopology,
          currentOrders: draftOrders,
          tileMapByRegion: mapData?.tileMapByRegion,
        );
    final upgradeTownOnSelectedTile =
        upgradeTown.showControl && upgradeTown.townTileKey == tileKey;
    return rankTileRadialCatalog(
      visibility: {
        TileRadialCatalogAction.explore: (
          showIcon: states.explore.showIcon,
          enabled: states.explore.enabled,
        ),
        TileRadialCatalogAction.prospect: (
          showIcon: states.prospect.showIcon,
          enabled: states.prospect.enabled,
        ),
        TileRadialCatalogAction.buildImprovement: (
          showIcon: states.buildImprovement.showIcon,
          enabled: states.buildImprovement.enabled,
        ),
        TileRadialCatalogAction.buildRoad: (
          showIcon: states.buildRoad.showIcon,
          enabled: states.buildRoad.enabled,
        ),
        TileRadialCatalogAction.purchaseLand: (
          showIcon: states.purchaseLand.showIcon,
          enabled: states.purchaseLand.enabled,
        ),
        TileRadialCatalogAction.upgradeTown: (
          showIcon: upgradeTownOnSelectedTile,
          enabled: upgradeTownOnSelectedTile && upgradeTown.enabled,
        ),
        TileRadialCatalogAction.buildPort: (
          showIcon: states.buildPort.showIcon,
          enabled: states.buildPort.enabled,
        ),
        TileRadialCatalogAction.buildRail: (
          showIcon: states.buildRail.showIcon,
          enabled: states.buildRail.enabled,
        ),
        TileRadialCatalogAction.buildFort: (
          showIcon: states.buildFort.showIcon,
          enabled: states.buildFort.enabled,
        ),
      },
    );
  }

  List<TileRadialSpokeView> _viewsFor(
    BuildContext context,
    String tileKey,
    List<TileRadialSpoke> spokes,
  ) {
    final l10n = appL10n(context);
    final draftOrders = ref.read(currentOrdersProvider);
    final parsed = tileKey.split('|');
    final provinceId = parsed.length >= 2
        ? '${parsed[0]}|${parsed[1]}'
        : tileKey;
    final mapData = tryGetGameMapData(
      () => ref.read(gameServiceProvider).getMapData(widget.game.id),
    );
    final states = ProvinceActionStateCalculator.compute(
      game: widget.game,
      humanPlayerId: widget.humanPlayerId,
      selectedTileKey: tileKey,
      region: widget.region,
      playerView: widget.playerView,
      currentOrders: draftOrders,
      workTargetSelectionCache: widget.workTargetSelectionCache,
      mapData: mapData,
    );
    final upgradeTown =
        GameMapAreaStateLogicProvinceActions.provinceUpgradeTownActionState(
          game: widget.game,
          humanPlayerId: widget.humanPlayerId,
          provinceId: provinceId,
          playerView: widget.playerView,
          workTargetSelectionCache: widget.workTargetSelectionCache,
          topology: mapData?.combinedTopology,
          currentOrders: draftOrders,
          tileMapByRegion: mapData?.tileMapByRegion,
        );
    bool hasMatchingUnits(TileRadialCatalogAction action) {
      switch (action) {
        case TileRadialCatalogAction.explore:
          return states.explore.hasMatchingUnits;
        case TileRadialCatalogAction.prospect:
          return states.prospect.hasMatchingUnits;
        case TileRadialCatalogAction.buildImprovement:
          return states.buildImprovement.hasMatchingUnits;
        case TileRadialCatalogAction.buildRoad:
          return states.buildRoad.hasMatchingUnits;
        case TileRadialCatalogAction.purchaseLand:
          return states.purchaseLand.hasMatchingUnits;
        case TileRadialCatalogAction.upgradeTown:
          return upgradeTown.hasBuilderUnits;
        case TileRadialCatalogAction.buildPort:
          return states.buildPort.hasMatchingUnits;
        case TileRadialCatalogAction.buildRail:
          return states.buildRail.hasMatchingUnits;
        case TileRadialCatalogAction.buildFort:
          return states.buildFort.hasMatchingUnits;
      }
    }

    return [
      for (final spoke in spokes)
        TileRadialSpokeView(
          action: spoke.action,
          enabled: spoke.enabled,
          label: tileRadialActionLabel(l10n, spoke.action),
          tooltip: tileRadialActionTooltip(
            context: context,
            l10n: l10n,
            action: spoke.action,
            game: widget.game,
            humanPlayerId: widget.humanPlayerId,
            tileKey: tileKey,
            provinceId: provinceId,
            currentOrders: draftOrders,
            enabled: spoke.enabled,
            hasMatchingUnits: hasMatchingUnits(spoke.action),
          ),
        ),
    ];
  }

  void _commit(TileRadialCatalogAction action) {
    final tileKey = _tileKey;
    final bus = widget.bus;
    if (tileKey == null || bus == null) return;
    emitTileRadialCatalogAction(
      action: action,
      tileKey: tileKey,
      game: widget.game,
      humanPlayerId: widget.humanPlayerId,
      region: widget.region,
      playerView: widget.playerView,
      workTargetSelectionCache: widget.workTargetSelectionCache,
      draftOrders: ref.read(currentOrdersProvider),
      mapData: tryGetGameMapData(
        () => ref.read(gameServiceProvider).getMapData(widget.game.id),
      ),
      bus: bus,
    );
    _dismiss();
  }

  Future<void> _openMoreDialog({required bool includeAllCatalog}) async {
    final tileKey = _tileKey;
    if (tileKey == null || !mounted) return;
    final layout = _layoutFor(tileKey);
    final remainder = includeAllCatalog ? layout.wedges : layout.moreRemainder;
    final place =
        tryMapTileHoverReadoutCopy(
          l10n: appL10n(context),
          game: widget.game,
          region: widget.region,
          tileKey: tileKey,
        )?.placeLine ??
        tileKey;
    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return TileMoreActionsDialog(
          placeLine: place,
          remainder: _viewsFor(dialogContext, tileKey, remainder),
          onAction: (action) {
            Navigator.of(dialogContext).pop();
            _commit(action);
          },
          onProvinceDetails: () {
            Navigator.of(dialogContext).pop();
            ref
                .read(mapProvincePanelProvider.notifier)
                .reportMapTileTapped(tileKey);
            _dismiss();
          },
        );
      },
    );
    if (mounted) {
      _dismiss();
    }
  }

  @override
  Widget build(BuildContext context) {
    final tileKey = _tileKey;
    final onSecondary = widget.canMutateViaUi ? openFromSecondary : null;
    Widget overlay = const SizedBox.shrink();
    if (_radialOpen && tileKey != null) {
      final layout = _layoutFor(tileKey);
      final place =
          tryMapTileHoverReadoutCopy(
            l10n: appL10n(context),
            game: widget.game,
            region: widget.region,
            tileKey: tileKey,
          )?.placeLine ??
          tileKey;
      overlay = TileContextRadial(
        placeLine: place,
        wedges: _viewsFor(context, tileKey, layout.wedges),
        anchor: _anchor,
        onWedge: _commit,
        onMore: () {
          setState(() => _radialOpen = false);
          _openMoreDialog(includeAllCatalog: false);
        },
        onDismiss: _dismiss,
      );
    }
    return Stack(children: [widget.mapBuilder(onSecondary), overlay]);
  }
}
