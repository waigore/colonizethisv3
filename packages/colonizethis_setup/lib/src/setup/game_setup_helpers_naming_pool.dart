// SPEC/program/game-setup-pipeline.md §7c — capital-display / name-pool helpers
// (Refs #4086 Slice C).

import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

const int _kNamingCapitalCollisionSalt = 919_393;
const int _kNamingPoolExhaustedSalt = 271_828;
const int _kNamingHybridExhaustedSalt = 314_159;
const int _kNamingFinalEmptySalt = 161_803;

String namingResolveCapitalDisplayName({
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

({String name, int nextPoolScan}) namingPickNonCapitalPoolName({
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

String namingResolveEmptyPoolNonCapital({
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

void namingAssignProvinceNames({
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
      name = namingResolveCapitalDisplayName(
        capitalName: capitalName,
        rowSalt: rowSalt,
        usedProvinceNames: usedProvinceNames,
        generateFallback: generateFallback,
      );
    } else if (pool.isNotEmpty) {
      final picked = namingPickNonCapitalPoolName(
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
      name = namingResolveEmptyPoolNonCapital(
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

void namingApplyNamingToFaction({
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
  namingAssignProvinceNames(
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
