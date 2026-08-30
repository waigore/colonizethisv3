import 'package:colonizethis_logic/civilian_intel_api.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';

import 'spy_relocate_intel_fixtures.dart';

Game _minorProvinceGame() {
  return Game(
    id: 'g_minor',
    players: const [
      Player(id: kSpyRelocateHumanId, displayName: 'Human', isHuman: true),
    ],
    minorNations: const [
      MinorNation(id: 'minor1', displayName: 'Minor'),
    ],
    worldState: WorldState(
      turnState: TurnState(phase: TurnPhase.orders, turnNumber: 1),
      oldWorld: RegionData(
        provinces: const [
          Province(
            id: 'oldWorld|p1',
            regionId: 'oldWorld',
            displayName: 'Home',
            ownerId: kSpyRelocateHumanId,
          ),
          Province(
            id: 'oldWorld|p2',
            regionId: 'oldWorld',
            displayName: 'Minor Land',
            ownerId: 'minor1',
          ),
        ],
        units: const [],
      ),
      newWorld: const RegionData(),
    ),
  );
}

void main() {
  group('isRivalGreatPowerProvinceForPlayer', () {
    test('true for rival GP province', () {
      final game = spyRelocateTwoProvinceGame();
      expect(
        isRivalGreatPowerProvinceForPlayer(
          game: game,
          prefixedProvinceId: 'oldWorld|p2',
          humanPlayerId: kSpyRelocateHumanId,
        ),
        isTrue,
      );
    });

    test('false for minor nation province', () {
      final game = _minorProvinceGame();
      expect(
        isRivalGreatPowerProvinceForPlayer(
          game: game,
          prefixedProvinceId: 'oldWorld|p2',
          humanPlayerId: kSpyRelocateHumanId,
        ),
        isFalse,
      );
    });
  });

  group('spyResearchInsightGistKindForProvince', () {
    test('may speed research on rival GP with no Spy there yet', () {
      final game = spyRelocateOwnedProvinceSpyGame();
      expect(
        spyResearchInsightGistKindForProvince(
          game: game,
          orders: const Orders(),
          humanPlayerId: kSpyRelocateHumanId,
          prefixedProvinceId: 'oldWorld|p2',
        ),
        SpyResearchInsightGistKind.none,
      );
      final rivalGame = spyRelocateTwoProvinceGame();
      // spy on rival land — for *target* province when relocating from home,
      // use a game where spy is at home and we query rival province
      final homeSpyGame = Game(
        id: 'g_home_spy',
        players: rivalGame.players,
        worldState: WorldState(
          turnState: TurnState(phase: TurnPhase.orders, turnNumber: 1),
          oldWorld: RegionData(
            provinces: rivalGame.worldState.oldWorld.provinces,
            units: [
              Unit(
                id: 'spy1',
                type: kUnitTypeSpy,
                ownerId: kSpyRelocateHumanId,
                locationProvinceId: 'oldWorld|p1',
                tileKey: 'oldWorld|p1|0|0',
              ),
            ],
          ),
          newWorld: const RegionData(),
        ),
      );
      expect(
        spyResearchInsightGistKindForProvince(
          game: homeSpyGame,
          orders: const Orders(),
          humanPlayerId: kSpyRelocateHumanId,
          prefixedProvinceId: 'oldWorld|p2',
        ),
        SpyResearchInsightGistKind.maySpeedResearch,
      );
    });

    test('already grants insight when Spy already in that court', () {
      final game = spyRelocateTwoProvinceGame();
      expect(
        spyResearchInsightGistKindForProvince(
          game: game,
          orders: const Orders(),
          humanPlayerId: kSpyRelocateHumanId,
          prefixedProvinceId: 'oldWorld|p2',
        ),
        SpyResearchInsightGistKind.alreadyGrantsInsight,
      );
    });

    test('none for minor nation province', () {
      final game = _minorProvinceGame();
      expect(
        spyResearchInsightGistKindForProvince(
          game: game,
          orders: const Orders(),
          humanPlayerId: kSpyRelocateHumanId,
          prefixedProvinceId: 'oldWorld|p2',
        ),
        SpyResearchInsightGistKind.none,
      );
    });
  });

  group('countOwnSpiesProjectedInRivalGp', () {
    test('counts projected Spies in rival GP provinces', () {
      final game = spyRelocateDualSpyForeignGame();
      expect(
        countOwnSpiesProjectedInRivalGp(
          game: game,
          orders: const Orders(),
          humanPlayerId: kSpyRelocateHumanId,
          rivalGpId: kSpyRelocateRivalId,
        ),
        2,
      );
    });
  });
}
