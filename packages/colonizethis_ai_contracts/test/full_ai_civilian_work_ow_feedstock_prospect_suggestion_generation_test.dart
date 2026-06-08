import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_ai_contracts/colonizethis_ai_contracts.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';

// Refs #2847 § H8-extraction Old World mineral feedstock prospect localization
// (suggestion-generation slice).
//
// `suggestsProspectForColocatedMineralEligibleUnprospectedOldWorldFeedstockTile`
// runs the **real** `suggestWorkOrders` pass and checks whether the co-located,
// mineral-eligible, unprospected Old World feedstock `iron` tile produces a
// `prospect` candidate. It refines the residual past the mineral-eligibility
// terrain gate: a co-located idle Explorer can sit on a mineral-eligible tile
// (the prior predicate is true) yet the pass still emit no `prospect` candidate
// when a downstream generation gate (province visibility / move-leg / validator
// material-cost or visibility precheck) rejects it. A `true` value instead
// proves the candidate is generated + validator-accepted, pinning the residual
// to selection ranking.

void main() {
  group(
    'suggestsProspectForColocatedMineralEligibleUnprospectedOldWorldFeedstockTile'
    ' (Refs #2847 H8-extraction prospect suggestion-generation gate)',
    () {
      const playerId = 'gp1';
      const ow = kRegionOldWorld;

      const feedstockProvinceId = 'oldWorld|s0';
      const feedstockIronTile = 'oldWorld|s0|0|0';
      const explorerId = 'e_feedstock';

      Game buildGame({
        bool tileVisible = true,
        bool alreadyProspected = false,
        CurrentWork? explorerWork,
        String explorerProvinceId = feedstockProvinceId,
      }) {
        final province = Province(
          id: feedstockProvinceId,
          regionId: ow,
          ownerId: playerId,
        );
        // A second, empty owned province gives a non-feedstock home for the
        // "different province" negative without changing the feedstock tile.
        final otherProvince = Province(
          id: 'oldWorld|s1',
          regionId: ow,
          ownerId: playerId,
        );

        final visibility = <String, String>{
          if (tileVisible) feedstockIronTile: 'fogged',
        };
        final prospected = <String>{
          if (alreadyProspected) feedstockIronTile,
        };

        final units = <Unit>[
          Unit(
            id: explorerId,
            type: kUnitTypeExplorer,
            ownerId: playerId,
            locationProvinceId: explorerProvinceId,
            currentWork: explorerWork,
          ),
        ];

        final world = WorldState(
          turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 1),
          oldWorld: RegionData(
            provinces: [province, otherProvince],
            units: units,
          ),
          newWorld: const RegionData(),
          playerVisibilityByTile: {playerId: visibility},
          playerProspectedTiles: {playerId: prospected},
          resourceByTileKey: const {feedstockIronTile: 'iron'},
          tileKeysByRegionAndProvince: {
            ow: const {
              feedstockProvinceId: [feedstockIronTile],
              'oldWorld|s1': <String>[],
            },
          },
        );
        return Game(
          id: 'g',
          worldState: world,
          players: const [
            Player(id: playerId, displayName: 'GP', isHuman: false),
          ],
        );
      }

      MapTopology topologyFor(Game game) {
        return MapTopology(
          nodes: [
            for (final p in game.worldState.oldWorld.provinces)
              TopologyNode(
                id: ProvinceId.localIdFrom(p.id),
                regionId: ow,
                type: TopologyNodeType.province,
              ),
          ],
          edges: const [],
        );
      }

      bool evaluate(Game game) {
        final topology = topologyFor(game);
        final view = buildPlayerView(game, topology, playerId);
        return suggestsProspectForColocatedMineralEligibleUnprospectedOldWorldFeedstockTile(
          game,
          topology,
          view,
          playerId,
          {'iron'},
          null,
        );
      }

      test('true when the suggestion pass emits the co-located iron prospect '
          '(generated + validator-accepted → residual is selection ranking)',
          () {
        final game = buildGame();
        expect(evaluate(game), isTrue);
      });

      test('false when the iron tile is not visible — the pass emits no '
          'prospect (residual inside generation, not selection ranking)', () {
        // Teeth: the mineral-eligibility predicate is still true (an idle
        // Explorer shares the unprospected, mineral-eligible iron province), so
        // the only discriminator is whether the live suggestion pass actually
        // produces the prospect candidate. With the tile not visible the
        // province visibility gate suppresses it.
        final game = buildGame(tileVisible: false);
        expect(
          ownsIdleExplorerColocatedWithMineralEligibleUnprospectedOldWorldFeedstockTile(
            game,
            playerId,
            {'iron'},
            null,
          ),
          isTrue,
        );
        expect(evaluate(game), isFalse);
      });

      test('false when the co-located Explorer is busy (currentWork set)', () {
        final game = buildGame(
          explorerWork: const CurrentWork(
            workTarget: kWorkTargetExplore,
            tileKey: 'newWorld|n0|0|0',
            totalTurns: 5,
            remainingTurns: 3,
          ),
        );
        expect(evaluate(game), isFalse);
      });

      test('false when the idle Explorer is in a different province', () {
        final game = buildGame(explorerProvinceId: 'oldWorld|s1');
        expect(evaluate(game), isFalse);
      });

      test('false when the iron tile is already prospected', () {
        final game = buildGame(alreadyProspected: true);
        expect(evaluate(game), isFalse);
      });

      test('false for an empty feedstock set (negative control)', () {
        final game = buildGame();
        final topology = topologyFor(game);
        final view = buildPlayerView(game, topology, playerId);
        expect(
          suggestsProspectForColocatedMineralEligibleUnprospectedOldWorldFeedstockTile(
            game,
            topology,
            view,
            playerId,
            const <String>{},
            null,
          ),
          isFalse,
        );
      });

      test('deterministic across repeated evaluation', () {
        final game = buildGame();
        expect(evaluate(game), evaluate(game));
        expect(evaluate(game), isTrue);
      });
    },
  );
}
