part of 'game_setup.dart';

Map<String, String> _buildPoliticalGlyphByPlayerId({
  required Game game,
  required List<String> greatPowerIds,
  required List<String> minorNationIds,
  required List<String> tribeIds,
}) {
  final glyphs = <String, String>{};

  String pickUpperForGp(String name, Set<String> used) {
    final upper = name.toUpperCase();
    for (var i = 0; i < upper.length; i++) {
      final ch = upper[i];
      if (ch.codeUnitAt(0) >= 'A'.codeUnitAt(0) &&
          ch.codeUnitAt(0) <= 'Z'.codeUnitAt(0) &&
          !used.contains(ch)) {
        return ch;
      }
    }
    for (var code = 'A'.codeUnitAt(0); code <= 'Z'.codeUnitAt(0); code++) {
      final ch = String.fromCharCode(code);
      if (!used.contains(ch)) return ch;
    }
    return 'X';
  }

  final usedUpper = <String>{};
  for (final gpId in greatPowerIds) {
    final player = game.players.firstWhere(
      (p) => p.id == gpId,
      orElse: () => game.players.first,
    );
    final glyph = pickUpperForGp(player.displayName, usedUpper);
    glyphs[gpId] = glyph;
    usedUpper.add(glyph);
  }

  final nonGpIds = <String>[...minorNationIds, ...tribeIds]..sort();

  const digitGlyphs = ['1', '2', '3', '4', '5', '6', '7', '8', '9'];
  for (var i = 0; i < nonGpIds.length; i++) {
    String glyph;
    if (i < digitGlyphs.length) {
      glyph = digitGlyphs[i];
    } else {
      final letterIndex = i - digitGlyphs.length;
      final baseCode = 'a'.codeUnitAt(0);
      glyph = String.fromCharCode(baseCode + letterIndex);
    }
    glyphs[nonGpIds[i]] = glyph;
  }

  return glyphs;
}

/// Builds a single topology with prefixed node ids (regionId|localId) and warp edges.
/// SPEC/game/map-topology.md: OW and NW are separate; connectivity across regions only via warp zones.
MapTopology buildCombinedTopology({
  required Map<String, MapTopology> topologyByRegion,
  List<WarpLink> warpLinks = const [],
}) {
  final nodes = <TopologyNode>[];
  final edges = <TopologyEdge>[];
  for (final entry in topologyByRegion.entries) {
    final regionId = entry.key;
    final topo = entry.value;
    for (final n in topo.nodes) {
      nodes.add(
        TopologyNode(id: '$regionId|${n.id}', regionId: regionId, type: n.type),
      );
    }
    for (final e in topo.edges) {
      edges.add(
        TopologyEdge(id1: '$regionId|${e.id1}', id2: '$regionId|${e.id2}'),
      );
    }
  }
  for (final link in warpLinks) {
    edges.add(TopologyEdge(id1: link.prefixedKey, id2: link.otherPrefixedKey));
  }
  return MapTopology(nodes: nodes, edges: edges);
}

List<String> _provinceIdsFromTopology(MapTopology topology) {
  return topology.nodes
      .where((n) => n.type == TopologyNodeType.province)
      .map((n) => n.id)
      .toList();
}

({int x, int y}) _provinceTownCentroidFromTileKeys(List<String> tiles) {
  final c = roundedCentroidFromTileKeys(tiles);
  if (c != null) return c;
  final xy = parseTileKeyCellXY(tiles.first);
  return (x: xy?.$1 ?? 0, y: xy?.$2 ?? 0);
}

int _compareTownTileCandidates(
  String a,
  String b, {
  required int centroidX,
  required int centroidY,
  required Map<String, int> bfsFromCapital,
}) {
  int distSq(String tk) {
    final xy = parseTileKeyCellXY(tk);
    if (xy == null) return 1 << 30;
    final dx = xy.$1 - centroidX;
    final dy = xy.$2 - centroidY;
    return dx * dx + dy * dy;
  }

  final da = distSq(a);
  final db = distSq(b);
  if (da != db) return da.compareTo(db);
  const unreachable = 999999;
  final ba = bfsFromCapital[a] ?? unreachable;
  final bb = bfsFromCapital[b] ?? unreachable;
  if (ba != bb) return ba.compareTo(bb);
  return a.compareTo(b);
}

String _pickTownTileByCentroidAndBfs({
  required List<String> candidates,
  required int centroidX,
  required int centroidY,
  required Map<String, int> bfsFromCapital,
}) {
  var best = candidates.first;
  for (var i = 1; i < candidates.length; i++) {
    final c = candidates[i];
    if (_compareTownTileCandidates(
          c,
          best,
          centroidX: centroidX,
          centroidY: centroidY,
          bfsFromCapital: bfsFromCapital,
        ) <
        0) {
      best = c;
    }
  }
  return best;
}

