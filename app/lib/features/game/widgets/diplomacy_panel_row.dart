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
          child: narrow ? _buildNarrowBody(context) : _buildWideBody(context),
        ),
      ),
    );
  }

  Key get _bodyKey => ValueKey('$kDiplomacyRowBodyKeyPrefix${data.factionId}');

  // SPEC/ui/diplomacy-panel.md § Responsive layout (wide variant): info
  // column shares a Row with the action cluster, anchored trailing-edge.
  Widget _buildWideBody(BuildContext context) {
    return Row(
      key: _bodyKey,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(child: _buildInfoColumn(context)),
        // SPEC/ui/diplomacy-panel.md § Action button styling — the trailing
        // cluster is capped to [kDiplomacyActionClusterMaxWidth] (mockup
        // `.f-actions { max-width: 180px }`) so the compact buttons flow
        // left-to-right and wrap onto additional runs instead of expanding
        // to fill the remaining row width as a single vertical stack.
        Flexible(
          child: Align(
            alignment: Alignment.topRight,
            child: ConstrainedBox(
              constraints: const BoxConstraints(
                maxWidth: kDiplomacyActionClusterMaxWidth,
              ),
              child: _buildActionButtons(alignEnd: true),
            ),
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
  /// § Relation state badge + § Per-faction row + § Relation word styling.
  /// The WAR/PEACE chip uses the dedicated [_RelationStateBadge]; the
  /// one-word relation state (Hostile / Unfriendly / Cordial / Friendly)
  /// renders **italic** in its level-appropriate color
  /// ([diplomacyRelationWordColor]) per the mockup `.f-relation .word`,
  /// while the muted separator and the optional overture stage keep the
  /// `--muted` body styling (mockup `.f-overture`).
  Widget _buildRelationRow(BuildContext context) {
    final TextStyle bodySmall =
        Theme.of(context).textTheme.bodySmall ?? const TextStyle(fontSize: 12);
    final DiplomacyRelation? rel = data.relation;
    if (rel == null) {
      return Text('—', style: bodySmall);
    }
    // SPEC/game/diplomacy.md § Player-facing relation display: show
    // one-word state, hide score.
    final String relationStateLabel = relationScoreToDisplayLabel(rel.score);
    final String overtureLabel = data.overture == null
        ? ''
        : _overtureStageLabel(data.overture!.stage);
    // SPEC/ui/diplomacy-panel.md § Relation word styling (Refs #3621): the
    // `·` separators and overture text stay `--muted`; only the relation
    // word carries the level color + italic treatment.
    final TextStyle mutedStyle = bodySmall.copyWith(
      color: EditorialMonoclePalette.muted,
    );
    final TextStyle wordStyle = bodySmall.copyWith(
      color: diplomacyRelationWordColor(rel.score),
      fontStyle: FontStyle.italic,
    );
    // Mockup `.f-relation`: the WAR/PEACE badge carries a 4 px right margin
    // before the relation word (no leading `·`); the overture clause keeps a
    // `·` separator. The leading single space here reproduces the badge gap.
    final List<InlineSpan> spans = <InlineSpan>[];
    if (relationStateLabel.isNotEmpty) {
      spans.add(const TextSpan(text: ' '));
      spans.add(TextSpan(text: relationStateLabel, style: wordStyle));
    }
    if (overtureLabel.isNotEmpty) {
      spans.add(TextSpan(text: ' · $overtureLabel'));
    }
    // SPEC/ui/diplomacy-panel.md § Formal alliance indicator (Refs #3625): a
    // persisted formal alliance (treaty) surfaces an explicit `ALLIANCE` badge
    // after the WAR/PEACE state badge so a mutual-defence treaty reads as
    // distinct from a merely-Friendly informal relation. The informal
    // `RelationLevel.allied` score band never shows this badge on its own.
    final bool showAlliance = rel.formalAlliance;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        _RelationStateBadge(atWar: rel.atWar),
        if (showAlliance) ...[CtGap.wm, const _AllianceBadge()],
        if (spans.isNotEmpty)
          Flexible(
            child: Text.rich(
              TextSpan(style: mutedStyle, children: spans),
              overflow: TextOverflow.ellipsis,
              maxLines: 2,
            ),
          ),
      ],
    );
  }

  /// Shared style for the outgoing economic-diplomacy lines (active subsidy,
  /// pending grant, pending subsidy). SPEC/ui/diplomacy-panel.md
  /// § Per-faction row → Outgoing economic diplomacy (styling, Refs #3621):
  /// the mockup `.f-subsidy` treatment is mono, `--accent-dim`, and
  /// non-italic. All three lines share one compact mono style so the block
  /// reads uniformly (superseding the prior italic / `colorScheme.tertiary`
  /// pending styling).
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
    if (data.activeSubsidyPerTurn != null) {
      lines.addAll([
        const SizedBox(height: 4),
        Text(
          l10n.diplomacy_panel_outgoingSubsidy(
            data.activeSubsidyPerTurn!,
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
    if (data.pendingSubsidyAmount != null) {
      lines.addAll([
        const SizedBox(height: 4),
        Text(
          l10n.diplomacy_panel_pendingSubsidy(data.pendingSubsidyAmount!),
          style: style,
        ),
      ]);
    }
    return lines;
  }

  Widget _buildActionButtons({bool alignEnd = false}) {
    if (readOnly) {
      return const SizedBox.shrink();
    }
    return Wrap(
      // SPEC/ui/diplomacy-panel.md § Action button styling — mockup
      // `.f-actions { gap: 4px; justify-content: flex-end }` (wide) /
      // `justify-content: flex-start` (narrow).
      alignment: alignEnd ? WrapAlignment.end : WrapAlignment.start,
      spacing: kDiplomacyActionWrapSpacing,
      runSpacing: kDiplomacyActionWrapSpacing,
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
    // SPEC/ui/diplomacy-panel.md § Action button styling — diplomacy action
    // buttons use the compact CtNinePatchButton variant (tighter minHeight
    // and padding than the 48 × 16/12 dp default) to match the mockup
    // `.f-actions button` density. Refs #3621.
    final Widget button = CtNinePatchButton(
      onPressed: isPending ? onCancel : onPressed,
      enabled: isPending || enabled,
      minHeight: kDiplomacyActionButtonMinHeight,
      padding: kDiplomacyActionButtonPadding,
      // SPEC/ui/diplomacy-panel.md § Action button styling (Refs #3621): the
      // compact action buttons shrink-wrap to their label so the trailing
      // cluster flows left-to-right across the 180 dp `Wrap` instead of each
      // button expanding to the full run width as a vertical column.
      shrinkWrap: true,
      dangerVariant: _isWarVariant,
      child: Text(label, style: labelStyle),
    );
    final String? reason = rejectionReason;
    if (!isPending && !enabled && reason != null && reason.isNotEmpty) {
      return Tooltip(message: reason, child: button);
    }
    return button;
  }
}
