// GP tech-researcher queries for nation-color pennants. Refs #3862.

import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_map/colonizethis_map.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:flutter/material.dart';

import 'package:colonizethis_app_ui_chrome/config/editorial_monocle_palette.dart';

/// Great Powers that have fully unlocked [techId] (`techUnlocked[techId] == true`).
List<Player> gpPlayersWithTechUnlocked(Game game, String techId) {
  return game.players
      .where(
        (player) =>
            isGreatPower(game, player.id) &&
            player.techUnlocked?[techId] == true,
      )
      .toList();
}

/// Orders [researchers] with [contextPlayerId] first (when present), then
/// remaining GPs in `game.players` setup order.
List<Player> orderGpResearchers({
  required List<Player> researchers,
  required String contextPlayerId,
  required Game game,
}) {
  if (researchers.isEmpty) return const [];
  final byId = {for (final player in researchers) player.id: player};
  final ordered = <Player>[];
  final contextPlayer = byId[contextPlayerId];
  if (contextPlayer != null) {
    ordered.add(contextPlayer);
  }
  for (final player in game.players) {
    if (!isGreatPower(game, player.id)) continue;
    if (player.id == contextPlayerId) continue;
    final match = byId[player.id];
    if (match != null) {
      ordered.add(match);
    }
  }
  return ordered;
}

/// Runtime map-ownership RGB for [playerId] (Old World GP palette + overrides).
Color gpMapColorForPlayer(Game game, String playerId) {
  final rgb = factionOwnershipColorMapForOldWorld(
    game,
    greatPowerColorOverride: greatPowerColorOverrideFromGame(game),
  )[playerId];
  if (rgb == null) {
    return EditorialMonoclePalette.muted;
  }
  return Color.fromRGBO(rgb.$1, rgb.$2, rgb.$3, 1);
}
