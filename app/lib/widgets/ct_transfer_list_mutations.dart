// Count-transfer mutation helpers for [CtTransferList].

import 'ct_transfer_list_state_base.dart';

mixin CtTransferListMutations on CtTransferListStateBase {
  void notifyChanged() {
    widget.onChanged?.call(leftCounts, rightCounts);
  }

  void cleanupZeros() {
    leftCounts.removeWhere((_, v) => v <= 0);
    rightCounts.removeWhere((_, v) => v <= 0);
  }

  void moveOneToRight(String itemId) {
    final from = leftCounts[itemId] ?? 0;
    if (from <= 0) return;
    setState(() {
      leftCounts[itemId] = from - 1;
      rightCounts[itemId] = (rightCounts[itemId] ?? 0) + 1;
      cleanupZeros();
    });
    notifyChanged();
  }

  void moveOneToLeft(String itemId) {
    final from = rightCounts[itemId] ?? 0;
    if (from <= 0) return;
    setState(() {
      rightCounts[itemId] = from - 1;
      leftCounts[itemId] = (leftCounts[itemId] ?? 0) + 1;
      cleanupZeros();
    });
    notifyChanged();
  }

  void moveAllToRight(String itemId) {
    final from = leftCounts[itemId] ?? 0;
    if (from <= 0) return;
    setState(() {
      rightCounts[itemId] = (rightCounts[itemId] ?? 0) + from;
      leftCounts.remove(itemId);
      cleanupZeros();
    });
    notifyChanged();
  }

  void moveAllToLeft(String itemId) {
    final from = rightCounts[itemId] ?? 0;
    if (from <= 0) return;
    setState(() {
      leftCounts[itemId] = (leftCounts[itemId] ?? 0) + from;
      rightCounts.remove(itemId);
      cleanupZeros();
    });
    notifyChanged();
  }

  void handleConfirm() {
    if (!canConfirm) return;
    widget.onConfirm(
      Map<String, int>.from(leftCounts),
      Map<String, int>.from(rightCounts),
    );
  }
}
