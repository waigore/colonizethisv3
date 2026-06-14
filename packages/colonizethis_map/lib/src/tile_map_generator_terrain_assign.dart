/// Pass 6–7: terrain ridges, region-growing, resources.

part of 'tile_map_generator.dart';

class _TileMapGenTerrainResource {
  _TileMapGenTerrainResource(this.params, this._graph);

  final TileMapParams params;
  final TileMapGridGraph _graph;

  (List<List<TerrainType?>>, List<List<Resource?>>) assignTerrainAndResources(
    List<List<String>> grid,
    String mapRegionId,
    ResourceRules rules,
    Random rnd,
  ) {
    final terrainGrid = TileMapGrid.filled<TerrainType?>(
      params.height,
      params.width,
      null,
    );
    final resourceGrid = TileMapGrid.filled<Resource?>(
      params.height,
      params.width,
      null,
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
    final remainingNonMountainLand = _assignMountainRidges(
      terrainGrid,
      grid,
      landCells,
      distribution,
      rnd,
    );

    // Pass 6b: region-growing for non-mountain terrains.
    _assignNonMountainTerrainsRegionGrowing(
      terrainGrid,
      grid,
      mapRegionId,
      distribution,
      rnd,
      remainingNonMountainLand: remainingNonMountainLand,
    );

    // Pass 7: resources, using final terrainGrid and existing rules.
    final capState = (mapRegionId == 'oldWorld' || mapRegionId == 'newWorld')
        ? MultiRegionCapState(
            params.multiRegionResourceCapFraction,
            rules,
            mapRegionId,
          )
        : null;

    for (var y = 0; y < params.height; y++) {
      for (var x = 0; x < params.width; x++) {
        _maybePlaceResourceAtLandCell(
          grid,
          terrainGrid,
          resourceGrid,
          mapRegionId,
          rules,
          capState,
          rnd,
          x,
          y,
        );
      }
    }

    return (terrainGrid, resourceGrid);
  }

  /// Single random-walk step for mountain ridge growth; returns updated
  /// position and direction, or `null` if the range cannot extend further.
  (int x, int y, (int, int) dir)? _extendMountainRandomWalkOnce(
    List<List<TerrainType?>> terrainGrid,
    List<List<String>> grid,
    Random rnd,
    int x,
    int y,
    (int dx, int dy) dir,
    List<(int dx, int dy)> directions,
  ) {
    const pForward = 0.6;
    const pTurn = 0.3;
    const maxTurnRetries = 4;

    (int dx, int dy) pickDirection((int dx, int dy) current) {
      final roll = rnd.nextDouble();
      if (roll < pForward) return current;
      if (roll < pForward + pTurn) {
        final left = (-current.$2, current.$1);
        final right = (current.$2, -current.$1);
        return rnd.nextBool() ? left : right;
      }
      return directions[rnd.nextInt(directions.length)];
    }

    var attempts = 0;
    var d = dir;
    while (attempts < maxTurnRetries) {
      d = pickDirection(d);
      final nx = x + d.$1;
      final ny = y + d.$2;
      attempts++;
      if (nx < 0 || nx >= params.width || ny < 0 || ny >= params.height) {
        continue;
      }
      if (grid[ny][nx] != _landSentinel) continue;
      if (terrainGrid[ny][nx] == TerrainType.mountain) continue;
      return (nx, ny, d);
    }
    return null;
  }

  void _maybePlaceResourceAtLandCell(
    List<List<String>> grid,
    List<List<TerrainType?>> terrainGrid,
    List<List<Resource?>> resourceGrid,
    String mapRegionId,
    ResourceRules rules,
    MultiRegionCapState? capState,
    Random rnd,
    int x,
    int y,
  ) {
    if (grid[y][x] != _landSentinel) return;
    final terrain = terrainGrid[y][x];
    if (terrain == null) return;
    tryPlaceWeightedResourceAtCell(
      resourceGrid: resourceGrid,
      x: x,
      y: y,
      terrain: terrain,
      mapRegionId: mapRegionId,
      rules: rules,
      rnd: rnd,
      capState: capState,
    );
  }

  void _addMountainAdjacentFrontierFromCell(
    int x,
    int y,
    List<List<TerrainType?>> terrainGrid,
    List<List<String>> grid,
    List<(int dx, int dy)> directions,
    Set<(int x, int y)> frontier,
  ) {
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

  /// One full-grid pass after mountain placement: count, ridge-adjacent frontier,
  /// and remaining non-mountain land (Refs #2489 P3).
  ({
    int mountainCount,
    Set<(int x, int y)> mountainAdjacentFrontier,
    List<(int x, int y)> remainingNonMountainLand,
  }) _scanPostMountainLand(
    List<List<TerrainType?>> terrainGrid,
    List<List<String>> grid,
    List<(int dx, int dy)> directions,
  ) {
    var mountainCount = 0;
    final frontier = <(int x, int y)>{};
    final remaining = <(int x, int y)>[];
    for (var y = 0; y < params.height; y++) {
      for (var x = 0; x < params.width; x++) {
        if (grid[y][x] != _landSentinel) continue;
        final terrain = terrainGrid[y][x];
        if (terrain == TerrainType.mountain) {
          mountainCount++;
          _addMountainAdjacentFrontierFromCell(
            x,
            y,
            terrainGrid,
            grid,
            directions,
            frontier,
          );
        } else {
          remaining.add((x, y));
        }
      }
    }
    return (
      mountainCount: mountainCount,
      mountainAdjacentFrontier: frontier,
      remainingNonMountainLand: remaining,
    );
  }

  /// Pass 6a: generate mountain ridges via random walks over land cells.
  /// Returns non-mountain land cells for pass 6b (one scan shared with top-up).
  List<(int x, int y)> _assignMountainRidges(
    List<List<TerrainType?>> terrainGrid,
    List<List<String>> grid,
    List<(int x, int y)> landCells,
    TerrainDistribution distribution,
    Random rnd,
  ) {
    final totalLand = landCells.length;
    if (totalLand == 0) return const [];
    final targetMountain = (distribution.mountainFraction * totalLand)
        .round()
        .clamp(0, totalLand);
    if (targetMountain <= 0) {
      return _nonMountainLandFromCells(landCells, terrainGrid);
    }

    // Determine number of ranges based on target mountain tiles.
    final suggestedRanges = (params.mountainRangesFactor * sqrt(targetMountain))
        .round()
        .clamp(params.mountainRangesMin, params.mountainRangesMax);
    final numRanges = suggestedRanges.clamp(1, targetMountain);
    if (numRanges <= 0) {
      return _nonMountainLandFromCells(landCells, terrainGrid);
    }

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
    const directions = kTileMapDirections4;

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

      var dir = directions[rnd.nextInt(directions.length)];

      while (placedThisRange < maxLengthForRange && remainingMountain > 0) {
        final step = _extendMountainRandomWalkOnce(
          terrainGrid,
          grid,
          rnd,
          x,
          y,
          dir,
          directions,
        );
        if (step == null) break;
        x = step.$1;
        y = step.$2;
        dir = step.$3;
        terrainGrid[y][x] = TerrainType.mountain;
        placedThisRange++;
        remainingMountain--;
      }
    }

    // If we significantly undershot the target due to blocking or early
    // termination of ranges, top up mountain tiles by growing existing ridges
    // along their edges. This keeps the overall pattern ridge-like while
    // nudging the global count closer to the configured fraction.
    var scan = _scanPostMountainLand(terrainGrid, grid, directions);
    var currentMountain = scan.mountainCount;
    if (currentMountain >= targetMountain) {
      return scan.remainingNonMountainLand;
    }

    final frontierList = scan.mountainAdjacentFrontier.toList()..shuffle(rnd);
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
      final remainingLand = scan.remainingNonMountainLand
        ..removeWhere((c) => terrainGrid[c.$2][c.$1] == TerrainType.mountain);
      remainingLand.shuffle(rnd);
      var i = 0;
      while (currentMountain < targetMountain && i < remainingLand.length) {
        final (lx, ly) = remainingLand[i++];
        if (terrainGrid[ly][lx] == TerrainType.mountain) continue;
        terrainGrid[ly][lx] = TerrainType.mountain;
        currentMountain++;
      }
    }

    if (currentMountain > scan.mountainCount) {
      scan.remainingNonMountainLand.removeWhere(
        (c) => terrainGrid[c.$2][c.$1] == TerrainType.mountain,
      );
    }
    return scan.remainingNonMountainLand;
  }

