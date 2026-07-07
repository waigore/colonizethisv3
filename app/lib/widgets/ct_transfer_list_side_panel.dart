part of 'ct_transfer_list.dart';

class _TransferSidePanel extends StatelessWidget {
  const _TransferSidePanel({
    required this.title,
    required this.counts,
    required this.total,
    required this.listHeight,
    required this.emptyLabel,
    required this.itemLabelBuilder,
    required this.totalLabelBuilder,
    required this.placeActionsAfterLabel,
    required this.moveAllToLeftLabel,
    required this.moveOneToLeftLabel,
    required this.moveOneToRightLabel,
    required this.moveAllToRightLabel,
    required this.onMoveOneToRight,
    required this.onMoveAllToRight,
    required this.onMoveOneToLeft,
    required this.onMoveAllToLeft,
    this.subtitle,
  });

  final String title;
  final String? subtitle;
  final Map<String, int> counts;
  final int total;
  final double listHeight;
  final String emptyLabel;
  final String Function(String itemId) itemLabelBuilder;
  final String Function(int total)? totalLabelBuilder;

  /// True: original-fleet panel — label then [>] [>>]. False: new-fleet panel — [<<] [<] then label.
  final bool placeActionsAfterLabel;
  final String moveAllToLeftLabel;
  final String moveOneToLeftLabel;
  final String moveOneToRightLabel;
  final String moveAllToRightLabel;
  final void Function(String itemId) onMoveOneToRight;
  final void Function(String itemId) onMoveAllToRight;
  final void Function(String itemId) onMoveOneToLeft;
  final void Function(String itemId) onMoveAllToLeft;

  static const double _rowButtonMinHeight = 40;

  /// Per-row transfer-button padding. Horizontal `CtSpacing.m` (8 px) and
  /// vertical `CtSpacing.s` (6 px) per
  /// `SPEC/ui/pixel-art-ui-catalog.md` § *Spacing tokens*.
  static const EdgeInsets _rowButtonPadding = EdgeInsets.symmetric(
    horizontal: CtSpacing.m,
    vertical: CtSpacing.s,
  );

  @override
  Widget build(BuildContext context) {
    return CtPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(title, style: Theme.of(context).textTheme.titleSmall),
          if (subtitle != null)
            Text(subtitle!, style: Theme.of(context).textTheme.bodySmall),
          const SizedBox(height: CtSpacing.m),
          const Divider(height: 1),
          const SizedBox(height: CtSpacing.m),
          _buildListArea(context),
          const SizedBox(height: CtSpacing.m),
          const Divider(height: 1),
          const SizedBox(height: 4),
          Text(
            totalLabelBuilder?.call(total) ?? 'Total: $total items',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }

  Widget _buildListArea(BuildContext context) {
    final sortedTypes = counts.keys.toList()..sort();
    return SizedBox(
      height: listHeight,
      child: sortedTypes.isEmpty
          ? _buildEmptyListBody(context)
          : ListView.builder(
              itemCount: sortedTypes.length,
              itemBuilder: (context, index) =>
                  _buildTypeRow(context, sortedTypes[index]),
            ),
    );
  }

  Widget _buildEmptyListBody(BuildContext context) {
    return Center(
      child: Text(
        emptyLabel,
        style: Theme.of(
          context,
        ).textTheme.bodyMedium?.copyWith(
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }

  Widget _buildTypeRow(BuildContext context, String typeId) {
    final count = counts[typeId] ?? 0;
    final label = Text(
      appL10n(context).transferList_rowCount(itemLabelBuilder(typeId), count),
      style: Theme.of(context).textTheme.bodyMedium,
    );
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: CtSpacing.xs),
      child: Material(
        color: Colors.transparent,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
          child: Row(
            children: _rowChildrenFor(typeId: typeId, count: count, label: label),
          ),
        ),
      ),
    );
  }

  List<Widget> _rowChildrenFor({
    required String typeId,
    required int count,
    required Widget label,
  }) {
    final canMove = count > 0;
    if (placeActionsAfterLabel) {
      return [
        Expanded(child: label),
        const SizedBox(width: 6),
        _transferActionButton(
          key: CtTransferListKeys.leftMoveOne(typeId),
          enabled: canMove,
          onPressed: canMove ? () => onMoveOneToRight(typeId) : null,
          label: moveOneToRightLabel,
        ),
        const SizedBox(width: 4),
        _transferActionButton(
          key: CtTransferListKeys.leftMoveAll(typeId),
          enabled: canMove,
          onPressed: canMove ? () => onMoveAllToRight(typeId) : null,
          label: moveAllToRightLabel,
        ),
      ];
    }
    return [
      _transferActionButton(
        key: CtTransferListKeys.rightMoveAll(typeId),
        enabled: canMove,
        onPressed: canMove ? () => onMoveAllToLeft(typeId) : null,
        label: moveAllToLeftLabel,
      ),
      const SizedBox(width: 4),
      _transferActionButton(
        key: CtTransferListKeys.rightMoveOne(typeId),
        enabled: canMove,
        onPressed: canMove ? () => onMoveOneToLeft(typeId) : null,
        label: moveOneToLeftLabel,
      ),
      const SizedBox(width: 6),
      Expanded(child: label),
    ];
  }

  CtNinePatchButton _transferActionButton({
    required Key key,
    required bool enabled,
    required VoidCallback? onPressed,
    required String label,
  }) {
    return CtNinePatchButton(
      key: key,
      minHeight: _rowButtonMinHeight,
      padding: _rowButtonPadding,
      enabled: enabled,
      onPressed: onPressed,
      child: Text(label),
    );
  }
}
