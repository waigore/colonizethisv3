// Diplomacy faction-row action button cluster. SPEC/ui/diplomacy-panel.md § Action button styling.

part of 'diplomacy_panel.dart';

extension _DiplomacyRowActions on _DiplomacyRow {
  Widget _buildActionButtons({bool alignEnd = false}) {
    if (readOnly) {
      return const SizedBox.shrink();
    }
    return Wrap(
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
    if (!isPending && !enabled && reason != null && reason.isNotEmpty) {
      return Tooltip(message: reason, child: button);
    }
    return button;
  }
}
