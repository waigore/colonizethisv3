// Production Available → Trade Market deep-link. SPEC/ui/production-panel.md Refs #4581.

import 'package:colonizethis_app/features/game/widgets/production/production_available_trade_cell.dart';
import 'package:colonizethis_app/widgets/ct_resource_cell.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'production_panel_test_support.dart';
import 'production_panel_widget_helpers.dart';
import 'widget_test_pumps.dart';

void main() {
  suppressLogsForTests();

  late Player fullPlayer;

  setUpAll(() {
    fullPlayer = productionPanelTestFullPlayer();
  });

  testWidgets('tapping a tradeable Available cell reports that commodity', (
    WidgetTester tester,
  ) async {
    String? opened;
    await pumpProductionPanelSettled(
      tester,
      player: fullPlayer,
      onOpenTradeMarket: (id) => opened = id,
    );

    await tester.tap(
      find.byKey(const ValueKey('production_available_cell_timber')),
    );
    await pumpSyncFrames(tester);

    expect(opened, 'timber');
  });

  testWidgets('Workers cell does not open Trade', (WidgetTester tester) async {
    var opened = false;
    await pumpProductionPanelSettled(
      tester,
      player: fullPlayer,
      onOpenTradeMarket: (_) => opened = true,
      height: 1400,
    );

    await tester.tap(
      find.byKey(const ValueKey('production_available_worker_peasant')),
    );
    await pumpSyncFrames(tester);

    expect(opened, isFalse);
  });

  testWidgets('tradeable cell still opens Trade when labour is read-only', (
    WidgetTester tester,
  ) async {
    String? opened;
    await tester.pumpWidget(
      buildProductionPanel(
        player: fullPlayer,
        canEditLabour: false,
        onOpenTradeMarket: (id) => opened = id,
      ),
    );
    await pumpSettleCapped(tester);

    await tester.tap(
      find.byKey(const ValueKey('production_available_cell_grain')),
    );
    await pumpSyncFrames(tester);
    expect(opened, 'grain');
  });

  testWidgets('tradeable Available quantity still matches sellable headroom', (
    WidgetTester tester,
  ) async {
    final player = productionPanelTestFullPlayer();
    await pumpProductionPanelSettled(
      tester,
      player: player,
      onOpenTradeMarket: (_) {},
    );
    final timberCell = tester.widget<CtResourceCell>(
      find.byKey(const ValueKey('production_available_cell_timber')),
    );
    expect(timberCell.quantity, player.stockpile.quantityOf('timber'));
  });

  testWidgets('on-request copy uses AppLocalizations sellable tooltip', (
    WidgetTester tester,
  ) async {
    await pumpProductionPanelSettled(
      tester,
      player: fullPlayer,
      onOpenTradeMarket: (_) {},
    );
    expect(
      find.byWidgetPredicate(
        (w) =>
            w is Tooltip &&
            (w.message ?? '').contains('still sell after industry reservations'),
      ),
      findsWidgets,
    );
  });

  testWidgets('narrow viewport tradeable cell hit target is at least 44 dp', (
    WidgetTester tester,
  ) async {
    await pumpProductionPanelSettled(
      tester,
      player: fullPlayer,
      onOpenTradeMarket: (_) {},
      width: 360,
      height: 640,
    );
    final size = tester.getSize(
      find.byType(ProductionAvailableTradeCell).first,
    );
    expect(size.width, greaterThanOrEqualTo(44));
    expect(size.height, greaterThanOrEqualTo(44));
  });
}
