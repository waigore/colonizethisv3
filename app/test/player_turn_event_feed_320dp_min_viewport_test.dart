// Pin the 320 dp minimum-viewport contract for [PlayerTurnEventFeedCard]
// (news feed card chrome from `SPEC/ui/player-turn-event-feed.md`) —
// extending the width-only pins in
// `player_turn_event_feed_narrow_width_test.dart` and the open/closed
// inset pins in `player_turn_event_feed_narrow_inset_test.dart` so the
// floating card body lays out without horizontal overflow when the in-game
// shell selects the narrow `clamp(180, 50vw, 260)` width at the minimum
// supported viewport (`kMinViewportWidth` = 320 dp).
//
// At 320 dp with `narrow: true`, `resolveNarrowWidth` clamps to 180 dp
// (50vw = 160 dp, below the mockup lower bound). The pins assert:
//
//  * `WidgetTester.takeException()` is `null` so no `RenderFlex` overflow
//    exception escapes the framework — the contract every sibling
//    `*_320dp_min_viewport_test.dart` file relies on.
//  * Populated and empty narrow paths still render their body copy
//    end-to-end so the scroll viewport + row list actually exercise the
//    card chrome at the minimum viewport rather than no-op'ing.
//  * A wide regression sentinel at 1024 × 768 dp pumps the same
//    populated fixture with `narrow: true` so a regression in the host
//    overflow contract upstream of the card itself would still surface.
//
// SPEC: `SPEC/ui/mobile-adaptation.md` § 7 (Minimum-viewport pin).
// SPEC: `SPEC/ui/player-turn-event-feed.md` § Card chrome — narrow layout.
// Refs #2870 S3 / Req 11 + S10 (no horizontal overflow at 320 dp).

import 'package:colonizethis_app/config/constants.dart';
import 'package:colonizethis_app/features/game/widgets/player_turn_event_feed.dart';
import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/min_viewport_harness.dart';

/// Minimum supported viewport dimensions for SPEC/ui/mobile-adaptation.md
/// § 7. Width matches [kMinViewportWidth]; height (640 dp) mirrors the
/// sibling screen-level pin files.
const Size _kMinViewport = Size(kMinViewportWidth, 640);

/// Wide regression sentinel — comfortably above every per-screen breakpoint.
const Size _kWideRegressionViewport = Size(1024, 768);

const List<PlayerTurnEventFeedEntry> _kPopulatedEntries = <PlayerTurnEventFeedEntry>[
  PlayerTurnEventFeedEntry(
    text:
        'Castile completed Castle in Lisbon after a long colonial campaign.',
  ),
  PlayerTurnEventFeedEntry(
    text:
        'England declared war on France along the Channel frontier provinces.',
  ),
  PlayerTurnEventFeedEntry(
    text: 'New trade route established: Lisbon to Bordeaux.',
  ),
];

Widget _hostNarrowCard({
  required List<PlayerTurnEventFeedEntry> entries,
  required String emptyLabel,
}) {
  return Scaffold(
    body: Align(
      alignment: Alignment.topRight,
      child: PlayerTurnEventFeedCard(
        entries: entries,
        emptyLabel: emptyLabel,
        narrow: true,
      ),
    ),
  );
}

Future<void> _pumpNarrow(
  WidgetTester tester, {
  required Size size,
  required Widget child,
}) async {
  await pumpAtMinViewport(tester, size: size, child: child);
  // The card's hover-aware row chrome animates the border color via an
  // `AnimatedContainer`; a second short framed pump lays out the body
  // without entering the animation steady-state loop (so we avoid
  // `pumpAndSettle`).
  await tester.pump(const Duration(milliseconds: 16));
}

void main() {
  suppressLogsForTests();

  group(
    'SPEC/ui/mobile-adaptation.md § 7 — PlayerTurnEventFeedCard @ 320 dp '
    '(Refs #2870 S3 / Req 11 + S10)',
    () {
      testWidgets(
        'AC (positive) narrow populated @ 320×640: no RenderFlex overflow '
        'and entry lines render',
        (WidgetTester tester) async {
          await _pumpNarrow(
            tester,
            size: _kMinViewport,
            child: _hostNarrowCard(
              entries: _kPopulatedEntries,
              emptyLabel: 'No events this turn.',
            ),
          );

          expect(
            tester.takeException(),
            isNull,
            reason:
                'SPEC/ui/mobile-adaptation.md § 7: the narrow news feed '
                'card with three populated rows must lay out inside the '
                '180 dp clamped width at 320 dp without horizontal overflow.',
          );
          expect(find.byKey(PlayerTurnEventFeedCard.surfaceKey), findsOneWidget);
          expect(find.textContaining('Castile completed Castle'), findsOneWidget);
          expect(find.textContaining('England declared war'), findsOneWidget);
          // Third row may sit below the 220 dp scroll cap; overflow contract
          // is the primary signal — at least two rows must render on-screen.
          expect(
            tester.getSize(find.byKey(PlayerTurnEventFeedCard.surfaceKey)).width,
            PlayerTurnEventFeedCard.narrowMinWidth,
          );
        },
      );

      testWidgets(
        'AC (positive) narrow empty @ 320×640: no RenderFlex overflow and '
        'empty copy renders',
        (WidgetTester tester) async {
          await _pumpNarrow(
            tester,
            size: _kMinViewport,
            child: _hostNarrowCard(
              entries: const <PlayerTurnEventFeedEntry>[],
              emptyLabel: 'No events this turn.',
            ),
          );

          expect(
            tester.takeException(),
            isNull,
            reason:
                'SPEC/ui/mobile-adaptation.md § 7: the narrow empty news '
                'feed card must lay out at 320 dp without horizontal overflow.',
          );
          expect(find.text('No events this turn.'), findsOneWidget);
        },
      );

      testWidgets(
        'Negative control: narrow populated @ 1024×768 also pumps without '
        'exception',
        (WidgetTester tester) async {
          await _pumpNarrow(
            tester,
            size: _kWideRegressionViewport,
            child: _hostNarrowCard(
              entries: _kPopulatedEntries,
              emptyLabel: 'No events this turn.',
            ),
          );

          expect(tester.takeException(), isNull);
          expect(find.textContaining('Castile completed Castle'), findsOneWidget);
        },
      );
    },
  );
}
