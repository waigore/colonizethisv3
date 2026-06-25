part of 'game_map_area.dart';

/// Player turn-event feed for [GameMapArea]: turning resolved `GameToUIEvent`s
/// into tappable feed entries and resolving the faction/province/sea-zone
/// display labels they render (Refs #3699 Theme 3).
mixin _GameMapAreaTurnFeed on ConsumerState<GameMapArea>, _GameMapAreaStateBase {
  String _factionLabel(String id) =>
      widget.game.factionDisplayNameById(id) ?? id;

  String _provinceLabel(String fullProvinceId) =>
      widget.game.worldState.tryGetProvince(fullProvinceId)?.displayName ??
      fullProvinceId;

  String _seaZoneLabel(String seaZoneId) {
    return widget.game.worldState.seaZoneDisplayNameById[seaZoneId] ??
        seaZoneId;
  }

  String _diplomacyOutcomeLine({
    required String actorId,
    required String targetId,
    required String changeType,
  }) {
    final actor = _factionLabel(actorId);
    final target = _factionLabel(targetId);
    final normalized = changeType.toLowerCase();
    return switch (normalized) {
      'declare_war' => '$actor declared war on $target!',
      'peace' => '$actor and $target signed peace!',
      'alliance' => '$actor and $target formed an alliance!',
      'break_alliance' => '$actor and $target broke their alliance!',
      _ => '$actor and $target diplomacy changed! ${changeType.toUpperCase()}!',
    };
  }

  Set<String> _seaZoneRegionCandidates(String seaZoneId) {
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

  String? _tileKeyForSeaZoneEvent(String seaZoneId) {
    final candidates = _seaZoneRegionCandidates(seaZoneId);
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

  ct_models.Province? _provinceByPrefixedId(String prefixedProvinceId) =>
      widget.game.worldState.tryGetProvince(prefixedProvinceId);

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
