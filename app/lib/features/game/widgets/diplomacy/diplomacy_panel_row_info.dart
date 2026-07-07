// Diplomacy faction-row info column (header, relation, standing, status).
// SPEC/ui/diplomacy-panel.md § Per-faction row.

import 'package:colonizethis_app_l10n/l10n/l10n.dart';
part of 'diplomacy_panel.dart';

extension _DiplomacyRowInfo on _DiplomacyRow {
  Widget _buildHeaderRow(BuildContext context) {
    // SPEC/ui/mobile-adaptation.md § 7 Minimum-viewport pin: at
    // `kMinViewportWidth` (320 dp) the inner Row width is ~262 dp once the
    // ListView, row padding, and chrome border are subtracted. A long
    // faction display name (e.g. `Holy Roman Empire`) plus the
    // `_FactionKindBadge` chip exceeds that budget without a shrinkable
    // child, producing the documented overflow. Wrap the name in
    // `Flexible` + `TextOverflow.ellipsis` so the name absorbs all
    // available width and shrinks gracefully at narrow viewports while
    // the chip retains its natural size for legibility. The Great Power
    // power comparison no longer lives here — it renders on the dedicated
    // relative-power line below the header (SPEC/ui/diplomacy-panel.md
    // § Relative power line).
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
        _kindChip(context, data.kind),
      ],
    );
  }

  /// Renders the Great Power relative-power line between the header and the
  /// relation row per SPEC/ui/diplomacy-panel.md § Relative power line. Only
  /// Great Power rows carry the comparison scores; Minor / Tribe rows omit
  /// the line entirely.
  List<Widget> _buildRelativePowerLine(BuildContext context) {
    final int? gpScore = data.powerScore;
    final int? playerScore = data.playerPowerScore;
    if (gpScore == null || playerScore == null) {
      return const [];
    }
    final int pct = powerComparisonPercent(gpScore, playerScore);
    return [const SizedBox(height: 4), RelativePowerLine(pct: pct)];
  }

  /// Renders the relation summary row per SPEC/ui/diplomacy-panel.md
  /// § Relation state badge + § Per-faction row + § Relation word styling.
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
        _RelationStateBadge(atWar: rel.atWar),
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
      lines.addAll([
        const SizedBox(height: 4),
        Text(
          l10n.diplomacy_panel_outgoingSubsidy(
            data.activeSubsidyPercent!,
            data.displayName,
          ),
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
        Text(
          l10n.diplomacy_panel_pendingSubsidy(data.pendingSubsidyPercent!),
          style: style,
        ),
      ]);
    }
    return lines;
  }
}
