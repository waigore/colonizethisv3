import 'package:colonizethis_app/config/constants.dart';
import 'package:colonizethis_app/features/game/widgets/dialogue/ftp_dialogue_overlay.dart';
import 'package:colonizethis_diplomacy/colonizethis_diplomacy.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'dialogs_320dp_min_viewport_support.dart';

const Size _kMinViewport = kDialogs320MinViewport;
const Size _kWideRegressionViewport = kDialogs320WideRegressionViewport;

void main() {
  suppressLogsForTests();

  group('SPEC/ui/mobile-adaptation.md § 7 — FtpDialogueOverlay @ 320 dp', () {
    Game ftpGame() => buildThreeGpDialogueOverlayGame(id: 'ftp_320');

    const FtpOffer oneOffer = FtpOffer(
      proposerGpId: 'gp_portugal',
      targetGpId: 'gp_player',
    );

    testWidgets(
      'FtpDialogueOverlay (one offer) @ 320×640: no overflow, title and Submit render',
      (WidgetTester tester) async {
        await pumpDialogs320At(
          tester,
          FtpDialogueOverlay(
            game: ftpGame(),
            pending: const [oneOffer],
            onDecisions: (_) {},
            child: const SizedBox.expand(),
          ),
          size: _kMinViewport,
        );

        expect(tester.takeException(), isNull);
        expect(find.text('Favored Trading Partner'), findsOneWidget);
        expect(find.text('Accept'), findsOneWidget);
        expect(find.text('Reject'), findsOneWidget);
        expect(find.text('Submit'), findsOneWidget);
      },
    );

    testWidgets('FtpDialogueOverlay wide viewport pumps without exception', (
      WidgetTester tester,
    ) async {
      await pumpDialogs320At(
        tester,
        FtpDialogueOverlay(
          game: ftpGame(),
          pending: const [oneOffer],
          onDecisions: (_) {},
          child: const SizedBox.expand(),
        ),
        size: _kWideRegressionViewport,
      );
      expect(tester.takeException(), isNull);
    });
  });
}
