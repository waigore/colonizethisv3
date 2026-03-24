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

/// Province ownership changed.
class ProvinceCapturedEvent extends GameEvent {
  const ProvinceCapturedEvent({
    required this.provinceId,
    required this.previousOwnerId,
    required this.newOwnerId,
    required this.turnNumber,
  });

  /// Province id in prefixed form (regionId|localId).
  final String provinceId;
  final String? previousOwnerId;
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
  final String reasonCode; // 'insufficient_treasury', 'invalid_destination', etc.
}