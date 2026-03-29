import 'dart:async';

import 'package:colonizethis_logger/colonizethis_logger.dart';

import '../game_events.dart';

/// Max length for the payload summary segment in [deliverGameEvent] log lines.
/// SPEC/program/logging/events.md — truncate with `…` and `truncated=true` when exceeded.
const int kGameEventLogSummaryMaxChars = 500;

final _gameEventLog = logicLogger();

String _gameEventPayloadSummary(GameEvent event) {
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
  };
}

void _logGameEventDelivery(GameEvent event) {
  final typeName = event.runtimeType.toString();
  var summary = _gameEventPayloadSummary(event);
  var truncated = false;
  if (summary.length > kGameEventLogSummaryMaxChars) {
    summary = '${summary.substring(0, kGameEventLogSummaryMaxChars)}…';
    truncated = true;
  }
  final suffix = truncated ? ' truncated=true' : '';
  _gameEventLog.i('event=$typeName $summary$suffix');
}

/// Delivers [event] to [eventBus] and/or [onGameEvent], logging once per SPEC/program/logging/events.md.
void deliverGameEvent(
  GameEvent event, {
  GameEventBus? eventBus,
  void Function(GameEvent)? onGameEvent,
}) {
  if (eventBus != null) {
    eventBus.publish(event);
  } else {
    _logGameEventDelivery(event);
  }
  onGameEvent?.call(event);
}

abstract class GameEventBus {
  void publish(GameEvent event);

  Stream<GameEvent> get events;

  void Function() subscribe<T extends GameEvent>(void Function(T) handler);
}

class DefaultGameEventBus implements GameEventBus {
  final _controller = StreamController<GameEvent>.broadcast();

  @override
  void publish(GameEvent event) {
    _logGameEventDelivery(event);
    _controller.add(event);
  }

  @override
  Stream<GameEvent> get events => _controller.stream;

  @override
  void Function() subscribe<T extends GameEvent>(void Function(T) handler) {
    late final StreamSubscription<GameEvent> sub;
    sub = _controller.stream.where((e) => e is T).cast<T>().listen(handler);
    return () => sub.cancel();
  }

  void dispose() {
    _controller.close();
  }
}
