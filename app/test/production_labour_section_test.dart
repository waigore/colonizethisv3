// Widget tests for ProductionLabourSection. SPEC/ui/production-panel.md
// § Labour Controls, SPEC/game/workers-and-population.md.

import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:colonizethis_app/features/game/widgets/production_labour_helpers.dart';
import 'package:colonizethis_app/features/game/widgets/production_labour_section.dart';
import 'package:colonizethis_app/l10n/l10n.dart';

import 'widget_test_pumps.dart';

const _playerId = 'gp_labour_widget_test';

Player _gpWithPool({
  int peasants = 0,
  int apprentices = 0,
  int journeymen = 0,
  int masters = 0,
  int treasury = 0,
  Map<String, int> stockpile = const {},
  Map<String, bool>? techUnlocked,
}) {
  return Player(
    id: _playerId,
    displayName: 'Labour widget GP',
    isHuman: true,
    workerPool: WorkerPool(
      peasants: peasants,
      apprentices: apprentices,
      journeymen: journeymen,
      masters: masters,
    ),
    stockpile: Stockpile(quantities: Map<String, int>.from(stockpile)),
    treasury: treasury,
    techUnlocked: techUnlocked,
  );
}

class _Capture {
  final List<WorkerTier> appended = [];
  final List<WorkerTier> popped = [];
  final List<WorkerTier> disbanded = [];

  ProductionLabourCallbacks asCallbacks() {
    return ProductionLabourCallbacks(
      onAppendRecruitOrder: appended.add,
      onPopLastRecruitOrder: popped.add,
      onDisband: disbanded.add,
    );
  }
}

Widget _mount({
  required Player player,
  Orders currentOrders = const Orders(),
  bool canEdit = true,
  ProductionLabourCallbacks? callbacks,
}) {
  return MaterialApp(
    localizationsDelegates:
        AppLocalizationsBinding.localizationsDelegates,
    supportedLocales: const [Locale('en')],
    home: Scaffold(
      body: SizedBox(
        width: 800,
        height: 600,
        child: ProductionLabourSection(
          player: player,
          currentOrders: currentOrders,
          canEdit: canEdit,
          callbacks: callbacks ?? _Capture().asCallbacks(),
        ),
      ),
    ),
  );
}

