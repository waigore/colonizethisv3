import 'dart:async';
import 'package:colonizethis_test/test.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

void main() {
  group('AppEventBus', () {
    tearDown(AppEventBus.reset);

    test('singleton factory returns the same instance', () {
      final a = AppEventBus();
      final b = AppEventBus();
      expect(identical(a, b), isTrue);
      AppEventBus.reset();
      expect(identical(AppEventBus(), a), isFalse);
    });

    test('dropUnconsumedEvents bumps delivery generation', () {
      final bus = AppEventBus.create();
      expect(bus.deliveryGeneration, 0);
      bus.dropUnconsumedEvents();
      expect(bus.deliveryGeneration, 1);
      bus.dropUnconsumedEvents();
      expect(bus.deliveryGeneration, 2);
      bus.dispose();
    });

    test('on<T> filters the broadcast stream by event type', () async {
      final bus = AppEventBus.create();
      final actions = <UIActionEvent>[];
      final system = <UISystemEvent>[];
      final subA = bus.uiActionEvents.listen(actions.add);
      final subS = bus.uiSystemEvents.listen(system.add);

      bus.emit(const ClosePanelEvent());
      bus.emit(const ShowSnackBarEvent(message: 'hi'));
      bus.emit(const PopNavigationEvent());

      await Future<void>.delayed(Duration.zero);

      expect(actions, hasLength(2));
      expect(actions.whereType<ClosePanelEvent>(), hasLength(1));
      expect(system, hasLength(1));
      expect(system.single, isA<ShowSnackBarEvent>());

      await subA.cancel();
      await subS.cancel();
      bus.dispose();
    });

    test('typed accessors expose category sub-streams', () async {
      final bus = AppEventBus.create();
      final sessionEvents = <SessionCommandEvent>[];
      final gameEvents = <GameToUIEvent>[];
      final dialogueEvents = <DialogueEvent>[];
      final moodEvents = <PortraitMoodEvent>[];
      final subSession = bus.sessionCommandEvents.listen(sessionEvents.add);
      final subGame = bus.gameToUIEvents.listen(gameEvents.add);
      final subDialogue = bus.dialogueEvents.listen(dialogueEvents.add);
      final subMood = bus.portraitMoodEvents.listen(moodEvents.add);

      bus.emit(CancelInProgressCivilianWorkRequestedEvent(unitId: 'u1'));
      bus.emit(const SaveGameCompleteEvent(gameId: 'g1'));
      bus.emit(
        const DialogueEvent(
          leaderId: 'victoria',
          category: 'greeting',
          situation: 'meet',
          era: 'industrial',
        ),
      );
      bus.emit(
        const PortraitMoodEvent(
          leaderId: 'victoria',
          fromMood: 'neutral',
          toMood: 'pleased',
        ),
      );

      await Future<void>.delayed(Duration.zero);

      expect(sessionEvents, hasLength(1));
      expect(gameEvents, hasLength(1));
      expect(dialogueEvents, hasLength(1));
      expect(moodEvents, hasLength(1));

      await subSession.cancel();
      await subGame.cancel();
      await subDialogue.cancel();
      await subMood.cancel();
      bus.dispose();
    });
  });

  group('DialogueEvent', () {
    test('toJson omits empty optionals and round-trips', () {
      const event = DialogueEvent(
        leaderId: 'napoleon',
        category: 'taunt',
        situation: 'war',
        era: 'napoleonic',
      );
      final json = event.toJson();
      expect(json.containsKey('mood'), isFalse);
      expect(json.containsKey('variables'), isFalse);

      final restored = DialogueEvent.fromJson(json);
      expect(restored.leaderId, 'napoleon');
      expect(restored.category, 'taunt');
      expect(restored.situation, 'war');
      expect(restored.era, 'napoleonic');
      expect(restored.mood, isNull);
      expect(restored.variables, isEmpty);
    });

    test('toJson/fromJson round-trips mood and variables', () {
      const event = DialogueEvent(
        leaderId: 'victoria',
        category: 'greeting',
        situation: 'peace',
        era: 'industrial',
        mood: 'pleased',
        variables: {'rival': 'France'},
      );
      final restored = DialogueEvent.fromJson(event.toJson());
      expect(restored.mood, 'pleased');
      expect(restored.variables, {'rival': 'France'});
    });
  });

  group('PortraitMoodEvent', () {
    test('toJson/fromJson round-trips all fields', () {
      const event = PortraitMoodEvent(
        leaderId: 'victoria',
        fromMood: 'neutral',
        toMood: 'angry',
        durationMs: 800,
      );
      final restored = PortraitMoodEvent.fromJson(event.toJson());
      expect(restored.leaderId, 'victoria');
      expect(restored.fromMood, 'neutral');
      expect(restored.toMood, 'angry');
      expect(restored.durationMs, 800);
    });

    test('fromJson defaults durationMs to zero', () {
      final restored = PortraitMoodEvent.fromJson({
        'leaderId': 'v',
        'fromMood': 'a',
        'toMood': 'b',
      });
      expect(restored.durationMs, 0);
    });
  });

  group('DefaultDialogueEventBus', () {
    test(
      'publish delivers to subscribers and unsubscribe stops delivery',
      () async {
        final bus = DefaultDialogueEventBus();
        final received = <DialogueEvent>[];
        final unsubscribe = bus.subscribe<DialogueEvent>(received.add);

        bus.publish(
          const DialogueEvent(
            leaderId: 'v',
            category: 'c',
            situation: 's',
            era: 'e',
          ),
        );
        await Future<void>.delayed(Duration.zero);
        expect(received, hasLength(1));

        unsubscribe();
        bus.publish(
          const DialogueEvent(
            leaderId: 'v2',
            category: 'c',
            situation: 's',
            era: 'e',
          ),
        );
        await Future<void>.delayed(Duration.zero);
        expect(received, hasLength(1));

        bus.dispose();
      },
    );

    test('events stream exposes published events', () async {
      final bus = DefaultDialogueEventBus();
      final future = bus.events.first;
      bus.publish(
        const DialogueEvent(
          leaderId: 'leader',
          category: 'c',
          situation: 's',
          era: 'e',
        ),
      );
      final event = await future;
      expect(event.leaderId, 'leader');
      bus.dispose();
    });
  });
}
