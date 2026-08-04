// GP tech-researcher queries for nation-color pennants. Refs #3862.


import 'package:colonizethis_map/colonizethis_map.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:flutter/material.dart';

import 'package:colonizethis_app_ui_chrome/config/editorial_monocle_palette.dart';
import 'package:colonizethis_world/colonizethis_world.dart';
import 'package:colonizethis_orders/colonizethis_orders.dart';
import 'package:colonizethis_turn/colonizethis_turn.dart';
import 'package:colonizethis_combat/colonizethis_combat.dart';
import 'package:colonizethis_diplomacy/colonizethis_diplomacy.dart';
import 'package:colonizethis_economy/colonizethis_economy.dart';
import 'package:colonizethis_setup/colonizethis_setup.dart';
import 'package:colonizethis_logic/order_suggestion_api.dart';
import 'package:colonizethis_logic/ai_api.dart';
import 'package:colonizethis_logic/industry_counsel_api.dart';
import 'package:colonizethis_logic/debug_console_api.dart';
import 'package:colonizethis_orders/src/orders/per_player_work_target_selection_cache.dart';
import 'package:colonizethis_orders/src/orders/civilian_projected_tile.dart';
import 'package:colonizethis_logic/src/turn_to_year.dart';
import 'package:colonizethis_logic/src/civilians/spy_relocate_intel.dart';
import 'package:colonizethis_logic/src/civilians/civilians_missing_work_orders.dart';

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
