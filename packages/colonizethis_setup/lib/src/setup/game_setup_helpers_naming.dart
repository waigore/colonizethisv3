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
    _namingApplyNamingToFaction(
      ownedProvinces: ownedProvincesForFaction(
        oldWorldProvinces,
        player.id,
        sorted: false,
      ),
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

/// One minor/tribe faction's resolved naming inputs for the shared
/// non-Great-Power naming pass. [empty] mirrors the prior `namingX.id.isEmpty`
/// branch (no naming entry matched), selecting the procedural-fallback path for
/// the capital name and the `'Territory'` fallback prefix.
typedef _MinorOrTribeNamingEntry = ({
  String factionId,
  String? capitalProvinceId,
  bool empty,
  String displayName,
  List<String> provinceNamePool,
  String fallbackPrefix,
});

/// Shared naming pass for the structurally identical Minor Nation and Tribe
/// province naming. Both previously threaded the always-constant
/// `_namingApplyNamingToFaction` callback and duplicated the
/// `firstWhere(..., orElse: empty)` / capital-name fallback / skip-when-empty
/// shape, differing only in region, faction list, and `fallbackPrefix`.
void _applyMinorOrTribeProvinceNaming({
  required List<_MinorOrTribeNamingEntry> factions,
  required List<Province> regionProvinces,
  required Map<String, Province> regionById,
  required Set<String> usedRegionProvinceNames,
  required int namingSeed,
  required String Function(int seedOffset) fallback,
}) {
  for (final faction in factions) {
    final owned = ownedProvincesForFaction(regionProvinces, faction.factionId);
    if (owned.isEmpty) continue;
    final capitalName = faction.empty
        ? fallback(namingSeed + faction.factionId.hashCode)
        : (faction.provinceNamePool.isNotEmpty
              ? faction.provinceNamePool.first
              : faction.displayName);
    _namingApplyNamingToFaction(
      ownedProvinces: owned,
      capitalProvinceId: faction.capitalProvinceId,
      capitalName: capitalName,
      pool: faction.provinceNamePool,
      fallbackPrefix: faction.fallbackPrefix,
      rngSeed: namingSeed + faction.factionId.hashCode,
      outById: regionById,
      usedInRegion: usedRegionProvinceNames,
      generateFallback: fallback,
    );
  }
}

List<_MinorOrTribeNamingEntry> _minorNationNamingEntries(
  Game game,
  ResolvedNamingConfig naming,
) {
  return [
    for (final minor in game.minorNations)
      () {
        final namingMinor = naming.minorNations.firstWhere(
          (n) => n.id == minor.id,
          orElse: () => const MinorNationNaming(id: '', displayName: ''),
        );
        return (
          factionId: minor.id,
          capitalProvinceId: minor.capitalProvinceId,
          empty: namingMinor.id.isEmpty,
          displayName: namingMinor.displayName,
          provinceNamePool: namingMinor.provinceNamePool,
          fallbackPrefix: namingMinor.id.isEmpty
              ? 'Territory'
              : namingMinor.displayName,
        );
      }(),
  ];
}

List<_MinorOrTribeNamingEntry> _tribeNamingEntries(
  Game game,
  ResolvedNamingConfig naming,
) {
  return [
    for (final tribe in game.tribes)
      () {
        final namingTribe = naming.tribes.firstWhere(
          (n) => n.id == tribe.id,
          orElse: () =>
              const TribeNaming(id: '', displayName: '', provinceNamePool: []),
        );
        return (
          factionId: tribe.id,
          capitalProvinceId: tribe.capitalProvinceId,
          empty: namingTribe.id.isEmpty,
          displayName: namingTribe.displayName,
          provinceNamePool: namingTribe.provinceNamePool,
          fallbackPrefix: namingTribe.id.isEmpty
              ? 'Territory'
              : '${namingTribe.displayName} Territory',
        );
      }(),
  ];
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
  final provincesByRegion = game.worldState.mutableProvinceListsByRegion();
  final owProvinces = provincesByRegion[kRegionOldWorld]!;
  final nwProvinces = provincesByRegion[kRegionNewWorld]!;
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
    fallbackOldWorld: fallbackOw,
  );
  _applyMinorOrTribeProvinceNaming(
    factions: _minorNationNamingEntries(game, naming),
    regionProvinces: owProvinces,
    regionById: owById,
    usedRegionProvinceNames: usedOwProvinceDisplayNames,
    namingSeed: namingSeed,
    fallback: fallbackOw,
  );
  _applyMinorOrTribeProvinceNaming(
    factions: _tribeNamingEntries(game, naming),
    regionProvinces: nwProvinces,
    regionById: nwById,
    usedRegionProvinceNames: usedNwProvinceDisplayNames,
    namingSeed: namingSeed,
    fallback: fallbackNw,
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

  final updatedWorld = game.worldState.mapBothRegions((rid, region) {
    final updatedProvinces = rid == kRegionOldWorld ? owById : nwById;
    return RegionData(
      provinces: updatedProvinces.values.toList()
        ..sort((a, b) => a.id.compareTo(b.id)),
      units: region.units,
    );
  }).copyWith(
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
    'naming applied ow=${updatedWorld.provincesForRegion(kRegionOldWorld).length} '
    'nw=${updatedWorld.provincesForRegion(kRegionNewWorld).length} players=${game.players.length} '
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