/// 7d. Province town assignment. For each province, set townTileKey: capital province = capital tile;
/// otherwise branch eligibility (seaboard, same-region BFS, overseas port) then centroid tie-break,
/// then shortest path to capital where applicable, then lexicographic tile key. SPEC/program/game-setup-pipeline.md.
Game _assignProvinceTowns({
  required Game game,
  required Map<String, MapTopology> topologyByRegion,
  required Map<String, TileMapResult> tileMapByRegion,
}) {
  final tileKeysByRegion = game.worldState.tileKeysByRegionAndProvince;
  final ports = game.worldState.portsByProvinceSeaboard;

  // Capital tile key and capital province id per faction (ownerId).
  final capitalTileKeyByOwner = <String, String>{};
  final capitalProvinceIdByOwner = <String, String>{};
  for (final p in game.players) {
    if (p.capitalProvinceId != null && p.capitalTile != null) {
      capitalProvinceIdByOwner[p.id] = p.capitalProvinceId!;
      capitalTileKeyByOwner[p.id] = p.capitalTile!.toTileKey();
    }
  }
  for (final m in game.minorNations) {
    if (m.capitalProvinceId != null && m.capitalTile != null) {
      capitalProvinceIdByOwner[m.id] = m.capitalProvinceId!;
      capitalTileKeyByOwner[m.id] = m.capitalTile!.toTileKey();
    }
  }
  for (final t in game.tribes) {
    if (t.capitalProvinceId != null && t.capitalTile != null) {
      capitalProvinceIdByOwner[t.id] = t.capitalProvinceId!;
      capitalTileKeyByOwner[t.id] = t.capitalTile!.toTileKey();
    }
  }

  // Build (regionId, x, y) -> tileKey for BFS.
  final coordToKey = <String, Map<String, String>>{};
  for (final regionEntry in tileKeysByRegion.entries) {
    final regionId = regionEntry.key;
    final byProvince = regionEntry.value;
    final m = <String, String>{};
    for (final list in byProvince.values) {
      for (final tk in list) {
        final parts = tk.split('|');
        if (parts.length >= 4) {
          final x = parts[2];
          final y = parts[3];
          m['$x|$y'] = tk;
        }
      }
    }
    coordToKey[regionId] = m;
  }

  // BFS from start tile key; returns map tileKey -> distance (in same region).
  Map<String, int> bfsDistances(String regionId, String startTileKey) {
    final result = <String, int>{};
    final parts = startTileKey.split('|');
    if (parts.length < 4) return result;
    final m = coordToKey[regionId];
    if (m == null) return result;
    int x = int.tryParse(parts[2]) ?? 0;
    int y = int.tryParse(parts[3]) ?? 0;
    final queue = <List<dynamic>>[];
    final key = '${parts[2]}|${parts[3]}';
    if (m[key] != null) {
      queue.add([x, y, 0]);
      result[m[key]!] = 0;
    }
    while (queue.isNotEmpty) {
      final item = queue.removeAt(0);
      final cx = item[0] as int;
      final cy = item[1] as int;
      final d = item[2] as int;
      for (final delta in [
        [1, 0],
        [-1, 0],
        [0, 1],
        [0, -1],
      ]) {
        final nx = cx + delta[0];
        final ny = cy + delta[1];
        final nk = '$nx|$ny';
        final tileKey = m[nk];
        if (tileKey != null && !result.containsKey(tileKey)) {
          result[tileKey] = d + 1;
          queue.add([nx, ny, d + 1]);
        }
      }
    }
    return result;
  }

  // Port tile in province (any port whose key starts with provinceId|).
  String? portTileInProvince(String provinceId) {
    for (final entry in ports.entries) {
      if (entry.key.startsWith('$provinceId|')) return entry.value;
    }
    return null;
  }

  Set<String> provinceSeaZones(String provinceId) {
    final regionId = ProvinceId.regionIdFrom(provinceId);
    final topology = topologyByRegion[regionId];
    if (topology == null) return const <String>{};
    final localProvinceId = ProvinceId.localIdFrom(provinceId);
    final out = <String>{};
    for (final edge in topology.edges) {
      if (edge.id1 != localProvinceId && edge.id2 != localProvinceId) continue;
      final other = edge.id1 == localProvinceId ? edge.id2 : edge.id1;
      for (final node in topology.nodes) {
        if (node.id == other && node.type == TopologyNodeType.seaZone) {
          out.add(other);
          break;
        }
      }
    }
    return out;
  }

  bool tileKeyAdjacentToProvinceSeaZone({
    required String tileKey,
    required String provinceId,
    required Set<String> seaZoneIds,
  }) {
    if (seaZoneIds.isEmpty) return false;
    final regionId = ProvinceId.regionIdFrom(provinceId);
    final map = tileMapByRegion[regionId];
    final topology = topologyByRegion[regionId];
    if (map == null || topology == null) return false;
    final parts = tileKey.split('|');
    if (parts.length < 4) return false;
    final x = int.tryParse(parts[2]);
    final y = int.tryParse(parts[3]);
    if (x == null || y == null) return false;

    final provinceIds = topology.nodes
        .where((n) => n.type == TopologyNodeType.province)
        .map((n) => n.id)
        .toSet();

    for (final d in const [(0, -1), (1, 0), (0, 1), (-1, 0)]) {
      final nx = x + d.$1;
      final ny = y + d.$2;
      if (nx < 0 || nx >= map.width || ny < 0 || ny >= map.height) continue;
      final cellId = map.cell(nx, ny);
      if (provinceIds.contains(cellId)) continue;
      if (seaZoneIds.contains(cellId)) return true;
    }
    return false;
  }

  String? townTileKeyForProvince(Province p) {
    final ownerId = p.ownerId;
    final tiles = tileKeysByRegion[p.regionId]?[p.id] ?? [];
    if (ownerId == null) {
      if (tiles.isEmpty) return null;
      final c = _provinceTownCentroidFromTileKeys(tiles);
      return _pickTownTileByCentroidAndBfs(
        candidates: tiles,
        centroidX: c.x,
        centroidY: c.y,
        bfsFromCapital: const {},
      );
    }
    final capProvinceId = capitalProvinceIdByOwner[ownerId];
    final capTileKey = capitalTileKeyByOwner[ownerId];
    if (p.id == capProvinceId && capTileKey != null) return capTileKey;
    if (tiles.isEmpty) return null;
    final centroid = _provinceTownCentroidFromTileKeys(tiles);
    final sameRegion =
        capProvinceId != null &&
        ProvinceId.regionIdFrom(capProvinceId) == p.regionId;
    final regionTopology = topologyByRegion[p.regionId];
    final isSeaBoundProvince =
        regionTopology != null &&
        isProvinceSeaBound(regionTopology, ProvinceId.localIdFrom(p.id));
    if (isSeaBoundProvince) {
      final seaZoneIds = provinceSeaZones(p.id);
      final coastalCandidates = tiles
          .where(
            (tk) => tileKeyAdjacentToProvinceSeaZone(
              tileKey: tk,
              provinceId: p.id,
              seaZoneIds: seaZoneIds,
            ),
          )
          .toList();
      if (coastalCandidates.isNotEmpty) {
        final distances = sameRegion && capTileKey != null
            ? bfsDistances(p.regionId, capTileKey)
            : const <String, int>{};
        return _pickTownTileByCentroidAndBfs(
          candidates: coastalCandidates,
          centroidX: centroid.x,
          centroidY: centroid.y,
          bfsFromCapital: distances,
        );
      }
      _log.w(
        'seaboard town fallback for province=${p.id}: '
        'topology is sea-bound but no sea-zone-adjacent tile candidate found',
      );
    }
    if (sameRegion && capTileKey != null) {
      final distances = bfsDistances(p.regionId, capTileKey);
      return _pickTownTileByCentroidAndBfs(
        candidates: tiles,
        centroidX: centroid.x,
        centroidY: centroid.y,
        bfsFromCapital: distances,
      );
    }
    final portTile = portTileInProvince(p.id);
    if (portTile != null) return portTile;
    return _pickTownTileByCentroidAndBfs(
      candidates: tiles,
      centroidX: centroid.x,
      centroidY: centroid.y,
      bfsFromCapital: const {},
    );
  }

  final oldProvinces = game.worldState.oldWorld.provinces.map((p) {
    final tk = townTileKeyForProvince(p);
    return tk != null ? p.copyWith(townTileKey: tk) : p;
  }).toList();
  final newProvinces = game.worldState.newWorld.provinces.map((p) {
    final tk = townTileKeyForProvince(p);
    return tk != null ? p.copyWith(townTileKey: tk) : p;
  }).toList();

  return game.copyWith(
    worldState: game.worldState.copyWith(
      oldWorld: RegionData(
        provinces: oldProvinces,
        units: game.worldState.oldWorld.units,
      ),
      newWorld: RegionData(
        provinces: newProvinces,
        units: game.worldState.newWorld.units,
      ),
    ),
  );
}

