part of 'tile_map_generator.dart';

mixin _TileMapGeneratorTerrainAssign on _TileMapGeneratorGraph {
  (List<List<TerrainType?>>, List<List<Resource?>>) _assignTerrainAndResources(
    List<List<String>> grid,
    String mapRegionId,
    ResourceRules rules,
    Random rnd,
  ) {
    final terrainGrid = List.generate(
      params.height,
      (_) => List.filled(params.width, null as TerrainType?),
    );
    final resourceGrid = List.generate(
      params.height,
      (_) => List.filled(params.width, null as Resource?),
    );

    // Collect land cells (sentinel) for terrain assignment.
    final landCells = <(int x, int y)>[];
    for (var y = 0; y < params.height; y++) {
      for (var x = 0; x < params.width; x++) {
        if (grid[y][x] == _landSentinel) {
          landCells.add((x, y));
        }
      }
    }
    if (landCells.isEmpty) {
      // No land; nothing to assign.
      return (terrainGrid, resourceGrid);
    }

    final distribution = terrainDistributionForRegion(mapRegionId);

    // Pass 6a: mountain ridges (random-walk ranges).
    _assignMountainRidges(terrainGrid, grid, landCells, distribution, rnd);

    // Pass 6b: region-growing for non-mountain terrains.
    _assignNonMountainTerrainsRegionGrowing(
      terrainGrid,
      grid,
      mapRegionId,
      distribution,
      rnd,
    );

    // Pass 7: resources, using final terrainGrid and existing rules.
    final capState = (mapRegionId == 'oldWorld' || mapRegionId == 'newWorld')
        ? _MultiRegionCapState(
            params.multiRegionResourceCapFraction,
            rules,
            mapRegionId,
          )
        : null;

    for (var y = 0; y < params.height; y++) {
      for (var x = 0; x < params.width; x++) {
        if (grid[y][x] != _landSentinel) {
          // Sea: no terrain, no resource.
          continue;
        }
        final terrain = terrainGrid[y][x];
        if (terrain == null) continue;
        var allowed = Resource.values
            .where(
              (r) =>
                  rules.isAllowedInRegion(r, mapRegionId) &&
                  rules.isAllowedOnTerrain(r, terrain),
            )
            .toList();
        if (allowed.isEmpty) continue;
        // Multi-region cap: when at cap, restrict to region-only where possible.
        if (capState != null && capState.shouldRestrictToRegionOnly(allowed)) {
          allowed = capState.filterToRegionOnly(allowed);
          if (allowed.isEmpty) continue;
        }
        // 40% chance to place any resource on eligible land; then weighted pick.
        if (rnd.nextDouble() > 0.4) continue;
        final weights = allowed.map((r) => rules.spawnWeight(r)).toList();
        final sum = weights.reduce((a, b) => a + b);
        var roll = rnd.nextDouble() * sum;
        for (var i = 0; i < allowed.length; i++) {
          roll -= weights[i];
          if (roll <= 0) {
            final placed = allowed[i];
            resourceGrid[y][x] = placed;
            capState?.record(placed);
            break;
          }
        }
      }
    }

    return (terrainGrid, resourceGrid);
  }

  /// Pass 6a: generate mountain ridges via random walks over land cells.
  void _assignMountainRidges(
    List<List<TerrainType?>> terrainGrid,
    List<List<String>> grid,
    List<(int x, int y)> landCells,
    TerrainDistribution distribution,
    Random rnd,
  ) {
    final totalLand = landCells.length;
    if (totalLand == 0) return;
    final targetMountain = (distribution.mountainFraction * totalLand)
        .round()
        .clamp(0, totalLand);
    if (targetMountain <= 0) return;

    // Determine number of ranges based on target mountain tiles.
    final suggestedRanges = (params.mountainRangesFactor * sqrt(targetMountain))
        .round()
        .clamp(params.mountainRangesMin, params.mountainRangesMax);
    final numRanges = suggestedRanges.clamp(1, targetMountain);
    if (numRanges <= 0) return;

    var remainingMountain = targetMountain;

    // Helper to pick a start cell biased away from edges and existing mountains.
    (int x, int y)? pickStart() {
      const maxAttempts = 1000;
      for (var attempt = 0; attempt < maxAttempts; attempt++) {
        final (cx, cy) = landCells[rnd.nextInt(landCells.length)];
        if (terrainGrid[cy][cx] == TerrainType.mountain) continue;
        // Prefer interior cells (not on border).
        if (cx <= 0 ||
            cx >= params.width - 1 ||
            cy <= 0 ||
            cy >= params.height - 1) {
          // Still acceptable, but try to find interior cells first.
          if (rnd.nextDouble() < 0.7) continue;
        }
        return (cx, cy);
      }
      return null;
    }

    // 4-connected directions: up, right, down, left.
    const directions = <(int dx, int dy)>[(0, -1), (1, 0), (0, 1), (-1, 0)];

    for (var r = 0; r < numRanges && remainingMountain > 0; r++) {
      final start = pickStart();
      if (start == null) break;
      var (x, y) = start;
      terrainGrid[y][x] = TerrainType.mountain;
      remainingMountain--;

      // Target length per range, clipped by remaining budget and minimum.
      final idealLength = (targetMountain / numRanges).round();
      final maxLengthForRange = idealLength.clamp(
        params.mountainRangeMinLength,
        targetMountain,
      );
      var placedThisRange = 1;

      // Initial direction.
      var dir = directions[rnd.nextInt(directions.length)];

      const pForward = 0.6;
      const pTurn = 0.3;
      const maxTurnRetries = 4;

      while (placedThisRange < maxLengthForRange && remainingMountain > 0) {
        // Choose a new direction with persistence.
        (int dx, int dy) pickDirection((int dx, int dy) current) {
          final roll = rnd.nextDouble();
          if (roll < pForward) {
            return current;
          } else if (roll < pForward + pTurn) {
            // Turn left or right relative to current direction.
            final left = (-current.$2, current.$1);
            final right = (current.$2, -current.$1);
            return rnd.nextBool() ? left : right;
          } else {
            return directions[rnd.nextInt(directions.length)];
          }
        }

        var attempts = 0;
        (int nx, int ny)? nextCell;
        while (attempts < maxTurnRetries && nextCell == null) {
          dir = pickDirection(dir);
          final nx = x + dir.$1;
          final ny = y + dir.$2;
          attempts++;
          if (nx < 0 || nx >= params.width || ny < 0 || ny >= params.height) {
            continue;
          }
          if (grid[ny][nx] != _landSentinel) continue;
          if (terrainGrid[ny][nx] == TerrainType.mountain) continue;
          nextCell = (nx, ny);
        }
        if (nextCell == null) {
          // This range is blocked; stop it.
          break;
        }
        (x, y) = nextCell;
        terrainGrid[y][x] = TerrainType.mountain;
        placedThisRange++;
        remainingMountain--;
      }
    }

    // If we significantly undershot the target due to blocking or early
    // termination of ranges, top up mountain tiles by growing existing ridges
    // along their edges. This keeps the overall pattern ridge-like while
    // nudging the global count closer to the configured fraction.
    var currentMountain = 0;
    for (var y = 0; y < params.height; y++) {
      for (var x = 0; x < params.width; x++) {
        if (terrainGrid[y][x] == TerrainType.mountain) currentMountain++;
      }
    }
    if (currentMountain >= targetMountain) {
      return;
    }

    // Prefer to grow from existing mountain fronts into adjacent land.
    final frontier = <(int x, int y)>{};
    for (var y = 0; y < params.height; y++) {
      for (var x = 0; x < params.width; x++) {
        if (terrainGrid[y][x] != TerrainType.mountain) continue;
        for (final (dx, dy) in directions) {
          final nx = x + dx;
          final ny = y + dy;
          if (nx < 0 || nx >= params.width || ny < 0 || ny >= params.height) {
            continue;
          }
          if (grid[ny][nx] != _landSentinel) continue;
          if (terrainGrid[ny][nx] == TerrainType.mountain) continue;
          frontier.add((nx, ny));
        }
      }
    }

    final frontierList = frontier.toList();
    frontierList.shuffle(rnd);
    var idx = 0;
    while (currentMountain < targetMountain && idx < frontierList.length) {
      final (fx, fy) = frontierList[idx++];
      if (terrainGrid[fy][fx] == TerrainType.mountain) continue;
      terrainGrid[fy][fx] = TerrainType.mountain;
      currentMountain++;
    }

    // As a final fallback, if we still undershoot (e.g. very small maps with
    // fragmented land), convert random remaining land cells until we reach
    // the target. This should be rare and only adjusts a handful of tiles.
    if (currentMountain < targetMountain) {
      final remainingLand = <(int x, int y)>[];
      for (var y = 0; y < params.height; y++) {
        for (var x = 0; x < params.width; x++) {
          if (grid[y][x] == _landSentinel &&
              terrainGrid[y][x] != TerrainType.mountain) {
            remainingLand.add((x, y));
          }
        }
      }
      remainingLand.shuffle(rnd);
      var i = 0;
      while (currentMountain < targetMountain && i < remainingLand.length) {
        final (lx, ly) = remainingLand[i++];
        if (terrainGrid[ly][lx] == TerrainType.mountain) continue;
        terrainGrid[ly][lx] = TerrainType.mountain;
        currentMountain++;
      }
    }
  }

  /// Pass 6b: region-growing assignment for non-mountain terrains.
  void _assignNonMountainTerrainsRegionGrowing(
    List<List<TerrainType?>> terrainGrid,
    List<List<String>> grid,
    String mapRegionId,
    TerrainDistribution distribution,
    Random rnd,
  ) {
    // Allowed non-mountain terrains for this region.
    final allowed = allowedTerrainsForRegion(
      mapRegionId,
    ).where((t) => t != TerrainType.mountain).toList();
    if (allowed.isEmpty) return;

    // Collect remaining land cells (not sea, not mountain).
    final remainingLand = <(int x, int y)>[];
    for (var y = 0; y < params.height; y++) {
      for (var x = 0; x < params.width; x++) {
        if (grid[y][x] != _landSentinel) continue;
        if (terrainGrid[y][x] == TerrainType.mountain) continue;
        remainingLand.add((x, y));
      }
    }
    if (remainingLand.isEmpty) return;

    // Split remaining land into connected components (continents) and run the
    // region-growing per component so each continent gets its own mix.
    final components = _connectedComponentsOfLand(remainingLand.toSet());
    if (components.isEmpty) return;

    const directions = <(int dx, int dy)>[(0, -1), (1, 0), (0, 1), (-1, 0)];

    for (final component in components) {
      if (component.isEmpty) continue;
      final cells = component.toList();
      final totalRemaining = cells.length;

      // Per-component targets: same regional fractions, applied to this
      // continent's non-mountain land. Adjust so the sum matches exactly.
      final targets = <TerrainType, int>{};
      int sum = 0;
      for (final t in allowed) {
        final frac = distribution.nonMountainFractions[t] ?? 0.0;
        final n = (frac * totalRemaining).round();
        targets[t] = n;
        sum += n;
      }
      if (sum <= 0) {
        // Fallback: uniform among allowed for this component.
        final int per = (totalRemaining / allowed.length).round();
        targets.clear();
        sum = 0;
        for (final t in allowed) {
          targets[t] = per;
          sum += per;
        }
      }
      final int delta = totalRemaining - sum;
      if (delta != 0) {
        final last = allowed.last;
        targets[last] = (targets[last] ?? 0) + delta;
      }

      // --- Macro phase: coarse blobs ---------------------------------------

      final macroTargets = <TerrainType, int>{};
      final macroRemaining = <TerrainType, int>{};
      for (final t in allowed) {
        final target = targets[t] ?? 0;
        if (target <= 0) continue;
        final macro = max(
          1,
          (target * params.terrainMacroFraction).round().clamp(1, target),
        );
        macroTargets[t] = macro;
        macroRemaining[t] = macro;
      }

      // Seed placement within this component for macro phase.
      final macroQueues = <TerrainType, List<(int x, int y)>>{};
      final availableMacro = List<(int x, int y)>.from(cells);

      for (final t in allowed) {
        final macroTarget = macroTargets[t] ?? 0;
        if (macroTarget <= 0) continue;
        final seedCount = max(
          params.terrainSeedsMin,
          min(
            params.terrainSeedsMax,
            (params.terrainSeedsFactor * sqrt(macroTarget)).round(),
          ),
        );
        final q = <(int x, int y)>[];
        macroQueues[t] = q;

        var placedSeeds = 0;
        while (placedSeeds < seedCount &&
            macroRemaining[t]! > 0 &&
            availableMacro.isNotEmpty) {
          final idx = rnd.nextInt(availableMacro.length);
          final (sx, sy) = availableMacro.removeAt(idx);
          if (terrainGrid[sy][sx] != null) continue;
          terrainGrid[sy][sx] = t;
          q.add((sx, sy));
          macroRemaining[t] = macroRemaining[t]! - 1;
          placedSeeds++;
        }
      }

      bool hasActiveMacroTerrain() {
        for (final t in allowed) {
          final rem = macroRemaining[t] ?? 0;
          final q = macroQueues[t];
          if (rem > 0 && q != null && q.isNotEmpty) return true;
        }
        return false;
      }

      // Macro region-growing loop, restricted to this component's cells.
      final cellSet = component;
      while (hasActiveMacroTerrain()) {
        var totalRem = 0;
        for (final t in allowed) {
          totalRem += macroRemaining[t] ?? 0;
        }
        if (totalRem <= 0) break;
        var roll = rnd.nextInt(totalRem) + 1;
        TerrainType? chosen;
        for (final t in allowed) {
          final rem = macroRemaining[t] ?? 0;
          if (rem <= 0) continue;
          roll -= rem;
          if (roll <= 0) {
            chosen = t;
            break;
          }
        }
        if (chosen == null) break;
        final queue = macroQueues[chosen]!;
        if (queue.isEmpty) continue;

        final (cx, cy) = queue.removeLast();

        final dirs = List<(int dx, int dy)>.from(directions)..shuffle(rnd);
        for (final (dx, dy) in dirs) {
          final nx = cx + dx;
          final ny = cy + dy;
          if (nx < 0 || nx >= params.width || ny < 0 || ny >= params.height) {
            continue;
          }
          if (!cellSet.contains((nx, ny))) continue;
          if (grid[ny][nx] != _landSentinel) continue;
          if (terrainGrid[ny][nx] != null) continue;
          terrainGrid[ny][nx] = chosen;
          macroRemaining[chosen] = macroRemaining[chosen]! - 1;
          queue.add((nx, ny));
          if (macroRemaining[chosen]! <= 0) break;
        }
      }

      // --- Micro phase: fill residual quotas with refinement ---------------

      final residualTargets = <TerrainType, int>{};
      for (final t in allowed) {
        final target = targets[t] ?? 0;
        if (target <= 0) continue;
        final macro = macroTargets[t] ?? 0;
        final usedMacro = macro - (macroRemaining[t] ?? 0);
        final residual = max(0, target - usedMacro);
        if (residual > 0) {
          residualTargets[t] = residual;
        }
      }

      if (residualTargets.isNotEmpty) {
        final microQueues = <TerrainType, List<(int x, int y)>>{};
        final microRemaining = <TerrainType, int>{};
        final availableMicro = <(int x, int y)>[];
        for (final (x, y) in cells) {
          if (terrainGrid[y][x] == null) {
            availableMicro.add((x, y));
          }
        }

        for (final t in allowed) {
          final residual = residualTargets[t] ?? 0;
          if (residual <= 0) continue;
          final seedCount = max(
            params.terrainSeedsMin,
            min(
              params.terrainSeedsMax,
              (params.terrainSeedsFactor * sqrt(residual)).round(),
            ),
          );
          final q = <(int x, int y)>[];
          microQueues[t] = q;
          microRemaining[t] = residual;

          var placedSeeds = 0;
          while (placedSeeds < seedCount &&
              microRemaining[t]! > 0 &&
              availableMicro.isNotEmpty) {
            final idx = rnd.nextInt(availableMicro.length);
            final (sx, sy) = availableMicro.removeAt(idx);
            if (terrainGrid[sy][sx] != null) continue;
            terrainGrid[sy][sx] = t;
            q.add((sx, sy));
            microRemaining[t] = microRemaining[t]! - 1;
            placedSeeds++;
          }
        }

        bool hasActiveMicroTerrain() {
          for (final t in allowed) {
            final rem = microRemaining[t] ?? 0;
            final q = microQueues[t];
            if (rem > 0 && q != null && q.isNotEmpty) return true;
          }
          return false;
        }

        while (hasActiveMicroTerrain()) {
          var totalRem = 0;
          for (final t in allowed) {
            totalRem += microRemaining[t] ?? 0;
          }
          if (totalRem <= 0) break;
          var roll = rnd.nextInt(totalRem) + 1;
          TerrainType? chosen;
          for (final t in allowed) {
            final rem = microRemaining[t] ?? 0;
            if (rem <= 0) continue;
            roll -= rem;
            if (roll <= 0) {
              chosen = t;
              break;
            }
          }
          if (chosen == null) break;
          final queue = microQueues[chosen]!;
          if (queue.isEmpty) continue;

          final (cx, cy) = queue.removeLast();

          final dirs = List<(int dx, int dy)>.from(directions)..shuffle(rnd);
          for (final (dx, dy) in dirs) {
            final nx = cx + dx;
            final ny = cy + dy;
            if (nx < 0 || nx >= params.width || ny < 0 || ny >= params.height) {
              continue;
            }
            if (!cellSet.contains((nx, ny))) continue;
            if (grid[ny][nx] != _landSentinel) continue;
            if (terrainGrid[ny][nx] != null) continue;
            terrainGrid[ny][nx] = chosen;
            microRemaining[chosen] = microRemaining[chosen]! - 1;
            queue.add((nx, ny));
            if (microRemaining[chosen]! <= 0) break;
          }
        }
      }

      // Cleanup within this component: assign any remaining unassigned land
      // cells to neighboring terrains (majority vote), or random fallback.
      for (final (x, y) in cells) {
        if (terrainGrid[y][x] != null) continue;
        final counts = <TerrainType, int>{};
        for (final (dx, dy) in directions) {
          final nx = x + dx;
          final ny = y + dy;
          if (nx < 0 || nx >= params.width || ny < 0 || ny >= params.height) {
            continue;
          }
          if (!cellSet.contains((nx, ny))) continue;
          final t = terrainGrid[ny][nx];
          if (t == null || t == TerrainType.mountain) continue;
          counts[t] = (counts[t] ?? 0) + 1;
        }
        if (counts.isNotEmpty) {
          TerrainType best = counts.keys.first;
          var bestCount = counts[best]!;
          for (final entry in counts.entries) {
            if (entry.value > bestCount) {
              best = entry.key;
              bestCount = entry.value;
            }
          }
          terrainGrid[y][x] = best;
        } else {
          terrainGrid[y][x] = allowed[rnd.nextInt(allowed.length)];
        }
      }

      // Optional pattern refinement phase: carve small pockets of alternate
      // non-mountain terrains inside large blobs, per continent.
      _refineTerrainPatternsInComponent(
        terrainGrid,
        grid,
        component,
        allowed,
        distribution,
        rnd,
      );
    }
  }

  /// Optional Pass 6b pattern refinement: for a given connected land component
  /// (continent), find large blobs of a single non-mountain terrain and carve
  /// small pockets of other non-mountain terrains into their interior while
  /// keeping blob shapes recognizable and overall fractions stable.
  void _refineTerrainPatternsInComponent(
    List<List<TerrainType?>> terrainGrid,
    List<List<String>> grid,
    Set<(int x, int y)> component,
    List<TerrainType> allowedNonMountain,
    TerrainDistribution distribution,
    Random rnd,
  ) {
    if (component.isEmpty || allowedNonMountain.isEmpty) return;

    // Restrict connected-components search to this continent's cells.
    Set<(int x, int y)> cellsOfTerrain(TerrainType t) {
      final out = <(int x, int y)>{};
      for (final (x, y) in component) {
        if (terrainGrid[y][x] == t) {
          out.add((x, y));
        }
      }
      return out;
    }

    // Helper to compute connected blobs within the component for a terrain.
    List<Set<(int x, int y)>> blobsForTerrain(TerrainType t) {
      final cells = cellsOfTerrain(t);
      if (cells.isEmpty) return const [];
      return _connectedComponentsOfLand(cells);
    }

    // Neighbour directions for interior tests and BFS (4-connected).
    const directions = <(int dx, int dy)>[(0, -1), (1, 0), (0, 1), (-1, 0)];

    for (final terrain in allowedNonMountain) {
      final blobs = blobsForTerrain(terrain);
      if (blobs.isEmpty) continue;

      for (final blob in blobs) {
        final size = blob.length;
        if (size < params.patternMinBlobSize) continue;

        // Budget: how many tiles in this blob we may convert away from [terrain].
        final maxChangesForBlob = (params.patternMaxFractionPerBlob * size)
            .floor()
            .clamp(0, size);
        if (maxChangesForBlob <= 0) continue;

        // Identify interior cells: all 4-neighbors are also in this blob.
        final interior = <(int x, int y)>[];
        for (final (x, y) in blob) {
          var isInterior = true;
          for (final (dx, dy) in directions) {
            final nx = x + dx;
            final ny = y + dy;
            if (nx < 0 ||
                nx >= params.width ||
                ny < 0 ||
                ny >= params.height ||
                !blob.contains((nx, ny))) {
              isInterior = false;
              break;
            }
          }
          if (isInterior) {
            interior.add((x, y));
          }
        }
        if (interior.isEmpty) continue;

        // Determine how many seeds to use in this blob.
        final seedCount = max(
          1,
          min(
            params.patternMaxSeedsPerBlob,
            (params.patternSeedFactor * sqrt(size)).round(),
          ),
        ).clamp(1, maxChangesForBlob);

        final interiorShuffled = List<(int x, int y)>.from(interior)
          ..shuffle(rnd);
        final seeds = <(int x, int y, TerrainType target)>[];
        var interiorIndex = 0;

        for (
          var i = 0;
          i < seedCount && interiorIndex < interiorShuffled.length;
          i++
        ) {
          final (sx, sy) = interiorShuffled[interiorIndex++];
          // Choose a target terrain different from the blob terrain, optionally
          // preferring underrepresented terrains according to distribution.
          final options = allowedNonMountain
              .where((t) => t != terrain)
              .toList();
          if (options.isEmpty) break;

          // Weight by desired fraction heuristic (simplified).
          final weights = <double>[];
          for (final t in options) {
            final desired = distribution.nonMountainFractions[t] ?? 0.0;
            weights.add(max(0.0001, desired));
          }
          final total = weights.fold<double>(0, (a, b) => a + b);
          var roll = rnd.nextDouble() * total;
          TerrainType chosen = options.first;
          for (var idx = 0; idx < options.length; idx++) {
            roll -= weights[idx];
            if (roll <= 0) {
              chosen = options[idx];
              break;
            }
          }
          seeds.add((sx, sy, chosen));
        }

        if (seeds.isEmpty) continue;

        var remainingBlobBudget = maxChangesForBlob;

        for (final (sx, sy, target) in seeds) {
          if (remainingBlobBudget <= 0) break;

          var changesForSeed = 0;
          final queue = <(int x, int y, int dist)>[(sx, sy, 0)];
          final visited = <(int, int)>{(sx, sy)};

          while (queue.isNotEmpty &&
              changesForSeed < params.patternMaxChangesPerSeed &&
              remainingBlobBudget > 0) {
            final (cx, cy, dist) = queue.removeAt(0);
            if (dist > params.patternMaxRadius) continue;

            if (grid[cy][cx] == _landSentinel &&
                blob.contains((cx, cy)) &&
                terrainGrid[cy][cx] == terrain) {
              terrainGrid[cy][cx] = target;
              changesForSeed++;
              remainingBlobBudget--;
            }

            if (dist == params.patternMaxRadius) continue;

            for (final (dx, dy) in directions) {
              final nx = cx + dx;
              final ny = cy + dy;
              if (nx < 0 ||
                  nx >= params.width ||
                  ny < 0 ||
                  ny >= params.height) {
                continue;
              }
              final key = (nx, ny);
              if (!blob.contains(key) || visited.contains(key)) continue;
              visited.add(key);
              queue.add((nx, ny, dist + 1));
            }
          }
        }
      }
    }
  }
}
