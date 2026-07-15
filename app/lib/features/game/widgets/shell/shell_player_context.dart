import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../providers/game_service_provider.dart';
import '../../../../providers/games_provider.dart';
import '../../../../providers/observe_session_provider.dart';
import '../../../../core/services/game_service/game_service.dart';
import '../../../../core/services/game_service/try_get_game_map_data.dart';
import '../../flame/region_map/region_map.dart' show CtMapVisibilityMode;

part 'shell_player_context_provider.dart';

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
      viewingPlayerId ??
      effectiveHumanPlayerId ??
      game.players.first.id;

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

MapTopology _topologyForGame(GameService service, Game game) {
  final mapData = tryGetGameMapData(() => service.getMapData(game.id));
  return mapData?.combinedTopology ?? const MapTopology();
}

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
