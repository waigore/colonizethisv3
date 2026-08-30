// Home Fleet cargo-consequence line on TransferToHomeFleetDialog (Refs #4544).
// SPEC/ui/transfer-to-home-fleet-dialog.md.

import 'package:colonizethis_app/features/game/widgets/unit_orders/home_fleet_cargo_consequence.dart';
import 'package:colonizethis_app/features/game/widgets/unit_orders/transfer_to_home_fleet_dialog.dart';
import 'package:colonizethis_app/widgets/ct_nine_patch_button.dart';
import 'package:colonizethis_app/widgets/ct_transfer_list.dart';
import 'package:colonizethis_app_l10n/l10n/app_localizations_en.dart';
import 'package:colonizethis_app_ui_chrome/config/editorial_monocle_palette.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'naval_units_panel_test_support.dart';
import 'transfer_to_home_fleet_dialog_test_support.dart';
import 'widget_test_assets.dart';

void main() {
  suppressLogsForTests();
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(setUpNinePatchAssets);

  final l10n = AppLocalizationsEn();

  String line({
    required int remaining,
    required int used,
    bool reliable = true,
    bool notDefined = false,
  }) {
    return homeFleetTransferCargoLineText(
      l10n: l10n,
      remainingHolds: remaining,
      overseasUsed: used,
      isCargoUsedReliable: reliable,
      cargoNotDefined: notDefined,
    );
  }

  testWidgets('live transfer line uses right counts and not split copy', (
    WidgetTester tester,
  ) async {
    await pumpTransferToHomeDialog(
      tester,
      bus: AppEventBus.create(),
      overseasCargoUsed: 4,
    );

    final initial = find.text(line(remaining: 3, used: 4));
    expect(initial, findsOneWidget);
    expect(find.textContaining('after this split'), findsNothing);
    expect(
      tester.widget<Text>(initial).style?.color,
      EditorialMonoclePalette.danger,
    );

    await tester.tap(find.byKey(CtTransferListKeys.leftMoveAll('fluyte')));
    await tester.pump();
    final after = find.text(line(remaining: 7, used: 4));
    expect(after, findsOneWidget);
    expect(
      tester.widget<Text>(after).style?.color,
      EditorialMonoclePalette.muted,
    );
  });

  testWidgets('reliable used colours muted / accent / danger', (
    WidgetTester tester,
  ) async {
    await pumpTransferToHomeDialog(
      tester,
      bus: AppEventBus.create(),
      overseasCargoUsed: 3,
    );
    expect(
      tester.widget<Text>(find.text(line(remaining: 3, used: 3))).style?.color,
      EditorialMonoclePalette.accent,
    );
  });

  testWidgets('unreliable used is em dash and muted', (
    WidgetTester tester,
  ) async {
    await pumpTransferToHomeDialog(
      tester,
      bus: AppEventBus.create(),
      overseasCargoUsed: 9,
      isCargoUsedReliable: false,
    );
    final cargo = find.text(line(remaining: 3, used: 9, reliable: false));
    expect(cargo, findsOneWidget);
    expect(find.textContaining('—'), findsWidgets);
    expect(
      tester.widget<Text>(cargo).style?.color,
      EditorialMonoclePalette.muted,
    );
  });

  testWidgets('warships do not increase remaining holds', (
    WidgetTester tester,
  ) async {
    await pumpTransferToHomeDialog(
      tester,
      bus: AppEventBus.create(),
      overseasCargoUsed: 2,
      fixture: transferCargoFixture(
        sourceShips: const [ShipInstance(id: 'ship_sloop_a', typeId: 'sloop')],
      ),
    );
    expect(find.text(line(remaining: 3, used: 2)), findsOneWidget);
    await tester.tap(find.byKey(CtTransferListKeys.leftMoveAll('sloop')));
    await tester.pump();
    expect(find.text(line(remaining: 3, used: 2)), findsOneWidget);
  });

  testWidgets('Transfer stays enabled when remaining holds fall short', (
    WidgetTester tester,
  ) async {
    await pumpTransferToHomeDialog(
      tester,
      bus: AppEventBus.create(),
      overseasCargoUsed: 9,
    );
    await tester.tap(find.byKey(CtTransferListKeys.leftMoveAll('fluyte')));
    await tester.pump();
    expect(find.text(line(remaining: 7, used: 9)), findsOneWidget);
    final transfer = find.widgetWithText(CtNinePatchButton, 'Transfer');
    expect(tester.widget<CtNinePatchButton>(transfer).enabled, isTrue);
  });

  testWidgets('Combine into Home Fleet threads panel cargo flags', (
    WidgetTester tester,
  ) async {
    const humanId = 'gp_home_combine_cargo';
    await pumpNavalPanel(
      tester,
      game: buildNavalPanelCapitalHomeAndPeersGame(
        humanId: humanId,
        gameId: 'g_home_combine_cargo',
        displayName: 'Home combine cargo',
        homeShips: const [ShipInstance(id: 'ship_h', typeId: 'carrack')],
        nextShipInstanceSeq: 3,
        peerFleets: [
          navalPanelPortShipFleet(
            id: 'at_capital',
            humanId: humanId,
            port: kNavalPanelCapProvince,
            shipId: 'ship_v',
            typeId: 'fluyte',
          ),
        ],
      ),
      humanPlayerId: humanId,
      overseasCargoUsed: 5,
      isCargoUsedReliable: true,
      cargoNotDefined: false,
    );
    await tapNavalFleetCheckboxes(tester, ['Home Fleet', 'Fleet at_capital']);
    await tapNavalCombine(tester);
    final dialog = tester.widget<TransferToHomeFleetDialog>(
      find.byType(TransferToHomeFleetDialog),
    );
    expect(dialog.overseasCargoUsed, 5);
    expect(dialog.isCargoUsedReliable, isTrue);
    expect(dialog.cargoNotDefined, isFalse);
  });
}
