import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_save/colonizethis_save.dart';
import 'package:colonizethis_setup/colonizethis_setup.dart';
import 'package:colonizethis_test/test.dart';
import 'package:colonizethis_world/colonizethis_world.dart';

import 'support/game_save_adapter_test_harness.dart';

/// Snapshot of advanced-start fields required by SPEC/game/advanced-starts.md
/// save/load AC (excludes load-time general reconciliation).
class _AdvancedStartSnapshot {
  const _AdvancedStartSnapshot({
    required this.advancedStartType,
    required this.turnNumber,
    required this.playerEconomyById,
    required this.playerTechUnlockedById,
    required this.playerVisibilityByTile,
    required this.playerProspectedTiles,
    required this.purchasedTilesByTileKey,
    required this.tileState,
    required this.oldWorldOwnership,
    required this.newWorldOwnership,
    required this.overtureStatesJson,
    required this.civilianCountsByPlayer,
    required this.regimentCountsByPlayer,
    required this.homeFleetShipTypesByPlayer,
  });

  final AdvancedStartType? advancedStartType;
  final int turnNumber;
  final Map<String, ({int treasury, int peasants, int apprentices})>
  playerEconomyById;
  final Map<String, Map<String, bool>> playerTechUnlockedById;
  final Map<String, Map<String, String>> playerVisibilityByTile;
  final Map<String, Set<String>> playerProspectedTiles;
  final Map<String, String> purchasedTilesByTileKey;
  final TileMapState tileState;
  final Map<String, String?> oldWorldOwnership;
  final Map<String, String?> newWorldOwnership;
  final List<Map<String, dynamic>> overtureStatesJson;
  final Map<String, Map<String, int>> civilianCountsByPlayer;
  final Map<String, int> regimentCountsByPlayer;
  final Map<String, List<String>> homeFleetShipTypesByPlayer;

  factory _AdvancedStartSnapshot.from(Game game) {
    final civilianCounts = <String, Map<String, int>>{};
    final regimentCounts = <String, int>{};
    final homeFleetShipTypes = <String, List<String>>{};

    for (final player in game.players) {
      final counts = <String, int>{};
      for (final unit in allUnitsFromWorld(game.worldState)) {
        if (unit.ownerId != player.id) continue;
        if (isMilitaryUnit(unit.type)) {
          regimentCounts[player.id] = (regimentCounts[player.id] ?? 0) + 1;
        } else {
          counts[unit.type] = (counts[unit.type] ?? 0) + 1;
        }
      }
      civilianCounts[player.id] = counts;

      final homeFleet = game.worldState.fleets
          .where((f) => f.id == homeFleetIdFor(player.id))
          .singleOrNull;
      homeFleetShipTypes[player.id] = homeFleet == null
          ? const []
          : (homeFleet.ships.map((s) => s.typeId).toList()..sort());
    }

    final economy = {
      for (final p in game.players)
        p.id: (
          treasury: p.treasury,
          peasants: p.workerPool.peasants,
          apprentices: p.workerPool.apprentices,
        ),
    };

    final techs = {
      for (final p in game.players)
        p.id: Map<String, bool>.from(p.techUnlocked ?? const {}),
    };

    final owOwnership = {
      for (final p in game.worldState.oldWorld.provinces) p.id: p.ownerId,
    };
    final nwOwnership = {
      for (final p in game.worldState.newWorld.provinces) p.id: p.ownerId,
    };

    final overturesJson = game.overtureStates.map((o) => o.toJson()).toList()
      ..sort((a, b) {
        final byGp = (a['gpId'] as String).compareTo(b['gpId'] as String);
        if (byGp != 0) return byGp;
        return (a['targetId'] as String).compareTo(b['targetId'] as String);
      });

    return _AdvancedStartSnapshot(
      advancedStartType: game.advancedStartType,
      turnNumber: game.worldState.turnState.turnNumber,
      playerEconomyById: economy,
      playerTechUnlockedById: techs,
      playerVisibilityByTile: game.worldState.playerVisibilityByTile,
      playerProspectedTiles: game.worldState.playerProspectedTiles,
      purchasedTilesByTileKey: game.worldState.purchasedTilesByTileKey,
      tileState: game.worldState.tileState,
      oldWorldOwnership: owOwnership,
      newWorldOwnership: nwOwnership,
      overtureStatesJson: overturesJson,
      civilianCountsByPlayer: civilianCounts,
      regimentCountsByPlayer: regimentCounts,
      homeFleetShipTypesByPlayer: homeFleetShipTypes,
    );
  }

  void expectMatches(_AdvancedStartSnapshot other) {
    expect(other.advancedStartType, advancedStartType);
    expect(other.turnNumber, turnNumber);
    expect(other.playerEconomyById, playerEconomyById);
    expect(other.playerTechUnlockedById, playerTechUnlockedById);
    expect(other.playerVisibilityByTile, playerVisibilityByTile);
    expect(other.playerProspectedTiles, playerProspectedTiles);
    expect(other.purchasedTilesByTileKey, purchasedTilesByTileKey);
    expect(other.tileState, tileState);
    expect(other.oldWorldOwnership, oldWorldOwnership);
    expect(other.newWorldOwnership, newWorldOwnership);
    expect(other.overtureStatesJson, overtureStatesJson);
    expect(other.civilianCountsByPlayer, civilianCountsByPlayer);
    expect(other.regimentCountsByPlayer, regimentCountsByPlayer);
    expect(other.homeFleetShipTypesByPlayer, homeFleetShipTypesByPlayer);
  }
}

void main() {
  final harness = GameSaveAdapterHiveHarness(
    hivePath: './.dart_tool/test_hive_advanced_start',
    boxName: 'advanced_start_games',
  );

  setUpAll(harness.open);
  tearDownAll(harness.close);
  setUp(harness.reset);

  group('advanced start save/load', () {
    test('turns50 runInitGame state round-trips through GameSaveAdapter', () {
      final init = runInitGame(
        config: GameSetupConfig(advancedStart: AdvancedStartType.turns50),
        options: const InitGameOptions(cellSize: 8, renderPng: false),
      );
      final game = init.game;
      final before = _AdvancedStartSnapshot.from(game);

      harness.adapter.save(harness.box, game);
      final loaded = harness.adapter.load(harness.box, game.id);
      expect(loaded, isNotNull);

      final after = _AdvancedStartSnapshot.from(loaded!);
      before.expectMatches(after);
    });

    test('turns100 runInitGame state round-trips through GameSaveAdapter', () {
      final init = runInitGame(
        config: GameSetupConfig(advancedStart: AdvancedStartType.turns100),
        options: const InitGameOptions(cellSize: 8, renderPng: false),
      );
      final game = init.game;
      final before = _AdvancedStartSnapshot.from(game);

      harness.adapter.save(harness.box, game);
      final loaded = harness.adapter.load(harness.box, game.id);
      expect(loaded, isNotNull);

      final after = _AdvancedStartSnapshot.from(loaded!);
      before.expectMatches(after);
    });
  });
}
