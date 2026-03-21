// Tests for AppEventBus and event classes. SPEC/program/app-event-bus.md.

import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter_test/flutter_test.dart';

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
      await Future.delayed(Duration.zero);
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
      await Future.delayed(Duration.zero);

      expect(dialogEvents, hasLength(2));
      expect(navEvents, hasLength(1));
    });

    test('multiple listeners all receive events', () async {
      final listener1 = <AppEvent>[];
      final listener2 = <AppEvent>[];

      bus.on<AppEvent>().listen(listener1.add);
      bus.on<AppEvent>().listen(listener2.add);

      bus.emit(const PopNavigationEvent());
      await Future.delayed(Duration.zero);

      expect(listener1, hasLength(1));
      expect(listener2, hasLength(1));
    });

    test('dispose prevents further events', () async {
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
      await Future.delayed(Duration.zero);

      expect(uiActions, hasLength(1));
      expect(uiSystem, hasLength(1));
    });

    test('dialogueEvents filters DialogueEvent', () async {
      final events = <DialogueEvent>[];
      bus.dialogueEvents.listen(events.add);

      bus.emit(const OpenDialogEvent('test'));
      await Future.delayed(Duration.zero);
      expect(events, isEmpty);

      bus.emit(
        const DialogueEvent(
          leaderId: 'gp1',
          category: 'war',
          situation: 'battle_lost',
          era: 'early',
        ),
      );
      await Future.delayed(Duration.zero);
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
      await Future.delayed(Duration.zero);
      expect(events, hasLength(1));
    });
  });

  group('UIActionEvent equality', () {
    test('OpenDialogEvent equal for same id and params', () {
      expect(
        const OpenDialogEvent('settings', {'tab': 'audio'}),
        const OpenDialogEvent('settings', {'tab': 'audio'}),
      );
      expect(
        const OpenDialogEvent('settings', {'tab': 'audio'}),
        isNot(const OpenDialogEvent('settings', {'tab': 'video'})),
      );
      expect(
        const OpenDialogEvent('settings'),
        const OpenDialogEvent('settings'),
      );
    });

    test('ConfirmDialogEvent equal for same params', () {
      expect(
        const ConfirmDialogEvent(title: 'a', message: 'b'),
        const ConfirmDialogEvent(title: 'a', message: 'b'),
      );
    });

    test('NavigateToRouteEvent equal for same route and args', () {
      expect(
        const NavigateToRouteEvent('/game', {'key': 'value'}),
        const NavigateToRouteEvent('/game', {'key': 'value'}),
      );
    });

    test('OpenPanelEvent equal for same panelId and params', () {
      expect(
        const OpenPanelEvent('pause_menu', {'a': 1}),
        const OpenPanelEvent('pause_menu', {'a': 1}),
      );
    });

    test('OpenPauseMenuPanelEvent equal when both use null callbacks', () {
      expect(
        const OpenPauseMenuPanelEvent(),
        const OpenPauseMenuPanelEvent(),
      );
    });

    test('StartTargetSelectionEvent equal for same params', () {
      expect(
        const StartTargetSelectionEvent(unitId: 'u1', action: 'move'),
        const StartTargetSelectionEvent(unitId: 'u1', action: 'move'),
      );
    });
  });

  group('UISystemEvent equality', () {
    test('ShowSnackBarEvent equal for same params', () {
      expect(
        const ShowSnackBarEvent(message: 'saved'),
        const ShowSnackBarEvent(message: 'saved'),
      );
    });

    test('NotifyEvent equal for same params', () {
      expect(
        const NotifyEvent(
          title: 'Research',
          body: 'Complete',
          priority: NotifyPriority.high,
        ),
        const NotifyEvent(
          title: 'Research',
          body: 'Complete',
          priority: NotifyPriority.high,
        ),
      );
    });

    test('ShowOverlayEvent equal for same id and params', () {
      expect(
        const ShowOverlayEvent(overlayId: 'loading', params: {'spin': true}),
        const ShowOverlayEvent(overlayId: 'loading', params: {'spin': true}),
      );
    });
  });

  group('GameToUIEvent equality', () {
    test('TurnResolutionCompleteEvent equal for same fields', () {
      expect(
        const TurnResolutionCompleteEvent(gameId: 'g1', turnNumber: 5),
        const TurnResolutionCompleteEvent(gameId: 'g1', turnNumber: 5),
      );
      expect(
        const TurnResolutionCompleteEvent(gameId: 'g1', turnNumber: 5),
        isNot(const TurnResolutionCompleteEvent(gameId: 'g1', turnNumber: 6)),
      );
    });

    test('SaveGameCompleteEvent equal for same gameId', () {
      expect(
        const SaveGameCompleteEvent(gameId: 'game_123'),
        const SaveGameCompleteEvent(gameId: 'game_123'),
      );
    });

    test('NewGameCreatedEvent equal for same gameId', () {
      expect(
        const NewGameCreatedEvent(gameId: 'game_456'),
        const NewGameCreatedEvent(gameId: 'game_456'),
      );
    });
  });
}
