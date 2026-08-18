// Widget tests for the GAME40001 slot-card finish-time line (Refs #4511).
//
// SPEC: SPEC/ui/technology-panel.md § Slot turn preview (Finish-time line).

import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:colonizethis_app/features/game/widgets/technology/research_slot_finish_estimate.dart';
import 'package:colonizethis_app/features/game/widgets/technology/research_slot_preview.dart';
import 'package:colonizethis_app/features/game/widgets/technology/research_slot_turn_preview_view.dart';
import 'package:colonizethis_app/features/game/widgets/technology/research_slot_turn_preview_view_breakdown.dart';
import 'package:colonizethis_app/features/game/widgets/technology/technology_panel.dart';
import 'package:colonizethis_app/features/game/widgets/technology/technology_slot_funding_toggles.dart';

import 'app_shell_harness.dart';

ResearchSlotTurnPreview _preview({
  int committedProgress = 600,
  int cost = 1800,
  int anticipatedRpPerTurn = 300,
  ResearchFundingLevel funding = ResearchFundingLevel.medium,
  bool debtBlocked = false,
}) {
  return ResearchSlotTurnPreview(
    funding: funding,
    committedProgress: committedProgress,
    cost: cost,
    baseRpPerTurn: anticipatedRpPerTurn,
    industrialBonusRpPerTurn: 0,
    anticipatedRpPerTurn: anticipatedRpPerTurn,
    goldCostPerTurn: funding == ResearchFundingLevel.none ? 0 : 150,
    goldSpentThisTurn: anticipatedRpPerTurn > 0 ? 150 : 0,
    debtBlocked: debtBlocked,
  );
}

Future<void> _pumpView(
  WidgetTester tester,
  ResearchSlotTurnPreview preview, {
  ResearchFinishCalendar? calendar,
  double width = 360,
}) async {
  await pumpAppShell(
    tester,
    settle: true,
    child: Scaffold(
      body: SizedBox(
        width: width,
        child: ResearchSlotTurnPreviewView(
          slotIndex: 0,
          preview: preview,
          calendar: calendar,
        ),
      ),
    ),
  );
}

void main() {
  suppressLogsForTests();

  testWidgets(
    'positive: remaining RP covered this turn shows Completes next turn',
    (WidgetTester tester) async {
      await _pumpView(
        tester,
        _preview(committedProgress: 1600, anticipatedRpPerTurn: 300),
      );
      expect(
        find.byKey(ResearchSlotTurnPreviewView.finishLineKey(0)),
        findsOneWidget,
      );
      expect(find.text('Completes next turn'), findsOneWidget);
    },
  );

  testWidgets(
    'positive: remaining RP above this-turn RP shows Finishes in N turns',
    (WidgetTester tester) async {
      await _pumpView(tester, _preview());
      expect(find.text('Finishes in 4 turns'), findsOneWidget);
    },
  );

  testWidgets(
    'positive: calendar year is appended when the finish turn is in cap',
    (WidgetTester tester) async {
      const calendar = ResearchFinishCalendar(
        currentTurn: 10,
        mapping: TurnTimeMapping.gdd01,
        infiniteMode: false,
      );
      await _pumpView(
        tester,
        _preview(committedProgress: 1600, anticipatedRpPerTurn: 300),
        calendar: calendar,
      );
      final year = TurnTimeMapping.gdd01.yearAtTurn(11);
      expect(find.text('Completes next turn ($year)'), findsOneWidget);
    },
  );

  testWidgets(
    'negative: year is omitted when the finish turn is after the campaign cap',
    (WidgetTester tester) async {
      const calendar = ResearchFinishCalendar(
        currentTurn: 199,
        mapping: TurnTimeMapping.gdd01,
        infiniteMode: false,
      );
      await _pumpView(
        tester,
        _preview(committedProgress: 0, cost: 1800, anticipatedRpPerTurn: 300),
        calendar: calendar,
      );
      expect(find.text('Finishes in 6 turns'), findsOneWidget);
      expect(find.textContaining('Finishes in 6 turns ('), findsNothing);
    },
  );

  testWidgets('negative: None funding omits the finish-time line', (
    WidgetTester tester,
  ) async {
    await _pumpView(
      tester,
      _preview(funding: ResearchFundingLevel.none, anticipatedRpPerTurn: 0),
    );
    expect(
      find.byKey(ResearchSlotTurnPreviewView.finishLineKey(0)),
      findsNothing,
    );
  });

  testWidgets('negative: debt-blocked slot omits the finish-time line', (
    WidgetTester tester,
  ) async {
    await _pumpView(
      tester,
      _preview(anticipatedRpPerTurn: 0, debtBlocked: true),
    );
    expect(
      find.byKey(ResearchSlotTurnPreviewView.finishLineKey(0)),
      findsNothing,
    );
  });

  testWidgets('positive: breakdown restates remaining RP and implied turns', (
    WidgetTester tester,
  ) async {
    await _pumpView(tester, _preview());
    await tester.tap(find.byKey(ResearchSlotTurnPreviewView.rpDeltaKey(0)));
    await tester.pumpAndSettle();
    expect(find.byType(ResearchFundingBreakdownDialog), findsOneWidget);
    expect(find.text('Remaining: 1200 RP'), findsOneWidget);
    expect(find.text('About 4 more turns at this funding'), findsOneWidget);
  });

  testWidgets(
    'positive: 320 dp finish line wraps and funding toggles stay tappable',
    (WidgetTester tester) async {
      var tapped = false;
      await pumpAppShell(
        tester,
        settle: true,
        child: Scaffold(
          body: SizedBox(
            width: 320,
            child: ResearchSlotCard(
              slotIndex: 0,
              techId: kTechIdCropRotation,
              progress: 600,
              cost: 1800,
              canEdit: true,
              funding: ResearchFundingLevel.medium,
              onFundingChanged: (_) => tapped = true,
              onCancel: () {},
              onChooseTech: () {},
              turnPreview: _preview(),
            ),
          ),
        ),
      );
      expect(find.text('Finishes in 4 turns'), findsOneWidget);
      final Size finishSize = tester.getSize(
        find.byKey(ResearchSlotTurnPreviewView.finishLineKey(0)),
      );
      expect(finishSize.width, lessThanOrEqualTo(320));
      await tester.tap(
        find.byKey(
          SlotFundingToggleRow.toggleKey(0, ResearchFundingLevel.high),
        ),
      );
      await tester.pump();
      expect(tapped, isTrue);
    },
  );
}
