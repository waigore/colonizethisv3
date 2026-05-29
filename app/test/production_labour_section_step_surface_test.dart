// Widget tests pinning the labour-control step-button surface contract.
//
// SPEC: SPEC/ui/production-panel.md § Labour Controls (per-tier ± controls
// reuse `ProductionStepButtonSurface` — 26×26 px, `CtGradients.buttonGradient`,
// 1 px `EditorialMonoclePalette.border`, 0.3 disabled opacity), Refs #2862.

import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:colonizethis_app/config/editorial_monocle_palette.dart';
import 'package:colonizethis_app/features/game/widgets/production_allocation_row_buttons.dart';
import 'package:colonizethis_app/features/game/widgets/production_labour_helpers.dart';
import 'package:colonizethis_app/features/game/widgets/production_labour_section.dart';
import 'package:colonizethis_app/l10n/l10n.dart';
import 'package:colonizethis_app/widgets/ct_gradients.dart';

import 'widget_test_pumps.dart';

const _playerId = 'gp_labour_surface_test';

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
    displayName: 'Labour surface GP',
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

Widget _mount({
  required Player player,
  Orders currentOrders = const Orders(),
  bool canEdit = true,
}) {
  return MaterialApp(
    localizationsDelegates: AppLocalizationsBinding.localizationsDelegates,
    supportedLocales: const [Locale('en')],
    home: Scaffold(
      body: SizedBox(
        width: 800,
        height: 600,
        child: ProductionLabourSection(
          player: player,
          currentOrders: currentOrders,
          canEdit: canEdit,
          callbacks: ProductionLabourCallbacks(
            onAppendRecruitOrder: (_) {},
            onPopLastRecruitOrder: (_) {},
            onDisband: (_) {},
          ),
        ),
      ),
    ),
  );
}

Finder _surfacesOf(Finder labourSection) =>
    find.descendant(of: labourSection, matching: find.byType(ProductionStepButtonSurface));

void main() {
  suppressLogsForTests();

  group(
    'ProductionLabourSection step-button surface contract '
    '(SPEC/ui/production-panel.md § Labour Controls; Refs #2862)',
    () {
      testWidgets(
        'each per-tier + / − control wraps its icon in a 26x26 '
        'ProductionStepButtonSurface (no ad-hoc Opacity padding fallback)',
        (WidgetTester tester) async {
          final player = _gpWithPool(
            peasants: 1,
            apprentices: 1,
            journeymen: 1,
            masters: 1,
            stockpile: {CommodityCatalog.fabric.id: 2},
          );
          await tester.pumpWidget(_mount(player: player));
          await pumpSettleCapped(tester);

          final labourSection = find.byType(ProductionLabourSection);
          final surfaces = _surfacesOf(labourSection);
          // 4 tiers × (+ and −) = 8 surfaces; disband uses CtNinePatchButton,
          // not the step-button surface.
          expect(
            surfaces,
            findsNWidgets(8),
            reason:
                'Each tier row contributes one ± surface pair; SPEC mandates '
                'reuse of the Allocation step-button surface contract.',
          );

          for (int i = 0; i < 8; i++) {
            final Size size = tester.getSize(surfaces.at(i));
            expect(size.width, kProductionAllocationStepButtonSize);
            expect(size.height, kProductionAllocationStepButtonSize);
          }
        },
      );

      testWidgets(
        'enabled ± control paints buttonGradient inside 1 px '
        '--border outline at full opacity',
        (WidgetTester tester) async {
          // Peasant + with fabric ≥ 2 → recruit cost row affordable → enabled.
          final player = _gpWithPool(
            stockpile: {CommodityCatalog.fabric.id: 2},
          );
          await tester.pumpWidget(_mount(player: player));
          await pumpSettleCapped(tester);

          final l10n = lookupAppLocalizations(const Locale('en'));
          final plusSemantics = find.bySemanticsLabel(
            l10n.production_labourRecruitTier(
              l10n.production_workers_peasants,
            ),
          );
          expect(plusSemantics, findsOneWidget);

          final surfaceFinder = find.descendant(
            of: plusSemantics,
            matching: find.byType(ProductionStepButtonSurface),
          );
          expect(surfaceFinder, findsOneWidget);

          final decoratedBoxFinder = find.descendant(
            of: surfaceFinder,
            matching: find.byType(DecoratedBox),
          );
          final DecoratedBox decoratedBox = tester.widget<DecoratedBox>(
            decoratedBoxFinder.first,
          );
          final BoxDecoration decoration =
              decoratedBox.decoration as BoxDecoration;
          expect(decoration.gradient, equals(CtGradients.buttonGradient));
          final Border border = decoration.border as Border;
          expect(border.top.color, equals(EditorialMonoclePalette.border));
          expect(border.top.width, 1.0);

          final opacityFinder = find.descendant(
            of: surfaceFinder,
            matching: find.byType(Opacity),
          );
          final Opacity opacityWidget = tester.widget<Opacity>(
            opacityFinder.first,
          );
          expect(opacityWidget.opacity, equals(1.0));
        },
      );

      testWidgets(
        'disabled ± control fades the entire surface to '
        'kProductionAllocationStepButtonDisabledOpacity (0.3)',
        (WidgetTester tester) async {
          // No fabric, no peasants, no tech → every + is disabled, every −
          // is disabled (queue is empty).
          final player = _gpWithPool();
          await tester.pumpWidget(_mount(player: player));
          await pumpSettleCapped(tester);

          final l10n = lookupAppLocalizations(const Locale('en'));
          final plusSemantics = find.bySemanticsLabel(
            l10n.production_labourRecruitTier(
              l10n.production_workers_peasants,
            ),
          );
          expect(plusSemantics, findsOneWidget);

          final surfaceFinder = find.descendant(
            of: plusSemantics,
            matching: find.byType(ProductionStepButtonSurface),
          );
          expect(surfaceFinder, findsOneWidget);

          final opacityFinder = find.descendant(
            of: surfaceFinder,
            matching: find.byType(Opacity),
          );
          final Opacity opacityWidget = tester.widget<Opacity>(
            opacityFinder.first,
          );
          expect(
            opacityWidget.opacity,
            equals(kProductionAllocationStepButtonDisabledOpacity),
          );
          expect(
            opacityWidget.opacity,
            equals(0.3),
            reason:
                'SPEC mandates the disabled opacity constant equals 0.3 — '
                'regressions to the legacy 0.35 icon-only opacity are '
                'forbidden (Refs #2862, SPEC § Allocation step buttons).',
          );
        },
      );

      testWidgets(
        'Disband retains CtNinePatchButton chrome (NOT '
        'ProductionStepButtonSurface) — negative regression guard',
        (WidgetTester tester) async {
          final player = _gpWithPool(journeymen: 1);
          await tester.pumpWidget(_mount(player: player));
          await pumpSettleCapped(tester);

          // Disband control is keyed; verify no step-button surface lives
          // inside its subtree (it must remain a nine-patch button per
          // SPEC § Labour Controls).
          final disbandFinder = find.byKey(
            const ValueKey<String>(
              'production_labour_disband_journeymen',
            ),
          );
          expect(disbandFinder, findsOneWidget);
          expect(
            find.descendant(
              of: disbandFinder,
              matching: find.byType(ProductionStepButtonSurface),
            ),
            findsNothing,
            reason:
                'Disband must remain a CtNinePatchButton per SPEC; reusing '
                'ProductionStepButtonSurface here would conflict with R11.',
          );
        },
      );
    },
  );
}
