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
        find.byKey(
          const ValueKey<String>('production_labour_plus_apprentices'),
        ),
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

    testWidgets('tier labels omit unlock parentheticals and show gists', (
      WidgetTester tester,
    ) async {
      await pumpProductionLabourSection(
        tester,
        player: productionLabourSectionGpWithPool(peasants: 1),
      );
      expect(
        find.text(productionLabourTierName(WorkerTier.peasant)),
        findsOneWidget,
      );
      expect(find.textContaining('(unlocked)'), findsNothing);
      expect(find.textContaining('(locked)'), findsNothing);
      expect(
        find.byKey(const ValueKey<String>('production_labour_cost_peasants')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey<String>('production_labour_upkeep_peasants')),
        findsOneWidget,
      );
      for (final tier in productionLabourTrainedTiers) {
        expect(
          find.byKey(ValueKey<String>('production_labour_requires_${tier.id}')),
          findsOneWidget,
          reason: '${tier.id} must show Requires: when tech-locked',
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
        find.byKey(
          const ValueKey<String>('production_labour_requires_apprentices'),
        ),
        findsNothing,
      );
    });
  });
}
