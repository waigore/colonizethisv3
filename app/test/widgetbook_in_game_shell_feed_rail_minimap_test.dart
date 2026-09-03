// In-game shell Widgetbook feed, empire-rail, and minimap stories
// (Refs #4720 Slice G / #2861 S12). Catalog directories are tested through
// the public `*Directories` getters so the test fails if a folder or use
// case is removed or renamed.

import 'package:colonizethis_app/features/game/flame/controls/controls.dart';
import 'package:colonizethis_app/features/game/flame/minimap/minimap.dart';
import 'package:colonizethis_app/features/game/widgets/shell/player_turn_event_feed.dart';
import 'package:widgetbook_host/catalogs/catalog.dart';
import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'widgetbook_in_game_shell_chrome_test_support.dart';

void main() {
  suppressLogsForTests();

  group('In-game shell chrome Widgetbook stories (Refs #2861 S12)', () {
    testWidgets(
      'Player Turn Event Feed Card folder exposes populated + empty variants',
      (WidgetTester tester) async {
        final populated = await pumpWidgetbookStoryAs<PlayerTurnEventFeedCard>(
          tester,
          playerTurnEventFeedCardDirectories,
          folder: 'Player Turn Event Feed Card',
          useCase: 'Populated — three entries (top entry tappable)',
        );
        expect(populated.entries.length, 3);
        expect(populated.narrow, isFalse);

        final empty = await pumpWidgetbookStoryAs<PlayerTurnEventFeedCard>(
          tester,
          playerTurnEventFeedCardDirectories,
          folder: 'Player Turn Event Feed Card',
          useCase: 'Empty — no events this turn',
        );
        expect(empty.entries, isEmpty);
        expect(empty.narrow, isFalse);
      },
    );

    testWidgets(
      'Player Turn Event Feed Card folder exposes market summary variants '
      '(Refs #4270)',
      (WidgetTester tester) async {
        final market = await pumpWidgetbookStoryAs<PlayerTurnEventFeedCard>(
          tester,
          playerTurnEventFeedCardDirectories,
          folder: 'Player Turn Event Feed Card',
          useCase: 'Market summary — tappable link to Deal Book',
        );
        expect(market.entries.length, 1);
        expect(market.entries.first.linkAffordance, isTrue);
        expect(
          market.entries.first.text,
          'Market: bought £240 · sold £160 · 2 orders carried',
        );

        final combined = await pumpWidgetbookStoryAs<PlayerTurnEventFeedCard>(
          tester,
          playerTurnEventFeedCardDirectories,
          folder: 'Player Turn Event Feed Card',
          useCase: 'Market + overseas profit — separate rows',
        );
        expect(combined.entries.length, 2);
        expect(combined.entries.map((entry) => entry.text).toList(), [
          'Overseas profit credited: £120 from 2 rival purchase(s). '
              'Tap to open Deal Book.',
          'Market: bought £240 · sold £160',
        ]);
      },
    );

    testWidgets('Player Turn Event Feed Card folder exposes narrow variants '
        '(Refs #2870 S3)', (WidgetTester tester) async {
      for (final name in const [
        'Narrow (360 dp) — populated, clamp(180, 50vw, 260)',
        'Narrow (460 dp) — populated, 50vw mid-range',
        'Narrow (599 dp) — empty, clamp upper bound (260 dp)',
      ]) {
        final card = await pumpWidgetbookStoryAs<PlayerTurnEventFeedCard>(
          tester,
          playerTurnEventFeedCardDirectories,
          folder: 'Player Turn Event Feed Card',
          useCase: name,
        );
        expect(card.narrow, isTrue, reason: name);
      }
    });

    testWidgets(
      'Game Map Empire Left Rail folder exposes wide, debug-console, and narrow variants',
      (WidgetTester tester) async {
        final wide = await pumpWidgetbookStoryAs<GameMapEmpireLeftRail>(
          tester,
          gameMapEmpireLeftRailDirectories,
          folder: 'Game Map Empire Left Rail',
          useCase: 'Wide — six core empire buttons with tooltips',
        );
        expect(wide.narrow, isFalse);
        expect(find.byType(Tooltip), findsWidgets);

        await pumpWidgetbookStory(
          tester,
          gameMapEmpireLeftRailDirectories,
          folder: 'Game Map Empire Left Rail',
          useCase: 'Wide — debug console enabled (7 icons)',
        );
        expect(find.byType(GameMapEmpireLeftRail), findsOneWidget);

        final narrow = await pumpWidgetbookStoryAs<GameMapEmpireLeftRail>(
          tester,
          gameMapEmpireLeftRailDirectories,
          folder: 'Game Map Empire Left Rail',
          useCase: 'Narrow (360 dp) — 26 × 26 dp buttons, tooltips suppressed',
        );
        expect(narrow.narrow, isTrue);
      },
    );

    testWidgets(
      'Region Minimap folder exposes visible, hidden, and narrow variants',
      (WidgetTester tester) async {
        final visible = await pumpWidgetbookStoryAs<GameRegionMinimap>(
          tester,
          gameRegionMinimapDirectories,
          folder: 'Region Minimap',
          useCase: 'Visible — wide chrome with viewport rectangle',
        );
        expect(visible.narrow, isFalse);
        expect(visible.viewportSnapshot, isNotNull);

        await pumpWidgetbookStory(
          tester,
          gameRegionMinimapDirectories,
          folder: 'Region Minimap',
          useCase: 'Hidden — toggle-only (zoom + show button)',
        );
        expect(find.byType(GameRegionMinimap), findsOneWidget);

        final narrow = await pumpWidgetbookStoryAs<GameRegionMinimap>(
          tester,
          gameRegionMinimapDirectories,
          folder: 'Region Minimap',
          useCase: 'Narrow — 90 × 70 dp grid (issue #2870 S3)',
        );
        expect(narrow.narrow, isTrue);
      },
    );
  });
}
