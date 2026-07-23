// Choose-tech dialog row widgets. Split from
// `technology_panel_choose_tech_dialog.dart` (Refs #3878).

part of 'technology_panel_orders.dart';

class _ChooseTechEmptyMessage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final l10n = appL10n(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: CtSpacing.ml),
      child: Text(
        l10n.technologyPanel_noTechsAvailable,
        textAlign: TextAlign.center,
        style: TextStyle(
          color: EditorialMonoclePalette.muted,
          fontStyle: FontStyle.italic,
        ),
      ),
    );
  }
}

class _ChooseTechOptionRow extends StatelessWidget {
  const _ChooseTechOptionRow({
    required this.game,
    required this.contextPlayerId,
    required this.tech,
    required this.onTap,
  });

  final Game game;
  final String contextPlayerId;
  final TechDefinition tech;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final iconPath = techCategoryIconAssetPath(tech.category);
    return InkWell(
      onTap: onTap,
      child: DecoratedBox(
        decoration: BoxDecoration(
          border: Border.all(
            color: EditorialMonoclePalette.border,
            width: 1,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(CtSpacing.m),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              if (iconPath != null) ...[
                StrictAssetIcon(
                  assetPath: iconPath,
                  width: kChooseTechDialogIconSize,
                  height: kChooseTechDialogIconSize,
                ),
                CtGap.wm,
              ],
              Expanded(
                child: _ChooseTechOptionLabels(
                  game: game,
                  contextPlayerId: contextPlayerId,
                  tech: tech,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ChooseTechOptionLabels extends StatelessWidget {
  const _ChooseTechOptionLabels({
    required this.game,
    required this.contextPlayerId,
    required this.tech,
  });

  final Game game;
  final String contextPlayerId;
  final TechDefinition tech;

  @override
  Widget build(BuildContext context) {
    final l10n = appL10n(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Wrap(
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: CtSpacing.s,
          runSpacing: 2,
          children: [
            Text(
              techDisplayName(tech.id),
              style: TextStyle(
                color: EditorialMonoclePalette.fg,
                fontWeight: FontWeight.w600,
                fontSize: 12,
              ),
            ),
            TechGpPennantRow(
              game: game,
              techId: tech.id,
              contextPlayerId: contextPlayerId,
              compact: true,
            ),
          ],
        ),
        const SizedBox(height: 2),
        Text(
          l10n.technologyPanel_pickSubtitle(
            eraRoman(tech.era),
            techCategoryLabelL10n(l10n, tech.category),
            tech.cost,
          ),
          style: TextStyle(
            color: EditorialMonoclePalette.muted,
            fontSize: 10,
            fontFamilyFallback: const <String>[
              'SF Mono',
              'Menlo',
              'monospace',
            ],
            fontFeatures: const <FontFeature>[
              FontFeature.tabularFigures(),
            ],
          ),
        ),
      ],
    );
  }
}
