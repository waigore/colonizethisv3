
import 'package:colonizethis_models/colonizethis_models.dart';

import '../../flame/region_map/region_map.dart' show CtMapVisibilityMode;

export 'shell_player_context_provider.dart' show shellPlayerContextProvider;
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

/// Resolved play/observe context for the in-game shell. SPEC/ui/observe-mode.md.
class ShellPlayerContext {
  const ShellPlayerContext({
    required this.effectiveHumanPlayerId,
    required this.viewingPlayerId,
    required this.mapVisibilityMode,
    required this.playerView,
    required this.omniscientDetail,
    required this.showPlayerChrome,
    required this.canMutateViaUi,
    required this.debugCommandTargetPlayerId,
    required this.inObservePhase,
    required this.observeBannerLabel,
    required this.treasuryNotDefined,
    required this.cargoNotDefined,
  });

  /// Global-observe sentinel (`ObserveMode.global`): no viewing GP, full map,
  /// chrome suppressed, mutations disabled. Optional [debugCommandTargetPlayerId]
  /// mirrors `observe.lastControlledPlayerId` in the provider.
  factory ShellPlayerContext.globalObserve({
    String? debugCommandTargetPlayerId,
  }) => ShellPlayerContext(
    effectiveHumanPlayerId: null,
    viewingPlayerId: null,
    mapVisibilityMode: CtMapVisibilityMode.full,
    playerView: null,
    omniscientDetail: true,
    showPlayerChrome: false,
    canMutateViaUi: false,
    debugCommandTargetPlayerId: debugCommandTargetPlayerId,
    inObservePhase: true,
    observeBannerLabel: 'Observing: global',
    treasuryNotDefined: true,
    cargoNotDefined: true,
  );

  final String? effectiveHumanPlayerId;
  final String? viewingPlayerId;
  final CtMapVisibilityMode mapVisibilityMode;
  final PlayerView? playerView;
  final bool omniscientDetail;
  final bool showPlayerChrome;
  final bool canMutateViaUi;
  final String? debugCommandTargetPlayerId;
  final bool inObservePhase;
  final String? observeBannerLabel;
  final bool treasuryNotDefined;
  final bool cargoNotDefined;

  /// Non-null player id for widgets that require a GP id string.
  String mapPlayerIdFor(Game game) =>
      viewingPlayerId ?? effectiveHumanPlayerId ?? game.players.first.id;

  /// GP id for P4–P17 panels; null in global observe (show [kObserveNotDefinedLabel]).
  String? get panelPlayerId => viewingPlayerId ?? effectiveHumanPlayerId;
}

/// Resolves the GP id for player-scoped panels and unit sheets.
String resolveShellPanelPlayerId(ShellPlayerContext shell, Game game) =>
    shell.panelPlayerId ??
    shell.debugCommandTargetPlayerId ??
    shell.mapPlayerIdFor(game);

/// True when P4–P17 should show the global-observe sentinel instead of GP data.
bool shellPanelsNotDefined(ShellPlayerContext shell) => !shell.showPlayerChrome;

/// Faction ids whose map civilians and panel rows are visible for the current shell.
/// SPEC/ui/observe-mode.md, SPEC/ui/map-widget.md.
Set<String> resolveCivilianMarkerOwnerIds(ShellPlayerContext shell, Game game) {
  if (!shell.inObservePhase) {
    final humanId = shell.effectiveHumanPlayerId;
    if (humanId != null && humanId.isNotEmpty) {
      return {humanId};
    }
    return game.players
        .where((player) => player.isHuman)
        .map((player) => player.id)
        .toSet();
  }
  final viewingId = shell.viewingPlayerId;
  if (viewingId != null && viewingId.isNotEmpty) {
    return {viewingId};
  }
  return {
    for (final player in game.players) player.id,
    for (final minor in game.minorNations) minor.id,
    for (final tribe in game.tribes) tribe.id,
  };
}
