// Layout chrome for [CtTransferList] side panels and confirm row.
// Split from `ct_transfer_list.dart` to keep each widget library part
// under the repo file-size target (Refs #3878).

part of 'ct_transfer_list.dart';

extension _CtTransferListLayout on _CtTransferListState {
  String _itemLabel(String itemId) {
    final builder = widget.itemLabelBuilder;
    if (builder == null) return itemId;
    return builder(itemId);
  }

  Widget _leftPanel() {
    return _TransferSidePanel(
      title: widget.leftTitle,
      subtitle: widget.leftSubtitle,
      counts: _leftCounts,
      total: _leftTotal,
      listHeight: widget.listHeight,
      emptyLabel: widget.leftEmptyLabel,
      itemLabelBuilder: _itemLabel,
      totalLabelBuilder: widget.totalLabelBuilder,
      placeActionsAfterLabel: true,
      moveAllToLeftLabel: widget.moveAllToLeftLabel,
      moveOneToLeftLabel: widget.moveOneToLeftLabel,
      moveOneToRightLabel: widget.moveOneToRightLabel,
      moveAllToRightLabel: widget.moveAllToRightLabel,
      onMoveOneToRight: _moveOneToRight,
      onMoveAllToRight: _moveAllToRight,
      onMoveOneToLeft: _moveOneToLeft,
      onMoveAllToLeft: _moveAllToLeft,
    );
  }

  Widget _rightPanel() {
    return _TransferSidePanel(
      title: widget.rightTitle,
      subtitle: widget.rightSubtitle,
      counts: _rightCounts,
      total: _rightTotal,
      listHeight: widget.listHeight,
      emptyLabel: widget.rightEmptyLabel,
      itemLabelBuilder: _itemLabel,
      totalLabelBuilder: widget.totalLabelBuilder,
      placeActionsAfterLabel: false,
      moveAllToLeftLabel: widget.moveAllToLeftLabel,
      moveOneToLeftLabel: widget.moveOneToLeftLabel,
      moveOneToRightLabel: widget.moveOneToRightLabel,
      moveAllToRightLabel: widget.moveAllToRightLabel,
      onMoveOneToRight: _moveOneToRight,
      onMoveAllToRight: _moveAllToRight,
      onMoveOneToLeft: _moveOneToLeft,
      onMoveAllToLeft: _moveAllToLeft,
    );
  }

  Widget _actionRow(BuildContext context, {required bool useWrap}) {
    // At the minimum supported viewport (`kMinViewportWidth = 320` dp) the
    // Cinzel engraved-label text in `CtNinePatchButton` overflows a single
    // right-aligned `Row` for `Cancel` + a long `confirmLabel` (e.g.
    // "Confirm Split", "Transfer"). The narrow stack therefore uses `Wrap`
    // so Cancel + Confirm can flow onto a second run when needed. Wider
    // viewports keep the canonical single-row right-aligned layout so
    // existing dialog tests (and SPEC mockups) see the unchanged chrome.
    final cancel = widget.onCancel == null
        ? null
        : CtNinePatchButton(
            onPressed: widget.onCancel,
            child: Text(widget.cancelLabel),
          );
    final confirm = CtNinePatchButton(
      onPressed: _handleConfirm,
      enabled: _canConfirm,
      child: Text(widget.confirmLabel),
    );
    if (useWrap) {
      return Wrap(
        alignment: WrapAlignment.end,
        crossAxisAlignment: WrapCrossAlignment.center,
        spacing: 8,
        runSpacing: 8,
        children: [
          ?cancel,
          confirm,
        ],
      );
    }
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        if (cancel != null) ...[cancel, const SizedBox(width: 8)],
        confirm,
      ],
    );
  }

  Widget buildTransferListLayout(BuildContext context) {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final bool stackVertically =
            constraints.maxWidth.isFinite &&
            constraints.maxWidth < kCtTransferListSideBySideMinWidth;
        if (stackVertically) {
          return Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _leftPanel(),
              const SizedBox(height: 16),
              _rightPanel(),
              const SizedBox(height: 16),
              _actionRow(context, useWrap: true),
            ],
          );
        }
        return Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: _leftPanel()),
                const SizedBox(width: 16),
                Expanded(child: _rightPanel()),
              ],
            ),
            const SizedBox(height: 16),
            _actionRow(context, useWrap: false),
          ],
        );
      },
    );
  }
}
