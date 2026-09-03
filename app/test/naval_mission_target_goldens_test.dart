// Widget goldens for naval mission target-picker dialogs (Refs #4213).
// Pins DLG31002 under AppThemes.editorialMonocle.
//
// Golden mapping:
//  - AC4–5: blockade target picker with war-enemy provinces
//  - DLG31002 empty-state when no legal targets
//
// SPEC: SPEC/ui/naval-mission-target-dialog.md.

import 'package:colonizethis_app/config/themes.dart';
import 'package:colonizethis_app/features/game/widgets/unit_orders/naval_mission_target_dialog.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

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
          'Goods from the chosen port will not reach its owner\'s warehouses until the blockade ends. Stronger interception than Patrol on fleets entering this zone.',
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
    'golden: blockade target picker shows capital-port extra line (Refs #4516)',
    (WidgetTester tester) async {
      const boundaryKey = ValueKey<String>(
        'navalMissionTargetBlockadeCapitalGolden',
      );
      const enemyCap = 'oldWorld|enemy1';
      final game = buildNavalMissionCapitalPortTargetGame();
      final fleet = game.worldState.fleets.single;

      await pumpNavalMissionGolden(
        tester,
        boundaryKey: boundaryKey,
        child: NavalMissionTargetDialog(
          game: game,
          mission: FleetMission.blockade,
          fleet: fleet,
          targetProvinceIds: const [enemyCap],
          humanPlayerId: navalMissionGoldenHumanId,
          initialTargetProvinceId: enemyCap,
        ),
      );

      expect(tester.takeException(), isNull);
      expect(find.text('Select target — Blockade'), findsOneWidget);
      expect(
        find.text(
          'At a capital port, sea-only and overseas links are cut; land roads still reach inland tiles.',
        ),
        findsOneWidget,
      );

      await expectLater(
        find.byKey(boundaryKey),
        matchesGoldenFile('goldens/naval_mission_target_blockade_capital.png'),
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
}
