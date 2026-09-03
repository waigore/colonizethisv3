// Shared 320 dp ProductionCommodityBreakdownDialog pump (Refs #4720 Slice G).
// Family SoT viewport sizes via dialogs harness constants.
// SPEC: SPEC/ui/mobile-adaptation.md § 7.

import 'package:colonizethis_app/features/game/widgets/production/production_commodity_breakdown_dialog.dart';
import 'package:colonizethis_app_l10n/l10n/l10n.dart';
import 'package:colonizethis_app_ui_chrome/config/editorial_monocle_palette.dart';
import 'package:colonizethis_data/colonizethis_data.dart' show MapTopology;
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'dialogs_320dp_min_viewport_support.dart';
import 'min_viewport_harness.dart';
import 'panel_test_fixtures.dart';

/// Minimum supported viewport — same Size(320, 640) as family SoT.
const Size kProductionBreakdown320MinViewport = kDialogs320MinViewport;

/// Wide regression sentinel.
const Size kProductionBreakdown320WideViewport =
    kDialogs320WideRegressionViewport;

/// Pumps [ProductionCommodityBreakdownDialog] via showDialog at [size].
Future<void> pumpProductionCommodityBreakdown320(
  WidgetTester tester, {
  required Size size,
}) async {
  final game = buildProductionBreakdownPanelTestGame();
  final player = game.players.firstWhere((p) => p.isHuman);

  await pumpAtMinViewport(
    tester,
    size: size,
    localizationsDelegates: AppLocalizationsBinding.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    locale: const Locale('en'),
    child: Scaffold(
      body: Builder(
        builder: (context) => TextButton(
          onPressed: () {
            showDialog<void>(
              context: context,
              barrierColor: EditorialMonoclePalette.dialogScrim,
              builder: (_) => ProductionCommodityBreakdownDialog(
                game: game,
                player: player,
                topology: const MapTopology(nodes: [], edges: []),
                tileMapByRegion: null,
                currentOrders: const Orders(),
              ),
            );
          },
          // ignore: avoid_hardcoded_strings_in_widgets
          child: const Text('open'),
        ),
      ),
    ),
  );
  await tester.tap(find.text('open'));
  await tester.pumpAndSettle();
}
