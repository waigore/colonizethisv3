part of 'game_setup_helpers.dart';

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
  if (capitalName.isEmpty) return generateFallback(rowSalt);
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
    if (usedProvinceNames.contains(candidate)) continue;
    usedProvinceNames.add(candidate);
    return (name: candidate, nextPoolScan: (poolScan + j + 1) % permLen);
  }
  return (
    name: generateFallback(rowSalt + _kNamingPoolExhaustedSalt),
    nextPoolScan: poolScan,
  );
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
  if (name.isEmpty) return generateFallback(iterationSalt);
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

void _applyGreatPowerProvinceNaming({
  required Game game,
  required ResolvedNamingConfig naming,
  required List<String> selectedGreatPowerIds,
  required Map<String, String> leaderVariantByGpId,
  required List<Province> oldWorldProvinces,
  required Map<String, Province> oldWorldById,
  required Set<String> usedOldWorldProvinceNames,
  required int namingSeed,
  required void Function({
    required List<Province> ownedProvinces,
    required String? capitalProvinceId,
    required String capitalName,
    required List<String> pool,
    required String fallbackPrefix,
    required int rngSeed,
    required Map<String, Province> outById,
    required Set<String> usedInRegion,
    required String Function(int seedOffset) generateFallback,
  })
  applyNamingToFaction,
  required String Function(int seedOffset) fallbackOldWorld,
}) {
  for (var i = 0; i < game.players.length; i++) {
    if (i >= selectedGreatPowerIds.length) continue;
    final player = game.players[i];
    final semanticId = selectedGreatPowerIds[i];
    final gpNaming = naming.gpById(semanticId);
    if (gpNaming == null || gpNaming.leaderVariants.isEmpty) continue;
    final variantId =
        leaderVariantByGpId[semanticId] ??
        naming.defaultLeaderVariantId(semanticId);
    final variant = gpNaming.variantById(variantId);
    final capitalProvId = player.capitalProvinceId;
    if (capitalProvId == null) continue;
    applyNamingToFaction(
      ownedProvinces: oldWorldProvinces
          .where((p) => p.ownerId == player.id)
          .toList(),
      capitalProvinceId: capitalProvId,
      capitalName: gpNaming.capitalCityName,
      pool: variant.provinceNamePool,
      fallbackPrefix: gpNaming.countryName,
      rngSeed: namingSeed + player.id.hashCode,
      outById: oldWorldById,
      usedInRegion: usedOldWorldProvinceNames,
      generateFallback: fallbackOldWorld,
    );
  }
}

void _applyMinorNationProvinceNaming({
  required Game game,
  required ResolvedNamingConfig naming,
  required List<Province> oldWorldProvinces,
  required Map<String, Province> oldWorldById,
  required Set<String> usedOldWorldProvinceNames,
  required int namingSeed,
  required void Function({
    required List<Province> ownedProvinces,
    required String? capitalProvinceId,
    required String capitalName,
    required List<String> pool,
    required String fallbackPrefix,
    required int rngSeed,
    required Map<String, Province> outById,
    required Set<String> usedInRegion,
    required String Function(int seedOffset) generateFallback,
  })
  applyNamingToFaction,
  required String Function(int seedOffset) fallbackOldWorld,
}) {
  for (final minor in game.minorNations) {
    final namingMinor = naming.minorNations.firstWhere(
      (n) => n.id == minor.id,
      orElse: () => const MinorNationNaming(id: '', displayName: ''),
    );
    final owned = oldWorldProvinces.where((p) => p.ownerId == minor.id).toList()
      ..sort((a, b) => a.id.compareTo(b.id));
    if (owned.isEmpty) continue;
    final capitalName = namingMinor.id.isEmpty
        ? fallbackOldWorld(namingSeed + minor.id.hashCode)
        : (namingMinor.provinceNamePool.isNotEmpty
              ? namingMinor.provinceNamePool.first
              : namingMinor.displayName);
    applyNamingToFaction(
      ownedProvinces: owned,
      capitalProvinceId: minor.capitalProvinceId,
      capitalName: capitalName,
      pool: namingMinor.provinceNamePool,
      fallbackPrefix: namingMinor.id.isEmpty
          ? 'Territory'
          : namingMinor.displayName,
      rngSeed: namingSeed + minor.id.hashCode,
      outById: oldWorldById,
      usedInRegion: usedOldWorldProvinceNames,
      generateFallback: fallbackOldWorld,
    );
  }
}

