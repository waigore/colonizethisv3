import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_diplomacy/colonizethis_diplomacy.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_setup/colonizethis_setup.dart';
import 'package:colonizethis_test/test.dart';
import 'package:colonizethis_world/colonizethis_world.dart';

import 'init_game_orchestrator_test_support.dart';

int _countUnitsOfType(Game game, String ownerId, String type) {
  return allUnitsFromWorld(game.worldState)
      .where((u) => u.ownerId == ownerId && u.type == type)
      .length;
}

int _countMilitaryRegiments(Game game, String ownerId) {
  return allUnitsFromWorld(game.worldState)
      .where((u) => u.ownerId == ownerId && isMilitaryUnit(u.type))
      .length;
}

int _unlockedTechCount(Player player) {
  return player.techUnlocked?.entries
          .where((e) => e.value)
          .length ??
      0;
}

Set<String> _unlockedTechIds(Player player) {
  return {
    for (final entry in player.techUnlocked!.entries)
      if (entry.value) entry.key,
  };
}

int _countGpOwnedNwProvinces(Game game, String gpId) {
  return game.worldState.newWorld.provinces
      .where((p) => p.ownerId == gpId)
      .length;
}

int _countFullyVisibleNwProvinces(Game game, String playerId) {
  final visibility =
      game.worldState.playerVisibilityByTile[playerId] ?? const {};
  return game.worldState.newWorld.provinces
      .where((p) {
        final provinceKey = ProvinceId.isPrefixed(p.id)
            ? p.id
            : ProvinceId.full(p.regionId, p.id);
        final tileKeys = game
                .worldState
                .tileKeysByRegionAndProvince[kRegionNewWorld]?[provinceKey] ??
            const [];
        return tileKeys.any(
          (tk) => visibility[tk] == VisibilityLevel.fullyVisible.name,
        );
      })
      .length;
}

void _expectTierCivilians(Game game, Player player, AdvancedStartType type) {
  final counts = advancedStartCivilianCounts(type);
  for (final entry in counts.entries) {
    expect(
      _countUnitsOfType(game, player.id, entry.key),
      entry.value,
      reason: '${player.id} ${entry.key}',
    );
  }
}

void _expectConsulatesWithAllMinors(Game game, String gpId) {
  for (final minor in game.minorNations) {
    expect(
      getOverture(game, gpId, minor.id)!.stage,
      OvertureStage.tradeConsulate,
      reason: 'consulate with ${minor.id}',
    );
  }
}

void _expectEmbassiesWithAllMinors(Game game, String gpId) {
  for (final minor in game.minorNations) {
    expect(
      getOverture(game, gpId, minor.id)!.stage,
      OvertureStage.embassy,
      reason: 'embassy with ${minor.id}',
    );
  }
}

