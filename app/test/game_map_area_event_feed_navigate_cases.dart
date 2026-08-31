import 'package:colonizethis_app/config/routes.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';

import 'game_map_area_event_feed_harness_support.dart';

typedef EventFeedNavigateTapCase = ({
  String name,
  List<AppEvent> Function(EventFeedHarness harness) buildEvents,
  String lineMatch,
  String expectedRoute,
  String? expectedFactionId,
  bool expectChevron,
});

List<EventFeedNavigateTapCase> eventFeedDiplomacyDetailNavigateCases() => [
  (
    name: 'Player turn event feed diplomacy line opens diplomacy detail on tap',
    buildEvents: (h) => [
      AppDiplomacyChangeEvent(
        actorId: h.humanId,
        targetId: h.opponentId,
        changeType: 'declare_war',
        turnNumber: 1,
      ),
    ],
    lineMatch: 'declared war on',
    expectedRoute: Routes.diplomacyDetail,
    expectedFactionId: null,
    expectChevron: true,
  ),
  (
    name: 'Player turn event feed overture line opens diplomacy detail on tap',
    buildEvents: (h) => [
      AppOvertureAdvancedEvent(
        offererGpId: h.humanId,
        targetFactionId: h.opponentId,
        newStage: 'embassy',
        turnNumber: 1,
      ),
    ],
    lineMatch: 'Overture advanced!',
    expectedRoute: Routes.diplomacyDetail,
    expectedFactionId: null,
    expectChevron: true,
  ),
  (
    name: 'Player turn event feed spy caught line opens diplomacy detail on tap',
    buildEvents: (h) => [
      AppSpyCaughtEvent(
        unitId: 'spy_1',
        spyOwnerId: h.opponentId,
        territoryOwnerId: h.humanId,
        provinceId: 'oldWorld|cap',
        turnNumber: 1,
      ),
    ],
    lineMatch: 'enemy spy from',
    expectedRoute: Routes.diplomacyDetail,
    expectedFactionId: null,
    expectChevron: true,
  ),
  (
    name: 'Player turn event feed spy defected line opens diplomacy detail on tap',
    buildEvents: (h) => [
      AppSpyDefectedEvent(
        unitId: 'spy_1',
        previousOwnerId: h.opponentId,
        newOwnerId: h.humanId,
        provinceId: 'oldWorld|cap',
        turnNumber: 1,
      ),
    ],
    lineMatch: 'defected to your side',
    expectedRoute: Routes.diplomacyDetail,
    expectedFactionId: null,
    expectChevron: true,
  ),
];

typedef EventFeedRejectedOrderNavigateCase = ({
  String name,
  OrderKind orderKind,
  String orderSummary,
  String expectedRoute,
});

List<EventFeedRejectedOrderNavigateCase>
eventFeedRejectedOrderNavigateCases() => [
  (
    name:
        'Player turn event feed rejected research order opens technology on tap',
    orderKind: OrderKind.research,
    orderSummary: 'Research cotton',
    expectedRoute: Routes.technology,
  ),
  (
    name: 'Player turn event feed rejected trade order opens trade screen on tap',
    orderKind: OrderKind.trade,
    orderSummary: 'Buy grain',
    expectedRoute: Routes.trade,
  ),
];

Future<void> pumpEventFeedRejectedOrderNavigateCase(
  WidgetTester tester, {
  required Box<dynamic> gamesBox,
  required EventFeedRejectedOrderNavigateCase case_,
}) async {
  final harness = newEventFeedHarness(disposeBus: false);
  final navigateEvents = listenEventFeedNavigateEvents(harness);
  await pumpEventFeedMapArea(tester, gamesBox: gamesBox, harness: harness);
  await commitEventFeedTurnEvents(tester, harness, [
    AppOrderRejectedEvent(
      playerId: harness.humanId,
      orderKind: case_.orderKind,
      orderSummary: case_.orderSummary,
      reasonCode: 'insufficient_treasury',
    ),
  ], turnNumber: 2);
  final line = find.textContaining('Order rejected: insufficient treasury.');
  if (case_.orderKind == OrderKind.research) {
    expect(line, findsOneWidget);
    expect(find.byIcon(Icons.chevron_right), findsOneWidget);
  }
  await tester.tap(line);
  await tester.pump();
  expect(navigateEvents, hasLength(1));
  expect(navigateEvents.single.route, case_.expectedRoute);
}
