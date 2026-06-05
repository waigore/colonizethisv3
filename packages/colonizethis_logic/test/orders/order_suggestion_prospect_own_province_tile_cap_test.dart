import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';

// Refs #2847: own-province prospect probes are exempt from the shared per-pass
// budget, but `_allAcceptedProspectTilesInProvince` still capped at
// `kMaxWorkProbeAttemptsPerUnitPerTarget` (4). When a co-located feedstock `iron`
// tile sorts after four other accepted mineral tiles in the same province, the
// full pass never emits a prospect for the feedstock tile even though the tile
// passes validator acceptance in isolation.
void main() {
  group(
    'suggestWorkOrders own-province prospect reaches feedstock tile past '
    'per-target probe cap (Refs #2847)',
    () {
      const playerId = 'gp1';
      const ow = kRegionOldWorld;
      const provinceId = 'oldWorld|home';
      const feedstockTileKey = 'oldWorld|home|9|0';

      Game buildGame() {
        // Five mineral tiles in the same province; feedstock iron sorts last.
        final mineralTiles = <String>[
          'oldWorld|home|0|0',
          'oldWorld|home|1|0',
          'oldWorld|home|2|0',
          'oldWorld|home|3|0',
          feedstockTileKey,
        ];
        final resourceByTile = <String, String>{
          for (final tk in mineralTiles) tk: 'iron',
        };
        final unit = Unit(
          id: 'e1',
          type: kUnitTypeExplorer,
          ownerId: playerId,
          locationProvinceId: provinceId,
        );
        final world = WorldState(
          turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 1),
          oldWorld: RegionData(
            provinces: [
              Province(id: provinceId, regionId: ow, ownerId: playerId),
            ],
            units: [unit],
          ),
          newWorld: const RegionData(),
          playerVisibilityByTile: {
            playerId: {for (final tk in mineralTiles) tk: 'fogged'},
          },
          resourceByTileKey: resourceByTile,
          tileKeysByRegionAndProvince: {
            ow: {provinceId: mineralTiles},
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

      test(
        'co-located Explorer still prospects feedstock iron when it sorts after '
        'four other accepted mineral tiles in the same province',
        () {
          final game = buildGame();
          final topology = topologyFor(game);
          final view = buildPlayerView(game, topology, playerId);
          final suggestions = suggestWorkOrders(
            view,
            game,
            topology,
            const Orders(),
          );
          final feedstockProspects = suggestions
              .where(
                (o) =>
                    o.unitId == 'e1' &&
                    o.target == kWorkTargetProspect &&
                    o.targetTileKey == feedstockTileKey,
              )
              .toList();
          expect(feedstockProspects, isNotEmpty);
        },
      );
    },
  );
}
