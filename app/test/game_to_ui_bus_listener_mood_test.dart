// Portrait mood forwarding for GameToUIBusListener (Refs #4734 Slice J).

import 'package:colonizethis_save/colonizethis_save.dart';
import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';

import 'app_test_hive_harness.dart';
import 'game_to_ui_bus_listener_test_support.dart';

void main() {
  suppressLogsForTests();

  late Box<dynamic> gamesBox;
  late GameSaveAdapter adapter;

  setUpAll(() async {
    gamesBox = await openAppTestHiveBox(suiteId: 'game_to_ui_mood');
    adapter = GameSaveAdapter();
  });

  testWidgets(
    'Given negotiation mood input When mood changes Then emits PortraitMoodEvent',
    (WidgetTester tester) async {
      final game = gameToUiOrdersGame(id: 'g_bus_mood_1');

      adapter.save(gamesBox, game);
      gameToUiSaveRequiredMapData(adapter, gamesBox, game.id);
      final bus = gameToUiCreateBus();

      final moodEvents = <PortraitMoodEvent>[];
      final moodSub = bus.portraitMoodEvents.listen(moodEvents.add);
      addTearDown(moodSub.cancel);

      await pumpGameToUiListener(
        tester,
        gamesBox: gamesBox,
        adapter: adapter,
        game: game,
        bus: bus,
      );

      bus.emit(
        const NegotiationMoodUpdateEvent(
          leaderId: 'ai1',
          currentMood: 'considering',
          offerQualityDelta: -0.8,
          stallCounter: 0,
          seed: 0,
          durationMs: 900,
        ),
      );
      await pumpGameToUiTwice(tester);

      expect(moodEvents, hasLength(1));
      expect(moodEvents.single.leaderId, 'ai1');
      expect(moodEvents.single.fromMood, 'considering');
      expect(moodEvents.single.toMood, anyOf('irritated', 'dismissive'));
      expect(moodEvents.single.durationMs, 900);
    },
  );

  testWidgets(
    'Given negotiation mood input When mood does not change Then emits no PortraitMoodEvent',
    (WidgetTester tester) async {
      final game = gameToUiOrdersGame(id: 'g_bus_mood_2');

      adapter.save(gamesBox, game);
      gameToUiSaveRequiredMapData(adapter, gamesBox, game.id);
      final bus = gameToUiCreateBus();

      final moodEvents = <PortraitMoodEvent>[];
      final moodSub = bus.portraitMoodEvents.listen(moodEvents.add);
      addTearDown(moodSub.cancel);

      await pumpGameToUiListener(
        tester,
        gamesBox: gamesBox,
        adapter: adapter,
        game: game,
        bus: bus,
      );

      bus.emit(
        const NegotiationMoodUpdateEvent(
          leaderId: 'ai1',
          currentMood: 'calculating',
          offerQualityDelta: 0.0,
          stallCounter: 2,
          seed: 1,
          durationMs: 900,
        ),
      );
      await pumpGameToUiTwice(tester);

      expect(moodEvents, isEmpty);
    },
  );
}
