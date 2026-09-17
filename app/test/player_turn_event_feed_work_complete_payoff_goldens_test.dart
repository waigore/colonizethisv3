// OVL70001 civilian work-complete payoff goldens (Refs #4778).
// Baselines: app/test/goldens/player_turn_event_feed_work_complete_*.png.
// Widgetbook pin: widgetbook_player_turn_event_feed_work_complete_payoff_test.dart.
// SPEC: SPEC/ui/player-turn-event-feed.md.

import 'package:colonizethis_app/config/themes.dart';
import 'package:colonizethis_app/features/game/widgets/shell/player_turn_event_feed.dart';
import 'package:colonizethis_app_ui_chrome/event_feed/ct_event_feed_text.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'editorial_monocle_dark_token_assertions.dart';
import 'golden_capture_harness.dart';

const Size _kWideFeedViewport = Size(420, 320);
const Size _kCard320Viewport = Size(360, 280);

const String _exploreLine =
    'Lisbon work completed! This province is now fully visible.';
const String _improveLine =
    'Lisbon work completed! This tile now sends Grain if still linked.';
const String _townLine =
    'Lisbon work completed! Town workshops pause until level 4.';
const String _portLine = 'Lisbon work completed! This coast now has a port.';
const String _fortLine = 'Lisbon work completed! Siege posture is now wood.';
const String _purchaseLine =
    'Lisbon work completed! Grain still sells as that court’s. '
    'First bid and gold now start. The land stays the court’s.';

Widget _payoffFeedGoldenHost({
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

Future<void> _pumpPayoffFeedGolden(
  WidgetTester tester, {
  required Key boundaryKey,
  required List<PlayerTurnEventFeedEntry> entries,
  required Size viewport,
}) async {
  configureGoldenView(tester, physicalSize: viewport);
  await tester.pumpWidget(
    _payoffFeedGoldenHost(
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

PlayerTurnEventFeedEntry _row(String text) =>
    PlayerTurnEventFeedEntry(text: text, linkAffordance: true, onTap: () {});

void main() {
  suppressLogsForTests();

  group('OVL70001 work-complete payoff goldens (Refs #4778)', () {
    test('canonical Explore payoff line', () {
      expect(
        CtEventFeedText.workOrderCompletedLine(
          provinceLabel: 'Lisbon',
          workTargetLabel: 'Explore',
          workTarget: CtEventFeedText.exploreWorkTarget,
          payoffKind: WorkOrderPayoffKind.fullyVisible,
        ),
        _exploreLine,
      );
    });

    testWidgets('Explore fully visible under editorial-monocle', (
      WidgetTester tester,
    ) async {
      const boundaryKey = ValueKey<String>('workCompleteExplore');
      await _pumpPayoffFeedGolden(
        tester,
        boundaryKey: boundaryKey,
        viewport: _kWideFeedViewport,
        entries: [_row(_exploreLine)],
      );
      expect(tester.takeException(), isNull);
      expectEditorialMonocleDarkChrome(tester);
      expect(
        find.textContaining('This province is now fully visible'),
        findsOneWidget,
      );
      await expectLater(
        find.byKey(boundaryKey),
        matchesGoldenFile(
          'goldens/player_turn_event_feed_work_complete_explore.png',
        ),
      );
    });

    testWidgets('Improve yield raise under editorial-monocle', (
      WidgetTester tester,
    ) async {
      const boundaryKey = ValueKey<String>('workCompleteImprove');
      await _pumpPayoffFeedGolden(
        tester,
        boundaryKey: boundaryKey,
        viewport: _kWideFeedViewport,
        entries: [_row(_improveLine)],
      );
      expect(tester.takeException(), isNull);
      expectEditorialMonocleDarkChrome(tester);
      expect(find.textContaining('Grain'), findsOneWidget);
      await expectLater(
        find.byKey(boundaryKey),
        matchesGoldenFile(
          'goldens/player_turn_event_feed_work_complete_improve.png',
        ),
      );
    });

    testWidgets('Upgrade town pause under editorial-monocle', (
      WidgetTester tester,
    ) async {
      const boundaryKey = ValueKey<String>('workCompleteTown');
      await _pumpPayoffFeedGolden(
        tester,
        boundaryKey: boundaryKey,
        viewport: _kWideFeedViewport,
        entries: [_row(_townLine)],
      );
      expect(tester.takeException(), isNull);
      expectEditorialMonocleDarkChrome(tester);
      await expectLater(
        find.byKey(boundaryKey),
        matchesGoldenFile(
          'goldens/player_turn_event_feed_work_complete_town.png',
        ),
      );
    });

    testWidgets('Build port under editorial-monocle', (
      WidgetTester tester,
    ) async {
      const boundaryKey = ValueKey<String>('workCompletePort');
      await _pumpPayoffFeedGolden(
        tester,
        boundaryKey: boundaryKey,
        viewport: _kWideFeedViewport,
        entries: [_row(_portLine)],
      );
      expect(tester.takeException(), isNull);
      expectEditorialMonocleDarkChrome(tester);
      await expectLater(
        find.byKey(boundaryKey),
        matchesGoldenFile(
          'goldens/player_turn_event_feed_work_complete_port.png',
        ),
      );
    });

    testWidgets('Build fort wood under editorial-monocle', (
      WidgetTester tester,
    ) async {
      const boundaryKey = ValueKey<String>('workCompleteFort');
      await _pumpPayoffFeedGolden(
        tester,
        boundaryKey: boundaryKey,
        viewport: _kWideFeedViewport,
        entries: [_row(_fortLine)],
      );
      expect(tester.takeException(), isNull);
      expectEditorialMonocleDarkChrome(tester);
      expect(find.textContaining('wood'), findsOneWidget);
      await expectLater(
        find.byKey(boundaryKey),
        matchesGoldenFile(
          'goldens/player_turn_event_feed_work_complete_fort.png',
        ),
      );
    });

    testWidgets('Purchase land wraps safely at 320 dp card width', (
      WidgetTester tester,
    ) async {
      const boundaryKey = ValueKey<String>('workCompletePurchase320');
      await _pumpPayoffFeedGolden(
        tester,
        boundaryKey: boundaryKey,
        viewport: _kCard320Viewport,
        entries: [_row(_purchaseLine)],
      );
      expect(tester.takeException(), isNull);
      expectEditorialMonocleDarkChrome(tester);
      expect(find.textContaining('First bid and gold'), findsOneWidget);
      await expectLater(
        find.byKey(boundaryKey),
        matchesGoldenFile(
          'goldens/player_turn_event_feed_work_complete_purchase_320dp.png',
        ),
      );
    });
  });
}
