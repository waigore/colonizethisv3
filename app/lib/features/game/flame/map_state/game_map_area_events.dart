
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:colonizethis_models/colonizethis_models.dart' as ct_models;


import 'game_map_area.dart';
import 'game_map_area_state_base.dart';
import 'game_map_area_selection.dart';

/// App-event-bus handlers for [GameMapArea]: filtering combat/diplomacy/
/// discovery/overture events to the viewing player and buffering them for the
/// turn-event feed, plus the turn-resolution-complete flush (Refs #3699 Theme
/// 3).
mixin GameMapAreaEvents
    on ConsumerState<GameMapArea>, GameMapAreaStateBase, GameMapAreaSelection {
  void onTurnResolutionCompleteEvent(
    ct_models.TurnResolutionCompleteEvent event,
  ) {
    if (event.gameId != widget.game.id || !mounted) {
      return;
    }
    setState(() {
      refreshWorkTargetSelectionCache(widget.game);
      resolvedPlayerTurnEvents = List<ct_models.GameToUIEvent>.from(
        pendingPlayerTurnEvents,
      );
      pendingPlayerTurnEvents.clear();
    });
  }

  void onAppCombatResultEvent(ct_models.AppCombatResultEvent event) {
    if (event.attackerId != mapPlayerId &&
        event.defenderId != mapPlayerId) {
      return;
    }
    pendingPlayerTurnEvents.add(event);
  }

  void onAppNavalCombatResultEvent(ct_models.AppNavalCombatResultEvent event) {
    if (event.side1OwnerId != mapPlayerId &&
        event.side2OwnerId != mapPlayerId) {
      return;
    }
    pendingPlayerTurnEvents.add(event);
  }

  void onAppProvinceCapturedEvent(ct_models.AppProvinceCapturedEvent event) {
    if (event.previousOwnerId != mapPlayerId &&
        event.newOwnerId != mapPlayerId) {
      return;
    }
    pendingPlayerTurnEvents.add(event);
  }

  void onAppDiplomacyChangeEvent(ct_models.AppDiplomacyChangeEvent event) {
    if (event.actorId != mapPlayerId && event.targetId != mapPlayerId) {
      return;
    }
    pendingPlayerTurnEvents.add(event);
  }

  void onAppResearchCompleteEvent(ct_models.AppResearchCompleteEvent event) {
    if (event.playerId != mapPlayerId) {
      return;
    }
    pendingPlayerTurnEvents.add(event);
  }

  void onAppOrderRejectedEvent(ct_models.AppOrderRejectedEvent event) {
    if (event.playerId != mapPlayerId) {
      return;
    }
    pendingPlayerTurnEvents.add(event);
  }

  void onAppWorkOrderCompletedEvent(
    ct_models.AppWorkOrderCompletedEvent event,
  ) {
    if (event.playerId != mapPlayerId) {
      return;
    }
    pendingPlayerTurnEvents.add(event);
  }

  void onAppOverseasProfitCreditedEvent(
    ct_models.AppOverseasProfitCreditedEvent event,
  ) {
    if (event.playerId != mapPlayerId) {
      return;
    }
    pendingPlayerTurnEvents.add(event);
  }

  void onAppMarketTurnSummaryEvent(
    ct_models.AppMarketTurnSummaryEvent event,
  ) {
    if (event.playerId != mapPlayerId) {
      return;
    }
    pendingPlayerTurnEvents.add(event);
  }

  void onAppPlayerProvinceDiscoveredEvent(
    ct_models.AppPlayerProvinceDiscoveredEvent event,
  ) {
    if (event.playerId != mapPlayerId) {
      return;
    }
    pendingPlayerTurnEvents.add(event);
  }

  void onAppPlayerSeaZoneDiscoveredEvent(
    ct_models.AppPlayerSeaZoneDiscoveredEvent event,
  ) {
    if (event.playerId != mapPlayerId) {
      return;
    }
    pendingPlayerTurnEvents.add(event);
  }

  void onAppOvertureAdvancedEvent(ct_models.AppOvertureAdvancedEvent event) {
    if (event.offererGpId != mapPlayerId &&
        event.targetFactionId != mapPlayerId) {
      return;
    }
    pendingPlayerTurnEvents.add(event);
  }

  void onAppSpyCaughtEvent(ct_models.AppSpyCaughtEvent event) {
    if (event.spyOwnerId != mapPlayerId &&
        event.territoryOwnerId != mapPlayerId) {
      return;
    }
    pendingPlayerTurnEvents.add(event);
  }

  void onAppSpyDefectedEvent(ct_models.AppSpyDefectedEvent event) {
    if (event.previousOwnerId != mapPlayerId &&
        event.newOwnerId != mapPlayerId) {
      return;
    }
    pendingPlayerTurnEvents.add(event);
  }

  void onAppGeneralMedalGainedEvent(
    ct_models.AppGeneralMedalGainedEvent event,
  ) {
    if (event.playerId != mapPlayerId) {
      return;
    }
    pendingPlayerTurnEvents.add(event);
  }
}
