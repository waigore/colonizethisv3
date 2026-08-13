// Widget pump/find helpers for ProductionLabourSection tests (Refs #4352).

import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_app_ui_chrome/config/editorial_monocle_palette.dart';
import 'package:colonizethis_app/widgets/ct_danger_text_button.dart';
import 'package:colonizethis_app/widgets/ct_nine_patch_button.dart';
import 'package:colonizethis_app/features/game/widgets/production/production_labour_helpers.dart';
import 'package:colonizethis_app/features/game/widgets/production/production_labour_section.dart';
import 'package:colonizethis_app_l10n/l10n/l10n.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'app_shell_harness.dart';
import 'production_labour_test_fixtures.dart';
import 'widget_test_pumps.dart';

const productionLabourSectionPlayerId = 'gp_labour_widget_test';

final productionLabourSectionL10n = lookupAppLocalizations(const Locale('en'));

Player productionLabourSectionGpWithPool({
  int peasants = 0,
  int apprentices = 0,
  int journeymen = 0,
  int masters = 0,
  int treasury = 0,
  Map<String, int> stockpile = const {},
  Map<String, bool>? techUnlocked,
}) =>
    productionLabourGpWithPool(
      id: productionLabourSectionPlayerId,
      peasants: peasants,
      apprentices: apprentices,
      journeymen: journeymen,
      masters: masters,
      treasury: treasury,
      stockpile: stockpile,
      techUnlocked: techUnlocked,
    );

class ProductionLabourSectionCapture {
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

ValueKey<String> productionLabourRowKey(WorkerTier tier) =>
    ValueKey<String>('production_labour_row_${tier.id}');

ValueKey<String> productionLabourDisbandKey(WorkerTier tier) =>
    ValueKey<String>('production_labour_disband_${tier.id}');

String productionLabourTierName(WorkerTier tier) {
  final l10n = productionLabourSectionL10n;
  return switch (tier) {
    WorkerTier.peasant => l10n.production_workers_peasants,
    WorkerTier.apprentice => l10n.production_workers_apprentices,
    WorkerTier.journeyman => l10n.production_workers_journeymen,
    WorkerTier.master => l10n.production_workers_masters,
  };
}

String productionLabourPlusVerb(WorkerTier tier) {
  final name = productionLabourTierName(tier);
  return tier == WorkerTier.peasant
      ? productionLabourSectionL10n.production_labourRecruitTier(name)
      : productionLabourSectionL10n.production_labourTrainTier(name);
}

Finder productionLabourDisbandFinder(WorkerTier tier) =>
    find.byKey(productionLabourDisbandKey(tier));

double productionLabourDisbandOpacity(WidgetTester tester, WorkerTier tier) {
  return tester
      .widget<Opacity>(
        find.descendant(
          of: productionLabourDisbandFinder(tier),
          matching: find.byType(Opacity),
        ),
      )
      .opacity;
}

Widget mountProductionLabourSection({
  required Player player,
  Orders currentOrders = const Orders(),
  bool canEdit = true,
  ProductionLabourCallbacks? callbacks,
}) {
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
          callbacks: callbacks ?? ProductionLabourSectionCapture().asCallbacks(),
        ),
      ),
    ),
  );
}

Future<void> pumpProductionLabourSection(
  WidgetTester tester, {
  required Player player,
  Orders currentOrders = const Orders(),
  bool canEdit = true,
  ProductionLabourCallbacks? callbacks,
}) async {
  await tester.pumpWidget(
    mountProductionLabourSection(
      player: player,
      currentOrders: currentOrders,
      canEdit: canEdit,
      callbacks: callbacks,
    ),
  );
  await pumpSettleCapped(tester);
}

Future<ProductionLabourSectionCapture> pumpProductionLabourSectionWithCapture(
  WidgetTester tester, {
  required Player player,
  Orders currentOrders = const Orders(),
}) async {
  final capture = ProductionLabourSectionCapture();
  await pumpProductionLabourSection(
    tester,
    player: player,
    currentOrders: currentOrders,
    callbacks: capture.asCallbacks(),
  );
  return capture;
}
