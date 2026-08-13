// Visual goldens for OVL40001 Call to Arms Join/Refuse Effect lines
// (Refs #4364). SPEC/ui/call-to-arms-dialogue-overlay.md § Acceptance Criteria.
import 'package:colonizethis_app/config/constants.dart';
import 'package:colonizethis_app/config/themes.dart';
import 'package:colonizethis_app/features/game/widgets/dialogue/call_to_arms_call_row.dart';
import 'package:colonizethis_app/features/game/widgets/dialogue/call_to_arms_dialogue_overlay.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'golden_capture_harness.dart';
import 'widget_test_assets.dart';

Game _ctaGame() {
  return const Game(
    id: 'cta_choice_effects_goldens',
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
      Player(
        id: 'gp_portugal',
        displayName: 'Portugal',
        isHuman: false,
        treasury: 0,
      ),
      Player(id: 'gp_spain', displayName: 'Spain', isHuman: false, treasury: 0),
      Player(
        id: 'gp_france',
        displayName: 'France',
        isHuman: false,
        treasury: 0,
      ),
      Player(
        id: 'gp_holland',
        displayName: 'Holland',
        isHuman: false,
        treasury: 0,
      ),
    ],
  );
}

const CallToArmsPending _portugalSpainCall = CallToArmsPending(
  allyGpId: 'gp_player',
  defenderGpId: 'gp_portugal',
  aggressorGpId: 'gp_spain',
);

const CallToArmsPending _franceHollandCall = CallToArmsPending(
  allyGpId: 'gp_player',
  defenderGpId: 'gp_france',
  aggressorGpId: 'gp_holland',
);

const Widget _overlayChild = ColoredBox(
  color: Color(0xFF101014),
  child: SizedBox.expand(),
);

Future<void> _pumpOverlayGolden(
  WidgetTester tester, {
  required Key boundaryKey,
  required Size physicalSize,
  required List<CallToArmsPending> pending,
}) async {
  await pumpGoldenHost(
    tester,
    boundaryKey: boundaryKey,
    physicalSize: physicalSize,
    settle: false,
    includeLocalizations: true,
    scaffoldBackgroundColor: AppThemes.editorialMonocle.scaffoldBackgroundColor,
    child: CallToArmsDialogueOverlay(
      game: _ctaGame(),
      pending: pending,
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

  testWidgets('golden: one pending call Join/Refuse Effect lines (Refs #4364)', (
    WidgetTester tester,
  ) async {
    const boundaryKey = ValueKey<String>(
      'call_to_arms_choice_effects_one_call_golden',
    );
    await _pumpOverlayGolden(
      tester,
      boundaryKey: boundaryKey,
      physicalSize: const Size(360, 800),
      pending: const [_portugalSpainCall],
    );

    expect(tester.takeException(), isNull);
    expect(find.text('Formal alliance with Portugal'), findsOneWidget);
    expect(
      find.byKey(ValueKey(CallToArmsCallRow.joinEffectKeyFor(0))),
      findsOneWidget,
    );
    expect(
      find.text(
        'Effect: Enter war with Spain this turn. The treaty with Portugal stays.',
      ),
      findsOneWidget,
    );
    expect(
      find.byKey(ValueKey(CallToArmsCallRow.refuseEffectKeyFor(0))),
      findsOneWidget,
    );
    expect(
      find.text(
        'Effect: The treaty with Portugal ends. Relations with Portugal worsen (−50). Standing with other Great Powers worsens (−10).',
      ),
      findsOneWidget,
    );
    expect(find.textContaining('Friendly'), findsNothing);

    await expectLater(
      find.byKey(boundaryKey),
      matchesGoldenFile('goldens/call_to_arms_choice_effects_one_call.png'),
    );
  });

  testWidgets('golden: two pending calls use per-row Effect names (Refs #4364)', (
    WidgetTester tester,
  ) async {
    const boundaryKey = ValueKey<String>(
      'call_to_arms_choice_effects_two_calls_golden',
    );
    await _pumpOverlayGolden(
      tester,
      boundaryKey: boundaryKey,
      physicalSize: const Size(360, 800),
      pending: const [_portugalSpainCall, _franceHollandCall],
    );

    expect(tester.takeException(), isNull);
    expect(find.text('Formal alliance with Portugal'), findsOneWidget);
    expect(find.text('Formal alliance with France'), findsOneWidget);
    expect(
      find.text(
        'Effect: Enter war with Spain this turn. The treaty with Portugal stays.',
      ),
      findsOneWidget,
    );
    expect(
      find.text(
        'Effect: Enter war with Holland this turn. The treaty with France stays.',
      ),
      findsOneWidget,
    );
    expect(
      find.byKey(ValueKey(CallToArmsCallRow.joinEffectKeyFor(0))),
      findsOneWidget,
    );
    expect(
      find.byKey(ValueKey(CallToArmsCallRow.joinEffectKeyFor(1))),
      findsOneWidget,
    );

    // The 500 dp shell clips the second row at rest; scroll it into view
    // so the golden is not a duplicate of the one-call baseline.
    await tester.ensureVisible(
      find.byKey(ValueKey(CallToArmsCallRow.joinEffectKeyFor(1))),
    );
    await tester.pump();
    await tester.ensureVisible(
      find.byKey(ValueKey(CallToArmsCallRow.refuseEffectKeyFor(1))),
    );
    await tester.pump();

    await expectLater(
      find.byKey(boundaryKey),
      matchesGoldenFile('goldens/call_to_arms_choice_effects_two_calls.png'),
    );
  });

  testWidgets('golden: two pending calls Effect wrap @ 320dp (Refs #4364)', (
    WidgetTester tester,
  ) async {
    const boundaryKey = ValueKey<String>(
      'call_to_arms_choice_effects_two_calls_320dp_golden',
    );
    await _pumpOverlayGolden(
      tester,
      boundaryKey: boundaryKey,
      physicalSize: const Size(kMinViewportWidth, 640),
      pending: const [_portugalSpainCall, _franceHollandCall],
    );

    expect(tester.takeException(), isNull);
    expect(find.text('Call to arms'), findsOneWidget);
    expect(find.text('Join'), findsNWidgets(2));
    expect(find.text('Refuse'), findsNWidgets(2));
    expect(
      find.byKey(ValueKey(CallToArmsCallRow.joinEffectKeyFor(0))),
      findsOneWidget,
    );
    expect(
      find.byKey(ValueKey(CallToArmsCallRow.refuseEffectKeyFor(1))),
      findsOneWidget,
    );

    // Pin wrapped first-row Effect copy in the 320 dp column.
    await tester.ensureVisible(
      find.byKey(ValueKey(CallToArmsCallRow.refuseEffectKeyFor(0))),
    );
    await tester.pump();

    await expectLater(
      find.byKey(boundaryKey),
      matchesGoldenFile(
        'goldens/call_to_arms_choice_effects_two_calls_320dp.png',
      ),
    );
  });
}
