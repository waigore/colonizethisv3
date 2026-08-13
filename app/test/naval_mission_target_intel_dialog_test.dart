// Pins DLG31002 Beachhead/Blockade target intel dialog rows (Refs #4340).

import 'package:colonizethis_app/features/game/widgets/unit_orders/naval_mission_target_dialog.dart';
import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:colonizethis_world/colonizethis_world.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'app_shell_harness.dart';
import 'naval_mission_target_intel_test_support.dart';

void main() {
  suppressLogsForTests();

  group('NavalMissionTargetDialog intel rows', () {
    testWidgets(
      'beachhead full intel shows unopposed and defender + stone fort labels',
      (tester) async {
        final game = buildNavalMissionIntelGame(
          visibilityByTile: {
            'oldWorld|p_empty|0|0': 'fullyVisible',
            'oldWorld|p_fort|0|0': 'fullyVisible',
          },
          units: [
            Unit(
              id: 'd1',
              type: 'musketeers',
              ownerId: navalIntelRivalId,
              locationProvinceId: navalIntelDefended,
            ),
            Unit(
              id: 'd2',
              type: 'pikemen',
              ownerId: navalIntelRivalId,
              locationProvinceId: navalIntelDefended,
            ),
          ],
        );
        final view =
            buildPlayerView(game, const MapTopology(), navalIntelHumanId);

        await tester.pumpWidget(
          buildAppShell(
            child: NavalMissionTargetDialog(
              game: game,
              mission: FleetMission.beachhead,
              fleet: navalIntelFleet,
              targetProvinceIds: const [navalIntelUnopposed, navalIntelDefended],
              humanPlayerId: navalIntelHumanId,
              playerView: view,
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('Open Coast'), findsOneWidget);
        expect(find.text('Stone Harbor'), findsOneWidget);
        expect(find.text('Unopposed capture'), findsOneWidget);
        expect(find.text('Defenders: 2 regiments'), findsOneWidget);
        expect(find.text('Stone fort siege'), findsOneWidget);
        expect(find.textContaining('musketeers'), findsNothing);

        await tester.tap(find.text('Stone Harbor'));
        await tester.pumpAndSettle();
        expect(find.textContaining('Musketeers'), findsOneWidget);
        expect(find.textContaining('Pikemen'), findsOneWidget);
      },
    );

    testWidgets(
      'blockade fogged target shows harbor unknown without fleet counts',
      (tester) async {
        final game = buildNavalMissionIntelGame(
          visibilityByTile: {
            'oldWorld|p_port|0|0': 'fogged',
          },
          portsByProvinceSeaboard: const {
            'oldWorld|p_port|sea1': 'oldWorld|p_port|0|0',
          },
          fleets: [
            Fleet(
              id: 'enemy_a',
              ownerId: navalIntelRivalId,
              regionId: 'oldWorld',
              inPortAtProvinceId: navalIntelPortProvince,
              ships: const [ShipInstance(id: 'ea', typeId: 'carrack')],
            ),
          ],
        );
        final view =
            buildPlayerView(game, const MapTopology(), navalIntelHumanId);

        await tester.pumpWidget(
          buildAppShell(
            child: NavalMissionTargetDialog(
              game: game,
              mission: FleetMission.blockade,
              fleet: navalIntelFleet,
              targetProvinceIds: const [navalIntelPortProvince],
              humanPlayerId: navalIntelHumanId,
              playerView: view,
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('Harbor status unknown'), findsOneWidget);
        expect(find.text('1 fleets in port'), findsNothing);
        expect(find.text('Empty harbor'), findsNothing);
      },
    );

    testWidgets('omitted playerView degrades to unknown without leaking world', (
      tester,
    ) async {
      final game = buildNavalMissionIntelGame(
        visibilityByTile: {
          'oldWorld|p_empty|0|0': 'fullyVisible',
          'oldWorld|p_port|0|0': 'fullyVisible',
        },
        portsByProvinceSeaboard: const {
          'oldWorld|p_port|sea1': 'oldWorld|p_port|0|0',
        },
        units: [
          Unit(
            id: 'd1',
            type: 'musketeers',
            ownerId: navalIntelRivalId,
            locationProvinceId: navalIntelUnopposed,
          ),
        ],
        fleets: [
          Fleet(
            id: 'enemy_a',
            ownerId: navalIntelRivalId,
            regionId: 'oldWorld',
            inPortAtProvinceId: navalIntelPortProvince,
            ships: const [ShipInstance(id: 'ea', typeId: 'carrack')],
          ),
        ],
      );

      await tester.pumpWidget(
        buildAppShell(
          child: NavalMissionTargetDialog(
            game: game,
            mission: FleetMission.beachhead,
            fleet: navalIntelFleet,
            targetProvinceIds: const [navalIntelUnopposed],
            humanPlayerId: navalIntelHumanId,
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Defenders unknown'), findsOneWidget);
      expect(find.text('Unopposed capture'), findsNothing);

      await tester.pumpWidget(
        buildAppShell(
          child: NavalMissionTargetDialog(
            game: game,
            mission: FleetMission.blockade,
            fleet: navalIntelFleet,
            targetProvinceIds: const [navalIntelPortProvince],
            humanPlayerId: navalIntelHumanId,
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Harbor status unknown'), findsOneWidget);
      expect(find.text('1 fleets in port'), findsNothing);
    });

    testWidgets('confirm still returns selected targetProvinceId', (tester) async {
      final game = buildNavalMissionIntelGame(
        visibilityByTile: {
          'oldWorld|p_empty|0|0': 'fullyVisible',
        },
      );
      final view =
          buildPlayerView(game, const MapTopology(), navalIntelHumanId);
      String? popped;

      await tester.pumpWidget(
        buildAppShell(
          child: Builder(
            builder: (context) {
              return TextButton(
                onPressed: () async {
                  popped = await showDialog<String>(
                    context: context,
                    builder: (_) => NavalMissionTargetDialog(
                      game: game,
                      mission: FleetMission.beachhead,
                      fleet: navalIntelFleet,
                      targetProvinceIds: const [navalIntelUnopposed],
                      humanPlayerId: navalIntelHumanId,
                      playerView: view,
                    ),
                  );
                },
                child: const Text('open'),
              );
            },
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Open Coast'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Confirm'));
      await tester.pumpAndSettle();
      expect(popped, navalIntelUnopposed);
    });
  });
}
