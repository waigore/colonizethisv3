import 'dart:async';

import '../ai_events.dart';
import '../stream_where_type.dart';

abstract class DialogueEventBus {
  void publish(DialogueEvent event);

  Stream<DialogueEvent> get events;

  void Function() subscribe<T extends DialogueEvent>(void Function(T) handler);
}

class DefaultDialogueEventBus implements DialogueEventBus {
  final _controller = StreamController<DialogueEvent>.broadcast();

  @override
  void publish(DialogueEvent event) {
    _controller.add(event);
  }

  @override
  Stream<DialogueEvent> get events => _controller.stream;

  @override
  void Function() subscribe<T extends DialogueEvent>(void Function(T) handler) {
    late final StreamSubscription<DialogueEvent> sub;
    sub = _controller.stream.whereType<T>().listen(handler);
    return () => sub.cancel();
  }

  void dispose() {
    _controller.close();
  }
}