const int _kNamingCapitalCollisionSalt = 919_393;
const int _kNamingPoolExhaustedSalt = 271_828;
const int _kNamingHybridExhaustedSalt = 314_159;
const int _kNamingFinalEmptySalt = 161_803;

String _namingResolveCapitalDisplayName({
  required String capitalName,
  required int rowSalt,
  required Set<String> usedProvinceNames,
  required String Function(int seedOffset) generateFallback,
}) {
  if (capitalName.isEmpty) {
    return generateFallback(rowSalt);
  }
  if (usedProvinceNames.contains(capitalName)) {
    return generateFallback(rowSalt + _kNamingCapitalCollisionSalt);
  }
  usedProvinceNames.add(capitalName);
  return capitalName;
}

({String name, int nextPoolScan}) _namingPickNonCapitalPoolName({
  required List<String> pool,
  required List<int> poolIndices,
  required int poolScan,
  required Set<String> usedProvinceNames,
  required int rowSalt,
  required String Function(int seedOffset) generateFallback,
}) {
  final permLen = poolIndices.length;
  for (var j = 0; j < permLen; j++) {
    final pos = (poolScan + j) % permLen;
    final candidate = pool[poolIndices[pos]];
    if (usedProvinceNames.contains(candidate)) {
      continue;
    }
    usedProvinceNames.add(candidate);
    final nextPoolScan = (poolScan + j + 1) % permLen;
    return (name: candidate, nextPoolScan: nextPoolScan);
  }
  final name = generateFallback(rowSalt + _kNamingPoolExhaustedSalt);
  return (name: name, nextPoolScan: poolScan);
}

