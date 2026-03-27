import 'package:flutter/material.dart';

import 'ct_nine_patch_button.dart';
import 'ct_panel.dart';

/// Generic dual-list transfer widget for moving counted items between two sides.
///
/// Use this component when a feature needs transferable quantities with:
/// - one selected item at a time
/// - single-item and move-all controls
/// - configurable validation before confirm
/// - customizable labels and item rendering
class CtTransferList extends StatefulWidget {
  const CtTransferList({
    super.key,
    required this.leftTitle,
    required this.rightTitle,
    required this.initialLeftCounts,
    required this.onConfirm,
    this.leftSubtitle,
    this.rightSubtitle,
    this.initialRightCounts = const {},
    this.itemLabelBuilder,
    this.canConfirm,
    this.onChanged,
    this.onCancel,
    this.leftEmptyLabel = 'No items',
    this.rightEmptyLabel = 'No items',
    this.moveAllToLeftLabel = '<<',
    this.moveOneToLeftLabel = '<',
    this.moveOneToRightLabel = '>',
    this.moveAllToRightLabel = '>>',
    this.cancelLabel = 'Cancel',
    this.confirmLabel = 'Confirm',
    this.listHeight = 150,
    this.totalLabelBuilder,
  });

  final String leftTitle;
  final String rightTitle;
  final String? leftSubtitle;
  final String? rightSubtitle;
  final Map<String, int> initialLeftCounts;
  final Map<String, int> initialRightCounts;
  final String Function(String itemId)? itemLabelBuilder;
  final bool Function(Map<String, int> left, Map<String, int> right)?
  canConfirm;
  final void Function(Map<String, int> left, Map<String, int> right)? onChanged;
  final void Function(Map<String, int> left, Map<String, int> right) onConfirm;
  final VoidCallback? onCancel;
  final String leftEmptyLabel;
  final String rightEmptyLabel;
  final String moveAllToLeftLabel;
  final String moveOneToLeftLabel;
  final String moveOneToRightLabel;
  final String moveAllToRightLabel;
  final String cancelLabel;
  final String confirmLabel;
  final double listHeight;
  final String Function(int total)? totalLabelBuilder;

  @override
  State<CtTransferList> createState() => _CtTransferListState();
}

class _CtTransferListState extends State<CtTransferList> {
  late Map<String, int> _leftCounts;
  late Map<String, int> _rightCounts;
  String? _selectedItemId;

  int get _leftTotal => _leftCounts.values.fold(0, (sum, count) => sum + count);
  int get _rightTotal =>
      _rightCounts.values.fold(0, (sum, count) => sum + count);

  bool get _canConfirm {
    final validate = widget.canConfirm;
    if (validate == null) {
      return _rightTotal > 0;
    }
    return validate(_leftCounts, _rightCounts);
  }

  @override
  void initState() {
    super.initState();
    _leftCounts = Map<String, int>.from(widget.initialLeftCounts);
    _rightCounts = Map<String, int>.from(widget.initialRightCounts);
  }

  String _itemLabel(String itemId) {
    final builder = widget.itemLabelBuilder;
    if (builder == null) return itemId;
    return builder(itemId);
  }

  void _notifyChanged() {
    widget.onChanged?.call(_leftCounts, _rightCounts);
  }

  void _cleanupZerosAndSelection() {
    _leftCounts.removeWhere((_, v) => v <= 0);
    _rightCounts.removeWhere((_, v) => v <= 0);
    final selected = _selectedItemId;
    if (selected == null) return;
    if (!_leftCounts.containsKey(selected) &&
        !_rightCounts.containsKey(selected)) {
      _selectedItemId = null;
    }
  }

  void _moveOneToRight(String itemId) {
    final from = _leftCounts[itemId] ?? 0;
    if (from <= 0) return;
    setState(() {
      _leftCounts[itemId] = from - 1;
      _rightCounts[itemId] = (_rightCounts[itemId] ?? 0) + 1;
      _cleanupZerosAndSelection();
    });
    _notifyChanged();
  }

  void _moveOneToLeft(String itemId) {
    final from = _rightCounts[itemId] ?? 0;
    if (from <= 0) return;
    setState(() {
      _rightCounts[itemId] = from - 1;
      _leftCounts[itemId] = (_leftCounts[itemId] ?? 0) + 1;
      _cleanupZerosAndSelection();
    });
    _notifyChanged();
  }

  void _moveAllToRight(String itemId) {
    final from = _leftCounts[itemId] ?? 0;
    if (from <= 0) return;
    setState(() {
      _rightCounts[itemId] = (_rightCounts[itemId] ?? 0) + from;
      _leftCounts.remove(itemId);
      _cleanupZerosAndSelection();
    });
    _notifyChanged();
  }

  void _moveAllToLeft(String itemId) {
    final from = _rightCounts[itemId] ?? 0;
    if (from <= 0) return;
    setState(() {
      _leftCounts[itemId] = (_leftCounts[itemId] ?? 0) + from;
      _rightCounts.remove(itemId);
      _cleanupZerosAndSelection();
    });
    _notifyChanged();
  }

