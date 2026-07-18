import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_economy/colonizethis_economy.dart';
import 'package:colonizethis_economy_test_support/colonizethis_economy_test_support.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';
import 'package:colonizethis_world/colonizethis_world.dart';

void main() {
  group('computeProvinceExtractionSnapshots (Refs #4002)', () {
    runLabeledScenarios(
      provinceExtractionSnapshotScenarios(),
      runProvinceExtractionSnapshotScenario,
      labelOf: (s) => s.label,
    );
  });

  group('provinceImprovableResourceTileCounts (Refs #4002)', () {
    runLabeledScenarios(
      provinceImprovableCountsScenarios(),
      runProvinceImprovableCountsScenario,
      labelOf: (s) => s.label,
    );
  });

  test(
    'negative: out-of-bounds improvement keys do not throw during snapshot build',
    () {
      // Combat-style stub maps can list improvements outside the grid
      // (e.g. y=1 on a height-1 map). Snapshot scan must skip them.
      const inBounds = 'oldWorld|p1|0|0';
      const outOfBounds = 'oldWorld|p1|0|1';
      final tileState = tileStateFromSpecs([
        const TileImprovementSpec(inBounds, 2, 1),
        const TileImprovementSpec(outOfBounds, 2, 1),
      ]);
      final game = resourceExtractorGame(tileState: tileState);
      final map = TileMapResult(
        width: 2,
        height: 1,
        grid: const [
          ['p1', 'p1'],
        ],
        resourceGrid: const [
          [Resource.grain, Resource.grain],
        ],
      );
      final snaps = computeProvinceExtractionSnapshots(
        game: game,
        tileMapByRegion: {'oldWorld': map},
        connectivityResult: {
          'pl1': ConnectivityResult(
            connected: {inBounds},
            pathTransportCap: const {inBounds: 4},
          ),
        },
        techCapForPlayer: (_) => 4,
      );
      final grain = snaps['oldWorld|p1']!.byCommodity['grain']!;
      expect(grain.effective, 2);
      expect(grain.full, 2);
      expect(grain.tileKeys, [inBounds]);
    },
  );

  group('projectProvinceExtraction (Refs #4064)', () {
    test(
      'negative: mid-turn draft improve intent is not applied — only Game '
      'tile state drives projection',
      () {
        // SPEC/program/province-extraction-snapshot.md: drafts ignored.
        // projectProvinceExtraction has no Orders parameter; quantities track
        // post-resolution improvement levels only.
        const tk = 'oldWorld|p1|0|0';
        const provinceId = 'oldWorld|p1';
        final map = TileMapResult(
          width: 2,
          height: 1,
          grid: const [
            ['p1', 'p1'],
          ],
          resourceGrid: const [
            [Resource.grain, Resource.grain],
          ],
        );
        final topology = const MapTopology(
          nodes: [
            TopologyNode(
              id: 'p1',
              regionId: 'oldWorld',
              type: TopologyNodeType.province,
            ),
          ],
          edges: [],
        );

        // Current post-resolution world: level-1 grain (draft build_improvement
        // would raise to 2 if applied — it must not affect projection).
        final unresolvedGame = resourceExtractorGame(
          tileState: tileStateFromSpecs([
            const TileImprovementSpec(tk, 1, 4),
          ]),
        );
        final unresolved = projectProvinceExtraction(
          game: unresolvedGame,
          tileMapByRegion: {'oldWorld': map},
          topology: topology,
          provinceId: provinceId,
          techCapForPlayer: (_) => 4,
        );
        expect(unresolved, isNotNull);
        final unresolvedGrain = unresolved!.byCommodity['grain']!;
        expect(unresolvedGrain.full, 1);

        // Same Game again → identical (no draft channel into the projector).
        final again = projectProvinceExtraction(
          game: unresolvedGame,
          tileMapByRegion: {'oldWorld': map},
          topology: topology,
          provinceId: provinceId,
          techCapForPlayer: (_) => 4,
        );
        expect(again, unresolved);

        // After turn resolution writes level 2 into Game, projection rises.
        final resolvedGame = resourceExtractorGame(
          tileState: tileStateFromSpecs([
            const TileImprovementSpec(tk, 2, 4),
          ]),
        );
        final resolved = projectProvinceExtraction(
          game: resolvedGame,
          tileMapByRegion: {'oldWorld': map},
          topology: topology,
          provinceId: provinceId,
          techCapForPlayer: (_) => 4,
        );
        expect(resolved, isNotNull);
        expect(resolved!.byCommodity['grain']!.full, 2);
        expect(resolved.byCommodity['grain']!.full, isNot(unresolvedGrain.full));
      },
    );

    test(
      'ownership change: new owner projection appears without Extraction write',
      () {
        // SPEC/program/province-extraction-snapshot.md: current-owner only;
        // conquest refreshes display immediately (Refs #4064).
        const tk = 'oldWorld|p1|0|0';
        const provinceId = 'oldWorld|p1';
        const otherProvinceId = 'oldWorld|p2';
        final map = TileMapResult(
          width: 2,
          height: 1,
          grid: const [
            ['p1', 'p1'],
          ],
          resourceGrid: const [
            [Resource.grain, Resource.grain],
          ],
        );
        final topology = const MapTopology(
          nodes: [
            TopologyNode(
              id: 'p1',
              regionId: 'oldWorld',
              type: TopologyNodeType.province,
            ),
            TopologyNode(
              id: 'p2',
              regionId: 'oldWorld',
              type: TopologyNodeType.province,
            ),
          ],
          edges: [],
        );
        final tileState = tileStateFromSpecs([
          const TileImprovementSpec(tk, 2, 4),
        ]);

        Player gp({required String id, required String capitalId}) {
          return Player(
            id: id,
            displayName: id,
            isHuman: id == 'pl1',
            capitalProvinceId: capitalId,
            capitalTile: CapitalTile(
              regionId: 'oldWorld',
              provinceId: capitalId,
              x: 0,
              y: 0,
            ),
            techUnlocked: const {kTechIdMoldboardPlow: true},
          );
        }

        Game gameWithOwner(String p1OwnerId) {
          final p2OwnerId = p1OwnerId == 'pl1' ? 'pl2' : 'pl1';
          return Game(
            id: 'g_ownership_projection',
            capitalTileGrainBonusPerTurn: 3,
            worldState: WorldState(
              turnState: const TurnState(
                phase: TurnPhase.orders,
                turnNumber: 2,
              ),
              oldWorld: RegionData(
                provinces: [
                  Province(
                    id: provinceId,
                    regionId: 'oldWorld',
                    ownerId: p1OwnerId,
                    townDevelopmentLevel: 4,
                  ),
                  Province(
                    id: otherProvinceId,
                    regionId: 'oldWorld',
                    ownerId: p2OwnerId,
                    townDevelopmentLevel: 4,
                  ),
                ],
              ),
              newWorld: const RegionData(),
              tileState: tileState,
              resourceByTileKey: const {tk: 'grain'},
              tileKeysByRegionAndProvince: const {
                'oldWorld': {
                  provinceId: [tk],
                  otherProvinceId: <String>[],
                },
              },
            ),
            players: [
              gp(
                id: 'pl1',
                capitalId: p1OwnerId == 'pl1' ? provinceId : otherProvinceId,
              ),
              gp(
                id: 'pl2',
                capitalId: p1OwnerId == 'pl2' ? provinceId : otherProvinceId,
              ),
            ],
          );
        }

        final before = projectProvinceExtraction(
          game: gameWithOwner('pl1'),
          tileMapByRegion: {'oldWorld': map},
          topology: topology,
          provinceId: provinceId,
          techCapForPlayer: (_) => 4,
        );
        expect(before, isNotNull);
        expect(before!.ownerId, 'pl1');
        expect(before.byCommodity['grain']!.full, greaterThan(0));
        expect(before.capitalGrainBonus, 3);

        final after = projectProvinceExtraction(
          game: gameWithOwner('pl2'),
          tileMapByRegion: {'oldWorld': map},
          topology: topology,
          provinceId: provinceId,
          techCapForPlayer: (_) => 4,
        );
        expect(after, isNotNull);
        expect(after!.ownerId, 'pl2');
        expect(after.byCommodity['grain']!.full, greaterThan(0));
        // Capital reassigned with conquest in this fixture → bonus follows new
        // capital owner immediately (no Extraction-phase snapshot write).
        expect(after.capitalGrainBonus, 3);
        expect(after.ownerId, isNot(before.ownerId));
      },
    );
  });
}