String _namingResolveEmptyPoolNonCapital({
  required int rowIndex,
  required int iterationSalt,
  required String fallbackPrefix,
  required Set<String> usedProvinceNames,
  required String Function(int seedOffset) generateFallback,
}) {
  var ordinal = rowIndex + 1;
  var name = '$fallbackPrefix $ordinal';
  if (name.isEmpty) {
    return generateFallback(iterationSalt);
  }
  while (usedProvinceNames.contains(name) && ordinal < 1_000_000) {
    ordinal++;
    name = '$fallbackPrefix $ordinal';
  }
  if (usedProvinceNames.contains(name)) {
    return generateFallback(iterationSalt + _kNamingHybridExhaustedSalt);
  }
  usedProvinceNames.add(name);
  return name;
}

Game _applyNaming({
  required Game game,
  required List<String> selectedGreatPowerIds,
  required Map<String, String> leaderVariantByGpId,
  required int namingSeed,
  required Map<String, MapTopology> topologyByRegion,
}) {
  final naming = defaultNamingConfig;
  final owProvinces = game.worldState.oldWorld.provinces;
  final nwProvinces = game.worldState.newWorld.provinces;
  final owById = {for (final p in owProvinces) p.id: p};
  final nwById = {for (final p in nwProvinces) p.id: p};
  final usedOwProvinceDisplayNames = <String>{};
  final usedNwProvinceDisplayNames = <String>{};
  var proceduralFallbackCount = 0;

  String Function(int seedOffset) fallbackFactory(Set<String> usedInRegion) {
    return (int seedOffset) {
      proceduralFallbackCount++;
      return generateUniqueProvinceName(namingSeed + seedOffset, usedInRegion);
    };
  }

  final fallbackOw = fallbackFactory(usedOwProvinceDisplayNames);
  final fallbackNw = fallbackFactory(usedNwProvinceDisplayNames);

  // Helper: assign names from pool / capital / procedural so that every name
  // is unique within the region's land provinces (SPEC/game/naming.md).
  void assignProvinceNames({
    required List<Province> provinces,
    required String? capitalProvinceId,
    required String capitalName,
    required List<String> pool,
    required String fallbackPrefix,
    required int rngSeed,
    required Set<String> usedProvinceNames,
    required String Function(int seedOffset) generateFallback,
    required Map<String, Province> outById,
  }) {
    if (provinces.isEmpty) return;
    provinces = List.of(provinces)..sort((a, b) => a.id.compareTo(b.id));
    final poolIndices = shuffledPoolIndices(
      poolLength: pool.length,
      seed: rngSeed,
    );
    var poolScan = 0;

    for (var i = 0; i < provinces.length; i++) {
      final p = provinces[i];
      final rowSalt = rngSeed + i;
      final String name;
      if (p.id == capitalProvinceId) {
        name = _namingResolveCapitalDisplayName(
          capitalName: capitalName,
          rowSalt: rowSalt,
          usedProvinceNames: usedProvinceNames,
          generateFallback: generateFallback,
        );
      } else if (pool.isNotEmpty) {
        final picked = _namingPickNonCapitalPoolName(
          pool: pool,
          poolIndices: poolIndices,
          poolScan: poolScan,
          usedProvinceNames: usedProvinceNames,
          rowSalt: rowSalt,
          generateFallback: generateFallback,
        );
        name = picked.name;
        poolScan = picked.nextPoolScan;
      } else {
        name = _namingResolveEmptyPoolNonCapital(
          rowIndex: i,
          iterationSalt: rowSalt,
          fallbackPrefix: fallbackPrefix,
          usedProvinceNames: usedProvinceNames,
          generateFallback: generateFallback,
        );
      }

      final resolved = name.isEmpty
          ? generateFallback(rowSalt + _kNamingFinalEmptySalt)
          : name;
      outById[p.id] = p.copyWith(displayName: resolved);
    }
  }

  // Applies naming to a single faction type with common logic.
  // Handles Great Powers, Minor Nations, and Tribes with their specific naming sources.
  void applyNamingToFaction({
    required List<Province> ownedProvinces,
    required String? capitalProvinceId,
    required String capitalName,
    required List<String> pool,
    required String fallbackPrefix,
    required int rngSeed,
    required Map<String, Province> outById,
    required Set<String> usedInRegion,
    required String Function(int seedOffset) generateFallback,
  }) {
    if (ownedProvinces.isEmpty) return;
    assignProvinceNames(
      provinces: ownedProvinces,
      capitalProvinceId: capitalProvinceId,
      capitalName: capitalName,
      pool: pool,
      fallbackPrefix: fallbackPrefix,
      rngSeed: rngSeed,
      usedProvinceNames: usedInRegion,
      generateFallback: generateFallback,
      outById: outById,
    );
  }

  // Great Powers: capital gets capitalCityName, others from chosen variant's pool. All owned OW provinces are named (no landmass filter).
  for (var i = 0; i < game.players.length; i++) {
    final player = game.players[i];
    if (i >= selectedGreatPowerIds.length) continue;
    final semanticId = selectedGreatPowerIds[i];
    final gpNaming = naming.gpById(semanticId);
    if (gpNaming == null || gpNaming.leaderVariants.isEmpty) continue;
    final variantId =
        leaderVariantByGpId[semanticId] ??
        naming.defaultLeaderVariantId(semanticId);
    final variant = gpNaming.variantById(variantId);
    final capitalProvId = player.capitalProvinceId;
    if (capitalProvId == null) continue;
    final owned = owProvinces.where((p) => p.ownerId == player.id).toList();
    applyNamingToFaction(
      ownedProvinces: owned,
      capitalProvinceId: capitalProvId,
      capitalName: gpNaming.capitalCityName,
      pool: variant.provinceNamePool,
      fallbackPrefix: gpNaming.countryName,
      rngSeed: namingSeed + player.id.hashCode,
      outById: owById,
      usedInRegion: usedOwProvinceDisplayNames,
      generateFallback: fallbackOw,
    );
  }

  // Minor Nations: capital gets first from pool, others random.
  for (var i = 0; i < game.minorNations.length; i++) {
    final minor = game.minorNations[i];
    final namingMinor = naming.minorNations.firstWhere(
      (n) => n.id == minor.id,
      orElse: () => const MinorNationNaming(id: '', displayName: ''),
    );
    final owned = owProvinces.where((p) => p.ownerId == minor.id).toList()
      ..sort((a, b) => a.id.compareTo(b.id));
    if (owned.isEmpty) continue;
    final capitalProvId = minor.capitalProvinceId;
    final capitalName = namingMinor.id.isEmpty
        ? fallbackOw(namingSeed + minor.id.hashCode)
        : (namingMinor.provinceNamePool.isNotEmpty
              ? namingMinor.provinceNamePool.first
              : namingMinor.displayName);
    final fallbackPrefix = namingMinor.id.isEmpty
        ? 'Territory'
        : namingMinor.displayName;
    applyNamingToFaction(
      ownedProvinces: owned,
      capitalProvinceId: capitalProvId,
      capitalName: capitalName,
      pool: namingMinor.provinceNamePool,
      fallbackPrefix: fallbackPrefix,
      rngSeed: namingSeed + minor.id.hashCode,
      outById: owById,
      usedInRegion: usedOwProvinceDisplayNames,
      generateFallback: fallbackOw,
    );
  }

  // Tribes: capital gets first from pool, others random.
  for (var i = 0; i < game.tribes.length; i++) {
    final tribe = game.tribes[i];
    final namingTribe = naming.tribes.firstWhere(
      (n) => n.id == tribe.id,
      orElse: () =>
          const TribeNaming(id: '', displayName: '', provinceNamePool: []),
    );
    final owned = nwProvinces.where((p) => p.ownerId == tribe.id).toList()
      ..sort((a, b) => a.id.compareTo(b.id));
    if (owned.isEmpty) continue;
    final capitalProvId = tribe.capitalProvinceId;
    final capitalName = namingTribe.id.isEmpty
        ? fallbackNw(namingSeed + tribe.id.hashCode)
        : (namingTribe.provinceNamePool.isNotEmpty
              ? namingTribe.provinceNamePool.first
              : namingTribe.displayName);
    final fallbackPrefix = namingTribe.id.isEmpty
        ? 'Territory'
        : '${namingTribe.displayName} Territory';
    applyNamingToFaction(
      ownedProvinces: owned,
      capitalProvinceId: capitalProvId,
      capitalName: capitalName,
      pool: namingTribe.provinceNamePool,
      fallbackPrefix: fallbackPrefix,
      rngSeed: namingSeed + tribe.id.hashCode,
      outById: nwById,
      usedInRegion: usedNwProvinceDisplayNames,
      generateFallback: fallbackNw,
    );
  }

  // Faction display names and leaderKey: GPs get countryName and leaderKey from chosen variant.
  final updatedPlayers = <Player>[];
  for (var i = 0; i < game.players.length; i++) {
    final p = game.players[i];
    if (i >= selectedGreatPowerIds.length) {
      updatedPlayers.add(p);
      continue;
    }
    final semanticId = selectedGreatPowerIds[i];
    final gpNaming = naming.gpById(semanticId);
    if (gpNaming == null || gpNaming.leaderVariants.isEmpty) {
      updatedPlayers.add(p);
      continue;
    }
    final variantId =
        leaderVariantByGpId[semanticId] ??
        naming.defaultLeaderVariantId(semanticId);
    final variant = gpNaming.variantById(variantId);
    updatedPlayers.add(
      p.copyWith(
        displayName: gpNaming.countryName,
        leaderKey: variant.leaderKey,
      ),
    );
  }

  final updatedMinors = game.minorNations.map((m) {
    final namingMinor = naming.minorNations.firstWhere(
      (n) => n.id == m.id,
      orElse: () => const MinorNationNaming(id: '', displayName: ''),
    );
    if (namingMinor.id.isEmpty) return m;
    return m.copyWith(displayName: namingMinor.displayName);
  }).toList();

  final updatedTribes = game.tribes.map((t) {
    final namingTribe = naming.tribes.firstWhere(
      (n) => n.id == t.id,
      orElse: () =>
          const TribeNaming(id: '', displayName: '', provinceNamePool: []),
    );
    if (namingTribe.id.isEmpty) return t;
    return t.copyWith(displayName: namingTribe.displayName);
  }).toList();

  final updatedWorld = game.worldState.copyWith(
    oldWorld: RegionData(
      provinces: owById.values.toList()..sort((a, b) => a.id.compareTo(b.id)),
      units: game.worldState.oldWorld.units,
    ),
    newWorld: RegionData(
      provinces: nwById.values.toList()..sort((a, b) => a.id.compareTo(b.id)),
      units: game.worldState.newWorld.units,
    ),
    seaZoneDisplayNameById: {
      ...buildSeaZoneDisplayNamesForRegion(
        topology: topologyByRegion[kRegionOldWorld] ?? const MapTopology(),
        regionId: kRegionOldWorld,
        namingSeed: namingSeed,
      ),
      ...buildSeaZoneDisplayNamesForRegion(
        topology: topologyByRegion[kRegionNewWorld] ?? const MapTopology(),
        regionId: kRegionNewWorld,
        namingSeed: namingSeed,
      ),
    },
  );

  _log.i(
    'naming applied ow=${updatedWorld.oldWorld.provinces.length} '
    'nw=${updatedWorld.newWorld.provinces.length} players=${game.players.length} '
    'minors=${game.minorNations.length} tribes=${game.tribes.length}',
  );
  if (proceduralFallbackCount > 0) {
    _log.d('naming procedural fallback used count=$proceduralFallbackCount');
  }

  return game.copyWith(
    worldState: updatedWorld,
    players: updatedPlayers,
    minorNations: updatedMinors,
    tribes: updatedTribes,
  );
}

