// Widget tests for the GAME40001 research slot turn-preview view (Refs #3512):
// the dual-segment progress bar, the anticipated-RP delta that opens the
// breakdown dialog, and the treasury (gold) preview row.
//
// SPEC: SPEC/ui/technology-panel.md § Slot turn preview.

import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:colonizethis_app/features/game/utils/research_slot_preview.dart';
import 'package:colonizethis_app/features/game/widgets/research_slot_turn_preview_view.dart';

import 'support/app_shell_harness.dart';

Player _player({int treasury = 0, Map<String, bool>? techUnlocked}) {
  return Player(
    id: 'p1',
    displayName: 'Tester',
    isHuman: true,
    treasury: treasury,
    techUnlocked: techUnlocked,
  );
}

TechDefinition _tech({String category = 'civic', int cost = 1000}) {
  return TechDefinition(id: 't1', era: 1, category: category, cost: cost);
}

ResearchSlotTurnPreview _preview({
  int treasury = 10000,
  int committedProgress = 400,
  ResearchFundingLevel funding = ResearchFundingLevel.medium,
  Map<String, bool>? techUnlocked,
  String category = 'civic',
}) {
  return computeResearchSlotTurnPreview(
    player: _player(treasury: treasury, techUnlocked: techUnlocked),
    tech: _tech(category: category),
    committedProgress: committedProgress,
    funding: funding,
  );
}

Future<void> _pumpView(
  WidgetTester tester,
  ResearchSlotTurnPreview preview, {
  int slotIndex = 0,
}) async {
  await pumpAppShell(
    tester,
    settle: true,
    child: Scaffold(
      body: SizedBox(
        width: 360,
        child: ResearchSlotTurnPreviewView(
          slotIndex: slotIndex,
          preview: preview,
        ),
      ),
    ),
  );
}

void main() {
  suppressLogsForTests();

  testWidgets(
    'positive: anticipated spend renders the segment-B fill, RP delta, and gold row',
    (WidgetTester tester) async {
      await _pumpView(tester, _preview());

      expect(
        find.byKey(ResearchSlotTurnPreviewView.anticipatedSegmentKey(0)),
        findsOneWidget,
      );
      expect(
        find.byKey(ResearchSlotTurnPreviewView.rpDeltaKey(0)),
        findsOneWidget,
      );
      expect(
        find.byKey(ResearchSlotTurnPreviewView.goldRowKey(0)),
        findsOneWidget,
      );
    },
  );

  testWidgets(
    'positive: tapping the RP delta opens the funding breakdown dialog',
    (WidgetTester tester) async {
      await _pumpView(tester, _preview());

      await tester.tap(find.byKey(ResearchSlotTurnPreviewView.rpDeltaKey(0)));
      await tester.pumpAndSettle();

      expect(find.byType(ResearchFundingBreakdownDialog), findsOneWidget);
    },
  );

  testWidgets(
    'negative: a debt-blocked slot shows no anticipated segment and no RP delta',
    (WidgetTester tester) async {
      // treasury 0, no money_lending => max debt 0 => Medium spend blocked.
      await _pumpView(tester, _preview(treasury: 0));

      expect(
        find.byKey(ResearchSlotTurnPreviewView.anticipatedSegmentKey(0)),
        findsNothing,
      );
      expect(
        find.byKey(ResearchSlotTurnPreviewView.rpDeltaKey(0)),
        findsNothing,
      );
      // The gold row still renders (greyed, no-spend) so the cost is visible.
      expect(
        find.byKey(ResearchSlotTurnPreviewView.goldRowKey(0)),
        findsOneWidget,
      );
    },
  );

  testWidgets(
    'negative: None funding hides the gold row entirely',
    (WidgetTester tester) async {
      await _pumpView(
        tester,
        _preview(funding: ResearchFundingLevel.none),
      );

      expect(
        find.byKey(ResearchSlotTurnPreviewView.rpDeltaKey(0)),
        findsNothing,
      );
      expect(
        find.byKey(ResearchSlotTurnPreviewView.goldRowKey(0)),
        findsOneWidget,
      );
      // The gold row collapses to an empty box under None funding.
      final Size size = tester.getSize(
        find.byKey(ResearchSlotTurnPreviewView.goldRowKey(0)),
      );
      expect(size.height, 0);
    },
  );
}
