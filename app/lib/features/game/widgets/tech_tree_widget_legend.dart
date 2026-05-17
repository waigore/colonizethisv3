/// Row label for tech tree legend samples (maps to [AppLocalizations] state strings).

part of 'tech_tree_widget.dart';

enum _TechLegendStateKind { researched, inProgress, available, locked }

class _TechTreeLegend extends StatelessWidget {
  const _TechTreeLegend({required this.l10n});

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
        const SizedBox(height: 8),
        _buildStateLegendWrap(),
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
    return const [
      _StateLegendSample(
        kind: _TechLegendStateKind.researched,
        state: _TechNodeState(
          researched: true,
          inProgress: false,
          available: false,
        ),
      ),
      _StateLegendSample(
        kind: _TechLegendStateKind.inProgress,
        state: _TechNodeState(
          researched: false,
          inProgress: true,
          available: false,
        ),
      ),
      _StateLegendSample(
        kind: _TechLegendStateKind.available,
        state: _TechNodeState(
          researched: false,
          inProgress: false,
          available: true,
        ),
      ),
      _StateLegendSample(
        kind: _TechLegendStateKind.locked,
        state: _TechNodeState(
          researched: false,
          inProgress: false,
          available: false,
        ),
      ),
    ];
  }
}

class _LegendChip extends StatelessWidget {
  const _LegendChip({required this.color, required this.label});

  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Chip(
      label: Text(label),
      backgroundColor: color.withValues(alpha: 0.2),
      side: BorderSide(color: color, width: 1.5),
      labelStyle: Theme.of(context).textTheme.bodySmall,
      visualDensity: VisualDensity.compact,
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
    );
  }
}

class _StateLegendSample extends StatelessWidget {
  const _StateLegendSample({required this.kind, required this.state});

  final _TechLegendStateKind kind;
  final _TechNodeState state;

  @override
  Widget build(BuildContext context) {
    final l10n = appL10n(context);
    // Use a dummy tech with neutral category just to render the style.
    const dummyTech = TechDefinition(
      id: 'legend_dummy',
      era: 1,
      category: 'gathering',
      cost: 0,
      prerequisiteIds: <String>[],
      regimentUnlockIds: <String>[],
      shipUnlockIds: <String>[],
    );

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: 72,
          height: 24,
          child: _TechNode(tech: dummyTech, state: state, onTap: () {}),
        ),
        const SizedBox(width: 4),
        Text(
          _localizedLabel(l10n),
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    );
  }

  String _localizedLabel(AppLocalizations l10n) {
    return switch (kind) {
      _TechLegendStateKind.researched => l10n.techTree_stateResearched,
      _TechLegendStateKind.inProgress => l10n.techTree_stateInProgress,
      _TechLegendStateKind.available => l10n.techTree_stateAvailable,
      _TechLegendStateKind.locked => l10n.techTree_stateLocked,
    };
  }
}
