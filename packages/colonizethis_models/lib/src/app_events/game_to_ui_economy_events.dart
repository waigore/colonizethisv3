/// Economy mirror Game-to-UI events (Refs #4334 wave 3).
/// SPEC/program/game-event-bridge.md

import 'game_to_ui_event_base.dart';

/// Overseas-profit treasury credited. Mirrors colonizethis_logic OverseasProfitCreditedEvent.
class AppOverseasProfitCreditedEvent extends GameToUIEvent {
  const AppOverseasProfitCreditedEvent({
    required this.playerId,
    required this.totalTreasuryCredit,
    required this.creditCount,
    required this.turnNumber,
  });
  final String playerId;
  final int totalTreasuryCredit;
  final int creditCount;
  final int turnNumber;
}

/// Last-turn ordinary market fill / carry-forward summary. Mirrors
/// [MarketTurnSummaryEvent] (Refs #4270).
class AppMarketTurnSummaryEvent extends GameToUIEvent {
  const AppMarketTurnSummaryEvent({
    required this.playerId,
    required this.totalSpent,
    required this.totalReceived,
    required this.carryForwardOrderCount,
    required this.turnNumber,
  });
  final String playerId;
  final int totalSpent;
  final int totalReceived;
  final int carryForwardOrderCount;
  final int turnNumber;
}

/// Last-turn treasury and stockpile net change. Mirrors
/// [EconomyTurnSummaryEvent] (Refs #4308).
class AppEconomyTurnSummaryEvent extends GameToUIEvent {
  const AppEconomyTurnSummaryEvent({
    required this.playerId,
    required this.treasuryDelta,
    required this.stockpileDeltas,
    required this.turnNumber,
  });
  final String playerId;
  final int treasuryDelta;
  final Map<String, int> stockpileDeltas;
  final int turnNumber;
}
