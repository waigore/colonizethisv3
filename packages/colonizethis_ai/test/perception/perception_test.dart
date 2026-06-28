import 'package:colonizethis_test/test.dart';
import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_ai/colonizethis_ai.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

void main() {
  group('AIWorldSnapshot.fromPlayerView', () {
    PlayerView _view({
      required String playerId,
      Map<String, DiplomacyRelation> diplomacyByOtherId = const {},
      Map<String, Province> provincesById = const {},
      int workerCount = 0,
      int treasury = 0,
    }) {
      final player = Player(
        id: playerId,
        displayName: 'P',
        isHuman: false,
        workerPool: WorkerPool(peasants: workerCount),
        treasury: treasury,
      );
      return PlayerView(
        playerId: playerId,
        player: player,
        ownUnitsById: const {},
        provincesById: provincesById,
        visibilityByTile: const {},
        prospectedTiles: const {},
        diplomacyByOtherId: diplomacyByOtherId,
      );
    }

    test('threats include atWarWith from diplomacy', () {
      final view = _view(
        playerId: 'gp1',
        diplomacyByOtherId: {
          'gp2': DiplomacyRelation(
            factionId1: 'gp1',
            factionId2: 'gp2',
            state: RelationState.atWar,
          ),
          'gp3': DiplomacyRelation(
            factionId1: 'gp1',
            factionId2: 'gp3',
            state: RelationState.atPeace,
          ),
        },
      );
      final snap = AIWorldSnapshot.fromPlayerView(view);
      expect(snap.threats.atWarWith, ['gp2']);
    });

    test('opportunities count unclaimed provinces', () {
      const r = 'oldWorld';
      final view = _view(
        playerId: 'gp1',
        provincesById: {
          '$r|p1': const Province(id: 'p1', regionId: r, displayName: 'P1', ownerId: null),
          '$r|p2': const Province(id: 'p2', regionId: r, displayName: 'P2', ownerId: ''),
          '$r|p3': const Province(id: 'p3', regionId: r, displayName: 'P3', ownerId: 'gp1'),
        },
      );
      final snap = AIWorldSnapshot.fromPlayerView(view);
      expect(snap.opportunities.unclaimedProvinces, 2);
    });

    test('economy summarizes worker count treasury own provinces', () {
      const r = 'oldWorld';
      final view = _view(
        playerId: 'gp1',
        workerCount: 5,
        treasury: 100,
        provincesById: {
          '$r|p1': const Province(id: 'p1', regionId: r, displayName: 'P1', ownerId: 'gp1'),
          '$r|p2': const Province(id: 'p2', regionId: r, displayName: 'P2', ownerId: 'gp2'),
        },
      );
      final snap = AIWorldSnapshot.fromPlayerView(view);
      expect(snap.economy.workerCount, 5);
      expect(snap.economy.treasury, 100);
      expect(snap.economy.ownProvinceCount, 1);
    });

    test('relations copied from view', () {
      final view = _view(
        playerId: 'gp1',
        diplomacyByOtherId: {
          'gp2': DiplomacyRelation(factionId1: 'gp1', factionId2: 'gp2'),
        },
      );
      final snap = AIWorldSnapshot.fromPlayerView(view);
      expect(snap.relations.length, 1);
      expect(snap.relations['gp2'], isNotNull);
    });

    test('with topology: neighborProvincesHostile and capitalThreatened when neighbor at war', () {
      const r = 'oldWorld';
      final view = _view(
        playerId: 'gp1',
        diplomacyByOtherId: {
          'gp2': DiplomacyRelation(
            factionId1: 'gp1',
            factionId2: 'gp2',
            state: RelationState.atWar,
          ),
        },
        provincesById: {
          '$r|p1': Province(id: 'p1', regionId: r, ownerId: 'gp1', displayName: 'P1'),
          '$r|p2': Province(id: 'p2', regionId: r, ownerId: 'gp2', displayName: 'P2'),
        },
      );
      final playerWithCapital = view.player.copyWith(capitalProvinceId: '$r|p1');
      final viewWithCapital = PlayerView(
        playerId: view.playerId,
        player: playerWithCapital,
        ownUnitsById: view.ownUnitsById,
        provincesById: view.provincesById,
        visibilityByTile: view.visibilityByTile,
        prospectedTiles: view.prospectedTiles,
        diplomacyByOtherId: view.diplomacyByOtherId,
      );
      const topology = MapTopology(
        nodes: [
          TopologyNode(id: 'p1', regionId: r, type: TopologyNodeType.province),
          TopologyNode(id: 'p2', regionId: r, type: TopologyNodeType.province),
        ],
        edges: [TopologyEdge(id1: 'p1', id2: 'p2')],
      );
      final snap = AIWorldSnapshot.fromPlayerView(viewWithCapital, topology: topology);
      expect(snap.threats.neighborProvincesHostile, 1);
      expect(snap.threats.capitalThreatened, true);
    });

    test('with topology: weakNeighbors lists faction ids owning adjacent provinces', () {
      const r = 'oldWorld';
      final view = _view(
        playerId: 'gp1',
        provincesById: {
          '$r|p1': Province(id: 'p1', regionId: r, ownerId: 'gp1', displayName: 'P1'),
          '$r|p2': Province(id: 'p2', regionId: r, ownerId: 'gp2', displayName: 'P2'),
          '$r|p3': Province(id: 'p3', regionId: r, ownerId: null, displayName: 'P3'),
        },
      );
      const topology = MapTopology(
        nodes: [
          TopologyNode(id: 'p1', regionId: r, type: TopologyNodeType.province),
          TopologyNode(id: 'p2', regionId: r, type: TopologyNodeType.province),
          TopologyNode(id: 'p3', regionId: r, type: TopologyNodeType.province),
        ],
        edges: [
          TopologyEdge(id1: 'p1', id2: 'p2'),
          TopologyEdge(id1: 'p1', id2: 'p3'),
        ],
      );
      final snap = AIWorldSnapshot.fromPlayerView(view, topology: topology);
      expect(snap.opportunities.weakNeighbors, contains('gp2'));
      expect(snap.opportunities.weakNeighbors.length, 1);
    });

    test(
      'with prefixed combined topology: invadable and adjacent owners resolve',
      () {
        const r = 'oldWorld';
        final view = _view(
          playerId: 'gp1',
          provincesById: {
            '$r|p1': Province(id: 'p1', regionId: r, ownerId: 'gp1', displayName: 'P1'),
            '$r|p2': Province(id: 'p2', regionId: r, ownerId: 'gp2', displayName: 'P2'),
            '$r|p3': Province(id: 'p3', regionId: r, ownerId: 'minor1', displayName: 'M1'),
          },
        );
        final topology = MapTopology(
          nodes: [
            TopologyNode(
              id: '$r|p1',
              regionId: r,
              type: TopologyNodeType.province,
            ),
            TopologyNode(
              id: '$r|p2',
              regionId: r,
              type: TopologyNodeType.province,
            ),
            TopologyNode(
              id: '$r|p3',
              regionId: r,
              type: TopologyNodeType.province,
            ),
          ],
          edges: [
            TopologyEdge(id1: '$r|p1', id2: '$r|p2'),
            TopologyEdge(id1: '$r|p1', id2: '$r|p3'),
          ],
        );
        final snap = AIWorldSnapshot.fromPlayerView(view, topology: topology);
        expect(snap.conquest.invadableProvinceIdsSorted, contains('$r|p2'));
        expect(snap.conquest.invadableProvinceIdsSorted, contains('$r|p3'));
        expect(
          snap.conquest.adjacentOwnerFactionIdsSorted,
          containsAll(['gp2', 'minor1']),
        );
      },
    );

    test('richUnexploitedProvinces counts unclaimed and others with development', () {
      const r = 'oldWorld';
      final view = _view(
        playerId: 'gp1',
        provincesById: {
          '$r|p1': Province(id: 'p1', regionId: r, ownerId: 'gp1', displayName: 'P1'),
          '$r|p2': Province(id: 'p2', regionId: r, ownerId: 'gp2', displayName: 'P2', townDevelopmentLevel: 2),
          '$r|p3': Province(id: 'p3', regionId: r, ownerId: null, displayName: 'P3'),
        },
      );
      final snap = AIWorldSnapshot.fromPlayerView(view);
      expect(snap.opportunities.unclaimedProvinces, 1);
      expect(snap.opportunities.richUnexploitedProvinces, 2); // unclaimed p3 + gp2's p2 with development
    });
  });
}
