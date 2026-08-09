// SPEC/program/game-setup-pipeline.md §7c — Great Power province / player naming
// (Refs #4086 Slice C).

import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

import 'faction_setup_helpers.dart';
import 'game_setup_helpers_naming_pool.dart';

void applyGreatPowerProvinceNaming({
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
    namingApplyNamingToFaction(
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

List<Player> updatedPlayersWithNaming({
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
