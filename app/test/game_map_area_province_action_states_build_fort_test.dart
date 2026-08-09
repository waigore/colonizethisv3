import 'package:colonizethis_app/features/game/flame/map_state/game_map_area_province_action_states_build_fort.dart';
import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';

void main() {
  group('GameMapAreaProvinceActionStatesBuildFort', () {
    test('tileCanConceivablyTakeBuildFortStep rejects max level', () {
      expect(
        GameMapAreaProvinceActionStatesBuildFort.tileCanConceivablyTakeBuildFortStep(
          fortLevel: 3,
          techUnlocked: const {},
        ),
        isFalse,
      );
    });

    test('tileCanConceivablyTakeBuildFortStep requires Mine Engineering for L2', () {
      expect(
        GameMapAreaProvinceActionStatesBuildFort.tileCanConceivablyTakeBuildFortStep(
          fortLevel: 1,
          techUnlocked: const {},
        ),
        isFalse,
      );
      expect(
        GameMapAreaProvinceActionStatesBuildFort.tileCanConceivablyTakeBuildFortStep(
          fortLevel: 1,
          techUnlocked: {kTechIdMineEngineering: true},
        ),
        isTrue,
      );
    });

    test('selectedTileIsProvinceTownTile matches province town tile key', () {
      const townKey = 'oldWorld|p1|2|3';
      final game = Game(
        id: 'g',
        worldState: WorldState(
          turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 1),
          oldWorld: RegionData(
            provinces: [
              Province(
                id: 'oldWorld|p1',
                regionId: 'oldWorld',
                ownerId: 'gp1',
                townTileKey: townKey,
              ),
            ],
          ),
          newWorld: const RegionData(),
        ),
        players: const [Player(id: 'gp1', displayName: 'GP', isHuman: true)],
      );
      expect(
        GameMapAreaProvinceActionStatesBuildFort.selectedTileIsProvinceTownTile(
          game: game,
          selectedTileKey: townKey,
        ),
        isTrue,
      );
      expect(
        GameMapAreaProvinceActionStatesBuildFort.selectedTileIsProvinceTownTile(
          game: game,
          selectedTileKey: 'oldWorld|p1|0|0',
        ),
        isFalse,
      );
    });
  });
}
