// Game events: shared event stream for game occurrences.
// SPEC/program/game-events.md

/// Base event type for game occurrences.
sealed class GameEvent {
  const GameEvent();
}

/// Combat resolved in a province.
class CombatResultEvent extends GameEvent {
  const CombatResultEvent({
    required this.provinceId,
    required this.attackerId,
    required this.defenderId,
    required this.winnerId,
    required this.turnNumber,
    this.casualties = const {},
  });

  /// Province id in prefixed form (regionId|localId).
  final String provinceId;
  final String attackerId;
  final String defenderId;
  final String winnerId;
  final int turnNumber;

  /// Casualties by player id.
  final Map<String, int> casualties;
}

/// Naval battle resolved in a sea zone. SPEC/program/game-events.md.
class NavalCombatResultEvent extends GameEvent {
  const NavalCombatResultEvent({
    required this.seaZoneId,
    required this.side1OwnerId,
    required this.side2OwnerId,
    required this.outcomeName,
    required this.turnNumber,
    this.winnerOwnerId,
    this.side1Retreated = false,
    this.side2Retreated = false,
  });

  /// Sea zone local id (e.g. s3).
  final String seaZoneId;
  final String side1OwnerId;
  final String side2OwnerId;

  /// [NavalBattleOutcome] `.name` from resolver.
  final String outcomeName;
  final int turnNumber;

  /// Set when [outcomeName] is a decisive victory for one side.
  final String? winnerOwnerId;
  final bool side1Retreated;
  final bool side2Retreated;
}

/// Province ownership changed (faction-to-faction handover).
///
/// When emitted from turn resolution (`emitProvinceCapturedEvents`),
/// [previousOwnerId] and [newOwnerId] are both non-empty faction ids.
/// See SPEC/game/world-model.md.
class ProvinceCapturedEvent extends GameEvent {
  const ProvinceCapturedEvent({
    required this.provinceId,
    required this.previousOwnerId,
    required this.newOwnerId,
    required this.turnNumber,
  });

  /// Province id in prefixed form (regionId|localId).
  final String provinceId;

  /// Non-empty prior owner when emitted from turn resolution.
  final String? previousOwnerId;

  /// Non-empty new owner when emitted from turn resolution.
  final String newOwnerId;
  final int turnNumber;
}

/// Diplomatic relationship changed.
class DiplomacyChangeEvent extends GameEvent {
  const DiplomacyChangeEvent({
    required this.actorId,
    required this.targetId,
    required this.changeType,
    required this.turnNumber,
  });

  final String actorId;
  final String targetId;
  final String changeType; // 'declare_war', 'peace', 'alliance', etc.
  final int turnNumber;
}

/// Technology research completed.
class ResearchCompleteEvent extends GameEvent {
  const ResearchCompleteEvent({
    required this.playerId,
    required this.techId,
    required this.turnNumber,
  });

  final String playerId;
  final String techId;
  final int turnNumber;
}

/// Victory condition met.
class VictorySetEvent extends GameEvent {
  const VictorySetEvent({
    required this.winnerPlayerId,
    required this.victoryType,
    required this.turnNumber,
  });

  final String winnerPlayerId;
  final String victoryType;
  final int turnNumber;
}

/// Order validation failed.
class OrderRejectedEvent extends GameEvent {
  const OrderRejectedEvent({
    required this.playerId,
    required this.orderSummary,
    required this.reasonCode,
  });

  final String playerId;
  final String orderSummary;
  final String
  reasonCode; // 'insufficient_treasury', 'invalid_destination', etc.
}

/// Civilian work order completed during Build/Work phase.
class WorkOrderCompletedEvent extends GameEvent {
  const WorkOrderCompletedEvent({
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

  /// Prefixed province id (`regionId|localId`) derived from target tile.
  final String provinceId;
  final int turnNumber;
}

/// First province discovery for a specific player in this resolved turn.
class PlayerProvinceDiscoveredEvent extends GameEvent {
  const PlayerProvinceDiscoveredEvent({
    required this.playerId,
    required this.provinceId,
    required this.turnNumber,
  });

  final String playerId;

  /// Prefixed province id (`regionId|localId`).
  final String provinceId;
  final int turnNumber;
}

/// First sea-zone charting for a specific player in this resolved turn.
class PlayerSeaZoneDiscoveredEvent extends GameEvent {
  const PlayerSeaZoneDiscoveredEvent({
    required this.playerId,
    required this.seaZoneId,
    required this.turnNumber,
  });

  final String playerId;

  /// Prefixed sea-zone id (`regionId|localSeaZoneId`).
  final String seaZoneId;
  final int turnNumber;
}

/// Overture stage advanced for a specific Great Power -> target pair.
class OvertureAdvancedEvent extends GameEvent {
  const OvertureAdvancedEvent({
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

/// Spy killed in foreign territory during spy-resolution sub-step. Refs #3834 R9.
class SpyCaughtEvent extends GameEvent {
  const SpyCaughtEvent({
    required this.unitId,
    required this.spyOwnerId,
    required this.territoryOwnerId,
    required this.provinceId,
    required this.turnNumber,
  });

  final String unitId;
  final String spyOwnerId;
  final String territoryOwnerId;

  /// Prefixed province id (`regionId|localId`).
  final String provinceId;
  final int turnNumber;
}

/// Enemy spy defected to counter-espionage runner during spy-resolution. Refs #3834 R9.
class SpyDefectedEvent extends GameEvent {
  const SpyDefectedEvent({
    required this.unitId,
    required this.previousOwnerId,
    required this.newOwnerId,
    required this.provinceId,
    required this.turnNumber,
  });

  final String unitId;
  final String previousOwnerId;
  final String newOwnerId;

  /// Prefixed province id (`regionId|localId`).
  final String provinceId;
  final int turnNumber;
}
