// Research-complete event feed widget tests (Refs #4724).
// Split from game_map_area_event_feed_test.dart for app/test 300-line cap.

import 'package:colonizethis_app/config/routes.dart';
import 'package:colonizethis_app/features/game/widgets/technology/tech_effect_summary.dart';
import 'package:colonizethis_app_l10n/l10n/app_localizations_en.dart';
import 'package:colonizethis_data/colonizethis_data.dart'
    show kTechIdCopperAndTinMining, kTechIdCropRotation, techById;
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';

import 'app_test_hive_harness.dart';
import 'game_map_area_event_feed_test_fixtures.dart';
import 'game_map_area_event_feed_toggle_support.dart';

void main() {
  suppressLogsForTests();

  late Box<dynamic> gamesBox;

  setUpAll(() async {
    gamesBox = await openAppTestHiveBox(suiteId: 'game_map_area_research');
  });

  testWidgets('Player turn event feed commits batch on turn complete', (
    WidgetTester tester,
  ) async {
    final harness = newEventFeedHarness();
    await pumpEventFeedMapArea(tester, gamesBox: gamesBox, harness: harness);
    await commitEventFeedTurnEvents(tester, harness, [
      AppResearchCompleteEvent(
        playerId: harness.humanId,
        techId: kTechIdCropRotation,
        turnNumber: 1,
      ),
    ], turnNumber: 2);

    expect(
      find.text(expectedCropRotationResearchCompleteLine()),
      findsOneWidget,
    );
    expect(find.textContaining(kTechIdCropRotation), findsNothing);
    expect(find.byIcon(Icons.chevron_right), findsOneWidget);
  });

  testWidgets(
    'Player turn event feed research line caps at two effect clauses',
    (WidgetTester tester) async {
      final harness = newEventFeedHarness();
      final l10n = AppLocalizationsEn();
      final effects = buildTechEffectSummaryLines(
        l10n,
        techById(kTechIdCopperAndTinMining)!,
      );
      expect(effects.length, greaterThan(2));
      final expected = formatResearchCompleteFeedLine(
        l10n,
        kTechIdCopperAndTinMining,
      );

      await pumpEventFeedMapArea(tester, gamesBox: gamesBox, harness: harness);
      await commitEventFeedTurnEvents(tester, harness, [
        AppResearchCompleteEvent(
          playerId: harness.humanId,
          techId: kTechIdCopperAndTinMining,
          turnNumber: 1,
        ),
      ], turnNumber: 2);

      expect(find.text(expected), findsOneWidget);
      expect(find.textContaining(effects[2]), findsNothing);
      expect(find.textContaining(kTechIdCopperAndTinMining), findsNothing);
    },
  );

  testWidgets(
    'Player turn event feed research line emits NavigateToRouteEvent on tap',
    (WidgetTester tester) async {
      final harness = newEventFeedHarness(disposeBus: false);
      final navigateEvents = listenEventFeedNavigateEvents(harness);

      await pumpEventFeedMapArea(tester, gamesBox: gamesBox, harness: harness);
      await commitEventFeedTurnEvents(tester, harness, [
        AppResearchCompleteEvent(
          playerId: harness.humanId,
          techId: kTechIdCropRotation,
          turnNumber: 1,
        ),
      ], turnNumber: 2);

      final researchLine = find.text(
        expectedCropRotationResearchCompleteLine(),
      );
      expect(researchLine, findsOneWidget);
      await tester.tap(researchLine);
      await tester.pump();

      expect(navigateEvents, hasLength(1));
      expect(navigateEvents.single.route, Routes.technology);
      final args = navigateEvents.single.arguments as Map<String, Object?>;
      expect(args['humanPlayerId'], harness.humanId);
    },
  );

  testWidgets(
    'Player turn event feed unknown research tech is non-tappable',
    (WidgetTester tester) async {
      final harness = newEventFeedHarness(disposeBus: false);
      final navigateEvents = listenEventFeedNavigateEvents(harness);

      await pumpEventFeedMapArea(tester, gamesBox: gamesBox, harness: harness);
      await commitEventFeedTurnEvents(tester, harness, [
        AppResearchCompleteEvent(
          playerId: harness.humanId,
          techId: 'agri_1',
          turnNumber: 1,
        ),
      ], turnNumber: 2);

      const fallbackLine = kResearchCompleteUnknownFallback;
      expect(find.text(fallbackLine), findsOneWidget);
      expect(find.textContaining('agri_1'), findsNothing);
      expect(find.byIcon(Icons.chevron_right), findsNothing);

      await tester.tap(find.text(fallbackLine));
      await tester.pump();
      expect(navigateEvents, isEmpty);
    },
  );

  testWidgets(
    'Player turn event feed skips row formatting while hidden on rebuild',
    (WidgetTester tester) async {
      final harness = newEventFeedHarness();
      await pumpEventFeedMapArea(tester, gamesBox: gamesBox, harness: harness);
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

      final researchLine = expectedCropRotationResearchCompleteLine();
      expect(find.textContaining(researchLine), findsNothing);
      expect(find.text('1'), findsOneWidget);

      for (var i = 0; i < 5; i++) {
        await tester.pump(const Duration(milliseconds: 16));
      }
      expect(find.textContaining(researchLine), findsNothing);
      expect(find.text('1'), findsOneWidget);
    },
  );
}
