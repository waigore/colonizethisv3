import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:colonizethis_models/colonizethis_models.dart' as ct_models;

import '../../../../providers/game_service_provider.dart';
import 'game_map_area.dart';
import 'game_map_area_state_base.dart';
import 'game_map_area_selection.dart';
import 'game_map_area_last_turn_playback.dart';
import 'player_turn_event_feed_session_cache.dart';

/// App-event-bus handlers for [GameMapArea]: filtering combat/diplomacy/
/// discovery/overture events to the viewing player and buffering them for the
/// turn-event feed, plus the turn-resolution-complete flush (Refs #3699 Theme
/// 3).
mixin GameMapAreaEvents
    on
        ConsumerState<GameMapArea>,
        GameMapAreaStateBase,
        GameMapAreaSelection,
        GameMapAreaLastTurnPlayback {
  void onTurnResolutionCompleteEvent(
    ct_models.TurnResolutionCompleteEvent event,
  ) {
    if (event.gameId != widget.game.id || !mounted) {
      return;
    }
    setState(() {
      refreshMapSuggestionCaches(widget.game);
      resolvedPlayerTurnEvents = List<ct_models.GameToUIEvent>.from(
        pendingPlayerTurnEvents,
      );
      pendingPlayerTurnEvents.clear();
      playerTurnFeedCommittedTurnNumber = event.turnNumber;
    });
    final spyLineCount = _spyDigestLineCountForFeedBadge();
    PlayerTurnEventFeedSessionCache.invalidateForTurnCommit(
      gameId: widget.game.id,
      committedTurnNumber: event.turnNumber,
      badgeCount: resolvedPlayerTurnEvents.length + spyLineCount,
    );
    // Event emits before provider apply; load saved game for overlay/news
    // gates (same source as GameToUIBusListener news omit).
    final loaded = ref.read(gameServiceProvider).loadGame(event.gameId);
    final overlayWillShow =
        loaded?.victory != null || (loaded?.calendarCampaignHalted ?? false);
    final newsDialogWillShow =
        event.turnNumber >= 1 &&
        event.turnNewsDigest != null &&
        loaded?.victory == null;
    armLastTurnPlaybackAfterResolution(
      newsDialogWillShow: newsDialogWillShow,
      overlayWillShow: overlayWillShow,
    );
  }

  void onAppCombatResultEvent(ct_models.AppCombatResultEvent event) {
    if (event.attackerId != mapPlayerId && event.defenderId != mapPlayerId) {
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

  void onAppMarketTurnSummaryEvent(ct_models.AppMarketTurnSummaryEvent event) {
    if (event.playerId != mapPlayerId) {
      return;
    }
    pendingPlayerTurnEvents.add(event);
  }

  void onAppEconomyTurnSummaryEvent(
    ct_models.AppEconomyTurnSummaryEvent event,
  ) {
    if (event.playerId != mapPlayerId) {
      return;
    }
    if (event.treasuryDelta == 0 && event.stockpileDeltas.isEmpty) {
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

  int _spyDigestLineCountForFeedBadge() {
    final digest = widget.game.lastTurnIntelligenceDigest;
    if (digest == null) {
      return 0;
    }
    var count = 0;
    for (final block in digest.spyReportsFor(mapPlayerId)) {
      count += block.lines.length;
    }
    return count;
  }
}
