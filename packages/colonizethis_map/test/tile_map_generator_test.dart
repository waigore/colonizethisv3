import 'package:colonizethis_test/test.dart';
import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_map/colonizethis_map.dart';
import 'package:colonizethis_map/src/tile_map_directions.dart';
import 'package:colonizethis_map/src/tile_map_topology_helpers.dart';
import 'package:logger/logger.dart';

void main() {
  group('TileMapGenerator', () {
    test('generates grid with correct dimensions', () {
      final params = TileMapParams(
        width: 20,
        height: 15,
        seed: 1,
        seaFraction: 0.6,
      );
      final (result, topology) = TileMapGenerator(
        params: params,
      ).generate(numProvinces: 1, numContinents: 1, regionId: 'r1');
      expect(result.width, 20);
      expect(result.height, 15);
      expect(result.grid.length, 15);
      for (final row in result.grid) {
        expect(row.length, 20);
        expect(
          row.every((id) => id == 'p1' || RegExp(r'^s\d+$').hasMatch(id)),
          isTrue,
        );
      }
      expect(topology.nodes.length, greaterThanOrEqualTo(2));
    });

    test(
      'TileMapGenerator.generate emits end info with continents and success',
      () {
        final capturedEvents = <LogEvent>[];
        void listener(LogEvent e) => capturedEvents.add(e);
        Logger.addLogListener(listener);
        Logger.level = Level.info;

        try {
          final params = TileMapParams(
            width: 20,
            height: 15,
            seed: 1,
            seaFraction: 0.6,
          );
          final gen = TileMapGenerator(params: params);

          final (_, topology) = gen.generate(
            numProvinces: 3,
            numContinents: 2,
            regionId: 'r1',
          );

          final expectedProvinces = topology.nodes
              .where((n) => n.type == TopologyNodeType.province)
              .length;
          const expectedContinents = 2;

          final endMessages = capturedEvents
              .where((e) => e.message.contains('TileMapGenerator.generate end'))
              .map((e) => e.message)
              .toList();
          expect(endMessages.length, 1);

          final endLine = endMessages.single;
          expect(endLine, contains('regionId=r1'));
          expect(endLine, contains('provinces=$expectedProvinces'));
          expect(endLine, contains('continents=$expectedContinents'));
          expect(endLine, contains('success=true'));
        } finally {
          Logger.removeLogListener(listener);
          Logger.level = Level.info;
        }
      },
    );

    test('two adjacent regions touch in grid', () {
      final params = TileMapParams(
        width: 30,
        height: 30,
        seed: 42,
        maxEnforceIterations: 5,
        seaFraction: 0.6,
      );
      final (result, _) = TileMapGenerator(
        params: params,
      ).generate(numProvinces: 2, numContinents: 1, regionId: 'r1');
      final pairs = result.adjacentRegionPairs();
      expect(pairs.contains('p1|p2'), isTrue);
    });

    test('numProvinces 0 throws', () {
      final gen = TileMapGenerator(
        params: TileMapParams(width: 10, height: 10),
      );
      expect(
        () => gen.generate(numProvinces: 0, numContinents: 1, regionId: 'r1'),
        throwsArgumentError,
      );
    });

    test('numContinents 0 throws', () {
      final gen = TileMapGenerator(
        params: TileMapParams(width: 10, height: 10),
      );
      expect(
        () => gen.generate(numProvinces: 1, numContinents: 0, regionId: 'r1'),
        throwsArgumentError,
      );
    });

    test(
      'with resourceRules produces terrain and resource grids of same dimensions',
      () {
        final params = TileMapParams(
          width: 20,
          height: 15,
          seed: 2,
          seaFraction: 0.6,
        );
        final (result, _) = TileMapGenerator(params: params).generate(
          numProvinces: 1,
          numContinents: 1,
          regionId: 'oldWorld',
          resourceRules: ResourceRules.defaultRules,
        );
        expect(result.terrainGrid, isNotNull);
        expect(result.resourceGrid, isNotNull);
        expect(result.terrainGrid!.length, result.height);
        expect(result.resourceGrid!.length, result.height);
        for (var i = 0; i < result.height; i++) {
          expect(result.terrainGrid![i].length, result.width);
          expect(result.resourceGrid![i].length, result.width);
        }
      },
    );

    test('terrain and resource respect region and terrain rules', () {
      final params = TileMapParams(
        width: 25,
        height: 25,
        seed: 3,
        seaFraction: 0.6,
      );
      final (result, _) = TileMapGenerator(params: params).generate(
        numProvinces: 1,
        numContinents: 1,
        regionId: 'oldWorld',
        resourceRules: ResourceRules.defaultRules,
      );
      final rules = ResourceRules.defaultRules;
      for (var y = 0; y < result.height; y++) {
        for (var x = 0; x < result.width; x++) {
          final t = result.terrainAt(x, y);
          final r = result.resourceAt(x, y);
          if (t != null && r != null) {
            expect(rules.isAllowedOnTerrain(r, t), isTrue);
            expect(rules.isAllowedInRegion(r, 'oldWorld'), isTrue);
          }
        }
      }
    });

    test('newWorld resources respect region and terrain rules', () {
      final params = TileMapParams(
        width: 30,
        height: 30,
        seed: 17,
        seaFraction: 0.6,
      );
      final (result, _) = TileMapGenerator(params: params).generate(
        numProvinces: 2,
        numContinents: 1,
        regionId: 'newWorld',
        resourceRules: ResourceRules.defaultRules,
      );
      final rules = ResourceRules.defaultRules;
      for (var y = 0; y < result.height; y++) {
        for (var x = 0; x < result.width; x++) {
          final t = result.terrainAt(x, y);
          final r = result.resourceAt(x, y);
          if (t != null && r != null) {
            expect(rules.isAllowedOnTerrain(r, t), isTrue);
            expect(rules.isAllowedInRegion(r, 'newWorld'), isTrue);
          }
        }
      }
    });

    test(
      'multi-region resource cap: newWorld keeps both resources at or below cap',
      () {
        final params = TileMapParams(
          width: 24,
          height: 24,
          seed: 42,
          seaFraction: 0.5,
        );
        final (result, _) = TileMapGenerator(params: params).generate(
          numProvinces: 2,
          numContinents: 1,
          regionId: 'newWorld',
          resourceRules: ResourceRules.defaultRules,
        );
        final rules = ResourceRules.defaultRules;
        var bothCount = 0;
        var totalCount = 0;
        for (var y = 0; y < result.height; y++) {
          for (var x = 0; x < result.width; x++) {
            final r = result.resourceAt(x, y);
            if (r == null) continue;
            // Guaranteed forest resource placements (timber/furs) are excluded
            // from multi-region cap accounting (R3.5, issue #3573), mirroring
            // the bootstrap-grain exclusion; the cap governs only non-forest
            // cells. SPEC/program/tile-map-gen-resources.md.
            final terrain = result.terrainAt(x, y);
            if (terrain != null && isForestTerrain(terrain)) continue;
            totalCount++;
            if (rules.regionRule[r] == ResourceRegionRule.both) bothCount++;
          }
        }
        if (totalCount > 0) {
          final fraction = bothCount / totalCount;
          expect(
            fraction,
            lessThanOrEqualTo(0.35),
            reason:
                'bothCount=$bothCount totalCount=$totalCount fraction=$fraction',
          );
        }
      },
    );

    test(
      'multi-region resource cap: oldWorld respects region and terrain rules',
      () {
        final params = TileMapParams(
          width: 24,
          height: 24,
          seed: 99,
          seaFraction: 0.5,
        );
        final (result, _) = TileMapGenerator(params: params).generate(
          numProvinces: 2,
          numContinents: 1,
          regionId: 'oldWorld',
          resourceRules: ResourceRules.defaultRules,
        );
        final rules = ResourceRules.defaultRules;
        for (var y = 0; y < result.height; y++) {
          for (var x = 0; x < result.width; x++) {
            final t = result.terrainAt(x, y);
            final r = result.resourceAt(x, y);
            if (t != null && r != null) {
              expect(rules.isAllowedOnTerrain(r, t), isTrue);
              expect(rules.isAllowedInRegion(r, 'oldWorld'), isTrue);
            }
          }
        }
      },
    );

    test('ResourceRules.defaultRules covers all Resource enum values', () {
      final rules = ResourceRules.defaultRules;
      for (final r in Resource.values) {
        expect(
          rules.regionRule.containsKey(r),
          isTrue,
          reason: 'regionRule missing $r',
        );
        expect(
          rules.allowedTerrains.containsKey(r),
          isTrue,
          reason: 'allowedTerrains missing $r',
        );
        expect(
          rules.defaultMarketPrice.containsKey(r),
          isTrue,
          reason: 'defaultMarketPrice missing $r',
        );
      }
    });

    test(
      'two-phase sea fraction: land count matches (1 - seaFraction) * width * height',
      () {
        const w = 20;
        const h = 20;
        const seaFraction = 0.6;
        final params = TileMapParams(
          width: w,
          height: h,
          seed: 12345,
          seaFraction: seaFraction,
        );
        final (result, _) = TileMapGenerator(
          params: params,
        ).generate(numProvinces: 1, numContinents: 1, regionId: 'r1');
        var landCount = 0;
        for (var y = 0; y < h; y++) {
          for (var x = 0; x < w; x++) {
            if (!RegExp(r'^s\d+$').hasMatch(result.cell(x, y))) landCount++;
          }
        }
        final expectedLand = ((1 - seaFraction) * w * h).round();
        expect(landCount, expectedLand);
      },
    );

    test('onLog receives a line per pass', () {
      final logLines = <String>[];
      TileMapGenerator(
        params: TileMapParams(width: 10, height: 10, seed: 1, seaFraction: 0.6),
      ).generate(
        numProvinces: 1,
        numContinents: 1,
        regionId: 'r1',
        onLog: (msg) => logLines.add(msg),
      );
      expect(logLines.any((s) => s.contains('Pass 1')), isTrue);
      expect(logLines.any((s) => s.contains('Pass 2')), isTrue);
      expect(logLines.any((s) => s.contains('Pass 3')), isTrue);
      expect(logLines.any((s) => s.contains('Pass 4')), isTrue);
      expect(logLines.any((s) => s.contains('Pass 5')), isTrue);
      expect(logLines.any((s) => s.contains('Pass 6')), isTrue);
      expect(logLines.any((s) => s.contains('Pass 8')), isTrue);
      expect(logLines.any((s) => s.contains('Pass 9')), isTrue);
      expect(logLines.any((s) => s.contains('Pass 11')), isTrue);
    });

    test(
      'emits generation_params map log with derived grid and key toggles',
      () {
        final capturedEvents = <LogEvent>[];
        void listener(LogEvent event) => capturedEvents.add(event);
        Logger.addLogListener(listener);
        addTearDown(() => Logger.removeLogListener(listener));

        final params = TileMapParams(
          width: 12,
          height: 9,
          seed: 77,
          seaFraction: 0.55,
          joinContinents: true,
          skipFillLakes: true,
          seedBeforeAssignment: false,
        );
        TileMapGenerator(
          params: params,
        ).generate(numProvinces: 3, numContinents: 2, regionId: 'oldWorld');

        final message = capturedEvents
            .map((e) => e.message.toString())
            .firstWhere((m) => m.contains('map: generation_params'));
        expect(message, contains('regionId=oldWorld'));
        expect(message, contains('numProvinces=3'));
        expect(message, contains('numContinents=2'));
        expect(message, contains('width=12'));
        expect(message, contains('height=9'));
        expect(message, contains('seed=77'));
        expect(message, contains('seaFraction=0.55'));
        expect(message, contains('joinContinents=true'));
        expect(message, contains('skipFillLakes=true'));
        expect(message, contains('seedBeforeAssignment=false'));
      },
    );

    test('without resourceRules leaves terrain and resource grids null', () {
      final (result, _) = TileMapGenerator(
        params: TileMapParams(width: 10, height: 10, seed: 1, seaFraction: 0.6),
      ).generate(numProvinces: 1, numContinents: 1, regionId: 'r1');
      expect(result.terrainGrid, isNull);
      expect(result.resourceGrid, isNull);
    });

    test(
      'final grid has only province and sea zone ids (no land sentinel)',
      () {
        final (result, topology) = TileMapGenerator(
          params: TileMapParams(
            width: 24,
            height: 24,
            seed: 7,
            seaFraction: 0.6,
          ),
        ).generate(numProvinces: 2, numContinents: 1, regionId: 'r1');
        final validIds = topology.nodes.map((n) => n.id).toSet();
        for (var y = 0; y < result.height; y++) {
          for (var x = 0; x < result.width; x++) {
            expect(
              validIds.contains(result.cell(x, y)),
              isTrue,
              reason: 'cell ($x,$y) has id ${result.cell(x, y)}',
            );
          }
        }
      },
    );

    test(
      'no enclosed sea after fill-lakes: all sea connected to grid edge',
      () {
        final (result, _) = TileMapGenerator(
          params: TileMapParams(
            width: 30,
            height: 30,
            seed: 11,
            seaFraction: 0.6,
          ),
        ).generate(numProvinces: 1, numContinents: 1, regionId: 'r1');
        final seaCells = <(int, int)>{};
        for (var y = 0; y < result.height; y++) {
          for (var x = 0; x < result.width; x++) {
            if (RegExp(r'^s\d+$').hasMatch(result.cell(x, y))) {
              seaCells.add((x, y));
            }
          }
        }
        if (seaCells.isEmpty) return;
        final queue = List<(int, int)>.from(
          seaCells.where(
            (p) =>
                p.$1 == 0 ||
                p.$1 == result.width - 1 ||
                p.$2 == 0 ||
                p.$2 == result.height - 1,
          ),
        );
        final reachable = queue.toSet();
        while (queue.isNotEmpty) {
          final (x, y) = queue.removeLast();
          for (final (dx, dy) in kTileMapDirections4NorthSouthWestEast) {
            final nx = x + dx;
            final ny = y + dy;
            if (nx >= 0 && nx < result.width && ny >= 0 && ny < result.height) {
              final nid = result.cell(nx, ny);
              if (RegExp(r'^s\d+$').hasMatch(nid) &&
                  !reachable.contains((nx, ny))) {
                reachable.add((nx, ny));
                queue.add((nx, ny));
              }
            }
          }
        }
        expect(
          reachable.length,
          seaCells.length,
          reason: 'All sea cells should be reachable from edge (no lakes)',
        );
      },
    );

    test(
      'generated map has at least one sea zone on grid boundary (warp zone placement)',
      () {
        // SPEC/game/map-topology.md § Warp zones: placement uses sea zones on the map edge.
        final (result, topology) = TileMapGenerator(
          params: TileMapParams(
            width: 24,
            height: 24,
            seed: 7,
            seaFraction: 0.6,
          ),
        ).generate(numProvinces: 2, numContinents: 1, regionId: 'r1');
        final seaZoneIds = seaZoneIdsFromTopology(topology);
        if (seaZoneIds.isEmpty) return;
        final boundaryIds = <String>{};
        final w = result.width;
        final h = result.height;
        for (var x = 0; x < w; x++) {
          boundaryIds.add(result.cell(x, 0));
          boundaryIds.add(result.cell(x, h - 1));
        }
        for (var y = 0; y < h; y++) {
          boundaryIds.add(result.cell(0, y));
          boundaryIds.add(result.cell(w - 1, y));
        }
        final edgeSea = boundaryIds.where(seaZoneIds.contains).toSet();
        expect(
          edgeSea,
          isNotEmpty,
          reason:
              'At least one sea zone should touch grid boundary for warp zone generation',
        );
      },
    );

    test('Pass 11 subdivides sea: result has sea zone ids s1, s2, ...', () {
      final (result, topology) = TileMapGenerator(
        params: TileMapParams(width: 24, height: 24, seed: 7, seaFraction: 0.6),
      ).generate(numProvinces: 2, numContinents: 1, regionId: 'r1');
      final seaNodes = seaZoneIdsFromTopology(topology);
      expect(seaNodes, isNotEmpty);
      for (final id in seaNodes) {
        expect(RegExp(r'^s\d+$').hasMatch(id), isTrue);
      }
      final gridSeaIds = <String>{};
      for (var y = 0; y < result.height; y++) {
        for (var x = 0; x < result.width; x++) {
          final id = result.cell(x, y);
          if (RegExp(r'^s\d+$').hasMatch(id)) gridSeaIds.add(id);
        }
      }
      expect(gridSeaIds, equals(seaNodes));
    });

    test(
      'Pass 11 sea zone size cap: subdivision produces many zones when sea is large',
      () {
        final (result, topology) = TileMapGenerator(
          params: TileMapParams(
            width: 40,
            height: 40,
            seed: 99,
            seaFraction: 0.65,
            maxSeaZoneFraction: 0.05,
          ),
        ).generate(numProvinces: 4, numContinents: 1, regionId: 'r1');
        var totalSea = 0;
        for (var y = 0; y < result.height; y++) {
          for (var x = 0; x < result.width; x++) {
            if (RegExp(r'^s\d+$').hasMatch(result.cell(x, y))) totalSea++;
          }
        }
        if (totalSea == 0) return;
        final seaZoneCount = seaZoneIdsFromTopology(topology).length;
        // With 5% cap, one ocean should be split into at least ~20 zones.
        expect(
          seaZoneCount,
          greaterThanOrEqualTo(15),
          reason:
              'Expected many sea zones when cap is 5% of $totalSea sea tiles',
        );
      },
    );

    test('Pass 11 log mentions sea zones and cap', () {
      final logLines = <String>[];
      TileMapGenerator(
        params: TileMapParams(width: 24, height: 24, seed: 7, seaFraction: 0.6),
      ).generate(
        numProvinces: 2,
        numContinents: 1,
        regionId: 'r1',
        onLog: (msg) => logLines.add(msg),
      );
      final pass11 = logLines.where((s) => s.contains('Pass 11')).toList();
      expect(pass11, isNotEmpty);
      expect(pass11.first, contains('Sea zone subdivision'));
      expect(pass11.first, contains('cap'));
    });

    test('terrain on land uses only map region allowed set (oldWorld)', () {
      final (
        result,
        _,
      ) = TileMapGenerator(
        params: TileMapParams(width: 25, height: 25, seed: 4, seaFraction: 0.6),
      ).generate(
        numProvinces: 1,
        numContinents: 1,
        regionId: 'oldWorld',
        resourceRules: ResourceRules.defaultRules,
      );
      final allowed = allowedTerrainsForRegion('oldWorld').toSet();
      for (var y = 0; y < result.height; y++) {
        for (var x = 0; x < result.width; x++) {
          final t = result.terrainAt(x, y);
          if (t != null)
            expect(allowed.contains(t), isTrue, reason: 'terrain $t');
        }
      }
    });

    test(
      'mountain fraction is close to configured distribution and forms ridges',
      () {
        const w = 40;
        const h = 30;
        final params = TileMapParams(
          width: w,
          height: h,
          seed: 10,
          seaFraction: 0.6,
        );
        final (result, _) = TileMapGenerator(params: params).generate(
          numProvinces: 4,
          numContinents: 1,
          regionId: 'oldWorld',
          resourceRules: ResourceRules.defaultRules,
        );
        final dist = terrainDistributionForRegion('oldWorld');
        var landCount = 0;
        var mountainCount = 0;
        for (var y = 0; y < h; y++) {
          for (var x = 0; x < w; x++) {
            final id = result.cell(x, y);
            if (!RegExp(r'^s\d+$').hasMatch(id)) {
              landCount++;
              if (result.terrainAt(x, y) == TerrainType.mountain) {
                mountainCount++;
              }
            }
          }
        }
        if (landCount == 0) return;
        final target = dist.mountainFraction * landCount;
        // Allow generous tolerance; we only require approximate adherence.
        expect(mountainCount, greaterThan(0));
        expect(
          mountainCount,
          inInclusiveRange((target * 0.4).round(), (target * 1.6).round()),
          reason:
              'mountain count $mountainCount should be within a factor of target $target',
        );

        // Check that there exists at least one elongated mountain component
        // (roughly ridge-like rather than a tiny blob).
        final seen = <(int, int)>{};
        final directions = <(int, int)>[(0, -1), (1, 0), (0, 1), (-1, 0)];
        var hasElongated = false;
        for (var y = 0; y < h; y++) {
          for (var x = 0; x < w; x++) {
            if (result.terrainAt(x, y) != TerrainType.mountain) continue;
            if (seen.contains((x, y))) continue;
            final queue = <(int, int)>[(x, y)];
            final component = <(int, int)>{(x, y)};
            seen.add((x, y));
            while (queue.isNotEmpty) {
              final (cx, cy) = queue.removeLast();
              for (final (dx, dy) in directions) {
                final nx = cx + dx;
                final ny = cy + dy;
                if (nx < 0 || nx >= w || ny < 0 || ny >= h) continue;
                if (result.terrainAt(nx, ny) != TerrainType.mountain) continue;
                if (component.add((nx, ny))) {
                  seen.add((nx, ny));
                  queue.add((nx, ny));
                }
              }
            }
            final size = component.length;
            if (size < 5) continue;
            var minX = w;
            var maxX = 0;
            var minY = h;
            var maxY = 0;
            for (final (cx, cy) in component) {
              if (cx < minX) minX = cx;
              if (cx > maxX) maxX = cx;
              if (cy < minY) minY = cy;
              if (cy > maxY) maxY = cy;
            }
            final spanX = (maxX - minX + 1);
            final spanY = (maxY - minY + 1);
            final maxSpan = spanX > spanY ? spanX : spanY;
            if (maxSpan >= 2 && size / maxSpan >= 2) {
              hasElongated = true;
              break;
            }
          }
          if (hasElongated) break;
        }
        expect(
          hasElongated,
          isTrue,
          reason: 'expected at least one elongated mountain component',
        );
      },
    );

    test('non-mountain terrain quotas roughly follow distribution', () {
      const w = 40;
      const h = 30;
      final params = TileMapParams(
        width: w,
        height: h,
        seed: 20,
        seaFraction: 0.6,
      );
      final (result, _) = TileMapGenerator(params: params).generate(
        numProvinces: 4,
        numContinents: 1,
        regionId: 'oldWorld',
        resourceRules: ResourceRules.defaultRules,
      );
      final dist = terrainDistributionForRegion('oldWorld');
      final counts = <TerrainType, int>{
        for (final t in TerrainType.values) t: 0,
      };
      var landCount = 0;
      for (var y = 0; y < h; y++) {
        for (var x = 0; x < w; x++) {
          final id = result.cell(x, y);
          if (RegExp(r'^s\d+$').hasMatch(id)) continue;
          landCount++;
          final t = result.terrainAt(x, y);
          if (t != null) {
            counts[t] = (counts[t] ?? 0) + 1;
          }
        }
      }
      if (landCount == 0) return;

      for (final t in TerrainType.values) {
        final frac = dist.fractionFor(t);
        if (frac == 0) continue;
        final expected = frac * landCount;
        final actual = counts[t] ?? 0;
        // Allow a generous band; we only require approximate adherence over the
        // map and small-fraction terrains (like swamp) can deviate more.
        if (expected < 50) {
          // For rare terrains, just assert they do not dominate the map.
          expect(
            actual,
            lessThanOrEqualTo((landCount * 0.5).round()),
            reason:
                'terrain $t has $actual tiles, expected roughly $expected (land=$landCount)',
          );
        } else {
          final lower = (expected * 0.3).round();
          final upper = (expected * 2.2).round();
          expect(
            actual,
            inInclusiveRange(lower, upper),
            reason:
                'terrain $t has $actual tiles, expected roughly $expected (land=$landCount)',
          );
        }
      }
    });

    test(
      'Pass 2 places continent seeds and clustered land seeds (log reports counts)',
      () {
        final logLines = <String>[];
        TileMapGenerator(
          params: TileMapParams(
            width: 24,
            height: 24,
            seed: 5,
            seaFraction: 0.6,
          ),
        ).generate(
          numProvinces: 2,
          numContinents: 1,
          regionId: 'r1',
          onLog: (msg) => logLines.add(msg),
        );
        final pass2 = logLines.where((s) => s.contains('Pass 2')).single;
        expect(pass2, contains('Continent seeds'));
        expect(pass2, contains('land seeds'));
        expect(pass2, contains('1')); // 1 continent
      },
    );

    test(
      'onLandSeedsPlaced is invoked with land seed positions and continent indices',
      () {
        List<(int x, int y)>? capturedPositions;
        List<int>? capturedIndices;
        TileMapGenerator(
          params: TileMapParams(
            width: 20,
            height: 15,
            seed: 1,
            seaFraction: 0.6,
          ),
        ).generate(
          numProvinces: 1,
          numContinents: 1,
          regionId: 'r1',
          onLandSeedsPlaced: (positions, indices) {
            capturedPositions = positions;
            capturedIndices = indices;
          },
        );
        expect(capturedPositions, isNotNull);
        expect(capturedIndices, isNotNull);
        expect(capturedPositions!.length, greaterThan(0));
        expect(capturedIndices!.length, capturedPositions!.length);
        for (final c in capturedIndices!) {
          expect(
            c,
            inInclusiveRange(0, 0),
            reason: 'Single continent: all indices 0',
          );
        }
      },
    );

    test('onContinentSeedsPlaced is invoked with one seed per continent', () {
      List<(int x, int y)>? continentSeeds;
      TileMapGenerator(
        params: TileMapParams(width: 24, height: 24, seed: 7, seaFraction: 0.6),
      ).generate(
        numProvinces: 2,
        numContinents: 1,
        regionId: 'r1',
        onContinentSeedsPlaced: (s) => continentSeeds = s,
      );
      expect(continentSeeds, isNotNull);
      expect(continentSeeds!.length, 1); // one continent
    });

    test(
      'seedBeforeAssignment: true produces valid tile map with land count matching budget',
      () {
        const w = 20;
        const h = 20;
        const seaFraction = 0.6;
        final params = TileMapParams(
          width: w,
          height: h,
          seed: 1,
          seaFraction: seaFraction,
          seedBeforeAssignment: true,
        );
        final (result, _) = TileMapGenerator(
          params: params,
        ).generate(numProvinces: 1, numContinents: 1, regionId: 'r1');
        var landCount = 0;
        for (var y = 0; y < h; y++) {
          for (var x = 0; x < w; x++) {
            if (!RegExp(r'^s\d+$').hasMatch(result.cell(x, y))) landCount++;
          }
        }
        final expectedLand = ((1 - seaFraction) * w * h).round();
        expect(landCount, expectedLand);
      },
    );

    test(
      'seedBeforeAssignment: false (organic default) produces valid tile map with land',
      () {
        final params = TileMapParams(
          width: 30,
          height: 30,
          seed: 42,
          seaFraction: 0.6,
          seedBeforeAssignment: false,
        );
        final (result, _) = TileMapGenerator(
          params: params,
        ).generate(numProvinces: 2, numContinents: 1, regionId: 'r1');
        var landCount = 0;
        for (var y = 0; y < result.height; y++) {
          for (var x = 0; x < result.width; x++) {
            if (!RegExp(r'^s\d+$').hasMatch(result.cell(x, y))) landCount++;
          }
        }
        expect(landCount, greaterThan(0));
        expect(result.adjacentRegionPairs(), contains('p1|p2'));
      },
    );

    test('organic mode logs Pass 2–3 (organic)', () {
      final logLines = <String>[];
      TileMapGenerator(
        params: TileMapParams(
          width: 10,
          height: 10,
          seed: 1,
          seaFraction: 0.6,
          seedBeforeAssignment: false,
        ),
      ).generate(
        numProvinces: 1,
        numContinents: 1,
        regionId: 'r1',
        onLog: (msg) => logLines.add(msg),
      );
      expect(logLines.any((s) => s.contains('organic')), isTrue);
    });

    test('Pass 4 log mentions lakes and moats', () {
      final logLines = <String>[];
      TileMapGenerator(
        params: TileMapParams(width: 10, height: 10, seed: 1, seaFraction: 0.6),
      ).generate(
        numProvinces: 1,
        numContinents: 1,
        regionId: 'r1',
        onLog: (msg) => logLines.add(msg),
      );
      expect(logLines.any((s) => s.contains('Pass 4')), isTrue);
      expect(
        logLines.any(
          (s) =>
              s.contains('Pass 4') &&
              s.contains('lakes') &&
              s.contains('moats'),
        ),
        isTrue,
      );
    });

    test('skipFillLakes true logs Fill lakes skipped', () {
      final logLines = <String>[];
      TileMapGenerator(
        params: TileMapParams(
          width: 10,
          height: 10,
          seed: 1,
          seaFraction: 0.6,
          skipFillLakes: true,
        ),
      ).generate(
        numProvinces: 1,
        numContinents: 1,
        regionId: 'r1',
        onLog: (msg) => logLines.add(msg),
      );
      expect(
        logLines.any((s) => s.contains('Fill lakes') && s.contains('skipped')),
        isTrue,
      );
    });

    test('borderNoise greater than zero applies border noise', () {
      final logLines = <String>[];
      final (result, _) =
          TileMapGenerator(
            params: TileMapParams(
              width: 20,
              height: 20,
              seed: 2,
              seaFraction: 0.6,
              borderNoise: 0.5,
            ),
          ).generate(
            numProvinces: 2,
            numContinents: 1,
            regionId: 'r1',
            resourceRules: ResourceRules.defaultRules,
            onLog: (msg) => logLines.add(msg),
          );
      expect(result.terrainGrid, isNotNull);
      expect(
        logLines.any((s) => s.contains('Border noise') || s.contains('Pass 5')),
        isTrue,
      );
    });

    test('jitter params produce terrain and resource grids', () {
      final (result, _) =
          TileMapGenerator(
            params: TileMapParams(
              width: 24,
              height: 24,
              seed: 3,
              seaFraction: 0.6,
              jitterHomogeneityThreshold: 0.5,
              jitterProbability: 0.5,
              jitterMaxFraction: 0.2,
            ),
          ).generate(
            numProvinces: 2,
            numContinents: 1,
            regionId: 'oldWorld',
            resourceRules: ResourceRules.defaultRules,
          );
      expect(result.terrainGrid, isNotNull);
      expect(result.resourceGrid, isNotNull);
      expect(result.terrainGrid!.length, result.height);
      expect(result.resourceGrid!.length, result.height);
    });

    test('inferred topology matches grid adjacencies', () {
      final (result, topology) = TileMapGenerator(
        params: TileMapParams(
          width: 30,
          height: 30,
          seed: 42,
          seaFraction: 0.6,
        ),
      ).generate(numProvinces: 2, numContinents: 1, regionId: 'r1');
      final validation = validateTileMapTopology(topology, result);
      expect(validation.missing, isEmpty);
      expect(validation.extra, isEmpty);
      expect(validation.hasIssues, isFalse);
    });

    test(
      'seed 125148772 with default buffer and fill lakes has no p6-p33 land bridge',
      () {
        final mapGenParams = MapGenerationParams(
          seed: 125148772,
          numContinents: 3,
          continentBufferTiles: 2,
          skipFillLakes: false,
        );
        final size = computeGridSizeFromParams(60, mapGenParams);
        final params = TileMapParams(
          width: size.width,
          height: size.height,
          seed: mapGenParams.seed,
          seaFraction: mapGenParams.seaFraction,
          continentBufferTiles: mapGenParams.continentBufferTiles,
          skipFillLakes: mapGenParams.skipFillLakes,
        );
        final (_, topology) = TileMapGenerator(
          params: params,
        ).generate(numProvinces: 60, numContinents: 3, regionId: 'oldWorld');
        final p6p33Key = 'p6|p33';
        final hasBridge = topology.edges.any((e) {
          final key = e.id1.compareTo(e.id2) < 0
              ? '${e.id1}|${e.id2}'
              : '${e.id2}|${e.id1}';
          return key == p6p33Key;
        });
        expect(hasBridge, isFalse);
      },
    );

    test(
      'joinContinents completes for small multi-continent grids (regression: no hang)',
      () {
        for (final seed in [0, 7, 42, 99, 777]) {
          final params = TileMapParams(
            width: 20,
            height: 18,
            seed: seed,
            seaFraction: 0.6,
          );
          TileMapGenerator(
            params: params,
          ).generate(numProvinces: 6, numContinents: 3, regionId: 'oldWorld');
        }
      },
    );
  });

}
