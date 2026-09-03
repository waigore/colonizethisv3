// Visual goldens for OVL30001 Consulate/Embassy targets and 320dp wrap
// (Refs #4720 Slice G / #4387 / #4682).
// SPEC/ui/overture-dialogue-overlay.md § Acceptance Criteria.
import 'package:colonizethis_app/config/constants.dart';
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

  testWidgets(
    'golden: Consulate Accept Effect GP and Minor targets (Refs #4682)',
    (WidgetTester tester) async {
      const boundaryKey = ValueKey<String>(
        'overture_choice_effects_consulate_golden',
      );
      await pumpOvertureChoiceEffectsGolden(
        tester,
        boundaryKey: boundaryKey,
        physicalSize: const Size(kMinViewportWidth, 720),
        offers: const [spainConsulateGpOffer, spainConsulateMinorOffer],
        game: overtureChoiceEffectsGameWithMinor(),
      );

      final gpExpected = buildIncomingOvertureEffectLines(
        offererDisplayName: 'Spain',
        stage: OvertureStage.tradeConsulate,
        game: overtureChoiceEffectsGameWithMinor(),
        targetFactionId: 'gp1',
      );
      final minorExpected = buildIncomingOvertureEffectLines(
        offererDisplayName: 'Spain',
        stage: OvertureStage.tradeConsulate,
        game: overtureChoiceEffectsGameWithMinor(),
        targetFactionId: 'minor1',
      );
      expect(tester.takeException(), isNull);
      expect(find.text(gpExpected.acceptEffect), findsOneWidget);
      expect(find.text(minorExpected.acceptEffect), findsOneWidget);
      expect(find.textContaining('Explore and Prospect'), findsOneWidget);
      expect(find.textContaining('Trade Consulate'), findsOneWidget);

      await expectLater(
        find.byKey(boundaryKey),
        matchesGoldenFile('goldens/overture_choice_effects_consulate.png'),
      );
    },
  );

  testWidgets(
    'golden: Embassy Accept Effect GP and Minor targets (Refs #4682)',
    (WidgetTester tester) async {
      const boundaryKey = ValueKey<String>(
        'overture_choice_effects_embassy_golden',
      );
      await pumpOvertureChoiceEffectsGolden(
        tester,
        boundaryKey: boundaryKey,
        physicalSize: const Size(kMinViewportWidth, 720),
        offers: const [spainEmbassyGpOffer, spainEmbassyMinorOffer],
        game: overtureChoiceEffectsGameWithMinor(),
      );

      final gpExpected = buildIncomingOvertureEffectLines(
        offererDisplayName: 'Spain',
        stage: OvertureStage.embassy,
        game: overtureChoiceEffectsGameWithMinor(),
        targetFactionId: 'gp1',
      );
      final minorExpected = buildIncomingOvertureEffectLines(
        offererDisplayName: 'Spain',
        stage: OvertureStage.embassy,
        game: overtureChoiceEffectsGameWithMinor(),
        targetFactionId: 'minor1',
      );
      expect(tester.takeException(), isNull);
      expect(find.text(gpExpected.acceptEffect), findsOneWidget);
      expect(find.text(minorExpected.acceptEffect), findsOneWidget);
      expect(find.textContaining('Grant Aid'), findsOneWidget);
      expect(find.textContaining('Embassy with Spain'), findsOneWidget);

      await expectLater(
        find.byKey(boundaryKey),
        matchesGoldenFile('goldens/overture_choice_effects_embassy.png'),
      );
    },
  );

  testWidgets('golden: NAP + Join Empire Effect wrap @ 320dp (Refs #4387)', (
    WidgetTester tester,
  ) async {
    const boundaryKey = ValueKey<String>(
      'overture_choice_effects_nap_join_320dp_golden',
    );
    await pumpOvertureChoiceEffectsGolden(
      tester,
      boundaryKey: boundaryKey,
      physicalSize: const Size(kMinViewportWidth, 640),
      offers: const [spainNapOffer, portugalJoinOffer],
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
