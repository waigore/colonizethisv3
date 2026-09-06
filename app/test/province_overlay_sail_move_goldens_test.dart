// Visual goldens for MAP20001 Naval Sail / Move (Refs #4735).
// SPEC/ui/province-sea-zone-detail-overlay.md § States and variants.

import 'package:colonizethis_app/features/game/flame/map_state/province_overlay_sail_move_overlay_controls.dart';
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
import 'package:colonizethis_map/colonizethis_map.dart' show CellViewData;
import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:colonizethis_app/core/utils/prefixed_id.dart';

import 'golden_capture_harness.dart';

class _SailMoveGoldenCase {
  const _SailMoveGoldenCase({
    required this.name,
    required this.goldenFile,
    required this.showSailMove,
    required this.sailMoveEnabled,
    this.seaZone = false,
    this.showTransfer = false,
    this.overlaySize = const Size(460, 680),
    this.surfaceSize = const Size(640, 720),
  });

  final String name;
  final String goldenFile;
  final bool showSailMove;
  final bool sailMoveEnabled;
  final bool seaZone;
  final bool showTransfer;
  final Size overlaySize;
  final Size surfaceSize;
}

const List<_SailMoveGoldenCase> _cases = [
  _SailMoveGoldenCase(
    name: 'Naval Sail Move sea enabled',
    goldenFile: 'goldens/province_overlay_sail_move_sea_enabled.png',
    showSailMove: true,
    sailMoveEnabled: true,
    seaZone: true,
  ),
  _SailMoveGoldenCase(
    name: 'Naval Sail Move multi fleet',
    goldenFile: 'goldens/province_overlay_sail_move_multi_fleet.png',
    showSailMove: true,
    sailMoveEnabled: true,
    seaZone: true,
  ),
  _SailMoveGoldenCase(
    name: 'Naval Sail Move hidden',
    goldenFile: 'goldens/province_overlay_sail_move_hidden.png',
    showSailMove: false,
    sailMoveEnabled: false,
    seaZone: true,
  ),
  _SailMoveGoldenCase(
    name: 'Naval Sail Move in-port enabled',
    goldenFile: 'goldens/province_overlay_sail_move_in_port_enabled.png',
    showSailMove: true,
    sailMoveEnabled: true,
  ),
  _SailMoveGoldenCase(
    name: 'Naval Sail Move capital with Transfer',
    goldenFile: 'goldens/province_overlay_sail_move_capital_transfer.png',
    showSailMove: true,
    sailMoveEnabled: true,
    showTransfer: true,
  ),
  _SailMoveGoldenCase(
    name: 'Naval Sail Move 320 dp',
    goldenFile: 'goldens/province_overlay_sail_move_320.png',
    showSailMove: true,
    sailMoveEnabled: true,
    showTransfer: true,
    overlaySize: Size(320, 680),
  ),
];

void main() {
  suppressLogsForTests();

  final l10n = AppLocalizationsEn();

  for (final c in _cases) {
    testWidgets('golden: ${c.name} (Refs #4735)', (WidgetTester tester) async {
      await configureGoldenSurface(tester, size: c.surfaceSize);
      configureGoldenView(
        tester,
        physicalSize: c.surfaceSize,
        devicePixelRatio: 1.0,
      );

      final boundaryKey = ValueKey<String>('province_overlay_${c.name}_golden');
      final game = demoGameForOverlay;
      final humanId = game.players.first.id;
      final region = demoRegionForOverlay;
      String displayId = sampleProvinceIdForOverlay;
      String? tileKey = sampleTileKeyForProvinceOverlay;
      if (c.seaZone) {
        displayId = sampleSeaZoneIdForOverlay;
        final localSea = prefixedIdLocalSegment(displayId);
        final regionId = prefixedIdRegionSegment(displayId) ?? region.regionId;
        CellViewData? seaCell;
        for (final cell in region.cells) {
          if (cell.isSea && cell.regionCellId == localSea) {
            seaCell = cell;
            break;
          }
        }
        tileKey = seaCell == null
            ? null
            : '$regionId|${seaCell.regionCellId}|${seaCell.x}|${seaCell.y}';
      }

      await tester.pumpWidget(
        wrapGoldenBoundary(
          boundaryKey: boundaryKey,
          includeLocalizations: true,
          child: SizedBox(
            width: c.overlaySize.width,
            height: c.overlaySize.height,
            child: ProvinceSeaZoneDetailOverlay(
              game: game,
              region: region,
              displayId: displayId,
              selectedTileKey: tileKey,
              humanPlayerId: humanId,
              playerView: demoHumanPlayerViewForOverlay,
              omniscientDetail: true,
              transferToHomeFleet: ProvinceTransferToHomeFleetOverlayControls(
                showTransferToHomeFleet: c.showTransfer,
                transferToHomeFleetEnabled: c.showTransfer,
                transferToHomeFleetTooltip: c.showTransfer
                    ? l10n.provinceOverlay_transferToHomeFleetTooltip
                    : '',
                onTransferToHomeFleetTap: () {},
              ),
              sailMove: ProvinceOverlaySailMoveOverlayControls(
                showSailMove: c.showSailMove,
                sailMoveEnabled: c.sailMoveEnabled,
                sailMoveTooltip: c.sailMoveEnabled
                    ? l10n.naval_mission_effect_sail
                    : '',
                onSailMoveTap: () {},
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
        l10n.naval_mission_sail,
      );
      if (c.showSailMove) {
        expect(actionFinder, findsOneWidget);
        final action = tester.widget<CtActionTextButton>(actionFinder);
        expect(action.enabled, c.sailMoveEnabled);
        expect(action.onPressed, isNotNull);
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
