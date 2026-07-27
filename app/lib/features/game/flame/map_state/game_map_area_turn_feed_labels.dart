
import 'package:colonizethis_app_ui_chrome/colonizethis_app_ui_chrome.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:colonizethis_app/core/utils/prefixed_id.dart';
import 'package:colonizethis_data/colonizethis_data.dart'
    show TopologyNodeType, techById, techDisplayName;
import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart' as ct_models;

import '../../../../config/routes.dart';
import '../../../../providers/app_event_bus_provider.dart';
import '../../../../providers/game_service_provider.dart';
import '../../../../providers/games_provider.dart';
import '../../widgets/diplomacy/diplomacy_order_helpers.dart';
import '../../widgets/diplomacy/diplomacy_panel_rows.dart';
import '../../widgets/diplomacy/diplomacy_panel_rows_builder_helpers.dart';
import '../../widgets/units/civilian/civilian_units_panel_support_resolution.dart';

import 'map_location_resolver.dart';
import 'game_map_area.dart';
import 'game_map_area_state_base.dart';

/// Display-label and map-locate helpers for [GameMapArea] turn-event feed
/// entries (Refs #3878 Phase 3 map_state modularization).
mixin GameMapAreaTurnFeedLabels
    on ConsumerState<GameMapArea>, GameMapAreaStateBase {
  String factionLabel(String id) =>
      widget.game.factionDisplayNameById(id) ?? id;

  String provinceLabel(String fullProvinceId) =>
      widget.game.worldState.tryGetProvince(fullProvinceId)?.displayName ??
      fullProvinceId;

  String seaZoneLabel(String seaZoneId) {
    return widget.game.worldState.seaZoneDisplayNameById[seaZoneId] ??
        seaZoneId;
  }

  String diplomacyOutcomeLine({
    required String actorId,
    required String targetId,
    required String changeType,
  }) {
    final actor = factionLabel(actorId);
    final target = factionLabel(targetId);
    final normalized = changeType.toLowerCase();
    return switch (normalized) {
      'declare_war' => '$actor declared war on $target!',
      'peace' => '$actor and $target signed peace!',
      'alliance' => '$actor and $target formed an alliance!',
      'break_alliance' => '$actor and $target broke their alliance!',
      _ => '$actor and $target diplomacy changed! ${changeType.toUpperCase()}!',
    };
  }

  Set<String> seaZoneRegionCandidates(String seaZoneId) {
    final regionFromPrefix = prefixedIdRegionSegment(seaZoneId);
    if (regionFromPrefix != null && regionFromPrefix.isNotEmpty) {
      return {regionFromPrefix};
    }
    final localSeaZoneId = prefixedIdLocalSegment(seaZoneId);
    final fromPorts = <String>{};
    for (final key in widget.game.worldState.portsByProvinceSeaboard.keys) {
      final firstPipe = key.indexOf('|');
      if (firstPipe <= 0 || firstPipe + 1 >= key.length) {
        continue;
      }
      final lastPipe = key.lastIndexOf('|');
      final keyRegion = key.substring(0, firstPipe);
      final keySeaZone = key.substring(lastPipe + 1);
      if (keySeaZone == localSeaZoneId && keyRegion.isNotEmpty) {
        fromPorts.add(keyRegion);
      }
    }
    final mapData = ref.read(gameServiceProvider).getMapData(widget.game.id);
    final fromTopology = <String>{};
    if (mapData == null) {
      return fromPorts;
    }
    for (final entry in mapData.topologyByRegion.entries) {
      if (entry.value.nodes.any(
        (node) =>
            node.type == TopologyNodeType.seaZone && node.id == localSeaZoneId,
      )) {
        fromTopology.add(entry.key);
      }
    }
    return {...fromPorts, ...fromTopology};
  }

  String? tileKeyForSeaZoneEvent(String seaZoneId) {
    final candidates = seaZoneRegionCandidates(seaZoneId);
    if (candidates.length != 1) {
      return null;
    }
    final regionId = candidates.first;
    final mapData = ref.read(gameServiceProvider).getMapData(widget.game.id);
    return tileKeyForNavalFleetAtSea(
      game: widget.game,
      regionId: regionId,
      seaZoneId: seaZoneId,
      tileMap: mapData?.tileMapByRegion[regionId],
      regionTopology: mapData?.topologyByRegion[regionId],
    );
  }

  ct_models.Province? provinceByPrefixedId(String prefixedProvinceId) =>
      widget.game.worldState.tryGetProvince(prefixedProvinceId);

  void emitLocateMapTile({
    required String tileKey,
    required String regionId,
  }) {
    ref.read(appEventBusProvider).emit(
          ct_models.LocateMapTileEvent(
            tileKey: tileKey,
            regionId: regionId,
          ),
        );
  }

  void locateProvinceTile(ct_models.Province province) {
    final tileKey = tileKeyForProvinceLocation(widget.game, province);
    if (tileKey == null) {
      return;
    }
    emitLocateMapTile(tileKey: tileKey, regionId: province.regionId);
  }

  void locateProvinceById(String provinceId) {
    final province = provinceByPrefixedId(provinceId);
    if (province == null) {
      return;
    }
    locateProvinceTile(province);
  }

  void locateSeaZoneTile(String seaZoneId) {
    final tileKey = tileKeyForSeaZoneEvent(seaZoneId);
    if (tileKey == null) {
      return;
    }
    final regionId = ct_models.Unit.regionIdFromTileKey(tileKey);
    if (regionId == null) {
      return;
    }
    emitLocateMapTile(tileKey: tileKey, regionId: regionId);
  }

  void locateTileKey(String tileKey) {
    final regionId = ct_models.Unit.regionIdFromTileKey(tileKey);
    if (regionId == null) {
      return;
    }
    emitLocateMapTile(tileKey: tileKey, regionId: regionId);
  }

  bool isCatalogTech(String techId) => techById(techId) != null;

  String researchCompleteLine(String techId) {
    if (!isCatalogTech(techId)) {
      return 'Research complete — technology unlocked!';
    }
    return 'Research complete: ${techDisplayName(techId)} unlocked';
  }

  void navigateToTechnologyScreen() {
    final orders = ref.read(currentOrdersProvider);
    ref.read(appEventBusProvider).emit(
          ct_models.NavigateToRouteEvent(Routes.technology, {
            'game': widget.game,
            'humanPlayerId': mapPlayerId,
            'currentOrders': orders,
          }),
        );
  }

  String workTargetLabel(String workTarget) =>
      civilianUnitsPanelWorkTargetLabels[workTarget] ?? workTarget;

  String overtureStageLabel(String stage) {
    for (final value in ct_models.OvertureStage.values) {
      if (value.name == stage) {
        return diplomacyOvertureStageShortLabel(value);
      }
    }
    return stage.replaceAll('_', ' ');
  }

  String orderRejectedReasonLabel(String reasonCode) =>
      CtEventFeedText.orderRejectedReasonLabel(reasonCode);

  String orderRejectedLine(String reasonCode) =>
      CtEventFeedText.orderRejectedLine(reasonCode);

  bool canResolveFaction(String factionId) =>
      widget.game.playerById(factionId) != null ||
      widget.game.minorNations.any((m) => m.id == factionId) ||
      widget.game.tribes.any((t) => t.id == factionId);

  FactionKind? factionKindForId(String factionId) {
    if (widget.game.playerById(factionId) != null) {
      return FactionKind.greatPower;
    }
    if (widget.game.minorNations.any((m) => m.id == factionId)) {
      return FactionKind.minor;
    }
    if (widget.game.tribes.any((t) => t.id == factionId)) {
      return FactionKind.tribe;
    }
    return null;
  }

  String? counterpartFactionId({
    required String actorId,
    required String targetId,
  }) {
    if (actorId == mapPlayerId) {
      return targetId;
    }
    if (targetId == mapPlayerId) {
      return actorId;
    }
    return null;
  }

  String? overtureCounterpartFactionId({
    required String offererGpId,
    required String targetFactionId,
  }) {
    if (offererGpId == mapPlayerId) {
      return targetFactionId;
    }
    if (targetFactionId == mapPlayerId) {
      return offererGpId;
    }
    return null;
  }

  String? spyCounterpartFactionId({
    required String spyOwnerId,
    required String territoryOwnerId,
  }) {
    if (mapPlayerId == territoryOwnerId) {
      return spyOwnerId;
    }
    if (mapPlayerId == spyOwnerId) {
      return territoryOwnerId;
    }
    return null;
  }

  bool unitExists(String unitId) =>
      widget.game.worldState.allUnitsById.containsKey(unitId);

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
}
