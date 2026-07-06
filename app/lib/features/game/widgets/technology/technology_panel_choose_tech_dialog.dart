// Choose-tech dialog widgets for the technology panel.
// Split out of `technology_panel_orders.dart` to keep host files under the
// repo file-size target (Refs #3878).

part of 'technology_panel_orders.dart';

/// Icon size used in Choose-tech dialog rows. Mirrors the mockup
/// `.tech-option img` width/height (22 px). Refs #2864 S4.
const double kChooseTechDialogIconSize = 22;

/// Opens the dark editorial-monocle Choose-tech dialog for [slotIndex]
/// and dispatches `onOrdersChanged` with the updated `Orders` when the
/// user selects a row. Empty-state message is
/// `"No techs available to research"`. The footer Close button pops the
/// route without mutating orders.
///
/// SPEC: `SPEC/ui/technology-panel.md` § Choose-tech dialog. Refs #2864 S4.
void showChooseTechDialog({
  required BuildContext context,
  required Game game,
  required int slotIndex,
  required String humanPlayerId,
  required Orders currentOrders,
  required Player player,
  required void Function(Orders orders) onOrdersChanged,
}) {
  final techUnlocked = player.techUnlocked ?? {};
  final existingOrders =
      currentOrders.researchOrdersByPlayerId[humanPlayerId] ??
      const <ResearchOrder>[];
  final currentlyAssignedIds = existingOrders
      .where((o) => o.techId.isNotEmpty)
      .map((o) => o.techId)
      .toSet();

  final researchableIds = researchableTechIds(
    techUnlocked,
    hasDiscoveredResource: (r) =>
        hasRevealedResourceForPlayer(game, player.id, r),
  );
  final choosableIds = researchableIds
      .where((id) => !currentlyAssignedIds.contains(id))
      .toList();
  final availableTechs =
      choosableIds
          .map((id) => techById(id))
          .whereType<TechDefinition>()
          .toList()
        ..sort((a, b) {
          final eraCmp = a.era.compareTo(b.era);
          if (eraCmp != 0) return eraCmp;
          return techDisplayName(a.id).compareTo(techDisplayName(b.id));
        });

  showDialog<void>(
    context: context,
    barrierColor: EditorialMonoclePalette.dialogScrim,
    builder: (ctx) {
      return ChooseTechDialog(
        game: game,
        contextPlayerId: player.id,
        slotIndex: slotIndex,
        availableTechs: availableTechs,
        onSelect: (tech) {
          final updatedOrders = applyAssignTechToSlot(
            currentOrders: currentOrders,
            humanPlayerId: humanPlayerId,
            slotIndex: slotIndex,
            techId: tech.id,
            existingOrders: existingOrders,
          );
          onOrdersChanged(updatedOrders);
          Navigator.of(ctx).pop();
        },
      );
    },
  );
}

/// Dark editorial-monocle Choose-tech dialog body. Composes
/// `CtDialogShell` + a vertical column of [_ChooseTechOptionRow]
/// entries (or the empty-state line) plus a single full-width Close
/// `CtNinePatchButton`. Refs #2864 S4.
@visibleForTesting
class ChooseTechDialog extends StatelessWidget {
  const ChooseTechDialog({
    super.key,
    required this.game,
    required this.contextPlayerId,
    required this.slotIndex,
    required this.availableTechs,
    required this.onSelect,
  });

  final Game game;
  final String contextPlayerId;
  final int slotIndex;
  final List<TechDefinition> availableTechs;
  final void Function(TechDefinition tech) onSelect;

  @override
  Widget build(BuildContext context) {
    final l10n = appL10n(context);
    final theme = Theme.of(context);
    final isEmpty = availableTechs.isEmpty;
    return CtDialogShell(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            l10n.technologyPanel_chooseTechDialogTitle(slotIndex + 1),
            style: theme.textTheme.titleMedium?.copyWith(
              color: EditorialMonoclePalette.accent,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.05,
            ),
          ),
          CtGap.m,
          if (isEmpty)
            _ChooseTechEmptyMessage()
          else
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                for (final tech in availableTechs)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: _ChooseTechOptionRow(
                      game: game,
                      contextPlayerId: contextPlayerId,
                      tech: tech,
                      onTap: () => onSelect(tech),
                    ),
                  ),
              ],
            ),
          const SizedBox(height: 10),
          CtNinePatchButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(l10n.common_close),
          ),
        ],
      ),
    );
  }
}

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
