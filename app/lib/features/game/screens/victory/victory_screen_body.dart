import 'package:colonizethis_app_l10n/l10n/l10n.dart';
import 'package:colonizethis_app_ui_chrome/config/editorial_monocle_palette.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_map/colonizethis_map.dart'
    show factionOwnershipColorMapForOldWorld;
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../config/constants.dart';
import '../../../../core/services/game_service/try_get_game_map_data.dart';
import '../../../../providers/game_service_provider.dart';
import 'victory_political_minimap.dart';
import 'victory_screen_keys.dart';
import 'victory_standings.dart';

class VictoryScreenBody extends ConsumerStatefulWidget {
  const VictoryScreenBody({
    super.key,
    required this.game,
    required this.humanPlayerId,
  });

  final Game game;
  final String humanPlayerId;

  @override
  ConsumerState<VictoryScreenBody> createState() => _VictoryScreenBodyState();
}

class _VictoryScreenBodyState extends ConsumerState<VictoryScreenBody> {
  final Set<String> _expandedPlayerIds = <String>{};
  late String _selectedPlayerId;

  @override
  void initState() {
    super.initState();
    _selectedPlayerId = widget.humanPlayerId;
  }

  void _selectPlayer(String playerId) {
    if (_selectedPlayerId == playerId) return;
    setState(() => _selectedPlayerId = playerId);
  }

  @override
  Widget build(BuildContext context) {
    final game = widget.game;
    final standings = buildVictoryStandings(game);
    final ownershipColors = factionOwnershipColorMapForOldWorld(game);
    final endState = _resolveEndState(game, appL10n(context));
    final textTheme = Theme.of(context).textTheme;
    final mapData = tryGetGameMapData(
      () => ref.read(gameServiceProvider).getMapData(game.id),
    );
    final owRegion = mapData == null
        ? null
        : buildVictoryOldWorldMapViewData(
            game: game,
            tileMapByRegion: mapData.tileMapByRegion,
            topologyByRegion: mapData.topologyByRegion,
          );

    return SingleChildScrollView(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (endState != null)
            _EndStateBanner(
              key: VictoryScreenKeys.endStateBannerKey,
              message: endState,
            ),
          _SectionCard(
            key: VictoryScreenKeys.conditionsSectionKey,
            title: 'Victory conditions',
            child: _ConditionsBlock(game: game),
          ),
          const SizedBox(height: 8),
          _VictoryStandingsMinimapLayout(
            isWide:
                MediaQuery.sizeOf(context).width >= kNarrowBreakpoint &&
                owRegion != null,
            standings: _SectionCard(
              key: VictoryScreenKeys.standingsSectionKey,
              title: 'Great Power standings',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    key: VictoryScreenKeys.standingsHelperKey,
                    appL10n(context).victory_standingsHelper,
                    style: textTheme.bodySmall?.copyWith(
                      color: EditorialMonoclePalette.muted,
                    ),
                  ),
                  const SizedBox(height: 8),
                  for (final row in standings)
                    _StandingRow(
                      key: VictoryScreenKeys.standingRowKey(row.playerId),
                      row: row,
                      isHuman: row.playerId == widget.humanPlayerId,
                      isSelected: row.playerId == _selectedPlayerId,
                      color: _swatchColorFor(ownershipColors, row.playerId),
                      threshold: victoryPanelMilitaryOwThreshold,
                      expanded: _expandedPlayerIds.contains(row.playerId),
                      onSelect: () => _selectPlayer(row.playerId),
                      onToggleExpand: () {
                        setState(() {
                          if (_expandedPlayerIds.contains(row.playerId)) {
                            _expandedPlayerIds.remove(row.playerId);
                          } else {
                            _expandedPlayerIds.add(row.playerId);
                          }
                        });
                      },
                      textTheme: textTheme,
                    ),
                ],
              ),
            ),
            minimap: owRegion == null
                ? null
                : _SectionCard(
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

class _EndStateBanner extends StatelessWidget {
  const _EndStateBanner({super.key, required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: EditorialMonoclePalette.surface,
          border: Border.all(color: EditorialMonoclePalette.accentDim),
        ),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Text(
            message,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: EditorialMonoclePalette.accentBright,
            ),
          ),
        ),
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({
    super.key,
    required this.title,
    required this.child,
  });

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: EditorialMonoclePalette.surface,
        border: Border.all(color: EditorialMonoclePalette.border),
      ),
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: EditorialMonoclePalette.fg,
              ),
            ),
            const SizedBox(height: 8),
            child,
          ],
        ),
      ),
    );
  }
}

