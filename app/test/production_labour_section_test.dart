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
import 'package:colonizethis_app/features/game/widgets/production/production_labour_section.dart';
import 'package:colonizethis_app_l10n/l10n/l10n.dart';

import 'app_shell_harness.dart';
import 'production_labour_test_fixtures.dart';
import 'widget_test_pumps.dart';

const _playerId = 'gp_labour_widget_test';

final _l10n = lookupAppLocalizations(const Locale('en'));

Player _gpWithPool({
  int peasants = 0,
  int apprentices = 0,
  int journeymen = 0,
  int masters = 0,
  int treasury = 0,
  Map<String, int> stockpile = const {},
  Map<String, bool>? techUnlocked,
}) {
  return productionLabourGpWithPool(
    id: _playerId,
    peasants: peasants,
    apprentices: apprentices,
    journeymen: journeymen,
    masters: masters,
    treasury: treasury,
    stockpile: stockpile,
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

ValueKey<String> _rowKey(WorkerTier tier) =>
    ValueKey<String>('production_labour_row_${tier.id}');

ValueKey<String> _disbandKey(WorkerTier tier) =>
    ValueKey<String>('production_labour_disband_${tier.id}');

String _tierName(WorkerTier tier) {
  return switch (tier) {
    WorkerTier.peasant => _l10n.production_workers_peasants,
    WorkerTier.apprentice => _l10n.production_workers_apprentices,
    WorkerTier.journeyman => _l10n.production_workers_journeymen,
    WorkerTier.master => _l10n.production_workers_masters,
  };
}

String _plusVerb(WorkerTier tier) {
  final name = _tierName(tier);
  return tier == WorkerTier.peasant
      ? _l10n.production_labourRecruitTier(name)
      : _l10n.production_labourTrainTier(name);
}

Finder _disbandFinder(WorkerTier tier) => find.byKey(_disbandKey(tier));

double _disbandOpacity(WidgetTester tester, WorkerTier tier) {
  return tester
      .widget<Opacity>(
        find.descendant(
          of: _disbandFinder(tier),
          matching: find.byType(Opacity),
        ),
      )
      .opacity;
}

Widget _mount({
  required Player player,
  Orders currentOrders = const Orders(),
  bool canEdit = true,
  ProductionLabourCallbacks? callbacks,
}) {
  // Editorial shell via buildAppShell (Refs #4035 — no inline MaterialApp).
  return buildAppShell(
    localizationsDelegates: AppLocalizationsBinding.localizationsDelegates,
    supportedLocales: const [Locale('en')],
    child: Scaffold(
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

Future<void> _pumpSection(
  WidgetTester tester, {
  required Player player,
  Orders currentOrders = const Orders(),
  bool canEdit = true,
  ProductionLabourCallbacks? callbacks,
}) async {
  await tester.pumpWidget(
    _mount(
      player: player,
      currentOrders: currentOrders,
      canEdit: canEdit,
      callbacks: callbacks,
    ),
  );
  await pumpSettleCapped(tester);
}

Future<_Capture> _pumpWithCapture(
  WidgetTester tester, {
  required Player player,
  Orders currentOrders = const Orders(),
}) async {
  final capture = _Capture();
  await _pumpSection(
    tester,
    player: player,
    currentOrders: currentOrders,
    callbacks: capture.asCallbacks(),
  );
  return capture;
}

void main() {
  suppressLogsForTests();

  group('ProductionLabourSection', () {
    testWidgets(
      'renders one row per tier (peasant + 3 trained) with disband only on trained tiers',
      (WidgetTester tester) async {
        final player = _gpWithPool(
          peasants: 1,
          apprentices: 1,
          journeymen: 1,
          masters: 1,
        );
        await _pumpSection(tester, player: player);

        for (final tier in kProductionLabourTierOrder) {
          expect(
            find.byKey(_rowKey(tier)),
            findsOneWidget,
            reason: 'expected row for ${tier.id}',
          );
        }

        for (final tier in productionLabourTrainedTiers) {
          expect(
            find.byKey(_disbandKey(tier)),
            findsOneWidget,
            reason: 'expected visible Disband for ${tier.id}',
          );
        }
        expect(
          find.byKey(_disbandKey(WorkerTier.peasant)),
          findsNothing,
          reason: 'peasant row must not mount a keyed Disband control (S8e)',
        );
      },
    );

    testWidgets('stepper / disband callbacks and queue chrome', (
      WidgetTester tester,
    ) async {
      // + on peasant appends recruit order.
      var capture = await _pumpWithCapture(
        tester,
        player: _gpWithPool(stockpile: {CommodityCatalog.fabric.id: 2}),
      );
      await tester.tap(find.bySemanticsLabel(_plusVerb(WorkerTier.peasant)));
      await pumpSyncFrames(tester);
      expect(capture.appended, [WorkerTier.peasant]);

      // − dequeues last matching tier order.
      capture = await _pumpWithCapture(
        tester,
        player: _gpWithPool(
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
            _playerId: const [
              RecruitWorkerOrder(targetTier: WorkerTier.journeyman),
            ],
          },
        ),
      );
      await tester.tap(
        find.bySemanticsLabel(
          _l10n.production_labourDequeueTier(_tierName(WorkerTier.journeyman)),
        ),
      );
      await pumpSyncFrames(tester);
      expect(capture.popped, [WorkerTier.journeyman]);

      // Queued badge only when count > 0.
      await _pumpSection(
        tester,
        player: _gpWithPool(peasants: 1),
        currentOrders: Orders(
          recruitWorkerOrdersByPlayerId: {
            _playerId: const [
              RecruitWorkerOrder(targetTier: WorkerTier.peasant),
              RecruitWorkerOrder(targetTier: WorkerTier.peasant),
            ],
          },
        ),
      );
      expect(find.text('Queued: 2'), findsOneWidget);
      expect(find.text('Queued: 0'), findsNothing);

      // Tech-locked apprentice + is a no-op.
      capture = await _pumpWithCapture(
        tester,
        player: _gpWithPool(
          peasants: 5,
          treasury: 5000,
          stockpile: {CommodityCatalog.paper.id: 50},
        ),
      );
      await tester.tap(
        find.bySemanticsLabel(_plusVerb(WorkerTier.apprentice)),
        warnIfMissed: false,
      );
      await pumpSyncFrames(tester);
      expect(capture.appended, isEmpty);

      // Disband fires when pool has workers; no-op when empty.
      capture = await _pumpWithCapture(
        tester,
        player: _gpWithPool(journeymen: 1),
      );
      await tester.tap(_disbandFinder(WorkerTier.journeyman));
      await pumpSyncFrames(tester);
      expect(capture.disbanded, [WorkerTier.journeyman]);

      capture = await _pumpWithCapture(
        tester,
        player: _gpWithPool(peasants: 1),
      );
      await tester.tap(_disbandFinder(WorkerTier.master), warnIfMissed: false);
      await pumpSyncFrames(tester);
      expect(capture.disbanded, isEmpty);

      // canEdit=false hides action chrome.
      await _pumpSection(
        tester,
        player: _gpWithPool(peasants: 2, journeymen: 1),
        canEdit: false,
      );
      expect(find.text('Disband'), findsNothing);
      expect(
        find.bySemanticsLabel(_plusVerb(WorkerTier.peasant)),
        findsNothing,
      );
    });

    // S7b — Tech-gate parenthetical (Refs #2862 S7).

    testWidgets('tier labels suffix unlocked/locked from techUnlocked map', (
      WidgetTester tester,
    ) async {
      await _pumpSection(tester, player: _gpWithPool(peasants: 1));
      expect(
        find.text(
          _l10n.production_labourTierLabel(
            _tierName(WorkerTier.peasant),
            _l10n.production_labourTierUnlocked,
          ),
        ),
        findsOneWidget,
      );
      for (final tier in productionLabourTrainedTiers) {
        expect(
          find.text(
            _l10n.production_labourTierLabel(
              _tierName(tier),
              _l10n.production_labourTierLocked,
            ),
          ),
          findsOneWidget,
          reason: '${_tierName(tier)} must render (locked) suffix',
        );
      }
      await _pumpSection(
        tester,
        player: _gpWithPool(
          peasants: 1,
          techUnlocked: const {
            kTechIdApprenticeWorkers: true,
            kTechIdSugarRefining: true,
          },
        ),
      );
      expect(
        find.text(
          _l10n.production_labourTierLabel(
            _tierName(WorkerTier.apprentice),
            _l10n.production_labourTierUnlocked,
          ),
        ),
        findsOneWidget,
      );
    });

    // S7c — Disband uses CtDangerTextButton (no CtNinePatchButton chrome).

    testWidgets('disband chrome uses CtDangerTextButton opacities', (
      WidgetTester tester,
    ) async {
      await _pumpSection(tester, player: _gpWithPool(journeymen: 1));
      expect(find.byType(CtDangerTextButton), findsNWidgets(4));
      expect(
        find.byType(CtNinePatchButton),
        findsNothing,
        reason: 'Labour rows must not mount CtNinePatchButton (S7c)',
      );
      expect(
        _disbandOpacity(tester, WorkerTier.journeyman),
        CtDangerTextButton.idleOpacity,
      );
      await _pumpSection(tester, player: _gpWithPool(peasants: 1));
      expect(
        _disbandOpacity(tester, WorkerTier.journeyman),
        CtNinePatchButton.disabledOpacity,
      );
    });

    testWidgets(
      'disband CtDangerTextButton paints danger border (no hard-coded colours)',
      (WidgetTester tester) async {
        await _pumpSection(tester, player: _gpWithPool(apprentices: 1));

        final container = tester.widget<AnimatedContainer>(
          find.descendant(
            of: _disbandFinder(WorkerTier.apprentice),
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
      await _pumpSection(tester, player: _gpWithPool(journeymen: 1));

      final disbandFinder = _disbandFinder(WorkerTier.journeyman);
      final gesture = await tester.createGesture(kind: PointerDeviceKind.mouse);
      addTearDown(gesture.removePointer);
      await gesture.addPointer(location: Offset.zero);
      await tester.pump();

      await gesture.moveTo(tester.getCenter(disbandFinder));
      await tester.pumpAndSettle(CtDangerTextButton.animationDuration);

      expect(
        _disbandOpacity(tester, WorkerTier.journeyman),
        CtDangerTextButton.hoverOpacity,
      );
    });

    // S8a — Trailing alignment of −/+ across rows + Disband flush right.

    testWidgets(
      '−/+ steppers share screen-x across peasant and trained rows (S8a)',
      (WidgetTester tester) async {
        await _pumpSection(
          tester,
          player: _gpWithPool(
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
              of: find.byKey(_rowKey(tier)),
              matching: find.bySemanticsLabel(semantic),
            ),
          );
        }

        Offset minus(WorkerTier tier) => centreFor(
          tier,
          _l10n.production_labourDequeueTier(_tierName(tier)),
        );
        Offset plus(WorkerTier tier) => centreFor(tier, _plusVerb(tier));

        final peasantMinus = minus(WorkerTier.peasant);
        final peasantPlus = plus(WorkerTier.peasant);
        for (final tier in productionLabourTrainedTiers) {
          expect(
            minus(tier).dx,
            closeTo(peasantMinus.dx, 0.5),
            reason: '− on ${tier.id} must align with peasant per S8a / C4',
          );
          expect(
            plus(tier).dx,
            closeTo(peasantPlus.dx, 0.5),
            reason: '+ on ${tier.id} must align with peasant per S8a / C4',
          );
          expect(
            tester.getCenter(_disbandFinder(tier)).dx,
            greaterThan(plus(tier).dx),
            reason: 'Disband must sit to the right of + on ${tier.id} (S8a)',
          );
        }
      },
    );

    testWidgets('peasant row reserves invisible Disband slot (S8a)', (
      WidgetTester tester,
    ) async {
      await _pumpSection(tester, player: _gpWithPool(peasants: 1));

      expect(find.byType(CtDangerTextButton), findsNWidgets(4));
      expect(find.byKey(_disbandKey(WorkerTier.peasant)), findsNothing);
    });

    // S8e — Disband enabled iff `pool.<tier> >= 1` (opacity + callback).
    testWidgets('Disband enabled/disabled follows pool.<tier> (S8e)', (
      WidgetTester tester,
    ) async {
      for (final case_ in <({Player player, double opacity, bool fires})>[
        (
          player: _gpWithPool(apprentices: 1),
          opacity: CtDangerTextButton.idleOpacity,
          fires: true,
        ),
        (
          player: _gpWithPool(peasants: 1),
          opacity: CtNinePatchButton.disabledOpacity,
          fires: false,
        ),
      ]) {
        final capture = await _pumpWithCapture(tester, player: case_.player);
        expect(_disbandOpacity(tester, WorkerTier.apprentice), case_.opacity);
        await tester.tap(
          _disbandFinder(WorkerTier.apprentice),
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