  /// Pass 6b: region-growing assignment for non-mountain terrains.
  void _assignNonMountainTerrainsRegionGrowing(
    List<List<TerrainType?>> terrainGrid,
    List<List<String>> grid,
    String mapRegionId,
    TerrainDistribution distribution,
    Random rnd, {
    required List<(int x, int y)> remainingNonMountainLand,
  }) {
    final allowed = allowedTerrainsForRegion(
      mapRegionId,
    ).where((t) => t != TerrainType.mountain).toList();
    if (allowed.isEmpty) return;

    final remainingLand = remainingNonMountainLand;
    if (remainingLand.isEmpty) return;
    final components = _graph.connectedComponentsOfLand(remainingLand.toSet());
    if (components.isEmpty) return;

    for (final component in components) {
      if (component.isEmpty) continue;
      _assignNonMountainInComponent(
        terrainGrid,
        grid,
        component,
        allowed,
        distribution,
        rnd,
      );
    }
  }

  /// Non-mountain subset of [landCells] (O(|land|); avoids full-grid scan when
  /// mountain ridges are skipped). Refs #2489 (P3).
  List<(int x, int y)> _nonMountainLandFromCells(
    List<(int x, int y)> landCells,
    List<List<TerrainType?>> terrainGrid,
  ) {
    return [
      for (final (x, y) in landCells)
        if (terrainGrid[y][x] != TerrainType.mountain) (x, y),
    ];
  }

