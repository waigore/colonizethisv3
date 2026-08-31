import 'package:colonizethis_app_l10n/l10n/l10n.dart';
import 'package:colonizethis_diplomacy/colonizethis_diplomacy.dart'
    show pickUniqueGreatPowerLeaderByPowerScore;
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../config/constants.dart';
import '../../../../providers/victory_panel_session_cache_provider.dart';
import '../../../../widgets/ct_app_perf_interactive_ready_marker.dart';
import 'victory_conditions_block.dart';
import 'victory_end_state_banner.dart';
import 'victory_political_minimap.dart';
import 'victory_screen_keys.dart';
import 'victory_section_card.dart';
import 'victory_standings.dart';
import 'victory_standings_minimap_layout.dart';
import 'victory_standings_section.dart';

class VictoryScreenBody extends ConsumerStatefulWidget {
  const VictoryScreenBody({
    super.key,
    required this.game,
    required this.humanPlayerId,
    this.initialSelectedPlayerId,
  });

  final Game game;
  final String humanPlayerId;

  /// Widgetbook / tests: pre-select a GP other than [humanPlayerId]. Defaults to human on open.
  final String? initialSelectedPlayerId;

  @override
  ConsumerState<VictoryScreenBody> createState() => _VictoryScreenBodyState();
}

class _VictoryScreenBodyState extends ConsumerState<VictoryScreenBody> {
  final Set<String> _expandedPlayerIds = <String>{};
  late String _selectedPlayerId;

  @override
  void initState() {
    super.initState();
    _selectedPlayerId =
        widget.initialSelectedPlayerId ?? widget.humanPlayerId;
  }

  void _selectPlayer(String playerId) {
    if (_selectedPlayerId == playerId) return;
    setState(() => _selectedPlayerId = playerId);
  }

  @override
  Widget build(BuildContext context) {
    final game = widget.game;
    final openPath = ref.watch(victoryPanelOpenPathProvider);
    if (openPath == null) {
      return const SizedBox.shrink();
    }
    final standings = openPath.standings;
    final ownershipColors = openPath.ownershipColors;
    final owRegion = openPath.owRegion;
    final endState = _resolveEndState(game, appL10n(context));
    final textTheme = Theme.of(context).textTheme;

    return CtAppPerfInteractiveReadyMarker(
      markerName: 'victory.interactiveReady',
      child: SingleChildScrollView(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (endState != null)
            VictoryEndStateBanner(
              key: VictoryScreenKeys.endStateBannerKey,
              message: endState,
            ),
          VictorySectionCard(
            key: VictoryScreenKeys.conditionsSectionKey,
            title: 'Victory conditions',
            child: VictoryConditionsBlock(game: game),
          ),
          const SizedBox(height: 8),
          VictoryStandingsMinimapLayout(
            isWide:
                MediaQuery.sizeOf(context).width >= kNarrowBreakpoint &&
                owRegion != null,
            standings: VictoryStandingsSection(
              standings: standings,
              humanPlayerId: widget.humanPlayerId,
              selectedPlayerId: _selectedPlayerId,
              ownershipColors: ownershipColors,
              expandedPlayerIds: _expandedPlayerIds,
              textTheme: textTheme,
              onSelectPlayer: _selectPlayer,
              onToggleExpand: (playerId) {
                setState(() {
                  if (_expandedPlayerIds.contains(playerId)) {
                    _expandedPlayerIds.remove(playerId);
                  } else {
                    _expandedPlayerIds.add(playerId);
                  }
                });
              },
            ),
            minimap: owRegion == null
                ? null
                : VictorySectionCard(
                    key: VictoryScreenKeys.politicalMinimapSectionKey,
                    title: 'Old World political map',
                    child: VictoryPoliticalMinimap(
                      game: game,
                      region: owRegion,
                      selectedPlayerId: _selectedPlayerId,
                      onGreatPowerOwnerSelected: _selectPlayer,
                    ),
                  ),
          ),
        ],
      ),
    ),
    );
  }

  String? _resolveEndState(Game game, AppLocalizations l10n) {
    final victory = game.victory;
    if (victory != null) {
      final winnerName = displayNameForVictoryFaction(
        game,
        victory.winnerPlayerId,
      );
      return l10n.victory_endProvinceCountWin(
        winnerName,
        victory.turnNumber,
      );
    }
    if (game.calendarCampaignHalted) {
      final declaredId = pickUniqueGreatPowerLeaderByPowerScore(game);
      if (declaredId == null) {
        return l10n.victory_endCalendarNoWinner;
      }
      final name = displayNameForVictoryFaction(game, declaredId);
      return l10n.victory_endCalendarDeclaredWinner(name);
    }
    return null;
  }
}
