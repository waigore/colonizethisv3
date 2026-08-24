// Visual goldens for MAP20001 Naval Transfer to Home Fleet (Refs #4625).
// SPEC/ui/province-sea-zone-detail-overlay.md § States and variants.

import 'package:colonizethis_app/features/game/flame/map_state/province_transfer_to_home_fleet_overlay_controls.dart';
import 'package:colonizethis_app/features/game/widgets/province_overlay/province_sea_zone_detail_overlay.dart';
import 'package:colonizethis_app/widgets/ct_action_text_button.dart';
import 'package:colonizethis_app_fixtures/demo/province_overlay_demo_data.dart'
    show
        demoGameForOverlay,
        demoHumanPlayerViewForOverlay,
        demoRegionForOverlay,
        sampleProvinceIdForOverlay,
        sampleSeaZoneIdForOverlay,
        sampleTileKeyForProvinceOverlay;
import 'package:colonizethis_app_l10n/l10n/app_localizations_en.dart';
import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'golden_capture_harness.dart';

class _TransferHomeGoldenCase {
  const _TransferHomeGoldenCase({
    required this.name,
    required this.goldenFile,
    required this.showTransfer,
    required this.transferEnabled,
    this.useSeaZone = false,
    this.overlaySize = const Size(460, 680),
    this.surfaceSize = const Size(640, 720),
  });

  final String name;
  final String goldenFile;
  final bool showTransfer;
  final bool transferEnabled;
  final bool useSeaZone;
  final Size overlaySize;
  final Size surfaceSize;
}

const List<_TransferHomeGoldenCase> _cases = [
  _TransferHomeGoldenCase(
    name: 'Naval Transfer to Home Fleet enabled',
    goldenFile: 'goldens/province_overlay_transfer_home_enabled.png',
    showTransfer: true,
    transferEnabled: true,
  ),
  _TransferHomeGoldenCase(
    name: 'Naval Transfer to Home Fleet disabled',
    goldenFile: 'goldens/province_overlay_transfer_home_disabled.png',
    showTransfer: true,
    transferEnabled: false,
  ),
  _TransferHomeGoldenCase(
    name: 'Naval Transfer to Home Fleet hidden',
    goldenFile: 'goldens/province_overlay_transfer_home_hidden.png',
    showTransfer: false,
    transferEnabled: false,
  ),
  _TransferHomeGoldenCase(
    name: 'Naval Transfer to Home Fleet sea-zone enabled',
    goldenFile: 'goldens/province_overlay_transfer_home_sea.png',
    showTransfer: true,
    transferEnabled: true,
    useSeaZone: true,
  ),
  _TransferHomeGoldenCase(
    name: 'Naval Transfer to Home Fleet 320 dp',
    goldenFile: 'goldens/province_overlay_transfer_home_320.png',
    showTransfer: true,
    transferEnabled: true,
    overlaySize: Size(320, 680),
  ),
];

void main() {
  suppressLogsForTests();

  final l10n = AppLocalizationsEn();

  for (final c in _cases) {
    testWidgets('golden: ${c.name} (Refs #4625)', (WidgetTester tester) async {
      await configureGoldenSurface(tester, size: c.surfaceSize);
      configureGoldenView(
        tester,
        physicalSize: c.surfaceSize,
        devicePixelRatio: 1.0,
      );

      final boundaryKey = ValueKey<String>('province_overlay_${c.name}_golden');
      final game = demoGameForOverlay;
      final humanId = game.players.first.id;
      final displayId = c.useSeaZone
          ? sampleSeaZoneIdForOverlay
          : sampleProvinceIdForOverlay;

      await tester.pumpWidget(
        wrapGoldenBoundary(
          boundaryKey: boundaryKey,
          includeLocalizations: true,
          child: SizedBox(
            width: c.overlaySize.width,
            height: c.overlaySize.height,
            child: ProvinceSeaZoneDetailOverlay(
              game: game,
              region: demoRegionForOverlay,
              displayId: displayId,
              selectedTileKey: c.useSeaZone
                  ? null
                  : sampleTileKeyForProvinceOverlay,
              humanPlayerId: humanId,
              playerView: demoHumanPlayerViewForOverlay,
              omniscientDetail: true,
              transferToHomeFleet: ProvinceTransferToHomeFleetOverlayControls(
                showTransferToHomeFleet: c.showTransfer,
                transferToHomeFleetEnabled: c.transferEnabled,
                transferToHomeFleetTooltip: c.transferEnabled
                    ? l10n.provinceOverlay_transferToHomeFleetTooltip
                    : l10n.provinceOverlay_transferToHomeFleetDisabledTooltip,
                onTransferToHomeFleetTap: () {},
              ),
              onClose: () {},
            ),
          ),
        ),
      );
      await pumpForGolden(tester);

      expect(tester.takeException(), isNull);
      final navalHeader = find.text(
        l10n.provinceOverlay_sectionNaval.toUpperCase(),
      );
      expect(navalHeader, findsOneWidget);
      await tester.ensureVisible(navalHeader);
      await tester.pump();

      final actionFinder = find.widgetWithText(
        CtActionTextButton,
        l10n.provinceOverlay_transferToHomeFleetAction,
      );
      if (c.showTransfer) {
        expect(actionFinder, findsOneWidget);
        final action = tester.widget<CtActionTextButton>(actionFinder);
        expect(action.enabled, c.transferEnabled);
        await tester.ensureVisible(actionFinder);
        await tester.pump();
      } else {
        expect(actionFinder, findsNothing);
      }

      await expectLater(
        find.byKey(boundaryKey),
        matchesGoldenFile(c.goldenFile),
      );
    });
  }
}
