/// Row label for tech tree legend samples (maps to [AppLocalizations] state strings).

import 'package:colonizethis_app_l10n/l10n/l10n.dart';
part of 'tech_tree_widget.dart';

class _TechTreeLegend extends StatelessWidget {
  const _TechTreeLegend({required this.game, required this.l10n});

  final Game game;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(l10n.techTree_legendTitle, style: theme.textTheme.labelLarge),
        const SizedBox(height: 4),
        _buildCategoryLegendWrap(),
        CtGap.m,
        _buildStateLegendWrap(),
        CtGap.m,
        _buildGpPennantLegend(context),
      ],
    );
  }

  Widget _buildGpPennantLegend(BuildContext context) {
    final sampleColor = game.players.isNotEmpty
        ? gpMapColorForPlayer(game, game.players.first.id)
        : EditorialMonoclePalette.muted;
    return Wrap(
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: 4,
      runSpacing: 4,
      children: [
        GpNationColorPennant(color: sampleColor, highlighted: true),
        GpNationColorPennant(color: sampleColor),
        Text(
          l10n.techTree_legendGpPennants,
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    );
  }

  Widget _buildCategoryLegendWrap() {
    return Wrap(
      spacing: 8,
      runSpacing: 4,
      children: _categoryColors.entries
          .map(
            (e) => _LegendChip(
              color: e.value,
              label: techCategoryLabelL10n(l10n, e.key),
            ),
          )
          .toList(),
    );
  }

  Widget _buildStateLegendWrap() {
    return Wrap(spacing: 8, runSpacing: 4, children: _stateLegendSamples());
  }

  List<Widget> _stateLegendSamples() {
    return [
      _StateLegendSample(
        game: game,
        kind: _TechLegendStateKind.researched,
        state: const _TechNodeState(
          researched: true,
          inProgress: false,
          available: false,
        ),
      ),
      _StateLegendSample(
        game: game,
        kind: _TechLegendStateKind.inProgress,
        state: const _TechNodeState(
          researched: false,
          inProgress: true,
          available: false,
        ),
      ),
      _StateLegendSample(
        game: game,
        kind: _TechLegendStateKind.available,
        state: const _TechNodeState(
          researched: false,
          inProgress: false,
          available: true,
        ),
      ),
      _StateLegendSample(
        game: game,
        kind: _TechLegendStateKind.locked,
        state: const _TechNodeState(
          researched: false,
          inProgress: false,
          available: false,
        ),
      ),
    ];
  }
}
