import 'package:flutter_riverpod/flutter_riverpod.dart';


import 'package:colonizethis_models/colonizethis_models.dart' as ct_models;

import '../../../../config/routes.dart';
import '../../../../providers/app_event_bus_provider.dart';
import '../../../../providers/game_service_provider.dart';
import '../../../../providers/games_provider.dart';
import '../../widgets/diplomacy/diplomacy_panel_rows_builder_helpers.dart';

import 'map_location_resolver.dart';
import 'game_map_area.dart';
import 'game_map_area_state_base.dart';
import 'game_map_area_turn_feed_labels.dart';
import 'package:colonizethis_diplomacy/colonizethis_diplomacy.dart';
import 'package:colonizethis_logic/ai_api.dart';

/// Turn-feed tap targets and navigation for [GameMapArea] (Refs #3878, #4226).
mixin GameMapAreaTurnFeedTaps
    on
        ConsumerState<GameMapArea>,
        GameMapAreaStateBase,
        GameMapAreaTurnFeedLabels {
  void navigateToDiplomacyDetail(String factionId) {
    final kind = factionKindForId(factionId);
    if (kind == null) {
      return;
    }
    final relation =
        getRelation(widget.game, mapPlayerId, factionId) ??
        defaultFirstContactRelation(
          mapPlayerId,
          factionId,
          widget.game.worldState.turnState.turnNumber,
        );
    ref.read(appEventBusProvider).emit(
          ct_models.NavigateToRouteEvent(Routes.diplomacyDetail, {
            'game': widget.game,
            'humanPlayerId': mapPlayerId,
            'factionId': factionId,
            'factionDisplayName': displayNameForFaction(widget.game, factionId),
            'kind': kind,
            'relation': relation,
          }),
        );
  }

  void Function()? diplomacyDetailTapForFaction(String factionId) {
    if (!canResolveFaction(factionId)) {
      return null;
    }
    return () => navigateToDiplomacyDetail(factionId);
  }

  void locateAndOpenProvinceOverlay(String provinceId) {
    final province = provinceByPrefixedId(provinceId);
    if (province == null) {
      return;
    }
    final tileKey = tileKeyForProvinceLocation(widget.game, province);
    if (tileKey == null) {
      return;
    }
    locateProvinceTile(province);
    ref.read(appEventBusProvider).emit(
          ct_models.OpenMapTileDetailEvent(tileKey: tileKey),
        );
  }

  void Function()? provinceOverlayTapForProvince(String provinceId) {
    final province = provinceByPrefixedId(provinceId);
    if (province == null) {
      return null;
    }
    final tileKey = tileKeyForProvinceLocation(widget.game, province);
    if (tileKey == null) {
      return null;
    }
    return () => locateAndOpenProvinceOverlay(provinceId);
  }

  void Function()? navalCombatTapForSeaZone(String seaZoneId) {
    final tileKey = tileKeyForSeaZoneEvent(seaZoneId);
    if (tileKey == null) {
      return null;
    }
    return () {
      locateSeaZoneTile(seaZoneId);
      ref.read(appEventBusProvider).emit(
            ct_models.OpenMapTileDetailEvent(tileKey: tileKey),
          );
    };
  }

  void Function()? workOrderCompletedTap({
    required String unitId,
    required String targetTileKey,
  }) {
    if (!unitExists(unitId)) {
      return null;
    }
    return () {
      locateTileKey(targetTileKey);
      ref.read(appEventBusProvider).emit(
            ct_models.OpenCivilianUnitsPanelEvent(
              initialSelectedUnitId: unitId,
            ),
          );
    };
  }

  void Function()? overseasProfitCreditedTap() {
    return () => ref.read(appEventBusProvider).emit(
          ct_models.NavigateToRouteEvent(Routes.trade, {
            'game': widget.game,
            'humanPlayerId': mapPlayerId,
            'initialTabIndex': 1,
          }),
        );
  }

  void Function()? orderRejectedTapForKind(ct_models.OrderKind orderKind) {
    final orders = ref.read(currentOrdersProvider);
    final mapData = ref.read(gameServiceProvider).getMapData(widget.game.id);
    switch (orderKind) {
      case ct_models.OrderKind.work:
      case ct_models.OrderKind.recruitWorker:
        return () => ref.read(appEventBusProvider).emit(
              const ct_models.OpenCivilianUnitsPanelEvent(),
            );
      case ct_models.OrderKind.move:
      case ct_models.OrderKind.armyMove:
        return () => ref.read(appEventBusProvider).emit(
              const ct_models.OpenMilitaryUnitsPanelEvent(),
            );
      case ct_models.OrderKind.navalMove:
      case ct_models.OrderKind.navalMission:
        return () => ref.read(appEventBusProvider).emit(
              const ct_models.OpenNavalUnitsPanelEvent(),
            );
      case ct_models.OrderKind.buildUnit:
        return () => ref.read(appEventBusProvider).emit(
              ct_models.NavigateToRouteEvent(Routes.production, {
                'game': widget.game,
                'humanPlayerId': mapPlayerId,
              }),
            );
      case ct_models.OrderKind.trade:
        return () => ref.read(appEventBusProvider).emit(
              ct_models.NavigateToRouteEvent(Routes.trade, {
                'game': widget.game,
                'humanPlayerId': mapPlayerId,
              }),
            );
      case ct_models.OrderKind.research:
        return navigateToTechnologyScreen;
      case ct_models.OrderKind.diplomacy:
        final topology = mapData?.combinedTopology;
        if (topology == null) {
          return null;
        }
        return () => ref.read(appEventBusProvider).emit(
              ct_models.NavigateToRouteEvent(Routes.diplomacy, {
                'game': widget.game,
                'humanPlayerId': mapPlayerId,
                'topology': topology,
                'currentOrders': orders,
              }),
            );
    }
  }
}
