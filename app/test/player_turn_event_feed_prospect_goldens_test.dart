// OVL70001 Prospect survey-result goldens (Refs #4746).
// Baselines: app/test/goldens/player_turn_event_feed_prospect_*.png.
// Widgetbook pin: widgetbook_player_turn_event_feed_prospect_test.dart.
// SPEC: SPEC/ui/player-turn-event-feed.md.

import 'package:colonizethis_app/config/themes.dart';
import 'package:colonizethis_app/features/game/widgets/shell/player_turn_event_feed.dart';
import 'package:colonizethis_app_ui_chrome/event_feed/ct_event_feed_text.dart';
import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'editorial_monocle_dark_token_assertions.dart';
import 'golden_capture_harness.dart';

const Size _kWideFeedViewport = Size(420, 320);
const Size _kCard320Viewport = Size(360, 280);

const String _foundLine = 'Lisbon work completed! Prospect found Iron';
const String _noneLine = 'Lisbon work completed! Prospect found no mineral';

Widget _prospectFeedGoldenHost({
  required Key boundaryKey,
  required Widget child,
  required Size viewport,
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
          child: Padding(padding: const EdgeInsets.all(24), child: child),
        ),
      ),
    ),
  );
}

Future<void> _pumpProspectFeedGolden(
  WidgetTester tester, {
  required Key boundaryKey,
  required List<PlayerTurnEventFeedEntry> entries,
  required Size viewport,
}) async {
  configureGoldenView(tester, physicalSize: viewport);
  await tester.pumpWidget(
    _prospectFeedGoldenHost(
      boundaryKey: boundaryKey,
      viewport: viewport,
      child: PlayerTurnEventFeedCard(
        entries: entries,
        emptyLabel: 'No events this turn.',
      ),
    ),
  );
  await pumpForGolden(tester, settle: false);
}

void main() {
  suppressLogsForTests();

  group('OVL70001 Prospect goldens (Refs #4746)', () {
    test('canonical Prospect found line', () {
      expect(
        CtEventFeedText.workOrderCompletedLine(
          provinceLabel: 'Lisbon',
          workTargetLabel: 'Prospect',
          workTarget: CtEventFeedText.prospectWorkTarget,
          prospectFoundDisplayName: 'Iron',
        ),
        _foundLine,
      );
    });

    testWidgets('Prospect found Iron under editorial-monocle', (
      WidgetTester tester,
    ) async {
      const boundaryKey = ValueKey<String>('prospectFeedFoundIron');
      await _pumpProspectFeedGolden(
        tester,
        boundaryKey: boundaryKey,
        viewport: _kWideFeedViewport,
        entries: [
          PlayerTurnEventFeedEntry(
            text: _foundLine,
            linkAffordance: true,
            onTap: () {},
          ),
        ],
      );

      expect(tester.takeException(), isNull);
      expectEditorialMonocleDarkChrome(tester);
      expect(find.textContaining('Prospect found Iron'), findsOneWidget);

      await expectLater(
        find.byKey(boundaryKey),
        matchesGoldenFile('goldens/player_turn_event_feed_prospect_found.png'),
      );
    });

    testWidgets('Prospect found no mineral under editorial-monocle', (
      WidgetTester tester,
    ) async {
      const boundaryKey = ValueKey<String>('prospectFeedFoundNone');
      await _pumpProspectFeedGolden(
        tester,
        boundaryKey: boundaryKey,
        viewport: _kWideFeedViewport,
        entries: [
          PlayerTurnEventFeedEntry(
            text: _noneLine,
            linkAffordance: true,
            onTap: () {},
          ),
        ],
      );

      expect(tester.takeException(), isNull);
      expectEditorialMonocleDarkChrome(tester);
      expect(find.textContaining('Prospect found no mineral'), findsOneWidget);

      await expectLater(
        find.byKey(boundaryKey),
        matchesGoldenFile('goldens/player_turn_event_feed_prospect_none.png'),
      );
    });

    testWidgets('Prospect found wraps safely at 320 dp card width', (
      WidgetTester tester,
    ) async {
      const boundaryKey = ValueKey<String>('prospectFeedFoundIron320');
      await _pumpProspectFeedGolden(
        tester,
        boundaryKey: boundaryKey,
        viewport: _kCard320Viewport,
        entries: [
          PlayerTurnEventFeedEntry(
            text: _foundLine,
            linkAffordance: true,
            onTap: () {},
          ),
        ],
      );

      expect(tester.takeException(), isNull);
      expectEditorialMonocleDarkChrome(tester);

      await expectLater(
        find.byKey(boundaryKey),
        matchesGoldenFile(
          'goldens/player_turn_event_feed_prospect_found_320dp.png',
        ),
      );
    });
  });
}
