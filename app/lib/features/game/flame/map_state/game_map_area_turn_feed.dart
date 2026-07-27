
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:colonizethis_models/colonizethis_models.dart' as ct_models;


import '../../widgets/shell/player_turn_event_feed.dart';
import 'game_map_area.dart';
import 'game_map_area_state_base.dart';
import 'game_map_area_turn_feed_labels.dart';

/// Player turn-event feed for [GameMapArea]: turning resolved `GameToUIEvent`s
/// into tappable feed entries (Refs #3699 Theme 3).
mixin GameMapAreaTurnFeed
    on
        ConsumerState<GameMapArea>,
        GameMapAreaStateBase,
        GameMapAreaTurnFeedLabels {
  List<PlayerTurnEventFeedEntry> buildFeedEntries() {
    return resolvedPlayerTurnEvents
        .map((event) {
          return switch (event) {
            ct_models.AppCombatResultEvent(
              :final provinceId,
              :final winnerId,
              :final attackerId,
              :final defenderId,
            ) =>
              PlayerTurnEventFeedEntry(
                text:
                    '${provinceLabel(provinceId)} battle resolved! ${factionLabel(winnerId)} defeated ${factionLabel(winnerId == attackerId ? defenderId : attackerId)}!',
                onTap: () => locateProvinceById(provinceId),
              ),
            ct_models.AppProvinceCapturedEvent(
              :final provinceId,
              :final newOwnerId,
            ) =>
              PlayerTurnEventFeedEntry(
                text:
                    '${provinceLabel(provinceId)} captured! ${factionLabel(newOwnerId)} now controls it!',
                onTap: () => locateProvinceById(provinceId),
              ),
            ct_models.AppNavalCombatResultEvent(
              :final seaZoneId,
              :final outcomeName,
            ) =>
              PlayerTurnEventFeedEntry(
                text:
                    '${seaZoneLabel(seaZoneId)} naval battle resolved! Outcome: $outcomeName!',
                onTap: () => locateSeaZoneTile(seaZoneId),
              ),
            ct_models.AppDiplomacyChangeEvent(
              :final actorId,
              :final targetId,
              :final changeType,
            ) =>
              PlayerTurnEventFeedEntry(
                text: diplomacyOutcomeLine(
                  actorId: actorId,
                  targetId: targetId,
                  changeType: changeType,
                ),
              ),
            ct_models.AppResearchCompleteEvent(:final techId) =>
              isCatalogTech(techId)
                  ? PlayerTurnEventFeedEntry(
                      text: researchCompleteLine(techId),
                      linkAffordance: true,
                      onTap: navigateToTechnologyScreen,
                    )
                  : PlayerTurnEventFeedEntry(
                      text: researchCompleteLine(techId),
                    ),
            ct_models.AppOrderRejectedEvent(:final reasonCode) =>
              PlayerTurnEventFeedEntry(
                text: 'Order rejected! Reason: $reasonCode!',
              ),
            ct_models.AppWorkOrderCompletedEvent(
              :final workTarget,
              :final targetTileKey,
              :final provinceId,
            ) =>
              PlayerTurnEventFeedEntry(
                text:
                    '${provinceLabel(provinceId)} work completed! ${workTarget.toUpperCase()} finished!',
                onTap: () => locateTileKey(targetTileKey),
              ),
            ct_models.AppPlayerProvinceDiscoveredEvent(:final provinceId) =>
              PlayerTurnEventFeedEntry(
                text: '${provinceLabel(provinceId)} discovered!',
                onTap: () => locateProvinceById(provinceId),
              ),
            ct_models.AppPlayerSeaZoneDiscoveredEvent(:final seaZoneId) =>
              PlayerTurnEventFeedEntry(
                text: '${seaZoneLabel(seaZoneId)} discovered!',
                onTap: () => locateSeaZoneTile(seaZoneId),
              ),
            ct_models.AppOvertureAdvancedEvent(
              :final offererGpId,
              :final targetFactionId,
              :final newStage,
            ) =>
              PlayerTurnEventFeedEntry(
                text:
                    'Overture advanced! ${factionLabel(offererGpId)} with ${factionLabel(targetFactionId)}: ${newStage.toUpperCase()}!',
              ),
            ct_models.AppSpyCaughtEvent(
              :final provinceId,
              :final spyOwnerId,
              :final territoryOwnerId,
            ) =>
              PlayerTurnEventFeedEntry(
                text: mapPlayerId == territoryOwnerId
                    ? '${provinceLabel(provinceId)} — enemy spy from ${factionLabel(spyOwnerId)} caught and eliminated!'
                    : 'Spy caught in ${provinceLabel(provinceId)}! ${factionLabel(territoryOwnerId)} eliminated your agent!',
                onTap: () => locateProvinceById(provinceId),
              ),
            ct_models.AppSpyDefectedEvent(
              :final provinceId,
              :final previousOwnerId,
              :final newOwnerId,
            ) =>
              PlayerTurnEventFeedEntry(
                text: mapPlayerId == newOwnerId
                    ? '${provinceLabel(provinceId)} — enemy spy from ${factionLabel(previousOwnerId)} defected to your side!'
                    : 'Spy defected in ${provinceLabel(provinceId)}! Agent joined ${factionLabel(newOwnerId)}!',
                onTap: () => locateProvinceById(provinceId),
              ),
            _ => const PlayerTurnEventFeedEntry(text: 'Event resolved!'),
          };
        })
        .toList(growable: false);
  }
}
