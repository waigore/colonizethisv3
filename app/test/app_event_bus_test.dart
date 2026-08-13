// Tests for AppEventBus and event classes. SPEC/program/app-event-bus.md.

import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter_test/flutter_test.dart';

import 'app_event_bus_equality_test_support.dart';

void main() {
  suppressLogsForTests();

  group('AppEventBus', () {
    late AppEventBus bus;

    setUp(() {
      AppEventBus.reset();
      bus = AppEventBus.create();
    });

    tearDown(() {
      bus.dispose();
    });

    test('emit delivers event to on<T> listener', () async {
      final events = <AppEvent>[];
      bus.on<AppEvent>().listen(events.add);
      bus.emit(const OpenDialogEvent('test'));
      await pumpEventQueue();
      expect(events, hasLength(1));
      expect(events.first, isA<OpenDialogEvent>());
    });

    test('on<T> only receives matching events', () async {
      final dialogEvents = <OpenDialogEvent>[];
      final navEvents = <NavigateToRouteEvent>[];
      bus.on<OpenDialogEvent>().listen(dialogEvents.add);
      bus.on<NavigateToRouteEvent>().listen(navEvents.add);

      bus.emit(const OpenDialogEvent('a'));
      bus.emit(const NavigateToRouteEvent('/home'));
      bus.emit(const OpenDialogEvent('b'));
      await pumpEventQueue();

      expect(dialogEvents, hasLength(2));
      expect(navEvents, hasLength(1));
    });

    test('multiple listeners all receive events', () async {
      final listener1 = <AppEvent>[];
      final listener2 = <AppEvent>[];

      bus.on<AppEvent>().listen(listener1.add);
      bus.on<AppEvent>().listen(listener2.add);

      bus.emit(const PopNavigationEvent());
      await pumpEventQueue();

      expect(listener1, hasLength(1));
      expect(listener2, hasLength(1));
    });

    test('dispose prevents further events', () {
      final events = <AppEvent>[];
      bus.on<AppEvent>().listen((e) => events.add(e));
      bus.dispose();
      expect(() => bus.emit(const ClosePanelEvent()), throwsStateError);
      expect(events, isEmpty);
    });

    test('convenience streams filter correctly', () async {
      final uiActions = <UIActionEvent>[];
      final uiSystem = <UISystemEvent>[];
      bus.on<UIActionEvent>().listen(uiActions.add);
      bus.on<UISystemEvent>().listen(uiSystem.add);

      bus.emit(const OpenDialogEvent('test'));
      bus.emit(const ShowSnackBarEvent(message: 'hello'));
      await pumpEventQueue();

      expect(uiActions, hasLength(1));
      expect(uiSystem, hasLength(1));
    });

    test('dialogueEvents filters DialogueEvent', () async {
      final events = <DialogueEvent>[];
      bus.dialogueEvents.listen(events.add);

      bus.emit(const OpenDialogEvent('test'));
      await pumpEventQueue();
      expect(events, isEmpty);

      bus.emit(
        const DialogueEvent(
          leaderId: 'gp1',
          category: 'war',
          situation: 'battle_lost',
          era: 'early',
        ),
      );
      await pumpEventQueue();
      expect(events, hasLength(1));
    });

    test('portraitMoodEvents filters PortraitMoodEvent', () async {
      final events = <PortraitMoodEvent>[];
      bus.portraitMoodEvents.listen(events.add);

      bus.emit(
        const PortraitMoodEvent(
          leaderId: 'gp1',
          fromMood: 'neutral',
          toMood: 'angry',
        ),
      );
      await pumpEventQueue();
      expect(events, hasLength(1));
    });
  });

  registerAppEventBusEqualityTests();
}
