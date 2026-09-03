// Visual goldens for research funding-breakdown spy-insight dialogs
// (Refs #4457 / #4720 Slice F).
// SPEC: SPEC/ui/technology-panel.md § Slot turn preview.

import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:colonizethis_app/features/game/widgets/technology/research_slot_preview.dart';
import 'package:colonizethis_app/features/game/widgets/technology/research_slot_turn_preview_view.dart';

import 'golden_capture_harness.dart';

const int _kCost = 1800;
const int _kCommitted = 600;

const ResearchSlotTurnPreview _spyInsightOne = ResearchSlotTurnPreview(
  funding: ResearchFundingLevel.medium,
  committedProgress: _kCommitted,
  cost: _kCost,
  baseRpPerTurn: 300,
  industrialBonusRpPerTurn: 0,
  anticipatedRpPerTurn: 345,
  goldCostPerTurn: 150,
  goldSpentThisTurn: 150,
  debtBlocked: false,
  spyInsightRpPerTurn: 45,
  spyInsightRivalCount: 1,
  spyInsightRivalNames: ['France'],
);

const ResearchSlotTurnPreview _spyInsightTwo = ResearchSlotTurnPreview(
  funding: ResearchFundingLevel.medium,
  committedProgress: _kCommitted,
  cost: _kCost,
  baseRpPerTurn: 300,
  industrialBonusRpPerTurn: 0,
  anticipatedRpPerTurn: 390,
  goldCostPerTurn: 150,
  goldSpentThisTurn: 150,
  debtBlocked: false,
  spyInsightRpPerTurn: 90,
  spyInsightRivalCount: 2,
  spyInsightRivalNames: ['France', 'Spain'],
);

Future<void> _pumpHost(
  WidgetTester tester, {
  required Key boundaryKey,
  required Widget child,
  Size surfaceSize = const Size(380, 360),
}) {
  return pumpGoldenHost(
    tester,
    boundaryKey: boundaryKey,
    physicalSize: surfaceSize,
    includeLocalizations: true,
    child: child,
  );
}

void main() {
  suppressLogsForTests();

  testWidgets('golden: spy-insight breakdown one rival (Refs #4457)', (
    WidgetTester tester,
  ) async {
    const boundaryKey = ValueKey<String>('researchFundingBreakdownSpyOne');
    await _pumpHost(
      tester,
      boundaryKey: boundaryKey,
      surfaceSize: const Size(420, 400),
      child: const ResearchFundingBreakdownDialog(preview: _spyInsightOne),
    );

    expect(tester.takeException(), isNull);
    await expectLater(
      find.byKey(boundaryKey),
      matchesGoldenFile('goldens/research_funding_breakdown_spy_one.png'),
    );
  });

  testWidgets('golden: spy-insight breakdown two rivals (Refs #4457)', (
    WidgetTester tester,
  ) async {
    const boundaryKey = ValueKey<String>('researchFundingBreakdownSpyTwo');
    await _pumpHost(
      tester,
      boundaryKey: boundaryKey,
      surfaceSize: const Size(420, 400),
      child: const ResearchFundingBreakdownDialog(preview: _spyInsightTwo),
    );

    expect(tester.takeException(), isNull);
    await expectLater(
      find.byKey(boundaryKey),
      matchesGoldenFile('goldens/research_funding_breakdown_spy_two.png'),
    );
  });
}
