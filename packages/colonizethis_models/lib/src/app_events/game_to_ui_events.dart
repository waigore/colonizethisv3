part of '../app_events.dart';

// ---------------------------------------------------------------------------
// Game-to-UI bridge — emitted by services when game state changes.
// These are additional events beyond GameEvent (which lives in colonizethis_logic).
// ---------------------------------------------------------------------------

sealed class GameToUIEvent extends AppEvent {
  const GameToUIEvent();
}

/// Emitted when turn resolution completes; UI may refresh panels.
class TurnResolutionCompleteEvent extends GameToUIEvent {
  const TurnResolutionCompleteEvent({
    required this.gameId,
    required this.turnNumber,
    this.turnNewsDigest,
  });
  final String gameId;
  final int turnNumber;

  /// Prior-turn digest for the news dialog; null when victory was set this resolution.
  final TurnNewsDigest? turnNewsDigest;
}

/// Emitted when overture decisions are required; UI should show overture dialog.
class OvertureRequiredEvent extends GameToUIEvent {
  const OvertureRequiredEvent({required this.overtures});
  final List<Object> overtures; // OvertureOffer
}

/// Emitted when intervention choices are required (Diplomacy phase).
class InterventionRequiredEvent extends GameToUIEvent {
  const InterventionRequiredEvent({required this.prompts});
  final List<Object> prompts; // InterventionPrompt from colonizethis_logic
}

/// Emitted when human ally must accept or refuse call to arms after a GP war declaration.
class CallToArmsRequiredEvent extends GameToUIEvent {
  const CallToArmsRequiredEvent({required this.pending});

  /// [CallToArmsPending] from colonizethis_logic (kept as Object to avoid package cycle).
  final List<Object> pending;
}

/// Emitted when save/load completes.
class SaveGameCompleteEvent extends GameToUIEvent {
  const SaveGameCompleteEvent({required this.gameId});
  final String gameId;
}

/// Emitted when a new game is created.
class NewGameCreatedEvent extends GameToUIEvent {
  const NewGameCreatedEvent({required this.gameId});
  final String gameId;
}

// ---------------------------------------------------------------------------
// App-prefixed GameEvent mirrors — forwarded from logic layer via GameEventBridge.
// SPEC/program/game-event-bridge.md
// ---------------------------------------------------------------------------

/// Combat resolved in a province. Mirrors colonizethis_logic CombatResultEvent.
class AppCombatResultEvent extends GameToUIEvent {
  const AppCombatResultEvent({
    required this.provinceId,
    required this.attackerId,
    required this.defenderId,
    required this.winnerId,
    required this.turnNumber,
    this.casualties = const {},
  });
  final String provinceId;
  final String attackerId;
  final String defenderId;
  final String winnerId;
  final int turnNumber;
  final Map<String, int> casualties;
}

/// Naval battle resolved in a sea zone. Mirrors colonizethis_logic NavalCombatResultEvent.
class AppNavalCombatResultEvent extends GameToUIEvent {
  const AppNavalCombatResultEvent({
    required this.seaZoneId,
    required this.side1OwnerId,
    required this.side2OwnerId,
    required this.outcomeName,
    required this.turnNumber,
    this.winnerOwnerId,
    this.side1Retreated = false,
    this.side2Retreated = false,
  });
  final String seaZoneId;
  final String side1OwnerId;
  final String side2OwnerId;
  final String outcomeName;
  final int turnNumber;
  final String? winnerOwnerId;
  final bool side1Retreated;
  final bool side2Retreated;
}

/// Province ownership changed. Mirrors colonizethis_logic ProvinceCapturedEvent.
class AppProvinceCapturedEvent extends GameToUIEvent {
  const AppProvinceCapturedEvent({
    required this.provinceId,
    required this.previousOwnerId,
    required this.newOwnerId,
    required this.turnNumber,
  });
  final String provinceId;
  final String? previousOwnerId;
  final String newOwnerId;
  final int turnNumber;
}

