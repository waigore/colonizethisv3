// SPEC/program/game-setup-pipeline.md §7c — Minor Nation / Tribe province naming
// (Refs #4086 Slice C).

import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

import 'faction_setup_helpers.dart';
import 'game_setup_helpers_naming_pool.dart';
import 'setup_naming_lookup.dart';

/// One minor/tribe faction's resolved naming inputs for the shared
/// non-Great-Power naming pass. [empty] mirrors the prior `namingX.id.isEmpty`
/// branch (no naming entry matched), selecting the procedural-fallback path for
/// the capital name and the `'Territory'` fallback prefix.
typedef MinorOrTribeNamingEntry = ({
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
void applyMinorOrTribeProvinceNaming({
  required List<MinorOrTribeNamingEntry> factions,
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
    namingApplyNamingToFaction(
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

List<MinorOrTribeNamingEntry> minorNationNamingEntries(
  Game game,
  ResolvedNamingConfig naming,
) {
  return [
    for (final minor in game.minorNations)
      () {
        final namingMinor = resolvedMinorNaming(naming, minor.id);
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

List<MinorOrTribeNamingEntry> tribeNamingEntries(
  Game game,
  ResolvedNamingConfig naming,
) {
  return [
    for (final tribe in game.tribes)
      () {
        final namingTribe = resolvedTribeNaming(naming, tribe.id);
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