class _ConditionsBlock extends StatelessWidget {
  const _ConditionsBlock({required this.game});

  final Game game;

  @override
  Widget build(BuildContext context) {
    final l10n = appL10n(context);
    final threshold = victoryPanelMilitaryOwThreshold;
    final bodyStyle = Theme.of(context).textTheme.bodyMedium?.copyWith(
      color: EditorialMonoclePalette.fg,
    );
    final mutedStyle = bodyStyle?.copyWith(
      color: EditorialMonoclePalette.muted,
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.victory_conditionsMilitaryThreshold(threshold),
          style: bodyStyle?.copyWith(
            color: EditorialMonoclePalette.accentBright,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          l10n.victory_conditionsCalendarEnd,
          style: mutedStyle,
        ),
        if (game.infiniteMode) ...[
          const SizedBox(height: 8),
          Text(
            l10n.victory_conditionsInfiniteMode,
            style: mutedStyle,
          ),
        ],
      ],
    );
  }
}

class _StandingRow extends StatelessWidget {
  const _StandingRow({
    super.key,
    required this.row,
    required this.isHuman,
    required this.isSelected,
    required this.color,
    required this.threshold,
    required this.expanded,
    required this.onSelect,
    required this.onToggleExpand,
    required this.textTheme,
  });

  final VictoryStandingRow row;
  final bool isHuman;
  final bool isSelected;
  final Color color;
  final int threshold;
  final bool expanded;
  final VoidCallback onSelect;
  final VoidCallback onToggleExpand;
  final TextTheme textTheme;

  @override
  Widget build(BuildContext context) {
    final l10n = appL10n(context);
    final titleStyle = textTheme.bodyLarge?.copyWith(
      color: isHuman || isSelected
          ? EditorialMonoclePalette.accentBright
          : EditorialMonoclePalette.fg,
      fontWeight: isHuman || isSelected ? FontWeight.w700 : FontWeight.w500,
    );
    final breakdown = row.powerBreakdown;
    final progress = threshold <= 0
        ? 0.0
        : (row.owProvinceCount / threshold).clamp(0.0, 1.0);
    return Column(
      children: [
        DecoratedBox(
          decoration: BoxDecoration(
            color: isSelected
                ? EditorialMonoclePalette.surfaceLite.withValues(alpha: 0.35)
                : null,
            border: isSelected
                ? Border.all(color: EditorialMonoclePalette.accentDim)
                : null,
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: InkWell(
                  key: VictoryScreenKeys.standingSelectKey(row.playerId),
                  onTap: onSelect,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      vertical: 8,
                      horizontal: 4,
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 12,
                          height: 12,
                          margin: const EdgeInsets.only(top: 4),
                          color: color,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Text(row.displayName, style: titleStyle),
                              const SizedBox(height: 4),
                              Text(
                                l10n.victory_standingOwProgress(
                                  row.owProvinceCount,
                                  threshold,
                                ),
                                style: textTheme.bodySmall?.copyWith(
                                  color: EditorialMonoclePalette.muted,
                                ),
                              ),
                              const SizedBox(height: 4),
                              _VictoryOwProgressBar(
                                key: VictoryScreenKeys.standingProgressKey(
                                  row.playerId,
                                ),
                                progress: progress,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              InkWell(
                key: VictoryScreenKeys.standingExpandKey(row.playerId),
                onTap: onToggleExpand,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(4, 8, 4, 8),
                  child: Icon(
                    expanded ? Icons.expand_less : Icons.expand_more,
                    color: EditorialMonoclePalette.muted,
                    size: 20,
                  ),
                ),
              ),
            ],
          ),
        ),
        if (expanded)
          _VictoryPowerBreakdown(
            key: VictoryScreenKeys.powerBreakdownKey(row.playerId),
            breakdown: breakdown,
            textTheme: textTheme,
          ),
        Divider(height: 1, color: EditorialMonoclePalette.border),
      ],
    );
  }
}

