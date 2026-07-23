part of 'game_map_area.dart';

/// Player turn-event feed for [GameMapArea]: turning resolved `GameToUIEvent`s
/// into tappable feed entries (Refs #3699 Theme 3).
mixin _GameMapAreaTurnFeed
    on
        ConsumerState<GameMapArea>,
        _GameMapAreaStateBase,
        _GameMapAreaTurnFeedLabels {
  List<PlayerTurnEventFeedEntry> _feedEntries() {
    return _resolvedPlayerTurnEvents
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
                    '${_provinceLabel(provinceId)} battle resolved! ${_factionLabel(winnerId)} defeated ${_factionLabel(winnerId == attackerId ? defenderId : attackerId)}!',
                onTap: () => _locateProvinceById(provinceId),
              ),
            ct_models.AppProvinceCapturedEvent(
              :final provinceId,
              :final newOwnerId,
            ) =>
              PlayerTurnEventFeedEntry(
                text:
                    '${_provinceLabel(provinceId)} captured! ${_factionLabel(newOwnerId)} now controls it!',
                onTap: () => _locateProvinceById(provinceId),
              ),
            ct_models.AppNavalCombatResultEvent(
              :final seaZoneId,
              :final outcomeName,
            ) =>
              PlayerTurnEventFeedEntry(
                text:
                    '${_seaZoneLabel(seaZoneId)} naval battle resolved! Outcome: $outcomeName!',
                onTap: () => _locateSeaZoneTile(seaZoneId),
              ),
            ct_models.AppDiplomacyChangeEvent(
              :final actorId,
              :final targetId,
              :final changeType,
            ) =>
              PlayerTurnEventFeedEntry(
                text: _diplomacyOutcomeLine(
                  actorId: actorId,
                  targetId: targetId,
                  changeType: changeType,
                ),
              ),
            ct_models.AppResearchCompleteEvent(:final techId) =>
              PlayerTurnEventFeedEntry(
                text: 'Research complete! $techId unlocked!',
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
                    '${_provinceLabel(provinceId)} work completed! ${workTarget.toUpperCase()} finished!',
                onTap: () => _locateTileKey(targetTileKey),
              ),
            ct_models.AppPlayerProvinceDiscoveredEvent(:final provinceId) =>
              PlayerTurnEventFeedEntry(
                text: '${_provinceLabel(provinceId)} discovered!',
                onTap: () => _locateProvinceById(provinceId),
              ),
            ct_models.AppPlayerSeaZoneDiscoveredEvent(:final seaZoneId) =>
              PlayerTurnEventFeedEntry(
                text: '${_seaZoneLabel(seaZoneId)} discovered!',
                onTap: () => _locateSeaZoneTile(seaZoneId),
              ),
            ct_models.AppOvertureAdvancedEvent(
              :final offererGpId,
              :final targetFactionId,
              :final newStage,
            ) =>
              PlayerTurnEventFeedEntry(
                text:
                    'Overture advanced! ${_factionLabel(offererGpId)} with ${_factionLabel(targetFactionId)}: ${newStage.toUpperCase()}!',
              ),
            ct_models.AppSpyCaughtEvent(
              :final provinceId,
              :final spyOwnerId,
              :final territoryOwnerId,
            ) =>
              PlayerTurnEventFeedEntry(
                text: _mapPlayerId == territoryOwnerId
                    ? '${_provinceLabel(provinceId)} — enemy spy from ${_factionLabel(spyOwnerId)} caught and eliminated!'
                    : 'Spy caught in ${_provinceLabel(provinceId)}! ${_factionLabel(territoryOwnerId)} eliminated your agent!',
                onTap: () => _locateProvinceById(provinceId),
              ),
            ct_models.AppSpyDefectedEvent(
              :final provinceId,
              :final previousOwnerId,
              :final newOwnerId,
            ) =>
              PlayerTurnEventFeedEntry(
                text: _mapPlayerId == newOwnerId
                    ? '${_provinceLabel(provinceId)} — enemy spy from ${_factionLabel(previousOwnerId)} defected to your side!'
                    : 'Spy defected in ${_provinceLabel(provinceId)}! Agent joined ${_factionLabel(newOwnerId)}!',
                onTap: () => _locateProvinceById(provinceId),
              ),
            _ => const PlayerTurnEventFeedEntry(text: 'Event resolved!'),
          };
        })
        .toList(growable: false);
  }
}
