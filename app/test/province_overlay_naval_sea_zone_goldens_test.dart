// Concern split under repo.app_test_file_size (Refs #4013, #4352, #4605).
// Visual goldens for MAP20001 sea-zone Patrol / Defend variants.

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
import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'golden_capture_harness.dart';

void main() {
  suppressLogsForTests();

  final l10n = AppLocalizationsEn();

  ({String displayId, String? tileKey, Game game}) seaOverlaySetup({
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

  Future<void> pumpSeaGolden(
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
    final setup = seaOverlaySetup(includeFleet: includeFleet);
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
      l10n.provinceOverlay_sectionNaval.toUpperCase(),
    );
    expect(navalHeader, findsOneWidget);
    await tester.ensureVisible(navalHeader);
    await tester.pump();
  }

  testWidgets('golden: Naval sea-zone Patrol/Defend enabled (Refs #4605)', (
    tester,
  ) async {
    const boundaryKey = ValueKey<String>(
      'province_overlay_sea_patrol_enabled_golden',
    );
    await pumpSeaGolden(
      tester,
      boundaryKey: boundaryKey,
      overlaySize: const Size(460, 680),
      surfaceSize: const Size(640, 720),
      navalMission: ProvinceNavalMissionOverlayControls(
        showPatrol: true,
        patrolEnabled: true,
        patrolTooltip: l10n.naval_mission_effect_patrol,
        onPatrolTap: () {},
        showDefend: true,
        defendEnabled: true,
        defendTooltip: l10n.naval_mission_effect_defend,
        onDefendTap: () {},
      ),
    );
    expect(
      find.widgetWithText(
        CtActionTextButton,
        l10n.provinceOverlay_patrolAction,
      ),
      findsOneWidget,
    );
    await expectLater(
      find.byKey(boundaryKey),
      matchesGoldenFile('goldens/province_overlay_sea_patrol_enabled.png'),
    );
  });

  testWidgets('golden: Naval sea-zone Patrol/Defend disabled (Refs #4605)', (
    tester,
  ) async {
    const boundaryKey = ValueKey<String>(
      'province_overlay_sea_patrol_disabled_golden',
    );
    await pumpSeaGolden(
      tester,
      boundaryKey: boundaryKey,
      overlaySize: const Size(460, 680),
      surfaceSize: const Size(640, 720),
      navalMission: ProvinceNavalMissionOverlayControls(
        showPatrol: true,
        patrolEnabled: false,
        patrolTooltip: l10n.naval_mission_noMissionsAvailable,
        showDefend: true,
        defendEnabled: false,
        defendTooltip: l10n.naval_mission_noMissionsAvailable,
      ),
    );
    await expectLater(
      find.byKey(boundaryKey),
      matchesGoldenFile('goldens/province_overlay_sea_patrol_disabled.png'),
    );
  });

  testWidgets('golden: Naval sea-zone Patrol/Defend hidden (Refs #4605)', (
    tester,
  ) async {
    const boundaryKey = ValueKey<String>(
      'province_overlay_sea_patrol_hidden_golden',
    );
    await pumpSeaGolden(
      tester,
      boundaryKey: boundaryKey,
      overlaySize: const Size(460, 680),
      surfaceSize: const Size(640, 720),
      navalMission: ProvinceNavalMissionOverlayControls.hidden,
    );
    expect(
      find.widgetWithText(
        CtActionTextButton,
        l10n.provinceOverlay_patrolAction,
      ),
      findsNothing,
    );
    await expectLater(
      find.byKey(boundaryKey),
      matchesGoldenFile('goldens/province_overlay_sea_patrol_hidden.png'),
    );
  });

  testWidgets('golden: Naval sea-zone Patrol/Defend 320 dp (Refs #4605)', (
    tester,
  ) async {
    const boundaryKey = ValueKey<String>(
      'province_overlay_sea_patrol_320_golden',
    );
    await pumpSeaGolden(
      tester,
      boundaryKey: boundaryKey,
      overlaySize: const Size(320, 680),
      surfaceSize: const Size(640, 720),
      navalMission: ProvinceNavalMissionOverlayControls(
        showPatrol: true,
        patrolEnabled: true,
        onPatrolTap: () {},
        showDefend: true,
        defendEnabled: true,
        onDefendTap: () {},
      ),
    );
    await expectLater(
      find.byKey(boundaryKey),
      matchesGoldenFile('goldens/province_overlay_sea_patrol_320.png'),
    );
  });

  testWidgets('golden: Naval sea-zone pending mission preview (Refs #4605)', (
    tester,
  ) async {
    const boundaryKey = ValueKey<String>(
      'province_overlay_sea_pending_mission_golden',
    );
    final human = demoGameForOverlay.players.first.id;
    await pumpSeaGolden(
      tester,
      boundaryKey: boundaryKey,
      overlaySize: const Size(460, 680),
      surfaceSize: const Size(640, 720),
      includeFleet: true,
      draftOrders: Orders(
        navalMissionOrdersByPlayerId: {
          human: [
            NavalMissionOrder(
              fleetId: 'overlay_sea_fleet',
              mission: FleetMission.patrol.name,
            ),
          ],
        },
      ),
      navalMission: ProvinceNavalMissionOverlayControls(
        showPatrol: true,
        patrolEnabled: false,
        showDefend: true,
        defendEnabled: false,
      ),
    );
    expect(find.textContaining('Ordered: fleet mission'), findsOneWidget);
    await expectLater(
      find.byKey(boundaryKey),
      matchesGoldenFile('goldens/province_overlay_sea_pending_mission.png'),
    );
  });

  testWidgets('golden: Naval sea-zone pending move preview (Refs #4605)', (
    tester,
  ) async {
    const boundaryKey = ValueKey<String>(
      'province_overlay_sea_pending_move_golden',
    );
    final human = demoGameForOverlay.players.first.id;
    await pumpSeaGolden(
      tester,
      boundaryKey: boundaryKey,
      overlaySize: const Size(460, 680),
      surfaceSize: const Size(640, 720),
      includeFleet: true,
      draftOrders: Orders(
        navalMoveOrdersByPlayerId: {
          human: [
            const NavalMoveOrder(
              fleetId: 'overlay_sea_fleet',
              destinationSeaZoneId: 'elsewhere',
            ),
          ],
        },
      ),
      navalMission: ProvinceNavalMissionOverlayControls(
        showPatrol: true,
        patrolEnabled: false,
        showDefend: true,
        defendEnabled: false,
      ),
    );
    expect(find.textContaining('Ordered: move fleet to sea'), findsOneWidget);
    await expectLater(
      find.byKey(boundaryKey),
      matchesGoldenFile('goldens/province_overlay_sea_pending_move.png'),
    );
  });
}