class _VictoryOwProgressBar extends StatelessWidget {
  const _VictoryOwProgressBar({
    super.key,
    required this.progress,
  });

  final double progress;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth * progress;
        return SizedBox(
          height: 6,
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: EditorialMonoclePalette.bgDeep,
              border: Border.all(color: EditorialMonoclePalette.border),
            ),
            child: Align(
              alignment: Alignment.centerLeft,
              child: SizedBox(
                width: width,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: EditorialMonoclePalette.accentBright
                        .withValues(alpha: 0.85),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _VictoryPowerBreakdown extends StatelessWidget {
  const _VictoryPowerBreakdown({
    super.key,
    required this.breakdown,
    required this.textTheme,
  });

  final VictoryPowerScoreBreakdown breakdown;
  final TextTheme textTheme;

  @override
  Widget build(BuildContext context) {
    final l10n = appL10n(context);
    return Padding(
      padding: const EdgeInsets.only(left: 20, bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.victory_powerBreakdownIntro,
            style: textTheme.bodySmall?.copyWith(
              color: EditorialMonoclePalette.muted,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            l10n.victory_powerBreakdownProvinces(breakdown.totalProvinces),
            style: textTheme.bodySmall?.copyWith(
              color: EditorialMonoclePalette.fg,
            ),
          ),
          Text(
            l10n.victory_powerBreakdownRegiments(breakdown.regimentStrength),
            style: textTheme.bodySmall?.copyWith(
              color: EditorialMonoclePalette.fg,
            ),
          ),
          Text(
            l10n.victory_powerBreakdownShips(breakdown.shipCount),
            style: textTheme.bodySmall?.copyWith(
              color: EditorialMonoclePalette.fg,
            ),
          ),
          Text(
            l10n.victory_powerBreakdownTotal(breakdown.totalScore),
            style: textTheme.bodySmall?.copyWith(
              color: EditorialMonoclePalette.fg,
            ),
          ),
        ],
      ),
    );
  }
}

Color _swatchColorFor(
  Map<String, (int r, int g, int b)> ownershipColors,
  String playerId,
) {
  final tuple = ownershipColors[playerId];
  if (tuple == null) {
    return EditorialMonoclePalette.muted;
  }
  return Color.fromRGBO(tuple.$1, tuple.$2, tuple.$3, 1.0);
}

/// Side-by-side standings + minimap on wide viewports when map data exists.
class _VictoryStandingsMinimapLayout extends StatelessWidget {
  const _VictoryStandingsMinimapLayout({
    required this.isWide,
    required this.standings,
    required this.minimap,
  });

  final bool isWide;
  final Widget standings;
  final Widget? minimap;

  @override
  Widget build(BuildContext context) {
    final map = minimap;
    if (map == null) {
      return standings;
    }
    if (isWide) {
      return Row(
        key: VictoryScreenKeys.standingsMinimapWideRowKey,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(child: standings),
          const SizedBox(width: 8),
          Expanded(child: map),
        ],
      );
    }
    return Column(
      key: VictoryScreenKeys.standingsMinimapNarrowColumnKey,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        standings,
        const SizedBox(height: 8),
        map,
      ],
    );
  }
}
