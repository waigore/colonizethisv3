// Count-transfer mutation helpers for [CtTransferList].
// Split from `ct_transfer_list.dart` to keep each widget library part
// under the repo file-size target (Refs #3878).

part of 'ct_transfer_list.dart';

extension _CtTransferListMutations on _CtTransferListState {
  void _notifyChanged() {
    widget.onChanged?.call(_leftCounts, _rightCounts);
  }

  void _cleanupZeros() {
    _leftCounts.removeWhere((_, v) => v <= 0);
    _rightCounts.removeWhere((_, v) => v <= 0);
  }

  void _moveOneToRight(String itemId) {
    final from = _leftCounts[itemId] ?? 0;
    if (from <= 0) return;
    setState(() {
      _leftCounts[itemId] = from - 1;
      _rightCounts[itemId] = (_rightCounts[itemId] ?? 0) + 1;
      _cleanupZeros();
    });
    _notifyChanged();
  }

  void _moveOneToLeft(String itemId) {
    final from = _rightCounts[itemId] ?? 0;
    if (from <= 0) return;
    setState(() {
      _rightCounts[itemId] = from - 1;
      _leftCounts[itemId] = (_leftCounts[itemId] ?? 0) + 1;
      _cleanupZeros();
    });
    _notifyChanged();
  }

  void _moveAllToRight(String itemId) {
    final from = _leftCounts[itemId] ?? 0;
    if (from <= 0) return;
    setState(() {
      _rightCounts[itemId] = (_rightCounts[itemId] ?? 0) + from;
      _leftCounts.remove(itemId);
      _cleanupZeros();
    });
    _notifyChanged();
  }

  void _moveAllToLeft(String itemId) {
    final from = _rightCounts[itemId] ?? 0;
    if (from <= 0) return;
    setState(() {
      _leftCounts[itemId] = (_leftCounts[itemId] ?? 0) + from;
      _rightCounts.remove(itemId);
      _cleanupZeros();
    });
    _notifyChanged();
  }

  void _handleConfirm() {
    if (!_canConfirm) return;
    widget.onConfirm(
      Map<String, int>.from(_leftCounts),
      Map<String, int>.from(_rightCounts),
    );
  }
}
