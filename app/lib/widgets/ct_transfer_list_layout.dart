// Layout chrome for [CtTransferList] side panels and confirm row.

import 'package:flutter/material.dart';

import 'ct_nine_patch_button.dart';
import 'ct_transfer_list.dart';
import 'ct_transfer_list_mutations.dart';
import 'ct_transfer_list_side_panel.dart';
import 'ct_transfer_list_state_base.dart';

mixin CtTransferListLayout on CtTransferListStateBase, CtTransferListMutations {
  String itemLabel(String itemId) {
    final builder = widget.itemLabelBuilder;
    if (builder == null) return itemId;
    return builder(itemId);
  }

  Widget leftPanel() {
    return CtTransferListSidePanel(
      title: widget.leftTitle,
      subtitle: widget.leftSubtitle,
      counts: leftCounts,
      total: leftTotal,
      listHeight: widget.listHeight,
      emptyLabel: widget.leftEmptyLabel,
      itemLabelBuilder: itemLabel,
      totalLabelBuilder: widget.totalLabelBuilder,
      placeActionsAfterLabel: true,
      moveAllToLeftLabel: widget.moveAllToLeftLabel,
      moveOneToLeftLabel: widget.moveOneToLeftLabel,
      moveOneToRightLabel: widget.moveOneToRightLabel,
      moveAllToRightLabel: widget.moveAllToRightLabel,
      onMoveOneToRight: moveOneToRight,
      onMoveAllToRight: moveAllToRight,
      onMoveOneToLeft: moveOneToLeft,
      onMoveAllToLeft: moveAllToLeft,
    );
  }

  Widget rightPanel() {
    return CtTransferListSidePanel(
      title: widget.rightTitle,
      subtitle: widget.rightSubtitle,
      counts: rightCounts,
      total: rightTotal,
      listHeight: widget.listHeight,
      emptyLabel: widget.rightEmptyLabel,
      itemLabelBuilder: itemLabel,
      totalLabelBuilder: widget.totalLabelBuilder,
      placeActionsAfterLabel: false,
      moveAllToLeftLabel: widget.moveAllToLeftLabel,
      moveOneToLeftLabel: widget.moveOneToLeftLabel,
      moveOneToRightLabel: widget.moveOneToRightLabel,
      moveAllToRightLabel: widget.moveAllToRightLabel,
      onMoveOneToRight: moveOneToRight,
      onMoveAllToRight: moveAllToRight,
      onMoveOneToLeft: moveOneToLeft,
      onMoveAllToLeft: moveAllToLeft,
    );
  }

  Widget actionRow(BuildContext context, {required bool useWrap}) {
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
      onPressed: handleConfirm,
      enabled: canConfirm,
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
              leftPanel(),
              const SizedBox(height: 16),
              rightPanel(),
              const SizedBox(height: 16),
              actionRow(context, useWrap: true),
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
                Expanded(child: leftPanel()),
                const SizedBox(width: 16),
                Expanded(child: rightPanel()),
              ],
            ),
            const SizedBox(height: 16),
            actionRow(context, useWrap: false),
          ],
        );
      },
    );
  }
}
