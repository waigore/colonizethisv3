import 'dart:async';

import 'package:colonizethis_models/stream_where_type.dart';

import 'package:colonizethis_world/src/game_events.dart';
import 'game_event_logger.dart';

const _defaultGameEventLogger = GameEventLogger();

/// Delivers [event] to [eventBus] and/or [onGameEvent], logging once per SPEC/program/logging/events.md.
void deliverGameEvent(
  GameEvent event, {
  GameEventBus? eventBus,
  void Function(GameEvent)? onGameEvent,
}) {
  if (eventBus != null) {
    eventBus.publish(event);
  } else {
    _defaultGameEventLogger.logDelivery(event);
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
    _defaultGameEventLogger.logDelivery(event);
    _controller.add(event);
  }

  @override
  Stream<GameEvent> get events => _controller.stream;

  @override
  void Function() subscribe<T extends GameEvent>(void Function(T) handler) {
    late final StreamSubscription<GameEvent> sub;
    sub = _controller.stream.whereType<T>().listen(handler);
    return () => sub.cancel();
  }

  void dispose() {
    _controller.close();
  }
}
