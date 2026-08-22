import 'package:colonizethis_app/features/game/widgets/dialogue/ftp_dialogue_offer_row.dart';
import 'package:colonizethis_app/features/game/widgets/dialogue/ftp_dialogue_overlay.dart';
import 'package:colonizethis_app/widgets/ct_nine_patch_button.dart';
import 'package:colonizethis_diplomacy/colonizethis_diplomacy.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'app_shell_harness.dart';

Game _ftpGame() {
  return const Game(
    id: 'ftp_overlay',
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
      Player(
        id: 'gp_portugal',
        displayName: 'Portugal',
        isHuman: false,
        treasury: 0,
      ),
    ],
  );
}

Future<void> _pumpOverlay(
  WidgetTester tester, {
  required List<FtpOffer> pending,
  required void Function(List<FtpDecision>) onDecisions,
}) async {
  await tester.pumpWidget(
    buildAppShell(
      child: Scaffold(
        body: FtpDialogueOverlay(
          game: _ftpGame(),
          pending: pending,
          onDecisions: onDecisions,
          child: const SizedBox.expand(),
        ),
      ),
    ),
  );
  await tester.pump();
}

void main() {
  suppressLogsForTests();

  testWidgets('one offer names court and first-order Accept/Reject effects', (
    tester,
  ) async {
    await _pumpOverlay(
      tester,
      pending: const [
        FtpOffer(proposerGpId: 'gp_spain', targetGpId: 'gp_player'),
      ],
      onDecisions: (_) {},
    );

    expect(find.text('Favored Trading Partner'), findsOneWidget);
    expect(find.text('Spain'), findsWidgets);
    expect(
      find.text(
        'Effect: If you accept, you become Favored Trading Partners with Spain.',
      ),
      findsOneWidget,
    );
    expect(find.textContaining('same bid rank'), findsOneWidget);
    expect(find.textContaining('Prices do not change'), findsOneWidget);
    expect(
      find.text('Effect: This does not beat First right of refusal.'),
      findsOneWidget,
    );
    expect(
      find.text('Effect: You decline Favored Trading Partner with Spain.'),
      findsOneWidget,
    );
    expect(find.text('65'), findsNothing);
    expect(find.text('gp_spain'), findsNothing);
    expect(
      tester
          .widget<CtNinePatchButton>(
            find.byKey(const ValueKey('ftpSubmitButton')),
          )
          .enabled,
      isFalse,
    );
  });

  testWidgets('Submit stays off until every offer is decided', (tester) async {
    tester.view.physicalSize = const Size(800, 1400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    List<FtpDecision>? emitted;
    await _pumpOverlay(
      tester,
      pending: const [
        FtpOffer(proposerGpId: 'gp_spain', targetGpId: 'gp_player'),
        FtpOffer(proposerGpId: 'gp_portugal', targetGpId: 'gp_player'),
      ],
      onDecisions: (d) => emitted = d,
    );

    expect(
      tester
          .widget<CtNinePatchButton>(
            find.byKey(const ValueKey('ftpSubmitButton')),
          )
          .enabled,
      isFalse,
    );

    await tester.tap(
      find.byKey(ValueKey(FtpDialogueOfferRow.acceptToggleKeyFor(0))),
    );
    await tester.pump();
    expect(
      tester
          .widget<CtNinePatchButton>(
            find.byKey(const ValueKey('ftpSubmitButton')),
          )
          .enabled,
      isFalse,
    );

    await tester.tap(
      find.byKey(ValueKey(FtpDialogueOfferRow.rejectToggleKeyFor(1))),
    );
    await tester.pump();
    final submit = tester.widget<CtNinePatchButton>(
      find.byKey(const ValueKey('ftpSubmitButton')),
    );
    expect(submit.enabled, isTrue);
    submit.onPressed!();
    await tester.pump();

    expect(emitted, isNotNull);
    expect(emitted, hasLength(2));
    expect(emitted![0].proposerGpId, 'gp_spain');
    expect(emitted![0].accepted, isTrue);
    expect(emitted![1].proposerGpId, 'gp_portugal');
    expect(emitted![1].accepted, isFalse);
  });
}
