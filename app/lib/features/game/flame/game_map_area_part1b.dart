part of 'game_map_area.dart';

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

  @override
  void didUpdateWidget(covariant GameMapArea oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.game.id != widget.game.id) {
      ref.read(mapProvincePanelProvider.notifier).reset();
      ref.read(regionMinimapVisibleProvider.notifier).resetToDefault();
      setState(() {
        _refreshWorkTargetSelectionCache(widget.game);
        _mapViewState = widget.game.mapViewState;
        _regionViewportSnapshot = null;
        _pendingRegionViewport = null;
        _regionViewportFrameScheduled = false;
      });
    } else if (oldWidget.game.mapViewState != widget.game.mapViewState) {
      _mapViewState = widget.game.mapViewState;
    }
    if (oldWidget.game.worldState.turnState.turnNumber !=
        widget.game.worldState.turnState.turnNumber) {
      setState(() {
        _refreshWorkTargetSelectionCache(widget.game);
      });
    }
  }

  void _onRegionViewportSnapshot(RegionMapViewportSnapshot snapshot) {
    final clampedMultiplier = snapshot.zoomMultiplier.clamp(0.5, 8.0);
    if ((clampedMultiplier - _mapViewState.zoomMultiplier).abs() > 0.001) {
      _setMapViewState(
        _mapViewState.copyWith(zoomMultiplier: clampedMultiplier),
      );
    }
    _pendingRegionViewport = snapshot;
    if (_regionViewportFrameScheduled) return;
    _regionViewportFrameScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _regionViewportFrameScheduled = false;
      if (!mounted) return;
      final next = _pendingRegionViewport;
      _pendingRegionViewport = null;
      if (next == null) return;
      final cur = _regionViewportSnapshot;
      if (cur != null && cur.matches(next)) return;
      setState(() => _regionViewportSnapshot = next);
    });
  }
}
