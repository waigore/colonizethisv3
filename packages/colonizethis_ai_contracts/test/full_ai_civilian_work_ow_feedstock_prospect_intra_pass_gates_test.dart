import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_ai_contracts/colonizethis_ai_contracts.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';

// Refs #2847 § H8-extraction Old World mineral feedstock prospect localization
// (intra-pass gate slice).
//
// `colocatedMineralEligibleUnprospectedOldWorldFeedstockProspectIntraPassGates`
// evaluates the three post-eligibility generation gates from
// `_addProspectSuggestionIfEligible` → `_allAcceptedProspectTilesInProvince`
// for co-located mineral-eligible feedstock tiles.

void main() {
  group(
    'colocatedMineralEligibleUnprospectedOldWorldFeedstockProspectIntraPassGates'
    ' (Refs #2847 H8-extraction prospect intra-pass gates)',
    () {
      const playerId = 'gp1';
      const ow = kRegionOldWorld;

      const feedstockProvinceId = 'oldWorld|s0';
      const feedstockIronTile = 'oldWorld|s0|0|0';
      const explorerId = 'e_feedstock';

      Game buildGame({bool tileVisible = true}) {
        final province = Province(
          id: feedstockProvinceId,
          regionId: ow,
          ownerId: playerId,
        );
        final otherProvince = Province(
          id: 'oldWorld|s1',
          regionId: ow,
          ownerId: playerId,
        );

        final visibility = <String, String>{
          if (tileVisible) feedstockIronTile: 'fogged',
        };

        final world = WorldState(
          turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 1),
          oldWorld: RegionData(
            provinces: [province, otherProvince],
            units: [
              Unit(
                id: explorerId,
                type: kUnitTypeExplorer,
                ownerId: playerId,
                locationProvinceId: feedstockProvinceId,
              ),
            ],
          ),
          newWorld: const RegionData(),
          playerVisibilityByTile: {playerId: visibility},
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

      ColocatedFeedstockProspectIntraPassGates evaluate(Game game) {
        final topology = topologyFor(game);
        final view = buildPlayerView(game, topology, playerId);
        return colocatedMineralEligibleUnprospectedOldWorldFeedstockProspectIntraPassGates(
          game: game,
          topology: topology,
          view: view,
          playerId: playerId,
          feedstockIds: {'iron'},
        );
      }

      test('all three gates pass on a visible co-located iron tile', () {
        final gates = evaluate(buildGame());
        expect(gates.provinceFoggedVisibility, isTrue);
        expect(gates.bundledMoveLeg, isTrue);
        expect(gates.validatorAccepted, isTrue);
      });

      test('provinceFoggedVisibility false when the iron tile is not visible',
          () {
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
        final gates = evaluate(game);
        expect(gates.provinceFoggedVisibility, isFalse);
      });

      test('bundledMoveLeg true when Explorer shares the feedstock province', () {
        final gates = evaluate(buildGame());
        expect(gates.bundledMoveLeg, isTrue);
      });

      test('validatorAccepted true when the suggestion pass emits prospect', () {
        final game = buildGame();
        final topology = topologyFor(game);
        final view = buildPlayerView(game, topology, playerId);
        expect(
          suggestsProspectForColocatedMineralEligibleUnprospectedOldWorldFeedstockTile(
            game,
            topology,
            view,
            playerId,
            {'iron'},
            null,
          ),
          isTrue,
        );
        expect(evaluate(game).validatorAccepted, isTrue);
      });

      test('all gates false for an empty feedstock set (negative control)', () {
        final game = buildGame();
        final topology = topologyFor(game);
        final view = buildPlayerView(game, topology, playerId);
        final gates =
            colocatedMineralEligibleUnprospectedOldWorldFeedstockProspectIntraPassGates(
              game: game,
              topology: topology,
              view: view,
              playerId: playerId,
              feedstockIds: const {},
            );
        expect(gates.provinceFoggedVisibility, isFalse);
        expect(gates.bundledMoveLeg, isFalse);
        expect(gates.validatorAccepted, isFalse);
      });

      test('deterministic across repeated evaluation', () {
        final game = buildGame();
        expect(evaluate(game), evaluate(game));
      });
    },
  );
}