/// Diplomatic relationship changed. Mirrors colonizethis_logic DiplomacyChangeEvent.
class AppDiplomacyChangeEvent extends GameToUIEvent {
  const AppDiplomacyChangeEvent({
    required this.actorId,
    required this.targetId,
    required this.changeType,
    required this.turnNumber,
  });
  final String actorId;
  final String targetId;
  final String changeType;
  final int turnNumber;
}

/// Technology research completed. Mirrors colonizethis_logic ResearchCompleteEvent.
class AppResearchCompleteEvent extends GameToUIEvent {
  const AppResearchCompleteEvent({
    required this.playerId,
    required this.techId,
    required this.turnNumber,
  });
  final String playerId;
  final String techId;
  final int turnNumber;
}

/// Victory condition set. Mirrors colonizethis_logic VictorySetEvent.
class AppVictorySetEvent extends GameToUIEvent {
  const AppVictorySetEvent({
    required this.winnerPlayerId,
    required this.victoryType,
    required this.turnNumber,
  });
  final String winnerPlayerId;
  final String victoryType;
  final int turnNumber;
}

/// Order rejected during validation. Mirrors colonizethis_logic OrderRejectedEvent.
class AppOrderRejectedEvent extends GameToUIEvent {
  const AppOrderRejectedEvent({
    required this.playerId,
    required this.orderSummary,
    required this.reasonCode,
  });
  final String playerId;
  final String orderSummary;
  final String reasonCode;
}

/// Civilian work order completed. Mirrors colonizethis_logic WorkOrderCompletedEvent.
class AppWorkOrderCompletedEvent extends GameToUIEvent {
  const AppWorkOrderCompletedEvent({
    required this.playerId,
    required this.unitId,
    required this.workTarget,
    required this.targetTileKey,
    required this.provinceId,
    required this.turnNumber,
  });
  final String playerId;
  final String unitId;
  final String workTarget;
  final String targetTileKey;
  final String provinceId;
  final int turnNumber;
}

/// Player-scoped province discovery. Mirrors colonizethis_logic PlayerProvinceDiscoveredEvent.
class AppPlayerProvinceDiscoveredEvent extends GameToUIEvent {
  const AppPlayerProvinceDiscoveredEvent({
    required this.playerId,
    required this.provinceId,
    required this.turnNumber,
  });
  final String playerId;
  final String provinceId;
  final int turnNumber;
}

/// Player-scoped sea-zone charting. Mirrors colonizethis_logic PlayerSeaZoneDiscoveredEvent.
class AppPlayerSeaZoneDiscoveredEvent extends GameToUIEvent {
  const AppPlayerSeaZoneDiscoveredEvent({
    required this.playerId,
    required this.seaZoneId,
    required this.turnNumber,
  });
  final String playerId;
  final String seaZoneId;
  final int turnNumber;
}

/// Overture stage advanced. Mirrors colonizethis_logic OvertureAdvancedEvent.
class AppOvertureAdvancedEvent extends GameToUIEvent {
  const AppOvertureAdvancedEvent({
    required this.offererGpId,
    required this.targetFactionId,
    required this.newStage,
    required this.turnNumber,
  });
  final String offererGpId;
  final String targetFactionId;
  final String newStage;
  final int turnNumber;
}

/// Spy killed in foreign territory. Mirrors colonizethis_logic SpyCaughtEvent.
class AppSpyCaughtEvent extends GameToUIEvent {
  const AppSpyCaughtEvent({
    required this.unitId,
    required this.spyOwnerId,
    required this.territoryOwnerId,
    required this.provinceId,
    required this.turnNumber,
  });
  final String unitId;
  final String spyOwnerId;
  final String territoryOwnerId;
  final String provinceId;
  final int turnNumber;
}

/// Spy defected to counter-espionage runner. Mirrors colonizethis_logic SpyDefectedEvent.
class AppSpyDefectedEvent extends GameToUIEvent {
  const AppSpyDefectedEvent({
    required this.unitId,
    required this.previousOwnerId,
    required this.newOwnerId,
    required this.provinceId,
    required this.turnNumber,
  });
  final String unitId;
  final String previousOwnerId;
  final String newOwnerId;
  final String provinceId;
  final int turnNumber;
}
