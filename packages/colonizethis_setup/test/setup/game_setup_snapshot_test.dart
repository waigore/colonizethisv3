// Ported from logic characterization (Refs #4090 Slice E; single-domain, fails keep gate).
import 'package:colonizethis_setup/colonizethis_setup.dart';
import 'package:colonizethis_test/test.dart';
import 'package:colonizethis_world/colonizethis_world.dart';
import 'game_setup_snapshot_fixture.dart';

void main() {
  group('GameSetup characterization', () {
    late GameSetupResult result;

    setUpAll(() {
      result = gameSetupSnapshotFixture();
    });

    test('player count and ids', () {
      expect(result.game.players.length, 2);
      expect(result.game.players[0].id, 'gp1');
      expect(result.game.players[1].id, 'gp2');
    });

    test('minor and tribe counts', () {
      expect(result.game.minorNations.length, 1);
      expect(result.game.tribes.length, 3);
    });

    test('OW province assignment is deterministic', () {
      final owProvinces = result.game.worldState.oldWorld.provinces;
      expect(owProvinces.length, 10);
      final ownerById = {for (final p in owProvinces) p.id: p.ownerId};

      // GPs should own (10 - 1*2) = 8 provinces, 4 each
      final gp1Count = ownerById.values.where((o) => o == 'gp1').length;
      final gp2Count = ownerById.values.where((o) => o == 'gp2').length;
      expect(gp1Count + gp2Count, 8);
      expect(gp1Count, 4);
      expect(gp2Count, 4);

      // Minor should own 2 provinces
      final minorCount = ownerById.values.where((o) => o == 'minor1').length;
      expect(minorCount, 2);
    });

    test('NW province assignment is deterministic', () {
      final nwProvinces = result.game.worldState.newWorld.provinces;
      expect(nwProvinces.length, 3);
      final ownerById = {for (final p in nwProvinces) p.id: p.ownerId};
      for (final tribeId in ['tribe1', 'tribe2', 'tribe3']) {
        expect(ownerById.values.where((o) => o == tribeId).length, 1);
      }
    });

    test('capitals are assigned for all factions', () {
      for (final p in result.game.players) {
        expect(
          p.capitalProvinceId,
          isNotNull,
          reason: '${p.id} must have capital',
        );
        expect(
          p.capitalTile,
          isNotNull,
          reason: '${p.id} must have capital tile',
        );
      }
      for (final m in result.game.minorNations) {
        expect(
          m.capitalProvinceId,
          isNotNull,
          reason: '${m.id} must have capital',
        );
      }
      for (final t in result.game.tribes) {
        expect(
          t.capitalProvinceId,
          isNotNull,
          reason: '${t.id} must have capital',
        );
      }
    });

    test('naming is applied to all provinces', () {
      for (final p in allProvinces(result.game.worldState)) {
        expect(p.displayName, isNotNull, reason: '${p.id} must have name');
        expect(
          p.displayName,
          isNotEmpty,
          reason: '${p.id} must have non-empty name',
        );
      }
    });

    test('land province display names are unique within each region', () {
      final owNames = result.game.worldState.oldWorld.provinces
          .map((p) => p.displayName!)
          .toList();
      expect(owNames.length, owNames.toSet().length);
      final nwNames = result.game.worldState.newWorld.provinces
          .map((p) => p.displayName!)
          .toList();
      expect(nwNames.length, nwNames.toSet().length);
    });

    test('within-faction province names are distinct in snapshot fixture', () {
      final ws = result.game.worldState;
      for (final owner in ['gp1', 'gp2', 'minor1']) {
        final names = ws.oldWorld.provinces
            .where((p) => p.ownerId == owner)
            .map((p) => p.displayName!)
            .toList();
        expect(names.length, names.toSet().length, reason: owner);
      }
      for (final owner in ['tribe1', 'tribe2', 'tribe3']) {
        final names = ws.newWorld.provinces
            .where((p) => p.ownerId == owner)
            .map((p) => p.displayName!)
            .toList();
        expect(names.length, names.toSet().length, reason: owner);
      }
    });

    test('GP display names and leader keys set from naming config', () {
      expect(result.game.players[0].displayName, 'England');
      expect(result.game.players[1].displayName, 'France');
      expect(result.game.players[0].leaderKey, isNotNull);
      expect(result.game.players[1].leaderKey, isNotNull);
    });

    test('initial visibility is set for all GPs', () {
      final vis = result.game.worldState.playerVisibilityByTile;
      for (final p in result.game.players) {
        expect(
          vis.containsKey(p.id),
          isTrue,
          reason: '${p.id} must have visibility',
        );
        expect(
          vis[p.id],
          isNotEmpty,
          reason: '${p.id} must have non-empty visibility',
        );
      }
    });

    test('starting units are spawned in capital provinces', () {
      final allUnits = [
        ...result.game.worldState.oldWorld.units,
        ...result.game.worldState.newWorld.units,
      ];
      for (final p in result.game.players) {
        final playerUnits = allUnits.where((u) => u.ownerId == p.id).toList();
        expect(
          playerUnits,
          isNotEmpty,
          reason: '${p.id} must have starting units',
        );
        for (final u in playerUnits) {
          expect(
            u.locationProvinceId,
            p.capitalProvinceId,
            reason: 'Unit ${u.id} must be in capital ${p.capitalProvinceId}',
          );
        }
      }
    });

    test('combined topology merges both regions', () {
      final combined = result.combinedTopology;
      expect(
        combined.nodes.length,
        result.topologyByRegion['oldWorld']!.nodes.length +
            result.topologyByRegion['newWorld']!.nodes.length,
      );
    });

    test('turnTimeMapping is set', () {
      expect(result.game.turnTimeMapping, isNotNull);
    });

    test(
      'each GP starts with general cap 1 and exactly one 0-medal general',
      () {
        // SPEC/game/military-generals.md § Count and tech-gated cap.
        for (final p in result.game.players) {
          expect(
            p.generalCap,
            1,
            reason: '${p.id} must start at general cap 1',
          );
          final generals = result.game.generals
              .where((g) => g.ownerId == p.id)
              .toList();
          expect(generals.length, 1, reason: '${p.id} must have one general');
          expect(generals.single.medals, 0);
        }
      },
    );
  });
}
