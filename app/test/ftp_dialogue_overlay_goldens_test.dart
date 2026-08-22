// Visual goldens for OVL90001 incoming Favored Trading Partner overlay
// (Refs #4586). SPEC/ui/favored-trading-partner-dialogue-overlay.md.

import 'package:colonizethis_app/config/themes.dart';
import 'package:colonizethis_app/features/game/widgets/dialogue/ftp_dialogue_overlay.dart';
import 'package:colonizethis_diplomacy/colonizethis_diplomacy.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'golden_capture_harness.dart';
import 'widget_test_assets.dart';

Game _ftpGame() {
  return const Game(
    id: 'ftp_overlay_goldens',
    worldState: WorldState(
      turnState: TurnState(phase: TurnPhase.orders, turnNumber: 1),
      oldWorld: RegionData(),
      newWorld: RegionData(),
    ),
    players: [
      Player(
        id: 'gp_player',
        displayName: 'England',
        isHuman: true,
        treasury: 0,
      ),
      Player(id: 'gp_spain', displayName: 'Spain', isHuman: false, treasury: 0),
    ],
  );
}

const Widget _overlayChild = ColoredBox(
  color: Color(0xFF101014),
  child: SizedBox.expand(),
);

void main() {
  suppressLogsForTests();

  setUpAll(() async {
    await setUpNinePatchAssets();
  });

  testWidgets(
    'golden: OVL90001 one pending offer first-order Effect (Refs #4586)',
    (WidgetTester tester) async {
      const boundaryKey = ValueKey<String>('ovl90001_ftp_dialogue_one_offer');
      await pumpGoldenHost(
        tester,
        boundaryKey: boundaryKey,
        physicalSize: const Size(360, 800),
        settle: false,
        includeLocalizations: true,
        scaffoldBackgroundColor:
            AppThemes.editorialMonocle.scaffoldBackgroundColor,
        child: FtpDialogueOverlay(
          game: _ftpGame(),
          pending: const [
            FtpOffer(proposerGpId: 'gp_spain', targetGpId: 'gp_player'),
          ],
          onDecisions: (_) {},
          child: _overlayChild,
        ),
      );
      await tester.pump(const Duration(milliseconds: 16));

      expect(tester.takeException(), isNull);
      expect(find.text('Favored Trading Partner'), findsOneWidget);
      expect(find.text('Spain'), findsWidgets);
      expect(find.textContaining('same bid rank'), findsOneWidget);
      expect(find.textContaining('Prices do not change'), findsOneWidget);
      expect(find.textContaining('First right of refusal'), findsWidgets);
      expect(find.textContaining('65'), findsNothing);
      expect(find.text('gp_spain'), findsNothing);

      await expectLater(
        find.byKey(boundaryKey),
        matchesGoldenFile('goldens/ovl90001_ftp_dialogue_one_offer.png'),
      );
    },
  );
}
