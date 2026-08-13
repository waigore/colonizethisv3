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
    testWidgets(
      'renders one row per tier (peasant + 3 trained) with disband only on trained tiers',
      (WidgetTester tester) async {
        final player = productionLabourSectionGpWithPool(
          peasants: 1,
          apprentices: 1,
          journeymen: 1,
          masters: 1,
        );
        await pumpProductionLabourSection(tester, player: player);

        for (final tier in kProductionLabourTierOrder) {
          expect(
            find.byKey(productionLabourRowKey(tier)),
            findsOneWidget,
            reason: 'expected row for ${tier.id}',
          );
        }

        for (final tier in productionLabourTrainedTiers) {
          expect(
            find.byKey(productionLabourDisbandKey(tier)),
            findsOneWidget,
            reason: 'expected visible Disband for ${tier.id}',
          );
        }
        expect(
          find.byKey(productionLabourDisbandKey(WorkerTier.peasant)),
          findsNothing,
          reason: 'peasant row must not mount a keyed Disband control (S8e)',
        );
      },
    );

    testWidgets('stepper / disband callbacks and queue chrome', (
      WidgetTester tester,
    ) async {
      var capture = await pumpProductionLabourSectionWithCapture(
        tester,
        player: productionLabourSectionGpWithPool(
          stockpile: {CommodityCatalog.fabric.id: 2},
        ),
      );
      await tester.tap(
        find.bySemanticsLabel(productionLabourPlusVerb(WorkerTier.peasant)),
      );
      await pumpSyncFrames(tester);
      expect(capture.appended, [WorkerTier.peasant]);

      capture = await pumpProductionLabourSectionWithCapture(
        tester,
        player: productionLabourSectionGpWithPool(
          peasants: 1,
          treasury: 500,
          stockpile: {CommodityCatalog.paper.id: 5},
          techUnlocked: const {
            kTechIdTrainedJourneymen: true,
            kTechIdCigarProduction: true,
          },
        ),
        currentOrders: Orders(
          recruitWorkerOrdersByPlayerId: {
            productionLabourSectionPlayerId: const [
              RecruitWorkerOrder(targetTier: WorkerTier.journeyman),
            ],
          },
        ),
      );
      await tester.tap(
        find.bySemanticsLabel(
          l10n.production_labourDequeueTier(
            productionLabourTierName(WorkerTier.journeyman),
          ),
        ),
      );
      await pumpSyncFrames(tester);
      expect(capture.popped, [WorkerTier.journeyman]);

      await pumpProductionLabourSection(
        tester,
        player: productionLabourSectionGpWithPool(peasants: 1),
        currentOrders: Orders(
          recruitWorkerOrdersByPlayerId: {
            productionLabourSectionPlayerId: const [
              RecruitWorkerOrder(targetTier: WorkerTier.peasant),
              RecruitWorkerOrder(targetTier: WorkerTier.peasant),
            ],
          },
        ),
      );
      expect(find.text('Queued: 2'), findsOneWidget);
      expect(find.text('Queued: 0'), findsNothing);

      capture = await pumpProductionLabourSectionWithCapture(
        tester,
        player: productionLabourSectionGpWithPool(
          peasants: 5,
          treasury: 5000,
          stockpile: {CommodityCatalog.paper.id: 50},
        ),
      );
      await tester.tap(
        find.bySemanticsLabel(productionLabourPlusVerb(WorkerTier.apprentice)),
        warnIfMissed: false,
      );
      await pumpSyncFrames(tester);
      expect(capture.appended, isEmpty);

      capture = await pumpProductionLabourSectionWithCapture(
        tester,
        player: productionLabourSectionGpWithPool(journeymen: 1),
      );
      await tester.tap(productionLabourDisbandFinder(WorkerTier.journeyman));
      await pumpSyncFrames(tester);
      expect(capture.disbanded, [WorkerTier.journeyman]);

      capture = await pumpProductionLabourSectionWithCapture(
        tester,
        player: productionLabourSectionGpWithPool(peasants: 1),
      );
      await tester.tap(
        productionLabourDisbandFinder(WorkerTier.master),
        warnIfMissed: false,
      );
      await pumpSyncFrames(tester);
      expect(capture.disbanded, isEmpty);

      await pumpProductionLabourSection(
        tester,
        player: productionLabourSectionGpWithPool(peasants: 2, journeymen: 1),
        canEdit: false,
      );
      expect(find.text('Disband'), findsNothing);
      expect(
        find.bySemanticsLabel(productionLabourPlusVerb(WorkerTier.peasant)),
        findsNothing,
      );
    });

    testWidgets('tier labels suffix unlocked/locked from techUnlocked map', (
      WidgetTester tester,
    ) async {
      await pumpProductionLabourSection(
        tester,
        player: productionLabourSectionGpWithPool(peasants: 1),
      );
      expect(
        find.text(
          l10n.production_labourTierLabel(
            productionLabourTierName(WorkerTier.peasant),
            l10n.production_labourTierUnlocked,
          ),
        ),
        findsOneWidget,
      );
      for (final tier in productionLabourTrainedTiers) {
        expect(
          find.text(
            l10n.production_labourTierLabel(
              productionLabourTierName(tier),
              l10n.production_labourTierLocked,
            ),
          ),
          findsOneWidget,
          reason: '${productionLabourTierName(tier)} must render (locked) suffix',
        );
      }
      await pumpProductionLabourSection(
        tester,
        player: productionLabourSectionGpWithPool(
          peasants: 1,
          techUnlocked: const {
            kTechIdApprenticeWorkers: true,
            kTechIdSugarRefining: true,
          },
        ),
      );
      expect(
        find.text(
          l10n.production_labourTierLabel(
            productionLabourTierName(WorkerTier.apprentice),
            l10n.production_labourTierUnlocked,
          ),
        ),
        findsOneWidget,
      );
    });

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

      final disbandFinder = productionLabourDisbandFinder(WorkerTier.journeyman);
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

        Offset centreFor(WorkerTier tier, String semantic) {
          return tester.getCenter(
            find.descendant(
              of: find.byKey(productionLabourRowKey(tier)),
              matching: find.bySemanticsLabel(semantic),
            ),
          );
        }

        Offset minus(WorkerTier tier) => centreFor(
          tier,
          l10n.production_labourDequeueTier(productionLabourTierName(tier)),
        );
        Offset plus(WorkerTier tier) =>
            centreFor(tier, productionLabourPlusVerb(tier));

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
