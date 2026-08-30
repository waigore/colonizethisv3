// OVL70001 naval-combat outcome-row goldens (Refs #4558).
// Baselines: app/test/goldens/player_turn_event_feed_naval_combat_*.png.
// Widgetbook pin: widgetbook_player_turn_event_feed_naval_combat_test.dart.
// SPEC: SPEC/ui/player-turn-event-feed.md.

import 'package:colonizethis_app/config/constants.dart';
import 'package:colonizethis_app/config/themes.dart';
import 'package:colonizethis_app/features/game/widgets/shell/player_turn_event_feed.dart';
import 'package:colonizethis_app_ui_chrome/event_feed/ct_event_feed_text.dart';
import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'editorial_monocle_dark_token_assertions.dart';
import 'golden_capture_harness.dart';

const Size _kWideFeedViewport = Size(420, 320);
const Size _kNarrowFeedViewport = Size(kMinViewportWidth, 640);

typedef _NavalCombatGoldenCase = ({
  String outcomeName,
  String goldenFile,
  String key,
  int side1Losses,
  int side2Losses,
  bool side2Retreated,
  String expectedLabel,
});

const List<_NavalCombatGoldenCase> _kCases = <_NavalCombatGoldenCase>[
  (
    outcomeName: 'side1Victory',
    goldenFile:
        'goldens/player_turn_event_feed_naval_combat_attacker_victory.png',
    key: 'navalCombatFeedAttackerVictory',
    side1Losses: 1,
    side2Losses: 2,
    side2Retreated: true,
    expectedLabel: 'Attacker victory',
  ),
  (
    outcomeName: 'side2Victory',
    goldenFile: 'goldens/player_turn_event_feed_naval_combat_defender_holds.png',
    key: 'navalCombatFeedDefenderHolds',
    side1Losses: 3,
    side2Losses: 0,
    side2Retreated: false,
    expectedLabel: 'Defender holds',
  ),
  (
    outcomeName: 'stalemate',
    goldenFile: 'goldens/player_turn_event_feed_naval_combat_stalemate.png',
    key: 'navalCombatFeedStalemate',
    side1Losses: 0,
    side2Losses: 0,
    side2Retreated: false,
    expectedLabel: 'Stalemate',
  ),
  (
    outcomeName: 'mutualDestruction',
    goldenFile: 'goldens/player_turn_event_feed_naval_combat_both_destroyed.png',
    key: 'navalCombatFeedBothDestroyed',
    side1Losses: 4,
    side2Losses: 3,
    side2Retreated: false,
    expectedLabel: 'Both fleets destroyed',
  ),
];

Widget _navalCombatFeedGoldenHost({
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

Future<void> _pumpNavalCombatFeedGolden(
  WidgetTester tester, {
  required Key boundaryKey,
  required List<PlayerTurnEventFeedEntry> entries,
  required Size viewport,
  bool narrow = false,
}) async {
  configureGoldenView(tester, physicalSize: viewport);
  await tester.pumpWidget(
    _navalCombatFeedGoldenHost(
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

PlayerTurnEventFeedEntry _navalCombatEntry(_NavalCombatGoldenCase c) {
  return PlayerTurnEventFeedEntry(
    text: CtEventFeedText.navalCombatResolvedLine(
      seaZoneLabel: 'North Sea',
      outcomeLabel: CtEventFeedText.navalBattleOutcomeLabel(c.outcomeName),
      side1Label: 'Castile',
      side2Label: 'Portugal',
      side1Losses: c.side1Losses,
      side2Losses: c.side2Losses,
      side2Retreated: c.side2Retreated,
    ),
    onTap: () {},
  );
}

void main() {
  suppressLogsForTests();

  group('OVL70001 naval-combat feed goldens (#4558)', () {
    for (final c in _kCases) {
      testWidgets('golden: ${c.expectedLabel} with both-side ship losses', (
        WidgetTester tester,
      ) async {
        final boundaryKey = ValueKey<String>(c.key);
        await _pumpNavalCombatFeedGolden(
          tester,
          boundaryKey: boundaryKey,
          viewport: _kWideFeedViewport,
          entries: <PlayerTurnEventFeedEntry>[_navalCombatEntry(c)],
        );

        expect(tester.takeException(), isNull);
        expectEditorialMonocleDarkChrome(tester);
        expect(find.textContaining(c.expectedLabel), findsOneWidget);
        expect(find.textContaining('North Sea'), findsOneWidget);
        expect(find.textContaining('side1Victory'), findsNothing);
        expect(find.textContaining('mutualDestruction'), findsNothing);

        await expectLater(
          find.byKey(boundaryKey),
          matchesGoldenFile(c.goldenFile),
        );
      });
    }

    testWidgets('golden: Attacker victory wraps at 320 dp narrow feed', (
      WidgetTester tester,
    ) async {
      const boundaryKey = ValueKey<String>('navalCombatFeedAttackerVictoryNarrow');
      final c = _kCases.first;
      await _pumpNavalCombatFeedGolden(
        tester,
        boundaryKey: boundaryKey,
        viewport: _kNarrowFeedViewport,
        narrow: true,
        entries: <PlayerTurnEventFeedEntry>[_navalCombatEntry(c)],
      );

      expect(tester.takeException(), isNull);
      expectEditorialMonocleDarkChrome(tester);
      expect(find.textContaining('Attacker victory'), findsOneWidget);
      expect(find.textContaining('retreated'), findsOneWidget);

      await expectLater(
        find.byKey(boundaryKey),
        matchesGoldenFile(
          'goldens/player_turn_event_feed_naval_combat_attacker_victory_320dp.png',
        ),
      );
    });
  });
}
