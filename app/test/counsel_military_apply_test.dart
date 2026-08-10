// Military Counsel Agree apply handlers. SPEC/ui/counsel-panel.md (Refs #4307).

import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_logic/military_counsel_api.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_orders/colonizethis_orders.dart'
    show ArmyMovePickerDestination;
import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter_test/flutter_test.dart';

import 'package:colonizethis_app/features/game/screens/counsel/counsel_military_apply.dart';
import 'panel_fixtures/train.dart';
import 'panel_test_fixtures.dart';

void main() {
  suppressLogsForTests();

  const playerId = kPanelTestHumanPlayerId;
  const unitType = 'peasant_levies';

  MapTopology trainPanelTopology() => const MapTopology(
    nodes: [
      TopologyNode(
        id: 'oldWorld|cap',
        regionId: 'oldWorld',
        type: TopologyNodeType.province,
      ),
      TopologyNode(
        id: 'oldWorld|p2',
        regionId: 'oldWorld',
        type: TopologyNodeType.province,
      ),
    ],
    edges: [TopologyEdge(id1: 'oldWorld|cap', id2: 'oldWorld|p2')],
  );

  group('militaryCounselOrdersAfterTrainAgree', () {
    test('returns null when unit type is not affordable', () {
      final game = buildPanelTestGame(
        players: [
          Player(
            id: playerId,
            displayName: 'Broke GP',
            isHuman: true,
            capitalProvinceId: 'oldWorld|cap',
            stockpile: const Stockpile(),
            workerPool: const WorkerPool(peasants: 0),
            treasury: 0,
          ),
        ],
        oldWorldProvinces: const [
          Province(
            id: 'oldWorld|cap',
            regionId: 'oldWorld',
            ownerId: playerId,
          ),
        ],
      );

      final result = militaryCounselOrdersAfterTrainAgree(
        game: game,
        playerId: playerId,
        currentOrders: const Orders(),
        topology: trainPanelTopology(),
        unitType: unitType,
        count: 1,
      );

      expect(result, isNull);
    });

    test('appends build orders when still affordable', () {
      final game = buildTrainPanelTestGame();
      final topology = trainPanelTopology();

      final result = militaryCounselOrdersAfterTrainAgree(
        game: game,
        playerId: playerId,
        currentOrders: const Orders(),
        topology: topology,
        unitType: unitType,
        count: 2,
      );

      expect(result, isNotNull);
      final builds = result!.buildUnitOrdersByPlayerId[playerId] ?? const [];
      expect(builds, hasLength(2));
      expect(builds.every((o) => o.unitType == unitType), isTrue);
      expect(builds.every((o) => o.isMilitary), isTrue);
    });
  });

  group('militaryCounselTrainStillAffordable', () {
    test('is false when greedy count is below requested count', () {
      final game = buildTrainPanelTestGame();

      final affordable = militaryCounselAffordableBuildCountForType(
        game: game,
        playerId: playerId,
        currentOrders: const Orders(),
        topology: trainPanelTopology(),
        unitType: unitType,
      );

      expect(
        militaryCounselTrainStillAffordable(
          game: game,
          playerId: playerId,
          currentOrders: const Orders(),
          topology: trainPanelTopology(),
          unitType: unitType,
          count: affordable + 1,
        ),
        isFalse,
      );
    });
  });

  group('militaryCounselInvadeDestinationForRecommendation', () {
    const from = 'oldWorld|p_from';
    const invasionDest = 'oldWorld|p_invade';
    const rivalId = 'gp2';
    const armyId = 'a_move';

    MapTopology invadeTopology() => const MapTopology(
      nodes: [
        TopologyNode(
          id: from,
          regionId: 'oldWorld',
          type: TopologyNodeType.province,
        ),
        TopologyNode(
          id: invasionDest,
          regionId: 'oldWorld',
          type: TopologyNodeType.province,
        ),
      ],
      edges: [TopologyEdge(id1: from, id2: invasionDest)],
    );

    Game invadeGame({bool homeArmy = false}) {
      return buildPanelTestGame(
        players: [
          Player(id: playerId, displayName: 'Human', isHuman: true),
          const Player(id: rivalId, displayName: 'Rival', isHuman: false),
        ],
        oldWorldProvinces: const [
          Province(
            id: from,
            regionId: 'oldWorld',
            ownerId: playerId,
            displayName: 'Origin',
          ),
          Province(
            id: invasionDest,
            regionId: 'oldWorld',
            ownerId: rivalId,
            displayName: 'Enemy Border',
          ),
        ],
        oldWorldUnits: [
          Unit(
            id: 'u1',
            type: 'musketeers',
            ownerId: playerId,
            locationProvinceId: from,
          ),
        ],
        armies: [
          Army(
            id: armyId,
            ownerId: playerId,
            regionId: 'oldWorld',
            stationedProvinceId: from,
            regimentUnitIds: const ['u1'],
            isHomeArmy: homeArmy,
          ),
        ],
        tileKeysByRegionAndProvince: const {
          'oldWorld': {
            from: ['oldWorld|p_from|0|0'],
            invasionDest: ['oldWorld|p_invade|0|0'],
          },
        },
        playerVisibilityByTile: const {
          playerId: {
            'oldWorld|p_from|0|0': 'fullyVisible',
            'oldWorld|p_invade|0|0': 'fullyVisible',
          },
        },
      );
    }

    MilitaryCounselRecommendation invadeRec() {
      return MilitaryCounselRecommendation(
        recommendationId: 'invade:$armyId:$invasionDest',
        kind: MilitaryCounselRecommendationKind.invade,
        rankScore: 5,
        briefReasonKey: MilitaryCounselReasonKey.declareWarInvasion,
        detailReasonKeys: const [MilitaryCounselReasonKey.declareWarInvasion],
        armyId: armyId,
        destinationProvinceId: invasionDest,
        destinationProvinceLabel: 'Enemy Border',
        ownerFactionId: rivalId,
        requiresDeclareWar: true,
        invasionIntel: const MilitaryCounselInvasionIntelSummary(
          intelLevel: MilitaryCounselInvasionIntelLevel.unknown,
        ),
      );
    }

    test('returns null for Home Army recommendation', () {
      final destination = militaryCounselInvadeDestinationForRecommendation(
        game: invadeGame(homeArmy: true),
        playerId: playerId,
        currentOrders: const Orders(),
        topology: invadeTopology(),
        recommendation: invadeRec(),
      );

      expect(destination, isNull);
    });

    test('resolves invasion destination for field army', () {
      final destination = militaryCounselInvadeDestinationForRecommendation(
        game: invadeGame(),
        playerId: playerId,
        currentOrders: const Orders(),
        topology: invadeTopology(),
        recommendation: invadeRec(),
      );

      expect(destination, isNotNull);
      expect(destination!.fullProvinceId, invasionDest);
      expect(destination.requiresDeclareWarOnConfirm, isTrue);
    });
  });

  group('militaryCounselOrdersAfterInvadeAgree', () {
    const armyId = 'a_move';
    const invasionDest = 'oldWorld|p_invade';
    const rivalId = 'gp2';

    ArmyMovePickerDestination invasionDestination({
      bool requiresWar = true,
    }) {
      return ArmyMovePickerDestination(
        fullProvinceId: invasionDest,
        provinceLabel: 'Enemy Border',
        regionId: 'oldWorld',
        ownerFactionId: rivalId,
        isPlayerOwned: false,
        requiresDeclareWarOnConfirm: requiresWar,
      );
    }

    test('stages army move only when war not required', () {
      final next = militaryCounselOrdersAfterInvadeAgree(
        currentOrders: const Orders(),
        playerId: playerId,
        armyId: armyId,
        destination: invasionDestination(requiresWar: false),
      );

      final moves = next.armyMoveOrdersByPlayerId[playerId] ?? const [];
      expect(moves, hasLength(1));
      expect(moves.single.armyId, armyId);
      expect(moves.single.destinationProvinceId, invasionDest);
      expect(next.diplomaticOrdersByPlayerId[playerId], isNull);
    });

    test('stages declare war and army move when war required', () {
      final next = militaryCounselOrdersAfterInvadeAgree(
        currentOrders: const Orders(),
        playerId: playerId,
        armyId: armyId,
        destination: invasionDestination(),
      );

      final diplo = next.diplomaticOrdersByPlayerId[playerId] ?? const [];
      expect(diplo, hasLength(1));
      expect(diplo.single.type, DiplomaticOrderType.declareWar);
      expect(diplo.single.targetFactionId, rivalId);

      final moves = next.armyMoveOrdersByPlayerId[playerId] ?? const [];
      expect(moves, hasLength(1));
      expect(moves.single.destinationProvinceId, invasionDest);
    });
  });
}
