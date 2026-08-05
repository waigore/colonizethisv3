// Golden pins for work-target selection prompt cost + afford row layout.
//
// SPEC: `SPEC/ui/map-widget.md` § Work-target selection afford preview;
// Refs #4262.

import 'package:colonizethis_app/features/game/flame/map_area/game_map_canvas_stack_selection_prompt.dart';
import 'package:colonizethis_orders/colonizethis_orders.dart';
import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'golden_capture_harness.dart';

const Size _kSelectionPromptAffordViewport = Size(640, 180);

Widget _selectionPromptAffordHost({
  required WorkOrderAffordPreview affordPreview,
}) {
  return SizedBox(
    width: _kSelectionPromptAffordViewport.width,
    height: _kSelectionPromptAffordViewport.height,
    child: Stack(
      clipBehavior: Clip.none,
      children: [
        GameMapCanvasStackSelectionPrompt(
          isNarrow: false,
          overlayOpen: false,
          onCancel: () {},
          affordPreview: affordPreview,
        ),
      ],
    ),
  );
}

Future<void> _pumpSelectionPromptAffordGolden(
  WidgetTester tester, {
  required Key boundaryKey,
  required WorkOrderAffordPreview affordPreview,
}) async {
  await pumpGoldenHost(
    tester,
    boundaryKey: boundaryKey,
    physicalSize: _kSelectionPromptAffordViewport,
    includeLocalizations: true,
    useScaffold: false,
    center: false,
    settle: false,
    child: _selectionPromptAffordHost(affordPreview: affordPreview),
  );
}

void main() {
  suppressLogsForTests();

  testWidgets(
    'golden: selection prompt can afford material costs (Refs #4262)',
    (WidgetTester tester) async {
      const boundaryKey = ValueKey<String>('selectionPromptAffordCanAfford');
      await _pumpSelectionPromptAffordGolden(
        tester,
        boundaryKey: boundaryKey,
        affordPreview: const WorkOrderAffordPreview(
          materialCosts: {'lumber': 1, 'castIron': 2},
          canAfford: true,
        ),
      );

      expect(find.textContaining('Can afford'), findsOneWidget);
      await expectLater(
        find.byKey(boundaryKey),
        matchesGoldenFile('goldens/selection_prompt_afford_can_afford.png'),
      );
    },
  );

  testWidgets(
    'golden: selection prompt material shortfall (Refs #4262)',
    (WidgetTester tester) async {
      const boundaryKey = ValueKey<String>('selectionPromptAffordMaterialShort');
      await _pumpSelectionPromptAffordGolden(
        tester,
        boundaryKey: boundaryKey,
        affordPreview: const WorkOrderAffordPreview(
          materialCosts: {'lumber': 2},
          canAfford: false,
          materialShortfalls: [(commodityId: 'lumber', quantity: 1)],
        ),
      );

      expect(find.textContaining('Short:'), findsOneWidget);
      await expectLater(
        find.byKey(boundaryKey),
        matchesGoldenFile('goldens/selection_prompt_afford_material_short.png'),
      );
    },
  );

  testWidgets(
    'golden: selection prompt treasury shortfall (Refs #4262)',
    (WidgetTester tester) async {
      const boundaryKey = ValueKey<String>('selectionPromptAffordTreasuryShort');
      await _pumpSelectionPromptAffordGolden(
        tester,
        boundaryKey: boundaryKey,
        affordPreview: const WorkOrderAffordPreview(
          treasuryAmount: 500,
          canAfford: false,
          treasuryShortfall: 200,
        ),
      );

      expect(find.textContaining('Short:'), findsOneWidget);
      await expectLater(
        find.byKey(boundaryKey),
        matchesGoldenFile('goldens/selection_prompt_afford_treasury_short.png'),
      );
    },
  );
}
