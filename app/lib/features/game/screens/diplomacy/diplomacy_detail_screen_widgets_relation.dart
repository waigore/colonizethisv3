import 'package:colonizethis_app_l10n/l10n/l10n.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:flutter/material.dart';

import 'package:colonizethis_app_ui_chrome/config/editorial_monocle_palette.dart';
import '../../../../widgets/relation_meter.dart';
import '../../widgets/diplomacy/diplomacy_panel.dart';

/// Body of the "Current relation" card. Renders a one-line summary with a
/// War/Peace state (colored badge label) and the one-word relation label.
class DiplomacyDetailRelationSummary extends StatelessWidget {
  const DiplomacyDetailRelationSummary({
    required this.relation,
    required this.l10n,
    this.standingChips = const DiplomaticStandingChips(),
  });

  final DiplomacyRelation? relation;
  final AppLocalizations l10n;

  /// Active overture/treaty/colony/boycott/overseas chips for this faction
  /// (Refs #3753 R12). Rendered below the relation summary when non-empty.
  final DiplomaticStandingChips standingChips;

  @override
  Widget build(BuildContext context) {
    final DiplomacyRelation? rel = relation;
    if (rel == null) {
      return Text(
        '—',
        style: diplomacyDetailRelationSummaryDisplayStyle(context).copyWith(
          color: EditorialMonoclePalette.muted,
        ),
      );
    }
    final Widget summaryRow = DiplomacyDetailRelationSummaryRow(
      relation: rel,
      l10n: l10n,
    );
    if (standingChips.isEmpty) {
      return summaryRow;
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        summaryRow,
        const SizedBox(height: 8),
        DiplomacyStandingChipCluster(chips: standingChips),
      ],
    );
  }
}

/// One-line War/Peace state, relation meter, one-word ladder label, and the
/// optional formal-alliance badge.
class DiplomacyDetailRelationSummaryRow extends StatelessWidget {
  const DiplomacyDetailRelationSummaryRow({
    required this.relation,
    required this.l10n,
  });

  final DiplomacyRelation relation;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    final bool atWar = relation.atWar;
    final String stateLabel = atWar
        ? l10n.diplomacy_relationState_war
        : l10n.diplomacy_relationState_peace;
    final Color stateColor = atWar
        ? EditorialMonoclePalette.danger
        : EditorialMonoclePalette.success;
    final String relationLabel = relationScoreToDisplayLabel(relation.score);
    // SPEC/ui/diplomacy-detail-screen.md § Formal alliance indicator
    // (Refs #3625, AC4): a persisted formal alliance surfaces the same gold
    // ALLIANCE treaty badge used by the panel row, distinct from the informal
    // one-word relation label. A merely-Friendly relation in the informal
    // RelationLevel.allied band (no treaty) never shows it.
    final bool showAlliance = relation.formalAlliance;

    return Wrap(
      spacing: 10,
      runSpacing: 4,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: <Widget>[
        Text(
          stateLabel,
          style: diplomacyDetailRelationSummaryDisplayStyle(context).copyWith(
            color: stateColor,
            fontWeight: FontWeight.w600,
          ),
        ),
        // SPEC/ui/diplomacy-detail-screen.md § Current relation (Refs #3753
        // R13.5): the same 10-step gradient meter used on the panel row sits
        // beside the one-word ladder label; the hidden decimal score positions
        // the indicator.
        RelationMeter(score: relation.score),
        if (relationLabel.isNotEmpty)
          Text(
            relationLabel,
            style: diplomacyDetailRelationSummaryDisplayStyle(context).copyWith(
              color: relationMeterStepColor(
                relationScoreToMeterStep(relation.score),
              ),
            ),
          ),
        if (showAlliance) const DiplomacyAllianceBadge(),
      ],
    );
  }
}

TextStyle diplomacyDetailRelationSummaryDisplayStyle(BuildContext context) {
  final ThemeData theme = Theme.of(context);
  return (theme.textTheme.titleSmall ?? const TextStyle(fontSize: 14))
      .copyWith(letterSpacing: 0.02);
}
