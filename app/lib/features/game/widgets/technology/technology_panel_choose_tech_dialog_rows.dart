// Choose-tech dialog row widgets. Split from
// `technology_panel_choose_tech_dialog.dart` (Refs #3878).

import 'package:colonizethis_app_l10n/l10n/l10n.dart';
import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_world/colonizethis_world.dart';
import 'package:flutter/material.dart';

import 'package:colonizethis_app_ui_chrome/config/editorial_monocle_palette.dart';
import '../../../../widgets/ct_action_text_button.dart';
import '../../../../widgets/ct_gap.dart';
import '../../../../widgets/ct_spacing.dart';
import '../../../../widgets/strict_asset_icon.dart';
import 'tech_definition_detail_dialog.dart';
import 'tech_effect_summary.dart';
import 'tech_ui_helpers.dart';
import 'tech_gp_pennant_row.dart';

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
    required this.onAssign,
  });

  final Game game;
  final String contextPlayerId;
  final TechDefinition tech;
  final VoidCallback onAssign;

  Player? get _player => game.playerById(contextPlayerId);

  @override
  Widget build(BuildContext context) {
    final l10n = appL10n(context);
    final iconPath = techCategoryIconAssetPath(tech.category);
    final player = _player;
    return DecoratedBox(
      decoration: BoxDecoration(
        border: Border.all(color: EditorialMonoclePalette.border, width: 1),
      ),
      child: Padding(
        padding: const EdgeInsets.all(CtSpacing.m),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
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
              child: InkWell(
                onTap: onAssign,
                child: ChooseTechOptionLabels(
                  game: game,
                  contextPlayerId: contextPlayerId,
                  tech: tech,
                ),
              ),
            ),
            if (player != null) ...[
              CtGap.wm,
              CtActionTextButton(
                label: l10n.technologyPanel_chooseTechDetails,
                onPressed: () => showTechDefinitionDetailDialog(
                  context,
                  game: game,
                  player: player,
                  tech: tech,
                ),
              ),
            ],
          ],
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
    this.effectLineCap = kChooseTechDefaultEffectLineCap,
  });

  final Game game;
  final String contextPlayerId;
  final TechDefinition tech;

  /// When set, only the first [effectLineCap] effect lines render on the row.
  final int effectLineCap;

  @override
  Widget build(BuildContext context) {
    final l10n = appL10n(context);
    final effectLines = buildTechEffectSummaryLines(l10n, tech);
    final visibleEffects = effectLineCap <= 0
        ? const <String>[]
        : effectLines.take(effectLineCap).toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        ChooseTechOptionTitleRow(
          game: game,
          contextPlayerId: contextPlayerId,
          tech: tech,
        ),
        const SizedBox(height: 2),
        ChooseTechOptionSubtitle(tech: tech),
        for (final line in visibleEffects) ...[
          const SizedBox(height: 2),
          ChooseTechOptionEffectLine(text: line),
        ],
      ],
    );
  }
}

class ChooseTechOptionTitleRow extends StatelessWidget {
  const ChooseTechOptionTitleRow({
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
    return Wrap(
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
    );
  }
}

class ChooseTechOptionSubtitle extends StatelessWidget {
  const ChooseTechOptionSubtitle({super.key, required this.tech});

  final TechDefinition tech;

  @override
  Widget build(BuildContext context) {
    final l10n = appL10n(context);
    return Text(
      l10n.technologyPanel_pickSubtitle(
        eraRoman(tech.era),
        techCategoryLabelL10n(l10n, tech.category),
        tech.cost,
      ),
      style: TextStyle(
        color: EditorialMonoclePalette.muted,
        fontSize: 10,
        fontFamilyFallback: const <String>['SF Mono', 'Menlo', 'monospace'],
        fontFeatures: const <FontFeature>[FontFeature.tabularFigures()],
      ),
    );
  }
}

class ChooseTechOptionEffectLine extends StatelessWidget {
  const ChooseTechOptionEffectLine({super.key, required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: TextStyle(color: EditorialMonoclePalette.muted, fontSize: 10),
    );
  }
}

/// All effect summary lines for [tech] (Tree parity helper for tests).
@visibleForTesting
List<String> chooseTechEffectSummaryLinesForTest(
  AppLocalizations l10n,
  TechDefinition tech,
) {
  return buildTechEffectSummaryLines(l10n, tech);
}
