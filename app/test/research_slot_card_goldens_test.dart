// Visual goldens for the GAME40001 research slot-card turn-preview states (Refs #3512).

import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:colonizethis_app/features/game/widgets/technology/research_slot_turn_preview_view.dart';

import 'research_slot_card_goldens_fixtures.dart';

void main() {
  suppressLogsForTests();

  testWidgets(
    'golden: Medium-funded slot card shows toggles, dual-segment bar, RP delta '
    'and gold row (Refs #3512 AC6/AC8/AC12)',
    (WidgetTester tester) async {
      const boundaryKey = ValueKey<String>('researchSlotCardMediumGolden');
      await pumpResearchSlotCardGoldenHost(
        tester,
        boundaryKey: boundaryKey,
        child: researchSlotCardGoldenSlotCard(
          funding: ResearchFundingLevel.medium,
          preview: researchSlotCardGoldenMediumFunded,
        ),
      );

      expect(tester.takeException(), isNull);
      await expectLater(
        find.byKey(boundaryKey),
        matchesGoldenFile('goldens/research_slot_card_medium_funded.png'),
      );
    },
  );

  testWidgets(
    'golden: None-funding slot card hides the RP delta and collapses the gold '
    'row (Refs #3512 AC9)',
    (WidgetTester tester) async {
      const boundaryKey = ValueKey<String>('researchSlotCardNoneGolden');
      await pumpResearchSlotCardGoldenHost(
        tester,
        boundaryKey: boundaryKey,
        child: researchSlotCardGoldenSlotCard(
          funding: ResearchFundingLevel.none,
          preview: researchSlotCardGoldenNoneFunding,
        ),
      );

      expect(tester.takeException(), isNull);
      await expectLater(
        find.byKey(boundaryKey),
        matchesGoldenFile('goldens/research_slot_card_none_funding.png'),
      );
    },
  );

  testWidgets(
    'golden: debt-blocked slot card hides segment B / RP delta and greys the '
    'gold row (Refs #3512 AC10)',
    (WidgetTester tester) async {
      const boundaryKey = ValueKey<String>('researchSlotCardDebtBlockedGolden');
      await pumpResearchSlotCardGoldenHost(
        tester,
        boundaryKey: boundaryKey,
        child: researchSlotCardGoldenSlotCard(
          funding: ResearchFundingLevel.medium,
          preview: researchSlotCardGoldenDebtBlocked,
        ),
      );

      expect(tester.takeException(), isNull);
      await expectLater(
        find.byKey(boundaryKey),
        matchesGoldenFile('goldens/research_slot_card_debt_blocked.png'),
      );
    },
  );

  testWidgets('golden: research funding breakdown dialog (Refs #3512 AC11)', (
    WidgetTester tester,
  ) async {
    const boundaryKey = ValueKey<String>('researchFundingBreakdownGolden');
    await pumpResearchSlotCardGoldenHost(
      tester,
      boundaryKey: boundaryKey,
      surfaceSize: const Size(420, 360),
      child: const ResearchFundingBreakdownDialog(
        preview: researchSlotCardGoldenMediumFunded,
      ),
    );

    expect(tester.takeException(), isNull);
    await expectLater(
      find.byKey(boundaryKey),
      matchesGoldenFile('goldens/research_funding_breakdown_dialog.png'),
    );
  });

  testWidgets('golden: spy-insight Medium slot card (Refs #4457)', (
    WidgetTester tester,
  ) async {
    const boundaryKey = ValueKey<String>('researchSlotCardSpyInsightGolden');
    await pumpResearchSlotCardGoldenHost(
      tester,
      boundaryKey: boundaryKey,
      child: researchSlotCardGoldenSlotCard(
        funding: ResearchFundingLevel.medium,
        preview: researchSlotCardGoldenSpyInsightOne,
      ),
    );

    expect(tester.takeException(), isNull);
    await expectLater(
      find.byKey(boundaryKey),
      matchesGoldenFile('goldens/research_slot_card_spy_insight.png'),
    );
  });

  testWidgets('golden: Completes next turn finish-time line (Refs #4511)', (
    WidgetTester tester,
  ) async {
    const boundaryKey = ValueKey<String>('researchSlotCardCompletesNextTurn');
    await pumpResearchSlotCardGoldenHost(
      tester,
      boundaryKey: boundaryKey,
      child: researchSlotCardGoldenSlotCard(
        funding: ResearchFundingLevel.medium,
        preview: researchSlotCardGoldenCompletesNextTurn,
      ),
    );

    expect(tester.takeException(), isNull);
    await expectLater(
      find.byKey(boundaryKey),
      matchesGoldenFile('goldens/research_slot_card_completes_next_turn.png'),
    );
  });
}
