import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_logger/colonizethis_logger.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';
import 'package:logger/logger.dart';

import 'package:run_observer_game/observer_snapshot_v1.dart';

/// Refs #2509 / #3753 (R5): Observer snapshots are written **post-resolution**.
/// A Tribe `Join Empire` overture now routes to a **colony** outcome instead of
/// absorption: the Tribe remains in the game, its `newWorld|` province is **not**
/// transferred to the Great Power, and a [ColonyState] is recorded. The
/// post-resolution snapshot must therefore still list that province under the
/// colony Tribe (not the suzerain Great Power).
void main() {
  setUpAll(() {
    CtLogger.level = Level.off;
  });

  group('observer snapshot Join Empire post-resolution timing', () {
    MapTopology buildTopology() {
      return MapTopology(
        nodes: const [
          TopologyNode(
            id: 'capital',
            regionId: 'oldWorld',
            type: TopologyNodeType.province,
          ),
          TopologyNode(
            id: 'nw1',
            regionId: 'newWorld',
            type: TopologyNodeType.province,
          ),
        ],
        edges: const [],
      );
    }

    Game buildPreResolutionGame({required int treasury}) {
      const ow = 'oldWorld';
      const nw = 'newWorld';
      return Game(
        id: 'g-join-empire-nw',
        worldState: WorldState(
          turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 1),
          oldWorld: const RegionData(
            provinces: [
              Province(id: '$ow|capital', regionId: ow, ownerId: 'gp1'),
            ],
          ),
          newWorld: const RegionData(
            provinces: [
              Province(id: '$nw|nw1', regionId: nw, ownerId: 'tribe1'),
            ],
          ),
        ),
        players: [
          const Player(
            id: 'gp1',
            displayName: 'GP1',
            isHuman: true,
            treasury: 0,
          ).copyWith(treasury: treasury),
        ],
        tribes: const [Tribe(id: 'tribe1', displayName: 'Tribe 1')],
        minorNations: const [],
        overtureStates: const [
          OvertureState(
            gpId: 'gp1',
            targetId: 'tribe1',
            stage: OvertureStage.nap,
            sinceTurn: 0,
          ),
        ],
        diplomacyRelations: const [
          DiplomacyRelation(
            factionId1: 'gp1',
            factionId2: 'tribe1',
            score: relationScoreMinFriendly + 10,
            level: RelationLevel.friendly,
          ),
        ],
      );
    }

    Orders buildJoinEmpireOrders() => Orders(
          diplomaticOrdersByPlayerId: {
            'gp1': const [
              DiplomaticOrder(
                type: DiplomaticOrderType.establishOverture,
                targetFactionId: 'tribe1',
                overtureStage: OvertureStage.joinEmpire,
              ),
            ],
          },
        );

    test(
      'snapshot.provinceOwnershipSorted keeps NW province under the colony '
      'Tribe (no transfer) when treasury covers Join Empire cost',
      () {
        final topology = buildTopology();
        // Cost = base 5000 + 1 province * 2000 = 7000; supply 15000 to cover.
        final game = buildPreResolutionGame(treasury: 15000);

        final result = validateOrdersAndResolveTurnFromTrustedOrders(
          game: game,
          topology: topology,
          orders: buildJoinEmpireOrders(),
        );
        final after = requireTurnResolutionComplete(result);

        expect(
          after.tribes.any((t) => t.id == 'tribe1'),
          isTrue,
          reason: 'Tribe must remain in the game as a colony (R5, no absorption)',
        );
        expect(
          after.colonyStates.any(
            (c) => c.tribeId == 'tribe1' && c.colonyOfGpId == 'gp1',
          ),
          isTrue,
          reason: 'A ColonyState must record the Tribe as a colony of the GP',
        );
        expect(
          after.players.firstWhere((p) => p.id == 'gp1').treasury,
          15000 - 7000,
          reason: 'Join Empire cost must still be deducted from GP treasury',
        );

        final snapshot = buildObserverSnapshotJson(
          after,
          postResolutionTurnNumber: after.worldState.turnState.turnNumber,
        );
        final rows =
            snapshot['provinceOwnershipSorted'] as List<Object?>;
        final nwRow = rows
            .cast<Map<String, Object?>>()
            .firstWhere((r) => r['id'] == 'newWorld|nw1');
        expect(
          nwRow['ownerId'],
          'tribe1',
          reason: 'Colony Tribe keeps its NW province; ownership is not '
              'transferred to the suzerain GP (R5)',
        );

        final gpOwnedNw = rows
            .cast<Map<String, Object?>>()
            .where((r) => r['ownerId'] == 'gp1' && r['id'] == 'newWorld|nw1')
            .toList();
        expect(
          gpOwnedNw,
          isEmpty,
          reason: 'GP must not own the colony Tribe NW province after Join Empire',
        );
      },
    );

    test(
      'snapshot retains NW province under tribe when Join Empire is rejected '
      'for insufficient treasury (negative case)',
      () {
        final topology = buildTopology();
        // Cost = 5000 + 2000 = 7000; treasury below cost rejects absorption.
        final game = buildPreResolutionGame(treasury: 100);

        final result = validateOrdersAndResolveTurnFromTrustedOrders(
          game: game,
          topology: topology,
          orders: buildJoinEmpireOrders(),
        );
        final after = requireTurnResolutionComplete(result);

        expect(
          after.tribes.any((t) => t.id == 'tribe1'),
          isTrue,
          reason: 'Tribe must remain when Join Empire is rejected',
        );
        expect(
          after.colonyStates.any((c) => c.tribeId == 'tribe1'),
          isFalse,
          reason: 'No ColonyState is recorded when Join Empire is rejected',
        );
        expect(
          after.players.firstWhere((p) => p.id == 'gp1').treasury,
          100,
          reason: 'Treasury is unchanged when Join Empire is rejected',
        );

        final snapshot = buildObserverSnapshotJson(
          after,
          postResolutionTurnNumber: after.worldState.turnState.turnNumber,
        );
        final rows =
            snapshot['provinceOwnershipSorted'] as List<Object?>;
        final nwRow = rows
            .cast<Map<String, Object?>>()
            .firstWhere((r) => r['id'] == 'newWorld|nw1');
        expect(nwRow['ownerId'], 'tribe1');
      },
    );
  });
}
