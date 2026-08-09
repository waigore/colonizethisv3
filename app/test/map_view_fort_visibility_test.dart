import 'package:colonizethis_app/features/game/flame/map_state/map_view_fort_visibility.dart';
import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart' show buildPlayerView;
import 'package:colonizethis_map/colonizethis_map.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';
import 'package:colonizethis_world/colonizethis_world.dart';

void main() {
  group('resolveMapVisibleFortLevel', () {
    const humanId = 'gp1';
    const foreignId = 'gp2';
    const provinceId = 'oldWorld|p1';
    const tileKey = 'oldWorld|p1|0|0';

    Game gameWithFort({required String ownerId, int fortLevel = 2}) {
      return Game(
        id: 'g',
        worldState: WorldState(
          turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 1),
          oldWorld: RegionData(
            provinces: [
              Province(
                id: provinceId,
                regionId: 'oldWorld',
                ownerId: ownerId,
                fortLevel: fortLevel,
                townTileKey: tileKey,
              ),
            ],
          ),
          newWorld: const RegionData(),
          tileKeysByRegionAndProvince: {
            'oldWorld': {
              provinceId: [tileKey],
            },
          },
        ),
        players: [
          Player(id: humanId, displayName: 'Human', isHuman: true),
          Player(id: foreignId, displayName: 'Foreign', isHuman: false),
        ],
      );
    }

    test('returns null for open field', () {
      final game = gameWithFort(ownerId: humanId, fortLevel: 0);
      final view = buildPlayerView(game, const MapTopology(nodes: [], edges: []), humanId);
      expect(
        resolveMapVisibleFortLevel(
          game: game,
          view: view,
          humanPlayerId: humanId,
          prefixedProvinceId: provinceId,
          worldFortLevel: 0,
          revealAllForts: false,
        ),
        isNull,
      );
    });

    test('own province shows true fort level', () {
      final game = gameWithFort(ownerId: humanId, fortLevel: 2);
      final view = buildPlayerView(game, const MapTopology(nodes: [], edges: []), humanId);
      expect(
        resolveMapVisibleFortLevel(
          game: game,
          view: view,
          humanPlayerId: humanId,
          prefixedProvinceId: provinceId,
          worldFortLevel: 2,
          revealAllForts: false,
        ),
        2,
      );
    });

    test('foreign province without intel hides fort', () {
      final game = gameWithFort(ownerId: foreignId, fortLevel: 2);
      final view = buildPlayerView(game, const MapTopology(nodes: [], edges: []), humanId);
      expect(
        resolveMapVisibleFortLevel(
          game: game,
          view: view,
          humanPlayerId: humanId,
          prefixedProvinceId: provinceId,
          worldFortLevel: 2,
          revealAllForts: false,
        ),
        isNull,
      );
    });

    test('revealAllForts shows foreign fort', () {
      final game = gameWithFort(ownerId: foreignId, fortLevel: 1);
      final view = buildPlayerView(game, const MapTopology(nodes: [], edges: []), humanId);
      expect(
        resolveMapVisibleFortLevel(
          game: game,
          view: view,
          humanPlayerId: humanId,
          prefixedProvinceId: provinceId,
          worldFortLevel: 1,
          revealAllForts: true,
        ),
        1,
      );
    });
  });
}
