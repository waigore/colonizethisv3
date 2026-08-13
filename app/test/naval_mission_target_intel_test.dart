// Pins DLG31002 Beachhead/Blockade target intel helpers and rows (Refs #4340).

import 'package:colonizethis_app/features/game/widgets/unit_orders/naval_mission_target_dialog.dart';
import 'package:colonizethis_app/features/game/widgets/unit_orders/naval_mission_target_intel.dart';
import 'package:colonizethis_app/features/game/widgets/unit_orders/naval_mission_target_intel_labels.dart';
import 'package:colonizethis_app_l10n/l10n/l10n.dart';
import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:colonizethis_world/colonizethis_world.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'app_shell_harness.dart';

void main() {
  suppressLogsForTests();

  const humanId = 'gp_naval_intel';
  const rivalId = 'gp_naval_rival';
  const unopposed = 'oldWorld|p_empty';
  const defended = 'oldWorld|p_fort';
  const portProvince = 'oldWorld|p_port';
  const noPortProvince = 'oldWorld|p_coast';

  Game buildIntelGame({
    required Map<String, String> visibilityByTile,
    List<Unit> units = const [],
    List<Fleet> fleets = const [],
    Map<String, String> portsByProvinceSeaboard = const {},
  }) {
    return Game(
      id: 'g_naval_target_intel',
      worldState: WorldState(
        turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 1),
        oldWorld: RegionData(
          provinces: const [
            Province(
              id: unopposed,
              regionId: 'oldWorld',
              ownerId: rivalId,
              displayName: 'Open Coast',
            ),
            Province(
              id: defended,
              regionId: 'oldWorld',
              ownerId: rivalId,
              displayName: 'Stone Harbor',
              fortLevel: 2,
            ),
            Province(
              id: portProvince,
              regionId: 'oldWorld',
              ownerId: rivalId,
              displayName: 'Busy Port',
            ),
            Province(
              id: noPortProvince,
              regionId: 'oldWorld',
              ownerId: rivalId,
              displayName: 'Coast Only',
            ),
          ],
          units: units,
        ),
        newWorld: const RegionData(),
        fleets: fleets,
        portsByProvinceSeaboard: portsByProvinceSeaboard,
        tileKeysByRegionAndProvince: const {
          'oldWorld': {
            unopposed: ['oldWorld|p_empty|0|0'],
            defended: ['oldWorld|p_fort|0|0'],
            portProvince: ['oldWorld|p_port|0|0'],
            noPortProvince: ['oldWorld|p_coast|0|0'],
          },
        },
        playerVisibilityByTile: {humanId: visibilityByTile},
      ),
      players: const [
        Player(id: humanId, displayName: 'England', isHuman: true),
        Player(id: rivalId, displayName: 'Spain', isHuman: false),
      ],
      diplomacyRelations: const [
        DiplomacyRelation(
          factionId1: humanId,
          factionId2: rivalId,
          state: RelationState.atWar,
        ),
      ],
    );
  }

  final fleet = Fleet(
    id: 'f_at_sea',
    ownerId: humanId,
    regionId: 'oldWorld',
    seaZoneId: 'sea1',
    ships: const [ShipInstance(id: 's1', typeId: 'carrack')],
  );

  group('computeNavalMissionHarborIntelSummary', () {
    test('unknown when playerView is null', () {
      final game = buildIntelGame(visibilityByTile: const {});
      final summary = computeNavalMissionHarborIntelSummary(
        game: game,
        playerView: null,
        humanPlayerId: humanId,
        targetProvinceId: portProvince,
      );
      expect(summary.intelLevel, NavalMissionHarborIntelLevel.unknown);
    });

    test('unknown when target tiles are fogged', () {
      final game = buildIntelGame(
        visibilityByTile: {
          'oldWorld|p_port|0|0': 'fogged',
        },
        portsByProvinceSeaboard: const {
          'oldWorld|p_port|sea1': 'oldWorld|p_port|0|0',
        },
      );
      final view = buildPlayerView(game, const MapTopology(), humanId);
      final summary = computeNavalMissionHarborIntelSummary(
        game: game,
        playerView: view,
        humanPlayerId: humanId,
        targetProvinceId: portProvince,
      );
      expect(summary.intelLevel, NavalMissionHarborIntelLevel.unknown);
      final l10n = lookupAppLocalizations(const Locale('en'));
      expect(
        navalMissionHarborIntelSummaryLines(l10n, summary),
        ['Harbor status unknown'],
      );
    });

    test('full intel empty harbor when port present and no hostile fleets', () {
      final game = buildIntelGame(
        visibilityByTile: {
          'oldWorld|p_port|0|0': 'fullyVisible',
        },
        portsByProvinceSeaboard: const {
          'oldWorld|p_port|sea1': 'oldWorld|p_port|0|0',
        },
      );
      final view = buildPlayerView(game, const MapTopology(), humanId);
      final summary = computeNavalMissionHarborIntelSummary(
        game: game,
        playerView: view,
        humanPlayerId: humanId,
        targetProvinceId: portProvince,
      );
      expect(summary.intelLevel, NavalMissionHarborIntelLevel.full);
      expect(summary.portPresent, isTrue);
      expect(summary.emptyHarbor, isTrue);
      final l10n = lookupAppLocalizations(const Locale('en'));
      expect(
        navalMissionHarborIntelSummaryLines(l10n, summary),
        ['Empty harbor'],
      );
    });

    test('full intel summarizes two hostile fleets in port', () {
      final game = buildIntelGame(
        visibilityByTile: {
          'oldWorld|p_port|0|0': 'fullyVisible',
        },
        portsByProvinceSeaboard: const {
          'oldWorld|p_port|sea1': 'oldWorld|p_port|0|0',
        },
        fleets: [
          Fleet(
            id: 'enemy_a',
            ownerId: rivalId,
            regionId: 'oldWorld',
            inPortAtProvinceId: portProvince,
            ships: const [ShipInstance(id: 'ea', typeId: 'carrack')],
          ),
          Fleet(
            id: 'enemy_b',
            ownerId: rivalId,
            regionId: 'oldWorld',
            inPortAtProvinceId: portProvince,
            ships: const [ShipInstance(id: 'eb', typeId: 'galleon')],
          ),
        ],
      );
      final view = buildPlayerView(game, const MapTopology(), humanId);
      final summary = computeNavalMissionHarborIntelSummary(
        game: game,
        playerView: view,
        humanPlayerId: humanId,
        targetProvinceId: portProvince,
      );
      expect(summary.hostileFleetsInPortCount, 2);
      final l10n = lookupAppLocalizations(const Locale('en'));
      expect(
        navalMissionHarborIntelSummaryLines(l10n, summary),
        ['2 fleets in port'],
      );
    });

    test('full intel reports no port when seaboard registry is empty', () {
      final game = buildIntelGame(
        visibilityByTile: {
          'oldWorld|p_coast|0|0': 'fullyVisible',
        },
      );
      final view = buildPlayerView(game, const MapTopology(), humanId);
      final summary = computeNavalMissionHarborIntelSummary(
        game: game,
        playerView: view,
        humanPlayerId: humanId,
        targetProvinceId: noPortProvince,
      );
      expect(summary.portPresent, isFalse);
      final l10n = lookupAppLocalizations(const Locale('en'));
      expect(
        navalMissionHarborIntelSummaryLines(l10n, summary),
        ['No port'],
      );
    });
  });

  group('NavalMissionTargetDialog intel rows', () {
    testWidgets(
      'beachhead full intel shows unopposed and defender + stone fort labels',
      (tester) async {
        final game = buildIntelGame(
          visibilityByTile: {
            'oldWorld|p_empty|0|0': 'fullyVisible',
            'oldWorld|p_fort|0|0': 'fullyVisible',
          },
          units: [
            Unit(
              id: 'd1',
              type: 'musketeers',
              ownerId: rivalId,
              locationProvinceId: defended,
            ),
            Unit(
              id: 'd2',
              type: 'pikemen',
              ownerId: rivalId,
              locationProvinceId: defended,
            ),
          ],
        );
        final view = buildPlayerView(game, const MapTopology(), humanId);

        await tester.pumpWidget(
          buildAppShell(
            child: NavalMissionTargetDialog(
              game: game,
              mission: FleetMission.beachhead,
              fleet: fleet,
              targetProvinceIds: const [unopposed, defended],
              humanPlayerId: humanId,
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
        final game = buildIntelGame(
          visibilityByTile: {
            'oldWorld|p_port|0|0': 'fogged',
          },
          portsByProvinceSeaboard: const {
            'oldWorld|p_port|sea1': 'oldWorld|p_port|0|0',
          },
          fleets: [
            Fleet(
              id: 'enemy_a',
              ownerId: rivalId,
              regionId: 'oldWorld',
              inPortAtProvinceId: portProvince,
              ships: const [ShipInstance(id: 'ea', typeId: 'carrack')],
            ),
          ],
        );
        final view = buildPlayerView(game, const MapTopology(), humanId);

        await tester.pumpWidget(
          buildAppShell(
            child: NavalMissionTargetDialog(
              game: game,
              mission: FleetMission.blockade,
              fleet: fleet,
              targetProvinceIds: const [portProvince],
              humanPlayerId: humanId,
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
      final game = buildIntelGame(
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
            ownerId: rivalId,
            locationProvinceId: unopposed,
          ),
        ],
        fleets: [
          Fleet(
            id: 'enemy_a',
            ownerId: rivalId,
            regionId: 'oldWorld',
            inPortAtProvinceId: portProvince,
            ships: const [ShipInstance(id: 'ea', typeId: 'carrack')],
          ),
        ],
      );

      await tester.pumpWidget(
        buildAppShell(
          child: NavalMissionTargetDialog(
            game: game,
            mission: FleetMission.beachhead,
            fleet: fleet,
            targetProvinceIds: const [unopposed],
            humanPlayerId: humanId,
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
            fleet: fleet,
            targetProvinceIds: const [portProvince],
            humanPlayerId: humanId,
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Harbor status unknown'), findsOneWidget);
      expect(find.text('1 fleets in port'), findsNothing);
    });

    testWidgets('confirm still returns selected targetProvinceId', (tester) async {
      final game = buildIntelGame(
        visibilityByTile: {
          'oldWorld|p_empty|0|0': 'fullyVisible',
        },
      );
      final view = buildPlayerView(game, const MapTopology(), humanId);
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
                      fleet: fleet,
                      targetProvinceIds: const [unopposed],
                      humanPlayerId: humanId,
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
      expect(popped, unopposed);
    });
  });
}
