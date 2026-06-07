// Per-faction diplomacy row + action button widgets for DiplomacyPanel.
// SPEC/ui/diplomacy-panel.md § Per-faction row, § Responsive layout,
// § Action button styling.

part of 'diplomacy_panel.dart';

class _DiplomacyRow extends StatelessWidget {
  const _DiplomacyRow({
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
    // SPEC/ui/diplomacy-panel.md § Per-faction row → Row chrome: each row
    // is rendered as a flat gradient tile with a 1 px outline and pointer
    // hover behaviour. The InkWell sits inside the hover-aware chrome so
    // taps still navigate to the detail screen (or order-cancel toggle).
    final double viewportWidth = MediaQuery.sizeOf(context).width;
    final bool narrow = viewportWidth <= kDiplomacyRowNarrowMaxWidth;
    return _DiplomacyRowChrome(
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(CtSpacing.ml),
          child: narrow
              ? _buildNarrowBody(context)
              : _buildWideBody(context),
        ),
      ),
    );
  }

  Key get _bodyKey =>
      ValueKey('$kDiplomacyRowBodyKeyPrefix${data.factionId}');

  // SPEC/ui/diplomacy-panel.md § Responsive layout (wide variant): info
  // column shares a Row with the action cluster, anchored trailing-edge.
  Widget _buildWideBody(BuildContext context) {
    return Row(
      key: _bodyKey,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(child: _buildInfoColumn(context)),
        _buildActionButtons(),
      ],
    );
  }

  // SPEC/ui/diplomacy-panel.md § Responsive layout (narrow ≤ 500 dp): info
  // column stacks above the action cluster; cluster aligns leading-edge.
  Widget _buildNarrowBody(BuildContext context) {
    final bool hasActions =
        !readOnly &&
        (data.actions.isNotEmpty || data.pendingOrderTypes.isNotEmpty);
    return Column(
      key: _bodyKey,
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildInfoColumn(context),
        if (hasActions) ...[
          const SizedBox(height: 8),
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
        const SizedBox(height: 4),
        _buildRelationRow(context),
        ..._buildOptionalStatusLines(context),
      ],
    );
  }

  Widget _buildHeaderRow(BuildContext context) {
    // SPEC/ui/mobile-adaptation.md § 7 Minimum-viewport pin: at
    // `kMinViewportWidth` (320 dp) the inner Row width is ~262 dp once the
    // ListView, row padding, and chrome border are subtracted. A long
    // faction display name (e.g. `Holy Roman Empire`) plus the
    // `_FactionKindBadge` chip and the optional `+N% / −N%` power
    // comparison label exceeds that budget by ~162 px without a
    // shrinkable child, producing the documented overflow. Wrap the name
    // in `Flexible` + `TextOverflow.ellipsis` so the name absorbs all
    // available width and shrinks gracefully at narrow viewports while
    // the chip + percentage retain their natural size for legibility.
    // SPEC/ui/diplomacy-panel.md § Per-faction row text layout is
    // preserved: the chip, optional percentage, and their leading gap
    // continue to anchor to the name's trailing edge.
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
        const SizedBox(width: 8),
        _kindChip(context, data.kind),
        ..._buildPowerComparison(context),
      ],
    );
  }

  /// Renders the Great Power power-comparison percentage per
  /// SPEC/ui/diplomacy-panel.md § Power comparison percentage.
  List<Widget> _buildPowerComparison(BuildContext context) {
    final int? gpScore = data.powerScore;
    final int? playerScore = data.playerPowerScore;
    if (gpScore == null || playerScore == null) {
      return const [];
    }
    final int pct = powerComparisonPercent(gpScore, playerScore);
    final String text = formatPowerComparisonPercent(pct);
    // SPEC: red (--danger) when GP stronger (pct > 0), green (--success) when
    // weaker or equal (pct <= 0). Token colors live in the editorial-monocle
    // palette so the row matches the dark theme rather than raw Material reds.
    final Color color = pct > 0
        ? EditorialMonoclePalette.danger
        : EditorialMonoclePalette.success;
    return [
      const SizedBox(width: 8),
      Text(
        text,
        style: Theme.of(context).textTheme.labelMedium?.copyWith(
          color: color,
          fontWeight: FontWeight.w600,
        ),
      ),
    ];
  }

  /// Renders the relation summary row per SPEC/ui/diplomacy-panel.md
  /// § Relation state badge + § Per-faction row. The WAR/PEACE chip uses
  /// the dedicated [_RelationStateBadge]; the one-word relation state
  /// (Hostile / Unfriendly / Cordial / Friendly) and the optional
  /// overture stage stay as inline text.
  Widget _buildRelationRow(BuildContext context) {
    final TextStyle? bodySmall = Theme.of(context).textTheme.bodySmall;
    final DiplomacyRelation? rel = data.relation;
    if (rel == null) {
      return Text('—', style: bodySmall);
    }
    // SPEC/game/diplomacy.md § Player-facing relation display: show
    // one-word state, hide score.
    final String relationStateLabel = relationScoreToDisplayLabel(rel.score);
    final String overtureLabel = data.overture == null
        ? ''
        : ' · ${_overtureStageLabel(data.overture!.stage)}';
    final String trailing = relationStateLabel.isEmpty
        ? overtureLabel
        : ' · $relationStateLabel$overtureLabel';
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        _RelationStateBadge(atWar: rel.atWar),
        if (trailing.isNotEmpty)
          Flexible(
            child: Text(
              trailing,
              style: bodySmall,
              overflow: TextOverflow.ellipsis,
              maxLines: 2,
            ),
          ),
      ],
    );
  }

  List<Widget> _buildOptionalStatusLines(BuildContext context) {
    final l10n = appL10n(context);
    final lines = <Widget>[];
    if (data.activeSubsidyPerTurn != null) {
      lines.addAll([
        const SizedBox(height: 4),
        Text(
          l10n.diplomacy_panel_outgoingSubsidy(
            data.activeSubsidyPerTurn!,
            data.displayName,
          ),
          style: Theme.of(
            context,
          ).textTheme.bodySmall?.copyWith(fontStyle: FontStyle.italic),
        ),
      ]);
    }
    if (data.pendingGrantAmount != null) {
      lines.addAll([
        const SizedBox(height: 4),
        Text(
          l10n.diplomacy_panel_pendingGrant(data.pendingGrantAmount!),
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            fontStyle: FontStyle.italic,
            color: Theme.of(context).colorScheme.tertiary,
          ),
        ),
      ]);
    }
    if (data.pendingSubsidyAmount != null) {
      lines.addAll([
        const SizedBox(height: 4),
        Text(
          l10n.diplomacy_panel_pendingSubsidy(data.pendingSubsidyAmount!),
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            fontStyle: FontStyle.italic,
            color: Theme.of(context).colorScheme.tertiary,
          ),
        ),
      ]);
    }
    return lines;
  }

  Widget _buildActionButtons() {
    if (readOnly) {
      return const SizedBox.shrink();
    }
    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: [
        for (final order in data.actions)
          if (!data.pendingOrderTypes.contains(order.type))
            _ActionButton(order: order, onPressed: () => onAction(order)),
        for (final orderType in data.pendingOrderTypes)
          _ActionButton(
            order: DiplomaticOrder(
              type: orderType,
              targetFactionId: data.factionId,
            ),
            onPressed: () {},
            isPending: true,
            onCancel: () => onAction(
              DiplomaticOrder(type: orderType, targetFactionId: data.factionId),
            ),
          ),
      ],
    );
  }

  Widget _kindChip(BuildContext context, FactionKind kind) {
    return _FactionKindBadge(kind: kind);
  }

  String _overtureStageLabel(OvertureStage stage) {
    return switch (stage) {
      OvertureStage.none => 'None',
      OvertureStage.tradeConsulate => 'Consulate',
      OvertureStage.embassy => 'Embassy',
      OvertureStage.nap => 'NAP',
      OvertureStage.joinEmpire => 'Join Empire',
    };
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.order,
    required this.onPressed,
    this.isPending = false,
    this.onCancel,
  });

  final DiplomaticOrder order;
  final VoidCallback onPressed;
  final bool isPending;
  final VoidCallback? onCancel;

  /// SPEC/ui/diplomacy-panel.md § Action button styling — destructive
  /// `Declare War` action resolves both the button outline and the
  /// engraved label to the canonical `--danger` token. Pending state
  /// keeps the default brass chrome so the "Cancel" affordance still
  /// reads as a recoverable toggle.
  bool get _isWarVariant =>
      !isPending && order.type == DiplomaticOrderType.declareWar;

  @override
  Widget build(BuildContext context) {
    final label = isPending ? 'Cancel' : diplomacyActionLabel(order);
    final ThemeData theme = Theme.of(context);
    // SPEC/ui/pixel-art-ui-catalog.md § Editorial-monocle text theme —
    // the action-button caption resolves through the M3 `bodySmall` slot
    // (12 dp) so font, weight, and colour flow from
    // `AppThemes.editorialMonocle` instead of a hard-coded literal.
    // Refs #2914 S7.
    final TextStyle labelStyle =
        theme.textTheme.bodySmall ?? const TextStyle(fontSize: 12);
    return SizedBox(
      height: 32,
      child: CtNinePatchButton(
        onPressed: isPending ? onCancel : onPressed,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        dangerVariant: _isWarVariant,
        child: Text(label, style: labelStyle),
      ),
    );
  }
}
