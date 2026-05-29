// Pins the narrow-layout width contract for `PlayerTurnEventFeedCard`
// (Refs #2870 S3 / Req 11).
//
// SPEC: `SPEC/ui/player-turn-event-feed.md` § Card chrome (dark
// editorial-monocle) — narrow-layout entry, plus the matching ACs.
// Source of truth: mockup `.news-feed-card @media (max-width:600px)
// { width: clamp(180px, 50vw, 260px); }` in
// `SPEC/ui/mockups/GAME10001-game-screen.html`.
//
// Pins:
//   1. `narrow: true` paints the card at `clamp(180, 50vw, 260)` dp,
//      using the viewport width (`MediaQuery.sizeOf(context).width`).
//   2. The narrow envelope clamps to 180 dp at `<= 360` dp viewports
//      and to 260 dp at `>= 520` dp viewports; intermediate viewports
//      land on `viewport / 2`.
//   3. Negative regression guard: `narrow: false` (default) still
//      paints the legacy 320 dp wide-layout width, so the wide-vs-open
//      province panel inset rule from #2861 S7 is preserved.

import 'package:colonizethis_app/features/game/flame/game_screen_shared.dart'
    show kGameMapWideProvinceSidePanelWidth;
import 'package:colonizethis_app/features/game/widgets/player_turn_event_feed.dart';
import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _hostNarrowCard({required Size viewportSize}) {
  return MediaQuery(
    data: MediaQueryData(size: viewportSize),
    child: const MaterialApp(
      home: Scaffold(
        body: Align(
          alignment: Alignment.topRight,
          child: PlayerTurnEventFeedCard(
            entries: <PlayerTurnEventFeedEntry>[],
            emptyLabel: 'No events.',
            narrow: true,
          ),
        ),
      ),
    ),
  );
}

Widget _hostWideCard({required Size viewportSize}) {
  return MediaQuery(
    data: MediaQueryData(size: viewportSize),
    child: const MaterialApp(
      home: Scaffold(
        body: Align(
          alignment: Alignment.topRight,
          child: PlayerTurnEventFeedCard(
            entries: <PlayerTurnEventFeedEntry>[],
            emptyLabel: 'No events.',
          ),
        ),
      ),
    ),
  );
}

