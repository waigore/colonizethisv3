// Structural pin for colonizethis_setup wave-7 Slice A concern splits (Refs #4349).
import 'dart:io';

import 'package:colonizethis_setup/colonizethis_setup.dart';
import 'package:colonizethis_test/test.dart';
import 'package:path/path.dart' as p;

import '../../lib/src/setup/game_setup_create_post_ownership.dart'
    as create_post;
import '../../lib/src/setup/game_setup_ownership_old_world.dart' as ow;
import '../../lib/src/setup/game_setup_ownership_old_world_contiguous.dart'
    as ow_contiguous;
import '../../lib/src/setup/game_setup_ownership_old_world_seeds.dart'
    as ow_seeds;
import '../../lib/src/setup/gp_old_world_resource_redistribution_quota_spillover.dart'
    as quota_spillover;
import '../../lib/src/setup/gp_old_world_terrain_redistribution_hamilton.dart'
    as terrain_hamilton;
import '../../lib/src/setup/locked_province_assigner_engine_candidates.dart'
    as locked_candidates;
import '../../lib/src/setup/province_assignment_bfs_greedy.dart' as bfs_greedy;
import '../../lib/src/setup/setup_road_wiring.dart' as road_wiring;
import '../../lib/src/setup/setup_road_wiring_tile_helpers.dart'
    as road_helpers;

void main() {
  group('setup wave-7 Slice A splits', () {
    test('split modules exist on disk under lib/src/setup', () {
      final root = Directory.current.path;
      // Package tests may run with cwd = package root or repo root.
      final candidates = [
        p.join(root, 'lib/src/setup'),
        p.join(root, 'packages/colonizethis_setup/lib/src/setup'),
      ];
      final setupDir = candidates
          .map(Directory.new)
          .firstWhere((d) => d.existsSync());
      for (final name in [
        'game_setup_ownership_old_world_contiguous.dart',
        'game_setup_ownership_old_world_seeds.dart',
        'province_assignment_bfs_greedy.dart',
        'locked_province_assigner_engine_candidates.dart',
        'locked_province_assigner_engine_search.dart',
        'setup_road_wiring_tile_helpers.dart',
      ]) {
        expect(File(p.join(setupDir.path, name)).existsSync(), isTrue);
      }
    });

    test('ownership / BFS / road / locked helpers remain importable', () {
      expect(ow.assignOldWorldSingleLandmass, isA<Function>());
      expect(ow_contiguous.assignOldWorldOwnershipContiguous, isA<Function>());
      expect(ow_seeds.selectGpSeedsForLandmass, isA<Function>());
      expect(assignTerritoriesByBfsGrowth, isA<Function>());
      expect(bfs_greedy.greedyAssignRemainingTerritories, isA<Function>());
      expect(bfs_greedy.greedyPickFactionForProvince, isA<Function>());
      expect(
        locked_candidates.lockedAssignerRankedCandidatesForFaction,
        isA<Function>(),
      );
      expect(road_helpers.raiseRoadAtLeast, isA<Function>());
      expect(road_wiring.applySeaboardPortAndRoadWiring, isA<Function>());
      expect(
        road_wiring.nearestSeaboardTileInProvinceForSeaZone,
        isA<Function>(),
      );
      expect(assignTerritoriesLockedOnLandmass, isA<Function>());
    });
  });

  group('setup wave-7 Slice B splits', () {
    test('near-cap split modules exist on disk under lib/src/setup', () {
      final root = Directory.current.path;
      final candidates = [
        p.join(root, 'lib/src/setup'),
        p.join(root, 'packages/colonizethis_setup/lib/src/setup'),
      ];
      final setupDir = candidates
          .map(Directory.new)
          .firstWhere((d) => d.existsSync());
      for (final name in [
        'gp_old_world_terrain_redistribution_hamilton.dart',
        'gp_old_world_resource_redistribution_quota_spillover.dart',
        'game_setup_create_post_ownership.dart',
      ]) {
        expect(File(p.join(setupDir.path, name)).existsSync(), isTrue);
      }
    });

    test('create / terrain / quota helpers remain importable', () {
      expect(createGameFromGeneratedMaps, isA<Function>());
      expect(applyGreatPowerOldWorldTerrainRedistribution, isA<Function>());
      expect(create_post.applyPostOwnershipSetupPhases, isA<Function>());
      expect(terrain_hamilton.hamiltonTargetsForType, isA<Function>());
      expect(terrain_hamilton.fairnessMaxAbsFracDeviation, isA<Function>());
      expect(quota_spillover.accumulateSpilloverPool, isA<Function>());
      expect(quota_spillover.distributeQuotaPool, isA<Function>());
    });

    test('hamilton targets sum to nT for equal weights', () {
      final targets = terrain_hamilton.hamiltonTargetsForType(
        nT: 5,
        gpIdsSorted: const ['gp1', 'gp2'],
        wByGp: const {'gp1': 1, 'gp2': 1},
        tieTerrainIndex: 0,
        setupSeedBase: 1,
      );
      expect(targets.values.fold<int>(0, (a, b) => a + b), 5);
    });

    test('hamilton targets are zero when nT is 0', () {
      final targets = terrain_hamilton.hamiltonTargetsForType(
        nT: 0,
        gpIdsSorted: const ['gp1'],
        wByGp: const {'gp1': 1},
        tieTerrainIndex: 0,
        setupSeedBase: 1,
      );
      expect(targets['gp1'], 0);
    });
  });
}