/// Adds starting civilian units for each civilian-owning faction at its capital tile.
Game _addStartingUnits({required Game game, required GameSetupConfig config}) {
  var oldWorldUnits = List<Unit>.from(game.worldState.oldWorld.units);
  var newWorldUnits = List<Unit>.from(game.worldState.newWorld.units);

  Iterable<
    ({
      String id,
      String? capitalProvinceId,
      CapitalTile? capitalTile,
      bool requireCapitalTile,
    })
  >
  civilianOwners() sync* {
    for (final player in game.players) {
      yield (
        id: player.id,
        capitalProvinceId: player.capitalProvinceId,
        capitalTile: player.capitalTile,
        requireCapitalTile: true,
      );
    }
    for (final minor in game.minorNations) {
      yield (
        id: minor.id,
        capitalProvinceId: minor.capitalProvinceId,
        capitalTile: minor.capitalTile,
        requireCapitalTile: false,
      );
    }
    for (final tribe in game.tribes) {
      yield (
        id: tribe.id,
        capitalProvinceId: tribe.capitalProvinceId,
        capitalTile: tribe.capitalTile,
        requireCapitalTile: false,
      );
    }
  }

  for (final owner in civilianOwners()) {
    final ownerId = owner.id;
    final capitalProvinceId = owner.capitalProvinceId;
    final capitalTile = owner.capitalTile;
    if (capitalProvinceId == null || capitalTile == null) {
      if (!owner.requireCapitalTile) {
        continue;
      }
      throw StateError(
        'Cannot spawn starting civilians without capital tile: owner=$ownerId',
      );
    }
    final capitalTileKey = capitalTile.toTileKey();
    final tileProvinceId = Unit.provinceIdFromTileKey(capitalTileKey);
    if (tileProvinceId == null || tileProvinceId != capitalProvinceId) {
      throw StateError(
        'Capital tile/province mismatch for starting civilians: '
        'owner=$ownerId capitalProvinceId=$capitalProvinceId '
        'capitalTileKey=$capitalTileKey',
      );
    }
    final capitalRegionId = ProvinceId.regionIdFrom(capitalProvinceId);

    final unitConfig = config.startingResources.startingCivilianUnits;
    for (final entry in unitConfig.entries) {
      final unitType = entry.key;
      final count = entry.value;

      for (var k = 1; k <= count; k++) {
        final unitId = '${ownerId}_${unitType.toLowerCase()}_$k';
        final unit = Unit(
          id: unitId,
          type: unitType,
          ownerId: ownerId,
          locationProvinceId: capitalProvinceId,
          status: UnitStatus.idle,
          tileKey: capitalTileKey,
        );
        if (capitalRegionId == kRegionOldWorld) {
          oldWorldUnits.add(unit);
        } else {
          newWorldUnits.add(unit);
        }
      }
    }
  }

  return game.copyWith(
    worldState: game.worldState.copyWith(
      oldWorld: RegionData(
        provinces: game.worldState.oldWorld.provinces,
        units: oldWorldUnits,
      ),
      newWorld: RegionData(
        provinces: game.worldState.newWorld.provinces,
        units: newWorldUnits,
      ),
    ),
  );
}

