// Visual goldens for OVL30001 incoming overture Accept/Reject Effect lines
// (Refs #4387). SPEC/ui/overture-dialogue-overlay.md § Acceptance Criteria.
import 'package:colonizethis_app/features/game/widgets/dialogue/overture_dialogue_overlay_offer_row.dart';
import 'package:colonizethis_diplomacy/colonizethis_diplomacy.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'overture_dialogue_overlay_choice_effects_goldens_support.dart';
import 'widget_test_assets.dart';

void main() {
  suppressLogsForTests();

  setUpAll(() async {
    await setUpNinePatchAssets();
  });

  testWidgets('golden: NAP Accept/Reject Effect lines (Refs #4387)', (
    WidgetTester tester,
  ) async {
    const boundaryKey = ValueKey<String>('overture_choice_effects_nap_golden');
    await pumpOvertureChoiceEffectsGolden(
      tester,
      boundaryKey: boundaryKey,
      physicalSize: const Size(360, 800),
      offers: const [spainNapOffer],
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
    await pumpOvertureChoiceEffectsGolden(
      tester,
      boundaryKey: boundaryKey,
      physicalSize: const Size(360, 800),
      offers: const [portugalJoinOffer],
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
}
