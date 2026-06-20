import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_logger/colonizethis_logger.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';
import 'package:logger/logger.dart';

import 'package:run_observer_game/observer_snapshot_v1.dart';

/// Refs #2509: Observer snapshots are written **post-resolution**. When a
/// Join Empire order absorbs a Tribe owning a `newWorld|` province in
/// [validateOrdersAndResolveTurnFromTrustedOrders], the post-resolution
/// snapshot must list that province under the absorbing Great Power.
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
      'snapshot.provinceOwnershipSorted lists absorbed NW province under '
      'absorbing GP when treasury covers Join Empire cost',
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
          isFalse,
          reason: 'Tribe must be removed from game after Join Empire absorbs it',
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
        expect(nwRow['ownerId'], 'gp1');

        final tribeOwned = rows
            .cast<Map<String, Object?>>()
            .where((r) => r['ownerId'] == 'tribe1')
            .toList();
        expect(
          tribeOwned,
          isEmpty,
          reason: 'No province should still be owned by the absorbed tribe',
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
          reason: 'Tribe must remain when absorption rejected',
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