void main() {
  suppressLogsForTests();

  group('ProductionLabourSection', () {
    testWidgets('renders one row per tier (peasant + 3 trained) with disband only on trained tiers', (
      WidgetTester tester,
    ) async {
      final player = _gpWithPool(peasants: 1, apprentices: 1, journeymen: 1, masters: 1);
      await tester.pumpWidget(_mount(player: player));
      await pumpSettleCapped(tester);

      // All four tier rows present.
      for (final tier in kProductionLabourTierOrder) {
        expect(
          find.byKey(ValueKey<String>('production_labour_row_${tier.id}')),
          findsOneWidget,
          reason: 'expected row for ${tier.id}',
        );
      }

      // Disband button on each trained tier (3) but not on peasant.
      expect(find.text('Disband'), findsNWidgets(3));
    });

    testWidgets('tapping + on peasant invokes onAppendRecruitOrder with peasant', (
      WidgetTester tester,
    ) async {
      final capture = _Capture();
      final player = _gpWithPool(
        stockpile: {CommodityCatalog.fabric.id: 2},
      );
      await tester.pumpWidget(
        _mount(player: player, callbacks: capture.asCallbacks()),
      );
      await pumpSettleCapped(tester);

      final l10n = lookupAppLocalizations(const Locale('en'));
      await tester.tap(
        find.bySemanticsLabel(
          l10n.production_labourRecruitTier(l10n.production_workers_peasants),
        ),
      );
      await pumpSyncFrames(tester);

      expect(capture.appended, [WorkerTier.peasant]);
    });

    testWidgets('tapping − dequeues last matching tier order', (
      WidgetTester tester,
    ) async {
      final capture = _Capture();
      final player = _gpWithPool(
        peasants: 1,
        treasury: 500,
        stockpile: {CommodityCatalog.paper.id: 5},
        techUnlocked: const {
          kTechIdTrainedJourneymen: true,
          kTechIdCigarProduction: true,
        },
      );
      final orders = Orders(
        recruitWorkerOrdersByPlayerId: {
          _playerId: const [RecruitWorkerOrder(targetTier: WorkerTier.journeyman)],
        },
      );
      await tester.pumpWidget(
        _mount(
          player: player,
          currentOrders: orders,
          callbacks: capture.asCallbacks(),
        ),
      );
      await pumpSettleCapped(tester);

      final l10n = lookupAppLocalizations(const Locale('en'));
      await tester.tap(
        find.bySemanticsLabel(
          l10n.production_labourDequeueTier(l10n.production_workers_journeymen),
        ),
      );
      await pumpSyncFrames(tester);

      expect(capture.popped, [WorkerTier.journeyman]);
    });

    testWidgets('Queued: N badge appears only when count > 0', (
      WidgetTester tester,
    ) async {
      final player = _gpWithPool(peasants: 1);
      final orders = Orders(
        recruitWorkerOrdersByPlayerId: {
          _playerId: const [
            RecruitWorkerOrder(targetTier: WorkerTier.peasant),
            RecruitWorkerOrder(targetTier: WorkerTier.peasant),
          ],
        },
      );
      await tester.pumpWidget(
        _mount(player: player, currentOrders: orders),
      );
      await pumpSettleCapped(tester);

      expect(find.text('Queued: 2'), findsOneWidget);
      // Other tiers have no queued orders so no badge appears for them.
      expect(find.text('Queued: 0'), findsNothing);
    });

    testWidgets('+ stepper for tech-locked apprentice tier is disabled (no callback on tap)', (
      WidgetTester tester,
    ) async {
      final capture = _Capture();
      final player = _gpWithPool(
        peasants: 5,
        treasury: 5000,
        stockpile: {CommodityCatalog.paper.id: 50},
      );
      await tester.pumpWidget(
        _mount(player: player, callbacks: capture.asCallbacks()),
      );
      await pumpSettleCapped(tester);

      final l10n = lookupAppLocalizations(const Locale('en'));
      await tester.tap(
        find.bySemanticsLabel(
          l10n.production_labourTrainTier(l10n.production_workers_apprentices),
        ),
        warnIfMissed: false,
      );
      await pumpSyncFrames(tester);

      expect(capture.appended, isEmpty);
    });

    testWidgets('disband control fires onDisband with the trained tier', (
      WidgetTester tester,
    ) async {
      final capture = _Capture();
      // Three Disband buttons (one per trained tier); only journeyman enabled.
      final player = _gpWithPool(journeymen: 1);
      await tester.pumpWidget(
        _mount(player: player, callbacks: capture.asCallbacks()),
      );
      await pumpSettleCapped(tester);

      await tester.tap(
        find.byKey(const ValueKey<String>('production_labour_disband_journeymen')),
      );
      await pumpSyncFrames(tester);

      expect(capture.disbanded, [WorkerTier.journeyman]);
    });

    testWidgets('disband is disabled when no worker of that tier (no callback)', (
      WidgetTester tester,
    ) async {
      final capture = _Capture();
      // No trained workers at all — all three disband buttons rendered, disabled.
      final player = _gpWithPool(peasants: 1);
      await tester.pumpWidget(
        _mount(player: player, callbacks: capture.asCallbacks()),
      );
      await pumpSettleCapped(tester);

      await tester.tap(
        find.byKey(const ValueKey<String>('production_labour_disband_masters')),
        warnIfMissed: false,
      );
      await pumpSyncFrames(tester);

      expect(capture.disbanded, isEmpty);
    });

    testWidgets('canEdit=false hides all action buttons', (
      WidgetTester tester,
    ) async {
      final player = _gpWithPool(peasants: 2, journeymen: 1);
      await tester.pumpWidget(_mount(player: player, canEdit: false));
      await pumpSettleCapped(tester);

      // No disband buttons rendered when read-only.
      expect(find.text('Disband'), findsNothing);
      final l10n = lookupAppLocalizations(const Locale('en'));
      // Append/dequeue semantic labels do not appear because read-only mode
      // skips emitting any action button.
      expect(
        find.bySemanticsLabel(
          l10n.production_labourRecruitTier(l10n.production_workers_peasants),
        ),
        findsNothing,
      );
    });
  });
}
