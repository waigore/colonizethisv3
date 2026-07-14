// App event bus: typed, centralized stream for all app events.
// SPEC/program/app-event-bus.md.
//
// Usage:
//   // In your service/component:
//   eventBus.emit(MyEvent());
//
//   // In your widget/service that reacts:
//   eventBus.on<MyEvent>().listen((e) => handle(e));
//
// The bus is a broadcast stream so multiple listeners can coexist.

import 'dart:async';

import 'app_events.dart';
import 'stream_where_type.dart';

class AppEventBus {
  AppEventBus._() : _controller = StreamController<AppEvent>.broadcast();

  /// Returns the singleton instance. In tests, prefer [create] for a fresh bus.
  factory AppEventBus() => _instance ??= AppEventBus._();

  /// Creates a fresh bus. Use in tests to avoid singleton interference.
  factory AppEventBus.create() => AppEventBus._();

  /// Resets the singleton. Call between test runs to avoid stale state.
  static void reset() => _instance = null;

  static AppEventBus? _instance;

  final StreamController<AppEvent> _controller;

  /// Delivery generation for session clear. Deferred handlers must discard work
  /// captured under an older generation. SPEC/program/save-load-session-clear.md.
  int _deliveryGeneration = 0;

  /// Current delivery generation (bumped by [dropUnconsumedEvents]).
  int get deliveryGeneration => _deliveryGeneration;

  /// Invalidates deferred/async deliveries from the prior session.
  void dropUnconsumedEvents() {
    _deliveryGeneration++;
  }

  void emit(AppEvent event) => _controller.add(event);

  Stream<AppEvent> get stream => _controller.stream;

  Stream<T> on<T extends AppEvent>() => _controller.stream.whereType<T>();

  Stream<UIActionEvent> get uiActionEvents => on<UIActionEvent>();

  Stream<SessionCommandEvent> get sessionCommandEvents =>
      on<SessionCommandEvent>();

  Stream<UISystemEvent> get uiSystemEvents => on<UISystemEvent>();

  Stream<GameToUIEvent> get gameToUIEvents => on<GameToUIEvent>();

  Stream<DialogueEvent> get dialogueEvents => on<DialogueEvent>();

  Stream<PortraitMoodEvent> get portraitMoodEvents => on<PortraitMoodEvent>();

  void dispose() => _controller.close();
}
