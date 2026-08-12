// Widget tests for the empire-wide research funding header (Refs #4335).
//
// SPEC: SPEC/ui/technology-panel.md § Slot turn preview.

import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:colonizethis_app/features/game/widgets/technology/research_slot_preview.dart';
import 'package:colonizethis_app/features/game/widgets/technology/research_turn_funding_header.dart';
import 'app_shell_harness.dart';

TechDefinition _tech() =>
    const TechDefinition(id: 't1', era: 1, category: 'civic', cost: 1000);

void main() {
  suppressLogsForTests();

  Future<void> pumpHeader(
    WidgetTester tester,
    ResearchSlotsTurnPreview preview,
  ) async {
    await tester.pumpWidget(
      buildAppShell(
        child: ResearchTurnFundingHeader(preview: preview),
      ),
    );
    await tester.pump();
  }

  group('ResearchTurnFundingHeader', () {
    testWidgets('shows spend summary when slots will fund research', (
      WidgetTester tester,
    ) async {
      final preview = computeResearchSlotsTurnPreview(
        player: Player(
          id: 'p1',
          displayName: 'Tester',
          isHuman: true,
          treasury: 200,
        ),
        occupiedSlots: [
          ResearchSlotPreviewInput(
            slotIndex: 0,
            tech: _tech(),
            committedProgress: 0,
            funding: ResearchFundingLevel.medium,
          ),
        ],
      );

      await pumpHeader(tester, preview);

      expect(find.byKey(ResearchTurnFundingHeader.summaryKey), findsOneWidget);
      expect(find.textContaining('Research this turn'), findsOneWidget);
      expect(find.textContaining('−£${preview.totalGoldSpent}'), findsOneWidget);
      expect(find.textContaining('+${preview.totalRp} RP'), findsOneWidget);
    });

    testWidgets('shows empty state when no spend occurs', (
      WidgetTester tester,
    ) async {
      await pumpHeader(
        tester,
        const ResearchSlotsTurnPreview(
          bySlotIndex: {},
          totalGoldSpent: 0,
          totalRp: 0,
        ),
      );

      expect(find.text('Research this turn: no spend'), findsOneWidget);
    });
  });
}