  void _toggleSelection(String itemId) {
    setState(() {
      _selectedItemId = _selectedItemId == itemId ? null : itemId;
    });
  }

  void _handleConfirm() {
    if (!_canConfirm) return;
    widget.onConfirm(
      Map<String, int>.from(_leftCounts),
      Map<String, int>.from(_rightCounts),
    );
  }

  @override
  Widget build(BuildContext context) {
    final selected = _selectedItemId;
    final selectedLeft = selected == null ? 0 : (_leftCounts[selected] ?? 0);
    final selectedRight = selected == null ? 0 : (_rightCounts[selected] ?? 0);
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: _TransferSidePanel(
                title: widget.leftTitle,
                subtitle: widget.leftSubtitle,
                counts: _leftCounts,
                total: _leftTotal,
                listHeight: widget.listHeight,
                selectedItemId: _selectedItemId,
                emptyLabel: widget.leftEmptyLabel,
                itemLabelBuilder: _itemLabel,
                onSelectItem: _toggleSelection,
                totalLabelBuilder: widget.totalLabelBuilder,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _TransferSidePanel(
                title: widget.rightTitle,
                subtitle: widget.rightSubtitle,
                counts: _rightCounts,
                total: _rightTotal,
                listHeight: widget.listHeight,
                selectedItemId: _selectedItemId,
                emptyLabel: widget.rightEmptyLabel,
                itemLabelBuilder: _itemLabel,
                onSelectItem: _toggleSelection,
                totalLabelBuilder: widget.totalLabelBuilder,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CtNinePatchButton(
              onPressed: selected == null
                  ? null
                  : () => _moveAllToLeft(selected),
              enabled: selected != null && selectedRight > 0,
              child: Text(widget.moveAllToLeftLabel),
            ),
            const SizedBox(width: 8),
            CtNinePatchButton(
              onPressed: selected == null
                  ? null
                  : () => _moveOneToLeft(selected),
              enabled: selected != null && selectedRight > 0,
              child: Text(widget.moveOneToLeftLabel),
            ),
            const SizedBox(width: 16),
            CtNinePatchButton(
              onPressed: selected == null
                  ? null
                  : () => _moveOneToRight(selected),
              enabled: selected != null && selectedLeft > 0,
              child: Text(widget.moveOneToRightLabel),
            ),
            const SizedBox(width: 8),
            CtNinePatchButton(
              onPressed: selected == null
                  ? null
                  : () => _moveAllToRight(selected),
              enabled: selected != null && selectedLeft > 0,
              child: Text(widget.moveAllToRightLabel),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            if (widget.onCancel != null) ...[
              CtNinePatchButton(
                onPressed: widget.onCancel,
                child: Text(widget.cancelLabel),
              ),
              const SizedBox(width: 8),
            ],
            CtNinePatchButton(
              onPressed: _handleConfirm,
              enabled: _canConfirm,
              child: Text(widget.confirmLabel),
            ),
          ],
        ),
      ],
    );
  }
}

class _TransferSidePanel extends StatelessWidget {
  const _TransferSidePanel({
    required this.title,
    required this.counts,
    required this.total,
    required this.listHeight,
    required this.selectedItemId,
    required this.emptyLabel,
    required this.itemLabelBuilder,
    required this.onSelectItem,
    required this.totalLabelBuilder,
    this.subtitle,
  });

  final String title;
  final String? subtitle;
  final Map<String, int> counts;
  final int total;
  final double listHeight;
  final String? selectedItemId;
  final String emptyLabel;
  final String Function(String itemId) itemLabelBuilder;
  final void Function(String itemId) onSelectItem;
  final String Function(int total)? totalLabelBuilder;

  @override
  Widget build(BuildContext context) {
    final sortedTypes = counts.keys.toList()..sort();
    return CtPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(title, style: Theme.of(context).textTheme.titleSmall),
          if (subtitle != null)
            Text(subtitle!, style: Theme.of(context).textTheme.bodySmall),
          const SizedBox(height: 8),
          const Divider(height: 1),
          const SizedBox(height: 8),
          SizedBox(
            height: listHeight,
            child: sortedTypes.isEmpty
                ? Center(
                    child: Text(
                      emptyLabel,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  )
                : ListView.builder(
                    itemCount: sortedTypes.length,
                    itemBuilder: (context, index) {
                      final typeId = sortedTypes[index];
                      final count = counts[typeId] ?? 0;
                      final isSelected = selectedItemId == typeId;
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 2),
                        child: Material(
                          color: isSelected
                              ? Theme.of(context).colorScheme.primaryContainer
                              : Colors.transparent,
                          child: InkWell(
                            onTap: () => onSelectItem(typeId),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 6,
                              ),
                              child: Text(
                                '${itemLabelBuilder(typeId)} ($count)',
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
          ),
          const SizedBox(height: 8),
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
}