/// Adds starting land regiments and home-fleet ships for each Great Power.
Game _addStartingMilitaryAndNaval({
  required Game game,
  required GameSetupConfig config,
  required MapTopology topologyOldWorld,
}) {
  final starting = config.startingResources;
  final regimentCount = starting.initialMilitaryRegiments;
  final shipCount = starting.initialNavalShips;

  if (regimentCount <= 0 && shipCount <= 0) {
    return game;
  }

  var oldWorldUnits = List<Unit>.from(game.worldState.oldWorld.units);
  var newWorldUnits = List<Unit>.from(game.worldState.newWorld.units);
  var fleets = List<Fleet>.from(game.worldState.fleets);
  var nextSeq = game.worldState.nextShipInstanceSeq;
  final inferredStart = inferNextShipInstanceSeqFromFleets(fleets);
  if (nextSeq < inferredStart) nextSeq = inferredStart;

  for (final player in game.players) {
    final capitalProvinceId = player.capitalProvinceId;
    if (capitalProvinceId == null) continue;

    final regionId = ProvinceId.regionIdFrom(capitalProvinceId);
    final localProvinceId = ProvinceId.localIdFrom(capitalProvinceId);

    // Starting regiments in capital province.
    if (regimentCount > 0) {
      final regimentTypeId = _startingRegimentTypeForPlayer(player);
      for (var i = 0; i < regimentCount; i++) {
        final unitId = '${player.id}_${regimentTypeId}_reg${i + 1}';
        final unit = Unit(
          id: unitId,
          type: regimentTypeId,
          ownerId: player.id,
          locationProvinceId: capitalProvinceId,
          status: UnitStatus.idle,
        );
        if (regionId == kRegionOldWorld) {
          oldWorldUnits.add(unit);
        } else {
          newWorldUnits.add(unit);
        }
      }
    }

    // Starting merchant ships in the home fleet (in port at capital province). SPEC/game/ships-and-naval.md.
    if (shipCount > 0 && regionId == kRegionOldWorld) {
      final fullProvinceId = '$regionId|$localProvinceId';

      final homeFleetId = homeFleetIdFor(player.id);
      final existingIndex = fleets.indexWhere((f) => f.id == homeFleetId);
      final existingFleet = existingIndex >= 0 ? fleets[existingIndex] : null;

      final shipTypeId = _startingShipTypeForPlayer(player);
      final existingShips = existingFleet?.ships ?? const <ShipInstance>[];
      final (seqAfter, newInstances) = mintShipInstances(
        nextShipInstanceSeq: nextSeq,
        typeIds: [for (var i = 0; i < shipCount; i++) shipTypeId],
      );
      nextSeq = seqAfter;

      final homeFleet = Fleet(
        id: homeFleetId,
        ownerId: player.id,
        seaZoneId: null,
        inPortAtProvinceId: fullProvinceId,
        regionId: regionId,
        ships: [...existingShips, ...newInstances],
      );

      if (existingFleet == null) {
        fleets.add(homeFleet);
      } else {
        fleets[existingIndex] = homeFleet;
      }
    }
  }

  return game.copyWith(
    worldState: game.worldState.copyWith(
      oldWorld: RegionData(
        provinces: game.worldState.oldWorld.provinces,
        units: oldWorldUnits,
      ),
      newWorld: RegionData(
        provinces: game.worldState.newWorld.provinces,
        units: newWorldUnits,
      ),
      fleets: fleets,
      nextShipInstanceSeq: nextSeq,
    ),
  );
}