void _applyTribeProvinceNaming({
  required Game game,
  required ResolvedNamingConfig naming,
  required List<Province> newWorldProvinces,
  required Map<String, Province> newWorldById,
  required Set<String> usedNewWorldProvinceNames,
  required int namingSeed,
  required void Function({
    required List<Province> ownedProvinces,
    required String? capitalProvinceId,
    required String capitalName,
    required List<String> pool,
    required String fallbackPrefix,
    required int rngSeed,
    required Map<String, Province> outById,
    required Set<String> usedInRegion,
    required String Function(int seedOffset) generateFallback,
  })
  applyNamingToFaction,
  required String Function(int seedOffset) fallbackNewWorld,
}) {
  for (final tribe in game.tribes) {
    final namingTribe = naming.tribes.firstWhere(
      (n) => n.id == tribe.id,
      orElse: () =>
          const TribeNaming(id: '', displayName: '', provinceNamePool: []),
    );
    final owned = newWorldProvinces.where((p) => p.ownerId == tribe.id).toList()
      ..sort((a, b) => a.id.compareTo(b.id));
    if (owned.isEmpty) continue;
    final capitalName = namingTribe.id.isEmpty
        ? fallbackNewWorld(namingSeed + tribe.id.hashCode)
        : (namingTribe.provinceNamePool.isNotEmpty
              ? namingTribe.provinceNamePool.first
              : namingTribe.displayName);
    applyNamingToFaction(
      ownedProvinces: owned,
      capitalProvinceId: tribe.capitalProvinceId,
      capitalName: capitalName,
      pool: namingTribe.provinceNamePool,
      fallbackPrefix: namingTribe.id.isEmpty
          ? 'Territory'
          : '${namingTribe.displayName} Territory',
      rngSeed: namingSeed + tribe.id.hashCode,
      outById: newWorldById,
      usedInRegion: usedNewWorldProvinceNames,
      generateFallback: fallbackNewWorld,
    );
  }
}

List<Player> _updatedPlayersWithNaming({
  required Game game,
  required ResolvedNamingConfig naming,
  required List<String> selectedGreatPowerIds,
  required Map<String, String> leaderVariantByGpId,
}) {
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
  return updatedPlayers;
}

void _namingAssignProvinceNames({
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
  final sorted = List.of(provinces)..sort((a, b) => a.id.compareTo(b.id));
  final poolIndices = shuffledPoolIndices(
    poolLength: pool.length,
    seed: rngSeed,
  );
  var poolScan = 0;

  for (var i = 0; i < sorted.length; i++) {
    final p = sorted[i];
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
    outById[p.id] = p.copyWith(
      displayName: name.isEmpty
          ? generateFallback(rowSalt + _kNamingFinalEmptySalt)
          : name,
    );
  }
}

void _namingApplyNamingToFaction({
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
  _namingAssignProvinceNames(
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

Game applyNaming({
  required Game game,
  required List<String> selectedGreatPowerIds,
  required Map<String, String> leaderVariantByGpId,
  required int namingSeed,
  required Map<String, MapTopology> topologyByRegion,
}) {
  final naming = defaultNamingConfig;
  final owProvinces = List<Province>.from(game.worldState.oldWorld.provinces);
  final nwProvinces = List<Province>.from(game.worldState.newWorld.provinces);
  final owById = <String, Province>{for (final p in owProvinces) p.id: p};
  final nwById = <String, Province>{for (final p in nwProvinces) p.id: p};
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

  _applyGreatPowerProvinceNaming(
    game: game,
    naming: naming,
    selectedGreatPowerIds: selectedGreatPowerIds,
    leaderVariantByGpId: leaderVariantByGpId,
    oldWorldProvinces: owProvinces,
    oldWorldById: owById,
    usedOldWorldProvinceNames: usedOwProvinceDisplayNames,
    namingSeed: namingSeed,
    applyNamingToFaction: _namingApplyNamingToFaction,
    fallbackOldWorld: fallbackOw,
  );
  _applyMinorNationProvinceNaming(
    game: game,
    naming: naming,
    oldWorldProvinces: owProvinces,
    oldWorldById: owById,
    usedOldWorldProvinceNames: usedOwProvinceDisplayNames,
    namingSeed: namingSeed,
    applyNamingToFaction: _namingApplyNamingToFaction,
    fallbackOldWorld: fallbackOw,
  );
  _applyTribeProvinceNaming(
    game: game,
    naming: naming,
    newWorldProvinces: nwProvinces,
    newWorldById: nwById,
    usedNewWorldProvinceNames: usedNwProvinceDisplayNames,
    namingSeed: namingSeed,
    applyNamingToFaction: _namingApplyNamingToFaction,
    fallbackNewWorld: fallbackNw,
  );

  final updatedPlayers = _updatedPlayersWithNaming(
    game: game,
    naming: naming,
    selectedGreatPowerIds: selectedGreatPowerIds,
    leaderVariantByGpId: leaderVariantByGpId,
  );

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

  gameSetupLog.i(
    'naming applied ow=${updatedWorld.oldWorld.provinces.length} '
    'nw=${updatedWorld.newWorld.provinces.length} players=${game.players.length} '
    'minors=${game.minorNations.length} tribes=${game.tribes.length}',
  );
  if (proceduralFallbackCount > 0) {
    gameSetupLog.d(
      'naming procedural fallback used count=$proceduralFallbackCount',
    );
  }

  return game.copyWith(
    worldState: updatedWorld,
    players: updatedPlayers,
    minorNations: updatedMinors,
    tribes: updatedTribes,
  );
}
