import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:test/test.dart';

void main() {
  group('movement without movement points', () {
    test(
        'London move is governed by movement rules, not movement points',
        () {
      final orderedGpIds = List<String>.from(
        GameSetupConfig.defaultConfig.selectedGreatPowerIds,
      );

      final leaderVariantByGpId = <String, String>{};
      for (final gpId in orderedGpIds) {
        final gp = defaultNamingConfig.gpById(gpId);
        if (gp != null && gp.leaderVariants.isNotEmpty) {
          leaderVariantByGpId[gpId] = gp.defaultLeaderVariantId;
        }
      }

      final config = GameSetupConfig(
        selectedGreatPowerIds: orderedGpIds,
        leaderVariantByGpId: leaderVariantByGpId,
        seed: 42,
        continentCount: GameSetupConfig.defaultConfig.continentCount,
        minorNationCount: GameSetupConfig.defaultConfig.minorNationCount,
        tribeCount: GameSetupConfig.defaultConfig.tribeCount,
        numProvincesOldWorld: GameSetupConfig.defaultConfig.numProvincesOldWorld,
        numProvincesNewWorld: GameSetupConfig.defaultConfig.numProvincesNewWorld,
        minProvincesPerMinor:
            GameSetupConfig.defaultConfig.minProvincesPerMinor,
      );

      final initResult = runInitGame(
        config: config,
        options: const InitGameOptions(renderPng: false),
      );

      final game = initResult.game;
      final topology = initResult.combinedTopology;

      expect(game, isNotNull);
      expect(topology, isNotNull);

      final player = game.players.first;
      final world = game.worldState.oldWorld;

      // London is oldWorld|p1 per naming/tests; assume Northumberland is another
      // province in the Old World reachable via normal movement rules.
      final london =
          world.provinces.firstWhere((p) => p.displayName == 'London');

      final unitsInLondon = world.units
          .where((u) => u.ownerId == player.id && u.locationProvinceId == london.id)
          .toList();

      expect(
        unitsInLondon,
        isNotEmpty,
        reason: 'Expected at least one player unit in London',
      );

      final unit = unitsInLondon.first;

      final regionId = unit.regionIdFromTile ??
          ProvinceId.regionIdFrom(unit.locationProvinceId);
      final localId = ProvinceId.localIdFrom(unit.locationProvinceId);

      final neighbours =
          neighborProvinceIdsInRegion(topology, regionId, localId).toList();

      expect(
        neighbours,
        isNotEmpty,
        reason: 'Expected London to have at least one adjacent province',
      );

      // Pick one adjacent province as a stand-in for Northumberland; the key
      // property is that adjacency/ownership/visibility, not movement points,
      // governs move validity.
      final targetProvinceId = ProvinceId.full(regionId, neighbours.first);

      final orders = Orders(
        moveOrdersByPlayerId: {
          player.id: [
            MoveOrder(
              unitId: unit.id,
              destinationProvinceId: targetProvinceId,
            ),
          ],
        },
      );

      final nextGame = requireTurnResolutionComplete(resolveTurnForGame(
        game: game,
        topology: topology,
        orders: orders,
        tileMapByRegion: initResult.tileMapByRegion,
      ));

      final movedUnit = nextGame.worldState.oldWorld.units
          .firstWhere((u) => u.id == unit.id);

      expect(
        movedUnit.locationProvinceId,
        targetProvinceId,
        reason:
            'Unit should move according to movement rules; movement points are not used',
      );
    });
  });
}

