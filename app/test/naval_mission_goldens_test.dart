// Widget goldens for naval mission assign dialogs (Refs #4213).
// Pins DLG31001–DLG31003 under AppThemes.editorialMonocle.
//
// Golden mapping:
//  - AC1–2: mission menu with gated blockade/beachhead rows
//  - AC6: cancel-pending row when draft mission exists
//  - AC4–5: blockade target picker with war-enemy provinces
//  - DLG31002 empty-state when no legal targets
//  - AC2: fleet picker when multiple fleets share a marker
//
// SPEC: SPEC/ui/naval-mission-menu-dialog.md,
//       SPEC/ui/naval-mission-target-dialog.md,
//       SPEC/ui/naval-mission-fleet-picker-dialog.md.

import 'package:colonizethis_app/config/themes.dart';
import 'package:colonizethis_app/features/game/widgets/unit_orders/naval_mission_menu_dialog.dart';
import 'package:colonizethis_app/features/game/widgets/unit_orders/naval_mission_target_dialog.dart';
import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'editorial_monocle_dark_token_assertions.dart';
import 'golden_capture_harness.dart';
import 'naval_mission_goldens_test_support.dart';
import 'widget_test_assets.dart';

void main() {
  suppressLogsForTests();

  setUpAll(() async {
    await setUpNinePatchAssets();
  });

  Future<void> pumpNavalMissionGolden(
    WidgetTester tester, {
    required Key boundaryKey,
    required Widget child,
    Size physicalSize = kNavalMissionGoldenViewport,
  }) async {
    await pumpGoldenHost(
      tester,
      boundaryKey: boundaryKey,
      physicalSize: physicalSize,
      settle: false,
      includeLocalizations: true,
      scaffoldBackgroundColor:
          AppThemes.editorialMonocle.scaffoldBackgroundColor,
      child: child,
    );
  }

  testWidgets(
    'golden: mission menu peacetime gates blockade and beachhead (Refs #4213)',
    (WidgetTester tester) async {
      const boundaryKey = ValueKey<String>('navalMissionMenuPeacetimeGolden');
      final game = buildNavalMissionMenuPeacetimeGame();
      final fleet = game.worldState.fleets.single;
      final availability = navalMissionAvailabilityForFleet(
        game: game,
        topology: const MapTopology(),
        playerId: navalMissionGoldenHumanId,
        fleet: fleet,
        currentOrders: const Orders(),
      );

      await pumpNavalMissionGolden(
        tester,
        boundaryKey: boundaryKey,
        child: NavalMissionMenuDialog(
          game: game,
          fleet: fleet,
          availability: availability,
        ),
      );

      expect(tester.takeException(), isNull);
      expectEditorialMonocleDarkChrome(tester);
      expect(find.text('Assign mission — Fleet sea_named'), findsOneWidget);
      expect(find.text('Patrol'), findsOneWidget);
      expect(find.text('Defend'), findsOneWidget);
      expect(find.text('Blockade'), findsOneWidget);
      expect(find.text('Beachhead'), findsOneWidget);

      await expectLater(
        find.byKey(boundaryKey),
        matchesGoldenFile('goldens/naval_mission_menu_peacetime.png'),
      );
    },
  );

  testWidgets(
    'golden: mission menu shows cancel pending row (Refs #4213)',
    (WidgetTester tester) async {
      const boundaryKey = ValueKey<String>('navalMissionMenuCancelPendingGolden');
      final game = buildNavalMissionMenuPeacetimeGame();
      final fleet = game.worldState.fleets.single;
      final availability = navalMissionAvailabilityForFleet(
        game: game,
        topology: const MapTopology(),
        playerId: navalMissionGoldenHumanId,
        fleet: fleet,
        currentOrders: Orders(
          navalMissionOrdersByPlayerId: {
            navalMissionGoldenHumanId: const [
              NavalMissionOrder(fleetId: 'sea_named', mission: 'patrol'),
            ],
          },
        ),
      );

      await pumpNavalMissionGolden(
        tester,
        boundaryKey: boundaryKey,
        child: NavalMissionMenuDialog(
          game: game,
          fleet: fleet,
          availability: availability,
        ),
      );

      expect(tester.takeException(), isNull);
      expect(find.text('Cancel pending mission'), findsOneWidget);

      await expectLater(
        find.byKey(boundaryKey),
        matchesGoldenFile('goldens/naval_mission_menu_cancel_pending.png'),
      );
    },
  );

  testWidgets(
    'golden: blockade target picker lists war-enemy provinces (Refs #4213)',
    (WidgetTester tester) async {
      const boundaryKey = ValueKey<String>('navalMissionTargetBlockadeGolden');
      final game = buildNavalMissionWarTargetsGame();
      final fleet = game.worldState.fleets.single;
      final availability = navalMissionAvailabilityForFleet(
        game: game,
        topology: navalMissionWarTopology(),
        playerId: navalMissionGoldenHumanId,
        fleet: fleet,
        currentOrders: const Orders(),
      );

      await pumpNavalMissionGolden(
        tester,
        boundaryKey: boundaryKey,
        child: NavalMissionTargetDialog(
          game: game,
          mission: FleetMission.blockade,
          fleet: fleet,
          targetProvinceIds: availability.blockadeTargetProvinceIds,
          humanPlayerId: navalMissionGoldenHumanId,
        ),
      );

      expect(tester.takeException(), isNull);
      expect(find.text('Select target — Blockade'), findsOneWidget);
      expect(
        find.text(
          'Pressures the target port approaches with stronger interception than Patrol.',
        ),
        findsOneWidget,
      );
      expect(find.text('Enemy Port'), findsOneWidget);
      expect(find.text('Hostile Coast'), findsOneWidget);
      expect(find.text('Harbor status unknown'), findsNWidgets(2));

      await expectLater(
        find.byKey(boundaryKey),
        matchesGoldenFile('goldens/naval_mission_target_blockade.png'),
      );
    },
  );

  testWidgets(
    'golden: beachhead target picker shows invasion timing caption (Refs #4295)',
    (WidgetTester tester) async {
      const boundaryKey = ValueKey<String>('navalMissionTargetBeachheadGolden');
      final game = buildNavalMissionWarTargetsGame();
      final fleet = game.worldState.fleets.single;
      final availability = navalMissionAvailabilityForFleet(
        game: game,
        topology: navalMissionWarTopology(),
        playerId: navalMissionGoldenHumanId,
        fleet: fleet,
        currentOrders: const Orders(),
      );

      await pumpNavalMissionGolden(
        tester,
        boundaryKey: boundaryKey,
        child: NavalMissionTargetDialog(
          game: game,
          mission: FleetMission.beachhead,
          fleet: fleet,
          targetProvinceIds: availability.beachheadTargetProvinceIds,
          humanPlayerId: navalMissionGoldenHumanId,
        ),
      );

      expect(tester.takeException(), isNull);
      expect(find.text('Select target — Beachhead'), findsOneWidget);
      expect(
        find.text(
          'Landing site supports invasion on the following turn and expires after that turn if unused.',
        ),
        findsOneWidget,
      );
      expect(find.text('Defenders unknown'), findsWidgets);

      await expectLater(
        find.byKey(boundaryKey),
        matchesGoldenFile('goldens/naval_mission_target_beachhead.png'),
      );
    },
  );

  testWidgets(
    'golden: target picker empty state disables confirm (Refs #4213)',
    (WidgetTester tester) async {
      const boundaryKey = ValueKey<String>('navalMissionTargetEmptyGolden');
      final game = buildNavalMissionWarTargetsGame();
      final fleet = game.worldState.fleets.single;

      await pumpNavalMissionGolden(
        tester,
        boundaryKey: boundaryKey,
        physicalSize: const Size(360, 280),
        child: NavalMissionTargetDialog(
          game: game,
          mission: FleetMission.beachhead,
          fleet: fleet,
          targetProvinceIds: const [],
          humanPlayerId: navalMissionGoldenHumanId,
        ),
      );

      expect(tester.takeException(), isNull);
      expect(find.text('No legal targets for this mission.'), findsOneWidget);

      await expectLater(
        find.byKey(boundaryKey),
        matchesGoldenFile('goldens/naval_mission_target_empty.png'),
      );
    },
  );

  testWidgets(
    'golden: fleet picker lists fleets at shared marker (Refs #4213)',
    (WidgetTester tester) async {
      const boundaryKey = ValueKey<String>('navalMissionFleetPickerGolden');
      final game = buildNavalMissionFleetPickerGame();

      await pumpNavalMissionGolden(
        tester,
        boundaryKey: boundaryKey,
        physicalSize: const Size(360, 320),
        child: NavalMissionFleetPickerDialog(
          game: game,
          humanPlayerId: navalMissionGoldenHumanId,
          fleetIds: const ['fleet_alpha', 'fleet_beta'],
          initialFleetId: 'fleet_alpha',
        ),
      );

      expect(tester.takeException(), isNull);
      expect(find.text('Select fleet'), findsOneWidget);
      expect(find.text('Fleet fleet_alpha'), findsOneWidget);
      expect(find.text('Fleet fleet_beta'), findsOneWidget);

      await expectLater(
        find.byKey(boundaryKey),
        matchesGoldenFile('goldens/naval_mission_fleet_picker.png'),
      );
    },
  );
}
