// Toggle/batch helpers for game_map_area_event_feed_test.dart (Refs #4680).

import 'package:colonizethis_app/features/game/screens/game/game_screen_shared.dart'
    show kPlayerTurnFeedToggleButtonKey;
import 'package:colonizethis_data/colonizethis_data.dart'
    show kTechIdCropRotation, techDisplayName;
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';

import 'game_map_area_event_feed_harness_support.dart';

Future<void> expectEventFeedToggleReplacesBatch(
  WidgetTester tester, {
  required Box<dynamic> gamesBox,
  required EventFeedHarness harness,
  required List<OpenCivilianUnitsPanelEvent> civilianEvents,
}) async {
  addTearDown(() async {
    await tester.binding.setSurfaceSize(null);
    harness.bus.dispose();
  });
  await pumpEventFeedMapArea(
    tester,
    gamesBox: gamesBox,
    harness: harness,
    mediaQuerySize: const Size(500, 900),
  );
  final researchLine =
      'Research complete: ${techDisplayName(kTechIdCropRotation)} unlocked';
  final researchFinder = find.textContaining(researchLine);

  await commitEventFeedTurnEvents(
    tester,
    harness,
    [
      AppResearchCompleteEvent(
        playerId: harness.humanId,
        techId: kTechIdCropRotation,
        turnNumber: 1,
      ),
    ],
    turnNumber: 2,
    openFeed: false,
  );

  expect(find.byKey(kPlayerTurnFeedToggleButtonKey), findsOneWidget);
  expect(find.text('1'), findsOneWidget);
  expect(researchFinder, findsNothing);
  expect(find.text('Events'), findsNothing);

  await openEventFeedToggle(tester);
  expect(researchFinder, findsOneWidget);
  expect(find.text('Events'), findsNothing);

  await openEventFeedToggle(tester);
  expect(researchFinder, findsNothing);

  await commitEventFeedTurnEvents(
    tester,
    harness,
    [
      AppOrderRejectedEvent(
        playerId: harness.humanId,
        orderKind: OrderKind.work,
        orderSummary: 'Build road',
        reasonCode: 'insufficient_treasury',
      ),
    ],
    turnNumber: 3,
    openFeed: false,
  );
  expect(researchFinder, findsNothing);
  await openEventFeedToggle(tester);
  expect(
    find.textContaining('Order rejected: insufficient treasury.'),
    findsOneWidget,
  );
  expect(find.byIcon(Icons.chevron_right), findsOneWidget);
  await tester.tap(
    find.textContaining('Order rejected: insufficient treasury.'),
  );
  await tester.pump();
  expect(civilianEvents, hasLength(1));
}
