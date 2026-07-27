
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
              _feedEntry(
                text:
                    '${provinceLabel(provinceId)} battle resolved! ${factionLabel(winnerId)} defeated ${factionLabel(winnerId == attackerId ? defenderId : attackerId)}!',
                onTap: provinceOverlayTapForProvince(provinceId),
              ),
            ct_models.AppProvinceCapturedEvent(
              :final provinceId,
              :final newOwnerId,
            ) =>
              _feedEntry(
                text:
                    '${provinceLabel(provinceId)} captured! ${factionLabel(newOwnerId)} now controls it!',
                onTap: provinceOverlayTapForProvince(provinceId),
              ),
            ct_models.AppNavalCombatResultEvent(
              :final seaZoneId,
              :final outcomeName,
            ) =>
              _feedEntry(
                text:
                    '${seaZoneLabel(seaZoneId)} naval battle resolved! Outcome: $outcomeName!',
                onTap: navalCombatTapForSeaZone(seaZoneId),
              ),
            ct_models.AppDiplomacyChangeEvent(
              :final actorId,
              :final targetId,
              :final changeType,
            ) =>
              _diplomacyFeedEntry(
                counterpartFactionId(
                  actorId: actorId,
                  targetId: targetId,
                ),
                diplomacyOutcomeLine(
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
              PlayerTurnEventFeedEntry(text: orderRejectedLine(reasonCode)),
            ct_models.AppWorkOrderCompletedEvent(
              :final workTarget,
              :final targetTileKey,
              :final provinceId,
              :final unitId,
            ) =>
              _workOrderFeedEntry(
                unitId: unitId,
                targetTileKey: targetTileKey,
                text:
                    '${provinceLabel(provinceId)} work completed! ${workTargetLabel(workTarget)} finished!',
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
              _diplomacyFeedEntry(
                overtureCounterpartFactionId(
                  offererGpId: offererGpId,
                  targetFactionId: targetFactionId,
                ),
                'Overture advanced! ${factionLabel(offererGpId)} with ${factionLabel(targetFactionId)}: ${overtureStageLabel(newStage)}!',
              ),
            ct_models.AppSpyCaughtEvent(
              :final provinceId,
              :final spyOwnerId,
              :final territoryOwnerId,
            ) =>
              _diplomacyFeedEntry(
                spyCounterpartFactionId(
                  spyOwnerId: spyOwnerId,
                  territoryOwnerId: territoryOwnerId,
                ),
                mapPlayerId == territoryOwnerId
                    ? '${provinceLabel(provinceId)} — enemy spy from ${factionLabel(spyOwnerId)} caught and eliminated!'
                    : 'Spy caught in ${provinceLabel(provinceId)}! ${factionLabel(territoryOwnerId)} eliminated your agent!',
              ),
            ct_models.AppSpyDefectedEvent(
              :final provinceId,
              :final previousOwnerId,
              :final newOwnerId,
            ) =>
              _diplomacyFeedEntry(
                mapPlayerId == newOwnerId
                    ? previousOwnerId
                    : newOwnerId,
                mapPlayerId == newOwnerId
                    ? '${provinceLabel(provinceId)} — enemy spy from ${factionLabel(previousOwnerId)} defected to your side!'
                    : 'Spy defected in ${provinceLabel(provinceId)}! Agent joined ${factionLabel(newOwnerId)}!',
              ),
            _ => const PlayerTurnEventFeedEntry(text: 'Event resolved!'),
          };
        })
        .toList(growable: false);
  }

  PlayerTurnEventFeedEntry _feedEntry({
    required String text,
    void Function()? onTap,
  }) {
    return PlayerTurnEventFeedEntry(text: text, onTap: onTap);
  }

  PlayerTurnEventFeedEntry _diplomacyFeedEntry(
    String? factionId,
    String text,
  ) {
    final onTap = factionId == null
        ? null
        : diplomacyDetailTapForFaction(factionId);
    return PlayerTurnEventFeedEntry(
      text: text,
      linkAffordance: onTap != null,
      onTap: onTap,
    );
  }

  PlayerTurnEventFeedEntry _workOrderFeedEntry({
    required String unitId,
    required String targetTileKey,
    required String text,
  }) {
    final onTap = workOrderCompletedTap(
      unitId: unitId,
      targetTileKey: targetTileKey,
    );
    return PlayerTurnEventFeedEntry(
      text: text,
      linkAffordance: onTap != null,
      onTap: onTap,
    );
  }
}