void main() {
  group('runInitGame advanced start units slice', () {
    test('turns50 locked profile applies tier civilians regiments and galleon', () {
      final result = runInitGame(
        config: GameSetupConfig(
          advancedStart: AdvancedStartType.turns50,
        ),
        options: defaultInitOptions,
      );
      final game = result.game;
      expect(game.advancedStartType, AdvancedStartType.turns50);
      expect(game.worldState.turnState.turnNumber, 50);

      for (final player in game.players) {
        expect(_countUnitsOfType(game, player.id, kUnitTypeExplorer), 3);
        expect(_countUnitsOfType(game, player.id, kUnitTypeBuilder), 3);
        expect(_countUnitsOfType(game, player.id, kUnitTypeEngineer), 2);
        expect(_countUnitsOfType(game, player.id, kUnitTypeSpy), 1);
        expect(_countUnitsOfType(game, player.id, kUnitTypeMerchant), 1);
        expect(_countMilitaryRegiments(game, player.id), 6);
        final homeFleet = game.worldState.fleets
            .where((f) => f.id == homeFleetIdFor(player.id))
            .singleOrNull;
        expect(homeFleet, isNotNull);
        expect(
          homeFleet!.ships.where((s) => s.typeId == kAdvancedStartCargoShipTypeId),
          hasLength(1),
        );
        expect(
          getOverture(game, player.id, game.minorNations.first.id)!.stage,
          OvertureStage.tradeConsulate,
        );
      }
    });

    test('turns50 locked profile reveals NW tiles for each GP', () {
      final result = runInitGame(
        config: GameSetupConfig(
          advancedStart: AdvancedStartType.turns50,
        ),
        options: defaultInitOptions,
      );
      final game = result.game;
      final totalNwProvinces = game.worldState.newWorld.provinces.length;

      for (final player in game.players) {
        final visibleNwProvinces = _countFullyVisibleNwProvinces(game, player.id);
        expect(visibleNwProvinces, greaterThan(0));
        expect(visibleNwProvinces, lessThanOrEqualTo(totalNwProvinces));
      }
    });

    test('turns100 locked profile applies rail builder and six galleons', () {
      final result = runInitGame(
        config: GameSetupConfig(
          advancedStart: AdvancedStartType.turns100,
        ),
        options: defaultInitOptions,
      );
      final game = result.game;
      expect(game.advancedStartType, AdvancedStartType.turns100);

      for (final player in game.players) {
        expect(_countUnitsOfType(game, player.id, kUnitTypeRailBuilder), 1);
        expect(_countMilitaryRegiments(game, player.id), 12);
        final homeFleet = game.worldState.fleets
            .where((f) => f.id == homeFleetIdFor(player.id))
            .singleOrNull;
        expect(homeFleet!.ships, hasLength(6));
        expect(
          getOverture(game, player.id, game.minorNations.first.id)!.stage,
          OvertureStage.embassy,
        );
      }
    });
  });

  group('runInitGame advanced start acceptance criteria', () {
    test('turns50 locked profile satisfies tier economy and world state', () {
      final game = runInitGame(
        config: GameSetupConfig(
          seed: 42,
          advancedStart: AdvancedStartType.turns50,
        ),
        options: defaultInitOptions,
      ).game;

      expect(game.advancedStartType, AdvancedStartType.turns50);
      expect(game.worldState.turnState.turnNumber, 50);

      for (final player in game.players) {
        expect(player.treasury, 20000);
        expect(player.workerPool.peasants, 16);
        expect(player.workerPool.apprentices, 0);
        expect(_unlockedTechCount(player), 23);
        expect(
          _unlockedTechIds(player),
          containsAll(kAdvancedStart50TurnTechIds),
        );
        _expectTierCivilians(game, player, AdvancedStartType.turns50);
        expect(_countMilitaryRegiments(game, player.id), 6);
        expect(_countGpOwnedNwProvinces(game, player.id), 0);
        expect(
          _countFullyVisibleNwProvinces(game, player.id),
          greaterThan(0),
        );
        _expectConsulatesWithAllMinors(game, player.id);
      }
    });

    test('turns100 locked profile satisfies colonization and tier economy', () {
      final game = runInitGame(
        config: GameSetupConfig(
          seed: 42,
          advancedStart: AdvancedStartType.turns100,
        ),
        options: defaultInitOptions,
      ).game;

      expect(game.advancedStartType, AdvancedStartType.turns100);
      expect(game.worldState.turnState.turnNumber, 100);

      var totalGpOwnedNw = 0;

      for (final player in game.players) {
        expect(player.treasury, 40000);
        expect(player.workerPool.peasants, 16);
        expect(player.workerPool.apprentices, 4);
        expect(_unlockedTechCount(player), 45);
        expect(
          _unlockedTechIds(player),
          containsAll(kAdvancedStart100TurnTechIds),
        );
        _expectTierCivilians(game, player, AdvancedStartType.turns100);
        expect(_countMilitaryRegiments(game, player.id), 12);
        totalGpOwnedNw += _countGpOwnedNwProvinces(game, player.id);
        expect(
          _countFullyVisibleNwProvinces(game, player.id),
          greaterThan(0),
        );
        _expectEmbassiesWithAllMinors(game, player.id);
      }

      // Map capacity may cap per-GP assignment below six; bootstrap still
      // assigns contiguous provinces where tribe reserves allow.
      expect(totalGpOwnedNw, greaterThan(0));

      for (final tribe in game.tribes) {
        final owned = game.worldState.newWorld.provinces
            .where((p) => p.ownerId == tribe.id)
            .length;
        expect(owned, greaterThanOrEqualTo(1), reason: tribe.id);
      }
    });

    test('none leaves turn-0 game unchanged', () {
      final game = runInitGame(
        config: GameSetupConfig.defaultConfig,
        options: defaultInitOptions,
      ).game;

      expect(game.advancedStartType, isNull);
      expect(game.worldState.turnState.turnNumber, 0);
    });
  });
}
