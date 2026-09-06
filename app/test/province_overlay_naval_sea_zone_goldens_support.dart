// Golden pump helpers for MAP20001 sea-zone Patrol / Defend variants (Refs #4605).

import 'package:colonizethis_app/features/game/flame/map_state/province_naval_mission_action_state.dart';
import 'package:colonizethis_app/features/game/widgets/province_overlay/province_sea_zone_detail_overlay.dart';
import 'package:colonizethis_app/widgets/ct_action_text_button.dart';
import 'package:colonizethis_app_fixtures/demo/province_overlay_demo_data.dart'
    show
        demoGameForOverlay,
        demoHumanPlayerViewForOverlay,
        demoRegionForOverlay,
        sampleSeaZoneIdForOverlay;
import 'package:colonizethis_app_l10n/l10n/app_localizations_en.dart';
import 'package:colonizethis_map/colonizethis_map.dart' show CellViewData;
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'golden_capture_harness.dart';

final navalSeaZoneGoldenL10n = AppLocalizationsEn();

({String displayId, String? tileKey, Game game}) seaOverlayGoldenSetup({
  bool includeFleet = false,
}) {
  final region = demoRegionForOverlay;
  final seaId = sampleSeaZoneIdForOverlay;
  final local = seaId.contains('|') ? seaId.split('|').last : seaId;
  CellViewData? seaCell;
  for (final c in region.cells) {
    if (c.isSea && c.regionCellId == local) {
      seaCell = c;
      break;
    }
  }
  final tileKey = seaCell == null
      ? null
      : '${region.regionId}|${seaCell.regionCellId}|${seaCell.x}|${seaCell.y}';
  final base = demoGameForOverlay;
  final game = includeFleet
      ? base.copyWith(
          worldState: base.worldState.copyWith(
            fleets: [
              ...base.worldState.fleets,
              Fleet(
                id: 'overlay_sea_fleet',
                ownerId: base.players.first.id,
                regionId: region.regionId,
                seaZoneId: local,
                ships: const [ShipInstance(id: 'os1', typeId: 'carrack')],
              ),
            ],
          ),
        )
      : base;
  return (displayId: seaId, tileKey: tileKey, game: game);
}

Future<void> pumpSeaNavalMissionGolden(
  WidgetTester tester, {
  required ValueKey<String> boundaryKey,
  required Size overlaySize,
  required Size surfaceSize,
  required ProvinceNavalMissionOverlayControls navalMission,
  Orders draftOrders = const Orders(),
  bool includeFleet = false,
}) async {
  await configureGoldenSurface(tester, size: surfaceSize);
  configureGoldenView(
    tester,
    physicalSize: surfaceSize,
    devicePixelRatio: 1.0,
  );
  final setup = seaOverlayGoldenSetup(includeFleet: includeFleet);
  await tester.pumpWidget(
    wrapGoldenBoundary(
      boundaryKey: boundaryKey,
      includeLocalizations: true,
      child: SizedBox(
        width: overlaySize.width,
        height: overlaySize.height,
        child: ProvinceSeaZoneDetailOverlay(
          game: setup.game,
          region: demoRegionForOverlay,
          displayId: setup.displayId,
          selectedTileKey: setup.tileKey,
          humanPlayerId: setup.game.players.first.id,
          playerView: demoHumanPlayerViewForOverlay,
          omniscientDetail: true,
          draftOrders: draftOrders,
          navalMission: navalMission,
          onClose: () {},
        ),
      ),
    ),
  );
  await pumpForGolden(tester);
  final navalHeader = find.text(
    navalSeaZoneGoldenL10n.provinceOverlay_sectionNaval.toUpperCase(),
  );
  expect(navalHeader, findsOneWidget);
  await tester.ensureVisible(navalHeader);
  await tester.pump();
}
