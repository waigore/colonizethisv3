// Visual goldens for MAP20001 sea-zone Patrol / Defend variants (Refs #4605).

import 'package:colonizethis_app/features/game/flame/map_state/province_naval_mission_action_state.dart';
import 'package:colonizethis_app/widgets/ct_action_text_button.dart';
import 'package:colonizethis_app_fixtures/demo/province_overlay_demo_data.dart'
    show demoGameForOverlay;
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'province_overlay_naval_sea_zone_goldens_support.dart';

void main() {
  suppressLogsForTests();

  final l10n = navalSeaZoneGoldenL10n;

  testWidgets('golden: Naval sea-zone Patrol/Defend enabled (Refs #4605)', (
    tester,
  ) async {
    const boundaryKey = ValueKey<String>(
      'province_overlay_sea_patrol_enabled_golden',
    );
    await pumpSeaNavalMissionGolden(
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
    await pumpSeaNavalMissionGolden(
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
    await pumpSeaNavalMissionGolden(
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
    await pumpSeaNavalMissionGolden(
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
    await pumpSeaNavalMissionGolden(
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
    await pumpSeaNavalMissionGolden(
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
