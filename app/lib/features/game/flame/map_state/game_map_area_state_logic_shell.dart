import 'package:colonizethis_data/colonizethis_data.dart';

import 'package:colonizethis_models/colonizethis_models.dart' as ct_models;
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

/// Resolved mount-time / home-to-capital auto-center target for the in-game
/// shell. SPEC/ui/empire-overview.md § Initial map viewport (shell entry).
class ShellEntryAutoCenter {
  const ShellEntryAutoCenter({
    required this.tileKey,
    required this.regionIndex,
  });

  /// Capital tile key (`regionId|localId|x|y`) to center on and highlight.
  final String tileKey;

  /// Region tab index for the capital region (`0` oldWorld, `1` newWorld).
  final int regionIndex;
}

/// Shell-entry and turn-resolution gating helpers for [GameMapAreaStateLogic].
class GameMapAreaStateLogicShell {
  GameMapAreaStateLogicShell._();

  /// Full turn resolution is a no-op once military [Game.victory] is set or the
  /// campaign calendar cap has been reached ([Game.calendarCampaignHalted]).
  /// SPEC/game/victory.md § UI blocking.
  static bool allowsFullTurnResolution(ct_models.Game game) {
    return !game.calendarCampaignHalted && game.victory == null;
  }

  static int regionIndexFromWorldRegionId(String regionId) {
    if (regionId == kRegionNewWorld) return 1;
    return 0; // oldWorld (default)
  }

  /// Resolves the in-game shell auto-center target for [currentPlayerId].
  ///
  /// Returns `null` when auto-center must be skipped: [currentPlayerId] is
  /// `null` (global observe has no viewing player) or that player has no
  /// `capitalTile`. SPEC/ui/empire-overview.md § Initial map viewport.
  static ShellEntryAutoCenter? resolveShellEntryAutoCenter({
    required ct_models.Game game,
    required String? currentPlayerId,
  }) {
    if (currentPlayerId == null) {
      return null;
    }
    final capital = game.playerById(currentPlayerId)?.capitalTile;
    if (capital == null) {
      return null;
    }
    return ShellEntryAutoCenter(
      tileKey: capital.toTileKey(),
      regionIndex: regionIndexFromWorldRegionId(capital.regionId),
    );
  }

  /// Work-target tile translation hook for assignment flows.
  ///
  /// Civilian draft projection and locate use exact assigned tile keys for every
  /// work target, so no target-specific tile normalization is applied here.
  static String translateWorkTargetTileKey({
    required String tileKey,
    required String workTarget,
  }) {
    if (workTarget.isEmpty) return tileKey;
    return tileKey;
  }
}
