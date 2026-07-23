import 'package:flutter/material.dart';

import 'ct_nine_patch_button.dart';
import 'ct_transfer_list.dart';
import 'ct_transfer_list_side_panel.dart';

/// Side-by-side two-panel layout requires at least this many logical pixels of
/// inner width (the constraint passed to [CtTransferList] by its parent shell,
/// e.g. `CtDialogShell` body). Below this threshold the two panels stack
/// vertically so the per-row label + transfer buttons can render without a
/// `RenderFlex` overflow at the minimum supported viewport
/// (`kMinViewportWidth = 320` dp). Normative narrow stacking behavior is
/// documented in `SPEC/ui/naval-units-fleet-management.md`,
/// `SPEC/ui/military-units-army-management.md`, and
/// `SPEC/ui/transfer-to-home-fleet-dialog.md`.
@visibleForTesting
const double kCtTransferListSideBySideMinWidth = 360;

class CtTransferListState extends State<CtTransferList> {
  late Map<String, int> leftCounts;
  late Map<String, int> rightCounts;

  int get leftTotal => leftCounts.values.fold(0, (sum, count) => sum + count);
  int get rightTotal =>
      rightCounts.values.fold(0, (sum, count) => sum + count);

  bool get canConfirm {
    final validate = widget.canConfirm;
    if (validate == null) {
      return rightTotal > 0;
    }
    return validate(leftCounts, rightCounts);
  }

  @override
  void initState() {
    super.initState();
    leftCounts = Map<String, int>.from(widget.initialLeftCounts);
    rightCounts = Map<String, int>.from(widget.initialRightCounts);
  }

  String itemLabel(String itemId) {
    final builder = widget.itemLabelBuilder;
    if (builder == null) return itemId;
    return builder(itemId);
  }

  void notifyCountsChanged() {
    widget.onChanged?.call(leftCounts, rightCounts);
  }

  void cleanupZeroCounts() {
    leftCounts.removeWhere((_, v) => v <= 0);
    rightCounts.removeWhere((_, v) => v <= 0);
  }

  void moveOneToRight(String itemId) {
    final from = leftCounts[itemId] ?? 0;
    if (from <= 0) return;
    setState(() {
      leftCounts[itemId] = from - 1;
      rightCounts[itemId] = (rightCounts[itemId] ?? 0) + 1;
      cleanupZeroCounts();
    });
    notifyCountsChanged();
  }

  void moveOneToLeft(String itemId) {
    final from = rightCounts[itemId] ?? 0;
    if (from <= 0) return;
    setState(() {
      rightCounts[itemId] = from - 1;
      leftCounts[itemId] = (leftCounts[itemId] ?? 0) + 1;
      cleanupZeroCounts();
    });
    notifyCountsChanged();
  }

  void moveAllToRight(String itemId) {
    final from = leftCounts[itemId] ?? 0;
    if (from <= 0) return;
    setState(() {
      rightCounts[itemId] = (rightCounts[itemId] ?? 0) + from;
      leftCounts.remove(itemId);
      cleanupZeroCounts();
    });
    notifyCountsChanged();
  }

  void moveAllToLeft(String itemId) {
    final from = rightCounts[itemId] ?? 0;
    if (from <= 0) return;
    setState(() {
      leftCounts[itemId] = (leftCounts[itemId] ?? 0) + from;
      rightCounts.remove(itemId);
      cleanupZeroCounts();
    });
    notifyCountsChanged();
  }

  void handleTransferListConfirm() {
    if (!canConfirm) return;
    widget.onConfirm(
      Map<String, int>.from(leftCounts),
      Map<String, int>.from(rightCounts),
    );
  }

  Widget leftTransferPanel() {
    return CtTransferSidePanel(
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

  Widget rightTransferPanel() {
    return CtTransferSidePanel(
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

  Widget transferListActionRow(BuildContext context, {required bool useWrap}) {
    final cancel = widget.onCancel == null
        ? null
        : CtNinePatchButton(
            onPressed: widget.onCancel,
            child: Text(widget.cancelLabel),
          );
    final confirm = CtNinePatchButton(
      onPressed: handleTransferListConfirm,
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
              leftTransferPanel(),
              const SizedBox(height: 16),
              rightTransferPanel(),
              const SizedBox(height: 16),
              transferListActionRow(context, useWrap: true),
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
                Expanded(child: leftTransferPanel()),
                const SizedBox(width: 16),
                Expanded(child: rightTransferPanel()),
              ],
            ),
            const SizedBox(height: 16),
            transferListActionRow(context, useWrap: false),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) => buildTransferListLayout(context);
}
