// Pins must-have #6 / SPEC `Colonial expansion (Full AI)` clause:
//   "Weight tuning only — no hard skip that removes all tribe declare-war
//    candidates for intervention risk."
// (`SPEC/ai/ai-architecture.md` § Colonial expansion).
//
// Counterpart AC text in `issue #2509`:
//   Given a fixed-seed Full AI state where a tribe is a valid declare-war
//   target, colonial-support weights are active, and intervention-risk
//   scoring would discourage war on a Great Power, when
//   `suggestDeclareWarOrders` runs, then the tribe target is **not**
//   unconditionally excluded by a hard skip guard (score may be low but
//   must remain in the candidate set; deterministic for fixed seed).
//
// Companion tests:
//   - `order_suggestion_declare_war_colonial_discovery_test.dart` (positive
//     tribe inclusion for sea-reachable NW without tile visibility).
//   - `war_desire_score_test.dart` (intervention-risk reduces minor/tribe
//     score; pure scoring level).

import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';

void main() {
  group('suggestDeclareWarOrders intervention-risk', () {
    test(
      'tribe stays in candidates when other GPs hold embassies on it',
      () {
        const api = DefaultOrderSuggestionAPI();
        const topology = MapTopology(
          nodes: [
            TopologyNode(
              id: 'oldWorld|home',
              regionId: 'oldWorld',
              type: TopologyNodeType.province,
            ),
            TopologyNode(
              id: 'oldWorld|owSea',
              regionId: 'oldWorld',
              type: TopologyNodeType.seaZone,
            ),
            TopologyNode(
              id: 'newWorld|nwSea',
              regionId: 'newWorld',
              type: TopologyNodeType.seaZone,
            ),
            TopologyNode(
              id: 'newWorld|colony',
              regionId: 'newWorld',
              type: TopologyNodeType.province,
            ),
          ],
          edges: [
            TopologyEdge(id1: 'oldWorld|home', id2: 'oldWorld|owSea'),
            TopologyEdge(id1: 'oldWorld|owSea', id2: 'newWorld|nwSea'),
            TopologyEdge(id1: 'newWorld|nwSea', id2: 'newWorld|colony'),
          ],
        );
        // Two other Great Powers (gp2, gp3) hold an `embassy` stage overture
        // toward `tribe1`. The war-desire intervention-risk penalty
        // (`packages/colonizethis_ai/lib/src/planning/war_desire_calculator.dart`)
        // would discourage war on `tribe1` for `gp1`, but the candidate
        // generator must still emit the declareWar suggestion.
        final game = Game(
          id: 'g-intervention-risk',
          worldState: WorldState(
            turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 1),
            oldWorld: const RegionData(
              provinces: [
                Province(
                  id: 'oldWorld|home',
                  regionId: 'oldWorld',
                  ownerId: 'gp1',
                ),
              ],
            ),
            newWorld: const RegionData(
              provinces: [
                Province(
                  id: 'newWorld|colony',
                  regionId: 'newWorld',
                  ownerId: 'tribe1',
                ),
              ],
            ),
            playerVisibilityByTile: const {
              'gp1': {'oldWorld|home|0|0': 'fullyVisible'},
            },
            tileKeysByRegionAndProvince: {
              'oldWorld': {
                'oldWorld|home': ['oldWorld|home|0|0'],
              },
              'newWorld': {
                'newWorld|colony': ['newWorld|colony|0|0'],
              },
            },
          ),
          players: const [
            Player(id: 'gp1', displayName: 'GP1', isHuman: false),
            Player(id: 'gp2', displayName: 'GP2', isHuman: false),
            Player(id: 'gp3', displayName: 'GP3', isHuman: false),
          ],
          tribes: const [Tribe(id: 'tribe1', displayName: 'T1')],
          overtureStates: const [
            OvertureState(
              gpId: 'gp2',
              targetId: 'tribe1',
              stage: OvertureStage.embassy,
            ),
            OvertureState(
              gpId: 'gp3',
              targetId: 'tribe1',
              stage: OvertureStage.embassy,
            ),
          ],
        );
        final view = buildPlayerView(game, topology, 'gp1');
        // Sanity: `tribe1` is in the known-target set for `gp1`. Sets the
        // precondition without which candidate emission would be moot.
        expect(
          knownDiplomaticTargetFactionIds(
            view: view,
            game: game,
            topology: topology,
          ),
          contains('tribe1'),
        );

        final declareOnly = api.suggestDeclareWarOrders(
          view,
          game,
          topology,
          const Orders(),
        );
        expect(
          declareOnly.any(
            (o) =>
                o.targetFactionId == 'tribe1' &&
                o.type == DiplomaticOrderType.declareWar,
          ),
          isTrue,
          reason:
              'tribe declare-war candidate must remain in the set even when '
              'intervention risk (GP embassies on the tribe) would discourage '
              'the war via war-desire scoring',
        );
      },
    );

    test(
      'tribe candidate is deterministic across repeated suggestDeclareWarOrders calls',
      () {
        const api = DefaultOrderSuggestionAPI();
        const topology = MapTopology(
          nodes: [
            TopologyNode(
              id: 'oldWorld|home',
              regionId: 'oldWorld',
              type: TopologyNodeType.province,
            ),
            TopologyNode(
              id: 'oldWorld|owSea',
              regionId: 'oldWorld',
              type: TopologyNodeType.seaZone,
            ),
            TopologyNode(
              id: 'newWorld|nwSea',
              regionId: 'newWorld',
              type: TopologyNodeType.seaZone,
            ),
            TopologyNode(
              id: 'newWorld|colony',
              regionId: 'newWorld',
              type: TopologyNodeType.province,
            ),
          ],
          edges: [
            TopologyEdge(id1: 'oldWorld|home', id2: 'oldWorld|owSea'),
            TopologyEdge(id1: 'oldWorld|owSea', id2: 'newWorld|nwSea'),
            TopologyEdge(id1: 'newWorld|nwSea', id2: 'newWorld|colony'),
          ],
        );
        final game = Game(
          id: 'g-intervention-risk-deterministic',
          worldState: WorldState(
            turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 1),
            oldWorld: const RegionData(
              provinces: [
                Province(
                  id: 'oldWorld|home',
                  regionId: 'oldWorld',
                  ownerId: 'gp1',
                ),
              ],
            ),
            newWorld: const RegionData(
              provinces: [
                Province(
                  id: 'newWorld|colony',
                  regionId: 'newWorld',
                  ownerId: 'tribe1',
                ),
              ],
            ),
            playerVisibilityByTile: const {
              'gp1': {'oldWorld|home|0|0': 'fullyVisible'},
            },
            tileKeysByRegionAndProvince: {
              'oldWorld': {
                'oldWorld|home': ['oldWorld|home|0|0'],
              },
              'newWorld': {
                'newWorld|colony': ['newWorld|colony|0|0'],
              },
            },
          ),
          players: const [
            Player(id: 'gp1', displayName: 'GP1', isHuman: false),
            Player(id: 'gp2', displayName: 'GP2', isHuman: false),
            Player(id: 'gp3', displayName: 'GP3', isHuman: false),
          ],
          tribes: const [Tribe(id: 'tribe1', displayName: 'T1')],
          overtureStates: const [
            OvertureState(
              gpId: 'gp2',
              targetId: 'tribe1',
              stage: OvertureStage.embassy,
            ),
            OvertureState(
              gpId: 'gp3',
              targetId: 'tribe1',
              stage: OvertureStage.embassy,
            ),
          ],
        );
        final view = buildPlayerView(game, topology, 'gp1');
        final first = api.suggestDeclareWarOrders(
          view,
          game,
          topology,
          const Orders(),
        );
        final second = api.suggestDeclareWarOrders(
          view,
          game,
          topology,
          const Orders(),
        );
        final firstTargetIds =
            first.map((o) => '${o.type.name}:${o.targetFactionId}').toList();
        final secondTargetIds =
            second.map((o) => '${o.type.name}:${o.targetFactionId}').toList();
        expect(secondTargetIds, equals(firstTargetIds));
        expect(
          firstTargetIds,
          contains('declareWar:tribe1'),
          reason:
              'deterministic candidate set must include the tribe target '
              'despite high intervention risk; pins the AC determinism clause',
        );
      },
    );
  });
}
