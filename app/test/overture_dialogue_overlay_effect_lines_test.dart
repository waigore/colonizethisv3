// Pins first-order Effect copy on OVL30001 incoming overture rows (Refs #4387).
import 'package:colonizethis_app/features/game/widgets/dialogue/overture_dialogue_overlay.dart';
import 'package:colonizethis_app/features/game/widgets/dialogue/overture_dialogue_overlay_offer_row.dart';
import 'package:colonizethis_app/widgets/ct_toggle_switch.dart';
import 'package:colonizethis_diplomacy/colonizethis_diplomacy.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'app_shell_harness.dart';

Game _game() {
  return const Game(
    id: 'overture_effects',
    worldState: WorldState(
      turnState: TurnState(phase: TurnPhase.orders, turnNumber: 1),
      oldWorld: RegionData(),
      newWorld: RegionData(),
    ),
    players: [
      Player(id: 'gp1', displayName: 'England', isHuman: true, treasury: 0),
      Player(id: 'gp2', displayName: 'Spain', isHuman: false, treasury: 0),
    ],
  );
}

Future<void> _pumpOverlay(
  WidgetTester tester, {
  required List<OvertureOffer> offers,
  void Function(List<OvertureDecision>)? onDecisions,
  bool skipIntroForTest = true,
}) async {
  await tester.pumpWidget(
    buildAppShell(
      child: OvertureDialogueOverlay(
        game: _game(),
        pendingOvertures: offers,
        skipIntroForTest: skipIntroForTest,
        onDecisions: onDecisions ?? (_) {},
        child: const SizedBox.expand(),
      ),
    ),
  );
  await tester.pump();
}

void main() {
  suppressLogsForTests();

  const napOffer = OvertureOffer(
    offererGpId: 'gp2',
    targetFactionId: 'gp1',
    stage: OvertureStage.nap,
  );
  const joinOffer = OvertureOffer(
    offererGpId: 'gp2',
    targetFactionId: 'gp1',
    stage: OvertureStage.joinEmpire,
  );
  const consulateOffer = OvertureOffer(
    offererGpId: 'gp2',
    targetFactionId: 'gp1',
    stage: OvertureStage.tradeConsulate,
  );

  testWidgets('NAP row shows pact Effect and reject-without-penalty copy', (
    tester,
  ) async {
    await _pumpOverlay(tester, offers: const [napOffer]);
    final expected = buildIncomingOvertureEffectLines(
      offererDisplayName: 'Spain',
      stage: OvertureStage.nap,
    );
    expect(
      find.byKey(ValueKey(OvertureOfferRow.acceptEffectKeyFor(0))),
      findsOneWidget,
    );
    expect(find.text(expected.acceptEffect), findsOneWidget);
    expect(find.text(expected.rejectEffect), findsOneWidget);
    expect(find.textContaining('standing'), findsNothing);
    expect(find.textContaining('-50'), findsNothing);
  });

  testWidgets('Join Empire accept Effect states absorption, not enum ids', (
    tester,
  ) async {
    await _pumpOverlay(tester, offers: const [joinOffer]);
    final expected = buildIncomingOvertureEffectLines(
      offererDisplayName: 'Spain',
      stage: OvertureStage.joinEmpire,
    );
    expect(find.text(expected.acceptEffect), findsOneWidget);
    expect(find.textContaining('absorbed'), findsOneWidget);
    expect(find.textContaining('joinEmpire'), findsNothing);
    expect(find.textContaining('OvertureStage'), findsNothing);
    expect(find.textContaining('standing'), findsNothing);
  });

  testWidgets('Consulate accept Effect states the human pays nothing', (
    tester,
  ) async {
    await _pumpOverlay(tester, offers: const [consulateOffer]);
    final expected = buildIncomingOvertureEffectLines(
      offererDisplayName: 'Spain',
      stage: OvertureStage.tradeConsulate,
    );
    expect(find.text(expected.acceptEffect), findsOneWidget);
    expect(find.textContaining('You pay nothing'), findsWidgets);
  });

  testWidgets('Effect lines are read-only: Submit still emits decisions', (
    tester,
  ) async {
    List<OvertureDecision>? emitted;
    await _pumpOverlay(
      tester,
      offers: const [napOffer],
      onDecisions: (d) => emitted = d,
    );
    await tester.tap(
      find.byKey(ValueKey(OvertureOfferRow.acceptToggleKeyFor(0))),
    );
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('overtureSubmitButton')));
    await tester.pump();
    expect(emitted, isNotNull);
    expect(emitted, hasLength(1));
    expect(emitted!.single.accepted, isTrue);
    expect(emitted!.single.offererGpId, 'gp2');
    expect(emitted!.single.stage, OvertureStage.nap);
  });

  testWidgets('Yarn intro / loading does not mount phase-2 Effect keys', (
    tester,
  ) async {
    await _pumpOverlay(
      tester,
      offers: const [napOffer],
      skipIntroForTest: false,
    );
    expect(
      find.byKey(ValueKey(OvertureOfferRow.acceptEffectKeyFor(0))),
      findsNothing,
    );
    expect(
      find.byKey(ValueKey(OvertureOfferRow.rejectEffectKeyFor(0))),
      findsNothing,
    );
    expect(find.byType(CtToggleSwitch), findsNothing);
  });
}
