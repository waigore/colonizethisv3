// Per-faction diplomacy row layout for DiplomacyPanel.
// SPEC/ui/diplomacy-panel.md § Per-faction row, § Responsive layout.

import 'package:colonizethis_app_l10n/l10n/l10n.dart';
import 'package:colonizethis_app_ui_chrome/config/editorial_monocle_palette.dart';
import 'package:colonizethis_diplomacy/colonizethis_diplomacy.dart';
import 'package:colonizethis_orders/src/orders/diplomatic_panel_actions.dart';

import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:flutter/material.dart';

import '../../../../config/themes.dart' show editorialMonocleDisplayFontFamily;
import '../../../../widgets/ct_gap.dart';
import '../../../../widgets/ct_nine_patch_button.dart';
import '../../../../widgets/ct_spacing.dart';
import '../../../../widgets/relation_meter.dart';
import 'diplomacy_order_helpers.dart';
import 'diplomacy_panel_chrome_relation_badges.dart';
import 'diplomacy_panel_chrome_section_header.dart';
import 'diplomacy_panel_chrome_standing.dart';
import 'diplomacy_panel_constants.dart';
import 'diplomacy_panel_rows.dart';
import 'relative_power_line.dart';

class DiplomacyRow extends StatelessWidget {
  const DiplomacyRow({super.key, 
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

  Widget _buildActionButtons({bool alignEnd = false}) {
    if (readOnly) {
      return const SizedBox.shrink();
    }
    return _DiplomacyActionCluster(
      factionId: data.factionId,
      actions: data.actions,
      pendingOrderTypes: data.pendingOrderTypes,
      pendingOvertureStage: data.pendingOvertureStage,
      onAction: onAction,
      alignEnd: alignEnd,
    );
  }
}

class _DiplomacyActionCluster extends StatefulWidget {
  const _DiplomacyActionCluster({
    required this.factionId,
    required this.actions,
    required this.pendingOrderTypes,
    required this.pendingOvertureStage,
    required this.onAction,
    this.alignEnd = false,
  });

  final String factionId;
  final List<DiplomaticPanelAction> actions;
  final Set<DiplomaticOrderType> pendingOrderTypes;
  final OvertureStage? pendingOvertureStage;
  final void Function(DiplomaticOrder) onAction;
  final bool alignEnd;

  @override
  State<_DiplomacyActionCluster> createState() => _DiplomacyActionClusterState();
}

class _DiplomacyActionClusterState extends State<_DiplomacyActionCluster> {
  bool _expanded = false;

  bool _isActionPending(DiplomaticPanelAction action) {
    if (!widget.pendingOrderTypes.contains(action.order.type)) {
      return false;
    }
    if (action.order.type == DiplomaticOrderType.establishOverture) {
      return widget.pendingOvertureStage == action.order.overtureStage;
    }
    return true;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = appL10n(context);
    final List<DiplomaticPanelAction> defaultActions = <DiplomaticPanelAction>[];
    final List<DiplomaticPanelAction> hiddenActions = <DiplomaticPanelAction>[];
    for (final DiplomaticPanelAction action in widget.actions) {
      if (action.enabled || _isActionPending(action)) {
        defaultActions.add(action);
      } else {
        hiddenActions.add(action);
      }
    }

    final List<Widget> children = <Widget>[
      for (final DiplomaticPanelAction action in defaultActions)
        _buildActionButton(action, showInlineRejectionReason: false),
      if (hiddenActions.isNotEmpty)
        _buildMoreToggleButton(
          context,
          expanded: _expanded,
          label: _expanded
              ? l10n.diplomacy_panel_fewerActions
              : l10n.diplomacy_panel_moreActions,
        ),
      if (_expanded)
        for (final DiplomaticPanelAction action in hiddenActions)
          _buildActionButton(action, showInlineRejectionReason: true),
    ];

    return Wrap(
      alignment: widget.alignEnd ? WrapAlignment.end : WrapAlignment.start,
      spacing: kDiplomacyActionWrapSpacing,
      runSpacing: kDiplomacyActionWrapSpacing,
      children: children,
    );
  }

  Widget _buildMoreToggleButton(
    BuildContext context, {
    required bool expanded,
    required String label,
  }) {
    final TextStyle labelStyle =
        (Theme.of(context).textTheme.bodySmall ?? const TextStyle(fontSize: 12))
            .copyWith(
              fontFamily: editorialMonocleDisplayFontFamily,
              fontSize: kDiplomacyActionButtonFontSize,
            );
    return CtNinePatchButton(
      key: ValueKey('${kDiplomacyMoreActionsKeyPrefix}${widget.factionId}'),
      onPressed: () => setState(() => _expanded = !expanded),
      minHeight: kDiplomacyActionButtonMinHeight,
      padding: kDiplomacyActionButtonPadding,
      shrinkWrap: true,
      child: Text(label, style: labelStyle),
    );
  }

  Widget _buildActionButton(
    DiplomaticPanelAction action, {
    required bool showInlineRejectionReason,
  }) {
    if (_isActionPending(action)) {
      return DiplomacyActionButton(
        order: action.order,
        onPressed: () {},
        isPending: true,
        onCancel: () => widget.onAction(action.order),
      );
    }
    return DiplomacyActionButton(
      order: action.order,
      enabled: action.enabled,
      rejectionReason: action.rejectionReason,
      showInlineRejectionReason: showInlineRejectionReason,
      onPressed: action.enabled ? () => widget.onAction(action.order) : null,
    );
  }
}

class DiplomacyActionButton extends StatelessWidget {
  const DiplomacyActionButton({super.key, 
    required this.order,
    required this.onPressed,
    this.isPending = false,
    this.onCancel,
    this.enabled = true,
    this.rejectionReason,
    this.showInlineRejectionReason = false,
  });

  final DiplomaticOrder order;
  final VoidCallback? onPressed;
  final bool isPending;
  final VoidCallback? onCancel;
  final bool enabled;
  final String? rejectionReason;
  final bool showInlineRejectionReason;

  bool get _isDangerVariant =>
      !isPending &&
      (order.type == DiplomaticOrderType.declareWar ||
          order.type == DiplomaticOrderType.breakAlliance);

  @override
  Widget build(BuildContext context) {
    final label = isPending ? 'Cancel' : diplomacyActionLabel(order);
    final ThemeData theme = Theme.of(context);
    final TextStyle labelStyle =
        (theme.textTheme.bodySmall ?? const TextStyle(fontSize: 12)).copyWith(
          fontFamily: editorialMonocleDisplayFontFamily,
          fontSize: kDiplomacyActionButtonFontSize,
        );
    final Widget button = CtNinePatchButton(
      onPressed: isPending ? onCancel : onPressed,
      enabled: isPending || enabled,
      minHeight: kDiplomacyActionButtonMinHeight,
      padding: kDiplomacyActionButtonPadding,
      shrinkWrap: true,
      dangerVariant: _isDangerVariant,
      child: Text(label, style: labelStyle),
    );
    final String? reason = rejectionReason;
    if (!isPending &&
        !enabled &&
        reason != null &&
        reason.isNotEmpty &&
        showInlineRejectionReason) {
      final TextStyle reasonStyle =
          (theme.textTheme.bodySmall ?? const TextStyle(fontSize: 12)).copyWith(
            color: EditorialMonoclePalette.muted,
            fontFamily: 'monospace',
            fontFamilyFallback: const ['Courier'],
            fontSize: kDiplomacyActionRejectionReasonFontSize,
          );
      return Semantics(
        label: '$label. $reason',
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            button,
            Padding(
              padding: const EdgeInsets.only(top: 2, left: 2, right: 2),
              child: Text(reason, style: reasonStyle),
            ),
          ],
        ),
      );
    }
    if (!isPending && !enabled && reason != null && reason.isNotEmpty) {
      return Tooltip(message: reason, child: button);
    }
    return button;
  }
}
