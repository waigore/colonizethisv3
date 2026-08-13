// Structural pin for colonizethis_setup wave-7 Slice A concern splits (Refs #4349).
import 'dart:io';

import 'package:colonizethis_setup/colonizethis_setup.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';

import '../../lib/src/setup/game_setup_ownership_old_world.dart' as ow;
import '../../lib/src/setup/game_setup_ownership_old_world_contiguous.dart'
    as ow_contiguous;
import '../../lib/src/setup/game_setup_ownership_old_world_seeds.dart' as ow_seeds;
import '../../lib/src/setup/locked_province_assigner_engine_candidates.dart'
    as locked_candidates;
import '../../lib/src/setup/province_assignment_bfs_greedy.dart' as bfs_greedy;
import '../../lib/src/setup/setup_road_wiring.dart' as road_wiring;
import '../../lib/src/setup/setup_road_wiring_tile_helpers.dart' as road_helpers;

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
      expect(road_wiring.nearestSeaboardTileInProvinceForSeaZone, isA<Function>());
      expect(assignTerritoriesLockedOnLandmass, isA<Function>());
    });
  });
}
