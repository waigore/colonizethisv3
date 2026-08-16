import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';
import 'package:colonizethis_turn/colonizethis_turn.dart';

void main() {
  group('spyResearchBoostRivalIdsForTech', () {
    test('positive: rival with own spy and unlocked tech qualifies', () {
      final game = _gameWithOwnSpyInRivalLand(rivalUnlocked: true);
      expect(
        spyResearchBoostRivalIdsForTech(
          game: game,
          playerId: 'gp1',
          techId: kTechIdCropRotation,
        ),
        ['gp2'],
      );
      expect(
        spyResearchBoostGpCountForTech(
          game: game,
          playerId: 'gp1',
          techId: kTechIdCropRotation,
        ),
        1,
      );
    });

    test('negative: rival without the tech does not qualify', () {
      final game = _gameWithOwnSpyInRivalLand(rivalUnlocked: false);
      expect(
        spyResearchBoostRivalIdsForTech(
          game: game,
          playerId: 'gp1',
          techId: kTechIdCropRotation,
        ),
        isEmpty,
      );
    });

    test('negative: empty tech id returns no rivals', () {
      final game = _gameWithOwnSpyInRivalLand(rivalUnlocked: true);
      expect(
        spyResearchBoostRivalIdsForTech(
          game: game,
          playerId: 'gp1',
          techId: '',
        ),
        isEmpty,
      );
    });
  });
}

Game _gameWithOwnSpyInRivalLand({required bool rivalUnlocked}) {
  const ow = 'oldWorld';
  const home = '$ow|p1';
  const rivalLand = '$ow|p2';
  return Game(
    id: 'g',
    worldState: WorldState(
      turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 1),
      oldWorld: RegionData(
        provinces: const [
          Province(id: home, regionId: ow, ownerId: 'gp1'),
          Province(id: rivalLand, regionId: ow, ownerId: 'gp2'),
        ],
        units: [
          Unit(
            id: 'spy_own',
            type: kUnitTypeSpy,
            ownerId: 'gp1',
            locationProvinceId: rivalLand,
            tileKey: '$rivalLand|0|0',
          ),
        ],
      ),
      newWorld: const RegionData(),
    ),
    players: [
      const Player(id: 'gp1', displayName: 'England', isHuman: true),
      Player(
        id: 'gp2',
        displayName: 'France',
        isHuman: false,
        techUnlocked: rivalUnlocked ? const {kTechIdCropRotation: true} : null,
      ),
    ],
  );
}
