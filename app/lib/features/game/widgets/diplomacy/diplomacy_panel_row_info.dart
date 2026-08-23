// Per-faction diplomacy row identity / relation / economic lines.
// SPEC/ui/diplomacy-panel.md § Per-faction row.

import 'package:colonizethis_app_l10n/l10n/l10n.dart';
import 'package:colonizethis_app_ui_chrome/config/editorial_monocle_palette.dart';
import 'package:colonizethis_diplomacy/colonizethis_diplomacy.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:flutter/material.dart';

import '../../../../widgets/ct_gap.dart';
import '../../../../widgets/ct_spacing.dart';
import '../../../../widgets/relation_meter.dart';
import 'diplomacy_panel_chrome_relation_badges.dart';
import 'diplomacy_panel_chrome_section_header.dart';
import 'diplomacy_panel_chrome_standing.dart';
import 'diplomacy_panel_constants.dart';
import 'diplomacy_panel_rows.dart';
import 'relative_power_line.dart';

class DiplomacyRowInfo extends StatelessWidget {
  const DiplomacyRowInfo({super.key, required this.data});

  final DiplomacyRowData data;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        _headerRow(context),
        ..._relativePowerLine(context),
        const SizedBox(height: 4),
        _relationRow(context),
        ..._standingChips(),
        ..._optionalStatusLines(context),
      ],
    );
  }

  Widget _headerRow(BuildContext context) {
    return Row(
      children: [
        Flexible(
          child: Text(
            data.displayName,
            style: Theme.of(
              context,
            ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
            overflow: TextOverflow.ellipsis,
            maxLines: 1,
          ),
        ),
        CtGap.wm,
        DiplomacyFactionKindBadge(kind: data.kind),
      ],
    );
  }

  List<Widget> _relativePowerLine(BuildContext context) {
    final int? gpScore = data.powerScore;
    final int? playerScore = data.playerPowerScore;
    if (gpScore == null || playerScore == null) {
      return const [];
    }
    final int pct = powerComparisonPercent(gpScore, playerScore);
    return [const SizedBox(height: 4), RelativePowerLine(pct: pct)];
  }

  Widget _relationRow(BuildContext context) {
    final TextStyle bodySmall =
        Theme.of(context).textTheme.bodySmall ?? const TextStyle(fontSize: 12);
    final DiplomacyRelation? rel = data.relation;
    if (rel == null) {
      return Text('—', style: bodySmall);
    }
    final String relationStateLabel = relationScoreToDisplayLabel(rel.score);
    final TextStyle mutedStyle = bodySmall.copyWith(
      color: EditorialMonoclePalette.muted,
    );
    final TextStyle wordStyle = bodySmall.copyWith(
      color: diplomacyRelationWordColor(rel.score),
      fontStyle: FontStyle.italic,
    );
    final List<InlineSpan> spans = <InlineSpan>[];
    if (relationStateLabel.isNotEmpty) {
      spans.add(TextSpan(text: relationStateLabel, style: wordStyle));
    }
    return Wrap(
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: CtSpacing.s,
      runSpacing: CtSpacing.xs,
      children: [
        DiplomacyRelationStateBadge(atWar: rel.atWar),
        if (rel.formalAlliance) const DiplomacyAllianceBadge(),
        RelationMeter(score: rel.score),
        if (spans.isNotEmpty)
          Text.rich(
            TextSpan(style: mutedStyle, children: spans),
            overflow: TextOverflow.ellipsis,
            maxLines: 2,
          ),
      ],
    );
  }

  List<Widget> _standingChips() {
    if (data.standingChips.isEmpty) {
      return const <Widget>[];
    }
    return <Widget>[
      const SizedBox(height: 4),
      DiplomacyStandingChipCluster(chips: data.standingChips),
    ];
  }

  TextStyle _economicLineStyle(BuildContext context) {
    final TextStyle base =
        Theme.of(context).textTheme.bodySmall ?? const TextStyle(fontSize: 12);
    return base.copyWith(
      color: EditorialMonoclePalette.accentDim,
      fontFamily: 'monospace',
      fontFamilyFallback: const ['Courier'],
      fontStyle: FontStyle.normal,
    );
  }

  List<Widget> _optionalStatusLines(BuildContext context) {
    final l10n = appL10n(context);
    final TextStyle style = _economicLineStyle(context);
    final lines = <Widget>[];
    if (data.activeSubsidyPercent != null) {
      lines.addAll([
        const SizedBox(height: 4),
        _subsidyEconomicLine(
          compact: l10n.diplomacy_panel_outgoingSubsidy(
            data.activeSubsidyPercent!,
            data.displayName,
          ),
          percent: data.activeSubsidyPercent!,
          lineKey: const Key('diplomacyOutgoingSubsidyLine'),
          style: style,
        ),
      ]);
    }
    if (data.pendingGrantAmount != null) {
      lines.addAll([
        const SizedBox(height: 4),
        Text(
          l10n.diplomacy_panel_pendingGrant(data.pendingGrantAmount!),
          style: style,
        ),
      ]);
    }
    if (data.pendingSubsidyPercent != null) {
      lines.addAll([
        const SizedBox(height: 4),
        _subsidyEconomicLine(
          compact: l10n.diplomacy_panel_pendingSubsidy(
            data.pendingSubsidyPercent!,
          ),
          percent: data.pendingSubsidyPercent!,
          lineKey: const Key('diplomacyPendingSubsidyLine'),
          style: style,
        ),
      ]);
    }
    return lines;
  }

  Widget _subsidyEconomicLine({
    required String compact,
    required int percent,
    required Key lineKey,
    required TextStyle style,
  }) {
    final tooltip = subsidyFillPriceConsequenceTooltip(
      targetDisplayName: data.displayName,
      percent: percent,
    );
    return Tooltip(
      message: tooltip,
      child: Text(compact, key: lineKey, style: style, semanticsLabel: tooltip),
    );
  }
}
