part of 'game_map_area.dart';

/// App-event-bus handlers for [GameMapArea]: filtering combat/diplomacy/
/// discovery/overture events to the viewing player and buffering them for the
/// turn-event feed, plus the turn-resolution-complete flush (Refs #3699 Theme
/// 3).
mixin _GameMapAreaEvents
    on ConsumerState<GameMapArea>, _GameMapAreaStateBase, _GameMapAreaSelection {
  void _onTurnResolutionCompleteEvent(
    ct_models.TurnResolutionCompleteEvent event,
  ) {
    if (event.gameId != widget.game.id || !mounted) {
      return;
    }
    setState(() {
      _refreshWorkTargetSelectionCache(widget.game);
      _resolvedPlayerTurnEvents = List<ct_models.GameToUIEvent>.from(
        _pendingPlayerTurnEvents,
      );
      _pendingPlayerTurnEvents.clear();
    });
  }

  void _onAppCombatResultEvent(ct_models.AppCombatResultEvent event) {
    if (event.attackerId != _mapPlayerId &&
        event.defenderId != _mapPlayerId) {
      return;
    }
    _pendingPlayerTurnEvents.add(event);
  }

  void _onAppNavalCombatResultEvent(ct_models.AppNavalCombatResultEvent event) {
    if (event.side1OwnerId != _mapPlayerId &&
        event.side2OwnerId != _mapPlayerId) {
      return;
    }
    _pendingPlayerTurnEvents.add(event);
  }

  void _onAppProvinceCapturedEvent(ct_models.AppProvinceCapturedEvent event) {
    if (event.previousOwnerId != _mapPlayerId &&
        event.newOwnerId != _mapPlayerId) {
      return;
    }
    _pendingPlayerTurnEvents.add(event);
  }

  void _onAppDiplomacyChangeEvent(ct_models.AppDiplomacyChangeEvent event) {
    if (event.actorId != _mapPlayerId && event.targetId != _mapPlayerId) {
      return;
    }
    _pendingPlayerTurnEvents.add(event);
  }

  void _onAppResearchCompleteEvent(ct_models.AppResearchCompleteEvent event) {
    if (event.playerId != _mapPlayerId) {
      return;
    }
    _pendingPlayerTurnEvents.add(event);
  }

  void _onAppOrderRejectedEvent(ct_models.AppOrderRejectedEvent event) {
    if (event.playerId != _mapPlayerId) {
      return;
    }
    _pendingPlayerTurnEvents.add(event);
  }

  void _onAppWorkOrderCompletedEvent(
    ct_models.AppWorkOrderCompletedEvent event,
  ) {
    if (event.playerId != _mapPlayerId) {
      return;
    }
    _pendingPlayerTurnEvents.add(event);
  }

  void _onAppPlayerProvinceDiscoveredEvent(
    ct_models.AppPlayerProvinceDiscoveredEvent event,
  ) {
    if (event.playerId != _mapPlayerId) {
      return;
    }
    _pendingPlayerTurnEvents.add(event);
  }

  void _onAppPlayerSeaZoneDiscoveredEvent(
    ct_models.AppPlayerSeaZoneDiscoveredEvent event,
  ) {
    if (event.playerId != _mapPlayerId) {
      return;
    }
    _pendingPlayerTurnEvents.add(event);
  }

  void _onAppOvertureAdvancedEvent(ct_models.AppOvertureAdvancedEvent event) {
    if (event.offererGpId != _mapPlayerId &&
        event.targetFactionId != _mapPlayerId) {
      return;
    }
    _pendingPlayerTurnEvents.add(event);
  }
}
