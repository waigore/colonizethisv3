// Widget goldens for OVL70001 market-summary feed rows (Refs #4270).
// Pixel baselines under app/test/goldens/; integration coverage in
// game_map_area_event_feed_test.dart (tap navigation, overseas-profit isolation).
//
// Five baselines in app/test/goldens/market_summary_feed_*.png:
// bid-only fills, bought+sold fills, carry-forward-only, fills+carry, narrow 320 dp.
//
// SPEC: SPEC/ui/player-turn-event-feed.md — Market-summary lines.

import 'package:colonizethis_app/config/constants.dart';
import 'package:colonizethis_app/config/themes.dart';
import 'package:colonizethis_app/features/game/widgets/shell/player_turn_event_feed.dart';
import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'editorial_monocle_dark_token_assertions.dart';
import 'golden_capture_harness.dart';

const Size _kWideFeedViewport = Size(420, 320);
const Size _kNarrowFeedViewport = Size(kMinViewportWidth, 640);

Widget _marketSummaryFeedGoldenHost({
  required Key boundaryKey,
  required Widget child,
  required Size viewport,
  bool narrow = false,
}) {
  return wrapGoldenBoundary(
    boundaryKey: boundaryKey,
    includeLocalizations: true,
    center: false,
    scaffoldBackgroundColor: AppThemes.editorialMonocle.scaffoldBackgroundColor,
    child: MediaQuery(
      data: MediaQueryData(size: viewport),
      child: SizedBox(
        width: viewport.width,
        height: viewport.height,
        child: Align(
          alignment: Alignment.topRight,
          child: Padding(
            padding: EdgeInsets.all(narrow ? 8 : 24),
            child: child,
          ),
        ),
      ),
    ),
  );
}

Future<void> _pumpMarketSummaryFeedGolden(
  WidgetTester tester, {
  required Key boundaryKey,
  required List<PlayerTurnEventFeedEntry> entries,
  required Size viewport,
  bool narrow = false,
}) async {
  configureGoldenView(tester, physicalSize: viewport);
  await tester.pumpWidget(
    _marketSummaryFeedGoldenHost(
      boundaryKey: boundaryKey,
      viewport: viewport,
      narrow: narrow,
      child: PlayerTurnEventFeedCard(
        entries: entries,
        emptyLabel: 'No events this turn.',
        narrow: narrow,
      ),
    ),
  );
  await pumpForGolden(tester, settle: false);
}

void main() {
  suppressLogsForTests();

  group('Market summary feed goldens (#4270)', () {
    testWidgets(
      'golden: market summary bid-only fill totals row with chevron link affordance',
      (WidgetTester tester) async {
        const boundaryKey = ValueKey<String>(
          'marketSummaryFeedBidOnlyWide',
        );

        await _pumpMarketSummaryFeedGolden(
          tester,
          boundaryKey: boundaryKey,
          viewport: _kWideFeedViewport,
          entries: const <PlayerTurnEventFeedEntry>[
            PlayerTurnEventFeedEntry(
              text: 'Market: bought £240',
              linkAffordance: true,
            ),
          ],
        );

        expect(tester.takeException(), isNull);
        expectEditorialMonocleDarkChrome(tester);
        expect(find.byIcon(Icons.chevron_right), findsOneWidget);
        expect(find.text('Market: bought £240'), findsOneWidget);

        await expectLater(
          find.byKey(boundaryKey),
          matchesGoldenFile('goldens/market_summary_feed_bid_only_wide.png'),
        );
      },
    );

    testWidgets(
      'golden: market summary bought and sold fill totals row with chevron link affordance',
      (WidgetTester tester) async {
        const boundaryKey = ValueKey<String>(
          'marketSummaryFeedFillTotalsWide',
        );

        await _pumpMarketSummaryFeedGolden(
          tester,
          boundaryKey: boundaryKey,
          viewport: _kWideFeedViewport,
          entries: const <PlayerTurnEventFeedEntry>[
            PlayerTurnEventFeedEntry(
              text: 'Market: bought £240 · sold £160',
              linkAffordance: true,
            ),
          ],
        );

        expect(tester.takeException(), isNull);
        expectEditorialMonocleDarkChrome(tester);
        expect(find.byIcon(Icons.chevron_right), findsOneWidget);
        expect(
          find.text('Market: bought £240 · sold £160'),
          findsOneWidget,
        );

        await expectLater(
          find.byKey(boundaryKey),
          matchesGoldenFile('goldens/market_summary_feed_fill_totals_wide.png'),
        );
      },
    );

    testWidgets(
      'golden: carry-forward-only market summary row',
      (WidgetTester tester) async {
        const boundaryKey = ValueKey<String>(
          'marketSummaryFeedCarryForwardOnlyWide',
        );

        await _pumpMarketSummaryFeedGolden(
          tester,
          boundaryKey: boundaryKey,
          viewport: _kWideFeedViewport,
          entries: const <PlayerTurnEventFeedEntry>[
            PlayerTurnEventFeedEntry(
              text: 'Market: 2 orders carried forward',
              linkAffordance: true,
            ),
          ],
        );

        expect(tester.takeException(), isNull);
        expectEditorialMonocleDarkChrome(tester);
        expect(find.byIcon(Icons.chevron_right), findsOneWidget);

        await expectLater(
          find.byKey(boundaryKey),
          matchesGoldenFile(
            'goldens/market_summary_feed_carry_forward_only_wide.png',
          ),
        );
      },
    );

    testWidgets(
      'golden: fills plus carry-forward on one market summary row',
      (WidgetTester tester) async {
        const boundaryKey = ValueKey<String>(
          'marketSummaryFeedFillsAndCarryWide',
        );

        await _pumpMarketSummaryFeedGolden(
          tester,
          boundaryKey: boundaryKey,
          viewport: _kWideFeedViewport,
          entries: const <PlayerTurnEventFeedEntry>[
            PlayerTurnEventFeedEntry(
              text: 'Market: bought £240 · sold £160 · 2 orders carried',
              linkAffordance: true,
            ),
          ],
        );

        expect(tester.takeException(), isNull);
        expectEditorialMonocleDarkChrome(tester);
        expect(find.byIcon(Icons.chevron_right), findsOneWidget);

        await expectLater(
          find.byKey(boundaryKey),
          matchesGoldenFile(
            'goldens/market_summary_feed_fills_and_carry_wide.png',
          ),
        );
      },
    );

    testWidgets(
      'golden: narrow 320 dp market summary row without overflow (≥44 dp tap target)',
      (WidgetTester tester) async {
        const boundaryKey = ValueKey<String>(
          'marketSummaryFeedNarrow320dp',
        );

        await _pumpMarketSummaryFeedGolden(
          tester,
          boundaryKey: boundaryKey,
          viewport: _kNarrowFeedViewport,
          narrow: true,
          entries: const <PlayerTurnEventFeedEntry>[
            PlayerTurnEventFeedEntry(
              text: 'Market: bought £240 · sold £160 · 2 orders carried',
              linkAffordance: true,
            ),
          ],
        );

        expect(tester.takeException(), isNull);
        expectEditorialMonocleDarkChrome(tester);
        expect(find.byIcon(Icons.chevron_right), findsOneWidget);

        await expectLater(
          find.byKey(boundaryKey),
          matchesGoldenFile('goldens/market_summary_feed_narrow_320dp.png'),
        );
      },
    );
  });
}
