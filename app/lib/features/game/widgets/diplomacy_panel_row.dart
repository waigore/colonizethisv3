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
        // Full action matrices can exceed one run; [Flexible] caps the
        // trailing cluster to remaining row width so [Wrap] can flow.
        Flexible(
          child: Align(
            alignment: Alignment.topRight,
            child: _buildActionButtons(),
          ),
        ),
      ],
    );
  }

  // SPEC/ui/diplomacy-panel.md § Responsive layout (narrow ≤ 500 dp): info
  // column stacks above the action cluster; cluster aligns leading-edge.
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
        ..._buildOptionalStatusLines(context),
      ],
    );
  }

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
        for (final action in data.actions)
          if (_isActionPending(action))
            _ActionButton(
              order: action.order,
              onPressed: () {},
              isPending: true,
              onCancel: () => onAction(action.order),
            )
          else
            _ActionButton(
              order: action.order,
              enabled: action.enabled,
              rejectionReason: action.rejectionReason,
              onPressed: action.enabled ? () => onAction(action.order) : null,
            ),
      ],
    );
  }

  bool _isActionPending(DiplomaticPanelAction action) {
    if (!data.pendingOrderTypes.contains(action.order.type)) {
      return false;
    }
    if (action.order.type == DiplomaticOrderType.establishOverture) {
      return data.pendingOvertureStage == action.order.overtureStage;
    }
    return true;
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
    this.enabled = true,
    this.rejectionReason,
  });

  final DiplomaticOrder order;
  final VoidCallback? onPressed;
  final bool isPending;
  final VoidCallback? onCancel;
  final bool enabled;
  final String? rejectionReason;

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
    final Widget button = SizedBox(
      height: 32,
      child: CtNinePatchButton(
        onPressed: isPending ? onCancel : onPressed,
        enabled: isPending || enabled,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        dangerVariant: _isWarVariant,
        child: Text(label, style: labelStyle),
      ),
    );
    final String? reason = rejectionReason;
    if (!isPending && !enabled && reason != null && reason.isNotEmpty) {
      return Tooltip(message: reason, child: button);
    }
    return button;
  }
}
