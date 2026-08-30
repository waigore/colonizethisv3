// Last-turn spatial playback anchors and captions for [GameMapArea].
// SPEC/ui/map-widget.md § Last-turn spatial playback.

import 'package:colonizethis_app_ui_chrome/event_feed/ct_event_feed_text.dart';
import 'package:colonizethis_models/colonizethis_models.dart' as ct_models;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'game_map_area.dart';
import 'game_map_area_state_base.dart';
import 'game_map_area_turn_feed_labels.dart';
import 'game_map_area_turn_feed_locate.dart';
import 'map_location_resolver.dart';

mixin GameMapAreaLastTurnPlaybackAnchors
    on
        ConsumerState<GameMapArea>,
        GameMapAreaStateBase,
        GameMapAreaTurnFeedLabels,
        GameMapAreaTurnFeedLocate {
  ({String tileKey, String regionId})? resolveLastTurnAnchor(
    ct_models.GameToUIEvent event,
  ) {
    return switch (event) {
      ct_models.AppCombatResultEvent(:final provinceId) ||
      ct_models.AppProvinceCapturedEvent(:final provinceId) ||
      ct_models.AppPlayerProvinceDiscoveredEvent(
        :final provinceId,
      ) => _anchorForProvince(provinceId),
      ct_models.AppNavalCombatResultEvent(:final seaZoneId) ||
      ct_models.AppPlayerSeaZoneDiscoveredEvent(
        :final seaZoneId,
      ) => _anchorForSeaZone(seaZoneId),
      ct_models.AppWorkOrderCompletedEvent(
        :final targetTileKey,
        :final provinceId,
      ) =>
        _anchorForWorkOrder(targetTileKey, provinceId),
      _ => null,
    };
  }

  ({String tileKey, String regionId})? _anchorForProvince(String provinceId) {
    final province = provinceByPrefixedId(provinceId);
    if (province == null) {
      return null;
    }
    final tileKey = tileKeyForProvinceLocation(widget.game, province);
    if (tileKey == null) {
      return null;
    }
    return (tileKey: tileKey, regionId: province.regionId);
  }

  ({String tileKey, String regionId})? _anchorForSeaZone(String seaZoneId) {
    final tileKey = tileKeyForSeaZoneEvent(seaZoneId);
    if (tileKey == null) {
      return null;
    }
    final regionId = ct_models.Unit.regionIdFromTileKey(tileKey);
    if (regionId == null) {
      return null;
    }
    return (tileKey: tileKey, regionId: regionId);
  }

  ({String tileKey, String regionId})? _anchorForWorkOrder(
    String targetTileKey,
    String provinceId,
  ) {
    if (targetTileKey.isNotEmpty) {
      final regionId = ct_models.Unit.regionIdFromTileKey(targetTileKey);
      if (regionId != null) {
        return (tileKey: targetTileKey, regionId: regionId);
      }
    }
    return _anchorForProvince(provinceId);
  }

  String captionForLastTurnEvent(ct_models.GameToUIEvent event) {
    return switch (event) {
      ct_models.AppCombatResultEvent(
        :final provinceId,
        :final attackerId,
        :final defenderId,
        :final outcomeName,
        :final attackerCasualtyCount,
        :final defenderCasualtyCount,
      ) =>
        CtEventFeedText.combatResolvedLine(
          provinceLabel: provinceLabel(provinceId),
          outcomeLabel: CtEventFeedText.landBattleOutcomeLabel(outcomeName),
          attackerLabel: factionLabel(attackerId),
          defenderLabel: factionLabel(defenderId),
          attackerLosses: attackerCasualtyCount,
          defenderLosses: defenderCasualtyCount,
        ),
      ct_models.AppProvinceCapturedEvent(
        :final provinceId,
        :final newOwnerId,
      ) =>
        '${provinceLabel(provinceId)} captured! '
            '${factionLabel(newOwnerId)} now controls it!',
      ct_models.AppNavalCombatResultEvent(
        :final seaZoneId,
        :final side1OwnerId,
        :final side2OwnerId,
        :final outcomeName,
        :final side1CasualtyCount,
        :final side2CasualtyCount,
        :final side1Retreated,
        :final side2Retreated,
      ) =>
        CtEventFeedText.navalCombatResolvedLine(
          seaZoneLabel: seaZoneLabel(seaZoneId),
          outcomeLabel: CtEventFeedText.navalBattleOutcomeLabel(outcomeName),
          side1Label: factionLabel(side1OwnerId),
          side2Label: factionLabel(side2OwnerId),
          side1Losses: side1CasualtyCount,
          side2Losses: side2CasualtyCount,
          side1Retreated: side1Retreated,
          side2Retreated: side2Retreated,
        ),
      ct_models.AppWorkOrderCompletedEvent(
        :final provinceId,
        :final workTarget,
      ) =>
        '${provinceLabel(provinceId)} work completed! '
            '${workTargetLabel(workTarget)} finished!',
      ct_models.AppPlayerProvinceDiscoveredEvent(:final provinceId) =>
        '${provinceLabel(provinceId)} discovered!',
      ct_models.AppPlayerSeaZoneDiscoveredEvent(:final seaZoneId) =>
        '${seaZoneLabel(seaZoneId)} discovered!',
      _ => '',
    };
  }
}
