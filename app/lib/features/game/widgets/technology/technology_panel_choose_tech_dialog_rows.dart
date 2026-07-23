// Choose-tech dialog row widgets for the technology panel.
// De-parted wave-9 cluster (Refs #4117).

import 'package:colonizethis_app_l10n/l10n/l10n.dart';
import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:flutter/material.dart';

import 'package:colonizethis_app_ui_chrome/config/editorial_monocle_palette.dart';
import '../../../../widgets/ct_gap.dart';
import '../../../../widgets/ct_spacing.dart';
import '../../../../widgets/strict_asset_icon.dart';
import 'tech_gp_pennant_row.dart';
import 'tech_ui_helpers.dart';

/// Icon size used in Choose-tech dialog rows. Mirrors the mockup
/// `.tech-option img` width/height (22 px). Refs #2864 S4.
const double kChooseTechDialogIconSize = 22;

class ChooseTechEmptyMessage extends StatelessWidget {
  const ChooseTechEmptyMessage({super.key});

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

class ChooseTechOptionRow extends StatelessWidget {
  const ChooseTechOptionRow({
    super.key,
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
                child: ChooseTechOptionLabels(
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

class ChooseTechOptionLabels extends StatelessWidget {
  const ChooseTechOptionLabels({
    super.key,
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
