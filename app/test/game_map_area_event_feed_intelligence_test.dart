// OVL70001 spy-gated digest rows. SPEC/ui/intelligence-council.md.

import 'package:colonizethis_app/config/constants.dart';
import 'package:colonizethis_app/config/routes.dart';
import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';

import 'game_map_area_event_feed_test_fixtures.dart';
import 'map_view_test_fixtures.dart';
import 'panel_test_fixtures.dart';
import 'app_test_hive_harness.dart';

void main() {
  suppressLogsForTests();

  late Box<dynamic> gamesBox;

  setUpAll(() async {
    gamesBox = await openAppTestHiveBox(suiteId: 'game_map_area_intelligence');
  });

  testWidgets(
    'Given spy digest When feed opens Then spy row opens Intelligence',
    (WidgetTester tester) async {
      final harness = _intelligenceFeedHarness(
        disposeBus: false,
        digest: LastTurnIntelligenceDigest(
          resolvedTurnNumber: 1,
          spyReportsByObserverId: {
            kPanelTestHumanPlayerId: const [
              IntelligenceSpyCourtBlock(
                courtFactionId: 'gp2',
                lines: [
                  IntelligenceSpyLine(
                    kind: IntelligenceSpyKind.researchComplete,
                    techId: kTechIdCropRotation,
                    fromFactionId: 'gp2',
                  ),
                ],
              ),
            ],
          },
        ),
      );
      final navigateEvents = listenEventFeedNavigateEvents(harness);

      await pumpEventFeedMapArea(tester, gamesBox: gamesBox, harness: harness);
      await commitEventFeedTurnEvents(tester, harness, const [], turnNumber: 2);

      final line = find.textContaining('Our spy in Rival Power reports:');
      expect(line, findsOneWidget);
      expect(find.textContaining('Crop Rotation'), findsOneWidget);
      await tester.tap(line);
      await tester.pump();
      expect(navigateEvents, hasLength(1));
      expect(navigateEvents.single.route, Routes.intelligence);
    },
  );

  testWidgets(
    'Given world-only digest When feed opens Then gazette and France secrets absent',
    (WidgetTester tester) async {
      final harness = _intelligenceFeedHarness(
        digest: const LastTurnIntelligenceDigest(
          resolvedTurnNumber: 1,
          worldLines: [
            IntelligenceWorldLine(
              kind: IntelligenceWorldKind.war,
              factionIdA: 'gp2',
              factionIdB: 'gp1',
            ),
          ],
        ),
      );

      await pumpEventFeedMapArea(tester, gamesBox: gamesBox, harness: harness);
      await commitEventFeedTurnEvents(tester, harness, const [], turnNumber: 2);

      expect(find.textContaining('Our spy in'), findsNothing);
      expect(find.textContaining('Crop Rotation'), findsNothing);
      expect(find.textContaining('are now at war'), findsNothing);
    },
  );
}

EventFeedHarness _intelligenceFeedHarness({
  required LastTurnIntelligenceDigest digest,
  bool disposeBus = true,
}) {
  final game = buildMapAreaEventFeedTestGame().copyWith(
    lastTurnIntelligenceDigest: digest,
  );
  final harness = EventFeedHarness(
    game,
    buildLightweightMapViewData(),
    AppEventBus.create(),
  );
  if (disposeBus) {
    addTearDown(harness.bus.dispose);
  }
  return harness;
}
