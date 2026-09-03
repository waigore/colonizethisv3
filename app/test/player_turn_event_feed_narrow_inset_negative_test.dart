// Negative narrow-layout inset pin for the floating `PlayerTurnEventFeedCard`
// (issue #2870 S3 / Req 11; Refs #4720 Slice G).
//
// SPEC: `SPEC/ui/player-turn-event-feed.md` § Acceptance criteria —
// `Positioned.right` does NOT equal
// `gameMapWideOverlayRightInset(provincePanelOpen: true)` (which would be
// `8 + 320 = 328`). Guards against accidental reuse of the wide inset
// helper on the narrow code path.

import 'package:colonizethis_app/features/game/flame/map_state/map_state.dart';
import 'package:colonizethis_app/features/game/screens/game/game_screen_shared.dart'
    show gameMapWideOverlayRightInset;
import 'package:colonizethis_app/providers/map_province_panel_provider.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';

import 'app_test_hive_harness.dart';
import 'map_view_test_fixtures.dart';
import 'player_turn_event_feed_narrow_inset_support.dart';

void main() {
  suppressLogsForTests();

  late Box<dynamic> gamesBox;

  setUpAll(() async {
    gamesBox = await openAppTestHiveBox(
      suiteId: 'news_feed_narrow_inset_negative',
    );
  });

  group(
    'PlayerTurnEventFeedCard narrow Positioned.right (Refs #2870 S3 / Req 11)',
    () {
      testWidgets('negative: narrow + feed visible + province panel OPEN → '
          'Positioned.right does NOT receive '
          'gameMapWideOverlayRightInset(true) (regression guard against '
          'accidental reuse of the wide inset helper on the narrow path)', (
        WidgetTester tester,
      ) async {
        final game = playerTurnEventFeedEnabledGame();
        final bus = AppEventBus.create();
        addTearDown(bus.dispose);

        await pumpNarrowPlayerTurnEventFeedGameMapArea(
          tester,
          gamesBox: gamesBox,
          game: game,
          mapViewData: buildLightweightMapViewData(),
          bus: bus,
        );

        final container = ProviderScope.containerOf(
          tester.element(find.byType(GameMapArea)),
        );
        container
            .read(mapProvincePanelProvider.notifier)
            .reportMapTileTapped(firstOldWorldTileKey(game));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 16));

        final wideInsetWhenPanelOpen = gameMapWideOverlayRightInset(
          provincePanelOpen: true,
        );
        expect(
          playerTurnEventFeedCardPositionedRight(tester),
          isNot(wideInsetWhenPanelOpen),
          reason:
              'Regression guard: gameMapWideOverlayRightInset (= '
              '$wideInsetWhenPanelOpen) is the wide-layout right inset '
              'that clears the 320 dp province side panel column. The '
              'narrow code path mounts the province panel at the bottom '
              'instead (see game_map_area_build.dart `if (isNarrow) … '
              'Align(bottomCenter, GameMapNarrowDetailOverlaySlot)`) '
              'so the wide inset MUST NOT bleed onto the narrow news '
              'feed card.',
        );
      });
    },
  );
}
