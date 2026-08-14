// Visual goldens for OVL30001 incoming overture Accept/Reject Effect lines
// (Refs #4387). SPEC/ui/overture-dialogue-overlay.md § Acceptance Criteria.
import 'package:colonizethis_app/config/constants.dart';
import 'package:colonizethis_app/config/themes.dart';
import 'package:colonizethis_app/features/game/widgets/dialogue/overture_dialogue_overlay.dart';
import 'package:colonizethis_app/features/game/widgets/dialogue/overture_dialogue_overlay_offer_row.dart';
import 'package:colonizethis_diplomacy/colonizethis_diplomacy.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'golden_capture_harness.dart';
import 'widget_test_assets.dart';

Game _overtureGame() {
  return const Game(
    id: 'overture_choice_effects_goldens',
    worldState: WorldState(
      turnState: TurnState(phase: TurnPhase.orders, turnNumber: 1),
      oldWorld: RegionData(),
      newWorld: RegionData(),
    ),
    players: [
      Player(id: 'gp1', displayName: 'England', isHuman: true, treasury: 0),
      Player(id: 'gp2', displayName: 'Spain', isHuman: false, treasury: 0),
      Player(id: 'gp3', displayName: 'Portugal', isHuman: false, treasury: 0),
    ],
  );
}

const OvertureOffer _spainNap = OvertureOffer(
  offererGpId: 'gp2',
  targetFactionId: 'gp1',
  stage: OvertureStage.nap,
);

const OvertureOffer _portugalJoin = OvertureOffer(
  offererGpId: 'gp3',
  targetFactionId: 'gp1',
  stage: OvertureStage.joinEmpire,
);

const Widget _overlayChild = ColoredBox(
  color: Color(0xFF101014),
  child: SizedBox.expand(),
);

Future<void> _pumpOverlayGolden(
  WidgetTester tester, {
  required Key boundaryKey,
  required Size physicalSize,
  required List<OvertureOffer> offers,
}) async {
  await pumpGoldenHost(
    tester,
    boundaryKey: boundaryKey,
    physicalSize: physicalSize,
    settle: false,
    includeLocalizations: true,
    scaffoldBackgroundColor: AppThemes.editorialMonocle.scaffoldBackgroundColor,
    child: OvertureDialogueOverlay(
      game: _overtureGame(),
      pendingOvertures: offers,
      skipIntroForTest: true,
      onDecisions: (_) {},
      child: _overlayChild,
    ),
  );
  await tester.pump(const Duration(milliseconds: 16));
}

void main() {
  suppressLogsForTests();

  setUpAll(() async {
    await setUpNinePatchAssets();
  });

  testWidgets('golden: NAP Accept/Reject Effect lines (Refs #4387)', (
    WidgetTester tester,
  ) async {
    const boundaryKey = ValueKey<String>('overture_choice_effects_nap_golden');
    await _pumpOverlayGolden(
      tester,
      boundaryKey: boundaryKey,
      physicalSize: const Size(360, 800),
      offers: const [_spainNap],
    );

    final IncomingOvertureEffectLines expected =
        buildIncomingOvertureEffectLines(
          offererDisplayName: 'Spain',
          stage: OvertureStage.nap,
        );
    expect(tester.takeException(), isNull);
    expect(find.text('Spain'), findsOneWidget);
    expect(
      find.byKey(ValueKey(OvertureOfferRow.acceptEffectKeyFor(0))),
      findsOneWidget,
    );
    expect(find.text(expected.acceptEffect), findsOneWidget);
    expect(find.text(expected.rejectEffect), findsOneWidget);
    expect(find.textContaining('standing'), findsNothing);
    expect(find.textContaining('-50'), findsNothing);

    await expectLater(
      find.byKey(boundaryKey),
      matchesGoldenFile('goldens/overture_choice_effects_nap.png'),
    );
  });

  testWidgets('golden: Join Empire absorption Effect lines (Refs #4387)', (
    WidgetTester tester,
  ) async {
    const boundaryKey = ValueKey<String>(
      'overture_choice_effects_join_empire_golden',
    );
    await _pumpOverlayGolden(
      tester,
      boundaryKey: boundaryKey,
      physicalSize: const Size(360, 800),
      offers: const [_portugalJoin],
    );

    final IncomingOvertureEffectLines expected =
        buildIncomingOvertureEffectLines(
          offererDisplayName: 'Portugal',
          stage: OvertureStage.joinEmpire,
        );
    expect(tester.takeException(), isNull);
    expect(find.text(expected.acceptEffect), findsOneWidget);
    expect(find.textContaining('absorbed'), findsOneWidget);
    expect(find.textContaining('joinEmpire'), findsNothing);
    expect(find.textContaining('OvertureStage'), findsNothing);
    expect(
      find.byKey(ValueKey(OvertureOfferRow.rejectEffectKeyFor(0))),
      findsOneWidget,
    );

    await expectLater(
      find.byKey(boundaryKey),
      matchesGoldenFile('goldens/overture_choice_effects_join_empire.png'),
    );
  });

  testWidgets('golden: NAP + Join Empire Effect wrap @ 320dp (Refs #4387)', (
    WidgetTester tester,
  ) async {
    const boundaryKey = ValueKey<String>(
      'overture_choice_effects_nap_join_320dp_golden',
    );
    await _pumpOverlayGolden(
      tester,
      boundaryKey: boundaryKey,
      physicalSize: const Size(kMinViewportWidth, 640),
      offers: const [_spainNap, _portugalJoin],
    );

    expect(tester.takeException(), isNull);
    expect(find.text('Spain'), findsOneWidget);
    expect(find.text('Portugal'), findsOneWidget);
    expect(
      find.byKey(ValueKey(OvertureOfferRow.acceptEffectKeyFor(0))),
      findsOneWidget,
    );
    expect(
      find.byKey(ValueKey(OvertureOfferRow.rejectEffectKeyFor(1))),
      findsOneWidget,
    );

    await tester.ensureVisible(
      find.byKey(ValueKey(OvertureOfferRow.rejectEffectKeyFor(0))),
    );
    await tester.pump();

    await expectLater(
      find.byKey(boundaryKey),
      matchesGoldenFile('goldens/overture_choice_effects_nap_join_320dp.png'),
    );
  });
}
