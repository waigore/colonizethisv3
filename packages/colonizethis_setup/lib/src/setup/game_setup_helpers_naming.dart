// SPEC/program/game-setup-pipeline.md §7c — province/sea-zone naming entry
// (Refs #4086 Slice C topic-split).
import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

import 'package:colonizethis_world/colonizethis_world.dart';
import 'game_setup_context.dart';
import 'game_setup_helpers_naming_gp.dart';
import 'game_setup_helpers_naming_minor_tribe.dart';
import 'province_name_fallback.dart';
import 'setup_naming_lookup.dart';

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

  applyGreatPowerProvinceNaming(
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
  applyMinorOrTribeProvinceNaming(
    factions: minorNationNamingEntries(game, naming),
    regionProvinces: owProvinces,
    regionById: owById,
    usedRegionProvinceNames: usedOwProvinceDisplayNames,
    namingSeed: namingSeed,
    fallback: fallbackOw,
  );
  applyMinorOrTribeProvinceNaming(
    factions: tribeNamingEntries(game, naming),
    regionProvinces: nwProvinces,
    regionById: nwById,
    usedRegionProvinceNames: usedNwProvinceDisplayNames,
    namingSeed: namingSeed,
    fallback: fallbackNw,
  );

  final updatedPlayers = updatedPlayersWithNaming(
    game: game,
    naming: naming,
    selectedGreatPowerIds: selectedGreatPowerIds,
    leaderVariantByGpId: leaderVariantByGpId,
  );

  final updatedMinors = game.minorNations.map((m) {
    final namingMinor = resolvedMinorNaming(naming, m.id);
    if (namingMinor.id.isEmpty) return m;
    return m.copyWith(displayName: namingMinor.displayName);
  }).toList();
  final updatedTribes = game.tribes.map((t) {
    final namingTribe = resolvedTribeNaming(naming, t.id);
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
