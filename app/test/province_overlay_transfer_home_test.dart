// Pins MAP20001 Naval Transfer to Home Fleet overlay (Refs #4625).

import 'package:colonizethis_app/features/game/flame/map_state/province_transfer_to_home_fleet_overlay_controls.dart';
import 'package:colonizethis_app/features/game/widgets/province_overlay/province_sea_zone_detail_overlay.dart';
import 'package:colonizethis_app/widgets/ct_action_text_button.dart';
import 'package:colonizethis_app_fixtures/demo/province_overlay_demo_data.dart'
    show
        demoGameForOverlay,
        demoHumanPlayerViewForOverlay,
        demoRegionForOverlay,
        sampleProvinceIdForOverlay,
        sampleTileKeyForProvinceOverlay;
import 'package:colonizethis_app_l10n/l10n/app_localizations_en.dart';
import 'package:colonizethis_app_l10n/l10n/l10n.dart';
import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'app_shell_harness.dart';

void main() {
  suppressLogsForTests();

  final l10n = AppLocalizationsEn();
  final game = demoGameForOverlay;
  final humanId = game.players.first.id;

  Future<void> pumpOverlay(
    WidgetTester tester, {
    ProvinceTransferToHomeFleetOverlayControls transfer =
        ProvinceTransferToHomeFleetOverlayControls.hidden,
  }) async {
    await tester.pumpWidget(
      buildAppShell(
        localizationsDelegates: AppLocalizationsBinding.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('en'),
        child: SizedBox(
          width: 460,
          height: 680,
          child: ProvinceSeaZoneDetailOverlay(
            game: game,
            region: demoRegionForOverlay,
            displayId: sampleProvinceIdForOverlay,
            selectedTileKey: sampleTileKeyForProvinceOverlay,
            humanPlayerId: humanId,
            playerView: demoHumanPlayerViewForOverlay,
            omniscientDetail: true,
            transferToHomeFleet: transfer,
            onClose: () {},
          ),
        ),
      ),
    );
    await tester.pump();
  }

  testWidgets('hidden controls omit Transfer to Home Fleet', (tester) async {
    await pumpOverlay(tester);
    expect(
      find.widgetWithText(
        CtActionTextButton,
        l10n.provinceOverlay_transferToHomeFleetAction,
      ),
      findsNothing,
    );
  });

  testWidgets('enabled control shows Transfer and invokes tap', (tester) async {
    var tapped = false;
    await pumpOverlay(
      tester,
      transfer: ProvinceTransferToHomeFleetOverlayControls(
        showTransferToHomeFleet: true,
        transferToHomeFleetEnabled: true,
        transferToHomeFleetTooltip:
            l10n.provinceOverlay_transferToHomeFleetTooltip,
        onTransferToHomeFleetTap: () => tapped = true,
      ),
    );
    final navalHeader = find.text(
      l10n.provinceOverlay_sectionNaval.toUpperCase(),
    );
    await tester.ensureVisible(navalHeader);
    await tester.pump();
    final finder = find.widgetWithText(
      CtActionTextButton,
      l10n.provinceOverlay_transferToHomeFleetAction,
    );
    expect(finder, findsOneWidget);
    await tester.ensureVisible(finder);
    await tester.pump();
    await tester.tap(finder);
    expect(tapped, isTrue);
  });

  testWidgets('disabled control is visible and does not tap-open', (
    tester,
  ) async {
    var tapped = false;
    await pumpOverlay(
      tester,
      transfer: ProvinceTransferToHomeFleetOverlayControls(
        showTransferToHomeFleet: true,
        transferToHomeFleetEnabled: false,
        transferToHomeFleetTooltip:
            l10n.provinceOverlay_transferToHomeFleetDisabledTooltip,
        onTransferToHomeFleetTap: () => tapped = true,
      ),
    );
    final finder = find.widgetWithText(
      CtActionTextButton,
      l10n.provinceOverlay_transferToHomeFleetAction,
    );
    expect(finder, findsOneWidget);
    final action = tester.widget<CtActionTextButton>(finder);
    expect(action.enabled, isFalse);
    expect(action.onPressed, isNull);
    expect(tapped, isFalse);
  });
}
