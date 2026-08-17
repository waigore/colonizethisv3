// OVL70001 spy-gated digest row goldens (Refs #4476 verification gaps).
// Baselines: app/test/goldens/intelligence_spy_feed_*.png.
// Tap navigation: game_map_area_event_feed_intelligence_test.dart.
// SPEC: SPEC/ui/player-turn-event-feed.md; SPEC/ui/intelligence-council.md.

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

Widget _spyFeedGoldenHost({
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

Future<void> _pumpSpyFeedGolden(
  WidgetTester tester, {
  required Key boundaryKey,
  required List<PlayerTurnEventFeedEntry> entries,
  required Size viewport,
  bool narrow = false,
}) async {
  configureGoldenView(tester, physicalSize: viewport);
  await tester.pumpWidget(
    _spyFeedGoldenHost(
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

  group('Intelligence spy-gated feed goldens (#4476)', () {
    testWidgets(
      'golden: spy-gated research row with chevron link affordance',
      (WidgetTester tester) async {
        const boundaryKey = ValueKey<String>('intelligenceSpyFeedWide');
        await _pumpSpyFeedGolden(
          tester,
          boundaryKey: boundaryKey,
          viewport: _kWideFeedViewport,
          entries: const <PlayerTurnEventFeedEntry>[
            PlayerTurnEventFeedEntry(
              text:
                  'Our spy in France reports: France finished researching Crop Rotation.',
              onTap: null,
              linkAffordance: true,
            ),
          ],
        );

        expect(tester.takeException(), isNull);
        expectEditorialMonocleDarkChrome(tester);
        expect(find.textContaining('Our spy in France reports:'), findsOneWidget);
        expect(find.textContaining('Crop Rotation'), findsOneWidget);

        await expectLater(
          find.byKey(boundaryKey),
          matchesGoldenFile('goldens/intelligence_spy_feed_wide.png'),
        );
      },
    );

    testWidgets(
      'golden: spy-gated row at 320 dp narrow feed',
      (WidgetTester tester) async {
        const boundaryKey = ValueKey<String>('intelligenceSpyFeedNarrow');
        await _pumpSpyFeedGolden(
          tester,
          boundaryKey: boundaryKey,
          viewport: _kNarrowFeedViewport,
          narrow: true,
          entries: const <PlayerTurnEventFeedEntry>[
            PlayerTurnEventFeedEntry(
              text:
                  'Our spy in France reports: France declared war on Spain.',
              onTap: null,
              linkAffordance: true,
            ),
          ],
        );

        expect(tester.takeException(), isNull);
        expectEditorialMonocleDarkChrome(tester);

        await expectLater(
          find.byKey(boundaryKey),
          matchesGoldenFile('goldens/intelligence_spy_feed_320dp.png'),
        );
      },
    );
  });
}
