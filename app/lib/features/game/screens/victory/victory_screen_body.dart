import 'package:colonizethis_app_ui_chrome/config/editorial_monocle_palette.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_map/colonizethis_map.dart'
    show factionOwnershipColorMapForOldWorld;
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:flutter/material.dart';

import 'victory_screen_keys.dart';
import 'victory_standings.dart';

class VictoryScreenBody extends StatefulWidget {
  const VictoryScreenBody({
    super.key,
    required this.game,
    required this.humanPlayerId,
  });

  final Game game;
  final String humanPlayerId;

  @override
  State<VictoryScreenBody> createState() => _VictoryScreenBodyState();
}

class _VictoryScreenBodyState extends State<VictoryScreenBody> {
  final Set<String> _expandedPlayerIds = <String>{};

  @override
  Widget build(BuildContext context) {
    final game = widget.game;
    final standings = buildVictoryStandings(game);
    final ownershipColors = factionOwnershipColorMapForOldWorld(game);
    final endState = _resolveEndState(game);
    final textTheme = Theme.of(context).textTheme;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
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
          const SizedBox(height: 12),
          _SectionCard(
            key: VictoryScreenKeys.standingsSectionKey,
            title: 'Great Power standings',
            child: Column(
              children: [
                for (final row in standings)
                  _StandingRow(
                    key: VictoryScreenKeys.standingRowKey(row.playerId),
                    row: row,
                    isHuman: row.playerId == widget.humanPlayerId,
                    color: _swatchColorFor(ownershipColors, row.playerId),
                    expanded: _expandedPlayerIds.contains(row.playerId),
                    onToggle: () {
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
        ],
      ),
    );
  }

  String? _resolveEndState(Game game) {
    final victory = game.victory;
    if (victory != null) {
      final winnerName = displayNameForVictoryFaction(
        game,
        victory.winnerPlayerId,
      );
      return 'Military victory: $winnerName won on turn ${victory.turnNumber}.';
    }
    if (game.calendarCampaignHalted) {
      final declaredId = pickUniqueGreatPowerLeaderByPowerScore(game);
      if (declaredId == null) {
        return 'Calendar campaign ended with no declared winner (tie or no scorer).';
      }
      final name = displayNameForVictoryFaction(game, declaredId);
      return 'Calendar campaign ended. Declared winner by power score: $name.';
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
      padding: const EdgeInsets.only(bottom: 12),
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
        padding: const EdgeInsets.all(12),
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
          'Military victory: control $threshold or more Old World provinces.',
          style: bodyStyle?.copyWith(
            color: EditorialMonoclePalette.accentBright,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Calendar campaign end: without military victory, the campaign can '
          'halt near 1800 (turn 201 under the default calendar). The declared '
          'winner is the Great Power with the strictly highest power score, or '
          'no-one on a tie. This is not a military victory.',
          style: mutedStyle,
        ),
        if (game.infiniteMode) ...[
          const SizedBox(height: 8),
          Text(
            'Infinite mode is on: the calendar halt is bypassed. Only military '
            'victory or leaving the campaign ends play.',
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
    required this.color,
    required this.expanded,
    required this.onToggle,
    required this.textTheme,
  });

  final VictoryStandingRow row;
  final bool isHuman;
  final Color color;
  final bool expanded;
  final VoidCallback onToggle;
  final TextTheme textTheme;

  @override
  Widget build(BuildContext context) {
    final titleStyle = textTheme.bodyLarge?.copyWith(
      color: isHuman
          ? EditorialMonoclePalette.accentBright
          : EditorialMonoclePalette.fg,
      fontWeight: isHuman ? FontWeight.w700 : FontWeight.w500,
    );
    final breakdown = row.powerBreakdown;
    return Column(
      children: [
        InkWell(
          onTap: onToggle,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Row(
              children: [
                Container(
                  width: 12,
                  height: 12,
                  color: color,
                ),
                const SizedBox(width: 8),
                Expanded(child: Text(row.displayName, style: titleStyle)),
                Text(
                  '${row.owProvinceCount} OW',
                  style: textTheme.bodyMedium?.copyWith(
                    color: EditorialMonoclePalette.fg,
                  ),
                ),
                Icon(
                  expanded ? Icons.expand_less : Icons.expand_more,
                  key: VictoryScreenKeys.standingExpandKey(row.playerId),
                  color: EditorialMonoclePalette.muted,
                  size: 20,
                ),
              ],
            ),
          ),
        ),
        if (expanded)
          Padding(
            key: VictoryScreenKeys.powerBreakdownKey(row.playerId),
            padding: const EdgeInsets.only(left: 20, bottom: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Power score ${breakdown.totalScore} (comparison / calendar '
                  'declared winner only — not the military victory meter).',
                  style: textTheme.bodySmall?.copyWith(
                    color: EditorialMonoclePalette.muted,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Provinces (all worlds): ${breakdown.totalProvinces} × '
                  '$powerScoreProvinceWeight = ${breakdown.provincePoints}',
                  style: textTheme.bodySmall?.copyWith(
                    color: EditorialMonoclePalette.fg,
                  ),
                ),
                Text(
                  'Regiment strength: ${breakdown.regimentStrength} × '
                  '$powerScoreRegimentWeight = ${breakdown.regimentPoints}',
                  style: textTheme.bodySmall?.copyWith(
                    color: EditorialMonoclePalette.fg,
                  ),
                ),
                Text(
                  'Ships: ${breakdown.shipCount} × $powerScoreShipWeight = '
                  '${breakdown.shipPoints}',
                  style: textTheme.bodySmall?.copyWith(
                    color: EditorialMonoclePalette.fg,
                  ),
                ),
              ],
            ),
          ),
        Divider(height: 1, color: EditorialMonoclePalette.border),
      ],
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
