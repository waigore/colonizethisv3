import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_map/colonizethis_map.dart';
import 'package:colonizethis_test/test.dart';

void main() {
  group('computeGridSizeFromParams', () {
    test('derives grid size from MapGenerationParams: 60 provinces, sea 0.6, target 35', () {
      final params = MapGenerationParams(
        targetTilesPerProvince: 35,
        seaFraction: 0.6,
        numContinents: 3,
      );
      final size = computeGridSizeFromParams(60, params);
      final totalLandTiles = 60 * 35;
      expect(totalLandTiles, 2100);
      final totalTiles = (totalLandTiles / (1 - 0.6)).round();
      expect(totalTiles, 5250);
      expect(size.width * size.height, greaterThanOrEqualTo(totalTiles - size.height));
      expect(size.width * size.height, lessThanOrEqualTo(totalTiles + size.height));
      expect(size.width, greaterThanOrEqualTo(8));
      expect(size.height, greaterThanOrEqualTo(8));
    });

    test('higher sea fraction yields larger total grid for same land', () {
      final sizeLowSea = computeGridSizeFromParams(
        20,
        MapGenerationParams(seaFraction: 0.5, targetTilesPerProvince: 35),
      );
      final sizeHighSea = computeGridSizeFromParams(
        20,
        MapGenerationParams(seaFraction: 0.6, targetTilesPerProvince: 35),
      );
      expect(sizeHighSea.width * sizeHighSea.height,
          greaterThan(sizeLowSea.width * sizeLowSea.height));
    });

    test('zero provinces returns default dimensions', () {
      final size = computeGridSizeFromParams(
        0,
        const MapGenerationParams(),
      );
      expect(size.width, 32);
      expect(size.height, 24);
    });
  });

  group('buildProvinceToContinentMap', () {
    test('partitions provinces evenly across continents', () {
      final map = buildProvinceToContinentMap(6, 2);
      expect(map.length, 6);
      expect(map['p1'], 0);
      expect(map['p2'], 0);
      expect(map['p3'], 0);
      expect(map['p4'], 1);
      expect(map['p5'], 1);
      expect(map['p6'], 1);
    });

    test('distributes remainder to first continents', () {
      final map = buildProvinceToContinentMap(7, 3);
      expect(map.length, 7);
      expect(map['p1'], 0);
      expect(map['p2'], 0);
      expect(map['p3'], 0); // continent 0 gets 3
      expect(map['p4'], 1);
      expect(map['p5'], 1); // continent 1 gets 2
      expect(map['p6'], 2);
      expect(map['p7'], 2); // continent 2 gets 2
    });
  });

  group('computeContinentMembership', () {
    test('returns two components for 2 continents', () {
      final topology = generateTopology(TopologyGeneratorParams(
        numProvinces: 60,
        numContinents: 2,
        regionId: 'oldWorld',
        seed: 1,
      ));
      final membership = computeContinentMembership(topology);
      expect(membership.length, 60);
      final indices = membership.values.toSet();
      expect(indices.length, 2);
      expect(membership['p1'], membership['p30']);
      expect(membership['p31'], membership['p60']);
      expect(membership['p1'], isNot(equals(membership['p31'])));
    });
  });

  group('TileMapGenerator', () {
    test('generates grid with correct dimensions', () {
      final params = TileMapParams(width: 20, height: 15, seed: 1, seaFraction: 0.6);
      final (result, topology) = TileMapGenerator(params: params).generate(
        numProvinces: 1,
        numContinents: 1,
        regionId: 'r1',
      );
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

    test('two adjacent regions touch in grid', () {
      final params = TileMapParams(width: 30, height: 30, seed: 42, maxEnforceIterations: 5, seaFraction: 0.6);
      final (result, _) = TileMapGenerator(params: params).generate(
        numProvinces: 2,
        numContinents: 1,
        regionId: 'r1',
      );
      final pairs = result.adjacentRegionPairs();
      expect(pairs.contains('p1|p2'), isTrue);
    });

    test('numProvinces 0 throws', () {
      final gen = TileMapGenerator(params: TileMapParams(width: 10, height: 10));
      expect(
        () => gen.generate(numProvinces: 0, numContinents: 1, regionId: 'r1'),
        throwsArgumentError,
      );
    });

    test('numContinents 0 throws', () {
      final gen = TileMapGenerator(params: TileMapParams(width: 10, height: 10));
      expect(
        () => gen.generate(numProvinces: 1, numContinents: 0, regionId: 'r1'),
        throwsArgumentError,
      );
    });

    test('with resourceRules produces terrain and resource grids of same dimensions', () {
      final params = TileMapParams(width: 20, height: 15, seed: 2, seaFraction: 0.6);
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
    });

    test('terrain and resource respect region and terrain rules', () {
      final params = TileMapParams(width: 25, height: 25, seed: 3, seaFraction: 0.6);
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
      final params = TileMapParams(width: 30, height: 30, seed: 17, seaFraction: 0.6);
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

    test('multi-region resource cap: newWorld keeps both resources at or below cap', () {
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
          totalCount++;
          if (rules.regionRule[r] == ResourceRegionRule.both) bothCount++;
        }
      }
      if (totalCount > 0) {
        final fraction = bothCount / totalCount;
        expect(
          fraction,
          lessThanOrEqualTo(0.35),
          reason: 'bothCount=$bothCount totalCount=$totalCount fraction=$fraction',
        );
      }
    });

    test('multi-region resource cap: oldWorld respects region and terrain rules', () {
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
    });

    test('ResourceRules.defaultRules covers all Resource enum values', () {
      final rules = ResourceRules.defaultRules;
      for (final r in Resource.values) {
        expect(rules.regionRule.containsKey(r), isTrue, reason: 'regionRule missing $r');
        expect(rules.allowedTerrains.containsKey(r), isTrue, reason: 'allowedTerrains missing $r');
        expect(rules.defaultMarketPrice.containsKey(r), isTrue, reason: 'defaultMarketPrice missing $r');
      }
    });

    test('two-phase sea fraction: land count matches (1 - seaFraction) * width * height', () {
      const w = 20;
      const h = 20;
      const seaFraction = 0.6;
      final params = TileMapParams(width: w, height: h, seed: 12345, seaFraction: seaFraction);
      final (result, _) = TileMapGenerator(params: params).generate(
        numProvinces: 1,
        numContinents: 1,
        regionId: 'r1',
      );
      var landCount = 0;
      for (var y = 0; y < h; y++) {
        for (var x = 0; x < w; x++) {
          if (!RegExp(r'^s\d+$').hasMatch(result.cell(x, y))) landCount++;
        }
      }
      final expectedLand = ((1 - seaFraction) * w * h).round();
      expect(landCount, expectedLand);
    });

    test('onLog receives a line per pass', () {
      final logLines = <String>[];
      TileMapGenerator(params: TileMapParams(width: 10, height: 10, seed: 1, seaFraction: 0.6))
          .generate(
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

    test('without resourceRules leaves terrain and resource grids null', () {
      final (result, _) = TileMapGenerator(
        params: TileMapParams(width: 10, height: 10, seed: 1, seaFraction: 0.6),
      ).generate(numProvinces: 1, numContinents: 1, regionId: 'r1');
      expect(result.terrainGrid, isNull);
      expect(result.resourceGrid, isNull);
    });

    test('final grid has only province and sea zone ids (no land sentinel)', () {
      final (result, topology) = TileMapGenerator(
        params: TileMapParams(width: 24, height: 24, seed: 7, seaFraction: 0.6),
      ).generate(numProvinces: 2, numContinents: 1, regionId: 'r1');
      final validIds = topology.nodes.map((n) => n.id).toSet();
      for (var y = 0; y < result.height; y++) {
        for (var x = 0; x < result.width; x++) {
          expect(validIds.contains(result.cell(x, y)), isTrue,
              reason: 'cell ($x,$y) has id ${result.cell(x, y)}');
        }
      }
    });

    test('no enclosed sea after fill-lakes: all sea connected to grid edge', () {
      final (result, _) = TileMapGenerator(
        params: TileMapParams(width: 30, height: 30, seed: 11, seaFraction: 0.6),
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
        seaCells.where((p) =>
            p.$1 == 0 || p.$1 == result.width - 1 || p.$2 == 0 || p.$2 == result.height - 1),
      );
      final reachable = queue.toSet();
      while (queue.isNotEmpty) {
        final (x, y) = queue.removeLast();
        for (final (dx, dy) in [(0, -1), (0, 1), (-1, 0), (1, 0)]) {
          final nx = x + dx;
          final ny = y + dy;
          if (nx >= 0 && nx < result.width && ny >= 0 && ny < result.height) {
            final nid = result.cell(nx, ny);
            if (RegExp(r'^s\d+$').hasMatch(nid) && !reachable.contains((nx, ny))) {
              reachable.add((nx, ny));
              queue.add((nx, ny));
            }
          }
        }
      }
      expect(reachable.length, seaCells.length,
          reason: 'All sea cells should be reachable from edge (no lakes)');
    });

    test('Pass 11 subdivides sea: result has sea zone ids s1, s2, ...', () {
      final (result, topology) = TileMapGenerator(
        params: TileMapParams(width: 24, height: 24, seed: 7, seaFraction: 0.6),
      ).generate(numProvinces: 2, numContinents: 1, regionId: 'r1');
      final seaNodes = topology.nodes
          .where((n) => n.type == TopologyNodeType.seaZone)
          .map((n) => n.id)
          .toSet();
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

    test('Pass 11 sea zone size cap: subdivision produces many zones when sea is large', () {
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
      final seaZoneCount = topology.nodes
          .where((n) => n.type == TopologyNodeType.seaZone)
          .length;
      // With 5% cap, one ocean should be split into at least ~20 zones.
      expect(seaZoneCount, greaterThanOrEqualTo(15),
          reason: 'Expected many sea zones when cap is 5% of $totalSea sea tiles');
    });

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
      final (result, _) = TileMapGenerator(
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
          if (t != null) expect(allowed.contains(t), isTrue, reason: 'terrain $t');
        }
      }
    });

    test('mountain fraction is close to configured distribution and forms ridges', () {
      const w = 40;
      const h = 30;
      final params = TileMapParams(width: w, height: h, seed: 10, seaFraction: 0.6);
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
      final directions = <(int, int)>[
        (0, -1),
        (1, 0),
        (0, 1),
        (-1, 0),
      ];
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
      expect(hasElongated, isTrue,
          reason: 'expected at least one elongated mountain component');
    });

    test('non-mountain terrain quotas roughly follow distribution', () {
      const w = 40;
      const h = 30;
      final params = TileMapParams(width: w, height: h, seed: 20, seaFraction: 0.6);
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

    test('Pass 2 places continent seeds and clustered land seeds (log reports counts)', () {
      final logLines = <String>[];
      TileMapGenerator(params: TileMapParams(width: 24, height: 24, seed: 5, seaFraction: 0.6))
          .generate(
        numProvinces: 2,
        numContinents: 1,
        regionId: 'r1',
        onLog: (msg) => logLines.add(msg),
      );
      final pass2 = logLines.where((s) => s.contains('Pass 2')).single;
      expect(pass2, contains('Continent seeds'));
      expect(pass2, contains('land seeds'));
      expect(pass2, contains('1')); // 1 continent
    });

    test('onLandSeedsPlaced is invoked with land seed positions and continent indices', () {
      List<(int x, int y)>? capturedPositions;
      List<int>? capturedIndices;
      TileMapGenerator(params: TileMapParams(width: 20, height: 15, seed: 1, seaFraction: 0.6))
          .generate(
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
        expect(c, inInclusiveRange(0, 0), reason: 'Single continent: all indices 0');
      }
    });

    test('onContinentSeedsPlaced is invoked with one seed per continent', () {
      List<(int x, int y)>? continentSeeds;
      TileMapGenerator(params: TileMapParams(width: 24, height: 24, seed: 7, seaFraction: 0.6))
          .generate(
        numProvinces: 2,
        numContinents: 1,
        regionId: 'r1',
        onContinentSeedsPlaced: (s) => continentSeeds = s,
      );
      expect(continentSeeds, isNotNull);
      expect(continentSeeds!.length, 1); // one continent
    });

    test('seedBeforeAssignment: true produces valid tile map with land count matching budget', () {
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
      final (result, _) = TileMapGenerator(params: params).generate(
        numProvinces: 1,
        numContinents: 1,
        regionId: 'r1',
      );
      var landCount = 0;
      for (var y = 0; y < h; y++) {
        for (var x = 0; x < w; x++) {
          if (!RegExp(r'^s\d+$').hasMatch(result.cell(x, y))) landCount++;
        }
      }
      final expectedLand = ((1 - seaFraction) * w * h).round();
      expect(landCount, expectedLand);
    });

    test('seedBeforeAssignment: false (organic default) produces valid tile map with land', () {
      final params = TileMapParams(
        width: 30,
        height: 30,
        seed: 42,
        seaFraction: 0.6,
        seedBeforeAssignment: false,
      );
      final (result, _) = TileMapGenerator(params: params).generate(
        numProvinces: 2,
        numContinents: 1,
        regionId: 'r1',
      );
      var landCount = 0;
      for (var y = 0; y < result.height; y++) {
        for (var x = 0; x < result.width; x++) {
          if (!RegExp(r'^s\d+$').hasMatch(result.cell(x, y))) landCount++;
        }
      }
      expect(landCount, greaterThan(0));
      expect(result.adjacentRegionPairs(), contains('p1|p2'));
    });

    test('organic mode logs Pass 2–3 (organic)', () {
      final logLines = <String>[];
      TileMapGenerator(
        params: TileMapParams(width: 10, height: 10, seed: 1, seaFraction: 0.6, seedBeforeAssignment: false),
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
          (s) => s.contains('Pass 4') && s.contains('lakes') && s.contains('moats'),
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
      final (result, _) = TileMapGenerator(
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
      final (result, _) = TileMapGenerator(
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
        params: TileMapParams(width: 30, height: 30, seed: 42, seaFraction: 0.6),
      ).generate(numProvinces: 2, numContinents: 1, regionId: 'r1');
      final validation = validateTileMapTopology(topology, result);
      expect(validation.missing, isEmpty);
      expect(validation.extra, isEmpty);
      expect(validation.hasIssues, isFalse);
    });

    test('seed 125148772 with default buffer and fill lakes has no p6-p33 land bridge', () {
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
      final (_, topology) = TileMapGenerator(params: params).generate(
        numProvinces: 60,
        numContinents: 3,
        regionId: 'oldWorld',
      );
      final p6p33Key = 'p6|p33';
      final hasBridge = topology.edges.any((e) {
        final key = e.id1.compareTo(e.id2) < 0 ? '${e.id1}|${e.id2}' : '${e.id2}|${e.id1}';
        return key == p6p33Key;
      });
      expect(hasBridge, isFalse);
    });
  });

  group('validateTileMapTopology', () {
    test('grid missing required adjacency yields missing non-empty', () {
      final topology = MapTopology(
        nodes: [
          const TopologyNode(id: 'p1', regionId: 'r1', type: TopologyNodeType.province),
          const TopologyNode(id: 'p2', regionId: 'r1', type: TopologyNodeType.province),
          const TopologyNode(id: 's1', regionId: 'r1', type: TopologyNodeType.seaZone),
        ],
        edges: [
          const TopologyEdge(id1: 'p1', id2: 'p2'),
          const TopologyEdge(id1: 'p1', id2: 's1'),
          const TopologyEdge(id1: 'p2', id2: 's1'),
        ],
      );
      final grid = [
        ['p1', 'p1', 's1'],
        ['p1', 'p1', 's1'],
        ['s1', 's1', 's1'],
      ];
      final result = TileMapResult(width: 3, height: 3, grid: grid);
      final validation = validateTileMapTopology(topology, result);
      expect(validation.missing, contains('p1|p2'));
      expect(validation.hasIssues, isTrue);
    });
  });

  group('TileMapResult', () {
    test('adjacentRegionPairs returns normalized pairs', () {
      final grid = [
        ['a', 'b'],
        ['a', 'a'],
      ];
      final result = TileMapResult(width: 2, height: 2, grid: grid);
      final pairs = result.adjacentRegionPairs();
      expect(pairs, contains('a|b'));
      expect(pairs.length, 1);
    });
  });
}

