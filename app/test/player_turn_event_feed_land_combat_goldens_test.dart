// OVL70001 land-combat outcome-row goldens (Refs #4548 verification gap).
// Baselines: app/test/goldens/player_turn_event_feed_land_combat_*.png.
// Widgetbook pin: widgetbook_player_turn_event_feed_land_combat_test.dart.
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

typedef _LandCombatGoldenCase = ({
  String outcomeName,
  String goldenFile,
  String key,
  int attackerLosses,
  int defenderLosses,
  String expectedLabel,
});

const List<_LandCombatGoldenCase> _kCases = <_LandCombatGoldenCase>[
  (
    outcomeName: 'attackerVictory',
    goldenFile:
        'goldens/player_turn_event_feed_land_combat_attacker_victory.png',
    key: 'landCombatFeedAttackerVictory',
    attackerLosses: 2,
    defenderLosses: 1,
    expectedLabel: 'Attacker victory',
  ),
  (
    outcomeName: 'defenderVictory',
    goldenFile: 'goldens/player_turn_event_feed_land_combat_defender_holds.png',
    key: 'landCombatFeedDefenderHolds',
    attackerLosses: 5,
    defenderLosses: 0,
    expectedLabel: 'Defender holds',
  ),
  (
    outcomeName: 'stalemate',
    goldenFile: 'goldens/player_turn_event_feed_land_combat_stalemate.png',
    key: 'landCombatFeedStalemate',
    attackerLosses: 0,
    defenderLosses: 0,
    expectedLabel: 'Stalemate',
  ),
  (
    outcomeName: 'mutualAnnihilation',
    goldenFile: 'goldens/player_turn_event_feed_land_combat_both_destroyed.png',
    key: 'landCombatFeedBothDestroyed',
    attackerLosses: 4,
    defenderLosses: 3,
    expectedLabel: 'Both armies destroyed',
  ),
];

Widget _landCombatFeedGoldenHost({
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

Future<void> _pumpLandCombatFeedGolden(
  WidgetTester tester, {
  required Key boundaryKey,
  required List<PlayerTurnEventFeedEntry> entries,
  required Size viewport,
  bool narrow = false,
}) async {
  configureGoldenView(tester, physicalSize: viewport);
  await tester.pumpWidget(
    _landCombatFeedGoldenHost(
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

PlayerTurnEventFeedEntry _landCombatEntry(_LandCombatGoldenCase c) {
  return PlayerTurnEventFeedEntry(
    text: CtEventFeedText.combatResolvedLine(
      provinceLabel: 'Lisbon',
      outcomeLabel: CtEventFeedText.landBattleOutcomeLabel(c.outcomeName),
      attackerLabel: 'Castile',
      defenderLabel: 'Portugal',
      attackerLosses: c.attackerLosses,
      defenderLosses: c.defenderLosses,
    ),
    onTap: () {},
  );
}

void main() {
  suppressLogsForTests();

  group('OVL70001 land-combat feed goldens (#4548)', () {
    for (final c in _kCases) {
      testWidgets('golden: ${c.expectedLabel} with both-side regiment losses', (
        WidgetTester tester,
      ) async {
        final boundaryKey = ValueKey<String>(c.key);
        await _pumpLandCombatFeedGolden(
          tester,
          boundaryKey: boundaryKey,
          viewport: _kWideFeedViewport,
          entries: <PlayerTurnEventFeedEntry>[_landCombatEntry(c)],
        );

        expect(tester.takeException(), isNull);
        expectEditorialMonocleDarkChrome(tester);
        expect(find.textContaining(c.expectedLabel), findsOneWidget);
        expect(find.textContaining('Lisbon'), findsOneWidget);
        expect(find.textContaining('defeated'), findsNothing);

        await expectLater(
          find.byKey(boundaryKey),
          matchesGoldenFile(c.goldenFile),
        );
      });
    }

    testWidgets('golden: Both armies destroyed wraps at 320 dp narrow feed', (
      WidgetTester tester,
    ) async {
      const boundaryKey = ValueKey<String>('landCombatFeedBothDestroyedNarrow');
      final c = _kCases.last;
      await _pumpLandCombatFeedGolden(
        tester,
        boundaryKey: boundaryKey,
        viewport: _kNarrowFeedViewport,
        narrow: true,
        entries: <PlayerTurnEventFeedEntry>[_landCombatEntry(c)],
      );

      expect(tester.takeException(), isNull);
      expectEditorialMonocleDarkChrome(tester);
      expect(find.textContaining('Both armies destroyed'), findsOneWidget);

      await expectLater(
        find.byKey(boundaryKey),
        matchesGoldenFile(
          'goldens/player_turn_event_feed_land_combat_both_destroyed_320dp.png',
        ),
      );
    });
  });
}
