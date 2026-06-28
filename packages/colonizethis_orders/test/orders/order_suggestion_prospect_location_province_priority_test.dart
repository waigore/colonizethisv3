import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';

// Refs #2847: prospect province sweep is capped at kMaxExploreProvinceProbesPerUnit
// (4). On seed-scale maps the co-located feedstock province sorts after many
// world provinces and was never probed despite a co-located idle Explorer.
void main() {
  group(
    'suggestWorkOrders prospect probes explorer location province first '
    '(Refs #2847 H8-extraction)',
    () {
      const playerId = 'gp1';
      const ow = kRegionOldWorld;
      const ironProvinceId = 'oldWorld|z_feedstock';
      const ironTileKey = 'oldWorld|z_feedstock|2|0';

      Game gameWithFillerProvinces() {
        final fillerProvinces = <Province>[
          for (var i = 0; i < 6; i++)
            Province(
              id: 'oldWorld|aaa$i',
              regionId: ow,
              ownerId: 'minor1',
            ),
        ];
        final ironProvince = Province(
          id: ironProvinceId,
          regionId: ow,
          ownerId: playerId,
        );
        final unit = Unit(
          id: 'e1',
          type: kUnitTypeExplorer,
          ownerId: playerId,
          locationProvinceId: ironProvinceId,
        );
        final tileKeysByRegion = <String, Map<String, List<String>>>{
          ow: {
            for (final p in fillerProvinces) p.id: <String>[],
            ironProvinceId: [ironTileKey],
          },
        };
        final world = WorldState(
          turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 1),
          oldWorld: RegionData(
            provinces: [...fillerProvinces, ironProvince],
            units: [unit],
          ),
          newWorld: const RegionData(),
          playerVisibilityByTile: const {
            playerId: {ironTileKey: 'fogged'},
          },
          resourceByTileKey: const {ironTileKey: 'iron'},
          tileKeysByRegionAndProvince: tileKeysByRegion,
        );
        return Game(
          id: 'g',
          worldState: world,
          players: const [
            Player(id: playerId, displayName: 'GP', isHuman: false),
          ],
          minorNations: const [MinorNation(id: 'minor1', displayName: 'M1')],
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

      test(
        'co-located Explorer in late-sorted province still receives a '
        'prospect suggestion for its iron tile',
        () {
          final game = gameWithFillerProvinces();
          final topology = topologyFor(game);
          final view = buildPlayerView(game, topology, playerId);
          final suggestions = suggestWorkOrders(
            view,
            game,
            topology,
            const Orders(),
          );
          final prospects = suggestions
              .where((o) => o.unitId == 'e1' && o.target == kWorkTargetProspect)
              .toList();
          expect(prospects, isNotEmpty);
          expect(
            prospects.map((o) => o.targetTileKey),
            contains(ironTileKey),
          );
        },
      );

      test(
        'iron province without fogged visibility still yields no prospect '
        '(negative control)',
        () {
          final game = gameWithFillerProvinces();
          final topology = topologyFor(game);
          final hiddenGame = Game(
            id: game.id,
            worldState: WorldState(
              turnState: game.worldState.turnState,
              oldWorld: game.worldState.oldWorld,
              newWorld: game.worldState.newWorld,
              resourceByTileKey: game.worldState.resourceByTileKey,
              tileKeysByRegionAndProvince:
                  game.worldState.tileKeysByRegionAndProvince,
              playerVisibilityByTile: const {},
            ),
            players: game.players,
            minorNations: game.minorNations,
          );
          final view = buildPlayerView(hiddenGame, topology, playerId);
          final suggestions = suggestWorkOrders(
            view,
            hiddenGame,
            topology,
            const Orders(),
          );
          expect(
            suggestions.where((o) => o.target == kWorkTargetProspect),
            isEmpty,
          );
        },
      );
    },
  );
}
