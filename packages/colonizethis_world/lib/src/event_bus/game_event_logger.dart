import 'package:colonizethis_world/src/logging.dart';

import 'package:colonizethis_world/src/game_events.dart';

/// Max length for the payload summary segment in game-event delivery logs.
/// SPEC/program/logging/events.md — truncate with `…` and `truncated=true` when exceeded.
const int kGameEventLogSummaryMaxChars = 500;

class GameEventLogger {
  const GameEventLogger();

  void logDelivery(GameEvent event) {
    final typeName = event.runtimeType.toString();
    var summary = _payloadSummary(event);
    var truncated = false;
    if (summary.length > kGameEventLogSummaryMaxChars) {
      summary = '${summary.substring(0, kGameEventLogSummaryMaxChars)}…';
      truncated = true;
    }
    final suffix = truncated ? ' truncated=true' : '';
    worldLog.i('event=$typeName $summary$suffix');
  }

  String _payloadSummary(GameEvent event) {
    return switch (event) {
      CombatResultEvent e =>
        'turn=${e.turnNumber} provinceId=${e.provinceId} attackerId=${e.attackerId} '
            'defenderId=${e.defenderId} winnerId=${e.winnerId} '
            'casualtyEntries=${e.casualties.length}',
      NavalCombatResultEvent e =>
        'turn=${e.turnNumber} seaZoneId=${e.seaZoneId} outcome=${e.outcomeName} '
            'winnerOwnerId=${e.winnerOwnerId} side1=${e.side1OwnerId} side2=${e.side2OwnerId}',
      ProvinceCapturedEvent e =>
        'turn=${e.turnNumber} provinceId=${e.provinceId} previousOwnerId=${e.previousOwnerId} '
            'newOwnerId=${e.newOwnerId}',
      DiplomacyChangeEvent e =>
        'turn=${e.turnNumber} actorId=${e.actorId} targetId=${e.targetId} changeType=${e.changeType}',
      ResearchCompleteEvent e =>
        'turn=${e.turnNumber} playerId=${e.playerId} techId=${e.techId}',
      VictorySetEvent e =>
        'turn=${e.turnNumber} winnerPlayerId=${e.winnerPlayerId} victoryType=${e.victoryType}',
      OrderRejectedEvent e =>
        'playerId=${e.playerId} reasonCode=${e.reasonCode} orderSummary=${e.orderSummary}',
      WorkOrderCompletedEvent e =>
        'turn=${e.turnNumber} playerId=${e.playerId} unitId=${e.unitId} '
            'workTarget=${e.workTarget} targetTileKey=${e.targetTileKey} provinceId=${e.provinceId}',
      PlayerProvinceDiscoveredEvent e =>
        'turn=${e.turnNumber} playerId=${e.playerId} provinceId=${e.provinceId}',
      PlayerSeaZoneDiscoveredEvent e =>
        'turn=${e.turnNumber} playerId=${e.playerId} seaZoneId=${e.seaZoneId}',
      OvertureAdvancedEvent e =>
        'turn=${e.turnNumber} offererGpId=${e.offererGpId} targetFactionId=${e.targetFactionId} '
            'newStage=${e.newStage}',
    };
  }
}
