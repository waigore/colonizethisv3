import 'dart:async';

import '../game_events.dart';

abstract class GameEventBus {
  void publish(GameEvent event);

  Stream<GameEvent> get events;

  void Function() subscribe<T extends GameEvent>(void Function(T) handler);
}

class DefaultGameEventBus implements GameEventBus {
  final _controller = StreamController<GameEvent>.broadcast();

  @override
  void publish(GameEvent event) {
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
