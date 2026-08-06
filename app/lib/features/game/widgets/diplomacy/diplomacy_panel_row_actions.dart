// Diplomacy row action chips and More-toggle cluster.
// SPEC/ui/diplomacy-panel.md § Per-faction row actions.

import 'package:colonizethis_app_l10n/l10n/l10n.dart';
import 'package:colonizethis_app_ui_chrome/config/editorial_monocle_palette.dart';
import 'package:colonizethis_orders/colonizethis_orders.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:flutter/material.dart';

import '../../../../config/themes.dart' show editorialMonocleDisplayFontFamily;
import '../../../../widgets/ct_nine_patch_button.dart';
import 'diplomacy_order_helpers.dart';
import 'diplomacy_panel_constants.dart';

class DiplomacyRowActions extends StatefulWidget {
  const DiplomacyRowActions({
    super.key,
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
  State<DiplomacyRowActions> createState() => _DiplomacyRowActionsState();
}

class _DiplomacyRowActionsState extends State<DiplomacyRowActions> {
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
  const DiplomacyActionButton({
    super.key,
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
    final l10n = appL10n(context);
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
        label: l10n.diplomacy_actionRejection_semanticsLabel(label, reason),
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