/// Chooses the regiment type used for starting armies.
String _startingRegimentTypeForPlayer(Player player) {
  // Bootstrap default: low-upkeep regiment (SPEC/program/game-setup-pipeline.md §7f).
  const fallbackId = 'peasant_levies';
  final stats = regimentStatsById(fallbackId);
  if (stats != null) return stats.id;
  return regimentCatalog.isNotEmpty ? regimentCatalog.first.id : fallbackId;
}

/// Merchant ship type for starting home fleets (baseline era).
String _startingShipTypeForPlayer(Player _) {
  return ShipEconomyCatalog.carrack.shipTypeId;
}

void _pushUnvisitedPpNeighborsDiag(
  String u,
  Map<String, Set<String>> neighbours,
  Set<String> visited,
  List<String> stack,
) {
  for (final v in neighbours[u] ?? const <String>{}) {
    if (visited.contains(v)) continue;
    stack.add(v);
  }
}

typedef _LmDiag = ({int size, String minProvinceId, Set<String> provinces});

List<_LmDiag> _landmassesSortedDescDiag(Map<String, Set<String>> neighbours) {
  final visited = <String>{};
  final out = <_LmDiag>[];
  for (final start in neighbours.keys.toList()..sort()) {
    if (visited.contains(start)) continue;
    final comp = <String>{};
    final stack = <String>[start];
    while (stack.isNotEmpty) {
      final u = stack.removeLast();
      if (!visited.add(u)) continue;
      comp.add(u);
      _pushUnvisitedPpNeighborsDiag(u, neighbours, visited, stack);
    }
    final minId = comp.reduce((a, b) => a.compareTo(b) < 0 ? a : b);
    out.add((size: comp.length, minProvinceId: minId, provinces: comp));
  }
  out.sort((a, b) {
    final c = b.size.compareTo(a.size);
    if (c != 0) return c;
    return a.minProvinceId.compareTo(b.minProvinceId);
  });
  return out;
}