void main() {
  suppressLogsForTests();

  group(
    'PlayerTurnEventFeedCard narrow width (Refs #2870 S3 / Req 11)',
    () {
      testWidgets(
        'positive: narrow at 360 dp viewport clamps to 180 dp lower bound',
        (WidgetTester tester) async {
          await tester.binding.setSurfaceSize(const Size(360, 640));
          addTearDown(() => tester.binding.setSurfaceSize(null));
          await tester.pumpWidget(
            _hostNarrowCard(viewportSize: const Size(360, 640)),
          );
          await tester.pump();

          final size = tester.getSize(
            find.byKey(PlayerTurnEventFeedCard.surfaceKey),
          );
          expect(
            size.width,
            PlayerTurnEventFeedCard.narrowMinWidth,
            reason:
                'At a 360 dp viewport (50vw = 180 dp) the narrow card '
                'must clamp to the 180 dp lower bound from the mockup '
                'clamp(180, 50vw, 260) rule.',
          );
        },
      );

      testWidgets(
        'positive: narrow at 320 dp viewport stays at 180 dp lower bound',
        (WidgetTester tester) async {
          await tester.binding.setSurfaceSize(const Size(320, 640));
          addTearDown(() => tester.binding.setSurfaceSize(null));
          await tester.pumpWidget(
            _hostNarrowCard(viewportSize: const Size(320, 640)),
          );
          await tester.pump();

          final size = tester.getSize(
            find.byKey(PlayerTurnEventFeedCard.surfaceKey),
          );
          expect(
            size.width,
            PlayerTurnEventFeedCard.narrowMinWidth,
            reason:
                'At a 320 dp viewport (50vw = 160 dp, below the lower '
                'bound) the narrow card must clamp up to 180 dp.',
          );
        },
      );

      testWidgets(
        'positive: narrow at 460 dp viewport renders at 50vw (230 dp)',
        (WidgetTester tester) async {
          await tester.binding.setSurfaceSize(const Size(460, 640));
          addTearDown(() => tester.binding.setSurfaceSize(null));
          await tester.pumpWidget(
            _hostNarrowCard(viewportSize: const Size(460, 640)),
          );
          await tester.pump();

          final size = tester.getSize(
            find.byKey(PlayerTurnEventFeedCard.surfaceKey),
          );
          expect(
            size.width,
            230.0,
            reason:
                'At a 460 dp viewport (50vw = 230 dp, inside the '
                '180 – 260 envelope) the narrow card must paint at '
                'exactly 230 dp.',
          );
        },
      );

      testWidgets(
        'positive: narrow at 599 dp viewport clamps to 260 dp upper bound',
        (WidgetTester tester) async {
          await tester.binding.setSurfaceSize(const Size(599, 640));
          addTearDown(() => tester.binding.setSurfaceSize(null));
          await tester.pumpWidget(
            _hostNarrowCard(viewportSize: const Size(599, 640)),
          );
          await tester.pump();

          final size = tester.getSize(
            find.byKey(PlayerTurnEventFeedCard.surfaceKey),
          );
          expect(
            size.width,
            PlayerTurnEventFeedCard.narrowMaxWidth,
            reason:
                'At a 599 dp viewport (50vw = 299.5 dp, above the upper '
                'bound) the narrow card must clamp down to the 260 dp '
                'upper bound from the mockup clamp(180, 50vw, 260) rule.',
          );
        },
      );

      test(
        'positive: resolveNarrowWidth pins the clamp(180, 50vw, 260) rule',
        () {
          expect(PlayerTurnEventFeedCard.resolveNarrowWidth(320), 180.0);
          expect(PlayerTurnEventFeedCard.resolveNarrowWidth(360), 180.0);
          expect(PlayerTurnEventFeedCard.resolveNarrowWidth(400), 200.0);
          expect(PlayerTurnEventFeedCard.resolveNarrowWidth(460), 230.0);
          expect(PlayerTurnEventFeedCard.resolveNarrowWidth(520), 260.0);
          expect(PlayerTurnEventFeedCard.resolveNarrowWidth(599), 260.0);
          expect(PlayerTurnEventFeedCard.resolveNarrowWidth(800), 260.0);
        },
      );

      test(
        'positive: narrow envelope constants match the mockup clamp(180, 50vw, 260)',
        () {
          expect(PlayerTurnEventFeedCard.narrowMinWidth, 180.0);
          expect(PlayerTurnEventFeedCard.narrowMaxWidth, 260.0);
          expect(PlayerTurnEventFeedCard.narrowViewportFraction, 0.5);
        },
      );

      testWidgets(
        'negative: wide layout (narrow: false) keeps 320 dp width baseline',
        (WidgetTester tester) async {
          await tester.binding.setSurfaceSize(const Size(1280, 720));
          addTearDown(() => tester.binding.setSurfaceSize(null));
          await tester.pumpWidget(
            _hostWideCard(viewportSize: const Size(1280, 720)),
          );
          await tester.pump();

          final size = tester.getSize(
            find.byKey(PlayerTurnEventFeedCard.surfaceKey),
          );
          expect(
            size.width,
            kGameMapWideProvinceSidePanelWidth,
            reason:
                'The default (narrow: false) card must keep the wide '
                'layout 320 dp width so the open province side panel '
                'inset rule from #2861 S7 still holds.',
          );
        },
      );

      testWidgets(
        'negative: wide layout (narrow: false) ignores the viewport width',
        (WidgetTester tester) async {
          await tester.binding.setSurfaceSize(const Size(360, 640));
          addTearDown(() => tester.binding.setSurfaceSize(null));
          await tester.pumpWidget(
            _hostWideCard(viewportSize: const Size(360, 640)),
          );
          await tester.pump();

          final size = tester.getSize(
            find.byKey(PlayerTurnEventFeedCard.surfaceKey),
          );
          expect(
            size.width,
            kGameMapWideProvinceSidePanelWidth,
            reason:
                'A `narrow: false` host that happens to mount under a '
                'narrow viewport must still paint at 320 dp; only the '
                'explicit `narrow: true` opt-in resolves the clamp '
                'envelope.',
          );
        },
      );
    },
  );
}
