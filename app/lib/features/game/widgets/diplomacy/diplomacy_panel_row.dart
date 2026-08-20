// Per-faction diplomacy row layout for DiplomacyPanel.
// SPEC/ui/diplomacy-panel.md § Per-faction row, § Responsive layout.

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
import 'diplomacy_panel_row_actions.dart';
import 'diplomacy_panel_rows.dart';
import 'relative_power_line.dart';

class DiplomacyRow extends StatelessWidget {
  const DiplomacyRow({
    super.key,
    required this.data,
    required this.onAction,
    this.onTap,
    this.readOnly = false,
  });

  final DiplomacyRowData data;
  final void Function(DiplomaticOrder) onAction;
  final VoidCallback? onTap;
  final bool readOnly;

  @override
  Widget build(BuildContext context) {
    final double viewportWidth = MediaQuery.sizeOf(context).width;
    final bool narrow = viewportWidth <= kDiplomacyRowNarrowMaxWidth;
    return DiplomacyRowChrome(
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(CtSpacing.ml),
          child: narrow ? _buildNarrowBody(context) : _buildWideBody(context),
        ),
      ),
    );
  }

  Key get _bodyKey => ValueKey('$kDiplomacyRowBodyKeyPrefix${data.factionId}');

  Widget _buildWideBody(BuildContext context) {
    return Row(
      key: _bodyKey,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(child: _buildInfoColumn(context)),
        Flexible(
          child: Align(
            alignment: Alignment.topRight,
            child: _buildActionButtons(alignEnd: true),
          ),
        ),
      ],
    );
  }

  Widget _buildNarrowBody(BuildContext context) {
    final bool hasActions = !readOnly && data.actions.isNotEmpty;
    return Column(
      key: _bodyKey,
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildInfoColumn(context),
        if (hasActions) ...[
          CtGap.m,
          Align(alignment: Alignment.centerLeft, child: _buildActionButtons()),
        ],
      ],
    );
  }

  Widget _buildInfoColumn(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildHeaderRow(context),
        ..._buildRelativePowerLine(context),
        const SizedBox(height: 4),
        _buildRelationRow(context),
        ..._buildStandingChips(context),
        ..._buildOptionalStatusLines(context),
      ],
    );
  }

  Widget _buildHeaderRow(BuildContext context) {
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

  List<Widget> _buildRelativePowerLine(BuildContext context) {
    final int? gpScore = data.powerScore;
    final int? playerScore = data.playerPowerScore;
    if (gpScore == null || playerScore == null) {
      return const [];
    }
    final int pct = powerComparisonPercent(gpScore, playerScore);
    return [const SizedBox(height: 4), RelativePowerLine(pct: pct)];
  }

  Widget _buildRelationRow(BuildContext context) {
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
    final bool showAlliance = rel.formalAlliance;
    return Wrap(
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: CtSpacing.s,
      runSpacing: CtSpacing.xs,
      children: [
        DiplomacyRelationStateBadge(atWar: rel.atWar),
        if (showAlliance) const DiplomacyAllianceBadge(),
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

  List<Widget> _buildStandingChips(BuildContext context) {
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

  List<Widget> _buildOptionalStatusLines(BuildContext context) {
    final l10n = appL10n(context);
    final TextStyle style = _economicLineStyle(context);
    final lines = <Widget>[];
    if (data.activeSubsidyPercent != null) {
      final int percent = data.activeSubsidyPercent!;
      final String compactLine = l10n.diplomacy_panel_outgoingSubsidy(
        percent,
        data.displayName,
      );
      lines.addAll([
        const SizedBox(height: 4),
        _subsidyEconomicLine(
          compactLine: compactLine,
          targetDisplayName: data.displayName,
          percent: percent,
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
      final int percent = data.pendingSubsidyPercent!;
      final String compactLine = l10n.diplomacy_panel_pendingSubsidy(percent);
      lines.addAll([
        const SizedBox(height: 4),
        _subsidyEconomicLine(
          compactLine: compactLine,
          targetDisplayName: data.displayName,
          percent: percent,
          style: style,
        ),
      ]);
    }
    return lines;
  }

  Widget _subsidyEconomicLine({
    required String compactLine,
    required String targetDisplayName,
    required int percent,
    required TextStyle style,
  }) {
    final String summary = subsidyPriceEffectSummary(
      targetDisplayName: targetDisplayName,
      percent: percent,
    );
    return Tooltip(
      message: summary,
      child: Text(
        compactLine,
        style: style,
        semanticsLabel: '$compactLine. $summary',
      ),
    );
  }

  Widget _buildActionButtons({bool alignEnd = false}) {
    if (readOnly) {
      return const SizedBox.shrink();
    }
    return DiplomacyRowActions(
      factionId: data.factionId,
      actions: data.actions,
      pendingOrderTypes: data.pendingOrderTypes,
      pendingOvertureStage: data.pendingOvertureStage,
      onAction: onAction,
      alignEnd: alignEnd,
    );
  }
}