  void _assignNonMountainInComponent(
    List<List<TerrainType?>> terrainGrid,
    List<List<String>> grid,
    Set<(int x, int y)> component,
    List<TerrainType> allowed,
    TerrainDistribution distribution,
    Random rnd,
  ) {
    final cells = component.toList();
    final targets = _buildComponentTargets(cells.length, allowed, distribution);
    final macro = _runMacroPhase(
      terrainGrid,
      grid,
      component,
      cells,
      allowed,
      targets,
      rnd,
    );
    _runMicroPhase(
      terrainGrid,
      grid,
      component,
      cells,
      allowed,
      targets,
      macro.$1,
      macro.$2,
      rnd,
    );
    _cleanupUnassignedInComponent(terrainGrid, component, allowed, rnd);
    _refineTerrainPatternsInComponent(
      terrainGrid,
      grid,
      component,
      allowed,
      distribution,
      rnd,
    );
    _applyTerrainNoisePerturbation(
      terrainGrid,
      grid,
      component,
      allowed,
      distribution,
      rnd,
    );
  }

  Map<TerrainType, int> _buildComponentTargets(
    int totalRemaining,
    List<TerrainType> allowed,
    TerrainDistribution distribution,
  ) {
    final targets = <TerrainType, int>{};
    int sum = 0;
    for (final t in allowed) {
      final frac = distribution.nonMountainFractions[t] ?? 0.0;
      final n = (frac * totalRemaining).round();
      targets[t] = n;
      sum += n;
    }
    if (sum <= 0) {
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
    return targets;
  }

  (Map<TerrainType, int>, Map<TerrainType, int>) _runMacroPhase(
    List<List<TerrainType?>> terrainGrid,
    List<List<String>> grid,
    Set<(int x, int y)> component,
    List<(int x, int y)> cells,
    List<TerrainType> allowed,
    Map<TerrainType, int> targets,
    Random rnd,
  ) {
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
    final macroQueues = _seedQueuesForPhase(
      terrainGrid,
      allowed,
      macroTargets,
      macroRemaining,
      cells,
      rnd,
    );
    _growQueuesForPhase(
      terrainGrid,
      grid,
      component,
      allowed,
      macroRemaining,
      macroQueues,
      rnd,
    );
    return (macroTargets, macroRemaining);
  }

  void _runMicroPhase(
    List<List<TerrainType?>> terrainGrid,
    List<List<String>> grid,
    Set<(int x, int y)> component,
    List<(int x, int y)> cells,
    List<TerrainType> allowed,
    Map<TerrainType, int> targets,
    Map<TerrainType, int> macroTargets,
    Map<TerrainType, int> macroRemaining,
    Random rnd,
  ) {
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
    if (residualTargets.isEmpty) return;
    final microRemaining = <TerrainType, int>{...residualTargets};
    final microQueues = _seedQueuesForPhase(
      terrainGrid,
      allowed,
      residualTargets,
      microRemaining,
      cells.where((c) => terrainGrid[c.$2][c.$1] == null).toList(),
      rnd,
    );
    _growQueuesForPhase(
      terrainGrid,
      grid,
      component,
      allowed,
      microRemaining,
      microQueues,
      rnd,
    );
  }

  Map<TerrainType, List<(int x, int y)>> _seedQueuesForPhase(
    List<List<TerrainType?>> terrainGrid,
    List<TerrainType> allowed,
    Map<TerrainType, int> phaseTargets,
    Map<TerrainType, int> phaseRemaining,
    List<(int x, int y)> availableCells,
    Random rnd,
  ) {
    final queues = <TerrainType, List<(int x, int y)>>{};
    final available = List<(int x, int y)>.from(availableCells);
    for (final t in allowed) {
      final target = phaseTargets[t] ?? 0;
      if (target <= 0) continue;
      final seedCount = max(
        params.terrainSeedsMin,
        min(
          params.terrainSeedsMax,
          (params.terrainSeedsFactor * sqrt(target)).round(),
        ),
      );
      final q = <(int x, int y)>[];
      queues[t] = q;
      var placedSeeds = 0;
      while (placedSeeds < seedCount &&
          (phaseRemaining[t] ?? 0) > 0 &&
          available.isNotEmpty) {
        final idx = rnd.nextInt(available.length);
        final (sx, sy) = available.removeAt(idx);
        if (terrainGrid[sy][sx] != null) continue;
        terrainGrid[sy][sx] = t;
        q.add((sx, sy));
        phaseRemaining[t] = (phaseRemaining[t] ?? 0) - 1;
        placedSeeds++;
      }
    }
    return queues;
  }

  void _growQueuesForPhase(
    List<List<TerrainType?>> terrainGrid,
    List<List<String>> grid,
    Set<(int x, int y)> component,
    List<TerrainType> allowed,
    Map<TerrainType, int> remainingByTerrain,
    Map<TerrainType, List<(int x, int y)>> queuesByTerrain,
    Random rnd,
  ) {
    const directions = kTileMapDirections4;
    while (true) {
      var totalRem = 0;
      var hasActive = false;
      for (final t in allowed) {
        final rem = remainingByTerrain[t] ?? 0;
        final q = queuesByTerrain[t];
        totalRem += rem;
        if (rem > 0 && q != null && q.isNotEmpty) {
          hasActive = true;
        }
      }
      if (!hasActive || totalRem <= 0) return;
      var roll = rnd.nextInt(totalRem) + 1;
      TerrainType? chosen;
      for (final t in allowed) {
        final rem = remainingByTerrain[t] ?? 0;
        if (rem <= 0) continue;
        roll -= rem;
        if (roll <= 0) {
          chosen = t;
          break;
        }
      }
      if (chosen == null) return;
      final queue = queuesByTerrain[chosen];
      if (queue == null || queue.isEmpty) continue;
      final (cx, cy) = queue.removeLast();
      final dirs = List<(int dx, int dy)>.from(directions)..shuffle(rnd);
      for (final (dx, dy) in dirs) {
        final nx = cx + dx;
        final ny = cy + dy;
        if (nx < 0 || nx >= params.width || ny < 0 || ny >= params.height) {
          continue;
        }
        if (!component.contains((nx, ny))) continue;
        if (grid[ny][nx] != _landSentinel) continue;
        if (terrainGrid[ny][nx] != null) continue;
        terrainGrid[ny][nx] = chosen;
        remainingByTerrain[chosen] = (remainingByTerrain[chosen] ?? 0) - 1;
        queue.add((nx, ny));
        if ((remainingByTerrain[chosen] ?? 0) <= 0) break;
      }
    }
  }

  void _cleanupUnassignedInComponent(
    List<List<TerrainType?>> terrainGrid,
    Set<(int x, int y)> component,
    List<TerrainType> allowed,
    Random rnd,
  ) {
    for (final (x, y) in component) {
      if (terrainGrid[y][x] != null) continue;
      final counts = _neighborNonMountainCounts(terrainGrid, component, x, y);
      terrainGrid[y][x] = counts.isEmpty
          ? allowed[rnd.nextInt(allowed.length)]
          : _mostFrequentTerrain(counts);
    }
  }

  Map<TerrainType, int> _neighborNonMountainCounts(
    List<List<TerrainType?>> terrainGrid,
    Set<(int x, int y)> component,
    int x,
    int y,
  ) {
    const directions = kTileMapDirections4;
    final counts = <TerrainType, int>{};
    for (final (dx, dy) in directions) {
      final nx = x + dx;
      final ny = y + dy;
      if (nx < 0 || nx >= params.width || ny < 0 || ny >= params.height) {
        continue;
      }
      if (!component.contains((nx, ny))) continue;
      final terrain = terrainGrid[ny][nx];
      if (terrain == null || terrain == TerrainType.mountain) continue;
      counts[terrain] = (counts[terrain] ?? 0) + 1;
    }
    return counts;
  }

  TerrainType _mostFrequentTerrain(Map<TerrainType, int> counts) {
    TerrainType best = counts.keys.first;
    var bestCount = counts[best]!;
    for (final entry in counts.entries) {
      if (entry.value <= bestCount) continue;
      best = entry.key;
      bestCount = entry.value;
    }
    return best;
  }

  Set<(int x, int y)> _componentCellsOfTerrain(
    List<List<TerrainType?>> terrainGrid,
    Set<(int x, int y)> component,
    TerrainType t,
  ) {
    final out = <(int x, int y)>{};
    for (final (x, y) in component) {
      if (terrainGrid[y][x] != t) continue;
      out.add((x, y));
    }
    return out;
  }

  bool _blobCellIsFullyInterior(
    Set<(int x, int y)> blob,
    List<(int dx, int dy)> directions,
    int x,
    int y,
  ) {
    for (final (dx, dy) in directions) {
      final nx = x + dx;
      final ny = y + dy;
      if (nx < 0 || nx >= params.width || ny < 0 || ny >= params.height) {
        return false;
      }
      if (!blob.contains((nx, ny))) return false;
    }
    return true;
  }

  List<(int x, int y)> _interiorCellsOfBlob(
    Set<(int x, int y)> blob,
    List<(int dx, int dy)> directions,
  ) {
    final interior = <(int x, int y)>[];
    for (final (x, y) in blob) {
      if (!_blobCellIsFullyInterior(blob, directions, x, y)) continue;
      interior.add((x, y));
    }
    return interior;
  }

  TerrainType _weightedPickTerrainFromOptions(
    List<TerrainType> options,
    TerrainDistribution distribution,
    Random rnd,
  ) {
    final weights = <double>[];
    for (final t in options) {
      final desired = distribution.nonMountainFractions[t] ?? 0.0;
      weights.add(max(0.0001, desired));
    }
    final total = weights.fold<double>(0, (a, b) => a + b);
    var roll = rnd.nextDouble() * total;
    for (var idx = 0; idx < options.length; idx++) {
      roll -= weights[idx];
      if (roll > 0) continue;
      return options[idx];
    }
    return options.first;
  }

  List<(int x, int y, TerrainType target)> _patternSeedsFromInterior(
    List<(int x, int y)> interiorShuffled,
    int seedCount,
    List<TerrainType> allowedNonMountain,
    TerrainType blobTerrain,
    TerrainDistribution distribution,
    Random rnd,
  ) {
    final seeds = <(int x, int y, TerrainType target)>[];
    var interiorIndex = 0;
    for (
      var i = 0;
      i < seedCount && interiorIndex < interiorShuffled.length;
      i++
    ) {
      final (sx, sy) = interiorShuffled[interiorIndex++];
      final options = allowedNonMountain
          .where((t) => t != blobTerrain)
          .toList();
      if (options.isEmpty) break;
      final chosen = _weightedPickTerrainFromOptions(
        options,
        distribution,
        rnd,
      );
      seeds.add((sx, sy, chosen));
    }
    return seeds;
  }

  /// Returns how many blob tiles were converted (spent from blob budget).
  int _expandPatternSeedInBlob(
    List<List<TerrainType?>> terrainGrid,
    List<List<String>> grid,
    Set<(int x, int y)> blob,
    TerrainType blobTerrain,
    int sx,
    int sy,
    TerrainType target,
    List<(int dx, int dy)> directions,
    int maxBlobBudget,
  ) {
    if (maxBlobBudget <= 0) return 0;
    var spent = 0;
    var changesForSeed = 0;
    final queue = <(int x, int y, int dist)>[(sx, sy, 0)];
    final visited = <(int, int)>{(sx, sy)};

    while (queue.isNotEmpty &&
        changesForSeed < params.patternMaxChangesPerSeed &&
        spent < maxBlobBudget) {
      final (cx, cy, dist) = queue.removeAt(0);
      if (dist > params.patternMaxRadius) continue;

      if (grid[cy][cx] == _landSentinel &&
          blob.contains((cx, cy)) &&
          terrainGrid[cy][cx] == blobTerrain) {
        terrainGrid[cy][cx] = target;
        changesForSeed++;
        spent++;
      }

      if (dist == params.patternMaxRadius) continue;

      for (final (dx, dy) in directions) {
        final nx = cx + dx;
        final ny = cy + dy;
        if (nx < 0 || nx >= params.width || ny < 0 || ny >= params.height) {
          continue;
        }
        final key = (nx, ny);
        if (!blob.contains(key) || visited.contains(key)) continue;
        visited.add(key);
        queue.add((nx, ny, dist + 1));
      }
    }
    return spent;
  }

  void _refineOneTerrainBlobPatterns(
    List<List<TerrainType?>> terrainGrid,
    List<List<String>> grid,
    Set<(int x, int y)> blob,
    TerrainType terrain,
    List<TerrainType> allowedNonMountain,
    TerrainDistribution distribution,
    List<(int dx, int dy)> directions,
    Random rnd,
  ) {
    final size = blob.length;
    if (size < params.patternMinBlobSize) return;

    final maxChangesForBlob = (params.patternMaxFractionPerBlob * size)
        .floor()
        .clamp(0, size);
    if (maxChangesForBlob <= 0) return;

    final interior = _interiorCellsOfBlob(blob, directions);
    if (interior.isEmpty) return;

    final seedCount = max(
      1,
      min(
        params.patternMaxSeedsPerBlob,
        (params.patternSeedFactor * sqrt(size)).round(),
      ),
    ).clamp(1, maxChangesForBlob);

    final interiorShuffled = List<(int x, int y)>.from(interior)..shuffle(rnd);
    final seeds = _patternSeedsFromInterior(
      interiorShuffled,
      seedCount,
      allowedNonMountain,
      terrain,
      distribution,
      rnd,
    );
    if (seeds.isEmpty) return;

    var remainingBlobBudget = maxChangesForBlob;
    for (final (sx, sy, target) in seeds) {
      if (remainingBlobBudget <= 0) break;
      final spent = _expandPatternSeedInBlob(
        terrainGrid,
        grid,
        blob,
        terrain,
        sx,
        sy,
        target,
        directions,
        remainingBlobBudget,
      );
      remainingBlobBudget -= spent;
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

    const directions = kTileMapDirections4;

    for (final terrain in allowedNonMountain) {
      final cells = _componentCellsOfTerrain(terrainGrid, component, terrain);
      if (cells.isEmpty) continue;
      final blobs = _graph.connectedComponentsOfLand(cells);
      if (blobs.isEmpty) continue;

      for (final blob in blobs) {
        _refineOneTerrainBlobPatterns(
          terrainGrid,
          grid,
          blob,
          terrain,
          allowedNonMountain,
          distribution,
          directions,
          rnd,
        );
      }
    }
  }

  // Pass 6b.5 noise perturbation methods live in
  // tile_map_generator_terrain_noise.dart as an extension on this class.
}
