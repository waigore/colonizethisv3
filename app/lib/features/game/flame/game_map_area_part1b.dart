part of 'game_map_area.dart';

extension _GameMapAreaStateTurnFeed on _GameMapAreaState {
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
                onTap: () {
                  final province = _provinceByPrefixedId(provinceId);
                  if (province == null) return;
                  final tileKey = tileKeyForProvinceLocation(
                    widget.game,
                    province,
                  );
                  if (tileKey == null) return;
                  ref
                      .read(appEventBusProvider)
                      .emit(
                        ct_models.LocateMapTileEvent(
                          tileKey: tileKey,
                          regionId: province.regionId,
                        ),
                      );
                },
              ),
            ct_models.AppProvinceCapturedEvent(
              :final provinceId,
              :final newOwnerId,
            ) =>
              PlayerTurnEventFeedEntry(
                text:
                    '${_provinceLabel(provinceId)} captured! ${_factionLabel(newOwnerId)} now controls it!',
                onTap: () {
                  final province = _provinceByPrefixedId(provinceId);
                  if (province == null) return;
                  final tileKey = tileKeyForProvinceLocation(
                    widget.game,
                    province,
                  );
                  if (tileKey == null) return;
                  ref
                      .read(appEventBusProvider)
                      .emit(
                        ct_models.LocateMapTileEvent(
                          tileKey: tileKey,
                          regionId: province.regionId,
                        ),
                      );
                },
              ),
            ct_models.AppNavalCombatResultEvent(
              :final seaZoneId,
              :final outcomeName,
            ) =>
              PlayerTurnEventFeedEntry(
                text:
                    '${_seaZoneLabel(seaZoneId)} naval battle resolved! Outcome: $outcomeName!',
                onTap: () {
                  final tileKey = _tileKeyForSeaZoneEvent(seaZoneId);
                  if (tileKey == null) {
                    return;
                  }
                  final regionId = ct_models.Unit.regionIdFromTileKey(tileKey);
                  if (regionId == null) {
                    return;
                  }
                  ref
                      .read(appEventBusProvider)
                      .emit(
                        ct_models.LocateMapTileEvent(
                          tileKey: tileKey,
                          regionId: regionId,
                        ),
                      );
                },
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
                onTap: () {
                  final regionId = ct_models.Unit.regionIdFromTileKey(
                    targetTileKey,
                  );
                  if (regionId == null) {
                    return;
                  }
                  ref
                      .read(appEventBusProvider)
                      .emit(
                        ct_models.LocateMapTileEvent(
                          tileKey: targetTileKey,
                          regionId: regionId,
                        ),
                      );
                },
              ),
            ct_models.AppPlayerProvinceDiscoveredEvent(:final provinceId) =>
              PlayerTurnEventFeedEntry(
                text: '${_provinceLabel(provinceId)} discovered!',
                onTap: () {
                  final province = _provinceByPrefixedId(provinceId);
                  if (province == null) return;
                  final tileKey = tileKeyForProvinceLocation(
                    widget.game,
                    province,
                  );
                  if (tileKey == null) return;
                  ref
                      .read(appEventBusProvider)
                      .emit(
                        ct_models.LocateMapTileEvent(
                          tileKey: tileKey,
                          regionId: province.regionId,
                        ),
                      );
                },
              ),
            ct_models.AppPlayerSeaZoneDiscoveredEvent(:final seaZoneId) =>
              PlayerTurnEventFeedEntry(
                text: '${_seaZoneLabel(seaZoneId)} discovered!',
                onTap: () {
                  final tileKey = _tileKeyForSeaZoneEvent(seaZoneId);
                  if (tileKey == null) {
                    return;
                  }
                  final regionId = ct_models.Unit.regionIdFromTileKey(tileKey);
                  if (regionId == null) {
                    return;
                  }
                  ref
                      .read(appEventBusProvider)
                      .emit(
                        ct_models.LocateMapTileEvent(
                          tileKey: tileKey,
                          regionId: regionId,
                        ),
                      );
                },
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
            _ => const PlayerTurnEventFeedEntry(text: 'Event resolved!'),
          };
        })
        .toList(growable: false);
  }
}