/// One-line topology summary when locked OW assigner fails (#1834 investigation).
String _lockedOwAssignFailureDiagnostics({
  required GameSetupConfig config,
  required MapTopology topology,
  required List<String> seaBoundIds,
}) {
  final ppNbr = provincePpNeighbours(topology);
  final sizes = ppLandComponentSizesSorted(topology);
  final partitionOk = oldWorldPartitionMatchesLockedProfile(topology);
  final feasibilityOk = lockedOldWorldRoleFeasibilityHolds(
    topology: topology,
    neighbours: ppNbr,
  );
  final lms = _landmassesSortedDescDiag(ppNbr);
  final lmParts = <String>[];
  for (var i = 0; i < lms.length; i++) {
    final lm = lms[i];
    var sea = 0;
    for (final p in lm.provinces) {
      if (isProvinceSeaBound(topology, p)) sea++;
    }
    lmParts.add('i=$i|sz=${lm.size}|sea=$sea|min=${lm.minProvinceId}');
  }
  var degMin = 1 << 30;
  var degMax = 0;
  var degSum = 0;
  for (final pid in ppNbr.keys) {
    final d = ppNbr[pid]?.length ?? 0;
    degSum += d;
    if (d < degMin) degMin = d;
    if (d > degMax) degMax = d;
  }
  final nProv = ppNbr.length;
  final degMean = nProv == 0 ? 0.0 : degSum / nProv;
  const cap = 16;
  final seaSample = seaBoundIds.length <= cap
      ? seaBoundIds.join(',')
      : '${seaBoundIds.take(cap).join(',')}…(+${seaBoundIds.length - cap})';
  return 'lockedOW_diag seed=${config.seed} nodes=${topology.nodes.length} '
      'edges=${topology.edges.length} nProv=$nProv ppSizes=$sizes '
      'partitionOk=$partitionOk feasibilityOk=$feasibilityOk '
      'seaboundCount=${seaBoundIds.length} seaboundSample=[$seaSample] '
      'ppDegMin=$degMin ppDegMax=$degMax ppDegMean=${degMean.toStringAsFixed(2)} '
      'landmasses=[${lmParts.join('; ')}]';
}

/// One-line topology summary when locked NW assigner fails (#1834 investigation).
String _lockedNwAssignFailureDiagnostics({
  required GameSetupConfig config,
  required MapTopology topology,
}) {
  final ppNbr = provincePpNeighbours(topology);
  final sizes = ppLandComponentSizesSorted(topology);
  final partitionOk = newWorldPartitionMatchesLockedProfile(topology);
  final feasibilityOk = lockedNewWorldRoleFeasibilityHolds(
    topology: topology,
    neighbours: ppNbr,
  );
  final lms = _landmassesSortedDescDiag(ppNbr);
  final lmParts = <String>[];
  for (var i = 0; i < lms.length; i++) {
    final lm = lms[i];
    var sea = 0;
    for (final p in lm.provinces) {
      if (isProvinceSeaBound(topology, p)) sea++;
    }
    lmParts.add('i=$i|sz=${lm.size}|sea=$sea|min=${lm.minProvinceId}');
  }
  return 'lockedNW_diag seed=${config.seed} nodes=${topology.nodes.length} '
      'edges=${topology.edges.length} nProv=${ppNbr.length} ppSizes=$sizes '
      'partitionOk=$partitionOk feasibilityOk=$feasibilityOk '
      'landmasses=[${lmParts.join('; ')}]';
}

/// Re-runs §7d province town assignment after the caller mutates provinces or maps.
///
/// For integration tests that need fixtures (e.g. overseas ownership) that
/// [createGameFromGeneratedMaps] does not produce by default.
Game assignProvinceTownsForTesting({
  required Game game,
  required Map<String, MapTopology> topologyByRegion,
  required Map<String, TileMapResult> tileMapByRegion,
}) {
  return _assignProvinceTowns(
    game: game,
    topologyByRegion: topologyByRegion,
    tileMapByRegion: tileMapByRegion,
  );
}
