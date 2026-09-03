// Pins the narrow-layout "no inset" contract for the floating
// `PlayerTurnEventFeedCard` (issue #2870 S3 / Req 11).
//
// SPEC: `SPEC/ui/player-turn-event-feed.md` § Acceptance criteria
// — the two new narrow-layout `Positioned.right == kMapOverlayEdgeInset`
// ACs added under issue #2870 S3 / Req 11. Source: `SPEC/ui/mockups/
// GAME10001-game-screen.html` `.news-feed-card` rule + the narrow
// province bottom-sheet contract in `SPEC/ui/mobile-adaptation.md` § 4
// (Province / sea detail row — narrow panel attaches to the bottom, not
// the right, so the wide `gameMapWideOverlayRightInset` MUST NOT apply
// on narrow viewports).
//
// Pins (mirrors the wide-layout `_feedCardPositionedRight` pin in
// `game_map_area_region_minimap_test.dart` so the regression sentinel is
// symmetric across breakpoints):
//
//  1. Positive — narrow + feed visible + province panel CLOSED: the
//     enclosing `Positioned.right` equals `kMapOverlayEdgeInset` (0).
//  2. Positive — narrow + feed visible + province panel OPEN: the
//     enclosing `Positioned.right` still equals `kMapOverlayEdgeInset`
//     (no wide inset added when the bottom-sheet province panel opens).
//  3. Negative — narrow + feed visible + province panel OPEN: the
//     enclosing `Positioned.right` does NOT equal
//     `gameMapWideOverlayRightInset(provincePanelOpen: true)` (which
//     would be `8 + 320 = 328`). This guards against an accidental
//     reuse of the wide inset helper on the narrow code path.

import 'package:colonizethis_app/features/game/flame/map_state/map_state.dart';
import 'package:colonizethis_app/features/game/screens/game/game_screen_shared.dart'
    show kMapOverlayEdgeInset;
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
    gamesBox = await openAppTestHiveBox(suiteId: 'news_feed_narrow_inset');
  });

  group(
    'PlayerTurnEventFeedCard narrow Positioned.right (Refs #2870 S3 / Req 11)',
    () {
      testWidgets('positive: narrow + feed visible + province panel CLOSED → '
          'Positioned.right equals kMapOverlayEdgeInset (no wide inset)', (
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

        expect(
          playerTurnEventFeedCardPositionedRight(tester),
          kMapOverlayEdgeInset,
          reason:
              'SPEC/ui/player-turn-event-feed.md § Acceptance criteria — '
              'narrow + panel closed: the floating feed card sits at '
              'Positioned.right = kMapOverlayEdgeInset (no wide inset '
              'applies on narrow viewports per issue #2870 S3 / Req 11).',
        );
      });

      testWidgets('positive: narrow + feed visible + province panel OPEN → '
          'Positioned.right still equals kMapOverlayEdgeInset (narrow '
          'bottom sheet covers from below, not from the right)', (
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

        // Pre-condition: feed card already at narrow inset before the
        // province panel opens. Mirrors the wide test's two-phase
        // assertion in `game_map_area_region_minimap_test.dart` so a
        // regression in either the pre- or post-open state surfaces here.
        expect(
          playerTurnEventFeedCardPositionedRight(tester),
          kMapOverlayEdgeInset,
          reason:
              'Pre-condition: narrow + feed visible (panel closed) must '
              'already use Positioned.right = kMapOverlayEdgeInset before '
              'the panel-open transition.',
        );

        final container = ProviderScope.containerOf(
          tester.element(find.byType(GameMapArea)),
        );
        container
            .read(mapProvincePanelProvider.notifier)
            .reportMapTileTapped(firstOldWorldTileKey(game));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 16));

        expect(
          playerTurnEventFeedCardPositionedRight(tester),
          kMapOverlayEdgeInset,
          reason:
              'SPEC/ui/player-turn-event-feed.md § Acceptance criteria — '
              'narrow + panel open: the floating feed card must keep '
              'Positioned.right = kMapOverlayEdgeInset. The narrow '
              'province bottom sheet covers the card from the BOTTOM '
              '(via GameMapNarrowDetailOverlaySlot at ~33 vh anchored '
              'to Alignment.bottomCenter), not from the right — so the '
              'wide gameMapWideOverlayRightInset MUST NOT apply on '
              'narrow viewports (issue #2870 S3 / Req 11).',
        );
      });
    },
  );
}
