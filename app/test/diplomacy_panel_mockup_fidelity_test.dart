// SPEC/ui/diplomacy-panel.md § Mode bar, § Per-faction row (Refs #3621).

import 'package:colonizethis_logic/colonizethis_logic.dart'
    show relationScoreToMeterStep;
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:colonizethis_app_ui_chrome/config/editorial_monocle_palette.dart';
import 'package:colonizethis_app/features/game/widgets/diplomacy/diplomacy_panel_constants.dart'
    show diplomacyRelationWordColor;
import 'package:colonizethis_app/widgets/ct_gradients.dart';
import 'package:colonizethis_app/widgets/ct_spacing.dart';
import 'package:colonizethis_app/widgets/relation_meter.dart';

import 'diplomacy_panel_mockup_fidelity_support.dart';
import 'diplomacy_panel_test_support.dart';

void main() {
  suppressLogsForTests();

  setUp(AppEventBus.reset);

  Future<void> bindSurface(WidgetTester tester) async {
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.binding.setSurfaceSize(const Size(600, 1100));
  }

  group('Diplomacy mode-bar chip chrome (AC4, Refs #3621)', () {
    testWidgets('inactive chip paints action gradient + --border outline', (
      WidgetTester tester,
    ) async {
      await bindSurface(tester);
      await tester.pumpWidget(
        diplomacyMockupPanelHost(diplomacyMockupEmptyStateGame()),
      );
      await pumpDiplomacyPanelBuilt(tester);

      final BoxDecoration deco = diplomacyMockupChipDecoration(
        tester,
        'Great Powers only',
      );
      expect(deco.gradient, CtGradients.actionButtonGradient);
      final Border border = deco.border! as Border;
      expect(border.top.width, 1);
      expect(border.top.color, EditorialMonoclePalette.border);
    });

    testWidgets('active chip paints action gradient + --accent-dim outline', (
      WidgetTester tester,
    ) async {
      await bindSurface(tester);
      await tester.pumpWidget(
        diplomacyMockupPanelHost(diplomacyMockupEmptyStateGame()),
      );
      await pumpDiplomacyPanelBuilt(tester);

      final BoxDecoration deco = diplomacyMockupChipDecoration(tester, 'All');
      expect(deco.gradient, CtGradients.actionButtonGradient);
      final Border border = deco.border! as Border;
      expect(border.top.width, 1);
      expect(border.top.color, EditorialMonoclePalette.accentDim);
    });
  });

  group('Diplomacy economic lines styling (AC7, Refs #3621)', () {
    testWidgets('outgoing subsidy line is mono, --accent-dim, non-italic', (
      WidgetTester tester,
    ) async {
      await bindSurface(tester);
      await tester.pumpWidget(
        diplomacyMockupPanelHost(diplomacyMockupSubsidyGame()),
      );
      await pumpDiplomacyPanelBuilt(tester);

      final Finder subsidyLine = find.textContaining('Outgoing subsidy');
      expect(subsidyLine, findsOneWidget);
      final Text text = tester.widget<Text>(subsidyLine);
      expect(text.style?.fontFamily, 'monospace');
      expect(text.style?.color, EditorialMonoclePalette.accentDim);
      expect(text.style?.fontStyle, isNot(FontStyle.italic));
    });
  });

  group('Diplomacy relation word styling (AC5, Refs #3621)', () {
    testWidgets('relation word renders italic in its meter-step color', (
      WidgetTester tester,
    ) async {
      await pumpDiplomacyMockupRelation(tester, 60);
      final TextSpan word = diplomacyMockupRelationWordSpan(tester, 'Cordial');
      expect(word.style?.fontStyle, FontStyle.italic);
      expect(word.style?.color, relationMeterStepColor(7));
    });

    testWidgets('Hostile word (step 1) resolves to --danger', (
      WidgetTester tester,
    ) async {
      await pumpDiplomacyMockupRelation(tester, 5);
      final TextSpan word = diplomacyMockupRelationWordSpan(tester, 'Hostile');
      expect(word.style?.color, EditorialMonoclePalette.danger);
      expect(word.style?.fontStyle, FontStyle.italic);
    });

    testWidgets('interior word (step 5) resolves to its gradient color', (
      WidgetTester tester,
    ) async {
      await pumpDiplomacyMockupRelation(tester, 40);
      final TextSpan word = diplomacyMockupRelationWordSpan(tester, 'Wary');
      expect(word.style?.color, relationMeterStepColor(5));
    });

    testWidgets('Devoted word (step 10) resolves to --success', (
      WidgetTester tester,
    ) async {
      await pumpDiplomacyMockupRelation(tester, 95);
      final TextSpan word = diplomacyMockupRelationWordSpan(tester, 'Devoted');
      expect(word.style?.color, EditorialMonoclePalette.success);
    });

    test('diplomacyRelationWordColor follows the meter-step gradient', () {
      expect(diplomacyRelationWordColor(0), EditorialMonoclePalette.danger);
      expect(diplomacyRelationWordColor(9.9), EditorialMonoclePalette.danger);
      expect(diplomacyRelationWordColor(100), EditorialMonoclePalette.success);
      expect(diplomacyRelationWordColor(90), EditorialMonoclePalette.success);
      for (final num score in <num>[15, 25, 35, 45, 55, 65, 75, 85]) {
        expect(
          diplomacyRelationWordColor(score),
          relationMeterStepColor(relationScoreToMeterStep(score)),
        );
      }
    });
  });

  group('Diplomacy section heading rhythm (AC8, Refs #3621)', () {
    testWidgets('first heading has zero top gap; later headings keep --l gap', (
      WidgetTester tester,
    ) async {
      await bindSurface(tester);
      await tester.pumpWidget(
        diplomacyMockupPanelHost(diplomacyMockupEmptyStateGame()),
      );
      await pumpDiplomacyPanelBuilt(tester);

      expect(diplomacyMockupHeadingOuterPadding(tester, 'Great Powers').top, 0);
      expect(
        diplomacyMockupHeadingOuterPadding(tester, 'Minor Nations').top,
        CtSpacing.l,
      );
    });
  });
}
