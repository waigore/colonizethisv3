// Host goldens for TransferToHomeFleetDialog cargo line (Refs #4544).
// SPEC/ui/transfer-to-home-fleet-dialog.md.

import 'package:colonizethis_app/config/themes.dart';
import 'package:colonizethis_app/features/game/widgets/unit_orders/home_fleet_cargo_consequence.dart';
import 'package:colonizethis_app/features/game/widgets/unit_orders/transfer_to_home_fleet_dialog.dart';
import 'package:colonizethis_app_l10n/l10n/app_localizations_en.dart';
import 'package:colonizethis_app_ui_chrome/config/editorial_monocle_palette.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'editorial_monocle_dark_token_assertions.dart';
import 'golden_capture_harness.dart';
import 'transfer_to_home_fleet_dialog_test_support.dart';
import 'widget_test_assets.dart';

void main() {
  suppressLogsForTests();
  TestWidgetsFlutterBinding.ensureInitialized();

  final l10n = AppLocalizationsEn();
  final fixture = transferCargoFixture();

  setUpAll(setUpNinePatchAssets);

  Future<void> pumpTransferGolden({
    required WidgetTester tester,
    required Key boundaryKey,
    required Size size,
  }) async {
    await pumpGoldenHost(
      tester,
      boundaryKey: boundaryKey,
      physicalSize: size,
      settle: false,
      includeLocalizations: true,
      scaffoldBackgroundColor:
          AppThemes.editorialMonocle.scaffoldBackgroundColor,
      child: TransferToHomeFleetDialog(
        sourceFleet: fixture.source,
        homeFleet: fixture.home,
        game: fixture.game,
        humanPlayerId: kTransferCargoPlayerId,
        bus: AppEventBus.create(),
        overseasCargoUsed: 2,
      ),
    );
  }

  const expected = 3;
  const used = 2;

  testWidgets('golden: default cargo line muted (Refs #4544)', (tester) async {
    const boundaryKey = ValueKey<String>('transferHomeCargoGolden');
    await pumpTransferGolden(
      tester: tester,
      boundaryKey: boundaryKey,
      size: const Size(520, 640),
    );
    expect(tester.takeException(), isNull);
    expectEditorialMonocleDarkChrome(tester);
    final cargo = find.text(
      homeFleetTransferCargoLineText(
        l10n: l10n,
        remainingHolds: expected,
        overseasUsed: used,
        isCargoUsedReliable: true,
        cargoNotDefined: false,
      ),
    );
    expect(cargo, findsOneWidget);
    expect(
      tester.widget<Text>(cargo).style?.color,
      EditorialMonoclePalette.muted,
    );
    await expectLater(
      find.byKey(boundaryKey),
      matchesGoldenFile('goldens/transfer_to_home_fleet_dialog_cargo.png'),
    );
  });

  testWidgets('golden: cargo line wraps at 320 dp (Refs #4544)', (
    tester,
  ) async {
    const boundaryKey = ValueKey<String>('transferHomeCargo320Golden');
    await pumpTransferGolden(
      tester: tester,
      boundaryKey: boundaryKey,
      size: const Size(320, 640),
    );
    expect(tester.takeException(), isNull);
    expectEditorialMonocleDarkChrome(tester);
    expect(
      find.text(
        homeFleetTransferCargoLineText(
          l10n: l10n,
          remainingHolds: expected,
          overseasUsed: used,
          isCargoUsedReliable: true,
          cargoNotDefined: false,
        ),
      ),
      findsOneWidget,
    );
    await expectLater(
      find.byKey(boundaryKey),
      matchesGoldenFile(
        'goldens/transfer_to_home_fleet_dialog_cargo_320dp.png',
      ),
    );
  });
}
