// Widget tests for ProductionLabourSection. SPEC/ui/production-panel.md
// § Labour Controls, SPEC/game/workers-and-population.md.

import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter/gestures.dart' show PointerDeviceKind;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:colonizethis_app_ui_chrome/config/editorial_monocle_palette.dart';
import 'package:colonizethis_app/widgets/ct_danger_text_button.dart';
import 'package:colonizethis_app/widgets/ct_nine_patch_button.dart';
import 'package:colonizethis_app/features/game/widgets/production/production_labour_helpers.dart';
import 'production_labour_section_test_support.dart';
import 'production_labour_test_fixtures.dart';
import 'widget_test_pumps.dart';

void main() {
  suppressLogsForTests();
  final l10n = productionLabourSectionL10n;

  group('ProductionLabourSection', () {
    testWidgets('disband chrome uses CtDangerTextButton opacities', (
      WidgetTester tester,
    ) async {
      await pumpProductionLabourSection(
        tester,
        player: productionLabourSectionGpWithPool(journeymen: 1),
      );
      expect(find.byType(CtDangerTextButton), findsNWidgets(4));
      expect(find.byType(CtNinePatchButton), findsNothing);
      expect(
        productionLabourDisbandOpacity(tester, WorkerTier.journeyman),
        CtDangerTextButton.idleOpacity,
      );
      await pumpProductionLabourSection(
        tester,
        player: productionLabourSectionGpWithPool(peasants: 1),
      );
      expect(
        productionLabourDisbandOpacity(tester, WorkerTier.journeyman),
        CtNinePatchButton.disabledOpacity,
      );
    });

    testWidgets(
      'disband CtDangerTextButton paints danger border (no hard-coded colours)',
      (WidgetTester tester) async {
        await pumpProductionLabourSection(
          tester,
          player: productionLabourSectionGpWithPool(apprentices: 1),
        );

        final container = tester.widget<AnimatedContainer>(
          find.descendant(
            of: productionLabourDisbandFinder(WorkerTier.apprentice),
            matching: find.byType(AnimatedContainer),
          ),
        );
        final decoration = container.decoration as BoxDecoration;
        final border = decoration.border! as Border;
        expect(border.top.color, EditorialMonoclePalette.danger);
        expect(border.top.width, 1);
        expect(decoration.color, Colors.transparent);
      },
    );

    testWidgets('CtDangerTextButton hover lifts opacity to 1.0', (
      WidgetTester tester,
    ) async {
      await pumpProductionLabourSection(
        tester,
        player: productionLabourSectionGpWithPool(journeymen: 1),
      );

      final disbandFinder = productionLabourDisbandFinder(
        WorkerTier.journeyman,
      );
      final gesture = await tester.createGesture(kind: PointerDeviceKind.mouse);
      addTearDown(gesture.removePointer);
      await gesture.addPointer(location: Offset.zero);
      await tester.pump();

      await gesture.moveTo(tester.getCenter(disbandFinder));
      await tester.pumpAndSettle(CtDangerTextButton.animationDuration);

      expect(
        productionLabourDisbandOpacity(tester, WorkerTier.journeyman),
        CtDangerTextButton.hoverOpacity,
      );
    });

    testWidgets(
      '−/+ steppers share screen-x across peasant and trained rows (S8a)',
      (WidgetTester tester) async {
        await pumpProductionLabourSection(
          tester,
          player: productionLabourSectionGpWithPool(
            peasants: 1,
            apprentices: 1,
            journeymen: 1,
            masters: 1,
            techUnlocked: const {
              kTechIdApprenticeWorkers: true,
              kTechIdSugarRefining: true,
            },
          ),
        );

        Offset centreFor(WorkerTier tier, String keySuffix) {
          return tester.getCenter(
            find.byKey(
              ValueKey<String>('production_labour_${keySuffix}_${tier.id}'),
            ),
          );
        }

        Offset minus(WorkerTier tier) => centreFor(tier, 'minus');
        Offset plus(WorkerTier tier) => centreFor(tier, 'plus');

        final peasantMinus = minus(WorkerTier.peasant);
        final peasantPlus = plus(WorkerTier.peasant);
        for (final tier in productionLabourTrainedTiers) {
          expect(minus(tier).dx, closeTo(peasantMinus.dx, 0.5));
          expect(plus(tier).dx, closeTo(peasantPlus.dx, 0.5));
          expect(
            tester.getCenter(productionLabourDisbandFinder(tier)).dx,
            greaterThan(plus(tier).dx),
          );
        }
      },
    );

    testWidgets('peasant row reserves invisible Disband slot (S8a)', (
      WidgetTester tester,
    ) async {
      await pumpProductionLabourSection(
        tester,
        player: productionLabourSectionGpWithPool(peasants: 1),
      );

      expect(find.byType(CtDangerTextButton), findsNWidgets(4));
      expect(
        find.byKey(productionLabourDisbandKey(WorkerTier.peasant)),
        findsNothing,
      );
    });

    testWidgets('Disband enabled/disabled follows pool.<tier> (S8e)', (
      WidgetTester tester,
    ) async {
      for (final case_ in <({Player player, double opacity, bool fires})>[
        (
          player: productionLabourSectionGpWithPool(apprentices: 1),
          opacity: CtDangerTextButton.idleOpacity,
          fires: true,
        ),
        (
          player: productionLabourSectionGpWithPool(peasants: 1),
          opacity: CtNinePatchButton.disabledOpacity,
          fires: false,
        ),
      ]) {
        final capture = await pumpProductionLabourSectionWithCapture(
          tester,
          player: case_.player,
        );
        expect(
          productionLabourDisbandOpacity(tester, WorkerTier.apprentice),
          case_.opacity,
        );
        await tester.tap(
          productionLabourDisbandFinder(WorkerTier.apprentice),
          warnIfMissed: false,
        );
        await pumpSyncFrames(tester);
        expect(
          capture.disbanded,
          case_.fires ? [WorkerTier.apprentice] : isEmpty,
        );
      }
    });
  });
}
